import 'package:flutter/material.dart';

// REMOVED: import '../../system/widgets/bottom_nav.dart';
// (Child screens don't need to import the bottom nav themselves)

enum _TripStatus { completed, cancelled }

class _TripRecord {
  final String id;
  final String pickup;
  final String destination;
  final String date;
  final String time;
  final double fare;
  final String distance;
  final String duration;
  final String driverName;
  final double driverRating;
  final _TripStatus status;
  final bool rated;
  final int seatsUsed;

  const _TripRecord({
    required this.id,
    required this.pickup,
    required this.destination,
    required this.date,
    required this.time,
    required this.fare,
    required this.distance,
    required this.duration,
    required this.driverName,
    required this.driverRating,
    required this.status,
    required this.rated,
    required this.seatsUsed,
  });
}

class TripHistoryScreen extends StatefulWidget {
  final String role;
  final VoidCallback? onBack; // Use this to switch tabs
  final void Function(_TripRecord trip)? onRebook;
  final void Function(_TripRecord trip)? onRate;

  const TripHistoryScreen({
    super.key,
    this.role = 'passenger',
    this.onBack,
    this.onRebook,
    this.onRate,
  });

  @override
  State<TripHistoryScreen> createState() => _TripHistoryScreenState();
}

class _TripHistoryScreenState extends State<TripHistoryScreen> {
  String filter = 'all';

  final mockTrips = const <_TripRecord>[
    _TripRecord(
      id: '1',
      pickup: 'Salt Lake Sector V',
      destination: 'Park Street Metro',
      date: 'Today',
      time: '2:30 PM',
      fare: 249,
      distance: '12.5 km',
      duration: '35 min',
      driverName: 'Rahul S.',
      driverRating: 4.8,
      status: _TripStatus.completed,
      rated: true,
      seatsUsed: 1,
    ),
    _TripRecord(
      id: '2',
      pickup: 'Howrah Station',
      destination: 'Salt Lake Stadium',
      date: 'Yesterday',
      time: '6:15 PM',
      fare: 189,
      distance: '8.2 km',
      duration: '28 min',
      driverName: 'Amit K.',
      driverRating: 4.9,
      status: _TripStatus.completed,
      rated: false,
      seatsUsed: 2,
    ),
    _TripRecord(
      id: '3',
      pickup: 'New Town AA1',
      destination: 'Netaji Airport',
      date: 'Jan 8, 2026',
      time: '5:00 AM',
      fare: 599,
      distance: '18.7 km',
      duration: '45 min',
      driverName: 'Sanjay M.',
      driverRating: 4.7,
      status: _TripStatus.completed,
      rated: true,
      seatsUsed: 1,
    ),
    _TripRecord(
      id: '4',
      pickup: 'Esplanade',
      destination: 'Ruby Hospital',
      date: 'Jan 5, 2026',
      time: '11:30 AM',
      fare: 0,
      distance: '0 km',
      duration: '0 min',
      driverName: 'Driver',
      driverRating: 0,
      status: _TripStatus.cancelled,
      rated: false,
      seatsUsed: 1,
    ),
  ];

  List<_TripRecord> get filteredTrips {
    if (filter == 'completed') {
      return mockTrips.where((t) => t.status == _TripStatus.completed).toList();
    }
    if (filter == 'cancelled') {
      return mockTrips.where((t) => t.status == _TripStatus.cancelled).toList();
    }
    return mockTrips;
  }

  @override
  Widget build(BuildContext context) {
    // We remove Scaffold here because the Parent (DriverHome) provides it.
    return Container(
      color: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              child: Row(
                children: [
                  IconButton(
                    // FIX: Instead of pop(), call onBack which switches tabs in the parent
                    onPressed: widget.onBack,
                    icon: const Icon(Icons.arrow_back),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.grey.shade100,
                      shape: const CircleBorder(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Trip History',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                  const Spacer(),
                ],
              ),
            ),

            // Filter Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _FilterChip(
                    label: 'All',
                    selected: filter == 'all',
                    onTap: () => setState(() => filter = 'all'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Completed',
                    selected: filter == 'completed',
                    onTap: () => setState(() => filter = 'completed'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Cancelled',
                    selected: filter == 'cancelled',
                    onTap: () => setState(() => filter = 'cancelled'),
                  ),
                ],
              ),
            ),

            // List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100), // Bottom padding for Nav
                children: [
                  if (filteredTrips.isEmpty) ...[
                    const SizedBox(height: 80),
                    const Center(child: Text('No trips found', style: TextStyle(fontWeight: FontWeight.bold))),
                  ] else ...[
                    for (final trip in filteredTrips)
                      _TripCard(
                        trip: trip,
                        onRebook: () => widget.onRebook?.call(trip),
                        onRate: trip.rated ? null : () => widget.onRate?.call(trip),
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Helper Widgets ---

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: Colors.indigo.withOpacity(0.12),
      backgroundColor: Colors.grey.shade100,
      labelStyle: TextStyle(
        color: selected ? Colors.indigo : Colors.black87,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class _TripCard extends StatelessWidget {
  final _TripRecord trip;
  final VoidCallback? onRebook;
  final VoidCallback? onRate;

  const _TripCard({required this.trip, this.onRebook, this.onRate});

  @override
  Widget build(BuildContext context) {
    final statusColor = trip.status == _TripStatus.completed ? Colors.green : Colors.red;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.access_time, size: 16, color: Colors.black45),
              const SizedBox(width: 8),
              Text('${trip.date} • ${trip.time}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
              const Spacer(),
              Text(
                trip.status == _TripStatus.completed ? 'Completed' : 'Cancelled',
                style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              const Icon(Icons.circle, size: 10, color: Colors.green),
              const SizedBox(width: 12),
              Expanded(child: Text(trip.pickup, style: const TextStyle(fontWeight: FontWeight.bold))),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on, size: 10, color: Colors.red),
              const SizedBox(width: 12),
              Expanded(child: Text(trip.destination, style: const TextStyle(fontWeight: FontWeight.bold))),
            ],
          ),
        ],
      ),
    );
  }
}