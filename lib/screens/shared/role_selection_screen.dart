import 'package:flutter/material.dart';

import '../../system/localization/app_language_controller.dart';
import '../../system/localization/app_localizations.dart';
import '../../system/widgets/language_menu_button.dart';

class RoleSelectionScreen extends StatelessWidget {
  final void Function(String role)? onSelectRole; // 'passenger' | 'driver'
  final AppLanguageController? languageController;

  const RoleSelectionScreen({
    super.key, this.onSelectRole, this.languageController,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final controller = languageController ?? AppLanguageController();
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  const Spacer(),
                  if (languageController != null)
                    LanguageMenuButton(controller: languageController!),
                  if (languageController == null)
                    LanguageMenuButton(controller: controller),
                ],
              ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            Icons.directions_car,
                            size: 28,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          l10n.text('welcomeAboard'),
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l10n.text('enterNumberPrompt'),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(height: 26),
                        _RoleButton(
                          icon: Icons.person,
                          title: l10n.text('passengerTitle'),
                          subtitle: l10n.text('passengerSubtitle'),
                          isPassenger: true,
                          onTap: () => onSelectRole?.call('passenger'),
                        ),
                        const SizedBox(height: 12),
                        _RoleButton(
                          icon: Icons.directions_car,
                          title: l10n.text('driverTitle'),
                          subtitle: l10n.text('driverSubtitle'),
                          isPassenger: false,
                          onTap: () => onSelectRole?.call('driver'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.text('termsNotice'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isPassenger;
  final VoidCallback onTap;

  const _RoleButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isPassenger,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = isPassenger ? scheme.primaryContainer : scheme.primary;
    final fg = isPassenger ? scheme.onSurface : scheme.onPrimary;
    final iconBg = isPassenger ? scheme.primaryContainer : scheme.primary;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          backgroundColor: bg,
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, size: 26, color: fg),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: fg,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isPassenger ? scheme.onSurfaceVariant : scheme.onPrimary,
                        ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: fg),
          ],
        ),
      ),
    );
  }
}
