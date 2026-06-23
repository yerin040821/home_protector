// lib/widgets/kakao_map_mobile.dart
//
// 모바일/데스크톱(io) 빌드용 지도 플레이스홀더.
// 대화형 카카오 지도는 웹 빌드(kakao_map_web.dart)에서 동작하며,
// 여기서는 선택 지역과 위험도를 요약해 보여 준다.
// (보안상 API 키는 화면에 노출하지 않는다.)
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

Widget createKakaoMapWidget({
  required String address,
  required int probability,
  double? lat,
  double? lon,
}) {
  final bool known = probability >= 0;
  final Color riskColor = !known
      ? AppColors.textMuted
      : probability >= 60
          ? AppColors.red
          : probability >= 30
              ? AppColors.amber
              : AppColors.success;
  final String riskLabel = !known
      ? '데이터 없음'
      : probability >= 60
          ? '위험'
          : probability >= 30
              ? '주의'
              : '관심';

  return Container(
    color: AppColors.bgSurface,
    padding: const EdgeInsets.all(24),
    child: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: riskColor.withValues(alpha: 0.10),
              shape: BoxShape.circle,
              border: Border.all(
                  color: riskColor.withValues(alpha: 0.3), width: 2),
            ),
            child: Icon(Icons.map_rounded, color: riskColor, size: 46),
          ),
          const SizedBox(height: 20),
          Text(
            address,
            textAlign: TextAlign.center,
            style: GoogleFonts.notoSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: riskColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: riskColor.withValues(alpha: 0.35)),
            ),
            child: Text(
              known ? 'AI 침수확률 $probability% · $riskLabel' : 'AI 침수확률 $riskLabel',
              style: GoogleFonts.notoSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: riskColor,
              ),
            ),
          ),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.bgPrimary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.public_rounded,
                    color: AppColors.amber, size: 16),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    '대화형 카카오 지도는 웹 브라우저(Chrome)에서\n전체 화면으로 제공됩니다.',
                    style: GoogleFonts.notoSans(
                      fontSize: 12,
                      color: AppColors.textMuted,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
