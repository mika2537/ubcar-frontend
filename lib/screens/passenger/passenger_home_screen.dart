import 'package:flutter/material.dart';
import '../../system/widgets/bottom_nav.dart';
import '../../system/routing/app_routes.dart';
import '../shared/wallet_screen.dart';
import '../shared/profile_screen.dart';
import '../passenger/passenger_history_screen.dart';

class PassengerHomeScreen extends StatefulWidget {
  final String userName;
  final VoidCallback? onSearchClick;
  final VoidCallback? onBrowseRoutes;
  final void Function(String location)? onQuickLocationClick;
  final VoidCallback? onWallet;
  final VoidCallback? onHistory;
  final VoidCallback? onProfile;
  final VoidCallback? onNotifications;

  const PassengerHomeScreen({
    super.key,
    this.userName = 'Mohit',
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
  int activeTab = 0;
  int requestedSeats = 1;

  // Controllers for entry
  final TextEditingController _pickupController = TextEditingController(text: "My Current Location");
  final TextEditingController _dropoffController = TextEditingController();

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
        return WalletScreen(onBack: () => setState(() => activeTab = 0));
      case 3:
        return ProfileScreen(
            role: 'passenger', onBack: () => setState(() => activeTab = 0));
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
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Good Morning',
                style: TextStyle(color: Colors.black54, fontSize: 14)),
            Text('Hi, ${widget.userName} 👋',
                style:
                const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          ],
        ),
        const Spacer(),
        IconButton(
          onPressed: () =>
              Navigator.pushNamed(context, AppRoutes.notificationCenter),
          icon: const Icon(Icons.notifications_active_outlined,
              color: Colors.indigo),
          style:
          IconButton.styleFrom(backgroundColor: Colors.white, elevation: 2),
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
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 25)
        ],
      ),
      child: Column(
        children: [
          _buildLocationTextField(
              _pickupController, Icons.my_location, Colors.green, "Pickup Point"),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Divider(indent: 40),
          ),
          _buildLocationTextField(
              _dropoffController, Icons.location_on, Colors.red, "Where to?"),
        ],
      ),
    );
  }

  Widget _buildLocationTextField(
      TextEditingController controller, IconData icon, Color color, String hint) {
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
                          borderRadius: BorderRadius.circular(10)))),
              const SizedBox(height: 24),

              // SEAT SELECTION & POST REQUEST
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
                        const Text('Seats Required',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Row(
                          children: [
                            _seatButton(
                                Icons.remove,
                                    () => setState(() => requestedSeats > 1
                                    ? requestedSeats--
                                    : null)),
                            Padding(
                              padding:
                              const EdgeInsets.symmetric(horizontal: 16),
                              child: Text('$requestedSeats',
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold)),
                            ),
                            _seatButton(
                                Icons.add,
                                    () => setState(() => requestedSeats < 6
                                    ? requestedSeats++
                                    : null)),
                          ],
                        )
                      ],
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        if (_dropoffController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text("Please enter destination")));
                        } else {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.browseRoutes,
                            arguments: {
                              'seats': requestedSeats,
                              'pickup': _pickupController.text,
                              'dropoff': _dropoffController.text,
                            },
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Find Shared Rides'),
                    )
                  ],
                ),
              ),

              const SizedBox(height: 24),
              _buildCategoryCard(
                title: 'Browse Active Routes',
                subtitle: 'See drivers already on the road',
                icon: Icons.map,
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.browseRoutes,
                    arguments: {
                      'seats': requestedSeats,
                      'pickup': _pickupController.text,
                      'dropoff': _dropoffController.text,
                    },
                  );
                },
              ),
              const SizedBox(height: 24),
              const Text('Quick Destinations',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              _buildLocationTile({
                'name': 'Home',
                'address': 'HGM Residency, Rishra',
                'icon': Icons.home_outlined
              }),
              _buildLocationTile({
                'name': 'Office',
                'address': 'Salt Lake Sector V',
                'icon': Icons.work_outline
              }),
              const SizedBox(height: 100),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMapBackground() {
    return Container(color: const Color(0xFFF1F5F9));
  }

  Widget _seatButton(IconData icon, VoidCallback onTap) {
    return IconButton(
        onPressed: onTap,
        icon: Icon(icon, color: Colors.indigo),
        style: IconButton.styleFrom(
            side: const BorderSide(color: Colors.indigo)));
  }

  Widget _buildCategoryCard(
      {required String title,
        required String subtitle,
        required IconData icon,
        VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.indigo.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20)),
        child: Row(
          children: [
            CircleAvatar(
                backgroundColor: Colors.indigo,
                child: Icon(icon, color: Colors.white)),
            const SizedBox(width: 16),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(subtitle, style: const TextStyle(fontSize: 12))
                    ])),
            const Icon(Icons.arrow_forward_ios, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationTile(Map<String, dynamic> loc) {
    return ListTile(
      onTap: () {
        setState(() {
          _dropoffController.text = loc['name'];
        });
        // Immediately navigate to Available Routes with this destination
        Navigator.pushNamed(
          context,
          AppRoutes.browseRoutes,
          arguments: {
            'seats': requestedSeats,
            'pickup': _pickupController.text,
            'dropoff': loc['name'],
          },
        );
      },
      leading: Icon(loc['icon'] as IconData, color: Colors.grey),
      title:
      Text(loc['name'], style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(loc['address'], style: const TextStyle(fontSize: 11)),
      trailing: const Icon(Icons.chevron_right, size: 20),
    );
  }
}