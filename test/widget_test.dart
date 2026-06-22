import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';

import 'package:home_protector/main.dart';
import 'package:home_protector/providers/app_provider.dart';
import 'package:home_protector/services/flood_api_service.dart';
import 'package:home_protector/services/weather_warning_service.dart';

/// 실제 네트워크 없이 결정적으로 동작하도록 API 응답을 모킹한다.
FloodApiService _fakeApi() {
  final client = MockClient((request) async {
    const jsonHeaders = {'content-type': 'application/json; charset=utf-8'};
    if (request.url.path.endsWith('/api/dongs')) {
      return http.Response(
        jsonEncode([
          {'adm_cd': 1162010200, 'gu': '관악구', 'dong': '신림동'},
        ]),
        200,
        headers: jsonHeaders,
      );
    }
    if (request.url.path.endsWith('/api/predict')) {
      return http.Response(
        jsonEncode({
          'adm_cd': 1162010200,
          'gu': '관악구',
          'dong': '신림동',
          'flood_probability': 0.0765,
        }),
        200,
        headers: jsonHeaders,
      );
    }
    return http.Response('{"status":"ok"}', 200, headers: jsonHeaders);
  });
  return FloodApiService(client: client);
}

void main() {
  testWidgets('HomeProtector app launches smoke test', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppProvider(api: _fakeApi()),
        child: const HomeProtectorApp(),
      ),
    );
    // 스플래시 애니메이션·지연 타이머를 흘려보낸다.
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('HomeProtector'), findsWidgets);
  });

  group('FloodApiService', () {
    test('predict 200 → PredictResult 파싱', () async {
      final api = FloodApiService(
        client: MockClient((req) async => http.Response(
              jsonEncode({
                'adm_cd': 1135010600,
                'gu': '노원구',
                'dong': '중계동',
                'flood_probability': 0.7473,
              }),
              200,
              headers: {'content-type': 'application/json; charset=utf-8'},
            )),
      );
      final r = await api
          .predict(admCd: 1135010600, forecastDailyRain: [5, 40, 60, 100]);
      expect(r.gu, '노원구');
      expect(r.dong, '중계동');
      expect(r.percent, 75);
    });

    test('predict 404 → CoverageException', () async {
      final api = FloodApiService(
        client: MockClient((req) async => http.Response(
              jsonEncode({'detail': 'dong not resolved'}),
              404,
              headers: {'content-type': 'application/json; charset=utf-8'},
            )),
      );
      expect(
        () => api.predict(address: '광주 남구 주월동', forecastDailyRain: [10]),
        throwsA(isA<CoverageException>()),
      );
    });

    test('dongs 200 → DongInfo 목록 파싱', () async {
      final api = FloodApiService(
        client: MockClient((req) async => http.Response(
              jsonEncode([
                {'adm_cd': 1162010200, 'gu': '관악구', 'dong': '신림동'},
                {'adm_cd': 1114013200, 'gu': '중구', 'dong': null},
              ]),
              200,
              headers: {'content-type': 'application/json; charset=utf-8'},
            )),
      );
      final list = await api.dongs();
      expect(list, hasLength(2));
      expect(list.first.label, '관악구 신림동');
      expect(list.last.label, '중구'); // dong 없음 → 구만
    });
  });

  group('WeatherWarningService.parseBulletin', () {
    const bulletin = '''
o 1. 특보 발효 현황 (2026.06.22.15:00 현재)
 - 호우주의보 : 서울특별시(관악구, 동작구, 영등포구), 경기도(부천시)
 - 강풍주의보 : 인천광역시(중구), 인천광역시(옹진군)
 - 폭염경보 : 대구광역시
''';

    test('지역(관악구) 매칭 특보만 추출', () {
      final w = WeatherWarningService.parseBulletin(bulletin, ['서울', '관악구']);
      expect(w, hasLength(1));
      expect(w.first.title, '호우주의보');
      expect(w.first.isCritical, isFalse);
    });

    test('매칭 지역 없으면 빈 목록', () {
      final w = WeatherWarningService.parseBulletin(bulletin, ['부산', '해운대구']);
      expect(w, isEmpty);
    });

    test('경보는 critical 로 분류', () {
      final w = WeatherWarningService.parseBulletin(bulletin, ['대구']);
      expect(w.single.title, '폭염경보');
      expect(w.single.isCritical, isTrue);
    });
  });
}
