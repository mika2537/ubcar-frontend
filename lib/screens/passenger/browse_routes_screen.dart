import 'package:flutter/material.dart';

import '../../system/localization/app_localizations.dart';
import '../../system/models/discover_route_model.dart';
import '../../system/state/auth_controller.dart';
import '../../system/state/passenger_controller.dart';
import '../../system/routing/app_routes.dart';

class BrowseRoutesScreen extends StatefulWidget {
  final int initialSeats;
  final String initialPickup;
  final String initialDropoff;

  const BrowseRoutesScreen({
    super.key,
    this.initialSeats = 1,
    this.initialPickup = '',
    this.initialDropoff = '',
  });

  @override
  State<BrowseRoutesScreen> createState() => _BrowseRoutesScreenState();
}

class _BrowseRoutesScreenState extends State<BrowseRoutesScreen> {
  final _passengerController = PassengerController();
  final _authController = AuthController();
  final _pickupController = TextEditingController();
  final _dropoffController = TextEditingController();

  List<DiscoverRouteModel> _rankedRoutes = const [];
  bool _isLoading = true;
  String? _message;
  int _seatsRequested = 1;
  String? _selectedRouteId;

  @override
  void initState() {
    super.initState();
    _pickupController.text = widget.initialPickup;
    _dropoffController.text = widget.initialDropoff;
    _seatsRequested = widget.initialSeats;
    _loadRoutes();
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _dropoffController.dispose();
    super.dispose();
  }

  Future<void> _loadRoutes() async {
    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      final routes = await _passengerController.discoverRoutes();
      final ranked = _rankRoutes(routes);
      if (!mounted) return;

      setState(() {
        _rankedRoutes = ranked;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _message = 'Unable to load route recommendations.';
        _isLoading = false;
      });
    }
  }

  List<DiscoverRouteModel> _rankRoutes(List<DiscoverRouteModel> routes) {
    final rawPickup = _pickupController.text.trim();
    final rawDestination = _dropoffController.text.trim();

    final scored = routes
        .map(
          (route) => MapEntry(
            route,
            _computeRouteScore(route, rawPickup, rawDestination),
          ),
        )
        .where((entry) => entry.value > 0.0)
        .toList();

    scored.sort((a, b) => b.value.compareTo(a.value));

    return scored.map((entry) => entry.key).toList();
  }

  double _computeRouteScore(
    DiscoverRouteModel route,
    String pickup,
    String destination,
  ) {
    final fromScore = _locationMatchScore(route.route.from, pickup);
    final toScore = _locationMatchScore(route.route.to, destination);
    final midpointScore =
        route.route.midpoints.any(
          (point) =>
              _locationMatchScore(point, pickup) > 0.5 ||
              _locationMatchScore(point, destination) > 0.5,
        )
        ? 0.12
        : 0.0;
    final directnessScore =
        1.0 - (route.route.midpoints.length.clamp(0, 4) / 5.0);

    final availabilityScore =
        1.0 - (route.activeTripCount / 6.0).clamp(0.0, 1.0);
    final reliabilityScore =
        (route.completedTripCount / (route.completedTripCount + 2.0)).clamp(
          0.0,
          1.0,
        );

    final routeMatch = (fromScore + toScore) / 2.0;
    final score =
        (0.50 * routeMatch) +
        (0.20 * availabilityScore) +
        (0.20 * reliabilityScore) +
        (0.08 * directnessScore) +
        midpointScore;

    return score.clamp(0.0, 1.0);
  }

  double _locationMatchScore(String routeValue, String searchValue) {
    final routeNormalized = routeValue.toLowerCase().trim();
    final searchNormalized = searchValue.toLowerCase().trim();

    if (searchNormalized.isEmpty) {
      return 0.5;
    }
    if (routeNormalized == searchNormalized) {
      return 1.0;
    }
    if (routeNormalized.contains(searchNormalized) ||
        searchNormalized.contains(routeNormalized)) {
      return 0.85;
    }
    final routeWords = routeNormalized.split(RegExp(r'\s+'));
    final searchWords = searchNormalized.split(RegExp(r'\s+'));
    final sharedWords = routeWords.where(searchWords.contains).length;
    if (sharedWords > 0) {
      return 0.6 + (sharedWords / routeWords.length) * 0.25;
    }
    return 0.15;
  }

  Future<void> _onSearchPressed() async {
    setState(() {
      _isLoading = true;
      _message = null;
    });

    final ranked = _rankRoutes(
      _rankedRoutes.isEmpty
          ? await _passengerController.discoverRoutes()
          : _rankedRoutes,
    );
    if (!mounted) return;
    setState(() {
      _rankedRoutes = ranked;
      _isLoading = false;
    });
  }

  Future<void> _requestRide(DiscoverRouteModel route) async {
    final pleaseLogInMessage = context.l10n.text('pleaseLogInBeforeRide');
    final user = await _authController.getCurrentUser();
    if (!mounted) return;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(pleaseLogInMessage)),
      );
      return;
    }

    setState(() {
      _message = 'Requesting ride from ${route.driver.name ?? 'driver'}...';
      _isLoading = true;
    });

    try {
      final trip = await _passengerController.createTrip(
        passengerId: user.id,
        route: route.route,
      );
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _message = 'Ride requested successfully.';
        _selectedRouteId = route.route.id;
      });

      if (trip != null) {
        Navigator.pushNamed(
          context,
          AppRoutes.searchingDriver,
          arguments: {
            'tripId': trip.id,
            'pickup': _pickupController.text,
            'destination': _dropoffController.text,
            'routeName': '${route.route.from} → ${route.route.to}',
            'driverName': route.driver.name ?? 'Driver',
            'seatsRequested': _seatsRequested,
            'fare': _estimateFare(route, _seatsRequested),
            'tripDistance': _estimateDistance(route),
            'tripDuration': _estimateDuration(route),
          },
        );
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _message = 'Failed to request ride. Please try again.';
      });
    }
  }

  double _estimateFare(DiscoverRouteModel route, int seats) {
    final midpointFee = route.route.midpoints.length * 1200;
    final seatCount = seats < 1 ? 1 : seats;
    return (6500 + midpointFee) * seatCount.toDouble();
  }

  String _estimateDistance(DiscoverRouteModel route) {
    final km = 4.8 + (route.route.midpoints.length * 1.7);
    return '${km.toStringAsFixed(1)} km';
  }

  String _estimateDuration(DiscoverRouteModel route) {
    final minutes = 14 + (route.route.midpoints.length * 5);
    return '$minutes min';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.text('browseSharedRoutes')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              children: [
                _buildLocationField(
                  controller: _pickupController,
                  label: 'Pickup',
                  hint: 'Enter pickup location',
                ),
                const SizedBox(height: 10),
                _buildLocationField(
                  controller: _dropoffController,
                  label: 'Destination',
                  hint: 'Enter destination',
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _onSearchPressed,
                        child: Text(context.l10n.text('searchRoutes')),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l10n.text('seats'),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Text('$_seatsRequested'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_message != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                _message!,
                style: const TextStyle(color: Colors.indigo),
              ),
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildResultsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationField({
    required TextEditingController controller,
    required String label,
    required String hint,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
      textInputAction: TextInputAction.next,
      onSubmitted: (_) => _onSearchPressed(),
    );
  }

  Widget _buildResultsList() {
    if (_rankedRoutes.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'No matching shared routes were found. Try changing pickup or destination, or save more routes in the backend.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      itemCount: _rankedRoutes.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final route = _rankedRoutes[index];
        final score =
            (_computeRouteScore(
                      route,
                      _pickupController.text.trim(),
                      _dropoffController.text.trim(),
                    ) *
                    100)
                .toInt();
        final routeName = '${route.route.from} → ${route.route.to}';

        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        routeName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.indigo.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$score%',
                        style: const TextStyle(
                          color: Colors.indigo,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '${context.l10n.text('driver')}: ${route.driver.name ?? context.l10n.text('unknownDriver')}',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 6),
                Text(
                  '${context.l10n.text('activeTrips')}: ${route.activeTripCount} • ${context.l10n.text('completed')}: ${route.completedTripCount}',
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                ),
                if (route.route.midpoints.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Midpoints: ${route.route.midpoints.join(', ')}',
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _requestRide(route),
                        child: Text(context.l10n.text('requestThisRide')),
                      ),
                    ),
                    if (_selectedRouteId == route.route.id) ...[
                      const SizedBox(width: 10),
                      const Icon(Icons.check_circle, color: Colors.green),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
