// lib/screens/setup_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/user_model.dart';
import '../providers/app_provider.dart';
import 'dashboard_screen.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _addressController = TextEditingController(
    text: '광주광역시 남구 주월동',
  );
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
    _addressController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _handleContinue(BuildContext context) {
    final address = _addressController.text.trim();
    if (address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('주소를 입력해 주세요',
              style: GoogleFonts.notoSans(color: Colors.white)),
          backgroundColor: AppColors.red,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }
    context.read<AppProvider>().completeSetup(address, _selectedType);
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
                        colors: [AppColors.red, AppColors.amber]),
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
              '주소 입력',
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
        TextField(
          controller: _addressController,
          style: GoogleFonts.notoSans(
              color: AppColors.textPrimary, fontSize: 15),
          decoration: InputDecoration(
            hintText: '예: 광주광역시 남구 주월동',
            hintStyle:
                GoogleFonts.notoSans(color: AppColors.textMuted, fontSize: 14),
            prefixIcon: const Icon(Icons.search_rounded,
                color: AppColors.textMuted, size: 20),
            suffixIcon: IconButton(
              icon: const Icon(Icons.clear_rounded,
                  color: AppColors.textMuted, size: 20),
              onPressed: () => _addressController.clear(),
            ),
            filled: true,
            fillColor: AppColors.bgCard,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.amber, width: 2),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children:
              ['남구 주월동', '북구 운암동', '서구 치평동', '광산구 수완동'].map((area) {
            return GestureDetector(
              onTap: () =>
                  setState(() => _addressController.text = '광주광역시 $area'),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.bgSurface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  area,
                  style: GoogleFonts.notoSans(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ),
            );
          }).toList(),
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
          gradient:
              const LinearGradient(colors: [AppColors.red, Color(0xFFB91C1C)]),
          boxShadow: [
            BoxShadow(
              color: AppColors.red.withValues(alpha: 0.4),
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
