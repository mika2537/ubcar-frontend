import 'package:flutter/material.dart';
import '../../system/routing/app_routes.dart';
import '../../system/widgets/bottom_nav.dart';
import '../shared/trip_history_screen.dart';
import '../shared/wallet_screen.dart';
import '../shared/profile_screen.dart';
import '../driver/driver_earnings_screen.dart';
import '../driver/create_route_screen.dart.dart';
import '../driver/saved_route_screen_test.dart';

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

  const DriverHomeScreen({
    super.key,
    this.driverName = 'Rajesh',
    this.isOnline = false,
  });

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  late bool isOnline;
  int activeTab = 0;
  List<_RideRequest> rideRequests = [];

  static const _mockRequests = [
    _RideRequest(
      requestId: 'rq1',
      passengerName: 'Amit Kumar',
      passengerRating: 4.8,
      seatRequested: 1,
      pickupAddress: 'Salt Lake Sector V',
      dropAddress: 'Park Street Metro',
      timestamp: '2 min ago',
    ),
    _RideRequest(
      requestId: 'rq2',
      passengerName: 'Priya Sharma',
      passengerRating: 4.9,
      seatRequested: 2,
      pickupAddress: 'Karunamoyee',
      dropAddress: 'Rabindra Sadan',
      timestamp: '5 min ago',
    ),
  ];

  @override
  void initState() {
    super.initState();
    isOnline = widget.isOnline;
    if (isOnline) {
      rideRequests = List.of(_mockRequests);
    }
  }

  void handleNavClick(int index) {
    setState(() => activeTab = index);
  }

  void handleToggle() async {
    final newState = !isOnline;
    setState(() => isOnline = newState);

    if (newState) {
      await Future<void>.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      setState(() => rideRequests = List.of(_mockRequests));
    } else {
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
          _buildHomeDashboard(),                // Index 0
          TripHistoryScreen(                    // Index 1
            onBack: () => setState(() => activeTab = 0),
          ),
          WalletScreen(                         // Index 2
            role: 'driver',
            onBack: () => setState(() => activeTab = 0),
          ),
          ProfileScreen(                        // Index 3
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
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isOnline ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              isOnline ? '• Online' : '• Offline',
                              style: TextStyle(
                                color: isOnline ? Colors.green.shade700 : Colors.red.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Hi, ${widget.driverName} 👋',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pushNamed(context, AppRoutes.notificationCenter),
                      icon: const Icon(Icons.notifications_outlined, size: 28),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    _StatCard(icon: Icons.account_balance_wallet, value: '₹1,240', label: 'Today'),
                    const SizedBox(width: 10),
                    _StatCard(icon: Icons.access_time, value: '8', label: 'Trips'),
                    const SizedBox(width: 10),
                    _StatCard(icon: Icons.star, value: '4.9', label: 'Rating'),
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
                          child:_ActionBtn(
                            icon: Icons.navigation,
                            label: 'My Routes',
                            onPressed: () {
                              Navigator.pushNamed(context, AppRoutes.savedDriverRoutes);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ActionBtn(
                            icon: Icons.trending_up,
                            label: 'Earnings',
                            onPressed: () => Navigator.pushNamed(context, AppRoutes.driverEarnings),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // NEW: Create New Route Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.pushNamed(context, AppRoutes.createDriverRoute),
                        icon: const Icon(Icons.add_location_alt_outlined),
                        label: const Text('Create New Route', style: TextStyle(fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
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
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
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
                              isOnline ? 'You are Online' : 'Go Online',
                              style: TextStyle(
                                color: isOnline ? Colors.white : Colors.black87,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            Text(
                              isOnline ? 'Accepting rides' : 'Tap to start earning',
                              style: TextStyle(
                                color: isOnline ? Colors.white70 : Colors.black54,
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
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  itemCount: rideRequests.length + 1,
                  itemBuilder: (context, index) {
                    if (index == rideRequests.length) {
                      return rideRequests.isEmpty ? _EmptyState() : const SizedBox(height: 20);
                    }
                    final req = rideRequests[index];
                    return _RideRequestCard(
                      request: req,
                      onAccept: () => setState(() => rideRequests.removeAt(index)),
                      onDecline: () => setState(() => rideRequests.removeAt(index)),
                    );
                  },
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
  const _StatCard({required this.icon, required this.value, required this.label});
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
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(label, style: const TextStyle(color: Colors.black54, fontSize: 12)),
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
  const _ActionBtn({required this.icon, required this.label, required this.onPressed});
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
  const _RideRequestCard({required this.request, required this.onAccept, required this.onDecline});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(child: Text(request.passengerName[0])),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(request.passengerName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('${request.passengerRating} ⭐', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                ]),
              ),
              Text(request.timestamp, style: const TextStyle(fontSize: 12, color: Colors.indigo)),
            ],
          ),
          const Divider(height: 24),
          _RouteInfo(icon: Icons.circle, color: Colors.green, address: request.pickupAddress),
          const SizedBox(height: 8),
          _RouteInfo(icon: Icons.location_on, color: Colors.red, address: request.dropAddress),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: OutlinedButton(onPressed: onDecline, child: const Text('Decline'))),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton(onPressed: onAccept, child: const Text('Accept'))),
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
  const _RouteInfo({required this.icon, required this.color, required this.address});
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 14, color: color),
      const SizedBox(width: 12),
      Expanded(child: Text(address, style: const TextStyle(fontSize: 13, color: Colors.black87))),
    ]);
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 40),
        child: Column(
          children: [
            Icon(Icons.directions_car_outlined, size: 64, color: Colors.black12),
            const SizedBox(height: 16),
            const Text('No ride requests yet', style: TextStyle(color: Colors.black45, fontWeight: FontWeight.bold)),
            const Text('Go online to start receiving requests', style: TextStyle(color: Colors.black38, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}