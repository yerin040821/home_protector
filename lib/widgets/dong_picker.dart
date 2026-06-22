// lib/widgets/dong_picker.dart
//
// 지원 지역(서울 법정동) 검색·선택 모달.
//
// 자유 입력 대신 이 모달로 주소 선택을 강제하면, 선택 결과에 항상
// 법정동코드(adm_cd)가 실려 예측 API 가 404 없이 해결된다.
// 목록은 Ready-Flow `/api/dongs` 응답(AppProvider.coverage)을 사용한다.
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../services/flood_api_service.dart';
import '../theme/app_theme.dart';

/// 지역 선택 모달을 띄우고 선택된 [DongInfo] 를 반환한다(취소 시 null).
Future<DongInfo?> showDongPicker(BuildContext context) {
  // 모달을 여는 시점에 커버리지가 비어 있으면 한 번 더 로드를 시도한다.
  final provider = context.read<AppProvider>();
  if (!provider.coverageLoaded || provider.coverage.isEmpty) {
    provider.loadCoverage();
  }
  return showModalBottomSheet<DongInfo>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _DongPickerSheet(),
  );
}

class _DongPickerSheet extends StatefulWidget {
  const _DongPickerSheet();

  @override
  State<_DongPickerSheet> createState() => _DongPickerSheetState();
}

class _DongPickerSheetState extends State<_DongPickerSheet> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final all = provider.coverage;
    final q = _query.trim();
    final filtered = q.isEmpty
        ? all
        : all
            .where((d) =>
                d.label.contains(q) || d.gu.contains(q) || (d.dong ?? '').contains(q))
            .toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.bgPrimary,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    const Icon(Icons.travel_explore_rounded,
                        color: AppColors.amber, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '지원 지역 검색',
                      style: GoogleFonts.notoSans(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${all.length}개 동',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: _searchCtrl,
                  autofocus: false,
                  style: GoogleFonts.notoSans(
                      color: AppColors.textPrimary, fontSize: 15),
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: '구 또는 동 이름으로 검색 (예: 신림동)',
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: AppColors.textMuted),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear_rounded,
                                color: AppColors.textMuted, size: 20),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _query = '');
                            },
                          ),
                    filled: true,
                    fillColor: AppColors.bgSurface,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        size: 13, color: AppColors.textMuted),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        'AI 침수 예측이 가능한 서울 지역만 표시됩니다.',
                        style: GoogleFonts.notoSans(
                            fontSize: 11, color: AppColors.textMuted),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(child: _buildList(provider, filtered, scrollController)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildList(
    AppProvider provider,
    List<DongInfo> items,
    ScrollController controller,
  ) {
    if (!provider.coverageLoaded) {
      return const Center(
        child: CircularProgressIndicator(
            color: AppColors.amber, strokeWidth: 2.5),
      );
    }
    if (provider.coverage.isEmpty) {
      return _emptyState(
        icon: Icons.wifi_off_rounded,
        title: '지역 목록을 불러오지 못했어요',
        subtitle: '네트워크 연결을 확인한 뒤 다시 시도해 주세요.',
        onRetry: () => provider.loadCoverage(),
      );
    }
    if (items.isEmpty) {
      return _emptyState(
        icon: Icons.search_off_rounded,
        title: '검색 결과가 없어요',
        subtitle: '“$_query” 와 일치하는 지원 지역이 없습니다.',
      );
    }
    return ListView.separated(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 6),
      itemBuilder: (context, i) {
        final d = items[i];
        return Material(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => Navigator.pop(context, d),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.amber.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.location_on_rounded,
                        color: AppColors.amber, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          d.label,
                          style: GoogleFonts.notoSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '법정동코드 ${d.admCd}',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded,
                      color: AppColors.textMuted),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onRetry,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: AppColors.textMuted),
            const SizedBox(height: 14),
            Text(
              title,
              style: GoogleFonts.notoSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.notoSans(
                  fontSize: 12, color: AppColors.textMuted, height: 1.5),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded,
                    size: 16, color: AppColors.amber),
                label: Text('다시 시도',
                    style: GoogleFonts.notoSans(color: AppColors.amber)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.amber),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
