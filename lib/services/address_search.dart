// lib/services/address_search.dart
//
// 플랫폼별 주소 검색 SDK 모달의 단일 진입점.
//   - 웹    : 다음(카카오) 우편번호 서비스 JS 팝업 (web/index.html)
//   - 모바일: kpostal(InAppWebView) 풀스크린 검색
// 임의 주소 텍스트 입력을 막고 SDK 가 검증한 주소만 받기 위함(CLAUDE.md §2).
import 'package:flutter/widgets.dart';

import 'address_result.dart';
import 'address_search_stub.dart'
    if (dart.library.html) 'address_search_web.dart'
    if (dart.library.io) 'address_search_mobile.dart' as platform;

export 'address_result.dart';

/// 주소 검색 SDK 모달을 띄우고 선택된 주소를 반환한다(취소 시 null).
Future<AddressResult?> showAddressSearch(BuildContext context) =>
    platform.searchAddress(context);
