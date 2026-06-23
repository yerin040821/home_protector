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

/// 사용자가 입력한 주소 문자열을 Ready-Flow 커버리지 동으로 매칭한다.
///
/// 예: "신림동 31-21" → `/api/dongs` 안의 "관악구 신림동".
List<DongInfo> matchingDongsForAddressInput(
  String input,
  List<DongInfo> coverage,
) {
  final query = _compactKoreanAddress(input);
  if (query.isEmpty) return const [];

  final guMatches = coverage.where((d) => query.contains(_compact(d.gu)));
  final dongMatches = coverage.where((d) {
    final dong = d.dong;
    return dong != null && dong.isNotEmpty && query.contains(_compact(dong));
  }).toList()
    ..sort((a, b) => (b.dong?.length ?? 0).compareTo(a.dong?.length ?? 0));

  if (dongMatches.isNotEmpty) {
    final guSet = guMatches.map((d) => d.admCd).toSet();
    final exactInGu =
        dongMatches.where((d) => guSet.isEmpty || guSet.contains(d.admCd));
    final exact = exactInGu.toList();
    if (exact.isNotEmpty) return _dedupeDongs(exact);
    return _dedupeDongs(dongMatches);
  }

  return _dedupeDongs(
    coverage.where((d) {
      final compactLabel = _compact(d.label);
      final compactDong = _compact(d.dong ?? '');
      return compactLabel.contains(query) ||
          query.contains(compactLabel) ||
          (compactDong.isNotEmpty && compactDong.contains(query)) ||
          _compact(d.gu).contains(query);
    }),
  );
}

DongInfo? resolveDongFromAddressInput(String input, List<DongInfo> coverage) {
  final matches = matchingDongsForAddressInput(input, coverage);
  return matches.length == 1 ? matches.single : null;
}

/// 주소 SDK 가 준 (구, 법정동)을 예측 커버리지의 한 동으로 해석한 결과.
class CoverageResolution {
  /// 매칭된 커버리지 동(없으면 null = 커버리지 밖).
  final DongInfo? dong;

  /// 사용자의 실제 법정동이 그대로 예측 대상인지(true), 아니면 같은 구의
  /// 인근 지원 동으로 근사한 것인지(false).
  final bool exactDong;

  const CoverageResolution(this.dong, this.exactDong);

  bool get covered => dong != null;
}

/// '구' 라벨 정규화 — 데이터에 '영등포'/'영등포구'가 섞여 있어 끝의 '구'를 떼고 비교.
String _normGu(String gu) {
  final g = gu.trim();
  return g.endsWith('구') ? g.substring(0, g.length - 1) : g;
}

/// 주소 SDK 결과(구·법정동)를 예측 가능한 커버리지 동으로 해석한다.
///
/// 1) 같은 구 안에 같은 법정동이 있으면 그 동(정확 매칭).
/// 2) 없으면 같은 구의 임의 지원 동으로 근사(구 단위 예측).
/// 3) 그 구에 지원 동이 하나도 없으면 커버리지 밖(null).
CoverageResolution resolveCoverageForAddress({
  required String gu,
  required String bname,
  required List<DongInfo> coverage,
}) {
  final ng = _normGu(gu);
  final inGu = coverage.where((d) => _normGu(d.gu) == ng).toList();

  if (bname.isNotEmpty) {
    for (final d in inGu) {
      if (d.dong != null && d.dong == bname) {
        return CoverageResolution(d, true);
      }
    }
    // 동명 고유성 가정 — 구 정보가 어긋나도 같은 동이 있으면 정확 매칭으로 본다.
    for (final d in coverage) {
      if (d.dong != null && d.dong == bname) {
        return CoverageResolution(d, true);
      }
    }
  }

  if (inGu.isNotEmpty) {
    // 라벨이 있는 동을 우선(구 placeholder보다 구체적).
    inGu.sort((a, b) => (b.dong?.length ?? 0).compareTo(a.dong?.length ?? 0));
    return CoverageResolution(inGu.first, false);
  }

  return const CoverageResolution(null, false);
}

String addressForMatchedDong(String input, DongInfo dong) {
  final trimmed = input.trim();
  if (trimmed.isEmpty) return dong.fullAddress;

  final compactInput = _compactKoreanAddress(trimmed);
  final hasGu = compactInput.contains(_compact(dong.gu));
  final hasSeoul = compactInput.contains('서울');
  if (hasGu && hasSeoul) return trimmed;
  if (hasGu) return '서울특별시 $trimmed';
  return '서울특별시 ${dong.gu} $trimmed';
}

String _compactKoreanAddress(String input) {
  return _compact(input)
      .replaceAll('서울특별시', '서울')
      .replaceAll('서울시', '서울');
}

String _compact(String input) =>
    input.replaceAll(RegExp(r'[\s,()\-]+'), '').trim();

List<DongInfo> _dedupeDongs(Iterable<DongInfo> items) {
  final seen = <int>{};
  final result = <DongInfo>[];
  for (final item in items) {
    if (seen.add(item.admCd)) result.add(item);
  }
  return result;
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

class FloodForecastDay {
  final DateTime date;
  final double rainMm;
  final double floodProbability;
  final String? riskLevel;
  final int? riskPercentile;

  const FloodForecastDay({
    required this.date,
    required this.rainMm,
    required this.floodProbability,
    this.riskLevel,
    this.riskPercentile,
  });

  factory FloodForecastDay.fromJson(Map<String, dynamic> json) =>
      FloodForecastDay(
        date: DateTime.parse(json['date'] as String),
        rainMm: (json['rain_mm'] as num? ?? 0).toDouble(),
        floodProbability:
            (json['flood_probability'] as num? ?? 0).toDouble(),
        riskLevel: json['risk_level'] as String?,
        riskPercentile: (json['risk_percentile'] as num?)?.toInt(),
      );

  int get percent => (floodProbability * 100).round();
}

class FloodWeekForecast {
  final List<FloodForecastDay> days;
  final FloodForecastDay? peak;
  final String source;
  final String? detail;

  const FloodWeekForecast({
    required this.days,
    this.peak,
    required this.source,
    this.detail,
  });

  factory FloodWeekForecast.fromJson(Map<String, dynamic> json) {
    final days = (json['days'] as List<dynamic>? ?? const [])
        .map((e) => FloodForecastDay.fromJson(e as Map<String, dynamic>))
        .toList();
    final peakJson = json['peak'] as Map<String, dynamic>?;
    return FloodWeekForecast(
      days: days,
      peak: peakJson == null ? null : FloodForecastDay.fromJson(peakJson),
      source: json['source'] as String? ?? 'kma',
      detail: json['detail'] as String?,
    );
  }
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

  Future<FloodWeekForecast> forecastWeek({
    required int admCd,
    String? buildingType,
  }) async {
    final uri = _uri('/api/forecast/flood-week').replace(
      queryParameters: {
        'adm_cd': '$admCd',
        'building_type': ?buildingType,
      },
    );

    final http.Response res;
    try {
      res = await _client.get(uri).timeout(timeout);
    } catch (e) {
      throw FloodApiException('네트워크 오류로 주간 예보를 불러오지 못했습니다.');
    }

    final decoded = res.bodyBytes.isEmpty
        ? const <String, dynamic>{}
        : jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    if (res.statusCode == 200) return FloodWeekForecast.fromJson(decoded);
    if (res.statusCode == 404) {
      throw CoverageException(decoded['detail']?.toString() ?? '커버리지 밖 지역입니다.');
    }
    throw FloodApiException(
      decoded['detail']?.toString() ?? '주간 예보를 불러오지 못했습니다.',
      statusCode: res.statusCode,
    );
  }

  void dispose() => _client.close();
}
