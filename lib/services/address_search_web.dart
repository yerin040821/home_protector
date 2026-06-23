// lib/services/address_search_web.dart
//
// 웹 주소 검색: 다음(카카오) 우편번호 서비스 JS 팝업을 띄운다.
// 팝업/지오코딩 로직은 web/index.html 의 window.openDaumPostcode 에 있고,
// 여기서는 dart:js 로 호출하고 콜백 결과(원시값)를 AddressResult 로 변환한다.
// (dart:js 는 callMethod 인자로 넘긴 Dart 클로저를 JS 함수로 자동 변환한다.)
// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:async';
import 'dart:js' as js;

import 'package:flutter/widgets.dart';

import 'address_result.dart';

Future<AddressResult?> searchAddress(BuildContext context) {
  final completer = Completer<AddressResult?>();
  void done(AddressResult? value) {
    if (!completer.isCompleted) completer.complete(value);
  }

  double? toDouble(dynamic v) => v == null ? null : (v as num).toDouble();

  void onComplete(dynamic address, dynamic sido, dynamic sigungu, dynamic bname,
      dynamic lat, dynamic lon) {
    done(AddressResult(
      address: (address as String?) ?? '',
      sido: (sido as String?) ?? '',
      sigungu: (sigungu as String?) ?? '',
      bname: (bname as String?) ?? '',
      lat: toDouble(lat),
      lon: toDouble(lon),
    ));
  }

  void onClose() => done(null);

  try {
    js.context.callMethod('openDaumPostcode', [onComplete, onClose]);
  } catch (_) {
    done(null);
  }
  return completer.future;
}
