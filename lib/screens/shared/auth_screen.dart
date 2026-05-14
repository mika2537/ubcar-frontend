import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../system/localization/app_language_controller.dart';
import '../../system/localization/app_localizations.dart';
import '../../system/state/auth_controller.dart';
import '../../system/widgets/language_menu_button.dart';

enum _AuthStep { welcome, login, signup, profile }

class AuthScreen extends StatefulWidget {
  final String role; // 'passenger' | 'driver'
  final VoidCallback? onBack;
  final VoidCallback? onComplete;

  const AuthScreen({
    super.key,
    this.role = 'passenger',
    this.onBack,
    this.onComplete,
  });

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  _AuthStep step = _AuthStep.welcome;
  final _authController = AuthController();
  final _languageController = AppLanguageController();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _genderController = TextEditingController();
  final _ageController = TextEditingController();
  final _carModelController = TextEditingController();
  final _carPlateController = TextEditingController();
  final _driverLicenseIdController = TextEditingController();

  bool showPassword = false;
  bool isLoading = false;
  String? _selectedGender;

  bool get _isLoginSubmitDisabled {
    return _emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty;
  }

  bool get _isSignupSubmitDisabled {
    final base =
        _nameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty ||
        _phoneController.text.trim().isEmpty ||
        _genderController.text.trim().isEmpty ||
        _ageController.text.trim().isEmpty;
    if (base) return true;
    if (widget.role == 'driver') {
      return _carModelController.text.trim().isEmpty ||
          _carPlateController.text.trim().isEmpty ||
          _driverLicenseIdController.text.trim().isEmpty;
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_handleFormChanged);
    _passwordController.addListener(_handleFormChanged);
    _nameController.addListener(_handleFormChanged);
    _phoneController.addListener(_handleFormChanged);
    _genderController.addListener(_handleFormChanged);
    _ageController.addListener(_handleFormChanged);
    _carModelController.addListener(_handleFormChanged);
    _carPlateController.addListener(_handleFormChanged);
    _driverLicenseIdController.addListener(_handleFormChanged);
    _languageController.load().then((_) {
      if (mounted) setState(() {});
    });
  }

  void _handleFormChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _emailController.removeListener(_handleFormChanged);
    _passwordController.removeListener(_handleFormChanged);
    _nameController.removeListener(_handleFormChanged);
    _phoneController.removeListener(_handleFormChanged);
    _genderController.removeListener(_handleFormChanged);
    _ageController.removeListener(_handleFormChanged);
    _carModelController.removeListener(_handleFormChanged);
    _carPlateController.removeListener(_handleFormChanged);
    _driverLicenseIdController.removeListener(_handleFormChanged);
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _genderController.dispose();
    _ageController.dispose();
    _carModelController.dispose();
    _carPlateController.dispose();
    _driverLicenseIdController.dispose();
    super.dispose();
  }

  String get _roleTitle {
    return widget.role == 'driver'
        ? context.l10n.text('startEarningDriver')
        : context.l10n.text('getRideMinutes');
  }

  void _goBack() {
    if (step == _AuthStep.login || step == _AuthStep.signup) {
      setState(() => step = _AuthStep.welcome);
    } else if (widget.onBack != null) {
      widget.onBack!.call();
    } else {
      Navigator.of(context).maybePop();
    }
  }

  Future<void> _handleLogin() async {
    setState(() => isLoading = true);
    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      if (email.isEmpty || password.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.text('enterEmailPassword'))),
        );
        return;
      }
      await _authController.signIn(email: email, password: password);
      widget.onComplete?.call();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _handleSignUp() async {
    setState(() => isLoading = true);
    try {
      final name = _nameController.text.trim();
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      final phone = _phoneController.text.trim();
      final gender = _genderController.text.trim();
      final age = int.tryParse(_ageController.text.trim());
      final carModel = _carModelController.text.trim();
      final carPlate = _carPlateController.text.trim();
      final driverLicenseId = _driverLicenseIdController.text.trim();
      if (name.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.text('enterName'))));
        return;
      }
      if (email.isEmpty || password.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.text('enterEmailPassword'))),
        );
        return;
      }
      if (phone.isEmpty || gender.isEmpty || age == null || age <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.text('requiredProfileFields'))),
        );
        return;
      }
      if (widget.role == 'driver' &&
          (carModel.isEmpty || carPlate.isEmpty || driverLicenseId.isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.text('requiredDriverFields'))),
        );
        return;
      }
      await _authController.signUp(
        name: name,
        email: email,
        password: password,
        role: widget.role,
        phone: phone,
        gender: gender,
        age: age,
        carModel: carModel.isEmpty ? null : carModel,
        carPlate: carPlate.isEmpty ? null : carPlate,
        driverLicenseId: driverLicenseId.isEmpty ? null : driverLicenseId,
      );
      setState(() => step = _AuthStep.profile);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => isLoading = true);
    try {
      final account = await GoogleSignIn(scopes: const ['email']).signIn();
      if (account == null) return;
      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw Exception('No Google ID token received');
      }

      await _authController.signInWithGoogle(
        role: widget.role,
        idToken: idToken,
      );
      widget.onComplete?.call();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _showForgotPasswordDialog() async {
    final l10n = context.l10n;
    final emailController = TextEditingController(
      text: _emailController.text.trim(),
    );
    final passwordController = TextEditingController();
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.text('resetPassword')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: _inputDecoration(
                  label: l10n.text('email'),
                  icon: Icons.mail_outline,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: _inputDecoration(
                  label: l10n.text('newPassword'),
                  icon: Icons.lock_outline,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.text('cancel')),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.text('reset')),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      final email = emailController.text.trim();
      final newPassword = passwordController.text;
      if (email.isEmpty || newPassword.isEmpty) {
        throw Exception('Email and new password are required');
      }
      await _authController.forgotPassword(
        email: email,
        newPassword: newPassword,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.text('passwordResetSuccess'))),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      emailController.dispose();
      passwordController.dispose();
    }
  }

  Future<void> _handleProfileComplete() async {
    setState(() => isLoading = true);
    try {
      widget.onComplete?.call();
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.text('appName')),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _goBack,
        ),
        actions: [LanguageMenuButton(controller: _languageController)],
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: _buildStep(context, theme),
        ),
      ),
    );
  }

  Widget _buildStep(BuildContext context, ThemeData theme) {
    final l10n = context.l10n;

    switch (step) {
      case _AuthStep.welcome:
        return Padding(
          key: const ValueKey('welcome'),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Spacer(),
              _brandLogo(),
              const SizedBox(height: 20),
              Text(
                l10n.text('welcomeToRideShare'),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _roleTitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              _fullWidthButton(
                onPressed: () => setState(() => step = _AuthStep.login),
                disabled: isLoading,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.mail_outline),
                    const SizedBox(width: 10),
                    Text(l10n.text('signIn')),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _fullWidthButton(
                outlined: true,
                onPressed: _handleGoogleSignIn,
                disabled: isLoading,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.g_mobiledata),
                    SizedBox(width: 10),
                    Text(l10n.text('continueWithGoogle')),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _fullWidthButton(
                outlined: true,
                onPressed: () => setState(() => step = _AuthStep.signup),
                disabled: isLoading,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.person_outline),
                    const SizedBox(width: 10),
                    Text(l10n.text('createAccount')),
                  ],
                ),
              ),
              const Spacer(),
            ],
          ),
        );

      case _AuthStep.login:
        return _authFormWrapper(
          key: 'login',
          title: l10n.text('authLoginTitle'),
          subtitle: l10n.text('authLoginSubtitle'),
          theme: theme,
          fields: [
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: _inputDecoration(
                label: l10n.text('email'),
                icon: Icons.mail_outline,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _passwordController,
              obscureText: !showPassword,
              decoration:
                  _inputDecoration(
                    label: l10n.text('password'),
                    icon: Icons.lock_outline,
                  ).copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        showPassword ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () =>
                          setState(() => showPassword = !showPassword),
                    ),
                  ),
            ),
          ],
          bottomAction: TextButton(
            onPressed: _showForgotPasswordDialog,
            child: Text(l10n.text('forgotPassword')),
          ),
          submitLabel: l10n.text('signIn'),
          onSubmit: _handleLogin,
          isSubmitDisabled: _isLoginSubmitDisabled,
        );

      case _AuthStep.signup:
        return _authFormWrapper(
          key: 'signup',
          title: l10n.text('createAccount'),
          subtitle: l10n.text('authSignupSubtitle'),
          theme: theme,
          fields: [
            TextField(
              controller: _nameController,
              decoration: _inputDecoration(
                label: l10n.text('fullName'),
                icon: Icons.person_outline,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: _inputDecoration(
                label: l10n.text('email'),
                icon: Icons.mail_outline,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _passwordController,
              obscureText: !showPassword,
              decoration: _inputDecoration(
                label: l10n.text('password'),
                icon: Icons.lock_outline,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
              ],
              decoration: _inputDecoration(
                label: l10n.text('phone'),
                icon: Icons.phone_outlined,
              ),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _selectedGender,
              decoration: _inputDecoration(
                label: l10n.text('gender'),
                icon: Icons.wc_outlined,
              ),
              items: [
                DropdownMenuItem(value: 'male', child: Text(l10n.text('male'))),
                DropdownMenuItem(
                  value: 'female',
                  child: Text(l10n.text('female')),
                ),
                DropdownMenuItem(
                  value: 'other',
                  child: Text(l10n.text('other')),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedGender = value;
                  _genderController.text = value ?? '';
                });
              },
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _ageController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: _inputDecoration(
                label: l10n.text('age'),
                icon: Icons.cake_outlined,
              ),
            ),
            if (widget.role == 'driver') const SizedBox(height: 14),
            if (widget.role == 'driver')
              TextField(
                controller: _carModelController,
                decoration: _inputDecoration(
                  label: l10n.text('carModel'),
                  icon: Icons.directions_car_outlined,
                ),
              ),
            if (widget.role == 'driver') const SizedBox(height: 14),
            if (widget.role == 'driver')
              TextField(
                controller: _carPlateController,
                textCapitalization: TextCapitalization.characters,
                decoration: _inputDecoration(
                  label: l10n.text('carPlate'),
                  icon: Icons.confirmation_number_outlined,
                ),
              ),
            if (widget.role == 'driver') const SizedBox(height: 14),
            if (widget.role == 'driver')
              TextField(
                controller: _driverLicenseIdController,
                decoration: _inputDecoration(
                  label: l10n.text('driverId'),
                  icon: Icons.badge_outlined,
                ),
              ),
          ],
          bottomAction: TextButton(
            onPressed: () => setState(() => step = _AuthStep.login),
            child: Text(l10n.text('alreadyHaveAccount')),
          ),
          submitLabel: l10n.text('createAccount'),
          onSubmit: _handleSignUp,
          isSubmitDisabled: _isSignupSubmitDisabled,
        );

      case _AuthStep.profile:
        return Padding(
          key: const ValueKey('profile'),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Icon(
                  Icons.check,
                  size: 48,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.text('accountCreated'),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),
              _fullWidthButton(
                onPressed: _handleProfileComplete,
                child: Text(l10n.text('getStarted')),
              ),
            ],
          ),
        );
    }
  }

  Widget _brandLogo() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0x806D28D9)],
        ),
      ),
      alignment: Alignment.center,
      child: const Text(
        'R',
        style: TextStyle(
          fontSize: 40,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _authFormWrapper({
    required String key,
    required String title,
    required String subtitle,
    required List<Widget> fields,
    required Widget bottomAction,
    required String submitLabel,
    required VoidCallback onSubmit,
    required bool isSubmitDisabled,
    required ThemeData theme,
  }) {
    return LayoutBuilder(
      key: ValueKey(key),
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                ...fields,
                const SizedBox(height: 18),
                Center(child: bottomAction),
                const SizedBox(height: 12),
                _fullWidthButton(
                  onPressed: onSubmit,
                  disabled: isLoading || isSubmitDisabled,
                  child: Text(isLoading ? '...' : submitLabel),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _fullWidthButton({
    required Widget child,
    required VoidCallback onPressed,
    bool outlined = false,
    bool disabled = false,
  }) {
    final style = ElevatedButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 16),
    );
    return SizedBox(
      width: double.infinity,
      child: outlined
          ? OutlinedButton(
              onPressed: disabled ? null : onPressed,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: child,
            )
          : ElevatedButton(
              onPressed: disabled ? null : onPressed,
              style: style,
              child: child,
            ),
    );
  }
}
