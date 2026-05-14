import 'package:flutter/material.dart';
import '../../system/routing/app_routes.dart';
import '../../system/localization/app_language_controller.dart';
import '../../system/localization/app_localizations.dart';
import '../../system/state/auth_controller.dart';
import '../../system/state/driver_controller.dart';
import '../../system/models/trip_model.dart';
import '../../system/models/user_model.dart';
import '../../system/widgets/bottom_nav.dart';
import '../../system/widgets/language_menu_button.dart';
import '../shared/trip_history_screen.dart';
import '../shared/wallet_screen.dart';
import '../shared/profile_screen.dart';
import '../driver/driver_earnings_screen.dart';

class _RideRequest {
  final String requestId;
  final String passengerName;
  final double passengerRating;
  final int seatRequested;
  final String pickupAddress;
  final String dropAddress;
  final String timestamp;

  const _RideRequest({
    required this.requestId,
    required this.passengerName,
    required this.passengerRating,
    required this.seatRequested,
    required this.pickupAddress,
    required this.dropAddress,
    required this.timestamp,
  });
}

class DriverHomeScreen extends StatefulWidget {
  final String driverName;
  final bool isOnline;
  final Map<String, dynamic>? publishedRouteRequest;

  const DriverHomeScreen({
    super.key,
    this.driverName = '',
    this.isOnline = false,
    this.publishedRouteRequest,
  });

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  final _languageController = AppLanguageController();
  final _authController = AuthController();
  final _driverController = DriverController();
  late bool isOnline;
  int activeTab = 0;
  List<_RideRequest> rideRequests = [];
  UserModel? currentUser;
  List<TripModel> driverTrips = const [];
  int savedRouteCount = 0;
  bool isLoading = true;
  String? loadError;
  bool _publishedRequestDismissed = false;

  @override
  void initState() {
    super.initState();
    isOnline = widget.isOnline;
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
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
      final trips = await _driverController.getDriverTrips(user.id);
      final routes = await _driverController.getSavedRoutes(user.id);
      final passengers = <String, UserModel>{};
      for (final trip in trips) {
        final passengerId = trip.passengerId;
        if (passengerId == null || passengerId.isEmpty) {
          continue;
        }
        final passenger = await _driverController.getUserProfile(passengerId);
        if (passenger != null) {
          passengers[passengerId] = passenger;
        }
      }
      if (!mounted) return;
      final loadedRideRequests = _buildRideRequests(trips, passengers);
      final publishedRequest = _publishedRouteRideRequest();
      final visibleLoadedRequests = publishedRequest == null
          ? loadedRideRequests
          : loadedRideRequests
                .where(
                  (request) => request.requestId != publishedRequest.requestId,
                )
                .toList();
      setState(() {
        currentUser = user;
        driverTrips = trips;
        rideRequests = [?publishedRequest, ...visibleLoadedRequests];
        savedRouteCount = routes.length;
        isOnline = publishedRequest != null || isOnline;
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

  _RideRequest? _publishedRouteRideRequest() {
    final request = widget.publishedRouteRequest;
    if (request == null || _publishedRequestDismissed) {
      return null;
    }

    final routeId = request['routeId'] as String? ?? 'route';
    final tripId = request['tripId'] as String? ?? '';
    final passengerName =
        request['passengerName'] as String? ?? 'Demo Passenger';
    final pickup = request['pickup'] as String? ?? 'Pickup not set';
    final destination =
        request['destination'] as String? ?? 'Destination not set';
    final seats = (request['seatsRequested'] as num?)?.toInt() ?? 1;
    final rating = (request['passengerRating'] as num?)?.toDouble() ?? 4.8;

    return _RideRequest(
      requestId: tripId.isNotEmpty
          ? tripId
          : 'demo-$routeId-${DateTime.now().millisecondsSinceEpoch}',
      passengerName: passengerName,
      passengerRating: rating,
      seatRequested: seats,
      pickupAddress: pickup,
      dropAddress: destination,
      timestamp: 'Now',
    );
  }

  List<_RideRequest> _buildRideRequests(
    List<TripModel> trips,
    Map<String, UserModel> passengers,
  ) {
    return trips.where((trip) => trip.status == 'active').map((trip) {
      final passenger = passengers[trip.passengerId ?? ''];
      final tripPassengerName = trip.passengerName?.trim();
      final passengerName =
          tripPassengerName != null && tripPassengerName.isNotEmpty
          ? tripPassengerName
          : passenger?.name?.trim().isNotEmpty == true
          ? passenger!.name!.trim()
          : 'Passenger';
      return _RideRequest(
        requestId: trip.id,
        passengerName: passengerName,
        passengerRating: trip.passengerRating,
        seatRequested: trip.seatsRequested,
        pickupAddress: trip.route?.from ?? 'Pickup not set',
        dropAddress: trip.route?.to ?? 'Destination not set',
        timestamp: _relativeTime(trip.createdAt),
      );
    }).toList();
  }

  String _relativeTime(DateTime createdAt) {
    final now = DateTime.now();
    final age = now.difference(createdAt.toLocal());
    if (age.inMinutes < 1) {
      return 'Now';
    }
    if (age.inMinutes < 60) {
      return '${age.inMinutes} min ago';
    }
    if (age.inHours < 24) {
      return '${age.inHours} hr ago';
    }
    return '${age.inDays} d ago';
  }

  Future<void> _acceptRide(_RideRequest request) async {
    final isDemoRequest = request.requestId.startsWith('demo-');
    if (!isDemoRequest) {
      await _driverController.acceptRide(tripId: request.requestId);
    }
    if (!mounted) return;
    setState(() {
      if (isDemoRequest) {
        _publishedRequestDismissed = true;
      }
      rideRequests = rideRequests
          .where((rideRequest) => rideRequest.requestId != request.requestId)
          .toList();
      driverTrips = driverTrips
          .map(
            (trip) => trip.id == request.requestId
                ? trip.copyWith(status: 'accepted')
                : trip,
          )
          .toList();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Approved ${request.passengerName}')),
    );
  }

  Future<void> _declineRide(_RideRequest request) async {
    final isDemoRequest = request.requestId.startsWith('demo-');
    if (!isDemoRequest) {
      await _driverController.cancelRide(tripId: request.requestId);
    }
    if (!mounted) return;
    setState(() {
      if (isDemoRequest) {
        _publishedRequestDismissed = true;
      }
      rideRequests = rideRequests
          .where((rideRequest) => rideRequest.requestId != request.requestId)
          .toList();
      driverTrips = driverTrips
          .map(
            (trip) => trip.id == request.requestId
                ? trip.copyWith(status: 'cancelled')
                : trip,
          )
          .toList();
    });
  }

  void handleNavClick(int index) {
    setState(() => activeTab = index);
  }

  void handleToggle() async {
    final newState = !isOnline;
    setState(() => isOnline = newState);
    if (!newState) {
      setState(() => rideRequests = []);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: activeTab,
        children: [
          _buildHomeDashboard(), // Index 0
          TripHistoryScreen(
            // Index 1
            onBack: () => setState(() => activeTab = 0),
          ),
          WalletScreen(
            // Index 2
            role: 'driver',
            onBack: () => setState(() => activeTab = 0),
          ),
          ProfileScreen(
            // Index 3
            role: 'driver',
            onBack: () => setState(() => activeTab = 0),
          ),
          // Inside your DriverHomeScreen's handleNavClick or build logic
          DriverEarningsScreen(
            onBack: () {
              setState(() {
                activeTab = 0; // Switches back to the Home/Dashboard tab
              });
            },
          ),
        ],
      ),
      bottomNavigationBar: BottomNav(
        currentIndex: activeTab,
        onTap: handleNavClick,
      ),
    );
  }

  Widget _buildHomeDashboard() {
    final l10n = context.l10n;
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFF8FAFC), Color(0xFFE0E7FF)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),
        SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isOnline
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              isOnline
                                  ? l10n.text('online')
                                  : l10n.text('offline'),
                              style: TextStyle(
                                color: isOnline
                                    ? Colors.green.shade700
                                    : Colors.red.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.hiDriver(
                              currentUser?.name ?? widget.driverName,
                            ),
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pushNamed(
                        context,
                        AppRoutes.notificationCenter,
                      ),
                      icon: const Icon(Icons.notifications_outlined, size: 28),
                    ),
                    LanguageMenuButton(controller: _languageController),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    _StatCard(
                      icon: Icons.alt_route,
                      value: '$savedRouteCount',
                      label: l10n.text('routes'),
                    ),
                    const SizedBox(width: 10),
                    _StatCard(
                      icon: Icons.access_time,
                      value: '${driverTrips.length}',
                      label: l10n.text('trips'),
                    ),
                    const SizedBox(width: 10),
                    _StatCard(
                      icon: Icons.check_circle_outline,
                      value:
                          '${driverTrips.where((trip) => trip.status == 'completed').length}',
                      label: l10n.text('done'),
                    ),
                  ],
                ),
              ),

              // Action Buttons Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _ActionBtn(
                            icon: Icons.navigation,
                            label: l10n.text('myRoutes'),
                            onPressed: () {
                              Navigator.pushNamed(
                                context,
                                AppRoutes.savedDriverRoutes,
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ActionBtn(
                            icon: Icons.trending_up,
                            label: l10n.text('earnings'),
                            onPressed: () => Navigator.pushNamed(
                              context,
                              AppRoutes.driverEarnings,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // NEW: Create New Route Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.pushNamed(
                          context,
                          AppRoutes.createDriverRoute,
                        ),
                        icon: const Icon(Icons.add_location_alt_outlined),
                        label: Text(
                          l10n.text('createNewRoute'),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(16.0),
                child: InkWell(
                  onTap: handleToggle,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isOnline ? Colors.indigo : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.power_settings_new,
                          color: isOnline ? Colors.white : Colors.indigo,
                          size: 32,
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isOnline
                                  ? l10n.text('youAreOnline')
                                  : l10n.text('goOnline'),
                              style: TextStyle(
                                color: isOnline ? Colors.white : Colors.black87,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            Text(
                              isOnline
                                  ? l10n.text('acceptingRides')
                                  : l10n.text('tapToStartEarning'),
                              style: TextStyle(
                                color: isOnline
                                    ? Colors.white70
                                    : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _loadDashboard,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    itemCount: rideRequests.length + 1,
                    itemBuilder: (context, index) {
                      if (index == rideRequests.length) {
                        if (isLoading) {
                          return const Padding(
                            padding: EdgeInsets.only(top: 48),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        if (loadError != null) {
                          return _MessageState(
                            title: l10n.text('couldNotLoadDashboard'),
                            subtitle: loadError!,
                          );
                        }
                        return rideRequests.isEmpty
                            ? _MessageState(
                                title: driverTrips.isEmpty
                                    ? l10n.text('noTripsYet')
                                    : l10n.text('noRideRequestsYet'),
                                subtitle: driverTrips.isEmpty
                                    ? l10n.text('createRouteAndGoOnline')
                                    : l10n.text('tripDataLoaded'),
                              )
                            : const SizedBox(height: 20);
                      }
                      final req = rideRequests[index];
                      return _RideRequestCard(
                        request: req,
                        onAccept: () => _acceptRide(req),
                        onDecline: () => _declineRide(req),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
  });
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withOpacity(0.05)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: Colors.indigo),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              label,
              style: const TextStyle(color: Colors.black54, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.onPressed,
  });
  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        side: BorderSide(color: Colors.indigo.withOpacity(0.2)),
      ),
    );
  }
}

class _RideRequestCard extends StatelessWidget {
  final _RideRequest request;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  const _RideRequestCard({
    required this.request,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(child: Text(request.passengerName[0])),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.passengerName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${request.passengerRating} ⭐',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                    Text(
                      '${request.seatRequested} ${request.seatRequested == 1 ? 'seat' : 'seats'} requested',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.indigo,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                request.timestamp,
                style: const TextStyle(fontSize: 12, color: Colors.indigo),
              ),
            ],
          ),
          const Divider(height: 24),
          _RouteInfo(
            icon: Icons.circle,
            color: Colors.green,
            address: request.pickupAddress,
          ),
          const SizedBox(height: 8),
          _RouteInfo(
            icon: Icons.location_on,
            color: Colors.red,
            address: request.dropAddress,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onDecline,
                  child: const Text('Decline'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: onAccept,
                  child: const Text('Accept'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RouteInfo extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String address;
  const _RouteInfo({
    required this.icon,
    required this.color,
    required this.address,
  });
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            address,
            style: const TextStyle(fontSize: 13, color: Colors.black87),
          ),
        ),
      ],
    );
  }
}

class _MessageState extends StatelessWidget {
  final String title;
  final String subtitle;

  const _MessageState({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 40),
        child: Column(
          children: [
            Icon(
              Icons.directions_car_outlined,
              size: 64,
              color: Colors.black12,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                color: Colors.black45,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.black38, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
