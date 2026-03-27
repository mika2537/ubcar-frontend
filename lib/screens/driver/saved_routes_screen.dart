import 'package:flutter/material.dart';
import '../../system/routing/app_routes.dart';

// Internal Model for Route Templates
class _RouteTemplate {
  final String templateId;
  final String name;
  final String origin;
  final String destination;
  final List<String> stops;
  final String departureTime;
  final String? returnTime;
  final List<String> days;
  final int seats;
  final int pricePerSeat;
  bool isActive;
  final bool isRoundTrip;

  _RouteTemplate({
    required this.templateId,
    required this.name,
    required this.origin,
    required this.destination,
    required this.stops,
    required this.departureTime,
    this.returnTime,
    required this.days,
    required this.seats,
    required this.pricePerSeat,
    required this.isActive,
    required this.isRoundTrip,
  });
}

class SavedRoutesScreen extends StatefulWidget {
  const SavedRoutesScreen({super.key});

  @override
  State<SavedRoutesScreen> createState() => _SavedRoutesScreenState();
}

class _SavedRoutesScreenState extends State<SavedRoutesScreen> {
  late List<_RouteTemplate> routes;

  @override
  void initState() {
    super.initState();
    routes = [
      _RouteTemplate(
        templateId: '1',
        name: 'Daily Office Commute',
        origin: 'Salt Lake Sector V',
        destination: 'Park Street',
        stops: ['Karunamoyee', 'Rabindra Sadan'],
        departureTime: '08:30',
        returnTime: '18:00',
        days: const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
        seats: 3,
        pricePerSeat: 60,
        isActive: true,
        isRoundTrip: true,
      ),
    ];
  }

  void toggleRouteActive(String id) {
    setState(() {
      final index = routes.indexWhere((r) => r.templateId == id);
      if (index != -1) {
        routes[index].isActive = !routes[index].isActive;
      }
    });
  }

  void deleteRoute(String id) {
    setState(() => routes.removeWhere((r) => r.templateId == id));
  }

  // Navigation logic for the Publish button
  void publishRoute(_RouteTemplate route) {
    Navigator.pushNamed(
      context,
      AppRoutes.liveTracking,
      arguments: {
        'pickup': route.origin,
        'destination': route.destination,
        'rideStatus': 'active', // or 'pending'
      },
    );
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
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('My Route Templates',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.createDriverRoute),
            icon: const Icon(Icons.add, color: Colors.indigo),
          ),
        ],
      ),
      body: routes.isEmpty ? _buildEmptyState() : _buildRouteList(),
      floatingActionButton: routes.isNotEmpty
          ? FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.createDriverRoute),
        label: const Text('Create New Route'),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.indigo,
      )
          : null,
    );
  }

  Widget _buildRouteList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: routes.length,
      itemBuilder: (context, index) {
        final route = routes[index];
        return _RouteCard(
          route: route,
          onToggleActive: () => toggleRouteActive(route.templateId),
          onDelete: () => deleteRoute(route.templateId),
          onEdit: () {
            // Edit logic here
          },
          onPublish: () => publishRoute(route), // NEW
          onTap: () {
            // View Detail logic here
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.alt_route_rounded, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('No Saved Routes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 8),
          const Text('Create templates for routes you drive often',
              style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.createDriverRoute),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
            child: const Text('Create Your First Route'),
          )
        ],
      ),
    );
  }
}

class _RouteCard extends StatelessWidget {
  final _RouteTemplate route;
  final VoidCallback onToggleActive;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final VoidCallback onPublish; // Added
  final VoidCallback onTap;

  const _RouteCard({
    required this.route,
    required this.onToggleActive,
    required this.onDelete,
    required this.onEdit,
    required this.onPublish, // Added
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: route.isActive ? Colors.indigo.withOpacity(0.3) : Colors.transparent,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(route.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  PopupMenuButton<String>(
                    onSelected: (val) {
                      if (val == 'active') onToggleActive();
                      if (val == 'delete') onDelete();
                      if (val == 'edit') onEdit();
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(value: 'active', child: Text(route.isActive ? 'Deactivate' : 'Activate')),
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                    ],
                  ),
                ],
              ),
              const Divider(),
              _buildLocationRow(Icons.circle, Colors.green, route.origin),
              const Padding(
                padding: EdgeInsets.only(left: 7),
                child: SizedBox(height: 10, child: VerticalDivider(width: 1)),
              ),
              _buildLocationRow(Icons.location_on, Colors.red, route.destination),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.people_outline, size: 18, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text('${route.seats} Seats', style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                  // PUBLISH BUTTON
                  ElevatedButton.icon(
                    onPressed: onPublish,
                    icon: const Icon(Icons.rocket_launch, size: 16),
                    label: const Text('Publish'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationRow(IconData icon, Color color, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
      ],
    );
  }
}