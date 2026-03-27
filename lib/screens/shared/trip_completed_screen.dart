import 'package:flutter/material.dart';

enum _PaymentMethod { wallet, card, cash }

class TripCompletedScreen extends StatefulWidget {
  final String driverName;
  final double fare;
  final String tripDistance;
  final String tripDuration;
  final int seatsUsed;

  final void Function(int rating, String? feedback)? onSubmitRating;
  final void Function(_PaymentMethod method)? onMakePayment;
  final VoidCallback? onClose;

  const TripCompletedScreen({
    super.key,
    this.driverName = 'Rakesh Kumar',
    this.fare = 85,
    this.tripDistance = '4.2 km',
    this.tripDuration = '18 min',
    this.seatsUsed = 1,
    this.onSubmitRating,
    this.onMakePayment,
    this.onClose,
  });

  @override
  State<TripCompletedScreen> createState() => _TripCompletedScreenState();
}

class _TripCompletedScreenState extends State<TripCompletedScreen> {
  int rating = 5;
  final selectedFeedback = <int>[];
  int? tip;
  _PaymentMethod selectedPayment = _PaymentMethod.wallet;
  bool isPaid = false;

  @override
  Widget build(BuildContext context) {
    final totalWithTip = widget.fare + (tip ?? 0);
    final driverInitial = widget.driverName.isNotEmpty ? widget.driverName[0] : '?';

    final quickFeedback = [
      {'id': 1, 'label': 'Great conversation', 'icon': Icons.message},
      {'id': 2, 'label': 'Smooth driving', 'icon': Icons.thumb_up},
      {'id': 3, 'label': 'Clean car', 'icon': Icons.star},
    ];

    const tipOptions = [10, 20, 50];

    final paymentMethods = <_PaymentMethod, String>{
      _PaymentMethod.wallet: 'Wallet',
      _PaymentMethod.card: 'Card',
      _PaymentMethod.cash: 'Cash',
    };

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 26, 16, 22),
              decoration: BoxDecoration(
                color: Colors.indigo,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(26)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.25),
                    ),
                    child: const Center(
                      child: Icon(Icons.check_circle, color: Colors.white, size: 34),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Trip Completed!',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Thanks for riding with RidePool',
                    style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                children: [
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
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Total fare (${widget.seatsUsed} ${widget.seatsUsed > 1 ? 'seats' : 'seat'})',
                                    style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w700, fontSize: 12),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '₹${widget.fare.toStringAsFixed(0)}',
                                    style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(widget.tripDistance, style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w700, fontSize: 12)),
                                const SizedBox(height: 6),
                                Text(widget.tripDuration, style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.w800, fontSize: 12)),
                              ],
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: Colors.grey.shade200,
                              child: Text(driverInitial, style: const TextStyle(fontWeight: FontWeight.w900)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(widget.driverName, style: const TextStyle(fontWeight: FontWeight.w900)),
                                  const SizedBox(height: 6),
                                  const Text('Your driver', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w700, fontSize: 12)),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () {},
                              icon: const Icon(Icons.share),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  if (!isPaid) ...[
                    const Text('Pay with', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _PaymentCard(
                            label: 'Wallet',
                            icon: Icons.account_balance_wallet,
                            selected: selectedPayment == _PaymentMethod.wallet,
                            onTap: () => setState(() => selectedPayment = _PaymentMethod.wallet),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _PaymentCard(
                            label: 'Card',
                            icon: Icons.credit_card,
                            selected: selectedPayment == _PaymentMethod.card,
                            onTap: () => setState(() => selectedPayment = _PaymentMethod.card),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _PaymentCard(
                      label: 'Cash',
                      icon: Icons.money,
                      selected: selectedPayment == _PaymentMethod.cash,
                      onTap: () => setState(() => selectedPayment = _PaymentMethod.cash),
                    ),

                    const SizedBox(height: 14),
                    ElevatedButton(
                      onPressed: () {
                        setState(() => isPaid = true);
                        widget.onMakePayment?.call(selectedPayment);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      ),
                      child: Text(
                        'Pay ₹${totalWithTip.toStringAsFixed(0)}',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                      ),
                    ),
                  ],

                  if (isPaid) ...[
                    const SizedBox(height: 6),
                    const Text('Rate your ride', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (i) {
                        final star = i + 1;
                        final selected = star <= rating;
                        return IconButton(
                          onPressed: () => setState(() => rating = star),
                          icon: Icon(
                            selected ? Icons.star : Icons.star_border,
                            color: selected ? Colors.indigo : Colors.black38,
                            size: 34,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 18),
                    const Text('What went well?', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                    const SizedBox(height: 12),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 10,
                      runSpacing: 10,
                      children: quickFeedback.map((f) {
                        final id = f['id'] as int;
                        final selected = selectedFeedback.contains(id);
                        return ChoiceChip(
                          label: Text(f['label'] as String),
                          selected: selected,
                          selectedColor: Colors.indigo.withOpacity(0.12),
                          onSelected: (_) => setState(() {
                            if (selected) {
                              selectedFeedback.remove(id);
                            } else {
                              selectedFeedback.add(id);
                            }
                          }),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),
                    const Text('Add a tip?', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: tipOptions.map((amount) {
                        final selected = tip == amount;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: ChoiceChip(
                            label: Text('₹$amount'),
                            selected: selected,
                            onSelected: (_) => setState(() => tip = selected ? null : amount),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          final feedbackText = selectedFeedback.isEmpty
                              ? null
                              : selectedFeedback.join(',');
                          widget.onSubmitRating?.call(rating, feedbackText);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        ),
                        child: const Text('Done', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _PaymentCard({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? Colors.indigo.withOpacity(0.08) : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? Colors.indigo.withOpacity(0.45) : Colors.grey.shade200,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? Colors.indigo : Colors.black54),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: selected ? Colors.indigo : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
