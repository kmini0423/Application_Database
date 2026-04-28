class Location {
  final int locationId;
  final String name;
  final String? address;
  final String? city;
  final String? state;
  final String? zipCode;
  final int? capacity;
  final String? description;
  final int? locationTypeId;
  final String? locationTypeName;

  Location({
    required this.locationId,
    required this.name,
    this.address,
    this.city,
    this.state,
    this.zipCode,
    this.capacity,
    this.description,
    this.locationTypeId,
    this.locationTypeName,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      locationId: json['location_id'] ?? json['locationId'],
      name: json['name'],
      address: json['address'],
      city: json['city'],
      state: json['state'],
      zipCode: json['zip_code'] ?? json['zipCode'],
      capacity: json['capacity'],
      description: json['description'],
      locationTypeId: json['location_type_id'] ?? json['locationTypeId'],
      locationTypeName: json['location_type_name'] ?? json['locationTypeName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'location_id': locationId,
      'name': name,
      'address': address,
      'city': city,
      'state': state,
      'zip_code': zipCode,
      'capacity': capacity,
      'description': description,
    };
  }

  String get fullAddress {
    List<String> parts = [];
    if (address != null && address!.isNotEmpty) parts.add(address!);
    if (city != null && city!.isNotEmpty) parts.add(city!);
    if (state != null && state!.isNotEmpty) parts.add(state!);
    if (zipCode != null && zipCode!.isNotEmpty) parts.add(zipCode!);
    return parts.join(', ');
  }
}
