/// Location type from DB (Parking Lot, Coffee Shop, Car Wash, etc.) - for adding locations anywhere.
class LocationType {
  final int locationTypeId;
  final String typeName;

  LocationType({required this.locationTypeId, required this.typeName});

  factory LocationType.fromJson(Map<String, dynamic> json) {
    return LocationType(
      locationTypeId: json['location_type_id'] ?? json['locationTypeId'],
      typeName: json['type_name'] ?? json['typeName'] ?? '',
    );
  }
}
