// lib/models/user_model.dart
enum BuildingType {
  semiBasement,  // 반지하
  groundFloor,   // 1층(저지대)
  highRise,      // 고층 아파트/빌딩
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

  String get alertMessage {
    switch (this) {
      case BuildingType.semiBasement:
        return '🚨 경고: 남구 주월동 반지하 거주자님, 24시간 내 침수 위험도는 88%입니다.';
      case BuildingType.groundFloor:
        return '⚠️ 주의: 저지대 거주자님, 침수 대비 모래주머니 비치를 권고드립니다. 위험도 55%';
      case BuildingType.highRise:
        return '🅿️ 알림: 지하주차장 차량 대피 권고. 고층 건물 위험도 35%';
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
  final String address;
  final BuildingType buildingType;
  final String district;

  const UserModel({
    this.address = '광주광역시 남구 주월동',
    this.buildingType = BuildingType.semiBasement,
    this.district = '남구 주월동',
  });

  UserModel copyWith({
    String? address,
    BuildingType? buildingType,
    String? district,
  }) {
    return UserModel(
      address: address ?? this.address,
      buildingType: buildingType ?? this.buildingType,
      district: district ?? this.district,
    );
  }
}
