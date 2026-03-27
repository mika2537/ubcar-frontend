import 'dart:async';

import 'package:flutter/material.dart';

enum _SearchStatus { pending, accepted }

class SearchingDriverScreen extends StatefulWidget {
  final String pickup;
  final String destination;
  final int seatsRequested;
  final String routeName;
  final String driverName;
  final VoidCallback? onCancel;
  final VoidCallback? onAccepted;

  const SearchingDriverScreen({
    super.key,
    this.pickup = 'Salt Lake Sector V',
    this.destination = 'Park Street Metro Station',
    this.seatsRequested = 1,
    this.routeName = 'Daily Office Commute',
    this.driverName = 'Rajesh Kumar',
    this.onCancel,
    this.onAccepted,
  });

  @override
  State<SearchingDriverScreen> createState() => _SearchingDriverScreenState();
}

class _SearchingDriverScreenState extends State<SearchingDriverScreen> {
  int waitTimeSeconds = 0;
  _SearchStatus status = _SearchStatus.pending;

  Timer? _waitTimer;
  Timer? _acceptTimer;

  @override
  void initState() {
    super.initState();

    _waitTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => waitTimeSeconds += 1);
    });

    // React: accept after ~4s; then call onAccepted after 1.5s
    _acceptTimer = Timer(const Duration(seconds: 4), () {
      if (!mounted) return;
      setState(() => status = _SearchStatus.accepted);
      Timer(const Duration(milliseconds: 1500), () {
        widget.onAccepted?.call();
      });
    });
  }

  @override
  void dispose() {
    _waitTimer?.cancel();
    _acceptTimer?.cancel();
    super.dispose();
  }

  String formatTime(int totalSeconds) {
    final mins = totalSeconds ~/ 60;
    final secs = totalSeconds % 60;
    final secStr = secs.toString().padLeft(2, '0');
    return '$mins:$secStr';
  }

  @override
  Widget build(BuildContext context) {
    final isAccepted = status == _SearchStatus.accepted;
    final title = isAccepted ? 'Request Accepted!' : 'Waiting for Confirmation';
    final subtitle = isAccepted
        ? '${widget.driverName} accepted your seat request'
        : '${widget.driverName} to accept...';
    final seatLabel = widget.seatsRequested > 1 ? 'seats' : 'seat';
    final statusChip = isAccepted ? 'Accepted' : 'Pending';

    final sheetHeight = MediaQuery.of(context).size.height * 0.46;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                color: Colors.grey.shade200,
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: Opacity(
                  opacity: 0.18,
                  child: GridView.builder(
                    padding: EdgeInsets.zero,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 8,
                    ),
                    itemBuilder: (_, __) => const SizedBox(),
                  ),
                ),
              ),
            ),

            // Pulsing center
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 700),
                    width: isAccepted ? 24 : 36,
                    height: isAccepted ? 24 : 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isAccepted ? Colors.green.withOpacity(0.20) : Colors.indigo.withOpacity(0.18),
                      border: Border.all(
                        color: isAccepted ? Colors.green.withOpacity(0.35) : Colors.indigo.withOpacity(0.40),
                        width: 2,
                      ),
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 700),
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isAccepted ? Colors.green.withOpacity(0.28) : Colors.indigo.withOpacity(0.28),
                    ),
                  ),
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isAccepted ? Colors.green : Colors.indigo,
                      boxShadow: [
                        BoxShadow(
                          color: (isAccepted ? Colors.green : Colors.indigo).withOpacity(0.35),
                          blurRadius: 22,
                        )
                      ],
                    ),
                    child: Center(
                      child: isAccepted
                          ? const Icon(Icons.check, color: Colors.white, size: 28)
                          : const Icon(Icons.people, color: Colors.white, size: 28),
                    ),
                  ),
                ],
              ),
            ),

            Positioned(
              top: 12,
              right: 12,
              child: IconButton(
                onPressed: widget.onCancel,
                icon: const Icon(Icons.close),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.85),
                  shape: const CircleBorder(),
                ),
              ),
            ),

            Align(
              alignment: Alignment.bottomCenter,
              child: SizedBox(
                height: sheetHeight,
                width: double.infinity,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      Container(
                        width: 54,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                subtitle,
                                style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w700),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Wait time: ${formatTime(waitTimeSeconds)}',
                                style: TextStyle(
                                  color: Colors.black54,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 18),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.routeName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        color: Colors.indigo,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
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
                                              width: 2,
                                              height: 40,
                                              color: Colors.grey.shade400,
                                            ),
                                            Container(
                                              width: 10,
                                              height: 10,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: Colors.indigo.withOpacity(0.5),
                                                  width: 2,
                                                ),
                                                color: Colors.indigo.withOpacity(0.12),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(widget.pickup,
                                                  style: const TextStyle(fontWeight: FontWeight.w800)),
                                              const SizedBox(height: 10),
                                              Text(widget.destination,
                                                  style: const TextStyle(fontWeight: FontWeight.w800)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: Colors.indigo.withOpacity(0.10),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.people, size: 18, color: Colors.indigo),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${widget.seatsRequested} $seatLabel',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w900,
                                            color: Colors.indigo,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: isAccepted ? Colors.green.withOpacity(0.10) : Colors.orange.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      statusChip,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        color: isAccepted ? Colors.green.shade800 : Colors.orange.shade800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),
                              if (!isAccepted)
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton(
                                    onPressed: widget.onCancel,
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      side: BorderSide(color: Colors.indigo.withOpacity(0.4)),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    ),
                                    child: const Text(
                                      'Cancel Request',
                                      style: TextStyle(fontWeight: FontWeight.w900, color: Colors.indigo),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
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
