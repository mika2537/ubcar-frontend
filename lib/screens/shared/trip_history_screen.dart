import 'package:flutter/material.dart';
import '../../system/localization/app_language_controller.dart';
import '../../system/localization/app_localizations.dart';
import '../../system/models/trip_model.dart';
import '../../system/state/auth_controller.dart';
import '../../system/state/trip_controller.dart';
import '../../system/widgets/language_menu_button.dart';

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
  final _languageController = AppLanguageController();
  final _authController = AuthController();
  final _tripController = TripController();
  String filter = 'all';
  List<_TripRecord> loadedTrips = const [];
  bool isLoading = true;
  String? loadError;

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  Future<void> _loadTrips() async {
    final pleaseSignInAgain = context.l10n.text('pleaseSignInAgain');
    setState(() {
      isLoading = true;
      loadError = null;
    });
    try {
      final user = await _authController.getCurrentUser();
      if (user == null) {
        throw Exception(pleaseSignInAgain);
      }
      final trips = await _tripController.getTrips(user.id);
      if (!mounted) return;
      setState(() {
        loadedTrips = trips.map(_mapTripRecord).toList();
        isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        loadError = error.toString().replaceFirst('Exception: ', '');
        isLoading = false;
      });
    }
  }

  _TripRecord _mapTripRecord(TripModel trip) {
    final createdAt = trip.createdAt.toLocal();
    final status = trip.status == 'cancelled'
        ? _TripStatus.cancelled
        : _TripStatus.completed;
    return _TripRecord(
      id: trip.id,
      pickup: trip.route?.from ?? context.l10n.text('unknownPickup'),
      destination: trip.route?.to ?? context.l10n.text('unknownDestination'),
      date: _formatDate(createdAt),
      time: _formatTime(createdAt),
      fare: 0,
      distance: '-',
      duration: '-',
      driverName: widget.role == 'driver'
          ? context.l10n.text('passengerTrip')
          : context.l10n.text('driverTrip'),
      driverRating: 0,
      status: status,
      rated: status == _TripStatus.completed,
      seatsUsed: 1,
    );
  }

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final difference = today.difference(date).inDays;
    if (difference == 0) return context.l10n.text('today');
    if (difference == 1) return context.l10n.text('yesterday');
    return '${dateTime.year}-${_twoDigits(dateTime.month)}-${_twoDigits(dateTime.day)}';
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:${_twoDigits(dateTime.minute)} $period';
  }

  String _twoDigits(int value) => value.toString().padLeft(2, '0');

  List<_TripRecord> get filteredTrips {
    if (filter == 'completed') {
      return loadedTrips.where((t) => t.status == _TripStatus.completed).toList();
    }
    if (filter == 'cancelled') {
      return loadedTrips.where((t) => t.status == _TripStatus.cancelled).toList();
    }
    return loadedTrips;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
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
                  Text(
                    l10n.text('tripHistory'),
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                  const Spacer(),
                  LanguageMenuButton(controller: _languageController),
                ],
              ),
            ),

            // Filter Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _FilterChip(
                    label: l10n.text('all'),
                    selected: filter == 'all',
                    onTap: () => setState(() => filter = 'all'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: l10n.text('completed'),
                    selected: filter == 'completed',
                    onTap: () => setState(() => filter = 'completed'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: l10n.text('cancelled'),
                    selected: filter == 'cancelled',
                    onTap: () => setState(() => filter = 'cancelled'),
                  ),
                ],
              ),
            ),

            // List
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadTrips,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  children: [
                    if (isLoading) ...[
                      const SizedBox(height: 80),
                      const Center(child: CircularProgressIndicator()),
                    ] else if (loadError != null) ...[
                      const SizedBox(height: 80),
                      Center(child: Text(loadError!, style: const TextStyle(fontWeight: FontWeight.bold))),
                    ] else if (filteredTrips.isEmpty) ...[
                      const SizedBox(height: 80),
                      Center(child: Text(l10n.text('noTripsFound'), style: const TextStyle(fontWeight: FontWeight.bold))),
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
                trip.status == _TripStatus.completed
                    ? context.l10n.text('completed')
                    : context.l10n.text('cancelled'),
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
