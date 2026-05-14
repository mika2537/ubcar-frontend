import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../system/models/trip_model.dart';
import '../../system/models/user_model.dart';
import '../../system/state/auth_controller.dart';
import '../../system/state/passenger_controller.dart';

class PassengerHistoryScreen extends StatefulWidget {
  const PassengerHistoryScreen({super.key});

  @override
  State<PassengerHistoryScreen> createState() => _PassengerHistoryScreenState();
}

class _PassengerHistoryScreenState extends State<PassengerHistoryScreen> {
  final _authController = AuthController();
  final _passengerController = PassengerController();

  List<TripModel> _trips = const [];
  Map<String, UserModel> _driversById = const {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = await _authController.getCurrentUser();
      if (user == null) {
        throw Exception('Please sign in again.');
      }

      final trips = await _passengerController.getPassengerTrips(user.id);
      final driverIDs = trips
          .map((trip) => trip.driverId)
          .whereType<String>()
          .where((id) => id.isNotEmpty)
          .toSet();

      final drivers = <String, UserModel>{};
      for (final driverID in driverIDs) {
        final driver = await _passengerController.getUserProfile(driverID);
        if (driver != null) {
          drivers[driverID] = driver;
        }
      }

      if (!mounted) {
        return;
      }
      setState(() {
        _trips = trips;
        _driversById = drivers;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'My Trips',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 56,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadHistory,
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (_trips.isEmpty) {
      return const Center(
        child: Text(
          'No passenger trips found yet.',
          style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w700),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadHistory,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: _trips.length,
        itemBuilder: (context, index) {
          final trip = _trips[index];
          final driver = trip.driverId == null
              ? null
              : _driversById[trip.driverId!];
          return _TripHistoryCard(trip: trip, driver: driver);
        },
      ),
    );
  }
}

class _TripHistoryCard extends StatelessWidget {
  const _TripHistoryCard({required this.trip, required this.driver});

  final TripModel trip;
  final UserModel? driver;

  @override
  Widget build(BuildContext context) {
    final createdAt = trip.createdAt.toLocal();
    final formatter = DateFormat('MMM d, yyyy');
    final timeFormatter = DateFormat('hh:mm a');
    final fare = _estimateFare(trip);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formatter.format(createdAt),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      timeFormatter.format(createdAt),
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
                Text(
                  '₮$fare',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildRouteRow(
                  Icons.circle,
                  Colors.green,
                  trip.route?.from ?? 'Unknown pickup',
                ),
                const SizedBox(height: 4),
                for (final midpoint
                    in trip.route?.midpoints ?? const <String>[])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: _buildRouteRow(
                      Icons.more_horiz,
                      Colors.orange,
                      midpoint,
                    ),
                  ),
                _buildRouteRow(
                  Icons.location_on,
                  Colors.red,
                  trip.route?.to ?? 'Unknown destination',
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.indigo.withOpacity(0.03),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(20),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.drive_eta,
                      size: 16,
                      color: Colors.black54,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Driver: ${driver?.name ?? trip.driverId ?? 'Not assigned'}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      size: 16,
                      color: Colors.black54,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Status: ${trip.status}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteRow(IconData icon, Color color, String text) {
    return Row(
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
        ),
      ],
    );
  }

  int _estimateFare(TripModel trip) {
    return 3500 + ((trip.route?.midpoints.length ?? 0) * 1200);
  }
}
