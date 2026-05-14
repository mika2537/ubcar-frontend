import 'dart:ui';
import 'package:flutter/material.dart';

import '../localization/app_localizations.dart';

class BottomNav extends StatelessWidget {
  final int currentIndex;
  final void Function(int index) onTap;

  const BottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // BackdropFilter creates the blur effect
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.7), // Semi-transparent
            border: Border(top: BorderSide(color: Colors.black.withOpacity(0.05))),
          ),
          child: BottomNavigationBar(
            currentIndex: currentIndex,
            onTap: onTap,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent, // Required for blur to show
            elevation: 0,
            selectedItemColor: Colors.indigo,
            unselectedItemColor: Colors.black45,
            items: [
              BottomNavigationBarItem(icon: const Icon(Icons.home_filled), label: l10n.text('home')),
              BottomNavigationBarItem(icon: const Icon(Icons.access_time), label: l10n.text('trips')),
              BottomNavigationBarItem(icon: const Icon(Icons.account_balance_wallet), label: l10n.text('wallet')),
              BottomNavigationBarItem(icon: const Icon(Icons.person), label: l10n.text('profile')),
            ],
          ),
        ),
      ),
    );
  }
}
