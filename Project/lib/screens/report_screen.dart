import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/event.dart';
import '../models/event_type.dart';
import '../models/location.dart';
import '../services/api_service.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  List<Event> _events = [];
  Map<String, dynamic>? _statistics;
  List<Location> _locations = [];
  List<EventType> _eventTypes = []; // from DB - dynamic dropdown (Stage 2)
  bool _isLoading = false;
  bool _hasGenerated = false;

  String? _selectedLocation;
  int? _selectedTypeId;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _loadDropdownData();
  }

  Future<void> _loadDropdownData() async {
    try {
      final locations = await ApiService.getLocations();
      final eventTypes = await ApiService.getEventTypes();
      setState(() {
        _locations = locations;
        _eventTypes = eventTypes;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading filter options: $e')),
        );
      }
    }
  }

  Future<void> _generateReport() async {
    setState(() {
      _isLoading = true;
      _hasGenerated = false;
    });

    try {
      final report = await ApiService.getEventReport(
        startDate: _startDate != null ? DateFormat('yyyy-MM-dd').format(_startDate!) : null,
        endDate: _endDate != null ? DateFormat('yyyy-MM-dd').format(_endDate!) : null,
        locationId: _selectedLocation != null ? int.parse(_selectedLocation!) : null,
        typeId: _selectedTypeId,
      );

      setState(() {
        _events = (report['events'] as List)
            .map((e) => Event.fromJson(e))
            .toList();
        _statistics = report['statistics'];
        _isLoading = false;
        _hasGenerated = true;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating report: $e')),
        );
      }
    }
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEE9E0),
      appBar: AppBar(
        title: const Text('Event Report'),
        backgroundColor: const Color(0xFFEEE9E0),
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Filter Options',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedLocation,
                      decoration: const InputDecoration(
                        labelText: 'Location',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('All Locations'),
                        ),
                        ..._locations.map((location) => DropdownMenuItem<String>(
                              value: location.locationId.toString(),
                              child: Text(location.name),
                            )),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedLocation = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      value: _selectedTypeId,
                      decoration: const InputDecoration(
                        labelText: 'Event Type',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem<int>(
                          value: null,
                          child: Text('All Types'),
                        ),
                        ..._eventTypes.map((type) => DropdownMenuItem<int>(
                              value: type.typeId,
                              child: Text(type.typeName),
                            )),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedTypeId = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _selectDateRange,
                      icon: const Icon(Icons.date_range),
                      label: Text(
                        _startDate != null && _endDate != null
                            ? '${DateFormat('MMM dd').format(_startDate!)} - ${DateFormat('MMM dd, yyyy').format(_endDate!)}'
                            : 'Select Date Range',
                      ),
                    ),
                    if (_startDate != null || _endDate != null)
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _startDate = null;
                            _endDate = null;
                          });
                        },
                        child: const Text('Clear Date Range'),
                      ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _generateReport,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black87,
                        foregroundColor: const Color(0xFFEEE9E0),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Generate Report',
                              style: TextStyle(fontSize: 18),
                            ),
                    ),
                  ],
                ),
              ),
            ),
            if (_hasGenerated && _statistics != null) ...[
              const SizedBox(height: 24),
              const Text(
                'Statistics',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.15,
                children: [
                  _buildStatCard(
                    'Total Events',
                    _statValue(_statistics!, 'total_events'),
                    Icons.event,
                    Colors.black87,
                  ),
                  _buildStatCard(
                    'Avg Duration',
                    '${_statNum(_statistics!, 'avg_duration').toStringAsFixed(1)} min',
                    Icons.access_time,
                    Colors.green,
                  ),
                  _buildStatCard(
                    'Avg Yes RSVPs',
                    _statNum(_statistics!, 'avg_yes_rsvps').toStringAsFixed(1),
                    Icons.check_circle_outline,
                    Colors.orange,
                  ),
                  _buildStatCard(
                    'Avg Total RSVPs',
                    _statNum(_statistics!, 'avg_total_rsvps').toStringAsFixed(1),
                    Icons.people_outline,
                    Colors.purple,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Event List',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              if (_events.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: Text('No events match the selected filters'),
                    ),
                  ),
                )
              else
                ..._events.map((event) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(
                          event.title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Date: ${event.formattedDate}'),
                            Text('Type: ${event.eventType}'),
                            if (event.locationName != null)
                              Text('Location: ${event.locationName}'),
                            Text('Duration: ${event.durationHours}'),
                          ],
                        ),
                      ),
                    )),
            ],
          ],
        ),
      ),
    );
  }

  /// Safely get a stat value as String (for total_events etc.)
  String _statValue(Map<String, dynamic> stats, String key) {
    final v = stats[key];
    if (v == null) return '0';
    if (v is num) return v.toString();
    if (v is String) return v;
    return v.toString();
  }

  /// Safely get a stat value as num (handles JSON number or string)
  num _statNum(Map<String, dynamic> stats, String key) {
    final v = stats[key];
    if (v == null) return 0;
    if (v is num) return v;
    if (v is String) return num.tryParse(v) ?? 0;
    return 0;
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 26, color: color),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }
}
