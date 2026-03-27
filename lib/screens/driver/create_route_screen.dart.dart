import 'package:flutter/material.dart';

// Public class so it can be accessed by SavedRoutesScreen and AppRouter
class RouteTemplate {final String templateId;
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

  const CreateRouteScreen({
    super.key,
    this.editRoute,
  });

  @override
  State<CreateRouteScreen> createState() => _CreateRouteScreenState();
}

class _CreateRouteScreenState extends State<CreateRouteScreen> {
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

  static const daysOfWeek = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void initState() {
    super.initState();
    final edit = widget.editRoute;

    routeNameController = TextEditingController(text: edit?.name ?? '');
    originController = TextEditingController(text: edit?.origin ?? '');
    destinationController = TextEditingController(text: edit?.destination ?? '');
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
    super.dispose();
  }

  // Validation logic to enable/disable Save button
  bool get isValid {
    return originController.text.trim().isNotEmpty &&
        destinationController.text.trim().isNotEmpty &&
        selectedDays.isNotEmpty &&
        pricePerSeat > 0;
  }

  void save() {
    final edit = widget.editRoute;
    final template = RouteTemplate(
      templateId: edit?.templateId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      driverId: edit?.driverId ?? 'd1',
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

    // Returns the data to the previous screen (SavedRoutesScreen)
    Navigator.pop(context, template);
  }

  @override
  Widget build(BuildContext context) {
    final potentialEarnings = seats * pricePerSeat;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.editRoute == null ? 'Create Route' : 'Edit Route',
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: routeNameController,
              decoration: const InputDecoration(
                labelText: 'Route Name (Optional)',
                hintText: 'e.g., Daily Office Commute',
                border: OutlineInputBorder(),
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
                  TextField(
                    controller: originController,
                    onChanged: (v) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Pickup Point',
                      prefixIcon: Icon(Icons.circle, size: 12, color: Colors.green),
                      border: OutlineInputBorder(),
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
                          Expanded(child: Text("Stop ${i + 1}: ${stops[i]}")),
                          IconButton(
                            onPressed: () => setState(() => stops.removeAt(i)),
                            icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  ],

                  if (showStopInput) ...[
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: newStopController,
                            decoration: const InputDecoration(hintText: 'Enter stop location'),
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
                            }
                          },
                        ),
                      ],
                    )
                  ] else ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () => setState(() => showStopInput = true),
                        icon: const Icon(Icons.add_location_alt_outlined),
                        label: const Text('Add Stop'),
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),
                  TextField(
                    controller: destinationController,
                    onChanged: (v) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Drop-off Point',
                      prefixIcon: Icon(Icons.location_on, size: 16, color: Colors.red),
                      border: OutlineInputBorder(),
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
                    title: const Text('Round Trip', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('Include return journey'),
                    value: isRoundTrip,
                    onChanged: (v) => setState(() => isRoundTrip = v),
                    activeColor: Colors.indigo,
                  ),
                  const Divider(),
                  const Text('Repeat on', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: daysOfWeek.map((d) {
                      final isSelected = selectedDays.contains(d);
                      return ChoiceChip(
                        label: Text(d),
                        selected: isSelected,
                        selectedColor: Colors.indigo.withOpacity(0.2),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.indigo : Colors.black,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        onSelected: (selected) {
                          setState(() {
                            selected ? selectedDays.add(d) : selectedDays.remove(d);
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
                  const Text('Capacity & Pricing', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Seats', style: TextStyle(color: Colors.grey)),
                            Row(
                              children: [
                                IconButton(
                                  onPressed: () => setState(() => seats > 1 ? seats-- : null),
                                  icon: const Icon(Icons.remove_circle_outline),
                                ),
                                Text('$seats', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                IconButton(
                                  onPressed: () => setState(() => seats < 7 ? seats++ : null),
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
                          decoration: const InputDecoration(
                            labelText: 'Price / Seat (₹)',
                            border: OutlineInputBorder(),
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
                      color: Colors.indigo.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Potential Earnings:', style: TextStyle(color: Colors.indigo)),
                        Text('₹$potentialEarnings',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.indigo)),
                      ],
                    ),
                  )
                ],
              ),
            ),

            const SizedBox(height: 24),

            // SAVE BUTTON
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: isValid ? save : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: Text(
                  widget.editRoute == null ? 'Save Route Template' : 'Save Changes',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}