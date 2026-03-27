import 'package:flutter/material.dart';

enum _AuthStep { welcome, login, signup, profile }

class AuthScreen extends StatefulWidget {
  final String role; // 'passenger' | 'driver'
  final VoidCallback? onBack; // This is called when exiting the auth flow
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

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  bool showPassword = false;
  bool isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  String get _roleTitle {
    return widget.role == 'driver' ? 'Start earning as a driver' : 'Get a ride in minutes';
  }

  // Navigation Logic
  void _goBack() {
    if (step == _AuthStep.login || step == _AuthStep.signup) {
      setState(() => step = _AuthStep.welcome);
    } else {
      // If we are at 'welcome', trigger the callback defined in the Router
      if (widget.onBack != null) {
        widget.onBack!.call();
      } else {
        Navigator.of(context).maybePop();
      }
    }
  }

  Future<void> _handleLogin() async {
    setState(() => isLoading = true);
    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      if (email.isEmpty || password.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter email and password')),
        );
        return;
      }
      widget.onComplete?.call();
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _handleSignUp() async {
    setState(() => isLoading = true);
    try {
      final name = _nameController.text.trim();
      if (name.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter your name')),
        );
        return;
      }
      setState(() => step = _AuthStep.profile);
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _handleProfileComplete() async {
    setState(() => isLoading = true);
    try {
      widget.onComplete?.call();
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('RidePool'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _goBack,
        ),
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
                'Welcome to RideShare',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _roleTitle,
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              _fullWidthButton(
                onPressed: () => setState(() => step = _AuthStep.login),
                disabled: isLoading,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.mail_outline),
                    SizedBox(width: 10),
                    Text('Sign In'),
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
                  children: const [
                    Icon(Icons.person_outline),
                    SizedBox(width: 10),
                    Text('Create Account'),
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
          title: 'Sign In',
          subtitle: 'Enter your credentials to continue',
          theme: theme,
          fields: [
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: _inputDecoration(label: 'Email', icon: Icons.mail_outline),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _passwordController,
              obscureText: !showPassword,
              decoration: _inputDecoration(label: 'Password', icon: Icons.lock_outline).copyWith(
                suffixIcon: IconButton(
                  icon: Icon(showPassword ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => showPassword = !showPassword),
                ),
              ),
            ),
          ],
          bottomAction: TextButton(
            onPressed: () => setState(() => step = _AuthStep.signup),
            child: const Text("Don't have an account? Sign up"),
          ),
          submitLabel: 'Sign In',
          onSubmit: _handleLogin,
          isSubmitDisabled: _emailController.text.isEmpty || _passwordController.text.isEmpty,
        );

      case _AuthStep.signup:
        return _authFormWrapper(
          key: 'signup',
          title: 'Create Account',
          subtitle: 'Tell us a bit about yourself',
          theme: theme,
          fields: [
            TextField(
              controller: _nameController,
              decoration: _inputDecoration(label: 'Full Name', icon: Icons.person_outline),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: _inputDecoration(label: 'Email', icon: Icons.mail_outline),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _passwordController,
              obscureText: !showPassword,
              decoration: _inputDecoration(label: 'Password', icon: Icons.lock_outline),
            ),
          ],
          bottomAction: TextButton(
            onPressed: () => setState(() => step = _AuthStep.login),
            child: const Text('Already have an account? Sign in'),
          ),
          submitLabel: 'Create Account',
          onSubmit: _handleSignUp,
          isSubmitDisabled: _nameController.text.isEmpty || _emailController.text.isEmpty,
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
                child: Icon(Icons.check, size: 48, color: theme.colorScheme.primary),
              ),
              const SizedBox(height: 24),
              const Text('Account Created!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 32),
              _fullWidthButton(
                onPressed: _handleProfileComplete,
                child: const Text('Get Started'),
              ),
            ],
          ),
        );
    }
  }

  // --- Helper UI Components ---

  Widget _brandLogo() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(colors: [Color(0xFF4F46E5), Color(0x806D28D9)]),
      ),
      alignment: Alignment.center,
      child: const Text('R', style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white)),
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
    return Padding(
      key: ValueKey(key),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          Text(subtitle, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 24),
          ...fields,
          const Spacer(),
          Center(child: bottomAction),
          const SizedBox(height: 12),
          _fullWidthButton(
            onPressed: onSubmit,
            disabled: isLoading || isSubmitDisabled,
            child: Text(isLoading ? 'Please wait...' : submitLabel),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({required String label, required IconData icon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _fullWidthButton({required Widget child, required VoidCallback onPressed, bool outlined = false, bool disabled = false}) {
    final style = ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16));
    return SizedBox(
      width: double.infinity,
      child: outlined
          ? OutlinedButton(onPressed: disabled ? null : onPressed, style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)), child: child)
          : ElevatedButton(onPressed: disabled ? null : onPressed, style: style, child: child),
    );
  }
}