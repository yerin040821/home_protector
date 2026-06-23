// lib/services/flood_api_service.dart
//
// Ready-Flow AI · Seoul Flood Risk API 클라이언트.
// OpenAPI 명세(https://ready-flow-ai.vercel.app/docs)와 1:1로 대응한다.
//
//   GET  /api/health   → 서비스 상태 + 커버리지 동 수
//   POST /api/predict  → 침수 확률 예측 (flood_probability ∈ [0,1])
//   GET  /api/dongs    → 예측 가능한 93개 법정동 목록 (주소 선택 UI용)
//
// 인증 토큰이 필요 없는 공개 API다.
import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// 예측 가능한 법정동 한 건. `/api/dongs` 응답 요소.
class DongInfo {
  final int admCd; // 10자리 법정동코드
  final String gu; // 자치구 (예: 관악구)
  final String? dong; // 동 라벨 (없을 수 있음)

  const DongInfo({required this.admCd, required this.gu, this.dong});

  factory DongInfo.fromJson(Map<String, dynamic> json) => DongInfo(
        admCd: (json['adm_cd'] as num).toInt(),
        gu: json['gu'] as String? ?? '',
        dong: json['dong'] as String?,
      );

  /// 사람이 읽는 라벨. 동 정보가 없으면 구만 노출한다.
  String get label => dong == null || dong!.isEmpty ? gu : '$gu $dong';

  /// 지도/지오코딩에 넘길 전체 주소 문자열.
  String get fullAddress => '서울특별시 $label';
}

/// `/api/predict` 200 응답.
class PredictResult {
  final int admCd;
  final String gu;
  final String? dong;
  final double floodProbability; // [0,1]

  const PredictResult({
    required this.admCd,
    required this.gu,
    this.dong,
    required this.floodProbability,
  });

  factory PredictResult.fromJson(Map<String, dynamic> json) => PredictResult(
        admCd: (json['adm_cd'] as num).toInt(),
        gu: json['gu'] as String? ?? '',
        dong: json['dong'] as String?,
        floodProbability: (json['flood_probability'] as num).toDouble(),
      );

  /// 0~100 정수 백분율.
  int get percent => (floodProbability * 100).round();
}

/// 커버리지 밖(404) 또는 동 미해결 시 던지는 예외.
class CoverageException implements Exception {
  final String message;
  const CoverageException(this.message);
  @override
  String toString() => message;
}

/// 그 외 API/네트워크 오류.
class FloodApiException implements Exception {
  final String message;
  final int? statusCode;
  const FloodApiException(this.message, {this.statusCode});
  @override
  String toString() => message;
}

class FloodApiService {
  FloodApiService({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        baseUrl = baseUrl ?? defaultBaseUrl;

  /// 기본 베이스 URL. `--dart-define=FLOOD_API_BASE_URL=...` 로 덮어쓸 수 있다.
  static const String defaultBaseUrl = String.fromEnvironment(
    'FLOOD_API_BASE_URL',
    defaultValue: 'https://ready-flow-ai.vercel.app',
  );

  final http.Client _client;
  final String baseUrl;
  final Duration timeout = const Duration(seconds: 12);

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  /// 헬스체크. 실패 시 false.
  Future<bool> health() async {
    try {
      final res = await _client.get(_uri('/api/health')).timeout(timeout);
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// 예측 가능한 법정동 목록. 자동완성/선택 UI용.
  Future<List<DongInfo>> dongs() async {
    try {
      final res = await _client.get(_uri('/api/dongs')).timeout(timeout);
      if (res.statusCode != 200) {
        throw FloodApiException('동 목록을 불러오지 못했습니다.',
            statusCode: res.statusCode);
      }
      final body = jsonDecode(utf8.decode(res.bodyBytes)) as List<dynamic>;
      return body
          .map((e) => DongInfo.fromJson(e as Map<String, dynamic>))
          .toList();
    } on FloodApiException {
      rethrow;
    } catch (e) {
      throw FloodApiException('네트워크 오류로 동 목록을 불러오지 못했습니다.');
    }
  }

  /// 침수 확률 예측.
  ///
  /// [admCd] 를 주면 지오코딩을 건너뛰어 항상 해결되므로 우선 사용한다.
  /// 없으면 [address] 문자열로 법정동을 해석한다(커버리지 밖이면 404).
  /// [forecastDailyRain] 은 과거→오늘 순서의 일강우(mm) 시퀀스(1~30개, 필수).
  Future<PredictResult> predict({
    int? admCd,
    String? address,
    required List<double> forecastDailyRain,
    String? buildingType,
  }) async {
    assert(forecastDailyRain.isNotEmpty && forecastDailyRain.length <= 30,
        'forecast_daily_rain must contain 1..30 values');

    final payload = <String, dynamic>{
      'forecast_daily_rain': forecastDailyRain,
      'adm_cd': ?admCd,
      if (address != null && address.isNotEmpty) 'address': address,
      'building_type': ?buildingType,
    };

    final http.Response res;
    try {
      res = await _client
          .post(
            _uri('/api/predict'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(timeout);
    } catch (e) {
      throw FloodApiException('네트워크 오류로 예측에 실패했습니다.');
    }

    final decoded = res.bodyBytes.isEmpty
        ? const <String, dynamic>{}
        : jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;

    switch (res.statusCode) {
      case 200:
        return PredictResult.fromJson(decoded);
      case 404:
        throw CoverageException(
            decoded['detail']?.toString() ?? '커버리지 밖 지역입니다.');
      case 422:
        throw const FloodApiException('요청 형식이 올바르지 않습니다.', statusCode: 422);
      default:
        throw FloodApiException('예측 서버 오류 (${res.statusCode})',
            statusCode: res.statusCode);
    }
  }

  void dispose() => _client.close();
}
