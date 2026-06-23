// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter
// lib/widgets/kakao_map_web.dart
import 'dart:html' as html;
import 'dart:js' as js;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';

class KakaoMapWebWidget extends StatefulWidget {
  final String address;
  final double? lat;
  final double? lon;
  const KakaoMapWebWidget(
      {super.key, required this.address, this.lat, this.lon});

  @override
  State<KakaoMapWebWidget> createState() => _KakaoMapWebWidgetState();
}

class _KakaoMapWebWidgetState extends State<KakaoMapWebWidget> {
  late String _viewId;
  late html.DivElement _element;

  @override
  void initState() {
    super.initState();
    _viewId = 'kakao-map-${DateTime.now().millisecondsSinceEpoch}';
    _element = html.DivElement()
      ..id = 'kakao-map-container-$_viewId'
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.backgroundColor = '#F8FAFC';

    ui_web.platformViewRegistry.registerViewFactory(
      _viewId,
      (int viewId) => _element,
    );

    Future.delayed(const Duration(milliseconds: 150), () {
      js.context.callMethod(
          'initKakaoMap', [_element, widget.address, widget.lat, widget.lon]);
    });
  }

  @override
  void didUpdateWidget(KakaoMapWebWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.address != widget.address ||
        oldWidget.lat != widget.lat ||
        oldWidget.lon != widget.lon) {
      js.context.callMethod(
          'updateKakaoMap', [_element, widget.address, widget.lat, widget.lon]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: _viewId);
  }
}

Widget createKakaoMapWidget({
  required String address,
  required int probability,
  double? lat,
  double? lon,
}) {
  return KakaoMapWebWidget(address: address, lat: lat, lon: lon);
}
