// lib/screens/setup_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/user_model.dart';
import '../providers/app_provider.dart';
import '../services/flood_api_service.dart';
import '../widgets/dong_picker.dart';
import 'dashboard_screen.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen>
    with SingleTickerProviderStateMixin {
  // 기본 선택: 관악구 신림동 (2022 침수 피해 지역, API 커버리지 내)
  DongInfo _selectedDong =
      const DongInfo(admCd: 1162010200, gu: '관악구', dong: '신림동');
  BuildingType _selectedType = BuildingType.semiBasement;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _openDongPicker() async {
    final picked = await showDongPicker(context);
    if (picked != null) setState(() => _selectedDong = picked);
  }

  void _handleContinue(BuildContext context) {
    final user = UserModel(
      address: _selectedDong.fullAddress,
      buildingType: _selectedType,
      district: _selectedDong.label,
      admCd: _selectedDong.admCd,
    );
    context.read<AppProvider>().completeSetup(user);
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (ctx, anim, secondaryAnim) => const DashboardScreen(),
        transitionsBuilder: (ctx, anim, secondaryAnim, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: Column(
              children: [
                Container(
                  height: 4,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                        colors: [AppColors.accent, AppColors.accent2]),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStepIndicator(),
                        const SizedBox(height: 32),
                        Text(
                          '거주지 정보 입력',
                          style: GoogleFonts.notoSans(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '정확한 재난 위험도 분석을 위해\n거주지 정보를 알려주세요',
                          style: GoogleFonts.notoSans(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 36),
                        _buildAddressField(),
                        const SizedBox(height: 28),
                        _buildBuildingTypeSection(),
                        const SizedBox(height: 32),
                        _buildInfoCard(),
                        const SizedBox(height: 40),
                        _buildContinueButton(context),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      children: [
        _StepDot(index: 1, isActive: true, isCompleted: false),
        Expanded(child: Container(height: 2, color: AppColors.border)),
        _StepDot(index: 2, isActive: false, isCompleted: false),
        Expanded(child: Container(height: 2, color: AppColors.border)),
        _StepDot(index: 3, isActive: false, isCompleted: false),
      ],
    );
  }

  Widget _buildAddressField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.location_on_rounded,
                color: AppColors.amber, size: 18),
            const SizedBox(width: 6),
            Text(
              '거주 지역 선택',
              style: GoogleFonts.notoSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.red.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '필수',
                style: GoogleFonts.notoSans(
                  fontSize: 10,
                  color: AppColors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: _openDongPicker,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on_rounded,
                    color: AppColors.amber, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedDong.label,
                        style: GoogleFonts.notoSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _selectedDong.fullAddress,
                        style: GoogleFonts.notoSans(
                            fontSize: 11, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.expand_more_rounded,
                    color: AppColors.textMuted),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.verified_rounded,
                size: 13, color: AppColors.success),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                'AI 침수 예측을 지원하는 서울 지역에서 선택합니다. 탭하여 검색하세요.',
                style: GoogleFonts.notoSans(
                    fontSize: 11, color: AppColors.textMuted),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBuildingTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.home_work_rounded,
                color: AppColors.amber, size: 18),
            const SizedBox(width: 6),
            Text(
              '건물 유형 선택',
              style: GoogleFonts.notoSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.red.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '필수',
                style: GoogleFonts.notoSans(
                  fontSize: 10,
                  color: AppColors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...BuildingType.values.map((type) => _BuildingTypeCard(
              type: type,
              isSelected: _selectedType == type,
              onTap: () => setState(() => _selectedType = type),
            )),
      ],
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.amber.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.amber.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded,
              color: AppColors.amber, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '입력하신 정보는 AI 기반 침수 위험도 계산에만 사용되며,\n언제든지 설정에서 변경할 수 있습니다.',
              style: GoogleFonts.notoSans(
                fontSize: 12,
                color: AppColors.amber,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContinueButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _handleContinue(context),
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
              colors: [AppColors.accent, AppColors.accentDark]),
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withValues(alpha: 0.32),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '대시보드로 이동',
              style: GoogleFonts.notoSans(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_rounded,
                color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }
}

// ─── Sub-widgets ───────────────────────────────────────────────────────────

class _StepDot extends StatelessWidget {
  final int index;
  final bool isActive;
  final bool isCompleted;

  const _StepDot(
      {required this.index,
      required this.isActive,
      required this.isCompleted});

  @override
  Widget build(BuildContext context) {
    final bg = isActive
        ? AppColors.amber
        : isCompleted
            ? AppColors.success
            : AppColors.bgCard;
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: Border.all(
          color: isActive ? AppColors.amber : AppColors.border,
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          '$index',
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isActive || isCompleted ? Colors.white : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}

class _BuildingTypeCard extends StatelessWidget {
  final BuildingType type;
  final bool isSelected;
  final VoidCallback onTap;

  const _BuildingTypeCard(
      {required this.type, required this.isSelected, required this.onTap});

  IconData get _icon {
    switch (type) {
      case BuildingType.semiBasement:
        return Icons.water_damage_rounded;
      case BuildingType.groundFloor:
        return Icons.home_rounded;
      case BuildingType.highRise:
        return Icons.apartment_rounded;
    }
  }

  String get _riskLabel {
    switch (type) {
      case BuildingType.semiBasement:
        return '침수 위험 높음';
      case BuildingType.groundFloor:
        return '침수 위험 보통';
      case BuildingType.highRise:
        return '주차장 대피 주의';
    }
  }

  Color get _riskColor {
    switch (type) {
      case BuildingType.semiBasement:
        return AppColors.red;
      case BuildingType.groundFloor:
        return AppColors.amber;
      case BuildingType.highRise:
        return AppColors.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.amber.withValues(alpha: 0.08)
              : AppColors.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.amber : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _riskColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_icon, color: _riskColor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    type.label,
                    style: GoogleFonts.notoSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _riskLabel,
                    style: GoogleFonts.notoSans(
                        fontSize: 12, color: _riskColor),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppColors.amber : Colors.transparent,
                border: Border.all(
                  color:
                      isSelected ? AppColors.amber : AppColors.borderLight,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check_rounded,
                      color: Colors.white, size: 14)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
