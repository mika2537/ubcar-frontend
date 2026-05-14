import 'package:flutter/material.dart';

import '../localization/app_language_controller.dart';
import '../localization/app_localizations.dart';

class LanguageMenuButton extends StatelessWidget {
  final AppLanguageController controller;
  final Color? color;

  const LanguageMenuButton({
    super.key,
    required this.controller,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return PopupMenuButton<String>(
      tooltip: l10n.text('language'),
      icon: Icon(Icons.language, color: color),
      onSelected: (value) {
        controller.setLocale(Locale(value));
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'en',
          child: Text(l10n.text('english')),
        ),
        PopupMenuItem(
          value: 'mn',
          child: Text(l10n.text('mongolian')),
        ),
      ],
    );
  }
}
