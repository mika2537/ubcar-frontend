import 'package:flutter/material.dart';

class _Vehicle {
  final String vehicleId;
  final String driverId;
  final String licensePlate;
  final String make;
  final String model;
  final int capacity;
  final bool available;

  const _Vehicle({
    required this.vehicleId,
    required this.driverId,
    required this.licensePlate,
    required this.make,
    required this.model,
    required this.capacity,
    required this.available,
  });
}

class DriverInfoScreen extends StatelessWidget {
  final String driverName;
  final String driverPhone;
  final double driverRating;
  final int driverTrips;
  final String? driverPhoto;
  final _Vehicle vehicle;

  final String pickup;
  final String destination;
  final double fare;
  final int seatsRequested;

  final VoidCallback? onBack;
  final VoidCallback? onStartTracking;
  final VoidCallback? onCall;

  const DriverInfoScreen({
    super.key,
    this.driverName = 'Rahul Sharma',
    this.driverPhone = '+976 9911 2233',
    this.driverRating = 4.9,
    this.driverTrips = 2847,
    this.driverPhoto,
    this.vehicle = const _Vehicle(
      vehicleId: 'v1',
      driverId: 'd1',
      licensePlate: 'УБ 02-34 АБВ',
      make: 'Toyota',
      model: 'Prius',
      capacity: 4,
      available: true,
    ),
    this.pickup = 'Чингисийн өргөн чөлөө',
    this.destination = 'Сүхбаатарын талбай',
    this.fare = 5000,
    this.seatsRequested = 1,
    this.onBack,
    this.onStartTracking,
    this.onCall,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [scheme.primary, scheme.primary.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: onBack,
                        icon: const Icon(Icons.arrow_back),
                        color: scheme.onPrimary,
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.20),
                          shape: const CircleBorder(),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.shield, size: 14, color: Colors.white),
                            const SizedBox(width: 8),
                            Text(
                              'Request Accepted!',
                              style: TextStyle(
                                color: scheme.onPrimary.withOpacity(0.9),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Your driver is confirmed!',
                    style: TextStyle(
                      color: scheme.onPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                children: [
                  // Driver card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 62,
                              height: 62,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.indigo.withOpacity(0.18), width: 3),
                              ),
                              child: Center(
                                child: driverPhoto != null
                                    ? ClipOval(
                                        child: Image.network(
                                          driverPhoto!,
                                          width: 62,
                                          height: 62,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : Text(
                                        driverName.isNotEmpty ? driverName[0] : '?',
                                        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.black54),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    driverName,
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(Icons.star, size: 14, color: Colors.amber),
                                      const SizedBox(width: 6),
                                      Text(
                                        driverRating.toStringAsFixed(1),
                                        style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.black54),
                                      ),
                                      const SizedBox(width: 8),
                                      const Text('•', style: TextStyle(color: Colors.black45)),
                                      const SizedBox(width: 8),
                                      Text(
                                        '$driverTrips trips',
                                        style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w700),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: onCall,
                            icon: const Icon(Icons.phone),
                            label: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Phone number', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white70)),
                                Text(
                                  driverPhone,
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                                ),
                              ],
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: scheme.primary.withOpacity(0.95),
                              foregroundColor: scheme.onPrimary,
                              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Vehicle card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.directions_car, color: Colors.indigo),
                            const SizedBox(width: 8),
                            const Text(
                              'Vehicle',
                              style: TextStyle(fontWeight: FontWeight.w900),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${vehicle.make} ${vehicle.model}',
                                    style: const TextStyle(fontWeight: FontWeight.w900),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'capacity: ${vehicle.capacity} seats',
                                    style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.indigo,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                vehicle.licensePlate,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Trip info
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              children: const [
                                CircleAvatar(radius: 6, backgroundColor: Colors.green),
                                SizedBox(height: 8),
                                SizedBox(height: 30, child: VerticalDivider(thickness: 2)),
                                SizedBox(height: 8),
                                CircleAvatar(radius: 6, backgroundColor: Colors.red),
                              ],
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Pickup', style: TextStyle(fontSize: 11, color: Colors.black54, fontWeight: FontWeight.w800, letterSpacing: 0.3)),
                                  const SizedBox(height: 6),
                                  Text(pickup, style: const TextStyle(fontWeight: FontWeight.w800)),
                                  const SizedBox(height: 14),
                                  Text('Drop-off', style: TextStyle(fontSize: 11, color: Colors.black54, fontWeight: FontWeight.w800, letterSpacing: 0.3)),
                                  const SizedBox(height: 6),
                                  Text(destination, style: const TextStyle(fontWeight: FontWeight.w800)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.people, size: 18, color: Colors.black54),
                                const SizedBox(width: 8),
                                Text(
                                  '$seatsRequested ${seatsRequested > 1 ? 'seats' : 'seat'}',
                                  style: const TextStyle(fontWeight: FontWeight.w800),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Text(
                              '₮${fare.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Colors.indigo,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),
                ],
              ),
            ),

            // Track ride
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.98),
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onStartTracking,
                  icon: const Icon(Icons.navigation),
                  label: const Text(
                    'Track Ride',
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
