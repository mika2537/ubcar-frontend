import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../system/models/route_model.dart';
import '../../system/models/trip_model.dart';
import '../../system/models/user_model.dart';
import '../../system/services/backend_api_service.dart';
import '../../system/services/maps_service.dart';
import '../../system/state/auth_controller.dart';
import '../../system/state/driver_controller.dart';

class LiveTrackingScreen extends StatefulWidget {
  final String pickup;
  final String destination;
  final String rideStatus;
  final List<Map<String, dynamic>> demoRequests;
  final VoidCallback? onCancel;

  const LiveTrackingScreen({
    super.key,
    required this.pickup,
    required this.destination,
    this.rideStatus = 'active',
    this.demoRequests = const [],
    this.onCancel,
  });

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  final _authController = AuthController();
  final _driverController = DriverController();
  final _api = BackendApiService();
  final _maps = const MapsService();

  List<TripModel> _activeTrips = const [];
  Map<String, UserModel> _passengersById = const {};
  bool _isLoading = true;
  bool _isPublishingDemoRequests = false;
  bool _hasCreatedDemoRequests = false;
  String? _error;
  TripModel? _acceptedTrip;
  List<LatLng> _optimizedRoutePoints = const [];
  bool _isLoadingOptimizedRoute = false;
  Timer? _demoRequestTimer;
  final Map<String, Timer> _boardingTimers = {};
  Set<String> _boardingReadyTripIds = const {};
  Set<String> _seatedTripIds = const {};

  @override
  void initState() {
    super.initState();
    _loadTrips();
    _scheduleDemoRequests();
  }

  @override
  void dispose() {
    _demoRequestTimer?.cancel();
    for (final timer in _boardingTimers.values) {
      timer.cancel();
    }
    super.dispose();
  }

  void _scheduleDemoRequests() {
    if (widget.demoRequests.isEmpty) {
      return;
    }
    _demoRequestTimer = Timer(
      const Duration(seconds: 1),
      _createDemoPassengerRequests,
    );
  }

  Future<void> _loadTrips({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final user = await _authController.getCurrentUser();
      if (user == null) {
        throw Exception('Please sign in again.');
      }
      final trips = await _driverController.getDriverTrips(user.id);
      final activeTrips = trips
          .where((trip) => trip.status == 'active' || trip.status == 'accepted')
          .take(5)
          .toList();
      final passengers = <String, UserModel>{};
      for (final trip in activeTrips) {
        if (trip.passengerName?.trim().isNotEmpty == true) {
          continue;
        }
        final passengerId = trip.passengerId;
        if (passengerId == null || passengerId.isEmpty) {
          continue;
        }
        final passenger = await _api.getUserProfile(passengerId);
        if (passenger != null) {
          passengers[passengerId] = passenger;
        }
      }
      if (!mounted) {
        return;
      }
      final acceptedTrip = _acceptedTrip == null
          ? activeTrips.where((trip) => trip.status == 'accepted').firstOrNull
          : activeTrips
                    .where((trip) => trip.id == _acceptedTrip!.id)
                    .firstOrNull ??
                activeTrips
                    .where((trip) => trip.status == 'accepted')
                    .firstOrNull;
      final shouldLoadAcceptedRoute =
          acceptedTrip != null && acceptedTrip.id != _acceptedTrip?.id;
      setState(() {
        _activeTrips = activeTrips;
        _acceptedTrip = acceptedTrip ?? _acceptedTrip;
        _passengersById = passengers;
        _isLoading = false;
      });
      if (shouldLoadAcceptedRoute) {
        unawaited(_loadOptimizedRoute(acceptedTrip));
      }
      for (final trip in activeTrips.where(
        (trip) => trip.status == 'accepted',
      )) {
        _scheduleBoardingReady(trip.id);
      }
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

  Future<void> _createDemoPassengerRequests() async {
    if (_hasCreatedDemoRequests || _isPublishingDemoRequests) {
      return;
    }

    setState(() => _isPublishingDemoRequests = true);
    try {
      for (final request in widget.demoRequests.take(5)) {
        final routeJson = request['route'];
        if (routeJson is! Map<String, dynamic>) {
          continue;
        }
        await _api.createDemoRideRequest(
          route: RouteModel.fromJson(routeJson),
          seatsRequested: (request['seatsRequested'] as num?)?.toInt() ?? 1,
          passengerId:
              request['passengerId'] as String? ?? 'passenger-demo-001',
          passengerName:
              request['passengerName'] as String? ?? 'Demo Passenger',
          passengerRating:
              (request['passengerRating'] as num?)?.toDouble() ?? 4.8,
        );
      }
      _hasCreatedDemoRequests = true;
      await _loadTrips(showLoading: false);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _isPublishingDemoRequests = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildMapView(),
          _buildTopRouteCard(),
          _buildPassengerBottomSheet(),
          Positioned(
            top: 40,
            left: 20,
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: widget.onCancel ?? () => Navigator.pop(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapView() {
    final acceptedTrip = _acceptedTrip;
    if (acceptedTrip != null) {
      final pickup = _locationFor(acceptedTrip.route?.from ?? 'Pickup', 0);
      final destination = _locationFor(
        acceptedTrip.route?.to ?? 'Destination',
        1,
      );
      final routePoints = _optimizedRoutePoints.isNotEmpty
          ? _optimizedRoutePoints
          : [pickup, destination];
      final pickupMarker = routePoints.first;
      final destinationMarker = routePoints.last;
      final center = LatLng(
        (pickupMarker.latitude + destinationMarker.latitude) / 2,
        (pickupMarker.longitude + destinationMarker.longitude) / 2,
      );

      return Stack(
        children: [
          GoogleMap(
            key: ValueKey('${acceptedTrip.id}-${routePoints.length}'),
            initialCameraPosition: CameraPosition(target: center, zoom: 13),
            markers: {
              Marker(
                markerId: const MarkerId('pickup'),
                position: pickupMarker,
                infoWindow: InfoWindow(
                  title: 'Pickup',
                  snippet: acceptedTrip.route?.from ?? '',
                ),
              ),
              Marker(
                markerId: const MarkerId('destination'),
                position: destinationMarker,
                infoWindow: InfoWindow(
                  title: 'Destination',
                  snippet: acceptedTrip.route?.to ?? '',
                ),
              ),
            },
            polylines: {
              Polyline(
                polylineId: const PolylineId('accepted-route'),
                points: routePoints,
                color: Colors.indigo,
                width: 5,
              ),
            },
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),
          if (_isLoadingOptimizedRoute)
            const Positioned(
              top: 52,
              right: 20,
              child: Card(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Text('Optimizing route...'),
                ),
              ),
            ),
        ],
      );
    }

    return Stack(
      children: [
        Container(
          color: const Color(0xFFE5E7EB),
          child: Stack(
            children: [
              const Center(
                child: Icon(
                  Icons.map_outlined,
                  size: 400,
                  color: Colors.black12,
                ),
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.indigo,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'My Location',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.navigation,
                      color: Colors.indigo,
                      size: 40,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (_isLoadingOptimizedRoute)
          const Positioned(
            top: 52,
            right: 20,
            child: Card(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Text('Optimizing route...'),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTopRouteCard() {
    final activeRoute = _acceptedTrip?.route;
    final pickup = activeRoute?.from ?? widget.pickup;
    final destination = activeRoute?.to ?? widget.destination;

    return Positioned(
      top: 100,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.circle, size: 12, color: Colors.green),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'PICKUP',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        pickup,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.only(left: 5),
              child: SizedBox(
                height: 10,
                child: VerticalDivider(width: 1, color: Colors.grey),
              ),
            ),
            Row(
              children: [
                const Icon(Icons.location_on, size: 14, color: Colors.red),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'DESTINATION',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        destination,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPassengerBottomSheet() {
    return DraggableScrollableSheet(
      initialChildSize: 0.35,
      minChildSize: 0.2,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF8FAFC),
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 15)],
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    const Text(
                      'Ride Management',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => _loadTrips(showLoading: false),
                      icon: const Icon(Icons.refresh, color: Colors.indigo),
                      tooltip: 'Refresh requests',
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(_error!, textAlign: TextAlign.center),
                        ),
                      )
                    : _activeTrips.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                        itemCount: _activeTrips.length + 1,
                        itemBuilder: (context, index) {
                          if (index == _activeTrips.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 20),
                              child: ElevatedButton(
                                onPressed: widget.onCancel,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red.shade50,
                                  foregroundColor: Colors.red,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  side: BorderSide(color: Colors.red.shade100),
                                ),
                                child: const Text('Cancel Published Route'),
                              ),
                            );
                          }
                          return _buildPassengerRequestCard(
                            _activeTrips[index],
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPassengerRequestCard(TripModel trip) {
    final isPending = trip.status == 'active';
    final isAccepted = trip.status == 'accepted';
    final isSeated = _seatedTripIds.contains(trip.id);
    final isBoardingReady = _boardingReadyTripIds.contains(trip.id);
    final passenger = trip.passengerId == null
        ? null
        : _passengersById[trip.passengerId!];
    final passengerName = trip.passengerName?.trim().isNotEmpty == true
        ? trip.passengerName!.trim()
        : passenger?.name ?? trip.passengerId ?? 'Passenger';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: isPending
                    ? Colors.orange.shade50
                    : Colors.green.shade50,
                child: Text(
                  passengerName.isNotEmpty
                      ? passengerName[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    color: isPending ? Colors.orange : Colors.green,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      passengerName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${trip.passengerRating.toStringAsFixed(1)} rating - ${trip.seatsRequested} ${trip.seatsRequested == 1 ? 'seat' : 'seats'} requested',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isPending
                      ? Colors.orange.withValues(alpha: 0.1)
                      : Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isPending
                      ? 'Pending'
                      : isSeated
                      ? 'In ride'
                      : isBoardingReady
                      ? 'Ready'
                      : 'Accepted',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isPending
                        ? Colors.orange
                        : isSeated
                        ? Colors.blue
                        : isBoardingReady
                        ? Colors.indigo
                        : Colors.green,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 16,
                color: Colors.indigo,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${trip.route?.from ?? 'Unknown'} → ${trip.route?.to ?? 'Unknown'}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          if (isPending) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _declineTrip(trip),
                    child: const Text('Decline'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _acceptTrip(trip),
                    child: const Text('Accept'),
                  ),
                ),
              ],
            ),
          ],
          if (isAccepted) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: isSeated
                  ? ElevatedButton.icon(
                      onPressed: () => _dropOffPassenger(trip),
                      icon: const Icon(Icons.flag_circle_outlined, size: 18),
                      label: const Text('Буух'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                      ),
                    )
                  : isBoardingReady
                  ? ElevatedButton.icon(
                      onPressed: () => _markPassengerSeated(trip),
                      icon: const Icon(Icons.event_seat, size: 18),
                      label: const Text('Суусан'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    )
                  : OutlinedButton.icon(
                      onPressed: null,
                      icon: const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      label: const Text('Passenger boarding...'),
                    ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _acceptTrip(TripModel trip) async {
    await _driverController.acceptRide(tripId: trip.id);
    if (mounted) {
      setState(() {
        _acceptedTrip = trip.copyWith(status: 'accepted');
      });
    }
    _scheduleBoardingReady(trip.id);
    await _loadOptimizedRoute(trip);
    await _loadTrips(showLoading: false);
  }

  Future<void> _declineTrip(TripModel trip) async {
    await _driverController.cancelRide(tripId: trip.id);
    await _loadTrips(showLoading: false);
  }

  void _scheduleBoardingReady(String tripId) {
    if (tripId.isEmpty ||
        _boardingReadyTripIds.contains(tripId) ||
        _boardingTimers.containsKey(tripId)) {
      return;
    }

    _boardingTimers[tripId] = Timer(const Duration(seconds: 3), () {
      _boardingTimers.remove(tripId);
      if (!mounted) {
        return;
      }
      setState(() {
        _boardingReadyTripIds = {..._boardingReadyTripIds, tripId};
      });
    });
  }

  Future<void> _markPassengerSeated(TripModel trip) async {
    _boardingTimers.remove(trip.id)?.cancel();
    if (mounted) {
      setState(() {
        _seatedTripIds = {..._seatedTripIds, trip.id};
        _boardingReadyTripIds = _boardingReadyTripIds
            .where((tripId) => tripId != trip.id)
            .toSet();
      });
    }
  }

  Future<void> _dropOffPassenger(TripModel trip) async {
    await _driverController.completeTrip(tripId: trip.id);
    _boardingTimers.remove(trip.id)?.cancel();
    if (mounted) {
      setState(() {
        _seatedTripIds = _seatedTripIds
            .where((tripId) => tripId != trip.id)
            .toSet();
        _boardingReadyTripIds = _boardingReadyTripIds
            .where((tripId) => tripId != trip.id)
            .toSet();
        if (_acceptedTrip?.id == trip.id) {
          _acceptedTrip = null;
          _optimizedRoutePoints = const [];
        }
      });
      await _showDriverPaymentSheet(trip);
    }
    await _loadTrips(showLoading: false);
  }

  Future<void> _showDriverPaymentSheet(TripModel trip) {
    final fare = _estimateFare(trip);
    final distance = _estimateDistance(trip);
    final duration = _estimateDuration(trip);
    final passengerName = trip.passengerName?.trim().isNotEmpty == true
        ? trip.passengerName!.trim()
        : trip.passengerId ?? 'Passenger';

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.payments_outlined,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Payment received',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _PaymentSummaryRow(label: 'Passenger', value: passengerName),
                _PaymentSummaryRow(
                  label: 'Seats',
                  value:
                      '${trip.seatsRequested} ${trip.seatsRequested == 1 ? 'seat' : 'seats'}',
                ),
                _PaymentSummaryRow(label: 'Distance', value: distance),
                _PaymentSummaryRow(label: 'Duration', value: duration),
                const Divider(height: 28),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Total fare',
                        style: TextStyle(
                          color: Colors.black54,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      '₮$fare',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Back to live tracking'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  int _estimateFare(TripModel trip) {
    final midpointFee = (trip.route?.midpoints.length ?? 0) * 1200;
    final seatCount = trip.seatsRequested < 1 ? 1 : trip.seatsRequested;
    return (6500 + midpointFee) * seatCount;
  }

  String _estimateDistance(TripModel trip) {
    final km = 4.8 + ((trip.route?.midpoints.length ?? 0) * 1.7);
    return '${km.toStringAsFixed(1)} km';
  }

  String _estimateDuration(TripModel trip) {
    final minutes = 14 + ((trip.route?.midpoints.length ?? 0) * 5);
    return '$minutes min';
  }

  LatLng _locationFor(String label, int salt) {
    final hash = label.codeUnits.fold<int>(
      17 + salt,
      (value, codeUnit) => (value * 31 + codeUnit) & 0x7fffffff,
    );
    final latOffset = ((hash % 900) - 450) / 10000.0;
    final lngOffset = (((hash ~/ 900) % 900) - 450) / 10000.0;
    return LatLng(47.9189 + latOffset, 106.9176 + lngOffset);
  }

  Future<void> _loadOptimizedRoute(TripModel trip) async {
    final route = trip.route;
    if (route == null || route.from.trim().isEmpty || route.to.trim().isEmpty) {
      return;
    }

    setState(() => _isLoadingOptimizedRoute = true);
    try {
      final points = await _maps.getOptimizedRoutePolyline(
        origin: route.from,
        destination: route.to,
        waypoints: route.midpoints,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _optimizedRoutePoints = (points ?? const [])
            .map((point) => LatLng(point['lat']!, point['lng']!))
            .toList();
      });
    } finally {
      if (mounted) {
        setState(() => _isLoadingOptimizedRoute = false);
      }
    }
  }

  Widget _buildEmptyState() {
    final isWaiting = widget.demoRequests.isNotEmpty;
    final message = _isPublishingDemoRequests
        ? 'Saving demo passenger requests...'
        : isWaiting
        ? 'Waiting for passenger seat requests...'
        : 'No active passenger trips found.';
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isWaiting ? Icons.radar : Icons.route,
            size: 72,
            color: Colors.grey,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isWaiting
                ? 'Demo requests will appear here from the backend.'
                : 'This screen reads active trip data from the backend.',
            style: const TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

class _PaymentSummaryRow extends StatelessWidget {
  const _PaymentSummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
