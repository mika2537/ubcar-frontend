import 'package:flutter/material.dart';

class SearchLocationScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final void Function(String pickup, String destination)? onSelectLocation;

  const SearchLocationScreen({
    super.key,
    this.onBack,
    this.onSelectLocation,
  });

  @override
  State<SearchLocationScreen> createState() => _SearchLocationScreenState();
}

enum _FocusedField { pickup, destination }

class _SearchLocationScreenState extends State<SearchLocationScreen> {
  final pickupController = TextEditingController();
  final destinationController = TextEditingController();

  _FocusedField focused = _FocusedField.pickup;

  @override
  void dispose() {
    pickupController.dispose();
    destinationController.dispose();
    super.dispose();
  }

  final savedLocations = const [
    {'name': 'Home', 'address': '45 Park Street, Kolkata'},
    {'name': 'Office', 'address': 'Salt Lake Sector V, Block A'},
  ];

  final recentSearches = const [
    {'name': 'The Royal Sweets Howrah Station', 'address': 'Near Howrah Station'},
    {'name': 'Add Risheswar Rd', 'address': 'Rishra, West Bengal'},
    {'name': 'HGM Residency Rd', 'address': 'Salt Lake, Kolkata'},
  ];

  void handleLocationSelect(String location) {
    if (focused == _FocusedField.pickup) {
      setState(() {
        pickupController.text = location;
        focused = _FocusedField.destination;
      });
    } else {
      setState(() {
        destinationController.text = location;
      });
    }
  }

  bool get canContinue {
    return pickupController.text.trim().isNotEmpty &&
        destinationController.text.trim().isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final pickup = pickupController.text.trim();
    final destination = destinationController.text.trim();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: widget.onBack,
                        icon: const Icon(Icons.arrow_back),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.grey.shade200,
                          shape: const CircleBorder(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Plan your trip',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Timeline-ish input
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.indigo,
                            ),
                          ),
                          Container(
                            width: 3,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade400,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.indigo.withOpacity(0.15),
                              border: Border.all(color: Colors.indigo.withOpacity(0.35), width: 2),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          children: [
                            _LocationInput(
                              controller: pickupController,
                              label: 'Pickup location',
                              placeholder: 'Pickup location',
                              isFocused: focused == _FocusedField.pickup,
                              onFocus: () => setState(() => focused = _FocusedField.pickup),
                              onClear: () => setState(() => pickupController.clear()),
                            ),
                            const SizedBox(height: 10),
                            _LocationInput(
                              controller: destinationController,
                              label: 'Where to?',
                              placeholder: 'Where to?',
                              isFocused: focused == _FocusedField.destination,
                              onFocus: () => setState(() => focused = _FocusedField.destination),
                              onClear: () => setState(() => destinationController.clear()),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                children: [
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => handleLocationSelect('Current Location'),
                    icon: const Icon(Icons.navigation_outlined),
                    label: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Use current location', style: TextStyle(fontWeight: FontWeight.w700)),
                          SizedBox(height: 2),
                          Text(
                            'Based on your GPS',
                            style: TextStyle(color: Colors.black54, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade100,
                      foregroundColor: Colors.black87,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                      alignment: Alignment.centerLeft,
                    ),
                  ),

                  const SizedBox(height: 20),
                  Text(
                    'Saved Places',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                          color: Colors.black54,
                        ),
                  ),
                  const SizedBox(height: 10),
                  ...savedLocations.map((loc) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        tileColor: Colors.grey.shade100,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        leading: CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.grey.shade200,
                          child: Text(loc['name']!.substring(0, 1), style: const TextStyle(fontWeight: FontWeight.w900)),
                        ),
                        title: Text(loc['name']!, style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text(loc['address']!, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => handleLocationSelect(loc['address']!),
                      ),
                    );
                  }).toList(),

                  const SizedBox(height: 18),
                  Text(
                    'Recent',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                          color: Colors.black54,
                        ),
                  ),
                  const SizedBox(height: 10),
                  ...recentSearches.map((loc) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        tileColor: Colors.grey.shade100,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        leading: const CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.grey,
                          child: Icon(Icons.access_time, size: 18, color: Colors.white),
                        ),
                        title: Text(loc['name']!, style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text(loc['address']!, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => handleLocationSelect(loc['name']!),
                      ),
                    );
                  }).toList(),

                  const SizedBox(height: 24),
                ],
              ),
            ),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              width: double.infinity,
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: canContinue
                      ? () => widget.onSelectLocation?.call(pickup, destination)
                      : null,
                  child: const Text('Confirm & Request'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String placeholder;
  final bool isFocused;
  final VoidCallback onFocus;
  final VoidCallback onClear;

  const _LocationInput({
    required this.controller,
    required this.label,
    required this.placeholder,
    required this.isFocused,
    required this.onFocus,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onTap: onFocus,
      decoration: InputDecoration(
        labelText: label,
        hintText: placeholder,
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isFocused ? Colors.indigo : Colors.transparent,
            width: isFocused ? 2 : 1,
          ),
        ),
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
                onPressed: onClear,
                icon: const Icon(Icons.close),
              )
            : null,
      ),
      textInputAction: TextInputAction.next,
    );
  }
}
