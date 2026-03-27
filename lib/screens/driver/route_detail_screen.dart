import 'package:flutter/material.dart';

class _RouteTemplate {
  final String templateId;
  final String name;
  final bool isRoundTrip;
  final String? returnTime;
  final String origin;
  final String destination;
  final List<String> stops;
  final String departureTime;
  final List<String> days;
  final int seats;
  final int pricePerSeat;
  final bool isActive;

  const _RouteTemplate({
    required this.templateId,
    required this.name,
    required this.isRoundTrip,
    this.returnTime,
    required this.origin,
    required this.destination,
    required this.stops,
    required this.departureTime,
    required this.days,
    required this.seats,
    required this.pricePerSeat,
    required this.isActive,
  });
}

class _UpcomingBooking {
  final String id;
  final String name;
  final String pickup;
  final int seats;
  final String time;

  const _UpcomingBooking({
    required this.id,
    required this.name,
    required this.pickup,
    required this.seats,
    required this.time,
  });
}

class RouteDetailScreen extends StatefulWidget {
  final _RouteTemplate route;
  final VoidCallback? onBack;
  final VoidCallback? onEdit;
  final VoidCallback? onStartRide;

  static const _sampleRoute = _RouteTemplate(
    templateId: 'sample',
    name: 'Daily Office Commute',
    isRoundTrip: true,
    returnTime: '18:00',
    origin: 'Salt Lake Sector V',
    destination: 'Park Street',
    stops: ['Karunamoyee', 'Rabindra Sadan'],
    departureTime: '08:30',
    days: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
    seats: 3,
    pricePerSeat: 60,
    isActive: true,
  );

  const RouteDetailScreen({
    super.key,
    _RouteTemplate? route,
    this.onBack,
    this.onEdit,
    this.onStartRide,
  }) : route = route ?? _sampleRoute;

  @override
  State<RouteDetailScreen> createState() => _RouteDetailScreenState();
}

class _RouteDetailScreenState extends State<RouteDetailScreen> {
  late bool isActive;

  static const upcomingBookings = [
    _UpcomingBooking(id: '1', name: 'Priya Sharma', pickup: 'Karunamoyee', seats: 1, time: '08:30'),
    _UpcomingBooking(id: '2', name: 'Rahul Das', pickup: 'Salt Lake Sector V', seats: 2, time: '08:30'),
  ];

  static const routeStats = {
    'totalTrips': 48,
    'totalEarnings': 8640,
    'avgRating': 4.9,
    'completionRate': 98,
  };

  @override
  void initState() {
    super.initState();
    isActive = widget.route.isActive;
  }

  @override
  Widget build(BuildContext context) {
    final route = widget.route;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header hero
            SizedBox(
              height: 240,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Container(
                      decoration: const BoxDecoration(color: Color(0xFFE5E7EB)),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: const Text('Route map preview'),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 14,
                    left: 16,
                    right: 16,
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: widget.onBack,
                          icon: const Icon(Icons.arrow_back),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.75),
                            shape: const CircleBorder(),
                          ),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            IconButton(
                              onPressed: () {},
                              icon: const Icon(Icons.share),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.white.withOpacity(0.75),
                                shape: const CircleBorder(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: widget.onEdit,
                              icon: const Icon(Icons.edit),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.white.withOpacity(0.75),
                                shape: const CircleBorder(),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 16,
                    bottom: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isActive ? Colors.green.withOpacity(0.15) : Colors.grey.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        isActive ? '● Active' : '○ Offline',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: isActive ? Colors.green.shade700 : Colors.black54,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [
                  const SizedBox(height: 0),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    route.name,
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                          fontWeight: FontWeight.w900,
                                        ),
                                  ),
                                  if (route.isRoundTrip)
                                    const SizedBox(height: 10),
                                  if (route.isRoundTrip)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.indigo.withOpacity(0.10),
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: const Text(
                                        'Round Trip',
                                        style: TextStyle(
                                          color: Colors.indigo,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '₹${route.pricePerSeat}',
                                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.indigo),
                                ),
                                const SizedBox(height: 6),
                                const Text('per seat', style: TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              children: [
                                const CircleAvatar(radius: 6, backgroundColor: Colors.indigo),
                                Container(width: 3, height: 48, color: Colors.grey.shade400),
                                const CircleAvatar(
                                  radius: 6,
                                  backgroundColor: Colors.white,
                                  child: Icon(Icons.circle, size: 0),
                                ),
                              ],
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Pickup', style: TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.w800)),
                                  const SizedBox(height: 6),
                                  Text(route.origin, style: const TextStyle(fontWeight: FontWeight.w800)),
                                  const SizedBox(height: 14),
                                  if (route.stops.isNotEmpty) ...[
                                    for (int i = 0; i < route.stops.length; i++) ...[
                                      Text('Stop ${i + 1}', style: const TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.w800)),
                                      const SizedBox(height: 6),
                                      Text(route.stops[i], style: const TextStyle(fontWeight: FontWeight.w700)),
                                      const SizedBox(height: 14),
                                    ]
                                  ],
                                  Text('Drop-off', style: const TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.w800)),
                                  const SizedBox(height: 6),
                                  Text(route.destination, style: const TextStyle(fontWeight: FontWeight.w800)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        const Divider(height: 1),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.access_time, size: 16, color: Colors.indigo),
                            const SizedBox(width: 6),
                            Text(route.departureTime),
                            if (route.isRoundTrip && route.returnTime != null) ...[
                              const SizedBox(width: 10),
                              Text('/ ${route.returnTime}', style: const TextStyle(color: Colors.black54)),
                            ],
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(Icons.calendar_month, size: 16, color: Colors.indigo),
                            const SizedBox(width: 6),
                            Text(route.days.join(', ')),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(Icons.people, size: 16, color: Colors.indigo),
                            const SizedBox(width: 6),
                            Text('${route.seats} seats'),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 1.25,
                    children: [
                      _MetricCard(
                        icon: Icons.trending_up,
                        label: 'Total Trips',
                        value: '${routeStats['totalTrips']}',
                      ),
                      _MetricCard(
                        icon: Icons.attach_money,
                        label: 'Earnings',
                        value: '₹${routeStats['totalEarnings']}',
                      ),
                      _MetricCard(
                        icon: Icons.star,
                        label: 'Avg Rating',
                        value: '${routeStats['avgRating']}',
                      ),
                      _MetricCard(
                        icon: Icons.navigation,
                        label: 'Completion',
                        value: '${routeStats['completionRate']}%',
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Today\'s Bookings',
                            style: TextStyle(fontWeight: FontWeight.w900)),
                        const SizedBox(height: 12),
                        ...upcomingBookings.map((b) {
                          return Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: Colors.grey.shade200),
                              ),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: Colors.indigo.withOpacity(0.10),
                                  child: Text(b.name[0], style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.indigo)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(b.name, style: const TextStyle(fontWeight: FontWeight.w900)),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.place, size: 14, color: Colors.black54),
                                          const SizedBox(width: 6),
                                          Text(b.pickup, style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w700)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${b.seats} ${b.seats > 1 ? 'seats' : 'seat'}',
                                      style: const TextStyle(fontWeight: FontWeight.w900),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      b.time,
                                      style: const TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.w700),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Bottom actions
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.96),
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => isActive = !isActive),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        side: BorderSide(
                          color: isActive ? Colors.red.withOpacity(0.35) : Colors.green.withOpacity(0.35),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(isActive ? Icons.pause_circle : Icons.play_circle,
                              color: isActive ? Colors.red : Colors.green),
                          const SizedBox(width: 8),
                          Text(isActive ? 'Pause Route' : 'Activate Route',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: isActive ? Colors.red : Colors.green,
                              )),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: widget.onStartRide,
                      icon: const Icon(Icons.navigation),
                      label: const Text('Start Ride', style: TextStyle(fontWeight: FontWeight.w900)),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: Colors.indigo),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w700, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}
