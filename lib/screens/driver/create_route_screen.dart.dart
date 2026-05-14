import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../system/localization/app_localizations.dart';
import '../../system/models/route_model.dart';
import '../../system/services/backend_api_service.dart';
import '../../system/services/maps_service.dart';
import '../../system/state/auth_controller.dart';

// Public class so it can be accessed by SavedRoutesScreen and AppRouter
class RouteTemplate {
  final String templateId;
  final String driverId;
  final String name;
  final String origin;
  final String destination;
  final List<String> stops;
  final String departureTime;
  final String? returnTime;
  final List<String> days;
  final int seats;
  final int pricePerSeat;
  final bool isActive;
  final bool isRoundTrip;

  const RouteTemplate({
    required this.templateId,
    required this.driverId,
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

class CreateRouteScreen extends StatefulWidget {
  final RouteTemplate? editRoute;
  final bool saveToBackend;

  const CreateRouteScreen({
    super.key,
    this.editRoute,
    this.saveToBackend = true,
  });

  @override
  State<CreateRouteScreen> createState() => _CreateRouteScreenState();
}

class _CreateRouteScreenState extends State<CreateRouteScreen> {
  final _authController = AuthController();
  final _apiService = BackendApiService();
  final _maps = const MapsService();

  late TextEditingController routeNameController;
  late TextEditingController originController;
  late TextEditingController destinationController;
  late TextEditingController newStopController;
  late TextEditingController priceController;

  late List<String> stops;
  late bool isRoundTrip;
  late String departureTime;
  late String returnTime;
  late List<String> selectedDays;
  late int seats;
  late int pricePerSeat;
  bool showStopInput = false;
  bool isSaving = false;
  bool isCheckingRoute = false;
  List<LatLng> _routePreviewPoints = const [];
  Set<Marker> _routeMarkers = const {};
  String? _routeDistance;
  String? _routeDuration;
  String? _routeMessage;
  GoogleMapController? _mapController;

  static const daysOfWeek = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void initState() {
    super.initState();
    final edit = widget.editRoute;

    routeNameController = TextEditingController(text: edit?.name ?? '');
    originController = TextEditingController(text: edit?.origin ?? '');
    destinationController = TextEditingController(
      text: edit?.destination ?? '',
    );
    newStopController = TextEditingController();

    stops = List.from(edit?.stops ?? []);
    isRoundTrip = edit?.isRoundTrip ?? false;
    departureTime = edit?.departureTime ?? '08:00';
    returnTime = edit?.returnTime ?? '18:00';
    selectedDays = List.from(edit?.days ?? ['Mon', 'Tue', 'Wed', 'Thu', 'Fri']);
    seats = edit?.seats ?? 3;
    pricePerSeat = edit?.pricePerSeat ?? 50;

    priceController = TextEditingController(text: pricePerSeat.toString());
  }

  @override
  void dispose() {
    routeNameController.dispose();
    originController.dispose();
    destinationController.dispose();
    newStopController.dispose();
    priceController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  // Validation logic to enable/disable Save button
  bool get isValid {
    return originController.text.trim().isNotEmpty &&
        destinationController.text.trim().isNotEmpty &&
        selectedDays.isNotEmpty &&
        pricePerSeat > 0;
  }

  Future<void> save() async {
    if (isSaving) {
      return;
    }

    final routeReady = await _validateAndPreviewRoute(
      applyOptimizedStops: true,
    );
    if (!routeReady || !mounted) {
      return;
    }

    final edit = widget.editRoute;
    final template = RouteTemplate(
      templateId:
          edit?.templateId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      driverId: edit?.driverId ?? '',
      name: routeNameController.text.trim().isNotEmpty
          ? routeNameController.text.trim()
          : '${originController.text.trim()} → ${destinationController.text.trim()}',
      origin: originController.text.trim(),
      destination: destinationController.text.trim(),
      stops: stops,
      departureTime: departureTime,
      returnTime: isRoundTrip ? returnTime : null,
      days: selectedDays,
      seats: seats,
      pricePerSeat: pricePerSeat,
      isActive: true,
      isRoundTrip: isRoundTrip,
    );

    if (!widget.saveToBackend) {
      Navigator.pop(context, template);
      return;
    }

    setState(() => isSaving = true);
    try {
      final user = await _authController.getCurrentUser();
      if (user == null) {
        throw Exception('Please sign in again.');
      }

      await _apiService.saveRoute(
        userId: user.id,
        route: RouteModel(
          id: template.templateId,
          userId: user.id,
          from: template.origin,
          to: template.destination,
          midpoints: template.stops,
        ),
      );

      if (!mounted) {
        return;
      }
      Navigator.pop(context, template);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }

  void _markRouteDirty() {
    setState(() {
      _routePreviewPoints = const [];
      _routeMarkers = const {};
      _routeDistance = null;
      _routeDuration = null;
      _routeMessage = null;
    });
  }

  Future<bool> _validateAndPreviewRoute({
    bool applyOptimizedStops = false,
  }) async {
    final origin = originController.text.trim();
    final destination = destinationController.text.trim();
    final cleanStops = stops
        .map((stop) => stop.trim())
        .where((stop) => stop.isNotEmpty)
        .toList();

    if (origin.isEmpty || destination.isEmpty) {
      _showRouteMessage('Start point and end point are required.');
      return false;
    }

    setState(() {
      isCheckingRoute = true;
      _routeMessage = null;
    });

    try {
      final plan = await _maps.getOptimizedRoutePlan(
        origin: origin,
        destination: destination,
        waypoints: cleanStops,
      );
      if (plan == null || plan.polyline.isEmpty) {
        _showRouteMessage(
          'No driving route found. Check the places and try again.',
        );
        return false;
      }

      final orderedStops = _optimizedStops(cleanStops, plan.waypointOrder);
      if (applyOptimizedStops && orderedStops.length == cleanStops.length) {
        stops = orderedStops;
      }
      final labels = [origin, ...orderedStops, destination];
      final locations = plan.routeLocations
          .map((point) => LatLng(point['lat']!, point['lng']!))
          .toList();

      final points = plan.polyline
          .map((point) => LatLng(point['lat']!, point['lng']!))
          .toList();

      if (!mounted) {
        return false;
      }
      setState(() {
        _routePreviewPoints = points;
        _routeDistance = plan.distanceText;
        _routeDuration = plan.durationText;
        _routeMarkers = _buildRouteMarkers(locations, labels);
        _routeMessage = cleanStops.isEmpty
            ? 'Route checked with Google Maps.'
            : 'Route checked and midpoints optimized.';
      });
      _fitMapToRoute(points);
      return true;
    } on MapsApiException catch (error) {
      _showRouteMessage(_friendlyDirectionsError(error));
      return false;
    } catch (error) {
      _showRouteMessage('Route check failed: $error');
      return false;
    } finally {
      if (mounted) {
        setState(() => isCheckingRoute = false);
      }
    }
  }

  String _friendlyDirectionsError(MapsApiException error) {
    final rawMessage = error.message?.toLowerCase() ?? '';
    if (error.status == 'NETWORK_ERROR') {
      return 'Cannot reach Google Maps. Check emulator internet/DNS and try again.';
    }
    if (error.status == 'NETWORK_TIMEOUT') {
      return 'Google Maps request timed out. Check connection and try again.';
    }
    if (error.status == 'REQUEST_DENIED' && rawMessage.contains('billing')) {
      return 'Directions API needs billing enabled for this Google API key.';
    }
    if (error.status == 'REQUEST_DENIED') {
      return 'Directions API denied this key. Enable Directions API and check key restrictions.';
    }
    if (error.status == 'ZERO_RESULTS') {
      return 'No driving route found between these places.';
    }
    if (error.status == 'NOT_FOUND') {
      return 'Google could not find one of the route places.';
    }
    return 'Directions error: ${error.toString()}';
  }

  List<String> _optimizedStops(List<String> currentStops, List<int> order) {
    if (order.length != currentStops.length) {
      return currentStops;
    }
    return order
        .where((index) => index >= 0 && index < currentStops.length)
        .map((index) => currentStops[index])
        .toList();
  }

  Set<Marker> _buildRouteMarkers(List<LatLng> locations, List<String> labels) {
    return {
      for (int i = 0; i < locations.length; i++)
        Marker(
          markerId: MarkerId('route-point-$i'),
          position: locations[i],
          infoWindow: InfoWindow(
            title: i == 0
                ? 'Start'
                : i == locations.length - 1
                ? 'End'
                : 'Midpoint $i',
            snippet: labels[i],
          ),
        ),
    };
  }

  Future<void> _fitMapToRoute(List<LatLng> points) async {
    final controller = _mapController;
    if (controller == null || points.isEmpty) {
      return;
    }

    var minLat = points.first.latitude;
    var maxLat = points.first.latitude;
    var minLng = points.first.longitude;
    var maxLng = points.first.longitude;
    for (final point in points.skip(1)) {
      minLat = point.latitude < minLat ? point.latitude : minLat;
      maxLat = point.latitude > maxLat ? point.latitude : maxLat;
      minLng = point.longitude < minLng ? point.longitude : minLng;
      maxLng = point.longitude > maxLng ? point.longitude : maxLng;
    }

    await controller.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        48,
      ),
    );
  }

  void _showRouteMessage(String message) {
    if (!mounted) {
      return;
    }
    setState(() => _routeMessage = message);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final potentialEarnings = seats * pricePerSeat;
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.editRoute == null
              ? l10n.text('createRoute')
              : l10n.text('editRoute'),
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          children: [
            _buildRoutePreviewCard(),
            const SizedBox(height: 16),
            TextField(
              controller: routeNameController,
              decoration: InputDecoration(
                labelText: l10n.text('routeNameOptional'),
                hintText: l10n.text('routeNameHint'),
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),

            // Pickup and Dropoff Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  _GooglePlaceField(
                    controller: originController,
                    maps: _maps,
                    onChanged: (_) => _markRouteDirty(),
                    decoration: InputDecoration(
                      labelText: l10n.text('startPoint'),
                      prefixIcon: Icon(
                        Icons.circle,
                        size: 12,
                        color: Colors.green,
                      ),
                      hintText: l10n.text('startPointHint'),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Display added stops
                  for (int i = 0; i < stops.length; i++) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        children: [
                          const Icon(Icons.more_vert, color: Colors.grey),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "${l10n.text('addStop')} ${i + 1}: ${stops[i]}",
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              setState(() => stops.removeAt(i));
                              _markRouteDirty();
                            },
                            icon: const Icon(
                              Icons.remove_circle_outline,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  if (showStopInput) ...[
                    Row(
                      children: [
                        Expanded(
                          child: _GooglePlaceField(
                            controller: newStopController,
                            maps: _maps,
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              hintText: l10n.text('enterStopLocation'),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.check, color: Colors.green),
                          onPressed: () {
                            if (newStopController.text.trim().isNotEmpty) {
                              setState(() {
                                stops.add(newStopController.text.trim());
                                newStopController.clear();
                                showStopInput = false;
                              });
                              _markRouteDirty();
                            }
                          },
                        ),
                      ],
                    ),
                  ] else ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () => setState(() => showStopInput = true),
                        icon: const Icon(Icons.add_location_alt_outlined),
                        label: Text(l10n.text('addStop')),
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),
                  _GooglePlaceField(
                    controller: destinationController,
                    maps: _maps,
                    onChanged: (_) => _markRouteDirty(),
                    decoration: InputDecoration(
                      labelText: l10n.text('dropOffPoint'),
                      prefixIcon: Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.red,
                      ),
                      hintText: l10n.text('dropOffHint'),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Schedule Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      l10n.text('roundTrip'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(l10n.text('includeReturnJourney')),
                    value: isRoundTrip,
                    onChanged: (v) => setState(() => isRoundTrip = v),
                    activeThumbColor: Colors.indigo,
                  ),
                  const Divider(),
                  Text(
                    l10n.text('repeatOn'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: daysOfWeek.map((d) {
                      final isSelected = selectedDays.contains(d);
                      return ChoiceChip(
                        label: Text(d),
                        selected: isSelected,
                        selectedColor: Colors.indigo.withValues(alpha: 0.2),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.indigo : Colors.black,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                        onSelected: (selected) {
                          setState(() {
                            selected
                                ? selectedDays.add(d)
                                : selectedDays.remove(d);
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Capacity & Pricing Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.text('capacityPricing'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.text('seats'),
                              style: const TextStyle(color: Colors.grey),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  onPressed: () => setState(
                                    () => seats > 1 ? seats-- : null,
                                  ),
                                  icon: const Icon(Icons.remove_circle_outline),
                                ),
                                Text(
                                  '$seats',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => setState(
                                    () => seats < 7 ? seats++ : null,
                                  ),
                                  icon: const Icon(Icons.add_circle_outline),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: priceController,
                          keyboardType: TextInputType.number,
                          onChanged: (v) => setState(() {
                            pricePerSeat = int.tryParse(v) ?? 0;
                          }),
                          decoration: InputDecoration(
                            labelText: '${l10n.text('pricePerSeat')} (₮)',
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.indigo.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${l10n.text('potentialEarnings')}:',
                          style: const TextStyle(color: Colors.indigo),
                        ),
                        Text(
                          '₮$potentialEarnings',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.indigo,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // SAVE BUTTON
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: isValid && !isSaving ? save : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        widget.editRoute == null
                            ? l10n.text('saveRouteTemplate')
                            : l10n.text('saveChanges'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildRoutePreviewCard() {
    final hasRoute = _routePreviewPoints.isNotEmpty;
    final origin = originController.text.trim();
    final destination = destinationController.text.trim();
    final routeTitle = origin.isEmpty && destination.isEmpty
        ? 'Search route places'
        : [
            if (origin.isNotEmpty) origin,
            if (destination.isNotEmpty) destination,
          ].join(' -> ');
    final polylines = hasRoute
        ? {
            Polyline(
              polylineId: const PolylineId('optimized-route-preview'),
              points: _routePreviewPoints,
              color: const Color(0xFF2563EB),
              width: 6,
            ),
          }
        : <Polyline>{};

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        height: 520,
        child: Stack(
          children: [
            Positioned.fill(
              child: GoogleMap(
                initialCameraPosition: const CameraPosition(
                  target: LatLng(47.9189, 106.9176),
                  zoom: 13,
                ),
                onMapCreated: (controller) {
                  _mapController = controller;
                  if (_routePreviewPoints.isNotEmpty) {
                    _fitMapToRoute(_routePreviewPoints);
                  }
                },
                markers: _routeMarkers,
                polylines: polylines,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
              ),
            ),
            Positioned(
              left: 14,
              right: 14,
              top: 14,
              child: _MapSearchPill(
                title: routeTitle,
                subtitle: stops.isEmpty
                    ? 'Start point, midpoint, end point'
                    : '${stops.length} midpoint${stops.length == 1 ? '' : 's'} selected',
                isChecking: isCheckingRoute,
                onPreview: isCheckingRoute
                    ? null
                    : () => _validateAndPreviewRoute(),
              ),
            ),
            Positioned(
              right: 14,
              top: 104,
              child: Column(
                children: [
                  _MapRoundButton(
                    icon: Icons.near_me_rounded,
                    onPressed: _routePreviewPoints.isEmpty
                        ? null
                        : () => _fitMapToRoute(_routePreviewPoints),
                  ),
                  const SizedBox(height: 10),
                  _MapRoundButton(icon: Icons.layers_rounded, onPressed: () {}),
                ],
              ),
            ),
            Positioned(
              left: 14,
              right: 14,
              bottom: 14,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.14),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _RouteMetric(
                          icon: Icons.social_distance_rounded,
                          label: 'Distance',
                          value: _routeDistance ?? '--',
                        ),
                        const SizedBox(width: 10),
                        _RouteMetric(
                          icon: Icons.schedule_rounded,
                          label: 'Duration',
                          value: _routeDuration ?? '--',
                        ),
                      ],
                    ),
                    if (_routeMessage != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        _routeMessage!,
                        style: TextStyle(
                          color: hasRoute
                              ? const Color(0xFF0F766E)
                              : Colors.redAccent,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapSearchPill extends StatelessWidget {
  const _MapSearchPill({
    required this.title,
    required this.subtitle,
    required this.isChecking,
    required this.onPreview,
  });

  final String title;
  final String subtitle;
  final bool isChecking;
  final VoidCallback? onPreview;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on_rounded, color: Color(0xFF2563EB)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: onPreview,
            icon: isChecking
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.route_rounded, size: 18),
            label: Text(isChecking ? 'Checking' : 'Preview'),
          ),
        ],
      ),
    );
  }
}

class _MapRoundButton extends StatelessWidget {
  const _MapRoundButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 4,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: const Color(0xFF0F172A)),
      ),
    );
  }
}

class _RouteMetric extends StatelessWidget {
  const _RouteMetric({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF14B8A6), size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900),
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

class _GooglePlaceField extends StatefulWidget {
  const _GooglePlaceField({
    required this.controller,
    required this.maps,
    required this.decoration,
    required this.onChanged,
  });

  final TextEditingController controller;
  final MapsService maps;
  final InputDecoration decoration;
  final ValueChanged<String> onChanged;

  @override
  State<_GooglePlaceField> createState() => _GooglePlaceFieldState();
}

class _GooglePlaceFieldState extends State<_GooglePlaceField> {
  Timer? _debounce;
  List<GooglePlaceSuggestion> _suggestions = const [];
  bool _isSearching = false;
  bool _skipNextSearch = false;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onTextChanged(String value) {
    widget.onChanged(value);
    if (_skipNextSearch) {
      _skipNextSearch = false;
      return;
    }

    _debounce?.cancel();
    final query = value.trim();
    if (query.length < 2) {
      setState(() {
        _suggestions = const [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      final List<GooglePlaceSuggestion> results;
      try {
        results = await widget.maps.searchPlaces(query);
      } catch (_) {
        if (mounted) {
          setState(() {
            _suggestions = const [];
            _isSearching = false;
          });
        }
        return;
      }
      if (!mounted || widget.controller.text.trim() != query) {
        return;
      }
      setState(() {
        _suggestions = results.take(5).toList();
        _isSearching = false;
      });
    });
  }

  void _selectSuggestion(GooglePlaceSuggestion suggestion) {
    _debounce?.cancel();
    _skipNextSearch = true;
    widget.controller.text = suggestion.description;
    widget.controller.selection = TextSelection.collapsed(
      offset: widget.controller.text.length,
    );
    widget.onChanged(suggestion.description);
    setState(() {
      _suggestions = const [];
      _isSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final suffix = _isSearching
        ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : widget.decoration.suffixIcon;

    return Column(
      children: [
        TextField(
          controller: widget.controller,
          onChanged: _onTextChanged,
          decoration: widget.decoration.copyWith(suffixIcon: suffix),
        ),
        if (_suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade200),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _suggestions.length,
              separatorBuilder: (_, _) =>
                  Divider(height: 1, thickness: 1, color: Colors.grey.shade100),
              itemBuilder: (context, index) {
                final suggestion = _suggestions[index];
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.place_outlined, size: 20),
                  title: Text(
                    suggestion.mainText ?? suggestion.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: suggestion.secondaryText == null
                      ? null
                      : Text(
                          suggestion.secondaryText!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                  onTap: () => _selectSuggestion(suggestion),
                );
              },
            ),
          ),
      ],
    );
  }
}
