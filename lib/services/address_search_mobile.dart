// lib/services/address_search_mobile.dart
//
// 모바일(Android/iOS) 주소 검색: kpostal 이 다음 우편번호 서비스를
// InAppWebView 풀스크린으로 띄운다. 선택 후 플랫폼 지오코딩으로 위경도를 채운다.
import 'package:flutter/material.dart';
import 'package:kpostal/kpostal.dart';

import 'address_result.dart';

Future<AddressResult?> searchAddress(BuildContext context) async {
  Kpostal? picked;
  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => KpostalView(
        title: '주소 검색',
        callback: (Kpostal result) => picked = result,
      ),
    ),
  );

  final r = picked;
  if (r == null) return null;

  double? lat = r.kakaoLatitude ?? r.latitude;
  double? lon = r.kakaoLongitude ?? r.longitude;
  if (lat == null || lon == null) {
    // 키 없이도 동작하는 플랫폼 지오코더로 위경도 보강(실패해도 무방).
    try {
      final loc = await r.latLng;
      lat = loc?.latitude;
      lon = loc?.longitude;
    } catch (_) {/* 위경도 없이 진행 — 지도는 주소 문자열로 폴백 */}
  }

  final addr = r.jibunAddress.isNotEmpty ? r.jibunAddress : r.address;
  return AddressResult(
    address: addr,
    sido: r.sido,
    sigungu: r.sigungu,
    bname: r.bname,
    lat: lat,
    lon: lon,
  );
}
