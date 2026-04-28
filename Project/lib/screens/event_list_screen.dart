import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/event.dart';
import '../models/event_type.dart';
import '../models/location.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'event_detail_screen.dart';

class EventListScreen extends StatefulWidget {
  const EventListScreen({super.key});

  @override
  State<EventListScreen> createState() => _EventListScreenState();
}

class _EventListScreenState extends State<EventListScreen> {
  List<Event> _events = [];
  List<Location> _locations = [];
  List<EventType> _eventTypes = []; // from DB - dynamic dropdown
  bool _isLoading = true;
  String? _selectedLocation;
  int? _selectedTypeId;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final locations = await ApiService.getLocations();
      final eventTypes = await ApiService.getEventTypes();
      final events = await ApiService.getEvents(
        startDate: _startDate != null ? DateFormat('yyyy-MM-dd').format(_startDate!) : null,
        endDate: _endDate != null ? DateFormat('yyyy-MM-dd').format(_endDate!) : null,
        locationId: _selectedLocation != null ? int.parse(_selectedLocation!) : null,
        typeId: _selectedTypeId,
      );

      setState(() {
        _locations = locations;
        _eventTypes = eventTypes;
        _events = events;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading events: $e')),
        );
      }
    }
  }

  void _showSettingsBottomSheet(BuildContext context, User? user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFEEE9E0),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Settings',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              if (user != null) ...[
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(user.name),
                  subtitle: Text(user.email),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black87,
                    side: const BorderSide(color: Colors.black87),
                  ),
                  icon: const Icon(Icons.logout),
                  label: const Text('Log out'),
                  onPressed: () async {
                    Navigator.pop(context);
                    await AuthService.logout();
                    if (context.mounted) {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/login',
                        (route) => false,
                      );
                    }
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: AuthService.getCurrentUser(),
      builder: (context, snapshot) {
        final user = snapshot.data;

        const Color primaryColor = Color(0xFFEEE9E0);
        
        return Scaffold(
          backgroundColor: primaryColor,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: const Text('Discover Events'),
            backgroundColor: primaryColor,
            foregroundColor: Colors.black87,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (context) => _buildFilterSheet(),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.bar_chart),
                onPressed: () {
                  Navigator.pushNamed(context, '/report');
                },
              ),
              if (user != null)
                IconButton(
                  icon: const Icon(Icons.dashboard),
                  tooltip: 'My Dashboard',
                  onPressed: () async {
                    await Navigator.pushNamed(context, '/admin-dashboard');
                    if (mounted) _loadData();
                  },
                ),
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () => _showSettingsBottomSheet(context, user),
              ),
            ],
          ),
      floatingActionButton: user != null
          ? FloatingActionButton(
              onPressed: () async {
                await Navigator.pushNamed(
                  context,
                  '/admin-dashboard',
                  arguments: {'openCreate': true},
                );
                if (mounted) _loadData();
              },
              backgroundColor: Colors.black87,
              child: const Icon(Icons.add, color: Color(0xFFEEE9E0)),
            )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _events.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.event_busy, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'No events found',
                        style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: const Text('Refresh'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _events.length,
                    itemBuilder: (context, index) {
                      final event = _events[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                        elevation: 2,
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: CircleAvatar(
                            backgroundColor: Colors.black87,
                            child: Icon(
                              _getEventTypeIcon(event.eventType),
                              color: primaryColor,
                            ),
                          ),
                          title: Text(
                            event.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today, size: 16),
                                  const SizedBox(width: 4),
                                  Text(event.formattedDate),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.access_time, size: 16),
                                  const SizedBox(width: 4),
                                  Text('${event.time} - ${event.durationHours}'),
                                ],
                              ),
                              if (event.locationName != null) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on, size: 16),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        event.locationName!,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 4),
                              Chip(
                                label: Text(event.eventType),
                                labelStyle: const TextStyle(fontSize: 12),
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ],
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EventDetailScreen(eventId: event.eventId),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
        );
      },
    );
  }

  Widget _buildFilterSheet() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Filter Events',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            value: _selectedLocation,
            decoration: const InputDecoration(
              labelText: 'Location',
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem<String>(value: null, child: Text('All Locations')),
              ..._locations.map((location) => DropdownMenuItem<String>(
                    value: location.locationId.toString(),
                    child: Text(location.name),
                  )),
            ],
            onChanged: (value) {
              setState(() {
                _selectedLocation = value;
              });
              _loadData();
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
              const DropdownMenuItem<int>(value: null, child: Text('All Types')),
              ..._eventTypes.map((type) => DropdownMenuItem<int>(
                    value: type.typeId,
                    child: Text(type.typeName),
                  )),
            ],
            onChanged: (value) {
              setState(() {
                _selectedTypeId = value;
              });
              _loadData();
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
                _loadData();
              },
              child: const Text('Clear Date Range'),
            ),
        ],
      ),
    );
  }

  IconData _getEventTypeIcon(String eventType) {
    switch (eventType) {
      case 'Cars & Coffee':
        return Icons.local_cafe;
      case 'Cruise':
        return Icons.directions_car;
      case 'Track Day':
        return Icons.speed;
      case 'Show & Shine':
        return Icons.auto_awesome;
      default:
        return Icons.event;
    }
  }
}
