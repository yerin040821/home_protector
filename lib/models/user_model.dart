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
  final String address; // 표시용 전체 주소
  final BuildingType buildingType;
  final String district; // 구 + 동 (예: 관악구 신림동)
  final int? admCd; // 선택된 법정동코드 (있으면 예측 시 지오코딩 생략)

  const UserModel({
    this.address = '서울특별시 관악구 신림동',
    this.buildingType = BuildingType.semiBasement,
    this.district = '관악구 신림동',
    this.admCd = 1162010200, // 관악구 신림동
  });

  UserModel copyWith({
    String? address,
    BuildingType? buildingType,
    String? district,
    int? admCd,
    bool clearAdmCd = false,
  }) {
    return UserModel(
      address: address ?? this.address,
      buildingType: buildingType ?? this.buildingType,
      district: district ?? this.district,
      admCd: clearAdmCd ? null : (admCd ?? this.admCd),
    );
  }
}
