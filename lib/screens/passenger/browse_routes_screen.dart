import 'package:flutter/material.dart';

// --- MODELS ---

class _Vehicle {
  final String model;
  final String licensePlate;
  const _Vehicle({required this.model, required this.licensePlate});
}

class _Route {
  final String routeId;
  final String name;
  final String driverName;
  final double driverRating;
  final _Vehicle? vehicle;
  final String startAddress;
  final String endAddress;
  final List<String> stops;
  final String departureTime;
  final int seatsAvailable;
  final int pricePerSeat;

  const _Route({
    required this.routeId,
    required this.name,
    required this.driverName,
    required this.driverRating,
    required this.vehicle,
    required this.startAddress,
    required this.endAddress,
    required this.stops,
    required this.departureTime,
    required this.seatsAvailable,
    required this.pricePerSeat,
  });
}

// --- SCREEN ---

class BrowseRoutesScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final void Function(_Route route, int seats)? onRequestSeat;
  final int initialSeats;
  final String initialPickup;
  final String initialDropoff;
  final bool allowSeatChange;

  const BrowseRoutesScreen({
    super.key,
    this.onBack,
    this.onRequestSeat,
    this.initialSeats = 1,
    this.initialPickup = '',
    this.initialDropoff = '',
    this.allowSeatChange = false,
  });

  @override
  State<BrowseRoutesScreen> createState() => _BrowseRoutesScreenState();
}

class _BrowseRoutesScreenState extends State<BrowseRoutesScreen> {
  String searchQuery = '';
  _Route? selectedRoute;
  late int seatsRequested;

  @override
  void initState() {
    super.initState();
    seatsRequested = widget.initialSeats;
  }

  final mockAvailableRoutes = const <_Route>[
    _Route(
      routeId: 'r1',
      name: 'Daily Office Commute',
      driverName: 'Rajesh Kumar',
      driverRating: 4.9,
      vehicle: _Vehicle(model: 'Swift Dzire', licensePlate: 'WB 02 AB 1234'),
      startAddress: 'Salt Lake Sector V',
      endAddress: 'Park Street Metro',
      stops: ['Karunamoyee', 'Rabindra Sadan'],
      departureTime: '08:30',
      seatsAvailable: 2,
      pricePerSeat: 60,
    ),
    _Route(
      routeId: 'r2',
      name: 'New Town Express',
      driverName: 'Amit Singh',
      driverRating: 4.7,
      vehicle: _Vehicle(model: 'i20', licensePlate: 'WB 06 CD 5678'),
      startAddress: 'New Town AA1',
      endAddress: 'Esplanade',
      stops: [],
      departureTime: '09:00',
      seatsAvailable: 3,
      pricePerSeat: 55,
    ),
    _Route(
      routeId: 'r3',
      name: 'Airport Shuttle',
      driverName: 'Sanjay Mondal',
      driverRating: 4.8,
      vehicle: _Vehicle(model: 'Nexon', licensePlate: 'WB 14 EF 9012'),
      startAddress: 'Howrah Station',
      endAddress: 'Netaji Airport',
      stops: ['Sealdah', 'Salt Lake'],
      departureTime: '05:00',
      seatsAvailable: 3,
      pricePerSeat: 150,
    ),
  ];

  List<_Route> get filteredRoutes {
    if (searchQuery.trim().isEmpty) return mockAvailableRoutes;
    final q = searchQuery.toLowerCase();
    return mockAvailableRoutes.where((route) {
      return route.startAddress.toLowerCase().contains(q) ||
          route.endAddress.toLowerCase().contains(q) ||
          route.name.toLowerCase().contains(q) ||
          route.stops.any((s) => s.toLowerCase().contains(q));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            if (selectedRoute != null) {
              setState(() => selectedRoute = null);
            } else {
              if (widget.onBack != null) {
                widget.onBack!();
              } else {
                Navigator.pop(context);
              }
            }
          },
        ),
        title: Text(
          selectedRoute == null ? 'Available Routes' : 'Confirm Ride',
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: selectedRoute == null
          ? _buildList()
          : _buildRouteDetails(context, selectedRoute!),
    );
  }

  Widget _buildList() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search routes, locations...',
              prefixIcon: const Icon(Icons.search, color: Colors.indigo),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (v) => setState(() => searchQuery = v),
          ),
        ),
        Expanded(
          child: filteredRoutes.isEmpty
              ? _buildEmptyState()
              : ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            itemCount: filteredRoutes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final route = filteredRoutes[index];
              return _buildRouteCard(route);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRouteCard(_Route route) {
    return InkWell(
      onTap: () => setState(() => selectedRoute = route),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.indigo.withOpacity(0.1),
                  child: Text(route.driverName[0],
                      style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(route.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Row(
                        children: [
                          const Icon(Icons.star, size: 14, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(route.driverRating.toString(),
                              style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                ),
                Text('₹${route.pricePerSeat}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo)),
              ],
            ),
            const Divider(height: 24),
            _buildLocationRow(Icons.circle, Colors.green, route.startAddress),
            const Padding(
              padding: EdgeInsets.only(left: 5),
              child: SizedBox(height: 10, child: VerticalDivider(width: 1)),
            ),
            _buildLocationRow(Icons.location_on, Colors.red, route.endAddress),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(route.departureTime, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(width: 16),
                const Icon(Icons.people, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text('${route.seatsAvailable} seats left',
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteDetails(BuildContext context, _Route route) {
    final int totalFare = seatsRequested * route.pricePerSeat;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildTimelineCard(route),
              const SizedBox(height: 16),
              _buildSectionTitle("Driver & Vehicle"),
              _buildDriverCard(route),
              const SizedBox(height: 16),
              _buildSectionTitle(widget.allowSeatChange ? "Adjust Seats" : "Ride Details"),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                child: widget.allowSeatChange
                    ? _buildAdjustableSeats(route)
                    : _buildFixedSeats(),
              ),
              const SizedBox(height: 16),
              _buildFareBreakdown(route),
            ],
          ),
        ),
        _buildBottomAction(totalFare.toDouble(), route),
      ],
    );
  }

  Widget _buildTimelineCard(_Route route) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("ROUTE TIMELINE", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.indigo, letterSpacing: 1.2)),
          const SizedBox(height: 20),
          _buildTimelineRow(icon: Icons.trip_origin, color: Colors.grey, label: "Driver Starts", address: route.startAddress, isSmall: true),
          _buildTimelineDivider(),
          _buildTimelineRow(icon: Icons.my_location, color: Colors.green, label: "Your Pickup", address: widget.initialPickup.isNotEmpty ? widget.initialPickup : "Current Location", highlight: true),
          _buildTimelineDivider(),
          _buildTimelineRow(icon: Icons.location_on, color: Colors.red, label: "Your Destination", address: widget.initialDropoff.isNotEmpty ? widget.initialDropoff : route.endAddress, highlight: true),
          _buildTimelineDivider(),
          _buildTimelineRow(icon: Icons.flag, color: Colors.grey, label: "Driver Ends", address: route.endAddress, isSmall: true),
        ],
      ),
    );
  }

  Widget _buildAdjustableSeats(_Route route) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text("How many seats?", style: TextStyle(fontWeight: FontWeight.w600)),
        Row(
          children: [
            _SeatBtn(Icons.remove, () {
              if (seatsRequested > 1) setState(() => seatsRequested--);
            }),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Text('$seatsRequested', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            _SeatBtn(Icons.add, () {
              if (seatsRequested < route.seatsAvailable) setState(() => seatsRequested++);
            }),
          ],
        )
      ],
    );
  }

  Widget _buildFixedSeats() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text("Seats Selected", style: TextStyle(color: Colors.black54)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: Colors.indigo.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Text("$seatsRequested Seats", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
        ),
      ],
    );
  }

  Widget _buildFareBreakdown(_Route route) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Fare per seat", style: TextStyle(color: Colors.black54)),
              Text("₹${route.pricePerSeat}", style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Total Seats", style: TextStyle(color: Colors.black54)),
              Text("x $seatsRequested", style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineRow({required IconData icon, required Color color, required String label, required String address, bool highlight = false, bool isSmall = false}) {
    return Row(
      children: [
        Icon(icon, color: color, size: isSmall ? 18 : 24),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: highlight ? FontWeight.bold : FontWeight.normal)),
              Text(address, style: TextStyle(fontWeight: highlight ? FontWeight.bold : FontWeight.w500, fontSize: highlight ? 15 : 13, color: highlight ? Colors.black : Colors.black87)),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildTimelineDivider() => const Padding(padding: EdgeInsets.only(left: 11), child: SizedBox(height: 15, child: VerticalDivider(width: 1, thickness: 1, color: Colors.black12)));

  Widget _buildLocationRow(IconData icon, Color color, String text) => Row(children: [Icon(icon, size: 10, color: color), const SizedBox(width: 8), Expanded(child: Text(text, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis))]);

  Widget _buildDriverCard(_Route route) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          CircleAvatar(radius: 25, backgroundColor: Colors.indigo.withOpacity(0.1), child: const Icon(Icons.person, color: Colors.indigo)),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(route.driverName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(route.vehicle?.model ?? "Standard Vehicle", style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(10)),
            child: Row(children: [const Icon(Icons.star, color: Colors.amber, size: 16), const SizedBox(width: 4), Text(route.driverRating.toString(), style: const TextStyle(fontWeight: FontWeight.bold))]),
          )
        ],
      ),
    );
  }

  Widget _buildBottomAction(double total, _Route route) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30)), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]),
      child: Row(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Total Fare", style: TextStyle(color: Colors.grey)),
              Text("₹${total.toInt()}", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.indigo)),
            ],
          ),
          const SizedBox(width: 30),
          Expanded(
            child: ElevatedButton(
              onPressed: () => widget.onRequestSeat?.call(route, seatsRequested),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
              child: Text("Request $seatsRequested Seats", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) => Padding(padding: const EdgeInsets.only(left: 4, bottom: 8), child: Text(title, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)));

  Widget _buildEmptyState() => const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.search_off, size: 80, color: Colors.grey), Text("No routes found", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey))]));
}

class _SeatBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _SeatBtn(this.icon, this.onTap);
  @override
  Widget build(BuildContext context) => InkWell(onTap: onTap, child: Container(padding: const EdgeInsets.all(5), decoration: BoxDecoration(border: Border.all(color: Colors.indigo), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: Colors.indigo, size: 20)));
}