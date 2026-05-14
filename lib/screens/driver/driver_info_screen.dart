import 'package:flutter/material.dart';

import '../../system/models/trip_model.dart';
import '../../system/models/user_model.dart';
import '../../system/state/auth_controller.dart';
import '../../system/state/driver_controller.dart';

class DriverInfoScreen extends StatefulWidget {
  final String? driverId;
  final String? driverName;
  final String? driverPhone;
  final double? driverRating;
  final int? driverTrips;
  final String? driverPhoto;
  final String pickup;
  final String destination;
  final double fare;
  final int seatsRequested;
  final VoidCallback? onBack;
  final VoidCallback? onStartTracking;
  final VoidCallback? onCall;

  const DriverInfoScreen({
    super.key,
    this.driverId,
    this.driverName,
    this.driverPhone,
    this.driverRating,
    this.driverTrips,
    this.driverPhoto,
    this.pickup = '',
    this.destination = '',
    this.fare = 0,
    this.seatsRequested = 1,
    this.onBack,
    this.onStartTracking,
    this.onCall,
  });

  @override
  State<DriverInfoScreen> createState() => _DriverInfoScreenState();
}

class _DriverInfoScreenState extends State<DriverInfoScreen> {
  final _authController = AuthController();
  final _driverController = DriverController();

  UserModel? _driver;
  List<TripModel> _trips = const [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDriver();
  }

  Future<void> _loadDriver() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final currentUser = await _authController.getCurrentUser();
      final driverId = widget.driverId ?? currentUser?.id;
      if (driverId == null || driverId.isEmpty) {
        throw Exception('Driver information is unavailable.');
      }

      final driver = await _driverController.getDriverProfile(driverId);
      final trips = await _driverController.getDriverTrips(driverId);
      if (!mounted) {
        return;
      }

      setState(() {
        _driver = driver ?? currentUser;
        _trips = trips;
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
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: widget.onBack ?? () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 56, color: Colors.redAccent),
                const SizedBox(height: 12),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadDriver,
                  child: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final driverName = widget.driverName?.trim().isNotEmpty == true
        ? widget.driverName!.trim()
        : (_driver?.name?.trim().isNotEmpty == true ? _driver!.name!.trim() : 'Driver');
    final driverContact = widget.driverPhone?.trim().isNotEmpty == true
        ? widget.driverPhone!.trim()
        : (_driver?.email ?? 'Contact unavailable');
    final completedTrips = _trips.where((trip) => trip.status == 'completed').length;
    final totalTrips = widget.driverTrips ?? _trips.length;
    final driverRating = widget.driverRating ?? _ratingFromTrips(_trips);

    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [scheme.primary, scheme.primary.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: widget.onBack ?? () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back),
                        color: scheme.onPrimary,
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.20),
                          shape: const CircleBorder(),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.shield, size: 14, color: Colors.white),
                            const SizedBox(width: 8),
                            Text(
                              'Driver Details',
                              style: TextStyle(
                                color: scheme.onPrimary.withOpacity(0.92),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Trip information from your backend',
                    style: TextStyle(
                      color: scheme.onPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 62,
                              height: 62,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.indigo.withOpacity(0.18),
                                  width: 3,
                                ),
                              ),
                              child: Center(
                                child: widget.driverPhoto != null &&
                                        widget.driverPhoto!.trim().isNotEmpty
                                    ? ClipOval(
                                        child: Image.network(
                                          widget.driverPhoto!,
                                          width: 62,
                                          height: 62,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : Text(
                                        driverName.isNotEmpty ? driverName[0].toUpperCase() : '?',
                                        style: const TextStyle(
                                          fontSize: 26,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.black54,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    driverName,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(Icons.star, size: 14, color: Colors.amber),
                                      const SizedBox(width: 6),
                                      Text(
                                        driverRating.toStringAsFixed(1),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          color: Colors.black54,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Text('•', style: TextStyle(color: Colors.black45)),
                                      const SizedBox(width: 8),
                                      Text(
                                        '$totalTrips trips',
                                        style: const TextStyle(
                                          color: Colors.black54,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '$completedTrips completed',
                                    style: const TextStyle(
                                      color: Colors.black45,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: widget.onCall,
                            icon: const Icon(Icons.alternate_email),
                            label: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Contact',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white70,
                                  ),
                                ),
                                Text(
                                  driverContact,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: scheme.primary.withOpacity(0.95),
                              foregroundColor: scheme.onPrimary,
                              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.directions_car, color: Colors.indigo),
                            SizedBox(width: 8),
                            Text(
                              'Vehicle',
                              style: TextStyle(fontWeight: FontWeight.w900),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    'Vehicle details are not stored yet.',
                                    style: TextStyle(fontWeight: FontWeight.w900),
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    'Add vehicle fields in the backend when you are ready.',
                                    style: TextStyle(
                                      color: Colors.black54,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.indigo,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'Backend',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              children: const [
                                CircleAvatar(radius: 6, backgroundColor: Colors.green),
                                SizedBox(height: 8),
                                SizedBox(height: 30, child: VerticalDivider(thickness: 2)),
                                SizedBox(height: 8),
                                CircleAvatar(radius: 6, backgroundColor: Colors.red),
                              ],
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Pickup',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.black54,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    widget.pickup.isEmpty ? 'Not provided' : widget.pickup,
                                    style: const TextStyle(fontWeight: FontWeight.w800),
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    'Drop-off',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.black54,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    widget.destination.isEmpty ? 'Not provided' : widget.destination,
                                    style: const TextStyle(fontWeight: FontWeight.w800),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.people, size: 18, color: Colors.black54),
                                const SizedBox(width: 8),
                                Text(
                                  '${widget.seatsRequested} ${widget.seatsRequested > 1 ? 'seats' : 'seat'}',
                                  style: const TextStyle(fontWeight: FontWeight.w800),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Text(
                              '₮${widget.fare.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Colors.indigo,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.98),
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: widget.onStartTracking,
                  icon: const Icon(Icons.navigation),
                  label: const Text(
                    'Track Ride',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _ratingFromTrips(List<TripModel> trips) {
    if (trips.isEmpty) {
      return 0;
    }

    final completedTrips = trips.where((trip) => trip.status == 'completed').length;
    final completionRatio = completedTrips / trips.length;
    final rating = 4 + completionRatio;
    return rating.clamp(0, 5).toDouble();
  }
}
