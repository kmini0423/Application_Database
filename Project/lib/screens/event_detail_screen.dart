import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/event.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class EventDetailScreen extends StatefulWidget {
  final int eventId;

  const EventDetailScreen({super.key, required this.eventId});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  Event? _event;
  bool _isLoading = true;
  String? _rsvpStatus;

  @override
  void initState() {
    super.initState();
    _loadEvent();
  }

  Future<void> _loadEvent() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final event = await ApiService.getEvent(widget.eventId);
      setState(() {
        _event = event;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading event: $e')),
        );
      }
    }
  }

  Future<void> _openLocationInMaps() async {
    if (_event == null) return;
    // Prefer Create Event place description for map search; fall back to address, then location name
    final parts = <String>[];
    if (_event!.locationDescription != null && _event!.locationDescription!.trim().isNotEmpty) {
      parts.add(_event!.locationDescription!.trim());
    }
    if (_event!.locationAddress != null && _event!.locationAddress!.trim().isNotEmpty) {
      parts.add(_event!.locationAddress!);
    }
    if (parts.isEmpty && _event!.locationName != null && _event!.locationName!.isNotEmpty) {
      parts.add(_event!.locationName!);
    }
    if (parts.isEmpty) return;
    final query = Uri.encodeComponent(parts.join(', '));
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _updateRsvp(String status) async {
    try {
      final user = await AuthService.getCurrentUser();
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please login to RSVP')),
          );
        }
        return;
      }

      await ApiService.createRsvp(
        eventId: widget.eventId,
        userId: user.userId,
        status: status,
      );

      setState(() {
        _rsvpStatus = status;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('RSVP updated to: $status')),
        );
      }

      _loadEvent(); // Reload to get updated counts
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating RSVP: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEE9E0),
      appBar: AppBar(
        title: const Text('Event Details'),
        backgroundColor: const Color(0xFFEEE9E0),
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _event == null
              ? const Center(child: Text('Event not found'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Card(
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _event!.title,
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Chip(
                                label: Text(_event!.eventType),
                                backgroundColor: Colors.grey.shade300,
                              ),
                              const SizedBox(height: 20),
                              _buildDetailRow(Icons.calendar_today, 'Date', _event!.formattedDate),
                              const SizedBox(height: 12),
                              _buildDetailRow(
                                Icons.access_time,
                                'Time',
                                '${_event!.time} - ${_event!.durationHours}',
                              ),
                              if (_event!.locationName != null) ...[
                                const SizedBox(height: 12),
                                _buildDetailRow(
                                  Icons.location_on,
                                  'Location',
                                  _event!.locationName!,
                                ),
                                if (_event!.locationAddress != null &&
                                    _event!.locationAddress!.trim().isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 40),
                                    child: Text(
                                      _event!.locationAddress!,
                                      style: TextStyle(color: Colors.grey.shade700),
                                    ),
                                  ),
                                if (_event!.locationAddress == null ||
                                    _event!.locationAddress!.trim().isEmpty)
                                  if (_event!.locationDescription != null &&
                                      _event!.locationDescription!.trim().isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 40),
                                      child: Text(
                                        _event!.locationDescription!,
                                        style: TextStyle(color: Colors.grey.shade700),
                                      ),
                                    ),
                                const SizedBox(height: 8),
                                Padding(
                                  padding: const EdgeInsets.only(left: 40),
                                  child: TextButton.icon(
                                    icon: const Icon(Icons.map, size: 20),
                                    label: const Text('View on Map'),
                                    onPressed: () => _openLocationInMaps(),
                                  ),
                                ),
                              ],
                              if (_event!.description != null && _event!.description!.isNotEmpty) ...[
                                const SizedBox(height: 20),
                                const Divider(),
                                const SizedBox(height: 12),
                                const Text(
                                  'Description',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _event!.description!,
                                  style: TextStyle(color: Colors.grey.shade700),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatColumn('Yes', (_event!.rsvpYesCount ?? 0).toString()),
                              _buildStatColumn('Maybe', (_event!.rsvpMaybeCount ?? 0).toString()),
                              _buildStatColumn('No', (_event!.rsvpNoCount ?? 0).toString()),
                            ],
                          ),
                        ),
                      ),
                      if (_event!.organizers != null && _event!.organizers!.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        const Text(
                          'Organizers',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ..._event!.organizers!.map((org) => Card(
                              child: ListTile(
                                leading: const CircleAvatar(
                                  child: Icon(Icons.person),
                                ),
                                title: Text(org['name'] ?? 'Unknown'),
                                subtitle: Text(org['email'] ?? ''),
                              ),
                            )),
                      ],
                      const SizedBox(height: 30),
                      const Text(
                        'RSVP',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _updateRsvp('yes'),
                              icon: const Icon(Icons.check),
                              label: const Text('Yes'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _updateRsvp('maybe'),
                              icon: const Icon(Icons.help_outline),
                              label: const Text('Maybe'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _updateRsvp('no'),
                              icon: const Icon(Icons.close),
                              label: const Text('No'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade700),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(color: Colors.grey.shade700),
          ),
        ),
      ],
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}
