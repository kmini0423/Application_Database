import 'package:intl/intl.dart';

class Event {
  final int eventId;
  final String title;
  final DateTime date;
  final String time;
  final int duration;
  final String? description;
  final int? locationId;
  final String? locationName;
  final String? locationAddress;
  final String? locationDescription;
  final int? typeId;
  final String eventType; // display name from type_name (DB)
  final int? maxCapacity;
  final int? createdBy;
  final List<Map<String, dynamic>>? organizers;
  final int? rsvpYesCount;
  final int? rsvpNoCount;
  final int? rsvpMaybeCount;

  Event({
    required this.eventId,
    required this.title,
    required this.date,
    required this.time,
    required this.duration,
    this.description,
    this.locationId,
    this.locationName,
    this.locationAddress,
    this.locationDescription,
    this.typeId,
    required this.eventType,
    this.maxCapacity,
    this.createdBy,
    this.organizers,
    this.rsvpYesCount,
    this.rsvpNoCount,
    this.rsvpMaybeCount,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(String? dateStr) {
      if (dateStr == null) return DateTime.now();
      try {
        return DateTime.parse(dateStr.split('T')[0]);
      } catch (e) {
        return DateTime.now();
      }
    }

    return Event(
      eventId: json['event_id'] ?? json['eventId'],
      title: json['title'],
      date: parseDate(json['date']),
      time: json['time'] ?? '',
      duration: json['duration'] ?? 0,
      description: json['description'],
      locationId: json['location_id'] ?? json['locationId'],
      locationName: json['location_name'] ?? json['locationName'],
      locationAddress: json['location_address'] ?? json['locationAddress'],
      locationDescription: json['location_description'] ?? json['locationDescription'],
      typeId: json['type_id'] ?? json['typeId'],
      eventType: json['event_type'] ?? json['eventType'] ?? json['event_type_name'] ?? 'Other',
      maxCapacity: json['max_capacity'] ?? json['maxCapacity'],
      createdBy: json['created_by'] ?? json['createdBy'],
      organizers: json['organizers'] != null
          ? List<Map<String, dynamic>>.from(json['organizers'])
          : null,
      rsvpYesCount: json['rsvp_yes_count'] ?? json['rsvpYesCount'],
      rsvpNoCount: json['rsvp_no_count'] ?? json['rsvpNoCount'],
      rsvpMaybeCount: json['rsvp_maybe_count'] ?? json['rsvpMaybeCount'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'event_id': eventId,
      'title': title,
      'date': DateFormat('yyyy-MM-dd').format(date),
      'time': time,
      'duration': duration,
      'description': description,
      'location_id': locationId,
      'type_id': typeId,
      'max_capacity': maxCapacity,
      'created_by': createdBy,
    };
  }

  String get formattedDate => DateFormat('MMM dd, yyyy').format(date);
  String get durationHours => '${duration ~/ 60}h ${duration % 60}m';
}
