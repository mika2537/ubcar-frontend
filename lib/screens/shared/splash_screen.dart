import 'dart:async';

import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback? onComplete;
  final int durationMs;

  const SplashScreen({
    super.key,
    this.onComplete,
    this.durationMs = 2500,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool isAnimating = false;
  Timer? _completeTimer;
  Timer? _animateTimer;

  @override
  void initState() {
    super.initState();

    _animateTimer = Timer(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      setState(() => isAnimating = true);
    });

    _completeTimer = Timer(Duration(milliseconds: widget.durationMs), () {
      widget.onComplete?.call();
    });
  }

  @override
  void dispose() {
    _completeTimer?.cancel();
    _animateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.primaryContainer,
      body: Stack(
        children: [
          // Expanding background blobs (rough equivalent of your React animation)
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedScale(
                  scale: isAnimating ? 4 : 1,
                  duration: const Duration(milliseconds: 1000),
                  child: AnimatedOpacity(
                    opacity: isAnimating ? 0 : 1,
                    duration: const Duration(milliseconds: 1000),
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: scheme.onPrimary.withOpacity(0.10),
                      ),
                    ),
                  ),
                ),
                AnimatedScale(
                  scale: isAnimating ? 5 : 1,
                  duration: const Duration(milliseconds: 1000),
                  child: AnimatedOpacity(
                    opacity: isAnimating ? 0 : 1,
                    duration: const Duration(milliseconds: 1000),
                    child: Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: scheme.onPrimary.withOpacity(0.14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Foreground logo/text
          Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(milliseconds: 700),
              builder: (context, value, child) {
                final scale = isAnimating ? 1.1 : 1.0;
                return Transform.scale(
                  scale: scale,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedRotation(
                        duration: const Duration(milliseconds: 500),
                        turns: isAnimating ? 1 : 0,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            color: scheme.onPrimary.withOpacity(0.95),
                          ),
                          child: Icon(
                            Icons.directions_car,
                            size: 40,
                            color: scheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'RidePool',
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: scheme.onPrimary,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Share rides, save money',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: scheme.onPrimary.withOpacity(0.75),
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          // Bottom dots
          Positioned(
            bottom: 120,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: scheme.onPrimary.withOpacity(0.55),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
