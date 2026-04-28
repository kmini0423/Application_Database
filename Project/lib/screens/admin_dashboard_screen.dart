import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/event.dart';
import '../models/event_type.dart';
import '../models/location.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key, this.openCreateOnLoad = false});

  final bool openCreateOnLoad;

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  List<Event> _events = [];
  List<Location> _locations = [];
  List<EventType> _eventTypes = []; // from DB - dynamic dropdown (Stage 2)
  List<User> _users = [];
  bool _isLoading = true;
  Event? _selectedEvent;
  bool _hasShownCreateOnLoad = false; // open Create dialog only once when openCreateOnLoad is true

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _openMap(String address) async {
    final query = Uri.encodeComponent(address);
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = await AuthService.getCurrentUserId();
      final events = await ApiService.getEvents();
      final locations = await ApiService.getLocations();
      final eventTypes = await ApiService.getEventTypes();
      final users = await ApiService.getUsers();
      // My Dashboard: show only events created by the current user
      final myEvents = userId != null
          ? events.where((e) => e.createdBy == userId).toList()
          : <Event>[];

      setState(() {
        _events = myEvents;
        _locations = locations;
        _eventTypes = eventTypes;
        _users = users;
        _isLoading = false;
      });
      if (widget.openCreateOnLoad && mounted && !_hasShownCreateOnLoad) {
        _hasShownCreateOnLoad = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _showEventDialog();
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  //Event dialog
  Future<void> _showEventDialog({Event? event}) async {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController(text: event?.title ?? '');
    final descriptionController = TextEditingController(text: event?.description ?? '');
    final locationDescriptionController = TextEditingController(text: event?.locationDescription ?? '');
    final durationController = TextEditingController(text: event?.duration.toString() ?? '');
    final timeController = TextEditingController(text: event?.time ?? '');


    // Use a list so the selected date is always read correctly when create is pressed
    final selectedDateHolder = <DateTime?>[event?.date];
    int? selectedLocationId = event?.locationId;
    int? selectedTypeId = event?.typeId;
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(event == null ? 'Create Event' : 'Edit Event'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    value: selectedLocationId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Location',
                      border: OutlineInputBorder(),
                    ),
                    items: _locations.map((location) {
                      return DropdownMenuItem<int>(
                        value: location.locationId,
                        child: Text(
                          location.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    selectedItemBuilder: (context) => _locations
                        .map((location) => Text(
                              location.name,
                              overflow: TextOverflow.ellipsis,
                            ))
                        .toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        selectedLocationId = value;
                      });
                    },
                    validator: (value) => value == null ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: locationDescriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Place / Location description',
                      border: OutlineInputBorder(),
                      hintText: 'e.g. address, landmark, or how to find the spot',
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    value: selectedTypeId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Event Type',
                      border: OutlineInputBorder(),
                    ),
                    items: _eventTypes.map((type) {
                      return DropdownMenuItem<int>(
                        value: type.typeId,
                        child: Text(
                          type.typeName,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    selectedItemBuilder: (context) => _eventTypes
                        .map((type) => Text(
                              type.typeName,
                              overflow: TextOverflow.ellipsis,
                            ))
                        .toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        selectedTypeId = value;
                      });
                    },
                    validator: (value) => value == null ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: selectedDateHolder[0] ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: Theme.of(context).colorScheme.copyWith(
                                primary: Colors.black,
                                onPrimary: Colors.white,
                              ),
                              textButtonTheme: TextButtonThemeData(
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.black,
                                ),
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (date != null) {
                        selectedDateHolder[0] = date;
                        setDialogState(() {});
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        selectedDateHolder[0] != null
                            ? DateFormat('yyyy-MM-dd').format(selectedDateHolder[0]!)
                            : 'Select Date',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: timeController,
                    decoration: const InputDecoration(
                      labelText: 'Time (HH:MM)',
                      border: OutlineInputBorder(),
                      hintText: '14:00',
                    ),
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: durationController,
                    decoration: const InputDecoration(
                      labelText: 'Duration (minutes)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(foregroundColor: Colors.black),
              onPressed: () async {
                if (formKey.currentState!.validate() &&
                    selectedDateHolder[0] != null &&
                    selectedLocationId != null &&
                    selectedTypeId != null) {
                  try {
                    final userId = await AuthService.getCurrentUserId();
                    final eventData = {
                      'title': titleController.text,
                      'date': DateFormat('yyyy-MM-dd').format(selectedDateHolder[0]!),
                      'time': timeController.text,
                      'duration': int.parse(durationController.text),
                      'description': descriptionController.text,
                      'location_id': selectedLocationId,
                      'type_id': selectedTypeId,
                      'location_description': locationDescriptionController.text.trim().isEmpty ? null : locationDescriptionController.text.trim(),
                      'created_by': userId,
                    };

                    if (event == null) {
                      await ApiService.createEvent(eventData);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Event created successfully')),
                        );
                      }
                    } else {
                      await ApiService.updateEvent(event.eventId, eventData);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Event updated successfully')),
                        );
                      }
                    }

                    if (mounted) {
                      Navigator.pop(context);
                      _loadData();
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  }
                }
              },
              child: Text(event == null ? 'Create' : 'Update'),
            ),
          ],
        ),
      ),
    );

    // Dispose controllers after the dialog is fully closed and the next frame has run,
    // so no widget tries to use them during the pop transition.
    await Future<void>.delayed(Duration.zero);
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        titleController.dispose();
        descriptionController.dispose();
        locationDescriptionController.dispose();
        durationController.dispose();
        timeController.dispose();
      });
    } else {
      titleController.dispose();
      descriptionController.dispose();
      locationDescriptionController.dispose();
      durationController.dispose();
      timeController.dispose();
    }
  }

  Future<void> _deleteEvent(Event event) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event'),
        content: Text('Are you sure you want to delete "${event.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ApiService.deleteEvent(event.eventId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Event deleted successfully')),
          );
          _loadData();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting event: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFFEEE9E0);
    
    return Scaffold(
      backgroundColor: primaryColor,
          appBar: AppBar(
            title: const Text('My Dashboard'),
            backgroundColor: primaryColor,
            foregroundColor: Colors.black87,
            elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.event),
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/event-list');
            },
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () {
              Navigator.pushNamed(context, '/report');
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _showEventDialog(),
                      icon: const Icon(Icons.add),
                      label: const Text('Create New Event'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black87,
                        foregroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: _events.isEmpty
                      ? const Center(child: Text('No events found'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: _events.length,
                          itemBuilder: (context, index) {
                            final event = _events[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 4,
                              ),
                              child: ListTile(
                                title: Text(
                                  event.title,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(event.formattedDate),
                                    Text('Type: ${event.eventType}'),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit),
                                      onPressed: () => _showEventDialog(event: event),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete),
                                      color: Colors.red,
                                      onPressed: () => _deleteEvent(event),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
