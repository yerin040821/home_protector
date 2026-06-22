// lib/services/weather_warning_service.dart
//
// 기상청(KMA) 기상특보 조회서비스 연동 — 실시간 특보(호우/강풍/대설 등)만 표시.
// 공공데이터포털 "기상청_기상특보 조회서비스"(WthrWrnInfoService) 사용:
//   getWthrWrnList → 최근 발표 목록(tmFc/tmSeq)
//   getWthrWrnMsg  → 해당 통보문 전문(t6) — "특보 발효 현황" 포함
//
// 서비스 키는 코드에 하드코딩하지 않고 --dart-define=KMA_SERVICE_KEY 로 주입한다.
// (run.sh 가 .env 의 KMA_SERVICE_KEY 를 전달)
//
// ⚠️ data.go.kr 은 CORS 를 지원하지 않으므로 Flutter 웹(브라우저)에서는 호출이
//    차단될 수 있다. 모바일(Android/iOS)에서는 정상 동작한다.
import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// 발효 중인 기상특보 한 건.
class WeatherWarning {
  final String hazard; // 호우, 강풍, 대설, 폭염 ...
  final String level; // 주의보 / 경보
  final String region; // 매칭된 지역 텍스트(라인 일부)

  const WeatherWarning({
    required this.hazard,
    required this.level,
    required this.region,
  });

  String get title => '$hazard$level';
  bool get isCritical => level.contains('경보');
}

/// 특보 조회 결과 래퍼.
class WeatherWarningResult {
  final List<WeatherWarning> warnings; // 우리 지역에 매칭된 특보
  final String? bulletin; // 원문 통보문(지역 매칭 실패 시 실제정보 표시용)
  final bool keyConfigured; // KMA_SERVICE_KEY 설정 여부
  final String? error;

  const WeatherWarningResult({
    this.warnings = const [],
    this.bulletin,
    this.keyConfigured = true,
    this.error,
  });

  bool get hasAny => warnings.isNotEmpty || (bulletin != null && bulletin!.isNotEmpty);
}

class WeatherWarningService {
  WeatherWarningService({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;
  final Duration timeout = const Duration(seconds: 12);

  /// data.go.kr 서비스 키(Encoding 키 권장). 코드에 하드코딩하지 않는다.
  static const String serviceKey =
      String.fromEnvironment('KMA_SERVICE_KEY', defaultValue: '');

  static const String _base =
      'https://apis.data.go.kr/1360000/WthrWrnInfoService';

  bool get hasKey => serviceKey.isNotEmpty;

  static const List<String> _hazards = [
    '폭풍해일', '지진해일', '호우', '대설', '강풍', '풍랑',
    '한파', '폭염', '건조', '황사', '안개', '태풍',
  ];

  /// 발효 중인 특보 조회.
  /// [regionKeywords] 예: ['서울', '관악구'] — 통보문에서 이 키워드가 포함된 특보만 추출.
  /// [stnId] 109 = 서울지방기상청.
  Future<WeatherWarningResult> fetchActive({
    required List<String> regionKeywords,
    String stnId = '109',
    DateTime? now,
  }) async {
    if (!hasKey) {
      return const WeatherWarningResult(keyConfigured: false);
    }
    try {
      final current = now ?? DateTime.now();
      final from = _fmt(current.subtract(const Duration(days: 3)));
      final to = _fmt(current);

      final latest = await _latestAnnouncement(stnId, from, to);
      if (latest == null) {
        // 최근 발표 없음 = 발효 중 특보 없음.
        return const WeatherWarningResult();
      }

      final bulletin = await _bulletinText(stnId, latest);
      if (bulletin == null || bulletin.trim().isEmpty) {
        return const WeatherWarningResult();
      }

      final warnings = parseBulletin(bulletin, regionKeywords);
      return WeatherWarningResult(
        warnings: warnings,
        // 지역 매칭이 없어도 실제 통보문은 보여준다(요청: 실제 정보만 표시).
        bulletin: warnings.isEmpty ? bulletin.trim() : null,
      );
    } catch (e) {
      return WeatherWarningResult(error: '기상특보를 불러오지 못했습니다.');
    }
  }

  /// getWthrWrnList → 가장 최근 (tmFc, tmSeq).
  Future<_Announcement?> _latestAnnouncement(
      String stnId, String fromTm, String toTm) async {
    final url = '$_base/getWthrWrnList'
        '?serviceKey=$serviceKey'
        '&dataType=JSON&numOfRows=20&pageNo=1'
        '&stnId=$stnId&fromTmFc=$fromTm&toTmFc=$toTm';
    final items = await _items(url);
    _Announcement? best;
    for (final it in items) {
      final tmFc = _str(it['tmFc']);
      if (tmFc.isEmpty) continue;
      final tmSeq = _str(it['tmSeq']);
      final a = _Announcement(tmFc: tmFc, tmSeq: tmSeq);
      if (best == null || a.tmFc.compareTo(best.tmFc) > 0) best = a;
    }
    return best;
  }

  /// getWthrWrnMsg → 통보문 전문(t6 또는 가장 긴 문자열 필드).
  Future<String?> _bulletinText(String stnId, _Announcement a) async {
    final url = '$_base/getWthrWrnMsg'
        '?serviceKey=$serviceKey'
        '&dataType=JSON&numOfRows=10&pageNo=1'
        '&stnId=$stnId&tmFc=${a.tmFc}'
        '${a.tmSeq.isNotEmpty ? '&tmSeq=${a.tmSeq}' : ''}';
    final items = await _items(url);
    for (final it in items) {
      final t6 = _str(it['t6']);
      if (t6.isNotEmpty) return t6;
      // t6 가 없으면 가장 긴 문자열 필드를 통보문으로 간주.
      String longest = '';
      it.forEach((_, v) {
        if (v is String && v.length > longest.length) longest = v;
      });
      if (longest.length > 40) return longest;
    }
    return null;
  }

  /// 통보문 텍스트에서 "<재해><주의보|경보>" 라인을 찾아 지역 키워드와 매칭.
  /// (테스트 가능하도록 static 공개)
  static List<WeatherWarning> parseBulletin(
      String bulletin, List<String> regionKeywords) {
    final result = <WeatherWarning>[];
    final seen = <String>{};
    final hazardAlt = _hazards.join('|');
    final re = RegExp('($hazardAlt)\\s*(주의보|경보)');

    for (final rawLine in bulletin.split(RegExp(r'[\n\r]+'))) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;
      final m = re.firstMatch(line);
      if (m == null) continue;

      final matchedRegion =
          regionKeywords.any((k) => k.isNotEmpty && line.contains(k));
      if (!matchedRegion) continue;

      final hazard = m.group(1)!;
      final level = m.group(2)!;
      final key = '$hazard$level';
      if (seen.add(key)) {
        result.add(WeatherWarning(
          hazard: hazard,
          level: level,
          region: regionKeywords.firstWhere((k) => line.contains(k),
              orElse: () => regionKeywords.first),
        ));
      }
    }
    return result;
  }

  /// data.go.kr 표준 응답에서 item 리스트를 안전하게 추출.
  Future<List<Map<String, dynamic>>> _items(String url) async {
    final res = await _client.get(Uri.parse(url)).timeout(timeout);
    if (res.statusCode != 200) return const [];
    final body = utf8.decode(res.bodyBytes);
    // 키 오류 등은 평문(예: "Unauthorized")으로 올 수 있다.
    if (!body.trimLeft().startsWith('{')) return const [];

    final decoded = jsonDecode(body);
    final response = decoded is Map ? decoded['response'] : null;
    final resultBody = response is Map ? response['body'] : null;
    final items = resultBody is Map ? resultBody['items'] : null;
    final item = items is Map ? items['item'] : null;

    if (item is List) {
      return item.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
    }
    if (item is Map) {
      return [item.cast<String, dynamic>()];
    }
    return const [];
  }

  static String _str(dynamic v) => v == null ? '' : v.toString();

  /// yyyyMMddHHmm
  static String _fmt(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}${two(d.month)}${two(d.day)}${two(d.hour)}${two(d.minute)}';
  }

  void dispose() => _client.close();
}

class _Announcement {
  final String tmFc; // 발표시각 yyyyMMddHHmm
  final String tmSeq; // 발표순번
  const _Announcement({required this.tmFc, required this.tmSeq});
}
