import 'package:flutter/material.dart';

class PassengerHistoryScreen extends StatelessWidget {
  const PassengerHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock Data for Trip History
    final List<Map<String, dynamic>> tripHistory = [
      {
        'date': 'Oct 24, 2023',
        'time': '09:15 AM',
        'origin': 'Salt Lake Sector V',
        'destination': 'Park Street Metro',
        'fare': 60,
        'status': 'Completed',
        'driver': 'Rajesh Kumar',
        'sharedWith': ['Amit S.', 'Suman D.'], // People shared with
        'carModel': 'Swift Dezire (WB 02 AD 1234)',
      },
      {
        'date': 'Oct 22, 2023',
        'time': '06:30 PM',
        'origin': 'City Center 1',
        'destination': 'Rishra Station',
        'fare': 120,
        'status': 'Completed',
        'driver': 'Suresh Pal',
        'sharedWith': ['Priya M.'],
        'carModel': 'Hyundai Xcent',
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('My Trips',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        // Bottom padding for Nav
        itemCount: tripHistory.length,
        itemBuilder: (context, index) {
          final trip = tripHistory[index];
          return _TripHistoryCard(trip: trip);
        },
      ),
    );
  }
}

class _TripHistoryCard extends StatelessWidget {
  final Map<String, dynamic> trip;

  const _TripHistoryCard({required this.trip});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header: Date and Price
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(trip['date'],
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(trip['time'], style: const TextStyle(
                        color: Colors.grey, fontSize: 12)),
                  ],
                ),
                Text('₹${trip['fare']}',
                    style: const TextStyle(fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo)),
              ],
            ),
          ),
          const Divider(height: 1),

          // Route Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildRouteRow(Icons.circle, Colors.green, trip['origin']),
                const SizedBox(height: 4),
                _buildRouteRow(
                    Icons.location_on, Colors.red, trip['destination']),
              ],
            ),
          ),

          // Driver & Shared Passengers
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.indigo.withOpacity(0.03),
              borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(20)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                        Icons.drive_eta, size: 16, color: Colors.black54),
                    const SizedBox(width: 8),
                    Text('Driver: ${trip['driver']}',
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                        Icons.people_outline, size: 16, color: Colors.black54),
                    const SizedBox(width: 8),
                    Text('Shared with: ${trip['sharedWith'].join(", ")}',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.black54)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteRow(IconData icon, Color color, String text) {
    return Row(
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Text(text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
        ),
      ],
    );
  }
}