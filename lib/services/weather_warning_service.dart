// lib/services/weather_warning_service.dart
//
// 기상청(KMA) 기상특보 조회서비스 연동 — 실시간 특보(호우/강풍/대설 등)만 표시.
// 공공데이터포털 "기상청_기상특보 조회서비스"(WthrWrnInfoService) 사용:
//   getWthrWrnList → 최근 발표 목록(tmFc/tmSeq)
//   getWthrWrnMsg  → 해당 통보문 전문(t6) — "특보 발효 현황" 포함
//
// 서비스 키는 코드에 하드코딩하지 않고 --dart-define=KMA_SERVICE_KEY 로 주입한다.
//
// 웹(브라우저) 지원: data.go.kr 은 CORS 를 지원하지 않으므로 웹에서는 CORS 프록시를
// 경유한다(--dart-define=CORS_PROXY, 기본 allorigins). 모바일은 직접 호출한다.
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

/// 특보 조회 결과 상태 — UI 에서 원인을 상세히 구분해 보여 주기 위함.
enum WarningStatus {
  ok, // 발효 중 특보 있음
  noWarnings, // 정상 조회, 발효 특보 없음
  noKey, // 서비스 키 미설정
  authError, // 키 오류(미등록/만료/한도초과)
  blockedOnWeb, // 웹 CORS 차단 추정
  networkError, // 네트워크/타임아웃
  apiError, // 기타 API 오류(resultCode != 00)
}

/// 발효 중인 기상특보 한 건.
class WeatherWarning {
  final String hazard; // 호우, 강풍, 대설, 폭염 ...
  final String level; // 주의보 / 경보
  final String region; // 매칭된 지역 텍스트

  const WeatherWarning({
    required this.hazard,
    required this.level,
    required this.region,
  });

  String get title => '$hazard$level';
  bool get isCritical => level.contains('경보');
}

/// 특보 조회 결과 래퍼(상태 + 진단 정보 포함).
class WeatherWarningResult {
  final WarningStatus status;
  final List<WeatherWarning> warnings; // 우리 지역 매칭 특보
  final String? bulletin; // 통보문 원문(지역 매칭 실패 시 실제정보 표시용)
  final int? httpStatus; // 마지막 HTTP 상태코드
  final String? resultCode; // data.go.kr resultCode
  final String? resultMsg; // data.go.kr resultMsg / 오류 사유
  final String? detail; // 사람이 읽는 추가 설명

  const WeatherWarningResult({
    required this.status,
    this.warnings = const [],
    this.bulletin,
    this.httpStatus,
    this.resultCode,
    this.resultMsg,
    this.detail,
  });

  bool get isOk => status == WarningStatus.ok;
  bool get hasContent =>
      warnings.isNotEmpty || (bulletin != null && bulletin!.isNotEmpty);
}

/// 내부: HTTP 응답 + 파싱 결과.
class _ApiResponse {
  final int statusCode;
  final String body;
  final dynamic json; // Map/List or null
  const _ApiResponse(this.statusCode, this.body, this.json);
}

class WeatherWarningService {
  WeatherWarningService({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;
  final Duration timeout = const Duration(seconds: 12);

  /// data.go.kr 서비스 키(Encoding 키 권장).
  static const String serviceKey =
      String.fromEnvironment('KMA_SERVICE_KEY', defaultValue: '');

  /// 웹 CORS 우회 프록시. 빈 값이면 우회하지 않음(모바일은 사용 안 함).
  /// allorigins 기본값 — 자체 프록시가 있으면 --dart-define=CORS_PROXY 로 교체 권장.
  static const String corsProxy = String.fromEnvironment(
    'CORS_PROXY',
    defaultValue: 'https://api.allorigins.win/raw?url=',
  );

  static const String _base =
      'https://apis.data.go.kr/1360000/WthrWrnInfoService';

  bool get hasKey => serviceKey.isNotEmpty;

  /// 쿼리에 안전하게 넣기 위한 키. 이미 인코딩된(Encoding) 키면 그대로 두고,
  /// 원본(Decoding) 키면 URL 인코딩한다.
  String get _encodedKey =>
      serviceKey.contains('%') ? serviceKey : Uri.encodeComponent(serviceKey);

  static const List<String> _hazards = [
    '폭풍해일', '지진해일', '호우', '대설', '강풍', '풍랑', //
    '한파', '폭염', '건조', '황사', '안개', '태풍',
  ];

  /// 발효 중인 특보 조회.
  /// [regionKeywords] 예: ['서울', '관악구'].  [stnId] 109 = 서울지방기상청.
  Future<WeatherWarningResult> fetchActive({
    required List<String> regionKeywords,
    String stnId = '109',
    DateTime? now,
  }) async {
    if (!hasKey) {
      return const WeatherWarningResult(
        status: WarningStatus.noKey,
        detail: '기상청 서비스 키(KMA_SERVICE_KEY)가 설정되지 않았습니다.',
      );
    }

    try {
      final current = now ?? DateTime.now();
      // 기상특보 조회는 '오늘 기준 6일 전까지'만 허용 → 5일 창으로 안전하게.
      // 발표시각 파라미터는 yyyyMMdd(8자리). 12자리(yyyyMMddHHmm)는 DB_ERROR(02).
      final from = _fmt(current.subtract(const Duration(days: 5)));
      final to = _fmt(current);

      // 1단계: 최근 발표 목록
      final listUrl = '$_base/getWthrWrnList'
          '?serviceKey=$_encodedKey&dataType=JSON&numOfRows=20&pageNo=1'
          '&stnId=$stnId&fromTmFc=$from&toTmFc=$to';
      final listRes = await _get(listUrl);
      final listErr = _detectError(listRes);
      if (listErr != null) return listErr;

      final latest = _latest(_extractItems(listRes.json));
      if (latest == null) {
        return WeatherWarningResult(
          status: WarningStatus.noWarnings,
          httpStatus: listRes.statusCode,
          resultCode: '00',
          detail: '최근 3일간 발표된 특보가 없습니다.',
        );
      }

      // 2단계: 통보문 전문
      final msgUrl = '$_base/getWthrWrnMsg'
          '?serviceKey=$_encodedKey&dataType=JSON&numOfRows=10&pageNo=1'
          '&stnId=$stnId&tmFc=${latest.tmFc}'
          '${latest.tmSeq.isNotEmpty ? '&tmSeq=${latest.tmSeq}' : ''}';
      final msgRes = await _get(msgUrl);
      final msgErr = _detectError(msgRes);
      if (msgErr != null) return msgErr;

      final bulletin = _bulletin(_extractItems(msgRes.json));
      if (bulletin == null || bulletin.trim().isEmpty) {
        return WeatherWarningResult(
          status: WarningStatus.noWarnings,
          httpStatus: msgRes.statusCode,
          resultCode: '00',
          detail: '발효 중인 특보가 없습니다.',
        );
      }

      final warnings = parseBulletin(bulletin, regionKeywords);
      return WeatherWarningResult(
        status: WarningStatus.ok,
        warnings: warnings,
        bulletin: warnings.isEmpty ? bulletin.trim() : null,
        httpStatus: 200,
        resultCode: '00',
      );
    } on TimeoutException {
      return const WeatherWarningResult(
        status: WarningStatus.networkError,
        detail: '기상청 서버 응답 시간이 초과되었습니다.',
      );
    } catch (e) {
      // 웹에서의 fetch 실패는 대개 CORS 차단이다.
      if (kIsWeb) {
        return WeatherWarningResult(
          status: WarningStatus.blockedOnWeb,
          detail: '웹 브라우저의 CORS 정책으로 기상청 API 호출이 차단되었습니다. '
              'CORS 프록시(현재: ${corsProxy.isEmpty ? '없음' : corsProxy})가 응답하지 않거나 '
              '차단되었습니다. 모바일 앱에서는 직접 호출되어 정상 동작합니다.',
        );
      }
      return WeatherWarningResult(
        status: WarningStatus.networkError,
        detail: '네트워크 오류: $e',
      );
    }
  }

  // ── HTTP ──────────────────────────────────────────────────────────
  Future<_ApiResponse> _get(String rawUrl) async {
    final url = kIsWeb && corsProxy.isNotEmpty
        ? '$corsProxy${Uri.encodeComponent(rawUrl)}'
        : rawUrl;
    final res = await _client.get(Uri.parse(url)).timeout(timeout);
    final body = res.bodyBytes.isEmpty ? '' : utf8.decode(res.bodyBytes);
    dynamic json;
    final trimmed = body.trimLeft();
    if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
      try {
        json = jsonDecode(body);
      } catch (_) {
        json = null;
      }
    }
    return _ApiResponse(res.statusCode, body, json);
  }

  /// data.go.kr 표준 오류를 감지해 적절한 결과로 변환. 정상이면 null.
  WeatherWarningResult? _detectError(_ApiResponse res) {
    // 인증 단계 오류는 평문/XML 로 온다.
    final upper = res.body.toUpperCase();
    String? reasonCode;
    final m = RegExp(r'<returnReasonCode>(\d+)</returnReasonCode>')
        .firstMatch(res.body);
    if (m != null) reasonCode = m.group(1);

    bool contains(String s) => upper.contains(s);

    if (res.statusCode == 401 ||
        res.statusCode == 403 ||
        contains('SERVICE_KEY_IS_NOT_REGISTERED') ||
        contains('UNAUTHORIZED') ||
        reasonCode == '30') {
      return WeatherWarningResult(
        status: WarningStatus.authError,
        httpStatus: res.statusCode,
        resultCode: reasonCode ?? '30',
        resultMsg: 'SERVICE_KEY_IS_NOT_REGISTERED',
        detail: '서비스 키가 등록되지 않았거나 올바르지 않습니다. '
            '공공데이터포털에서 발급한 일반 인증키(Encoding)인지 확인하세요.',
      );
    }
    if (contains('LIMITED_NUMBER_OF_SERVICE_REQUESTS') || reasonCode == '22') {
      return WeatherWarningResult(
        status: WarningStatus.authError,
        httpStatus: res.statusCode,
        resultCode: '22',
        resultMsg: 'LIMITED_NUMBER_OF_SERVICE_REQUESTS',
        detail: '일일 트래픽 한도를 초과했습니다. 잠시 후 다시 시도하세요.',
      );
    }
    if (contains('SERVICE_KEY_IS_NOT_REGISTERED') || reasonCode == '31') {
      return WeatherWarningResult(
        status: WarningStatus.authError,
        httpStatus: res.statusCode,
        resultCode: '31',
        detail: '서비스 키 활용 기간이 만료되었습니다.',
      );
    }

    // JSON 헤더 resultCode 확인
    final resp = res.json is Map ? res.json['response'] : null;
    final header = resp is Map ? resp['header'] : null;
    if (header is Map) {
      final code = header['resultCode']?.toString();
      final msg = header['resultMsg']?.toString();
      if (code == '00') return null; // 정상
      if (code == '03') {
        return WeatherWarningResult(
          status: WarningStatus.noWarnings,
          httpStatus: res.statusCode,
          resultCode: '03',
          resultMsg: msg,
          detail: '조회된 특보 데이터가 없습니다(NODATA).',
        );
      }
      if (code == '30' || code == '31') {
        return WeatherWarningResult(
          status: WarningStatus.authError,
          httpStatus: res.statusCode,
          resultCode: code,
          resultMsg: msg,
          detail: '서비스 키 오류입니다($msg).',
        );
      }
      if (code != null) {
        return WeatherWarningResult(
          status: WarningStatus.apiError,
          httpStatus: res.statusCode,
          resultCode: code,
          resultMsg: msg,
          detail: '기상청 API 오류($code): $msg',
        );
      }
    }

    // 200 인데 JSON 도 아니고 알 수 없는 형식
    if (res.statusCode == 200 && res.json == null) {
      return WeatherWarningResult(
        status: WarningStatus.apiError,
        httpStatus: 200,
        detail: '예상치 못한 응답 형식입니다.',
      );
    }
    if (res.statusCode != 200) {
      return WeatherWarningResult(
        status: WarningStatus.apiError,
        httpStatus: res.statusCode,
        detail: 'HTTP ${res.statusCode} 오류',
      );
    }
    return null;
  }

  List<Map<String, dynamic>> _extractItems(dynamic json) {
    final response = json is Map ? json['response'] : null;
    final body = response is Map ? response['body'] : null;
    final items = body is Map ? body['items'] : null;
    final item = items is Map ? items['item'] : null;
    if (item is List) {
      return item
          .whereType<Map>()
          .map((e) => e.cast<String, dynamic>())
          .toList();
    }
    if (item is Map) return [item.cast<String, dynamic>()];
    return const [];
  }

  _Announcement? _latest(List<Map<String, dynamic>> items) {
    _Announcement? best;
    for (final it in items) {
      final tmFc = _str(it['tmFc']);
      if (tmFc.isEmpty) continue;
      final a = _Announcement(tmFc: tmFc, tmSeq: _str(it['tmSeq']));
      if (best == null || a.tmFc.compareTo(best.tmFc) > 0) best = a;
    }
    return best;
  }

  String? _bulletin(List<Map<String, dynamic>> items) {
    for (final it in items) {
      final t6 = _str(it['t6']);
      if (t6.isNotEmpty) return t6;
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
    final re = RegExp('(${_hazards.join('|')})\\s*(주의보|경보)');

    for (final rawLine in bulletin.split(RegExp(r'[\n\r]+'))) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;
      final m = re.firstMatch(line);
      if (m == null) continue;
      if (!regionKeywords.any((k) => k.isNotEmpty && line.contains(k))) {
        continue;
      }
      final hazard = m.group(1)!;
      final level = m.group(2)!;
      if (seen.add('$hazard$level')) {
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

  static String _str(dynamic v) => v == null ? '' : v.toString();

  /// yyyyMMdd (기상특보 조회 fromTmFc/toTmFc 형식)
  static String _fmt(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}${two(d.month)}${two(d.day)}';
  }

  void dispose() => _client.close();
}

class _Announcement {
  final String tmFc;
  final String tmSeq;
  const _Announcement({required this.tmFc, required this.tmSeq});
}
