import 'package:flutter/material.dart';

import 'bottom_nav.dart';

class AppScaffold extends StatelessWidget {
  final Widget body;
  final int currentIndex;
  final void Function(int index) onTap;

  const AppScaffold({
    super.key,
    required this.body,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: body,
      bottomNavigationBar: BottomNav(
        currentIndex: currentIndex,
        onTap: onTap,
      ),
    );
  }
}

