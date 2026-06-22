// lib/widgets/live_flood_card.dart
//
// Ready-Flow AI `/api/predict` 실시간 결과 카드.
// 앱 자체 시나리오 위험도와 별개로, 외부 AI 모델의 실측 침수 확률을
// 솔직하게(법정동 라벨과 함께) 보여 준다.
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

class LiveFloodCard extends StatelessWidget {
  const LiveFloodCard({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

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
                  color: AppColors.info.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.cloud_sync_rounded,
                    color: AppColors.info, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ready-Flow AI 실시간 예측',
                      style: GoogleFonts.notoSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '법정동 단위 머신러닝 침수 확률',
                      style: GoogleFonts.notoSans(
                          fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              _statusChip(provider),
            ],
          ),
          const SizedBox(height: 14),
          _buildBody(context, provider),
        ],
      ),
    );
  }

  Widget _statusChip(AppProvider provider) {
    late final Color color;
    late final String label;
    if (provider.isApiLoading) {
      color = AppColors.textMuted;
      label = '동기화 중';
    } else if (provider.apiPredict != null) {
      color = AppColors.success;
      label = '연결됨';
    } else if (provider.isCoverageError) {
      color = AppColors.amber;
      label = '미지원 지역';
    } else {
      color = AppColors.red;
      label = '오프라인';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.notoSans(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, AppProvider provider) {
    if (provider.isApiLoading && provider.apiPredict == null) {
      return _infoRow(
        const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
              strokeWidth: 2, color: AppColors.amber),
        ),
        'AI 모델에서 최신 침수 확률을 불러오는 중…',
      );
    }

    final predict = provider.apiPredict;
    if (predict != null) {
      final percent = predict.percent;
      final color = percent >= 60
          ? AppColors.red
          : percent >= 30
              ? AppColors.amber
              : AppColors.success;
      return Row(
        children: [
          // 게이지 수치
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '$percent',
                    style: GoogleFonts.outfit(
                      fontSize: 38,
                      fontWeight: FontWeight.w800,
                      color: color,
                      height: 1,
                    ),
                  ),
                  Text(
                    '%',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                '${predict.gu}${predict.dong != null ? ' ${predict.dong}' : ''} · 침수 확률',
                style: GoogleFonts.notoSans(
                    fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Stack(
                children: [
                  Container(height: 10, color: AppColors.borderLight),
                  FractionallySizedBox(
                    widthFactor: (percent / 100).clamp(0.02, 1.0),
                    child: Container(
                      height: 10,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          color.withValues(alpha: 0.55),
                          color,
                        ]),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    if (provider.isCoverageError) {
      return _infoRow(
        const Icon(Icons.location_off_rounded,
            color: AppColors.amber, size: 18),
        '현재 지역은 AI 예측 커버리지(서울 93개 법정동) 밖입니다. 지도 탭에서 지원 지역을 선택해 주세요.',
      );
    }

    return _infoRow(
      const Icon(Icons.cloud_off_rounded, color: AppColors.red, size: 18),
      provider.apiError ?? '예측 서버에 연결할 수 없습니다.',
      action: TextButton(
        onPressed: () => provider.fetchFloodPrediction(),
        child: Text('재시도',
            style: GoogleFonts.notoSans(
                color: AppColors.amber, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _infoRow(Widget leading, String text, {Widget? action}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        leading,
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.notoSans(
              fontSize: 12.5,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ),
        ?action,
      ],
    );
  }
}
