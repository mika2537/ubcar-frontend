import 'package:flutter/material.dart';

class LiveTrackingScreen extends StatefulWidget {
  final String pickup;
  final String destination;  final String rideStatus;
  final VoidCallback? onCancel;

  const LiveTrackingScreen({
    super.key,
    required this.pickup,
    required this.destination,
    this.rideStatus = 'active',
    this.onCancel,
  });

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  // Mock Data for Passengers who requested a seat
  final List<Map<String, dynamic>> passengerRequests = [
    {'name': 'Arjun Das', 'seats': 1, 'pickup': 'Karunamoyee', 'status': 'Accepted', 'lat': 0.1, 'lng': 0.2},
    {'name': 'Srijit Roy', 'seats': 2, 'pickup': 'City Center', 'status': 'Pending', 'lat': -0.1, 'lng': -0.2},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. BACKGROUND: MAP VIEW
          _buildMapView(),

          // 2. TOP OVERLAY: ROUTE INFO
          _buildTopRouteCard(),

          // 3. BOTTOM OVERLAY: PASSENGER REQUESTS & MANAGEMENT
          _buildPassengerBottomSheet(),

          // 4. BACK BUTTON
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
    return Container(
      color: const Color(0xFFE5E7EB),
      child: Stack(
        children: [
          const Center(child: Icon(Icons.map_outlined, size: 400, color: Colors.black12)),

          // Driver Location Marker
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.indigo, borderRadius: BorderRadius.circular(8)),
                  child: const Text('My Location', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
                const Icon(Icons.navigation, color: Colors.indigo, size: 40),
              ],
            ),
          ),

          // Accepted Passenger Marker
          Positioned(
            top: 250,
            right: 80,
            child: Column(
              children: [
                const Icon(Icons.person_pin_circle, color: Colors.green, size: 45),
                Container(
                  padding: const EdgeInsets.all(4),
                  color: Colors.white,
                  child: const Text('Arjun (Accepted)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopRouteCard() {
    return Positioned(
      top: 100,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
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
                      const Text('PICKUP', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                      Text(widget.pickup, style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.only(left: 5),
              child: SizedBox(height: 10, child: VerticalDivider(width: 1, color: Colors.grey)),
            ),
            Row(
              children: [
                const Icon(Icons.location_on, size: 14, color: Colors.red),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('DESTINATION', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                      Text(widget.destination, style: const TextStyle(fontWeight: FontWeight.bold)),
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
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(10))),

              const Padding(
                padding: EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    Text("Ride Management", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Spacer(),
                    Icon(Icons.people_alt_outlined, size: 18, color: Colors.indigo),
                  ],
                ),
              ),

              Expanded(
                child: passengerRequests.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  itemCount: passengerRequests.length + 1, // +1 for the Cancel Button at the end
                  itemBuilder: (context, index) {
                    if (index == passengerRequests.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: ElevatedButton(
                          onPressed: widget.onCancel,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade50,
                            foregroundColor: Colors.red,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            side: BorderSide(color: Colors.red.shade100),
                          ),
                          child: const Text("Cancel Published Route"),
                        ),
                      );
                    }

                    final req = passengerRequests[index];
                    return _buildPassengerRequestCard(req, index);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPassengerRequestCard(Map<String, dynamic> req, int index) {
    bool isPending = req['status'] == 'Pending';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
              CircleAvatar(
                backgroundColor: isPending ? Colors.orange.shade50 : Colors.green.shade50,
                child: Text(req['name'][0], style: TextStyle(color: isPending ? Colors.orange : Colors.green)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(req['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('Pickup: ${req['pickup']}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                    ]
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isPending ? Colors.orange.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isPending ? "Pending" : "Accepted",
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isPending ? Colors.orange : Colors.green),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              const Icon(Icons.airline_seat_recline_normal, size: 16, color: Colors.indigo),
              const SizedBox(width: 6),
              Text('${req['seats']} Seats Requested', style: const TextStyle(fontSize: 13)),
              const Spacer(),
              if (isPending) ...[
                TextButton(
                  onPressed: () => setState(() => passengerRequests.removeAt(index)),
                  child: const Text('Decline', style: TextStyle(color: Colors.red)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => setState(() => req['status'] = 'Accepted'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Accept'),
                ),
              ] else
                const Text('Waiting for Pickup', style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.person_search_outlined, size: 64, color: Colors.black12),
          const SizedBox(height: 16),
          const Text('No passengers joined yet', style: TextStyle(color: Colors.black45, fontWeight: FontWeight.bold)),
          const Text('Nearby passengers will see your published route',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black38, fontSize: 12)),
        ],
      ),
    );
  }
}