import 'package:flutter/material.dart';

class RideOptionsScreen extends StatefulWidget {
  final String pickup;
  final String destination;
  final VoidCallback? onBack;
  final void Function(_RideOption option)? onConfirm;

  const RideOptionsScreen({
    super.key,
    this.pickup = 'Salt Lake Sector V',
    this.destination = 'Park Street Metro Station',
    this.onBack,
    this.onConfirm,
  });

  @override
  State<RideOptionsScreen> createState() => _RideOptionsScreenState();
}

class _RideOption {
  final String id;
  final String name;
  final String description;
  final String price;
  final String time;
  final String icon;
  final String? discount;
  final bool isEco;

  const _RideOption({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.time,
    required this.icon,
    this.discount,
    this.isEco = false,
  });
}

class _RideOptionsScreenState extends State<RideOptionsScreen> {
  static const rideOptions = <_RideOption>[
    _RideOption(
      id: 'carpool',
      name: 'RidePool',
      description: 'Share with others, save money',
      price: '₹85',
      time: '18-25 min',
      icon: 'carpool',
      discount: '40% off',
      isEco: true,
    ),
    _RideOption(
      id: 'standard',
      name: 'Standard',
      description: 'Affordable everyday rides',
      price: '₹145',
      time: '12-18 min',
      icon: 'private',
    ),
    _RideOption(
      id: 'premium',
      name: 'Premium',
      description: 'Extra comfort for special trips',
      price: '₹220',
      time: '10-15 min',
      icon: 'private',
    ),
  ];

  String selectedOptionId = 'carpool';

  _RideOption get selected =>
      rideOptions.firstWhere((o) => o.id == selectedOptionId);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 220,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Container(
                      color: Colors.grey.shade300,
                      child: const Center(child: Text('Map preview')),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: IconButton(
                      onPressed: widget.onBack,
                      icon: const Icon(Icons.arrow_back),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.85),
                        shape: const CircleBorder(),
                      ),
                    ),
                  ),
                  // Simulated route line
                  const Positioned.fill(
                    child: Center(child: Icon(Icons.alt_route, size: 90, color: Colors.indigo)),
                  ),
                ],
              ),
            ),

            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  Column(
                    children: const [
                      Icon(Icons.circle, size: 10, color: Colors.indigo),
                      SizedBox(height: 10),
                      SizedBox(
                        height: 18,
                        child: VerticalDivider(width: 8, thickness: 2, color: Colors.indigo),
                      ),
                      SizedBox(height: 10),
                      Icon(Icons.circle, size: 10, color: Colors.indigoAccent),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.pickup, style: const TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        Text(widget.destination, style: const TextStyle(fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text('Edit', style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.w700)),
                  )
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 96),
                children: [
                  const Text(
                    'Choose a ride',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 14),
                  ...rideOptions.map((option) {
                    final selected = option.id == selectedOptionId;
                    return InkWell(
                      onTap: () => setState(() => selectedOptionId = option.id),
                      borderRadius: BorderRadius.circular(22),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          color: selected ? Colors.indigo.withOpacity(0.06) : Colors.white,
                          border: Border.all(
                            color: selected ? Colors.indigo.withOpacity(0.45) : Colors.grey.shade200,
                            width: selected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: option.id == 'carpool'
                                    ? Colors.indigo.withOpacity(0.10)
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Icon(
                                option.id == 'carpool'
                                    ? Icons.people
                                    : Icons.directions_car,
                                color: option.id == 'carpool' ? Colors.indigo : Colors.black54,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        option.name,
                                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                                      ),
                                      const SizedBox(width: 10),
                                      if (option.discount != null)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.indigo.withOpacity(0.12),
                                            borderRadius: BorderRadius.circular(999),
                                          ),
                                          child: Text(
                                            option.discount!,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w900,
                                              color: Colors.indigo,
                                            ),
                                          ),
                                        ),
                                      if (option.isEco) const SizedBox(width: 6),
                                      if (option.isEco) const Text('🌿'),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    option.description,
                                    style: const TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      const Icon(Icons.access_time, size: 14, color: Colors.black54),
                                      const SizedBox(width: 6),
                                      Text(
                                        option.time,
                                        style: const TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.w700),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  option.price,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                if (option.discount != null)
                                  const Text(
                                    '₹140',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.black54,
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                              ],
                            )
                          ],
                        ),
                      ),
                    );
                  }).toList(),

                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.shield, color: Colors.green, size: 22),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'All rides include safety features and insurance',
                            style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Bottom action
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.98),
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Estimated fare', style: TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 6),
                            Text(selected.price, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.black)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('ETA', style: TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 6),
                          Text(selected.time, style: const TextStyle(fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => widget.onConfirm?.call(selected),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text('Confirm ${selected.name}', style: const TextStyle(fontWeight: FontWeight.w900)),
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
