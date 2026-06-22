import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';

class AppProvider extends ChangeNotifier {
  UserModel _user = const UserModel();
  int _activeTab = 0;
  bool _isLoggedIn = false;
  bool _isSetupDone = false;
  String _toastMessage = '';
  bool _showToast = false;

  // Predict API State
  double? _apiFloodProbability;
  bool _isApiLoading = false;
  String? _apiError;

  UserModel get user => _user;
  int get activeTab => _activeTab;
  bool get isLoggedIn => _isLoggedIn;
  bool get isSetupDone => _isSetupDone;
  String get toastMessage => _toastMessage;
  bool get showToast => _showToast;

  double? get apiFloodProbability => _apiFloodProbability;
  bool get isApiLoading => _isApiLoading;
  String? get apiError => _apiError;

  AppProvider() {
    fetchFloodPrediction();
  }

  void login() {
    _isLoggedIn = true;
    notifyListeners();
  }

  void completeSetup(String address, BuildingType buildingType) {
    _user = _user.copyWith(
      address: address,
      buildingType: buildingType,
      district: _extractDistrict(address),
    );
    _isSetupDone = true;
    notifyListeners();
    fetchFloodPrediction();
  }

  void logout() {
    _isLoggedIn = false;
    _isSetupDone = false;
    _user = const UserModel();
    _activeTab = 0;
    _apiFloodProbability = null;
    _apiError = null;
    notifyListeners();
  }

  void updateAddressAndBuilding(String address, BuildingType buildingType) {
    _user = _user.copyWith(
      address: address,
      buildingType: buildingType,
      district: _extractDistrict(address),
    );
    notifyListeners();
    fetchFloodPrediction();
  }

  void setActiveTab(int index) {
    _activeTab = index;
    notifyListeners();
  }

  void triggerToast(String message) {
    _showToastMessage(message);
  }

  void _showToastMessage(String message) {
    _toastMessage = message;
    _showToast = true;
    notifyListeners();
    Future.delayed(const Duration(seconds: 3), () {
      _showToast = false;
      notifyListeners();
    });
  }

  String _extractDistrict(String address) {
    List<String> parts = address.split(' ');
    if (parts.length >= 3) {
      return '${parts[parts.length - 2]} ${parts.last}';
    }
    return address;
  }

  // ─── 실시간 공공 데이터 및 침수 연산 예측 연동 ───
  MockWeatherData get weatherData => WeatherDataService.getWeatherData(user.address);

  int get floodProbability {
    if (_apiFloodProbability != null) {
      return (_apiFloodProbability! * 100).round();
    }
    return WeatherDataService.calculateFloodProbability(
      weatherData: weatherData,
      buildingType: user.buildingType.label,
    );
  }

  AlertLevel get alertLevel {
    final prob = floodProbability;
    if (prob >= 80) return AlertLevel.critical;
    if (prob >= 50) return AlertLevel.warning;
    return AlertLevel.info;
  }

  String get alertMessage {
    final prob = floodProbability;
    final name = user.address.contains('주월동') ? '주월동' : '거주자';
    if (prob >= 80) {
      return '🚨 경고: $name 거주자님, 집중 호우로 인한 침수 위험도는 $prob%입니다. 차수 스티커와 차수판 작동을 대기시키십시오.';
    } else if (prob >= 50) {
      return '⚠️ 주의: $name 거주자님, 배수 용량 저하로 침수 우려가 있습니다. 모래주머니 비치 권장 (위험도 $prob%)';
    } else {
      return '🅿️ 알림: 지하주차장 차량 대피 권고. 고층 건물 위험도 $prob%';
    }
  }

  Future<void> fetchFloodPrediction() async {
    _isApiLoading = true;
    _apiError = null;
    notifyListeners();

    try {
      final weather = weatherData;
      final forecastRain = [10.0, 20.0, 50.0, weather.precipitation];

      String apiBuildingType = 'residential';
      if (user.buildingType == BuildingType.semiBasement) {
        apiBuildingType = 'underground';
      }

      final url = Uri.parse('https://ready-flow-ai.vercel.app/api/predict');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'address': user.address,
          'forecast_daily_rain': forecastRain,
          'building_type': apiBuildingType,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _apiFloodProbability = (data['flood_probability'] as num).toDouble();
        _apiError = null;
      } else if (response.statusCode == 404) {
        _apiFloodProbability = null;
        _apiError = 'coverage_error';
      } else {
        _apiFloodProbability = null;
        _apiError = 'API Error: ${response.statusCode}';
      }
    } catch (e) {
      _apiFloodProbability = null;
      _apiError = 'Network error: $e';
    } finally {
      _isApiLoading = false;
      notifyListeners();
    }
  }
}

// ─── 공공 데이터 및 침수 연산 예측 서비스 ───

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
  // 동네별 고유 기상/지형 특성 데이터셋
  static const Map<String, MockWeatherData> _districtDatabase = {
    '남구 주월동': MockWeatherData(
      districtName: '남구 주월동',
      precipitation: 45.0, // 폭우
      drainageCapacity: 75.0, // 배수 불량 (처리 용량 초과)
      elevation: 12.0, // 저지대
    ),
    '남구 봉선동': MockWeatherData(
      districtName: '남구 봉선동',
      precipitation: 15.0, // 보통 비
      drainageCapacity: 240.0, // 배수 우수
      elevation: 45.0, // 고지대
    ),
    '서구 치평동': MockWeatherData(
      districtName: '서구 치평동',
      precipitation: 30.0, // 강한 비
      drainageCapacity: 150.0, // 보통
      elevation: 24.0, // 평지
    ),
    '북구 용봉동': MockWeatherData(
      districtName: '북구 용봉동',
      precipitation: 25.0,
      drainageCapacity: 130.0,
      elevation: 18.0,
    ),
  };

  // 주소 기반 데이터 쿼리 함수 (Mocking)
  static MockWeatherData getWeatherData(String address) {
    for (var key in _districtDatabase.keys) {
      if (address.contains(key) || key.contains(address)) {
        return _districtDatabase[key]!;
      }
    }
    return const MockWeatherData(
      districtName: '일반 지역',
      precipitation: 20.0,
      drainageCapacity: 160.0,
      elevation: 25.0,
    );
  }

  // 침수 확률 계산 로직 (수학적 가중치 연산)
  static int calculateFloodProbability({
    required MockWeatherData weatherData,
    required String buildingType,
  }) {
    // 1. 강수량 가중치 (비가 많이 올수록 급격히 위험도 증가)
    double rainFactor = weatherData.precipitation * 1.6;

    // 2. 배수 성능 영향도 (배수 처리량이 낮을수록 위험도 증가)
    double drainageFactor = (250.0 - weatherData.drainageCapacity).clamp(0.0, 200.0) * 0.3;

    // 3. 해발고도 영향도 (고도가 낮을수록 위험도 증가)
    double elevationFactor = (50.0 - weatherData.elevation).clamp(0.0, 50.0) * 0.8;

    // 건물 유형별 위험 가중치
    double buildingWeight = 1.0;
    if (buildingType == '반지하') {
      buildingWeight = 1.8;
    } else if (buildingType == '1층(저지대)') {
      buildingWeight = 1.3;
    } else if (buildingType == '고층 아파트/빌딩') {
      buildingWeight = 0.4;
    }

    double baseScore = (rainFactor + drainageFactor + elevationFactor);
    double finalProbability = baseScore * buildingWeight;

    return finalProbability.clamp(5.0, 98.0).round();
  }
}
