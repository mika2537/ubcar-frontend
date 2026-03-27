import 'package:flutter/material.dart';

import 'screens/shared/splash_screen.dart';
import 'system/routing/app_routes.dart';
import 'system/routing/app_router.dart';
import 'system/theme/app_theme.dart';

void main() {
  runApp(const RideTogetherApp());
}

class RideTogetherApp extends StatelessWidget {
  const RideTogetherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      onGenerateRoute: AppRouter.generateRoute,
      home: _SplashToRoleSelection(),
    );
  }
}

class _SplashToRoleSelection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SplashScreen(
      onComplete: () {
        Navigator.of(context).pushReplacementNamed(AppRoutes.roleSelection);
      },
    );
  }
}

