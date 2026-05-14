import 'package:flutter/material.dart';

import '../../system/models/route_model.dart';
import '../../system/models/trip_model.dart';
import '../../system/state/auth_controller.dart';
import '../../system/state/driver_controller.dart';

class RouteDetailScreen extends StatefulWidget {
  final RouteModel? route;
  final VoidCallback? onBack;
  final VoidCallback? onEdit;
  final VoidCallback? onStartRide;

  const RouteDetailScreen({
    super.key,
    this.route,
    this.onBack,
    this.onEdit,
    this.onStartRide,
  });

  @override
  State<RouteDetailScreen> createState() => _RouteDetailScreenState();
}

class _RouteDetailScreenState extends State<RouteDetailScreen> {
  final _authController = AuthController();
  final _driverController = DriverController();

  RouteModel? _route;
  List<TripModel> _routeTrips = const [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRoute();
  }

  Future<void> _loadRoute() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = await _authController.getCurrentUser();
      if (user == null) {
        throw Exception('Please sign in again.');
      }

      final routes = await _driverController.getSavedRoutes(user.id);
      final route = widget.route ?? (routes.isNotEmpty ? routes.first : null);
      if (route == null) {
        throw Exception('No saved route found for this driver.');
      }

      final trips = await _driverController.getDriverTrips(user.id);
      final routeTrips = trips.where((trip) => trip.route?.id == route.id).toList();

      if (!mounted) {
        return;
      }
      setState(() {
        _route = route;
        _routeTrips = routeTrips;
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
                const Icon(Icons.alt_route, size: 56, color: Colors.redAccent),
                const SizedBox(height: 12),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadRoute,
                  child: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final route = _route!;
    final completedTrips = _routeTrips.where((trip) => trip.status == 'completed').length;
    final activeTrips = _routeTrips.where((trip) => trip.status == 'active' || trip.status == 'accepted').length;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 240,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Container(
                      decoration: const BoxDecoration(color: Color(0xFFE5E7EB)),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.map_outlined, size: 44, color: Colors.indigo),
                            const SizedBox(height: 12),
                            Text(
                              '${route.from} to ${route.to}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 20,
                              ),
                            ),
                            if (route.midpoints.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Text(
                                route.midpoints.join(' • '),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.black54,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 14,
                    left: 16,
                    right: 16,
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: widget.onBack ?? () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.arrow_back),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.75),
                            shape: const CircleBorder(),
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: widget.onEdit,
                          icon: const Icon(Icons.edit),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.75),
                            shape: const CircleBorder(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 16,
                    bottom: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '● ${activeTrips > 0 ? 'In use' : 'Saved'}',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${route.from} to ${route.to}',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              children: [
                                const CircleAvatar(radius: 6, backgroundColor: Colors.indigo),
                                Container(width: 3, height: 48, color: Colors.grey.shade400),
                                const CircleAvatar(radius: 6, backgroundColor: Colors.red),
                              ],
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Pickup', style: TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.w800)),
                                  const SizedBox(height: 6),
                                  Text(route.from, style: const TextStyle(fontWeight: FontWeight.w800)),
                                  const SizedBox(height: 14),
                                  if (route.midpoints.isNotEmpty) ...[
                                    for (int index = 0; index < route.midpoints.length; index++) ...[
                                      Text('Midpoint ${index + 1}', style: const TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.w800)),
                                      const SizedBox(height: 6),
                                      Text(route.midpoints[index], style: const TextStyle(fontWeight: FontWeight.w700)),
                                      const SizedBox(height: 14),
                                    ],
                                  ],
                                  const Text('Drop-off', style: TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.w800)),
                                  const SizedBox(height: 6),
                                  Text(route.to, style: const TextStyle(fontWeight: FontWeight.w800)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _StatTile(label: 'Trips', value: '${_routeTrips.length}', icon: Icons.alt_route),
                      _StatTile(label: 'Completed', value: '$completedTrips', icon: Icons.check_circle_outline),
                      _StatTile(label: 'Active', value: '$activeTrips', icon: Icons.local_taxi_outlined),
                      _StatTile(label: 'Midpoints', value: '${route.midpoints.length}', icon: Icons.more_horiz),
                    ],
                  ),
                  const SizedBox(height: 14),
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
                        const Text('Recent Trips On This Route', style: TextStyle(fontWeight: FontWeight.w900)),
                        const SizedBox(height: 10),
                        if (_routeTrips.isEmpty)
                          const Text(
                            'No trips have been recorded for this route yet.',
                            style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w700),
                          )
                        else
                          ..._routeTrips.take(6).map((trip) {
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                backgroundColor: Colors.indigo.withOpacity(0.10),
                                child: const Icon(Icons.route, color: Colors.indigo),
                              ),
                              title: Text(
                                trip.status.toUpperCase(),
                                style: const TextStyle(fontWeight: FontWeight.w900),
                              ),
                              subtitle: Text(
                                '${trip.createdAt.toLocal()}'.split('.').first,
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
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
                  onPressed: widget.onStartRide,
                  icon: const Icon(Icons.navigation),
                  label: const Text(
                    'Start Ride',
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
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.indigo),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
