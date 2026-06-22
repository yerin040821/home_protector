// lib/widgets/ai_weight_card.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../theme/app_theme.dart';
import '../providers/app_provider.dart';

class AiWeightCard extends StatefulWidget {
  final UserModel user;
  const AiWeightCard({super.key, required this.user});

  @override
  State<AiWeightCard> createState() => _AiWeightCardState();
}

class _AiWeightCardState extends State<AiWeightCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late List<Animation<double>> _barAnims;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _barAnims = List.generate(
      3,
      (i) => Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _animController,
          curve:
              Interval(i * 0.2, 0.6 + i * 0.2, curve: Curves.easeOutCubic),
        ),
      ),
    );
    Future.delayed(const Duration(milliseconds: 300),
        () => _animController.forward());
  }

  @override
  void didUpdateWidget(AiWeightCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user.buildingType != widget.user.buildingType) {
      _animController.reset();
      _animController.forward();
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  List<_WeightItem> _getWeights(AppProvider provider) {
    final weather = provider.weatherData;

    // 강수량 팩터 비율 (0.0 ~ 60.0 mm/h 기준)
    double rainRatio = (weather.precipitation / 60.0).clamp(0.1, 0.95);
    // 고도 팩터 비율 (0.0 ~ 60.0 m 기준, 낮을수록 위험하므로 역산)
    double elevRatio = ((60.0 - weather.elevation) / 60.0).clamp(0.1, 0.95);
    // 하수구 팩터 비율 (0.0 ~ 250.0 mm/h 기준, 낮을수록 위험하므로 역산)
    double drainRatio = ((250.0 - weather.drainageCapacity) / 250.0).clamp(0.1, 0.95);

    return [
      _WeightItem(
        icon: Icons.cloud_rounded,
        label: '기상청 강수량',
        subLabel: '${weather.precipitation.toInt()}mm/h 예보',
        weight: rainRatio,
        weightLabel: '${(rainRatio * 100).toInt()}%',
        color: AppColors.info,
      ),
      _WeightItem(
        icon: Icons.terrain_rounded,
        label: '지형 해발고도',
        subLabel: '해발 ${weather.elevation.toInt()}m · ${weather.elevation < 20 ? '저지대' : weather.elevation < 40 ? '보통' : '안전'}',
        weight: elevRatio,
        weightLabel: '${(elevRatio * 100).toInt()}%',
        color: AppColors.amber,
      ),
      _WeightItem(
        icon: Icons.water_drop_rounded,
        label: '하수구 상태',
        subLabel: '배수량 ${weather.drainageCapacity.toInt()}mm/h',
        weight: drainRatio,
        weightLabel: '${(drainRatio * 100).toInt()}%',
        color: weather.drainageCapacity < 100 ? AppColors.red : weather.drainageCapacity < 180 ? AppColors.amber : AppColors.success,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final weights = _getWeights(provider);
    final risk = provider.floodProbability.toDouble();

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
                  gradient: const LinearGradient(
                      colors: [AppColors.amber, AppColors.red]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.psychology_rounded,
                    color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI 침수 위험도 분석',
                      style: GoogleFonts.notoSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '3개 지표 가중치 종합 계산',
                      style: GoogleFonts.notoSans(
                          fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    AppColors.red.withValues(alpha: 0.2),
                    AppColors.amber.withValues(alpha: 0.2),
                  ]),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.amber.withValues(alpha: 0.4)),
                ),
                child: Column(
                  children: [
                    Text('종합',
                        style: GoogleFonts.notoSans(
                            fontSize: 10, color: AppColors.textMuted)),
                    Text(
                      '${risk.toInt()}%',
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.amber,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Formula card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _FormulaChip(label: '강수량', color: AppColors.info),
                _FormulaOp(label: '×45%'),
                _FormulaChip(label: '고도', color: AppColors.amber),
                _FormulaOp(label: '×35%'),
                _FormulaChip(label: '하수구', color: AppColors.warning),
                _FormulaOp(label: '×20%'),
                const Text('=',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 14)),
                const SizedBox(width: 6),
                Text(
                  '${risk.toInt()}%',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.amber,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Weight bars
          ...List.generate(weights.length, (i) {
            return AnimatedBuilder(
              animation: _barAnims[i],
              builder: (_, child) => _WeightBar(
                item: weights[i],
                progress: _barAnims[i].value,
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _WeightItem {
  final IconData icon;
  final String label;
  final String subLabel;
  final double weight;
  final String weightLabel;
  final Color color;
  const _WeightItem({
    required this.icon,
    required this.label,
    required this.subLabel,
    required this.weight,
    required this.weightLabel,
    required this.color,
  });
}

class _WeightBar extends StatelessWidget {
  final _WeightItem item;
  final double progress;
  const _WeightBar({required this.item, required this.progress});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(item.icon, color: item.color, size: 16),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  item.label,
                  style: GoogleFonts.notoSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(item.subLabel,
                  style: GoogleFonts.notoSans(
                      fontSize: 11, color: AppColors.textMuted)),
              const SizedBox(width: 8),
              Text(
                item.weightLabel,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: item.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Stack(
              children: [
                Container(height: 6, color: AppColors.borderLight),
                FractionallySizedBox(
                  widthFactor: item.weight * progress,
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        item.color.withValues(alpha: 0.6),
                        item.color,
                      ]),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FormulaChip extends StatelessWidget {
  final String label;
  final Color color;
  const _FormulaChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: GoogleFonts.notoSans(
              fontSize: 10, color: color, fontWeight: FontWeight.w600)),
    );
  }
}

class _FormulaOp extends StatelessWidget {
  final String label;
  const _FormulaOp({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Text(label,
          style:
              GoogleFonts.outfit(fontSize: 10, color: AppColors.textMuted)),
    );
  }
}
