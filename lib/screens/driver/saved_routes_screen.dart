import 'package:flutter/material.dart';

import '../../system/localization/app_localizations.dart';
import '../../system/models/route_model.dart';
import '../../system/models/trip_model.dart';
import '../../system/routing/app_routes.dart';
import '../../system/state/auth_controller.dart';
import '../../system/state/driver_controller.dart';
import '../../system/services/backend_api_service.dart';
import 'create_route_screen.dart.dart';

class SavedRoutesScreen extends StatefulWidget {
  const SavedRoutesScreen({super.key});

  @override
  State<SavedRoutesScreen> createState() => _SavedRoutesScreenState();
}

class _SavedRoutesScreenState extends State<SavedRoutesScreen> {
  final _authController = AuthController();
  final _driverController = DriverController();
  final _apiService = BackendApiService();

  List<RouteModel> _routes = const [];
  List<TripModel> _activeTrips = const [];
  String? _userId;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRoutes();
  }

  Future<void> _loadRoutes() async {
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
      final activeTrips = await _loadActiveTrips(user.id);
      if (!mounted) {
        return;
      }

      setState(() {
        _userId = user.id;
        _routes = routes;
        _activeTrips = activeTrips;
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

  Future<void> _openCreateRoute() async {
    final created = await Navigator.push<RouteTemplate>(
      context,
      MaterialPageRoute(
        builder: (_) => const CreateRouteScreen(saveToBackend: false),
      ),
    );

    if (created == null || _userId == null || _isSaving) {
      return;
    }

    final newRoute = RouteModel(
      id: created.templateId,
      userId: _userId,
      from: created.origin,
      to: created.destination,
      midpoints: created.stops,
    );

    setState(() {
      _isSaving = true;
      _error = null;
      _routes = _upsertRoute(newRoute, _routes);
    });

    try {
      final savedRoute = await _apiService.saveRoute(
        userId: _userId!,
        route: newRoute,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _routes = _upsertRoute(savedRoute ?? newRoute, _routes);
      });
      await _refreshRoutesKeepingLocal(newRoute);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error =
            'Route is shown locally, but backend save failed: ${error.toString().replaceFirst('Exception: ', '')}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  List<RouteModel> _upsertRoute(RouteModel route, List<RouteModel> routes) {
    final filtered = routes.where((item) => item.id != route.id).toList();
    return [route, ...filtered];
  }

  Future<void> _refreshRoutesKeepingLocal(RouteModel fallbackRoute) async {
    try {
      final user = await _authController.getCurrentUser();
      if (user == null) {
        return;
      }
      final routes = await _driverController.getSavedRoutes(user.id);
      final activeTrips = await _loadActiveTrips(user.id);
      if (!mounted) {
        return;
      }
      setState(() {
        _userId = user.id;
        _routes = routes.any((route) => route.id == fallbackRoute.id)
            ? routes
            : _upsertRoute(fallbackRoute, routes);
        _activeTrips = activeTrips;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _routes = _upsertRoute(fallbackRoute, _routes);
        _isLoading = false;
      });
    }
  }

  Future<List<TripModel>> _loadActiveTrips(String userId) async {
    try {
      final trips = await _driverController.getDriverTrips(userId);
      return trips
          .where((trip) => trip.status == 'active' || trip.status == 'accepted')
          .toList();
    } catch (_) {
      return _activeTrips;
    }
  }

  Future<void> _openRoute(RouteModel route) async {
    if (_routeHasActiveRequests(route, _activeTrips)) {
      await _openLiveTracking(route);
      return;
    }
    await Navigator.pushNamed(
      context,
      AppRoutes.driverRouteDetail,
      arguments: route,
    );
  }

  Future<void> _publishRoute(RouteModel route) async {
    if (_routeHasActiveRequests(route, _activeTrips)) {
      await _openLiveTracking(route);
      return;
    }

    final demoRequests = _buildDemoPassengerRequests(route);
    if (demoRequests.isEmpty) {
      setState(() {
        _error = 'Route needs a start and end point before publishing.';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final userId = _userId;
      if (userId == null || userId.isEmpty) {
        throw Exception('Please sign in again.');
      }

      final trips = await _driverController.getDriverTrips(userId);
      if (_routeHasActiveRequests(route, trips)) {
        if (!mounted) {
          return;
        }
        await _openLiveTracking(route);
        return;
      }

      if (!mounted) {
        return;
      }

      await _openLiveTracking(route, demoRequests: demoRequests);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _openLiveTracking(
    RouteModel route, {
    List<_DemoPassengerRequest> demoRequests = const [],
  }) async {
    await Navigator.pushNamed(
      context,
      AppRoutes.liveTracking,
      arguments: {
        'isOnline': true,
        'pickup': route.from,
        'destination': route.to,
        'rideStatus': 'active',
        'demoRequests': demoRequests
            .map(
              (request) => {
                'passengerId': request.passengerId,
                'passengerName': request.passengerName,
                'passengerRating': request.passengerRating,
                'seatsRequested': request.seatsRequested,
                'route': request.route.toJson(),
              },
            )
            .toList(),
      },
    );
    if (mounted) {
      await _loadRoutes();
    }
  }

  Future<void> _endRoute(RouteModel route) async {
    if (_isSaving) {
      return;
    }

    final activeTrips = _activeTripsForRoute(route);
    if (activeTrips.isEmpty) {
      await _loadRoutes();
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      await Future.wait(
        activeTrips.map(
          (trip) => _driverController.cancelRide(tripId: trip.id),
        ),
      );
      await _loadRoutes();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  List<TripModel> _activeTripsForRoute(RouteModel route) {
    return _activeTrips.where((trip) {
      final routeId = trip.route?.id ?? '';
      final isSameRoute =
          routeId == route.id || routeId.startsWith('${route.id}-demo-');
      final isActiveStatus =
          trip.status == 'active' || trip.status == 'accepted';
      return isSameRoute && isActiveStatus;
    }).toList();
  }

  bool _routeHasActiveRequests(RouteModel route, List<TripModel> trips) {
    return trips.any((trip) {
      final routeId = trip.route?.id ?? '';
      final isSameRoute =
          routeId == route.id || routeId.startsWith('${route.id}-demo-');
      final isActiveStatus =
          trip.status == 'active' || trip.status == 'accepted';
      return isSameRoute && isActiveStatus;
    });
  }

  List<_DemoPassengerRequest> _buildDemoPassengerRequests(RouteModel route) {
    final points = [
      route.from,
      ...route.midpoints,
      route.to,
    ].where((point) => point.trim().isNotEmpty).toList();
    if (points.length < 2) {
      return const [];
    }

    const passengers = [
      ('passenger-demo-001', 'Anu Passenger', 4.8, 1),
      ('passenger-demo-002', 'Temu Passenger', 4.7, 2),
      ('passenger-demo-003', 'Saraa Passenger', 4.9, 1),
      ('passenger-demo-004', 'Nomin Passenger', 4.6, 3),
      ('passenger-demo-005', 'Bat Passenger', 4.8, 1),
    ];

    final requests = <_DemoPassengerRequest>[];
    for (var i = 0; i < points.length - 1 && i < passengers.length; i++) {
      final passenger = passengers[i];
      requests.add(
        _DemoPassengerRequest(
          passengerId: passenger.$1,
          passengerName: passenger.$2,
          passengerRating: passenger.$3,
          seatsRequested: passenger.$4,
          route: RouteModel(
            id: '${route.id}-demo-$i',
            userId: route.userId,
            from: points[i],
            to: points[i + 1],
            midpoints: const [],
          ),
        ),
      );
    }
    return requests;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'My Saved Routes',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: _isSaving ? null : _openCreateRoute,
            icon: const Icon(Icons.add, color: Colors.indigo),
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: _routes.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _isSaving ? null : _openCreateRoute,
              backgroundColor: Colors.indigo,
              label: Text(_isSaving ? 'Saving...' : 'Create Route'),
              icon: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _routes.isEmpty) {
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
                onPressed: _loadRoutes,
                child: Text(context.l10n.text('tryAgain')),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        if (_error != null)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Text(
              _error!,
              style: TextStyle(
                color: Colors.orange.shade900,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        Expanded(
          child: _routes.isEmpty ? _buildEmptyState() : _buildRouteList(),
        ),
      ],
    );
  }

  Widget _buildRouteList() {
    return RefreshIndicator(
      onRefresh: _loadRoutes,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _routes.length,
        itemBuilder: (context, index) {
          final route = _routes[index];
          final isPublished = _routeHasActiveRequests(route, _activeTrips);
          return _RouteCard(
            route: route,
            isPublished: isPublished,
            isBusy: _isSaving,
            onPublish: () => _publishRoute(route),
            onEndRoute: () => _endRoute(route),
            onTap: () => _openRoute(route),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.alt_route_rounded, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No saved routes yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create a route and it will be loaded from your backend data.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isSaving ? null : _openCreateRoute,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
              child: Text(_isSaving ? 'Saving...' : 'Create Your First Route'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DemoPassengerRequest {
  const _DemoPassengerRequest({
    required this.passengerId,
    required this.passengerName,
    required this.passengerRating,
    required this.seatsRequested,
    required this.route,
  });

  final String passengerId;
  final String passengerName;
  final double passengerRating;
  final int seatsRequested;
  final RouteModel route;
}

class _RouteCard extends StatelessWidget {
  const _RouteCard({
    required this.route,
    required this.isPublished,
    required this.isBusy,
    required this.onPublish,
    required this.onEndRoute,
    required this.onTap,
  });

  final RouteModel route;
  final bool isPublished;
  final bool isBusy;
  final VoidCallback onPublish;
  final VoidCallback onEndRoute;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.indigo.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      routeLabel(route),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isPublished
                          ? Colors.indigo.withValues(alpha: 0.10)
                          : Colors.green.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      isPublished ? 'Published' : 'Saved',
                      style: TextStyle(
                        color: isPublished ? Colors.indigo : Colors.green,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(),
              _buildLocationRow(Icons.circle, Colors.green, route.from),
              for (final midpoint in route.midpoints) ...[
                const Padding(
                  padding: EdgeInsets.only(left: 7),
                  child: SizedBox(height: 10, child: VerticalDivider(width: 1)),
                ),
                _buildLocationRow(Icons.more_horiz, Colors.orange, midpoint),
              ],
              const Padding(
                padding: EdgeInsets.only(left: 7),
                child: SizedBox(height: 10, child: VerticalDivider(width: 1)),
              ),
              _buildLocationRow(Icons.location_on, Colors.red, route.to),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      route.midpoints.isEmpty
                          ? 'Direct route'
                          : '${route.midpoints.length} midpoint${route.midpoints.length == 1 ? '' : 's'}',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (isPublished) ...[
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: isBusy ? null : onTap,
                      icon: const Icon(Icons.visibility_outlined, size: 16),
                      label: const Text('Go'),
                    ),
                  ],
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: isBusy
                        ? null
                        : isPublished
                        ? onEndRoute
                        : onPublish,
                    icon: Icon(
                      isPublished
                          ? Icons.stop_circle_outlined
                          : Icons.rocket_launch,
                      size: 16,
                    ),
                    label: Text(
                      isPublished ? 'End' : context.l10n.text('publish'),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isPublished
                          ? Colors.redAccent
                          : Colors.indigo,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationRow(IconData icon, Color color, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
      ],
    );
  }

  String routeLabel(RouteModel route) {
    final from = route.from.trim();
    final to = route.to.trim();
    if (from.isEmpty && to.isEmpty) {
      return 'Saved Route';
    }
    return '$from to $to';
  }
}
