import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../models/event.dart';
import '../models/location.dart';
import '../models/event_type.dart';
import '../models/location_type.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:5001/api';
  
  // Replace with your actual IP when testing on device/emulator
  // For Android emulator: 'http://10.0.2.2:5001/api'
  // For iOS simulator: 'http://localhost:5001/api'
  // For physical device: 'http://YOUR_COMPUTER_IP:5001/api'

  // Authentication
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    String role = 'user',
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'role': role,
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception(jsonDecode(response.body)['error'] ?? 'Registration failed');
    }
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(jsonDecode(response.body)['error'] ?? 'Login failed');
    }
  }

  // Events
  static Future<List<Event>> getEvents({
    String? startDate,
    String? endDate,
    int? locationId,
    int? typeId,
  }) async {
    final queryParams = <String, String>{};
    if (startDate != null) queryParams['start_date'] = startDate;
    if (endDate != null) queryParams['end_date'] = endDate;
    if (locationId != null) queryParams['location_id'] = locationId.toString();
    if (typeId != null) queryParams['type_id'] = typeId.toString();

    final uri = Uri.parse('$baseUrl/events').replace(queryParameters: queryParams);
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Event.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load events');
    }
  }

  static Future<Event> getEvent(int eventId) async {
    final response = await http.get(Uri.parse('$baseUrl/events/$eventId'));

    if (response.statusCode == 200) {
      return Event.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load event');
    }
  }

  static Future<Map<String, dynamic>> createEvent(Map<String, dynamic> eventData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/events'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(eventData),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception(jsonDecode(response.body)['error'] ?? 'Failed to create event');
    }
  }

  static Future<void> updateEvent(int eventId, Map<String, dynamic> eventData) async {
    final response = await http.put(
      Uri.parse('$baseUrl/events/$eventId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(eventData),
    );

    if (response.statusCode != 200) {
      throw Exception(jsonDecode(response.body)['error'] ?? 'Failed to update event');
    }
  }

  static Future<void> deleteEvent(int eventId) async {
    final response = await http.delete(Uri.parse('$baseUrl/events/$eventId'));

    if (response.statusCode != 200) {
      throw Exception(jsonDecode(response.body)['error'] ?? 'Failed to delete event');
    }
  }

  // RSVP
  static Future<void> createRsvp({
    required int eventId,
    required int userId,
    required String status,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/events/$eventId/rsvp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'status': status,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(jsonDecode(response.body)['error'] ?? 'Failed to update RSVP');
    }
  }

  static Future<List<EventType>> getEventTypes() async {
    final response = await http.get(Uri.parse('$baseUrl/event-types'));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => EventType.fromJson(json)).toList();
    }
    throw Exception('Failed to load event types');
  }

  static Future<List<LocationType>> getLocationTypes() async {
    final response = await http.get(Uri.parse('$baseUrl/location-types'));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => LocationType.fromJson(json)).toList();
    }
    throw Exception('Failed to load location types');
  }

  static Future<List<Location>> getLocations() async {
    final response = await http.get(Uri.parse('$baseUrl/locations'));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Location.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load locations');
    }
  }

  static Future<Map<String, dynamic>> createLocation(Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse('$baseUrl/locations'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    }
    throw Exception(jsonDecode(response.body)['error'] ?? 'Failed to add location');
  }

  // Users
  static Future<List<User>> getUsers() async {
    final response = await http.get(Uri.parse('$baseUrl/users'));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => User.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load users');
    }
  }

  // Reports (Requirement 2: filter by date range, type_id, location_id)
  static Future<Map<String, dynamic>> getEventReport({
    String? startDate,
    String? endDate,
    int? locationId,
    int? typeId,
  }) async {
    final queryParams = <String, String>{};
    if (startDate != null) queryParams['start_date'] = startDate;
    if (endDate != null) queryParams['end_date'] = endDate;
    if (locationId != null) queryParams['location_id'] = locationId.toString();
    if (typeId != null) queryParams['type_id'] = typeId.toString();

    final uri = Uri.parse('$baseUrl/reports/events').replace(queryParameters: queryParams);
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to generate report');
    }
  }

  // Health check
  static Future<bool> healthCheck() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/health'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
