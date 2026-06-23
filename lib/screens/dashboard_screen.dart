// lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/app_provider.dart';
import '../models/user_model.dart';
import '../services/flood_api_service.dart';
import '../services/kma_daily_service.dart';
import '../services/weather_warning_service.dart';
import '../widgets/alert_banner.dart';
import '../widgets/commerce_widget.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/home_address_flow.dart';
import '../widgets/live_flood_card.dart';
import 'splash_screen.dart';
import '../widgets/card_news_widget.dart';
import '../widgets/kakao_map_stub.dart'
    if (dart.library.html) '../widgets/kakao_map_web.dart'
    if (dart.library.io) '../widgets/kakao_map_mobile.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final List<bool> _planChecks = [true, false, true, false];
  late int _selectedDay;
  late final TextEditingController _noteController;
  final Map<int, String> _calendarNotes = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now().day;
    _noteController = TextEditingController(text: _calendarNotes[_selectedDay] ?? '');
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  /// 해당 일의 실측 강수량(mm). 관측 데이터 없으면 null.
  double? _rainFor(AppProvider provider, int day) =>
      provider.monthlyRain.rainByDay[day];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final user = provider.user;
    final activeTab = provider.activeTab;

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                height: 4,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                      colors: [AppColors.accent, AppColors.accent2]),
                ),
              ),
              _buildAppBar(context, user, provider),
              Expanded(
                child: _buildBody(activeTab, user, provider),
              ),
              const HomeProtectorBottomNav(),
            ],
          ),
          if (provider.showToast) _buildToast(provider.toastMessage),
        ],
      ),
    );
  }

  Widget _buildBody(int activeTab, UserModel user, AppProvider provider) {
    switch (activeTab) {
      case 0:
        return RefreshIndicator(
          color: AppColors.amber,
          backgroundColor: AppColors.bgSurface,
          onRefresh: () => provider.fetchFloodPrediction(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              AlertBanner(user: user),
              const LiveFloodCard(),
              _buildQuickStats(provider),
              const CommerceWidget(),
              _buildNearbyReport(),
              const CardNewsWidget(),
              const SizedBox(height: 20),
            ],
          ),
        );
      case 1:
        return _buildMapPage(user, provider);
      case 2:
        return _buildAlertsPage(provider);
      case 3:
        return _buildCalendarPage(provider);
      case 4:
        return _buildPlanPage();
      default:
        return const SizedBox();
    }
  }

  Widget _buildAppBar(BuildContext context, UserModel user, AppProvider provider) {
    return Container(
      color: AppColors.bgSurface,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top,
        left: 16,
        right: 16,
        bottom: 12,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: AppColors.amber.withValues(alpha: 0.3), width: 1.5),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: Image.asset(
                'assets/images/logo.png',
                fit: BoxFit.contain,
                errorBuilder: (ctx, err, stack) => const Icon(
                  Icons.home_work_rounded,
                  color: AppColors.amber,
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'HomeProtector',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded,
                        color: AppColors.amber, size: 12),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        user.address,
                        style: GoogleFonts.notoSans(
                            fontSize: 11, color: AppColors.textSecondary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_rounded, color: AppColors.textSecondary),
            onPressed: () => _showSettingsSheet(context, user, provider),
          ),
        ],
      ),
    );
  }

  void _showSettingsSheet(BuildContext context, UserModel user, AppProvider provider) {
    DongInfo selectedDong = DongInfo(
      admCd: user.admCd ?? 1162010200,
      gu: user.district.split(' ').first,
      dong: user.district.contains(' ') ? user.district.split(' ').last : null,
    );
    String selectedAddress = user.address;
    BuildingType selectedType = user.buildingType;
    double? selectedLat = user.lat;
    double? selectedLon = user.lon;
    bool selectedExact = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgPrimary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 24,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '설정 및 회원 정보',
                          style: GoogleFonts.notoSans(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const Divider(color: AppColors.border, height: 24),
                    const SizedBox(height: 8),
                    Text(
                      '거주 지역 변경',
                      style: GoogleFonts.notoSans(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () async {
                        final picked = await pickHomeAddress(context);
                        if (picked != null) {
                          setSheetState(() {
                            selectedDong = picked.dong;
                            selectedAddress = picked.address;
                            selectedLat = picked.lat;
                            selectedLon = picked.lon;
                            selectedExact = picked.exact;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.bgSurface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on_rounded,
                                color: AppColors.amber),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    selectedAddress,
                                    style: GoogleFonts.notoSans(
                                        color: AppColors.textPrimary,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    selectedExact
                                        ? '예측 기준: ${selectedDong.label}'
                                        : '예측 기준: ${selectedDong.label} (구 단위 근사)',
                                    style: GoogleFonts.notoSans(
                                        color: AppColors.textMuted,
                                        fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.search_rounded,
                                color: AppColors.amber),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '* 실제 주소를 검색(다음 우편번호)하면 동/구만 추출해 예측에 씁니다.',
                      style: GoogleFonts.notoSans(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      '건물 유형 변경',
                      style: GoogleFonts.notoSans(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<BuildingType>(
                      initialValue: selectedType,
                      dropdownColor: AppColors.bgPrimary,
                      style: GoogleFonts.notoSans(color: AppColors.textPrimary, fontSize: 14),
                      decoration: const InputDecoration(
                        filled: true,
                        fillColor: AppColors.bgSurface,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      items: BuildingType.values.map((type) {
                        return DropdownMenuItem<BuildingType>(
                          value: type,
                          child: Text(type.label, style: const TextStyle(color: AppColors.textPrimary)),
                        );
                      }).toList(),
                      onChanged: (BuildingType? newValue) {
                        if (newValue != null) {
                          setSheetState(() {
                            selectedType = newValue;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.red),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () {
                              Navigator.pop(context); // Close bottom sheet
                              provider.logout();
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(builder: (context) => const SplashScreen()),
                                (route) => false,
                              );
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.logout_rounded, color: AppColors.red, size: 18),
                                const SizedBox(width: 6),
                                Text(
                                  '로그아웃',
                                  style: GoogleFonts.notoSans(
                                    color: AppColors.red,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.amber,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            onPressed: () {
                              provider.updateUser(
                                UserModel(
                                  address: selectedAddress,
                                  buildingType: selectedType,
                                  district: selectedDong.label,
                                  admCd: selectedDong.admCd,
                                  lat: selectedLat,
                                  lon: selectedLon,
                                ),
                              );
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('거주지 정보가 저장되었습니다.',
                                      style: GoogleFonts.notoSans(
                                          color: AppColors.textPrimary)),
                                  backgroundColor: AppColors.bgSurface,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: const BorderSide(
                                        color: AppColors.border),
                                  ),
                                ),
                              );
                            },
                            child: Text(
                              '저장하기',
                              style: GoogleFonts.notoSans(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// 홈 퀵스탯 — 전부 실데이터(예측 API + 기상특보)에서 파생. 임의 수치 없음.
  Widget _buildQuickStats(AppProvider provider) {
    final prob = provider.floodProbability;
    final probColor = _getRiskColor(prob);
    final warn = provider.warningResult;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          _QuickStatCard(
            icon: Icons.water_drop_rounded,
            label: 'AI 침수확률',
            value: prob == null ? '—' : '$prob%',
            color: probColor,
          ),
          const SizedBox(width: 8),
          _QuickStatCard(
            icon: Icons.warning_amber_rounded,
            label: '위험 단계',
            value: _getRiskLevel(prob),
            color: probColor,
          ),
          const SizedBox(width: 8),
          _QuickStatCard(
            icon: Icons.campaign_rounded,
            label: '기상특보',
            value: _warningSummary(provider),
            color: _warningColor(warn.status),
          ),
          const SizedBox(width: 8),
          _QuickStatCard(
            icon: Icons.location_city_rounded,
            label: '지원 지역',
            value: provider.user.district.split(' ').first,
            color: AppColors.info,
          ),
        ],
      ),
    );
  }

  String _warningSummary(AppProvider provider) {
    if (provider.warningsLoading) return '조회중';
    final w = provider.warningResult;
    switch (w.status) {
      case WarningStatus.ok:
        return w.warnings.isNotEmpty ? '${w.warnings.length}건' : '발효중';
      case WarningStatus.noWarnings:
        return '없음';
      case WarningStatus.noKey:
        return '대기';
      case WarningStatus.authError:
        return '키오류';
      case WarningStatus.blockedOnWeb:
        return '웹제한';
      case WarningStatus.networkError:
      case WarningStatus.apiError:
        return '오류';
    }
  }

  Color _warningColor(WarningStatus status) {
    switch (status) {
      case WarningStatus.ok:
        return AppColors.red;
      case WarningStatus.noWarnings:
        return AppColors.success;
      case WarningStatus.noKey:
        return AppColors.textMuted;
      default:
        return AppColors.amber;
    }
  }

  String _getRiskLevel(int? score) {
    if (score == null) return '—';
    if (score >= 60) return '위험';
    if (score >= 30) return '주의';
    return '관심';
  }

  Color _getRiskColor(int? score) {
    if (score == null) return AppColors.textMuted;
    if (score >= 60) return AppColors.red;
    if (score >= 30) return AppColors.amber;
    return AppColors.success;
  }

  /// 데모/예시 데이터임을 표시하는 배지(실제 API 미연동 콘텐츠).
  Widget _demoBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.textMuted.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        '예시',
        style: GoogleFonts.outfit(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppColors.textMuted,
        ),
      ),
    );
  }

  Widget _buildNearbyReport() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.people_rounded,
                    color: AppColors.warning, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                '근처 주민 제보',
                style: GoogleFonts.notoSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              _demoBadge(),
            ],
          ),
          const SizedBox(height: 12),
          const _ReportItem(
            emoji: '💧',
            text: '신림동 순대타운 사거리 도로 침수 시작',
            time: '3분 전',
            distance: '250m',
          ),
          const _ReportItem(
            emoji: '🚗',
            text: '관악구청 앞 지하주차장 입구 잠김',
            time: '12분 전',
            distance: '1.2km',
          ),
          const _ReportItem(
            emoji: '⚠️',
            text: '신림역 4번 출구 배수구 역류 발생',
            time: '31분 전',
            distance: '800m',
          ),
        ],
      ),
    );
  }

  Widget _buildToast(String message) {
    return Positioned(
      bottom: 90,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.10),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.construction_rounded,
                color: AppColors.amber, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.notoSans(
                  fontSize: 13,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Map Page ──────────────────────────────────────────────────────────────
  Widget _buildMapPage(UserModel user, AppProvider provider) {
    return Container(
      color: AppColors.bgPrimary,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: GestureDetector(
              onTap: () async {
                final picked = await pickHomeAddress(context);
                if (picked != null && context.mounted) {
                  provider.updateUser(
                    UserModel(
                      address: picked.address,
                      buildingType: user.buildingType,
                      district: picked.district,
                      admCd: picked.dong.admCd,
                      lat: picked.lat,
                      lon: picked.lon,
                    ),
                  );
                }
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.bgSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: AppColors.textSecondary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '주소 검색 · 예측 기준 ${user.district}',
                        style: GoogleFonts.notoSans(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.tune_rounded,
                        color: AppColors.amber, size: 20),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.bgSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.06),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: createKakaoMapWidget(
                  address: user.address,
                  probability: provider.floodProbability ?? -1,
                  lat: user.lat,
                  lon: user.lon,
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            height: 140,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildMapInfoCard(
                  name: '신림동 주민센터 대피소',
                  distance: '120m',
                  time: '도보 2분',
                  status: '여유',
                  statusColor: AppColors.success,
                ),
                const SizedBox(width: 12),
                _buildMapInfoCard(
                  name: '관악구청 임시대피소',
                  distance: '450m',
                  time: '도보 7분',
                  status: '보통',
                  statusColor: AppColors.amber,
                ),
                const SizedBox(width: 12),
                _buildMapInfoCard(
                  name: '난곡 종합안전센터',
                  distance: '820m',
                  time: '도보 12분',
                  status: '혼잡',
                  statusColor: AppColors.red,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapInfoCard({
    required String name,
    required String distance,
    required String time,
    required String status,
    required Color statusColor,
  }) {
    return Container(
      width: 240,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on_rounded, color: AppColors.red, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  name,
                  style: GoogleFonts.notoSans(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '거리: $distance ($time)',
                    style: GoogleFonts.notoSans(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                ),
                child: Text(
                  status,
                  style: GoogleFonts.notoSans(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Alerts Page (기상청 실시간 특보) ────────────────────────────────────────
  Widget _buildAlertsPage(AppProvider provider) {
    return Container(
      color: AppColors.bgPrimary,
      child: RefreshIndicator(
        color: AppColors.amber,
        backgroundColor: AppColors.bgSurface,
        onRefresh: () => provider.fetchWeatherWarnings(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '기상청 실시간 특보',
                    style: GoogleFonts.notoSans(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded,
                      color: AppColors.textSecondary),
                  onPressed: () => provider.fetchWeatherWarnings(),
                  tooltip: '새로고침',
                ),
              ],
            ),
            Text(
              '${provider.user.district} · 기상청 기상특보 조회',
              style: GoogleFonts.notoSans(
                  color: AppColors.textMuted, fontSize: 12),
            ),
            const SizedBox(height: 16),
            ..._buildAlertsBody(provider),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildAlertsBody(AppProvider provider) {
    if (provider.warningsLoading) {
      return [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 60),
          child: Center(
            child: CircularProgressIndicator(
                color: AppColors.amber, strokeWidth: 2.5),
          ),
        ),
      ];
    }

    final result = provider.warningResult;

    switch (result.status) {
      // 발효 특보 있음
      case WarningStatus.ok:
        if (result.warnings.isNotEmpty) {
          return result.warnings.map((w) {
            final color = w.isCritical ? AppColors.red : AppColors.amber;
            return _buildAlertItem(
              title: '${w.region} ${w.title} 발효',
              body: '기상청 발표 — ${w.region} 지역에 ${w.title}가 발효 중입니다. '
                  '${w.hazard == '호우' ? '저지대·반지하 주민은 침수에 대비하세요.' : '안전에 유의하세요.'}',
              time: '발효 중',
              type: color,
              icon: w.isCritical
                  ? Icons.error_outline_rounded
                  : Icons.warning_amber_rounded,
            );
          }).toList();
        }
        // 지역 매칭은 없지만 실제 통보문 존재 → 원문(실제 정보) 표시
        return [
          _buildNoticeCard(
            icon: Icons.campaign_rounded,
            color: AppColors.amber,
            title: '기상청 특보 통보문 (타 지역)',
            body: '${provider.user.district} 직접 매칭 특보는 없으나, '
                '현재 발표된 기상청 통보문 원문은 다음과 같습니다:\n\n${result.bulletin ?? ''}',
          ),
        ];

      // 발효 특보 없음 (정상)
      case WarningStatus.noWarnings:
        return [
          _buildNoticeCard(
            icon: Icons.task_alt_rounded,
            color: AppColors.success,
            title: '발효 중인 기상특보 없음',
            body: '현재 ${provider.user.district} 지역에 발효 중인 기상특보가 없습니다.\n'
                '당겨서 새로고침하면 최신 정보를 다시 확인합니다.',
            diag: result,
          ),
        ];

      // 키 미설정 (백엔드)
      case WarningStatus.noKey:
        return [
          _buildNoticeCard(
            icon: Icons.vpn_key_off_rounded,
            color: AppColors.info,
            title: '기상청 특보 연동 대기 중',
            body: result.detail ??
                '백엔드(Ready-Flow)에 기상청 서비스 키(KMA_SERVICE_KEY)가 '
                    '설정되지 않았습니다. 잠시 후 다시 시도해 주세요.',
            diag: result,
          ),
        ];

      // 키 오류 / 서비스 미신청
      case WarningStatus.authError:
        return [
          _buildNoticeCard(
            icon: Icons.key_off_rounded,
            color: AppColors.red,
            title: '기상청 API 키 오류',
            body: result.detail ??
                '서비스 키가 등록되지 않았거나 한도를 초과했습니다.',
            diag: result,
          ),
        ];

      // (호환용) 더 이상 발생하지 않음 — 백엔드 프록시로 웹에서도 조회됨
      case WarningStatus.blockedOnWeb:
        return [
          _buildNoticeCard(
            icon: Icons.cloud_off_rounded,
            color: AppColors.amber,
            title: '특보를 불러오지 못했습니다',
            body: result.detail ?? '잠시 후 다시 시도해 주세요.',
          ),
        ];

      // 네트워크 / 기타 API 오류
      case WarningStatus.networkError:
      case WarningStatus.apiError:
        return [
          _buildNoticeCard(
            icon: Icons.cloud_off_rounded,
            color: AppColors.red,
            title: '특보를 불러오지 못했습니다',
            body: result.detail ?? '알 수 없는 오류가 발생했습니다.',
            diag: result,
          ),
        ];
    }
  }

  Widget _buildNoticeCard({
    required IconData icon,
    required Color color,
    required String title,
    required String body,
    WeatherWarningResult? diag,
  }) {
    final diagParts = <String>[];
    if (diag != null) {
      if (diag.httpStatus != null) diagParts.add('HTTP ${diag.httpStatus}');
      if (diag.resultCode != null) diagParts.add('code ${diag.resultCode}');
      if (diag.resultMsg != null) diagParts.add(diag.resultMsg!);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.notoSans(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            body,
            style: GoogleFonts.notoSans(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          if (diagParts.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.bgCardDark,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '진단: ${diagParts.join(' · ')}',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAlertItem({
    required String title,
    required String body,
    required String time,
    required Color type,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: type.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: type, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.notoSans(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      time,
                      style: GoogleFonts.notoSans(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            body,
            style: GoogleFonts.notoSans(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Calendar Page ─────────────────────────────────────────────────────────
  Widget _buildCalendarPage(AppProvider provider) {
    final now = DateTime.now();
    final year = provider.calYear != 0 ? provider.calYear : now.year;
    final month = provider.calMonth != 0 ? provider.calMonth : now.month;
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final leadingBlanks = DateTime(year, month, 1).weekday - 1; // 월요일 시작
    final weekdayLabels = ['월', '화', '수', '목', '금', '토', '일'];
    FloodForecastDay? forecastForDay(int day) {
      final days = provider.weekForecast?.days ?? const <FloodForecastDay>[];
      for (final item in days) {
        if (item.date.year == year && item.date.month == month && item.date.day == day) {
          return item;
        }
      }
      return null;
    }

    return Container(
      color: AppColors.bgPrimary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '월간 침수 예측 캘린더',
                      style: GoogleFonts.notoSans(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '기상청 ASOS 일자료(서울) 실측 강수량 기반',
                      style: GoogleFonts.notoSans(
                          color: AppColors.textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Text(
                '$year년 $month월',
                style: GoogleFonts.outfit(
                  color: AppColors.accent,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded,
                    color: AppColors.textSecondary, size: 20),
                onPressed: () {
                  provider.fetchMonthlyRain(year, month);
                  provider.fetchWeekFloodForecast();
                },
                tooltip: '새로고침',
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildWeekForecastSummary(provider),
          const SizedBox(height: 8),
          if (provider.monthlyLoading)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(
                    color: AppColors.accent, strokeWidth: 2.5),
              ),
            )
          else if (!provider.monthlyRain.isOk &&
              provider.monthlyRain.status != DailyStatus.noData)
            Expanded(child: _calendarNotice(provider.monthlyRain))
          else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: weekdayLabels.map((label) {
                final isWeekend = label == '토' || label == '일';
                return SizedBox(
                  width: 40,
                  child: Text(
                    label,
                    style: GoogleFonts.notoSans(
                      color: isWeekend
                          ? AppColors.red.withValues(alpha: 0.8)
                          : AppColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // 모든 주(행)가 가용 높이에 정확히 들어가도록 셀 비율을 계산한다.
                  // (고정 비율이면 넓은 화면에서 셀이 커져 비스크롤 그리드가 잘림)
                  const spacing = 5.0;
                  final rows =
                      ((leadingBlanks + daysInMonth) / 7).ceil().clamp(1, 6);
                  final cellW = (constraints.maxWidth - spacing * 6) / 7;
                  final cellH = (constraints.maxHeight - spacing * (rows - 1)) /
                      rows;
                  final ratio =
                      (cellH > 0 ? cellW / cellH : 0.95).clamp(0.5, 1.3);
                  return GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      crossAxisSpacing: spacing,
                      mainAxisSpacing: spacing,
                      childAspectRatio: ratio,
                    ),
                    itemCount: leadingBlanks + daysInMonth,
                    itemBuilder: (context, index) {
                  if (index < leadingBlanks) return const SizedBox();
                  final day = index - leadingBlanks + 1;
                  final isSelected = _selectedDay == day;
                  final forecast = forecastForDay(day);
                  final rain = _rainFor(provider, day);
                  final color = forecast == null
                      ? _rainColor(rain)
                      : _probabilityColor(forecast.percent);

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedDay = day;
                        _noteController.text = _calendarNotes[day] ?? '';
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.accent.withValues(alpha: 0.12)
                            : AppColors.bgSurface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color:
                              isSelected ? AppColors.accent : AppColors.border,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$day',
                            style: GoogleFonts.outfit(
                              color: isSelected
                                  ? AppColors.accent
                                  : AppColors.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              forecast != null
                                  ? '${forecast.percent}%'
                                  : rain == null
                                  ? '–'
                                  : rain == 0
                                      ? '0'
                                      : rain.toStringAsFixed(rain < 10 ? 1 : 0),
                              style: GoogleFonts.outfit(
                                color: color,
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 2),
              child: Text(
                '미래 = 침수확률(%) · 과거/현재 = 일강수량(mm) · “–”는 데이터 없음',
                style: GoogleFonts.notoSans(
                    color: AppColors.textMuted, fontSize: 10),
              ),
            ),
          ],
          const SizedBox(height: 8),
          _buildDayDetailCard(provider, year, month),
        ],
      ),
    );
  }

  Widget _buildWeekForecastSummary(AppProvider provider) {
    final peak = provider.weekForecast?.peak;
    final error = provider.weekForecastError;

    if (provider.weekForecastLoading) {
      return _forecastSummaryShell(
        icon: Icons.cloud_sync_rounded,
        color: AppColors.info,
        title: '단기 침수 예보를 불러오는 중',
        body: '기상청 예보 강수량을 백엔드에서 받아 침수 확률을 계산하고 있습니다.',
      );
    }
    if (peak == null) {
      // 단기예보 활용신청/승인 반영 대기는 일시적 상태 — 친절하게 안내.
      final pending = error != null &&
          (error.contains('단기예보') || error.contains('활용신청'));
      return _forecastSummaryShell(
        icon: pending ? Icons.hourglass_bottom_rounded : Icons.cloud_off_rounded,
        color: pending ? AppColors.info : AppColors.textMuted,
        title: pending ? '단기 예보 준비 중' : '향후 침수 예보 없음',
        body: pending
            ? '기상청 단기예보 서비스 승인이 반영되면 향후 며칠의 침수 확률이 자동으로 표시됩니다. '
                '아래 달력의 과거 강수량은 정상 표시됩니다.'
            : error ?? '예보 데이터가 아직 준비되지 않았습니다.',
      );
    }

    final color = _probabilityColor(peak.percent);
    final dateLabel = '${peak.date.month}/${peak.date.day}';
    final level = switch (peak.riskLevel) {
      'danger' => '경고',
      'warning' => '주의',
      'info' => '관심',
      _ => '상대위험 ${peak.riskPercentile ?? 0}분위',
    };
    return _forecastSummaryShell(
      icon: Icons.warning_amber_rounded,
      color: color,
      title: '향후 며칠 중 $dateLabel 침수 위험 최고',
      body:
          '침수 확률 ${peak.percent}% · 예상 강수량 ${peak.rainMm.toStringAsFixed(1)}mm · $level',
    );
  }

  Widget _forecastSummaryShell({
    required IconData icon,
    required Color color,
    required String title,
    required String body,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.notoSans(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: GoogleFonts.notoSans(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _probabilityColor(int percent) {
    if (percent >= 60) return AppColors.red;
    if (percent >= 30) return AppColors.amber;
    if (percent >= 10) return AppColors.info;
    return AppColors.success;
  }

  Color _rainColor(double? rain) {
    if (rain == null) return AppColors.textMuted;
    final p = MonthlyRain.riskPercentFor(rain);
    if (p >= 70) return AppColors.red;
    if (p >= 40) return AppColors.amber;
    if (p >= 15) return AppColors.info;
    if (p > 0) return AppColors.success;
    return AppColors.textMuted;
  }

  Widget _calendarNotice(MonthlyRain r) {
    final isForbidden = r.status == DailyStatus.forbidden;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isForbidden
                  ? Icons.lock_outline_rounded
                  : r.status == DailyStatus.noKey
                      ? Icons.vpn_key_off_rounded
                      : Icons.cloud_off_rounded,
              size: 44,
              color: isForbidden ? AppColors.amber : AppColors.textMuted,
            ),
            const SizedBox(height: 14),
            Text(
              isForbidden ? '일자료 서비스 신청이 필요해요' : '강수량을 불러오지 못했어요',
              style: GoogleFonts.notoSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              r.detail ?? '잠시 후 다시 시도해 주세요.',
              textAlign: TextAlign.center,
              style: GoogleFonts.notoSans(
                  fontSize: 12, color: AppColors.textSecondary, height: 1.5),
            ),
            if (r.httpStatus != null || r.resultCode != null) ...[
              const SizedBox(height: 10),
              Text(
                '진단: ${[
                  if (r.httpStatus != null) 'HTTP ${r.httpStatus}',
                  if (r.resultCode != null) 'code ${r.resultCode}',
                ].join(' · ')}',
                style: GoogleFonts.outfit(
                    fontSize: 11, color: AppColors.textMuted),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDayDetailCard(AppProvider provider, int year, int month) {
    FloodForecastDay? forecast;
    for (final item in provider.weekForecast?.days ?? const <FloodForecastDay>[]) {
      if (item.date.year == year &&
          item.date.month == month &&
          item.date.day == _selectedDay) {
        forecast = item;
        break;
      }
    }
    final rain = _rainFor(provider, _selectedDay);
    final percent =
        forecast?.percent ?? (rain == null ? null : MonthlyRain.riskPercentFor(rain));
    final color = forecast == null ? _rainColor(rain) : _probabilityColor(forecast.percent);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$month월 $_selectedDay일 침수 일지',
                style: GoogleFonts.notoSans(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  percent == null ? '데이터 없음' : '위험도 $percent%',
                  style: GoogleFonts.notoSans(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.umbrella_rounded, color: AppColors.info, size: 14),
              const SizedBox(width: 6),
              Text(
                forecast != null
                    ? '침수 확률: ${forecast.percent}% · 예보 강수량: ${forecast.rainMm.toStringAsFixed(1)}mm'
                    : rain == null
                        ? '강수량: 관측 데이터 없음'
                        : '강수량: ${rain.toStringAsFixed(1)}mm (기상청 실측)',
                style: GoogleFonts.notoSans(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.bgPrimary,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: TextField(
              controller: _noteController,
              maxLines: 2,
              style: GoogleFonts.notoSans(
                color: AppColors.textPrimary,
                fontSize: 11,
              ),
              decoration: InputDecoration(
                hintText: '이 날의 침수 대비 메모나 특이사항을 적어두세요.',
                hintStyle: GoogleFonts.notoSans(
                  color: AppColors.textMuted,
                  fontSize: 10,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                border: InputBorder.none,
              ),
              onChanged: (text) {
                _calendarNotes[_selectedDay] = text;
              },
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              height: 26,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                ),
                onPressed: () {
                  FocusScope.of(context).unfocus();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AppColors.bgSurface,
                      duration: const Duration(seconds: 1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: const BorderSide(color: AppColors.border),
                      ),
                      content: Text(
                        '$_selectedDay일 메모가 저장되었습니다.',
                        style: GoogleFonts.notoSans(color: AppColors.textPrimary, fontSize: 11),
                      ),
                    ),
                  );
                },
                child: Text(
                  '저장',
                  style: GoogleFonts.notoSans(fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Plan Page ─────────────────────────────────────────────────────────────
  Widget _buildPlanPage() {
    final checklists = [
      '현관문 외부 차수판(물막이판) 정상 작동 여부 점검하기',
      '비상 배낭 준비 (비상식량, 물, 손전등, 구급상자 포함)',
      '침수 우려 시 차량을 신속히 지상 또는 안전 지역으로 이동하기',
      '가구 내 누전 차단기 위치를 파악하고 가스 밸브 잠금 연습하기',
    ];

    return Container(
      color: AppColors.bgPrimary,
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          Text(
            '맞춤형 재난 대비 체크리스트',
            style: GoogleFonts.notoSans(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '반지하/저지대 맞춤형 권장 행동 지침입니다.',
            style: GoogleFonts.notoSans(
              color: AppColors.textMuted,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: List.generate(checklists.length, (index) {
                final checked = _planChecks[index];
                return CheckboxListTile(
                  activeColor: AppColors.amber,
                  checkColor: AppColors.bgPrimary,
                  title: Text(
                    checklists[index],
                    style: GoogleFonts.notoSans(
                      color: checked ? AppColors.textMuted : AppColors.textPrimary,
                      fontSize: 13,
                      decoration: checked ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  value: checked,
                  onChanged: (val) {
                    setState(() {
                      _planChecks[index] = val ?? false;
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                );
              }),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '비상 긴급 연락처',
            style: GoogleFonts.notoSans(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildEmergencyContactCard(
            title: '종합 재난 신고 센터',
            phone: '119 / 112',
            icon: Icons.phone_in_talk_rounded,
          ),
          const SizedBox(height: 8),
          _buildEmergencyContactCard(
            title: '서울 관악구청 재난안전대책본부',
            phone: '02-879-5000',
            icon: Icons.business_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyContactCard({
    required String title,
    required String phone,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.amber, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.notoSans(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  phone,
                  style: GoogleFonts.outfit(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.amber.withValues(alpha: 0.15),
              foregroundColor: AppColors.amber,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: AppColors.bgSurface,
                  duration: const Duration(seconds: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  content: Text(
                    '$phone 번호로 통화를 연결하는 시늉을 냅니다.',
                    style: GoogleFonts.notoSans(color: AppColors.textPrimary),
                  ),
                ),
              );
            },
            child: Text(
              '전화',
              style: GoogleFonts.notoSans(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Sub-widgets ───────────────────────────────────────────────────────────

class _QuickStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _QuickStatCard(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.notoSans(
                  fontSize: 9, color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportItem extends StatelessWidget {
  final String emoji;
  final String text;
  final String time;
  final String distance;

  const _ReportItem(
      {required this.emoji,
      required this.text,
      required this.time,
      required this.distance});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: GoogleFonts.notoSans(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(time,
                        style: GoogleFonts.notoSans(
                            fontSize: 11, color: AppColors.textMuted)),
                    const SizedBox(width: 8),
                    Container(
                      width: 3,
                      height: 3,
                      decoration: const BoxDecoration(
                        color: AppColors.textMuted,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(distance,
                        style: GoogleFonts.notoSans(
                            fontSize: 11, color: AppColors.amber)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}







