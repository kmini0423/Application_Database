/// Event type from DB - used for dynamic dropdown (Stage 2: not hard-coded).
class EventType {
  final int typeId;
  final String typeName;

  EventType({required this.typeId, required this.typeName});

  factory EventType.fromJson(Map<String, dynamic> json) {
    return EventType(
      typeId: json['type_id'] ?? json['typeId'],
      typeName: json['type_name'] ?? json['typeName'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'type_id': typeId, 'type_name': typeName};
}
