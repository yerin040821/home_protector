// lib/services/address_result.dart
//
// 주소 검색 SDK(웹: 다음 우편번호, 모바일: kpostal) 결과의 플랫폼 공통 모델.
// 임의 텍스트 입력 대신 SDK 모달에서 받은 구조화된 주소만 다룬다.

/// 우편번호/주소 SDK 가 돌려준 한 건의 주소.
class AddressResult {
  /// 표시·지오코딩용 전체 주소(지번 우선 — 법정동이 드러나야 동 매칭이 쉽다).
  final String address;

  /// 시/도 (예: 서울특별시)
  final String sido;

  /// 시/군/구 (예: 성동구, 또는 "고양시 덕양구")
  final String sigungu;

  /// 법정동/법정리 (예: 상왕십리동)
  final String bname;

  /// 위도/경도(있으면 지도 핀에 사용). SDK·플랫폼에 따라 없을 수 있다.
  final double? lat;
  final double? lon;

  const AddressResult({
    required this.address,
    this.sido = '',
    this.sigungu = '',
    this.bname = '',
    this.lat,
    this.lon,
  });

  /// 시/군/구 문자열에서 '구' 토큰만 추출(예: "고양시 덕양구" → "덕양구").
  String get gu {
    final parts = sigungu.trim().split(RegExp(r'\s+'));
    for (final p in parts.reversed) {
      if (p.endsWith('구')) return p;
    }
    return parts.isNotEmpty ? parts.last : sigungu.trim();
  }

  /// 서울 지역 여부(현재 예측 커버리지는 서울 한정).
  bool get isSeoul => sido.contains('서울');
}
