// lib/services/kma_daily_service.dart
//
// 기상청(KMA) 지상(종관)기상관측 일자료 — 캘린더의 '월간 실측 강수량'에 사용.
// 공공데이터포털 "기상청_지상(종관, ASOS) 일자료 조회서비스"(AsosDalyInfoService):
//   GET /getWthrDataList  (dataCd=ASOS, dateCd=DAY, stnIds=108=서울)
//   item.tm = 'YYYY-MM-DD', item.sumRn = 일강수량(mm, 없으면 빈 문자열)
//
// ⚠️ 기상특보 서비스와 별개로 '활용신청'이 필요하다(미신청 시 403 Forbidden).
//    같은 KMA_SERVICE_KEY 로 동작한다.  웹은 CORS 프록시 경유.
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

enum DailyStatus {
  ok,
  noKey,
  forbidden, // 403 — 해당 서비스 미구독
  blockedOnWeb, // 웹 CORS
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
  KmaDailyService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  final Duration timeout = const Duration(seconds: 12);

  static const String serviceKey =
      String.fromEnvironment('KMA_SERVICE_KEY', defaultValue: '');
  // 웹 CORS 우회 프록시. 기본 빈 값(공개 프록시 불안정). 자체 프록시는 --dart-define=CORS_PROXY.
  static const String corsProxy =
      String.fromEnvironment('CORS_PROXY', defaultValue: '');
  static const String _base =
      'https://apis.data.go.kr/1360000/AsosDalyInfoService';

  bool get hasKey => serviceKey.isNotEmpty;

  String get _encodedKey =>
      serviceKey.contains('%') ? serviceKey : Uri.encodeComponent(serviceKey);

  /// [year]/[month] 한 달치 일강수량. [stnId] 108 = 서울.
  Future<MonthlyRain> fetchMonth(int year, int month, {String stnId = '108'}) async {
    if (!hasKey) {
      return const MonthlyRain(
        status: DailyStatus.noKey,
        detail: '기상청 서비스 키(KMA_SERVICE_KEY)가 설정되지 않았습니다.',
      );
    }

    // 웹 + 프록시 미설정이면 즉시 모바일 전용 안내.
    if (kIsWeb && corsProxy.isEmpty) {
      return const MonthlyRain(
        status: DailyStatus.blockedOnWeb,
        detail: '월간 실측 강수량은 모바일 앱(Android/iOS)에서만 제공됩니다.\n'
            '웹은 기상청 API의 CORS 정책으로 차단됩니다(자체 CORS_PROXY 설정 시 가능).',
      );
    }

    final lastDay = DateTime(year, month + 1, 0).day;
    final start = _ymd(year, month, 1);
    final end = _ymd(year, month, lastDay);
    final rawUrl = '$_base/getWthrDataList'
        '?serviceKey=$_encodedKey&pageNo=1&numOfRows=40&dataType=JSON'
        '&dataCd=ASOS&dateCd=DAY&startDt=$start&endDt=$end&stnIds=$stnId';

    try {
      final url = kIsWeb && corsProxy.isNotEmpty
          ? '$corsProxy${Uri.encodeComponent(rawUrl)}'
          : rawUrl;
      final res = await _client.get(Uri.parse(url)).timeout(timeout);
      final body = res.bodyBytes.isEmpty ? '' : utf8.decode(res.bodyBytes);

      if (res.statusCode == 403 || body.toUpperCase().contains('FORBIDDEN')) {
        return MonthlyRain(
          status: DailyStatus.forbidden,
          httpStatus: 403,
          detail: '이 키는 기상청 "지상관측 일자료" 서비스에 활용신청되어 있지 않습니다.\n'
              '공공데이터포털에서 해당 서비스를 추가 신청하면 같은 키로 동작합니다.',
        );
      }

      final trimmed = body.trimLeft();
      if (!trimmed.startsWith('{') && !trimmed.startsWith('[')) {
        // 인증 오류(평문/XML) 등
        final auth = RegExp(r'<returnAuthMsg>([^<]*)</returnAuthMsg>')
            .firstMatch(body)
            ?.group(1);
        return MonthlyRain(
          status: DailyStatus.apiError,
          httpStatus: res.statusCode,
          detail: auth ?? '예상치 못한 응답 형식입니다.',
        );
      }

      final json = jsonDecode(body);
      final response = json is Map ? json['response'] : null;
      final header = response is Map ? response['header'] : null;
      final code = header is Map ? header['resultCode']?.toString() : null;
      final msg = header is Map ? header['resultMsg']?.toString() : null;

      if (code == '03') {
        return MonthlyRain(
          status: DailyStatus.noData,
          httpStatus: res.statusCode,
          resultCode: '03',
          detail: '해당 기간 관측 데이터가 없습니다.',
        );
      }
      if (code != null && code != '00') {
        return MonthlyRain(
          status:
              (code == '30' || code == '31') ? DailyStatus.forbidden : DailyStatus.apiError,
          httpStatus: res.statusCode,
          resultCode: code,
          detail: '기상청 API 오류($code): $msg',
        );
      }

      final body2 = response is Map ? response['body'] : null;
      final items = body2 is Map ? body2['items'] : null;
      final item = items is Map ? items['item'] : null;
      final list = item is List
          ? item
          : item is Map
              ? [item]
              : const [];

      final rain = <int, double>{};
      for (final e in list) {
        if (e is! Map) continue;
        final tm = e['tm']?.toString() ?? ''; // YYYY-MM-DD
        final day = int.tryParse(tm.split('-').length == 3 ? tm.split('-')[2] : '');
        if (day == null) continue;
        final sum = double.tryParse((e['sumRn']?.toString() ?? '').trim());
        rain[day] = sum ?? 0.0;
      }

      if (rain.isEmpty) {
        return MonthlyRain(
          status: DailyStatus.noData,
          httpStatus: res.statusCode,
          detail: '관측 데이터가 비어 있습니다.',
        );
      }
      return MonthlyRain(
          status: DailyStatus.ok, rainByDay: rain, httpStatus: res.statusCode);
    } on TimeoutException {
      return const MonthlyRain(
          status: DailyStatus.networkError, detail: '응답 시간이 초과되었습니다.');
    } catch (e) {
      if (kIsWeb) {
        return MonthlyRain(
          status: DailyStatus.blockedOnWeb,
          detail: corsProxy.isEmpty
              ? '웹은 CORS 정책으로 기상청 API를 직접 호출할 수 없습니다. 모바일 앱에서 정상 동작합니다. '
                  '(웹은 자체 CORS 프록시를 --dart-define=CORS_PROXY 로 설정)'
              : 'CORS 프록시($corsProxy)가 응답하지 않습니다. 모바일 앱을 권장합니다.',
        );
      }
      return MonthlyRain(status: DailyStatus.networkError, detail: '네트워크 오류: $e');
    }
  }

  static String _ymd(int y, int m, int d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '$y${two(m)}${two(d)}';
  }

  void dispose() => _client.close();
}
