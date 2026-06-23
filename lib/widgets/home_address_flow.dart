// lib/widgets/home_address_flow.dart
//
// "실제 거주지 주소를 SDK 로 받아 → 동/구를 예측 커버리지로 해석"하는 공통 흐름.
// 셋업/설정/지도 탭에서 모두 같은 동작을 쓰도록 한 곳에 모았다.
//
//  - 실제 주소(+위경도)는 표시·지도 핀에 그대로 보존한다.
//  - 예측 기준(district/admCd)은 커버리지 동으로 해석한다.
//    · 정확 매칭   : 사용자의 법정동이 그대로 지원 대상
//    · 구 단위 근사 : 같은 구의 인근 지원 동으로 예측(안내 표시)
//    · 커버리지 밖 : 지원 지역을 직접 고르도록 안내
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../services/address_search.dart';
import '../services/flood_api_service.dart';
import '../theme/app_theme.dart';
import 'dong_picker.dart';

/// 주소 선택의 최종 결과(실주소 + 예측 기준 동).
class HomeSelection {
  final String address; // 실제 거주지 전체 주소(표시/핀)
  final DongInfo dong; // 예측 기준 커버리지 동
  final bool exact; // 실제 법정동이 그대로 예측 대상인지
  final double? lat;
  final double? lon;

  const HomeSelection({
    required this.address,
    required this.dong,
    required this.exact,
    this.lat,
    this.lon,
  });

  String get district => dong.label;
}

/// 주소 검색 SDK → 커버리지 해석 → (필요 시)지원 지역 선택까지의 전체 흐름.
/// 사용자가 끝까지 취소하면 null.
Future<HomeSelection?> pickHomeAddress(BuildContext context) async {
  final provider = context.read<AppProvider>();
  // 커버리지 목록이 준비돼야 동/구 해석이 정확하다 — 먼저 로드를 보장한다.
  if (!provider.coverageLoaded || provider.coverage.isEmpty) {
    await provider.loadCoverage();
  }
  if (!context.mounted) return null;

  final result = await showAddressSearch(context);
  if (result == null || !context.mounted) return null;

  // 서울 외 지역 — 현재 예측 미지원.
  if (result.sido.isNotEmpty && !result.isSeoul) {
    final picked = await _fallbackPick(
      context,
      title: '서울 지역만 지원돼요',
      message: '“${result.sigungu} ${result.bname}”은(는) 현재 AI 침수 예측 '
          '커버리지(서울 일부 지역) 밖입니다.\n가까운 지원 지역을 선택해 주세요.',
    );
    if (picked == null) return null;
    return HomeSelection(
      address: result.address.isEmpty ? picked.fullAddress : result.address,
      dong: picked,
      exact: false,
      lat: result.lat,
      lon: result.lon,
    );
  }

  final res = resolveCoverageForAddress(
    gu: result.gu,
    bname: result.bname,
    coverage: provider.coverage,
  );

  // 같은 구에 지원 동이 없음 — 직접 선택.
  if (res.dong == null) {
    final picked = await _fallbackPick(
      context,
      title: '예측 커버리지 밖이에요',
      message: '“${result.gu} ${result.bname}”은(는) 현재 AI 침수 예측 대상 '
          '93개 법정동에 포함되지 않습니다.\n가까운 지원 지역을 선택해 주세요.',
    );
    if (picked == null) return null;
    return HomeSelection(
      address: result.address,
      dong: picked,
      exact: false,
      lat: result.lat,
      lon: result.lon,
    );
  }

  return HomeSelection(
    address: result.address.isEmpty ? res.dong!.fullAddress : result.address,
    dong: res.dong!,
    exact: res.exactDong,
    lat: result.lat,
    lon: result.lon,
  );
}

/// 커버리지 밖일 때 안내 후 지원 지역(커버리지 동) 선택 모달을 띄운다.
Future<DongInfo?> _fallbackPick(
  BuildContext context, {
  required String title,
  required String message,
}) async {
  final proceed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.bgSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.amber),
          const SizedBox(width: 8),
          Expanded(
            child: Text(title,
                style: GoogleFonts.notoSans(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary)),
          ),
        ],
      ),
      content: Text(message,
          style: GoogleFonts.notoSans(
              fontSize: 13, color: AppColors.textSecondary, height: 1.5)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text('취소',
              style: GoogleFonts.notoSans(color: AppColors.textMuted)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.amber),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text('지원 지역 선택',
              style: GoogleFonts.notoSans(
                  color: Colors.white, fontWeight: FontWeight.w700)),
        ),
      ],
    ),
  );
  if (proceed != true || !context.mounted) return null;
  final selection = await showDongPicker(context);
  return selection?.dong;
}
