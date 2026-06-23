import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/flood_api_service.dart';
import '../services/kma_daily_service.dart';
import '../services/weather_warning_service.dart';

/// 앱 전역 상태.
///
/// - 사용자 거주지/건물유형 (지원 지역 = 서울 93개 법정동)
/// - Ready-Flow AI 실시간 침수 확률(`apiPredict`)
/// - 앱 자체 시나리오 위험도(`scenarioProbability`) — 리치 UI 연출용 보조 지표
class AppProvider extends ChangeNotifier {
  AppProvider({
    FloodApiService? api,
    WeatherWarningService? warningService,
    KmaDailyService? dailyService,
  })  : _api = api ?? FloodApiService(),
        _warnings = warningService ?? WeatherWarningService(),
        _daily = dailyService ?? KmaDailyService() {
    loadCoverage();
    fetchFloodPrediction();
    fetchWeatherWarnings();
  }

  final FloodApiService _api;
  final WeatherWarningService _warnings;
  final KmaDailyService _daily;

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

  // ── 기상청 실시간 특보 ──
  WeatherWarningResult _warningResult =
      const WeatherWarningResult(status: WarningStatus.noWarnings);
  bool _warningsLoading = false;

  WeatherWarningResult get warningResult => _warningResult;
  bool get warningsLoading => _warningsLoading;
  bool get hasWeatherKey => _warnings.hasKey;

  // ── 캘린더: 월간 실측 강수량(기상청 ASOS 일자료) ──
  MonthlyRain _monthlyRain =
      const MonthlyRain(status: DailyStatus.noData);
  bool _monthlyLoading = false;
  int _calYear = 0; // 0 = 미로딩
  int _calMonth = 0;

  MonthlyRain get monthlyRain => _monthlyRain;
  bool get monthlyLoading => _monthlyLoading;
  int get calYear => _calYear;
  int get calMonth => _calMonth;

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
    fetchWeatherWarnings();
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
    fetchWeatherWarnings();
  }

  void setActiveTab(int index) {
    _activeTab = index;
    notifyListeners();
    // 캘린더 탭(3) 진입 시 이번 달 실측 강수량을 1회 로드.
    if (index == 3 && _calYear == 0 && !_monthlyLoading) {
      final now = DateTime.now();
      fetchMonthlyRain(now.year, now.month);
    }
  }

  /// 지정 연/월의 일강수량을 기상청에서 조회.
  Future<void> fetchMonthlyRain(int year, int month) async {
    _monthlyLoading = true;
    _calYear = year;
    _calMonth = month;
    notifyListeners();
    _monthlyRain = await _daily.fetchMonth(year, month);
    _monthlyLoading = false;
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

  // ─── 기상청 실시간 특보 ───

  List<String> get _regionKeywords {
    final parts = _user.district.split(' ');
    final gu = parts.isNotEmpty ? parts.first : '';
    return ['서울', if (gu.isNotEmpty) gu];
  }

  Future<void> fetchWeatherWarnings() async {
    _warningsLoading = true;
    notifyListeners();
    final result = await _warnings.fetchActive(regionKeywords: _regionKeywords);
    _warningResult = result;
    _warningsLoading = false;
    notifyListeners();
  }

  // ─── 침수 확률 예측 ───

  /// 예측 API 에 보내는 일강우(mm) 시퀀스(과거→오늘).
  /// 실시간 강우 예보 API 연동 전까지 사용하는 기본 입력값이며,
  /// 화면에 '실측 강수량'처럼 표시하지 않는다(입력 가정치).
  static const List<double> _forecastDailyRain = [5.0, 20.0, 40.0, 30.0];

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

  // ─── 표시용 위험도 (전적으로 실측 API 기반) ───

  /// 침수 위험도(%). Ready-Flow AI 실측치 그대로. 데이터 없으면 null.
  int? get floodProbability => _apiPredict?.percent;

  /// 위험 단계. 데이터 없으면 null.
  AlertLevel? get alertLevel {
    final prob = floodProbability;
    if (prob == null) return null;
    if (prob >= 60) return AlertLevel.critical;
    if (prob >= 30) return AlertLevel.warning;
    return AlertLevel.info;
  }

  /// 경보 배너 문구. 실측 데이터 기반.
  String get alertMessage {
    final prob = floodProbability;
    final name = _user.district;
    if (prob == null) {
      if (_isCoverageError) {
        return 'ℹ️ $name 은(는) AI 예측 커버리지(서울 93개 법정동) 밖입니다. 지원 지역을 선택해 주세요.';
      }
      if (_isApiLoading) return '⏳ $name 의 실시간 침수 확률을 불러오는 중입니다…';
      return '⚠️ 실시간 침수 예측 데이터를 불러오지 못했습니다. 새로고침해 주세요.';
    }
    if (prob >= 60) {
      return '🚨 경고: $name, AI 예측 침수 확률 $prob%. 차수판 작동 대기 및 대피를 준비하세요.';
    } else if (prob >= 30) {
      return '⚠️ 주의: $name, AI 예측 침수 확률 $prob%. 침수 대비를 권장합니다.';
    } else {
      return '🅿️ 안정: $name, AI 예측 침수 확률 $prob% — 현재 위험은 낮습니다.';
    }
  }

  @override
  void dispose() {
    _api.dispose();
    _warnings.dispose();
    _daily.dispose();
    super.dispose();
  }
}
