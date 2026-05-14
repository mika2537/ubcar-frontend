import 'package:flutter/material.dart';

import '../../system/localization/app_localizations.dart';
import '../../system/routing/app_routes.dart';
import '../../system/state/auth_controller.dart';
import '../../system/models/user_model.dart';
import '../../system/widgets/bottom_nav.dart';
import '../shared/profile_screen.dart';
import '../shared/wallet_screen.dart';
import 'passenger_history_screen.dart';

class PassengerHomeScreen extends StatefulWidget {
  final VoidCallback? onSearchClick;
  final VoidCallback? onBrowseRoutes;
  final void Function(String location)? onQuickLocationClick;
  final VoidCallback? onWallet;
  final VoidCallback? onHistory;
  final VoidCallback? onProfile;
  final VoidCallback? onNotifications;

  const PassengerHomeScreen({
    super.key,
    this.onSearchClick,
    this.onBrowseRoutes,
    this.onQuickLocationClick,
    this.onWallet,
    this.onHistory,
    this.onProfile,
    this.onNotifications,
  });

  @override
  State<PassengerHomeScreen> createState() => _PassengerHomeScreenState();
}

class _PassengerHomeScreenState extends State<PassengerHomeScreen> {
  final _authController = AuthController();

  int activeTab = 0;
  int requestedSeats = 1;
  final TextEditingController _pickupController = TextEditingController(
    text: 'Current Location',
  );
  final TextEditingController _dropoffController = TextEditingController();

  UserModel? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _dropoffController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    final user = await _authController.getCurrentUser();
    if (!mounted) {
      return;
    }
    setState(() {
      _currentUser = user;
      _isLoading = false;
    });
  }

  void handleNavClick(int index) {
    setState(() => activeTab = index);
    if (index == 1) widget.onHistory?.call();
    if (index == 2) widget.onWallet?.call();
    if (index == 3) widget.onProfile?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          _buildCurrentScreen(),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: BottomNav(currentIndex: activeTab, onTap: handleNavClick),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentScreen() {
    switch (activeTab) {
      case 0:
        return _buildHomeContent();
      case 1:
        return const PassengerHistoryScreen();
      case 2:
        return WalletScreen(
          role: 'passenger',
          onBack: () => setState(() => activeTab = 0),
        );
      case 3:
        return ProfileScreen(
          role: 'passenger',
          onBack: () => setState(() => activeTab = 0),
        );
      default:
        return _buildHomeContent();
    }
  }

  Widget _buildHomeContent() {
    return Stack(
      children: [
        _buildMapBackground(),
        Positioned(top: 50, left: 20, right: 20, child: _buildHeader()),
        Positioned(top: 130, left: 20, right: 20, child: _buildEntryCard()),
        _buildDraggableSheet(),
      ],
    );
  }

  Widget _buildHeader() {
    final displayName = _currentUser?.name?.trim().isNotEmpty == true
        ? _currentUser!.name!.trim()
        : 'Passenger';

    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isLoading ? 'Loading...' : 'Welcome back',
              style: const TextStyle(color: Colors.black54, fontSize: 14),
            ),
            Text(
              'Hi, $displayName',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const Spacer(),
        IconButton(
          onPressed: () =>
              Navigator.pushNamed(context, AppRoutes.notificationCenter),
          icon: const Icon(
            Icons.notifications_active_outlined,
            color: Colors.indigo,
          ),
          style: IconButton.styleFrom(
            backgroundColor: Colors.white,
            elevation: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildEntryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 25),
        ],
      ),
      child: Column(
        children: [
          _buildLocationTextField(
            _pickupController,
            Icons.my_location,
            Colors.green,
            'Pickup Point',
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Divider(indent: 40),
          ),
          _buildLocationTextField(
            _dropoffController,
            Icons.location_on,
            Colors.red,
            'Where to?',
          ),
        ],
      ),
    );
  }

  Widget _buildLocationTextField(
    TextEditingController controller,
    IconData icon,
    Color color,
    String hint,
  ) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hint,
              border: InputBorder.none,
              hintStyle: const TextStyle(color: Colors.black38),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDraggableSheet() {
    return DraggableScrollableSheet(
      initialChildSize: 0.4,
      minChildSize: 0.35,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20)],
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.indigo.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.indigo.withOpacity(0.1)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Seats Required',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Row(
                          children: [
                            _seatButton(Icons.remove, () {
                              if (requestedSeats > 1) {
                                setState(() => requestedSeats--);
                              }
                            }),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Text(
                                '$requestedSeats',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            _seatButton(Icons.add, () {
                              if (requestedSeats < 6) {
                                setState(() => requestedSeats++);
                              }
                            }),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        if (_dropoffController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                context.l10n.text('pleaseEnterDestination'),
                              ),
                            ),
                          );
                          return;
                        }

                        Navigator.pushNamed(
                          context,
                          AppRoutes.browseRoutes,
                          arguments: {
                            'seats': requestedSeats,
                            'pickup': _pickupController.text.trim(),
                            'dropoff': _dropoffController.text.trim(),
                          },
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(context.l10n.text('findSharedRides')),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Your route search will use live backend route data instead of local mock rides.',
                style: TextStyle(
                  color: Colors.black54,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMapBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE0E7FF), Color(0xFFF8FAFC)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: const Center(
        child: Icon(Icons.map_outlined, size: 320, color: Colors.black12),
      ),
    );
  }

  Widget _seatButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.indigo),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.indigo, size: 20),
      ),
    );
  }
}
