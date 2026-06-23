// lib/services/weather_warning_service.dart
//
// 기상청(KMA) 기상특보 — 실시간 특보(호우/강풍/대설 등)만 표시.
//
// ⚠️ data.go.kr 은 CORS 미지원이고 키 노출 위험이 있어 클라이언트가 직접 호출하지 않는다.
//    백엔드 프록시(`GET {FLOOD_API_BASE_URL}/api/weather/warning-bulletin`)가
//    기상청 특보 현황(getPwnStatus) 통보문(t6)을 받아 돌려주면, 여기서는 그 통보문을
//    사용자 지역 키워드로 매칭(parseBulletin)만 한다. 웹/모바일 동일 동작.
import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'flood_api_service.dart' show FloodApiService;

/// 특보 조회 결과 상태 — UI 에서 원인을 상세히 구분해 보여 주기 위함.
enum WarningStatus {
  ok, // 발효 중 특보 있음
  noWarnings, // 정상 조회, 발효 특보 없음
  noKey, // 백엔드 서비스 키 미설정
  authError, // 키 오류(미신청/만료/한도초과)
  blockedOnWeb, // (호환용 — 더 이상 발생하지 않음)
  networkError, // 네트워크/타임아웃
  apiError, // 기타 API 오류
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

class WeatherWarningService {
  WeatherWarningService({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? FloodApiService.defaultBaseUrl;

  final http.Client _client;
  final String _baseUrl;
  final Duration timeout = const Duration(seconds: 12);

  // 키는 백엔드에 있으므로 클라이언트는 항상 시도한다.
  bool get hasKey => true;

  static const List<String> _hazards = [
    '폭풍해일', '지진해일', '호우', '대설', '강풍', '풍랑', //
    '한파', '폭염', '건조', '황사', '안개', '태풍',
  ];

  /// 발효 중인 특보 조회 — 백엔드 프록시 경유.
  /// [regionKeywords] 예: ['서울', '관악구'].  [stnId] 109 = 서울지방기상청.
  Future<WeatherWarningResult> fetchActive({
    required List<String> regionKeywords,
    String stnId = '109',
    DateTime? now,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/weather/warning-bulletin')
        .replace(queryParameters: {'stn': stnId});
    try {
      final res = await _client.get(uri).timeout(timeout);
      final body = res.bodyBytes.isEmpty ? '' : utf8.decode(res.bodyBytes);
      final decoded = body.isEmpty ? null : jsonDecode(body);

      if (res.statusCode == 503) {
        final detail = decoded is Map ? decoded['detail']?.toString() : null;
        final forbidden = (detail ?? '').contains('활용신청') ||
            (detail ?? '').contains('403');
        return WeatherWarningResult(
          status: forbidden ? WarningStatus.authError : WarningStatus.noKey,
          httpStatus: 503,
          detail: detail ??
              '백엔드에 기상청 키(KMA_SERVICE_KEY)가 설정되지 않았습니다.',
        );
      }
      if (res.statusCode != 200 || decoded is! Map) {
        final detail = decoded is Map ? decoded['detail']?.toString() : null;
        return WeatherWarningResult(
          status: WarningStatus.apiError,
          httpStatus: res.statusCode,
          detail: detail ?? '특보를 불러오지 못했습니다 (HTTP ${res.statusCode}).',
        );
      }

      final bulletin = decoded['bulletin']?.toString();
      if (bulletin == null || bulletin.trim().isEmpty) {
        return const WeatherWarningResult(
          status: WarningStatus.noWarnings,
          httpStatus: 200,
          resultCode: '00',
          detail: '현재 발효 중인 기상특보가 없습니다.',
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
        detail: '서버 응답 시간이 초과되었습니다.',
      );
    } catch (e) {
      return const WeatherWarningResult(
        status: WarningStatus.networkError,
        detail: '네트워크 오류로 특보를 불러오지 못했습니다.',
      );
    }
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

  void dispose() => _client.close();
}
