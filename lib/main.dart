import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'screens/shared/splash_screen.dart';
import 'system/localization/app_language_controller.dart';
import 'system/localization/app_localizations.dart';
import 'system/routing/app_routes.dart';
import 'system/routing/app_router.dart';
import 'system/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final languageController = AppLanguageController();
  await languageController.load();

  runApp(RideTogetherApp(languageController: languageController));
}

class RideTogetherApp extends StatefulWidget {
  final AppLanguageController languageController;

  const RideTogetherApp({
    super.key,
    required this.languageController,
  });

  @override
  State<RideTogetherApp> createState() => _RideTogetherAppState();
}

class _RideTogetherAppState extends State<RideTogetherApp> {
  @override
  void initState() {
    super.initState();
    widget.languageController.addListener(_handleLocaleChanged);
  }

  @override
  void dispose() {
    widget.languageController.removeListener(_handleLocaleChanged);
    super.dispose();
  }

  void _handleLocaleChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      locale: widget.languageController.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      onGenerateRoute: AppRouter.generateRoute,
      home: _SplashToRoleSelection(
        languageController: widget.languageController,
      ),
    );
  }
}

class _SplashToRoleSelection extends StatelessWidget {
  final AppLanguageController languageController;

  const _SplashToRoleSelection({
    required this.languageController,
  });

  @override
  Widget build(BuildContext context) {
    return SplashScreen(
      languageController: languageController,
      onComplete: () {
        Navigator.of(context).pushReplacementNamed(AppRoutes.roleSelection);
      },
    );
  }
}