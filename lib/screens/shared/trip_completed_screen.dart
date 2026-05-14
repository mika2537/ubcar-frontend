import 'package:flutter/material.dart';

enum PaymentMethod { wallet, card, cash }

class TripCompletedScreen extends StatefulWidget {
  final String driverName;
  final double fare;
  final String tripDistance;
  final String tripDuration;
  final int seatsUsed;

  final void Function(int rating, String? feedback)? onSubmitRating;
  final void Function(PaymentMethod method)? onMakePayment;
  final VoidCallback? onClose;

  const TripCompletedScreen({
    super.key,
    this.driverName = '',
    this.fare = 0,
    this.tripDistance = '',
    this.tripDuration = '',
    this.seatsUsed = 1,
    this.onSubmitRating,
    this.onMakePayment,
    this.onClose,
  });

  @override
  State<TripCompletedScreen> createState() => _TripCompletedScreenState();
}

class _TripCompletedScreenState extends State<TripCompletedScreen> {
  static const _primary = Color(0xFF2563EB);
  static const _accent = Color(0xFF14B8A6);
  static const _ink = Color(0xFF0F172A);
  static const _muted = Color(0xFF64748B);
  static const _line = Color(0xFFE2E8F0);
  static const _surface = Colors.white;
  static const _background = Color(0xFFF8FAFC);

  int rating = 5;
  final selectedFeedback = <int>[];
  int? tip;
  PaymentMethod selectedPayment = PaymentMethod.wallet;
  bool isPaid = false;

  void _handleDone() {
    final feedbackText = selectedFeedback.isEmpty
        ? null
        : selectedFeedback.join(',');
    widget.onSubmitRating?.call(rating, feedbackText);
    widget.onClose?.call();
  }

  @override
  Widget build(BuildContext context) {
    final totalWithTip = widget.fare + (tip ?? 0);
    final driverInitial = widget.driverName.isNotEmpty
        ? widget.driverName[0]
        : '?';

    final quickFeedback = [
      {'id': 1, 'label': 'Great conversation', 'icon': Icons.message},
      {'id': 2, 'label': 'Smooth driving', 'icon': Icons.thumb_up},
      {'id': 3, 'label': 'Clean car', 'icon': Icons.star},
    ];

    const tipOptions = [10, 20, 50];

    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 26, 20, 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [_primary, _accent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(18),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.18),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.36),
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.check_circle,
                        color: Colors.white,
                        size: 34,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Trip completed',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Thanks for riding with RidePool',
                    style: TextStyle(
                      color: Color(0xFFEFF6FF),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: _surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _line),
                      boxShadow: [
                        BoxShadow(
                          color: _ink.withValues(alpha: 0.06),
                          blurRadius: 18,
                          offset: const Offset(0, 10),
                        ),
                      ],
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
                                    style: const TextStyle(
                                      color: _muted,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '₹${widget.fare.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      color: _ink,
                                      fontSize: 32,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  widget.tripDistance,
                                  style: const TextStyle(
                                    color: _muted,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  widget.tripDuration,
                                  style: const TextStyle(
                                    color: _primary,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const Divider(height: 24, color: _line),
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: const Color(0xFFEFF6FF),
                              child: Text(
                                driverInitial,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: _primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.driverName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      color: _ink,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    'Your driver',
                                    style: TextStyle(
                                      color: _muted,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () {},
                              style: IconButton.styleFrom(
                                backgroundColor: const Color(0xFFF1F5F9),
                                foregroundColor: _primary,
                              ),
                              icon: const Icon(Icons.ios_share_rounded),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  if (!isPaid) ...[
                    const Text(
                      'Pay with',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _ink,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _PaymentCard(
                            label: 'Wallet',
                            icon: Icons.account_balance_wallet,
                            selected: selectedPayment == PaymentMethod.wallet,
                            onTap: () => setState(
                              () => selectedPayment = PaymentMethod.wallet,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _PaymentCard(
                            label: 'Card',
                            icon: Icons.credit_card,
                            selected: selectedPayment == PaymentMethod.card,
                            onTap: () => setState(
                              () => selectedPayment = PaymentMethod.card,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _PaymentCard(
                      label: 'Cash',
                      icon: Icons.money,
                      selected: selectedPayment == PaymentMethod.cash,
                      onTap: () =>
                          setState(() => selectedPayment = PaymentMethod.cash),
                    ),

                    const SizedBox(height: 14),
                    ElevatedButton(
                      onPressed: () {
                        setState(() => isPaid = true);
                        widget.onMakePayment?.call(selectedPayment);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.lock_rounded, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Pay ₹${totalWithTip.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  if (isPaid) ...[
                    const SizedBox(height: 6),
                    const Text(
                      'Rate your ride',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _ink,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
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
                            color: selected ? const Color(0xFFF59E0B) : _line,
                            size: 34,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'What went well?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _ink,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
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
                          selectedColor: _accent.withValues(alpha: 0.14),
                          backgroundColor: const Color(0xFFF1F5F9),
                          labelStyle: TextStyle(
                            color: selected ? const Color(0xFF0F766E) : _ink,
                            fontWeight: FontWeight.w800,
                          ),
                          side: BorderSide(
                            color: selected
                                ? _accent.withValues(alpha: 0.4)
                                : Colors.transparent,
                          ),
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
                    const Text(
                      'Add a tip?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _ink,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
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
                            selectedColor: _primary.withValues(alpha: 0.12),
                            backgroundColor: const Color(0xFFF1F5F9),
                            labelStyle: TextStyle(
                              color: selected ? _primary : _ink,
                              fontWeight: FontWeight.w900,
                            ),
                            side: BorderSide(
                              color: selected
                                  ? _primary.withValues(alpha: 0.35)
                                  : Colors.transparent,
                            ),
                            onSelected: (_) =>
                                setState(() => tip = selected ? null : amount),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _handleDone,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _accent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_rounded, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Done',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
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
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEFF6FF) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? _TripCompletedScreenState._primary
                : _TripCompletedScreenState._line,
            width: selected ? 2 : 1,
          ),
          boxShadow: [
            if (selected)
              BoxShadow(
                color: _TripCompletedScreenState._primary.withValues(
                  alpha: 0.12,
                ),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: selected
                    ? _TripCompletedScreenState._primary.withValues(alpha: 0.12)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: selected
                    ? _TripCompletedScreenState._primary
                    : _TripCompletedScreenState._muted,
                size: 19,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: selected
                      ? _TripCompletedScreenState._primary
                      : _TripCompletedScreenState._ink,
                ),
              ),
            ),
            if (selected)
              const Icon(
                Icons.check_circle_rounded,
                color: _TripCompletedScreenState._accent,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
