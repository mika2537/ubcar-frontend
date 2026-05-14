import 'package:flutter/material.dart';

import '../../system/models/trip_model.dart';
import '../../system/state/auth_controller.dart';
import '../../system/state/driver_controller.dart';
import '../../system/state/passenger_controller.dart';

class NotificationCenterScreen extends StatefulWidget {
  final String role;
  final VoidCallback? onBack;

  const NotificationCenterScreen({
    super.key,
    this.role = 'passenger',
    this.onBack,
  });

  @override
  State<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _ActivityItem {
  final IconData icon;
  final Color color;
  final String title;
  final String message;
  final DateTime timestamp;

  const _ActivityItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
    required this.timestamp,
  });
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  final _authController = AuthController();
  final _driverController = DriverController();
  final _passengerController = PassengerController();

  List<_ActivityItem> _items = const [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = await _authController.getCurrentUser();
      if (user == null) {
        throw Exception('Please sign in again.');
      }

      final trips = user.role == 'driver'
          ? await _driverController.getDriverTrips(user.id)
          : await _passengerController.getPassengerTrips(user.id);

      final items = trips.map(_activityForTrip).toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

      if (!mounted) {
        return;
      }
      setState(() {
        _items = items;
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

  _ActivityItem _activityForTrip(TripModel trip) {
    switch (trip.status) {
      case 'completed':
        return _ActivityItem(
          icon: Icons.check_circle_outline,
          color: Colors.green,
          title: 'Trip Completed',
          message:
              '${trip.route?.from ?? 'Pickup'} to ${trip.route?.to ?? 'Destination'} finished successfully.',
          timestamp: trip.createdAt,
        );
      case 'accepted':
        return _ActivityItem(
          icon: Icons.thumb_up_alt_outlined,
          color: Colors.indigo,
          title: 'Trip Accepted',
          message:
              'A driver accepted the route ${trip.route?.from ?? 'Pickup'} to ${trip.route?.to ?? 'Destination'}.',
          timestamp: trip.createdAt,
        );
      case 'cancelled':
        return _ActivityItem(
          icon: Icons.cancel_outlined,
          color: Colors.red,
          title: 'Trip Cancelled',
          message:
              'The trip ${trip.route?.from ?? 'Pickup'} to ${trip.route?.to ?? 'Destination'} was cancelled.',
          timestamp: trip.createdAt,
        );
      default:
        return _ActivityItem(
          icon: Icons.directions_car_outlined,
          color: Colors.orange,
          title: 'Trip Created',
          message:
              'A new trip was created for ${trip.route?.from ?? 'Pickup'} to ${trip.route?.to ?? 'Destination'}.',
          timestamp: trip.createdAt,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed:
                        widget.onBack ?? () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.grey.shade200,
                      shape: const CircleBorder(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Notifications',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _loadNotifications,
                    icon: const Icon(Icons.refresh),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.grey.shade200,
                      shape: const CircleBorder(),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
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
                onPressed: _loadNotifications,
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (_items.isEmpty) {
      return const Center(
        child: Text(
          "You're all caught up! Check back later.",
          style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w700),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadNotifications,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        itemCount: _items.length,
        itemBuilder: (context, index) {
          final item = _items[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: item.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(item.icon, color: item.color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.message,
                        style: const TextStyle(
                          color: Colors.black54,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${item.timestamp.toLocal()}'.split('.').first,
                        style: const TextStyle(
                          color: Colors.black45,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
