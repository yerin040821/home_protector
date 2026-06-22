// lib/widgets/drainage_chart.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';

class DrainageChartWidget extends StatefulWidget {
  const DrainageChartWidget({super.key});

  @override
  State<DrainageChartWidget> createState() => _DrainageChartWidgetState();
}

class _DrainageChartWidgetState extends State<DrainageChartWidget>
    with SingleTickerProviderStateMixin {
  final Random _random = Random();
  final List<FlSpot> _spots = [];
  late Timer _timer;
  double _xCounter = 0;
  late AnimationController _fadeController;

  double _currentSpeed = 42.0;
  String _statusLabel = '정상';
  Color _statusColor = AppColors.success;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    for (int i = 0; i < 20; i++) {
      _spots.add(FlSpot(_xCounter, _generateValue()));
      _xCounter++;
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        final newVal = _generateValue();
        _spots.add(FlSpot(_xCounter, newVal));
        if (_spots.length > 20) _spots.removeAt(0);
        _xCounter++;
        _currentSpeed = newVal * 10;
        _updateStatus(newVal);
      });
    });
  }

  double _generateValue() {
    final base = 5.5 + sin(_xCounter * 0.3) * 1.5;
    final noise = (_random.nextDouble() - 0.5) * 1.5;
    return (base + noise).clamp(1.0, 9.5);
  }

  void _updateStatus(double val) {
    if (val >= 7.5) {
      _statusLabel = '위험';
      _statusColor = AppColors.red;
    } else if (val >= 5.5) {
      _statusLabel = '주의';
      _statusColor = AppColors.amber;
    } else {
      _statusLabel = '정상';
      _statusColor = AppColors.success;
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeController,
      child: Container(
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
                    color: AppColors.info.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.water_rounded,
                      color: AppColors.info, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '실시간 배수구 처리 속도',
                        style: GoogleFonts.notoSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '신림동 3번 배수구 · 1초 갱신',
                        style: GoogleFonts.notoSans(
                            fontSize: 11, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.red.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: AppColors.red.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _PulsingDot(color: AppColors.red),
                      const SizedBox(width: 4),
                      Text(
                        'LIVE',
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.red,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _StatBadge(
                    label: '현재 속도',
                    value: '${_currentSpeed.toStringAsFixed(1)} L/s',
                    color: _statusColor),
                const SizedBox(width: 10),
                _StatBadge(
                    label: '상태', value: _statusLabel, color: _statusColor),
                const SizedBox(width: 10),
                _StatBadge(
                  label: '포화도',
                  value:
                      '${((_currentSpeed / 95) * 100).toStringAsFixed(0)}%',
                  color: AppColors.textSecondary,
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 130,
              child: _spots.length < 2
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.amber, strokeWidth: 2))
                  : LineChart(
                      LineChartData(
                        minY: 0,
                        maxY: 10,
                        clipData: const FlClipData.all(),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          getDrawingHorizontalLine: (val) => FlLine(
                            color: AppColors.border.withValues(alpha: 0.5),
                            strokeWidth: 1,
                            dashArray: [4, 4],
                          ),
                          horizontalInterval: 2.5,
                        ),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 28,
                              interval: 2.5,
                              getTitlesWidget: (val, meta) => Text(
                                val.toInt().toString(),
                                style: GoogleFonts.outfit(
                                  fontSize: 9,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ),
                          ),
                          rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                        ),
                        lineBarsData: [
                          // Danger threshold
                          LineChartBarData(
                            spots: [
                              FlSpot(_spots.first.x, 7.5),
                              FlSpot(_spots.last.x, 7.5),
                            ],
                            isCurved: false,
                            color: AppColors.red.withValues(alpha: 0.4),
                            barWidth: 1,
                            dashArray: [5, 5],
                            dotData: const FlDotData(show: false),
                          ),
                          // Main data
                          LineChartBarData(
                            spots: List.from(_spots),
                            isCurved: true,
                            curveSmoothness: 0.35,
                            color: AppColors.info,
                            barWidth: 2.5,
                            dotData: FlDotData(
                              show: true,
                              getDotPainter: (spot, pct, bar, idx) {
                                if (idx == _spots.length - 1) {
                                  return FlDotCirclePainter(
                                    radius: 4,
                                    color: AppColors.info,
                                    strokeColor: Colors.white,
                                    strokeWidth: 2,
                                  );
                                }
                                return FlDotCirclePainter(
                                    radius: 0,
                                    color: Colors.transparent);
                              },
                            ),
                            belowBarData: BarAreaData(
                              show: true,
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  AppColors.info.withValues(alpha: 0.25),
                                  AppColors.info.withValues(alpha: 0.0),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOut,
                    ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _LegendItem(color: AppColors.info, label: '배수 속도'),
                const SizedBox(width: 16),
                _LegendItem(
                    color: AppColors.red.withValues(alpha: 0.6),
                    label: '위험 임계값',
                    dashed: true),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  final Color color;
  const _PulsingDot({required this.color});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) => Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color
              .withValues(alpha: 0.5 + _ctrl.value * 0.5),
        ),
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatBadge(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: GoogleFonts.notoSans(
                    fontSize: 10, color: AppColors.textMuted)),
            const SizedBox(height: 2),
            Text(value,
                style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: color)),
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final bool dashed;
  const _LegendItem(
      {required this.color,
      required this.label,
      this.dashed = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 20,
          height: 2,
          child: dashed
              ? Row(children: [
                  Container(width: 5, height: 2, color: color),
                  Container(
                      width: 3, height: 2, color: Colors.transparent),
                  Container(width: 5, height: 2, color: color),
                ])
              : Container(color: color),
        ),
        const SizedBox(width: 5),
        Text(label,
            style: GoogleFonts.notoSans(
                fontSize: 11, color: AppColors.textMuted)),
      ],
    );
  }
}
