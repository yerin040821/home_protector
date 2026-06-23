// lib/services/kma_daily_service.dart
//
// 캘린더의 '월간 실측 강수량' — 기상청 ASOS 일자료.
//
// ⚠️ 기상청(data.go.kr)은 CORS 미지원이라 웹에서 직접 호출할 수 없고, 키를 클라이언트에
//    심으면 노출된다. 그래서 클라이언트가 직접 호출하지 않고 **백엔드 프록시**
//    (`GET {FLOOD_API_BASE_URL}/api/weather/asos-monthly`)를 통해 받는다.
//    KMA 키는 백엔드(Vercel) 환경변수에만 존재한다. 웹/모바일 모두 동일하게 동작.
import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'flood_api_service.dart' show FloodApiService;

enum DailyStatus {
  ok,
  noKey, // 백엔드에 KMA 키 미설정(503)
  forbidden, // 백엔드 키가 해당 서비스 미신청(503/403)
  networkError,
  apiError,
  noData,
}

/// 한 달치 일강수량 결과.
class MonthlyRain {
  final DailyStatus status;
  final Map<int, double> rainByDay; // 일(1~31) → 강수량(mm)
  final int? httpStatus;
  final String? resultCode;
  final String? detail;

  const MonthlyRain({
    required this.status,
    this.rainByDay = const {},
    this.httpStatus,
    this.resultCode,
    this.detail,
  });

  bool get isOk => status == DailyStatus.ok;

  /// 강수량(mm) → 침수 위험 백분율(실측 강우 기반 단순 환산).
  static int riskPercentFor(double rainMm) {
    if (rainMm <= 0) return 0;
    // 80mm/일 이상이면 위험(≈90%), 로그 형태로 완만히 증가.
    final pct = (rainMm * 1.1 + 8).clamp(5.0, 95.0);
    return pct.round();
  }
}

class KmaDailyService {
  KmaDailyService({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? FloodApiService.defaultBaseUrl;

  final http.Client _client;
  final String _baseUrl;
  final Duration timeout = const Duration(seconds: 12);

  // 키는 백엔드에 있으므로 클라이언트는 항상 시도한다.
  bool get hasKey => true;

  /// [year]/[month] 한 달치 일강수량. [stnId] 108 = 서울.
  Future<MonthlyRain> fetchMonth(int year, int month,
      {String stnId = '108'}) async {
    final uri = Uri.parse('$_baseUrl/api/weather/asos-monthly').replace(
      queryParameters: {
        'year': '$year',
        'month': '$month',
        'stn': stnId,
      },
    );

    try {
      final res = await _client.get(uri).timeout(timeout);
      final body = res.bodyBytes.isEmpty ? '' : utf8.decode(res.bodyBytes);
      final decoded = body.isEmpty ? null : jsonDecode(body);

      if (res.statusCode == 503) {
        final detail = decoded is Map ? decoded['detail']?.toString() : null;
        // 키 미설정 vs 미신청을 메시지로 구분.
        final forbidden = (detail ?? '').contains('활용신청') ||
            (detail ?? '').contains('403');
        return MonthlyRain(
          status: forbidden ? DailyStatus.forbidden : DailyStatus.noKey,
          httpStatus: 503,
          detail: detail ??
              '백엔드에 기상청 키(KMA_SERVICE_KEY)가 설정되지 않았습니다.',
        );
      }
      if (res.statusCode != 200 || decoded is! Map) {
        final detail = decoded is Map ? decoded['detail']?.toString() : null;
        return MonthlyRain(
          status: DailyStatus.apiError,
          httpStatus: res.statusCode,
          detail: detail ?? '강수량을 불러오지 못했습니다 (HTTP ${res.statusCode}).',
        );
      }

      final map = decoded['rain_by_day'];
      final rain = <int, double>{};
      if (map is Map) {
        map.forEach((k, v) {
          final day = int.tryParse(k.toString());
          final mm = (v is num) ? v.toDouble() : double.tryParse('$v');
          if (day != null && mm != null) rain[day] = mm;
        });
      }

      if (rain.isEmpty) {
        return MonthlyRain(
          status: DailyStatus.noData,
          httpStatus: res.statusCode,
          detail: '해당 기간 관측 데이터가 없습니다.',
        );
      }
      return MonthlyRain(
          status: DailyStatus.ok, rainByDay: rain, httpStatus: res.statusCode);
    } on TimeoutException {
      return const MonthlyRain(
          status: DailyStatus.networkError, detail: '응답 시간이 초과되었습니다.');
    } catch (e) {
      return MonthlyRain(
          status: DailyStatus.networkError, detail: '네트워크 오류로 강수량을 불러오지 못했습니다.');
    }
  }

  void dispose() => _client.close();
}
