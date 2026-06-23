// lib/widgets/kakao_map_stub.dart
import 'package:flutter/material.dart';

Widget createKakaoMapWidget({
  required String address,
  required int probability,
  double? lat,
  double? lon,
}) {
  throw UnsupportedError('Cannot create Kakao Map without web or mobile support.');
}
