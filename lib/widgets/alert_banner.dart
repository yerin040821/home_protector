// lib/widgets/alert_banner.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../theme/app_theme.dart';
import '../providers/app_provider.dart';

class AlertBanner extends StatefulWidget {
  final UserModel user;
  const AlertBanner({super.key, required this.user});

  @override
  State<AlertBanner> createState() => _AlertBannerState();
}

class _AlertBannerState extends State<AlertBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final level = provider.alertLevel;
    final risk = provider.floodProbability.toDouble();

    Color primaryColor;
    Color bgColor;
    Color borderColor;
    String iconEmoji;

    switch (level) {
      case AlertLevel.critical:
        primaryColor = AppColors.red;
        bgColor = AppColors.redLight;
        borderColor = AppColors.red.withValues(alpha: 0.3);
        iconEmoji = '🚨';
        break;
      case AlertLevel.warning:
        primaryColor = AppColors.amber;
        bgColor = AppColors.amberLight;
        borderColor = AppColors.amber.withValues(alpha: 0.3);
        iconEmoji = '⚠️';
        break;
      case AlertLevel.info:
        primaryColor = AppColors.info;
        bgColor = const Color(0xFFEFF6FF);
        borderColor = AppColors.info.withValues(alpha: 0.3);
        iconEmoji = '🅿️';
        break;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: borderColor.withValues(alpha: 0.6), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.25),
            blurRadius: 16,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (level == AlertLevel.critical)
                AnimatedBuilder(
                  animation: _pulseAnim,
                  builder: (_, child) => Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: primaryColor.withValues(
                          alpha: _pulseAnim.value),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withValues(alpha: 0.5),
                          blurRadius: 6,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              Text(iconEmoji,
                  style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                      color: primaryColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  level == AlertLevel.critical
                      ? '위험 경보'
                      : level == AlertLevel.warning
                          ? '주의 경보'
                          : '정보 알림',
                  style: GoogleFonts.notoSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: primaryColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Spacer(),
              _RiskGauge(risk: risk, color: primaryColor),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            provider.alertMessage,
            style: GoogleFonts.notoSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _ActionChip(
                icon: Icons.shield_rounded,
                label: '대피 경로 보기',
                color: primaryColor,
              ),
              const SizedBox(width: 8),
              _ActionChip(
                icon: Icons.notifications_rounded,
                label: '알림 설정',
                color: AppColors.textMuted,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RiskGauge extends StatelessWidget {
  final double risk;
  final Color color;
  const _RiskGauge({required this.risk, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text('위험도',
            style: GoogleFonts.notoSans(
                fontSize: 10, color: AppColors.textMuted)),
        Text(
          '${risk.toInt()}%',
          style: GoogleFonts.outfit(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _ActionChip(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.notoSans(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
