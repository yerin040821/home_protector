// lib/models/user_model.dart
enum BuildingType {
  semiBasement, // 반지하
  groundFloor, // 1층(저지대)
  highRise, // 고층 아파트/빌딩
}

extension BuildingTypeExtension on BuildingType {
  String get label {
    switch (this) {
      case BuildingType.semiBasement:
        return '반지하';
      case BuildingType.groundFloor:
        return '1층(저지대)';
      case BuildingType.highRise:
        return '고층 아파트/빌딩';
    }
  }

  /// Ready-Flow API 의 `building_type` enum 값으로 매핑.
  /// (현재 모델은 사용하지 않는 예약 필드지만 명세에 맞춰 전달한다.)
  String get apiValue {
    switch (this) {
      case BuildingType.semiBasement:
        return 'underground';
      case BuildingType.groundFloor:
        return 'residential';
      case BuildingType.highRise:
        return 'residential';
    }
  }

  double get floodRiskScore {
    switch (this) {
      case BuildingType.semiBasement:
        return 88.0;
      case BuildingType.groundFloor:
        return 55.0;
      case BuildingType.highRise:
        return 35.0;
    }
  }

  AlertLevel get alertLevel {
    switch (this) {
      case BuildingType.semiBasement:
        return AlertLevel.critical;
      case BuildingType.groundFloor:
        return AlertLevel.warning;
      case BuildingType.highRise:
        return AlertLevel.info;
    }
  }
}

enum AlertLevel { critical, warning, info }

class UserModel {
  final String address; // 표시용 실제 거주지 전체 주소 (지도 핀에도 사용)
  final BuildingType buildingType;
  final String district; // 예측 기준 구 + 동 (예: 관악구 신림동)
  final int? admCd; // 예측에 쓰는 법정동코드 (커버리지 내 동/구 대표)
  final double? lat; // 실제 거주지 위도 (지도 핀)
  final double? lon; // 실제 거주지 경도 (지도 핀)

  const UserModel({
    this.address = '서울특별시 관악구 신림동',
    this.buildingType = BuildingType.semiBasement,
    this.district = '관악구 신림동',
    this.admCd = 1162010200, // 관악구 신림동
    this.lat,
    this.lon,
  });

  UserModel copyWith({
    String? address,
    BuildingType? buildingType,
    String? district,
    int? admCd,
    double? lat,
    double? lon,
    bool clearAdmCd = false,
    bool clearLatLon = false,
  }) {
    return UserModel(
      address: address ?? this.address,
      buildingType: buildingType ?? this.buildingType,
      district: district ?? this.district,
      admCd: clearAdmCd ? null : (admCd ?? this.admCd),
      lat: clearLatLon ? null : (lat ?? this.lat),
      lon: clearLatLon ? null : (lon ?? this.lon),
    );
  }
}
