import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/flood_api_service.dart';

/// 앱 전역 상태.
///
/// - 사용자 거주지/건물유형 (지원 지역 = 서울 93개 법정동)
/// - Ready-Flow AI 실시간 침수 확률(`apiPredict`)
/// - 앱 자체 시나리오 위험도(`scenarioProbability`) — 리치 UI 연출용 보조 지표
class AppProvider extends ChangeNotifier {
  AppProvider({FloodApiService? api}) : _api = api ?? FloodApiService() {
    loadCoverage();
    fetchFloodPrediction();
  }

  final FloodApiService _api;

  UserModel _user = const UserModel();
  int _activeTab = 0;
  bool _isLoggedIn = false;
  bool _isSetupDone = false;
  String _toastMessage = '';
  bool _showToast = false;

  // ── Predict API 상태 ──
  PredictResult? _apiPredict;
  bool _isApiLoading = false;
  bool _isCoverageError = false; // 404: 지원하지 않는 지역
  String? _apiError; // 그 외 오류 메시지

  // ── 커버리지(지원 동) 목록 ──
  List<DongInfo> _coverage = const [];
  bool _coverageLoaded = false;

  UserModel get user => _user;
  int get activeTab => _activeTab;
  bool get isLoggedIn => _isLoggedIn;
  bool get isSetupDone => _isSetupDone;
  String get toastMessage => _toastMessage;
  bool get showToast => _showToast;

  PredictResult? get apiPredict => _apiPredict;
  double? get apiFloodProbability => _apiPredict?.floodProbability;
  bool get isApiLoading => _isApiLoading;
  bool get isCoverageError => _isCoverageError;
  String? get apiError => _apiError;

  List<DongInfo> get coverage => _coverage;
  bool get coverageLoaded => _coverageLoaded;

  void login() {
    _isLoggedIn = true;
    notifyListeners();
  }

  void completeSetup(UserModel updated) {
    _user = updated;
    _isSetupDone = true;
    notifyListeners();
    fetchFloodPrediction();
  }

  void logout() {
    _isLoggedIn = false;
    _isSetupDone = false;
    _user = const UserModel();
    _activeTab = 0;
    _apiPredict = null;
    _apiError = null;
    _isCoverageError = false;
    notifyListeners();
  }

  /// 거주지/건물유형 갱신 후 예측 재요청.
  void updateUser(UserModel updated) {
    _user = updated;
    notifyListeners();
    fetchFloodPrediction();
  }

  void setActiveTab(int index) {
    _activeTab = index;
    notifyListeners();
  }

  void triggerToast(String message) => _showToastMessage(message);

  void _showToastMessage(String message) {
    _toastMessage = message;
    _showToast = true;
    notifyListeners();
    Future.delayed(const Duration(seconds: 3), () {
      _showToast = false;
      notifyListeners();
    });
  }

  // ─── 커버리지 동 목록 로드 (주소 선택 모달용) ───
  Future<void> loadCoverage() async {
    if (_coverageLoaded && _coverage.isNotEmpty) return;
    try {
      final list = await _api.dongs();
      _coverage = list;
      _coverageLoaded = true;
      notifyListeners();
    } catch (_) {
      // 실패해도 치명적이지 않음 — 선택 모달이 빈 목록을 안내한다.
      _coverageLoaded = true;
      notifyListeners();
    }
  }

  // ─── 침수 확률 예측 ───

  /// 실시간 예보 일강우 시퀀스(과거→오늘). 데모용 폭우 시나리오.
  List<double> get _forecastDailyRain {
    final w = weatherData;
    return [10.0, 25.0, 60.0, w.precipitation.clamp(5.0, 300.0)];
  }

  Future<void> fetchFloodPrediction() async {
    _isApiLoading = true;
    _apiError = null;
    _isCoverageError = false;
    notifyListeners();

    try {
      _apiPredict = await _api.predict(
        admCd: _user.admCd,
        address: _user.admCd == null ? _user.address : null,
        forecastDailyRain: _forecastDailyRain,
        buildingType: _user.buildingType.apiValue,
      );
      _apiError = null;
      _isCoverageError = false;
    } on CoverageException {
      _apiPredict = null;
      _isCoverageError = true;
    } on FloodApiException catch (e) {
      _apiPredict = null;
      _apiError = e.message;
    } catch (e) {
      _apiPredict = null;
      _apiError = '예측을 불러오지 못했습니다.';
    } finally {
      _isApiLoading = false;
      notifyListeners();
    }
  }

  // ─── 표시용 위험도 ───

  MockWeatherData get weatherData =>
      WeatherDataService.getWeatherData(_user.district);

  /// 앱 자체 시나리오 위험도(%). 리치 UI(경보 배너·게이지·캘린더) 연출용.
  /// 외부 AI 실측치는 [apiFloodProbability] 로 별도 표시한다.
  int get floodProbability => WeatherDataService.calculateFloodProbability(
        weatherData: weatherData,
        buildingType: _user.buildingType.label,
      );

  AlertLevel get alertLevel {
    final prob = floodProbability;
    if (prob >= 80) return AlertLevel.critical;
    if (prob >= 50) return AlertLevel.warning;
    return AlertLevel.info;
  }

  String get alertMessage {
    final prob = floodProbability;
    final name = _user.district.split(' ').last;
    if (prob >= 80) {
      return '🚨 경고: $name 거주자님, 집중호우로 인한 침수 위험도는 $prob%입니다. 차수판을 작동 대기시키고 대피를 준비하세요.';
    } else if (prob >= 50) {
      return '⚠️ 주의: $name 거주자님, 배수 용량 저하로 침수 우려가 있습니다. 모래주머니 비치를 권장합니다 (위험도 $prob%).';
    } else {
      return '🅿️ 알림: $name 지역 지하주차장 차량 대피 권고. 현재 침수 위험도는 $prob%로 안정적입니다.';
    }
  }

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }
}

// ─── 공공 데이터(모킹) 및 시나리오 침수 연산 ───

class MockWeatherData {
  final String districtName;
  final double precipitation; // 강수량 (mm/h)
  final double drainageCapacity; // 면적당 배수 처리량 (mm/h)
  final double elevation; // 해발고도 (m)

  const MockWeatherData({
    required this.districtName,
    required this.precipitation,
    required this.drainageCapacity,
    required this.elevation,
  });
}

class WeatherDataService {
  // 서울 주요 지역의 기상/지형 특성(데모용). 키는 "구 동" 형식.
  static const Map<String, MockWeatherData> _districtDatabase = {
    '관악구 신림동': MockWeatherData(
      districtName: '관악구 신림동',
      precipitation: 48.0, // 폭우 — 2022 침수 피해 지역
      drainageCapacity: 80.0, // 배수 불량
      elevation: 14.0, // 저지대
    ),
    '동작구 상도동': MockWeatherData(
      districtName: '동작구 상도동',
      precipitation: 30.0,
      drainageCapacity: 150.0,
      elevation: 28.0,
    ),
    '강남구 대치동': MockWeatherData(
      districtName: '강남구 대치동',
      precipitation: 35.0,
      drainageCapacity: 120.0,
      elevation: 18.0, // 저지대 + 강남역 상습 침수권
    ),
    '양천구 신월동': MockWeatherData(
      districtName: '양천구 신월동',
      precipitation: 40.0,
      drainageCapacity: 100.0,
      elevation: 16.0,
    ),
    '노원구 중계동': MockWeatherData(
      districtName: '노원구 중계동',
      precipitation: 18.0,
      drainageCapacity: 220.0,
      elevation: 42.0, // 고지대
    ),
  };

  /// "구 동" 또는 전체 주소로 데이터를 조회한다.
  static MockWeatherData getWeatherData(String districtOrAddress) {
    for (final entry in _districtDatabase.entries) {
      if (districtOrAddress.contains(entry.key) ||
          entry.key.contains(districtOrAddress)) {
        return entry.value;
      }
    }
    // 미등록 지역: 서울 평균 가정.
    return const MockWeatherData(
      districtName: '서울 일반 지역',
      precipitation: 22.0,
      drainageCapacity: 160.0,
      elevation: 25.0,
    );
  }

  /// 침수 확률 계산 로직 (수학적 가중치 연산).
  static int calculateFloodProbability({
    required MockWeatherData weatherData,
    required String buildingType,
  }) {
    // 1. 강수량 가중치 (비가 많이 올수록 급격히 위험도 증가)
    final double rainFactor = weatherData.precipitation * 1.6;

    // 2. 배수 성능 영향도 (배수 처리량이 낮을수록 위험도 증가)
    final double drainageFactor =
        (250.0 - weatherData.drainageCapacity).clamp(0.0, 200.0) * 0.3;

    // 3. 해발고도 영향도 (고도가 낮을수록 위험도 증가)
    final double elevationFactor =
        (50.0 - weatherData.elevation).clamp(0.0, 50.0) * 0.8;

    // 건물 유형별 위험 가중치
    double buildingWeight = 1.0;
    if (buildingType == '반지하') {
      buildingWeight = 1.8;
    } else if (buildingType == '1층(저지대)') {
      buildingWeight = 1.3;
    } else if (buildingType == '고층 아파트/빌딩') {
      buildingWeight = 0.4;
    }

    final double baseScore = rainFactor + drainageFactor + elevationFactor;
    final double finalProbability = baseScore * buildingWeight;

    return finalProbability.clamp(5.0, 98.0).round();
  }
}
