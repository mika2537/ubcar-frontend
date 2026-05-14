import 'package:flutter/material.dart';

import '../../system/localization/app_language_controller.dart';
import '../../system/localization/app_localizations.dart';
import '../../system/models/route_model.dart';
import '../../system/models/trip_model.dart';
import '../../system/models/user_model.dart';
import '../../system/routing/app_routes.dart';
import '../../system/state/auth_controller.dart';
import '../../system/state/driver_controller.dart';
import '../../system/state/passenger_controller.dart';

class ProfileScreen extends StatefulWidget {
  final String role;
  final VoidCallback? onBack;

  const ProfileScreen({super.key, this.role = 'passenger', this.onBack});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authController = AuthController();
  final _driverController = DriverController();
  final _passengerController = PassengerController();
  final _languageController = AppLanguageController();

  UserModel? _user;
  List<TripModel> _trips = const [];
  List<RouteModel> _routes = const [];
  bool _isLoading = true;
  String? _error;
  Locale? _locale;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    await _languageController.load();
    if (!mounted) {
      return;
    }
    setState(() => _locale = _languageController.locale);
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = await _authController.getCurrentUser();
      if (user == null) {
        throw Exception('Please sign in again.');
      }

      final trips = user.role == 'driver'
          ? await _driverController.getDriverTrips(user.id)
          : await _passengerController.getPassengerTrips(user.id);
      final routes = await _passengerController.getSavedRoutes(user.id);

      if (!mounted) {
        return;
      }
      setState(() {
        _user = user;
        _trips = trips;
        _routes = routes;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _signOut() async {
    await _authController.signOut();
    if (!mounted) {
      return;
    }
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRoutes.roleSelection, (route) => false);
  }

  String _langLabel(Locale? locale) {
    if (locale?.languageCode == 'mn') {
      return 'Монгол';
    }
    return 'English';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: widget.onBack ?? () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 56,
                  color: Colors.redAccent,
                ),
                const SizedBox(height: 12),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadProfile,
                  child: Text(context.l10n.text('tryAgain')),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final user = _user!;
    final isDriver = user.role == 'driver';
    final initials = _initials(user.name ?? user.email);
    final completedTrips = _trips
        .where((trip) => trip.status == 'completed')
        .length;
    final activeTrips = _trips
        .where((trip) => trip.status == 'active' || trip.status == 'accepted')
        .length;
    final completionRate = _trips.isEmpty
        ? 0
        : ((completedTrips / _trips.length) * 100).round();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.indigo, Colors.indigo.withOpacity(0.80)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(26),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed:
                            widget.onBack ?? () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.18),
                          shape: const CircleBorder(),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: _loadProfile,
                        icon: const Icon(Icons.refresh),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.18),
                          shape: const CircleBorder(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Profile',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: 104,
                    height: 104,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.25),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.35),
                        width: 4,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        initials,
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user.name ?? 'User',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    user.email,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    user.createdAt == null
                        ? 'Joined recently'
                        : 'Member since ${_monthYear(user.createdAt!)}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isDriver ? 'Driver Stats' : 'Trip Stats',
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 12),
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          childAspectRatio: 1.2,
                          children: [
                            _StatCard(
                              label: 'Trips',
                              value: '${_trips.length}',
                            ),
                            _StatCard(
                              label: 'Completed',
                              value: '$completedTrips',
                            ),
                            _StatCard(label: 'Active', value: '$activeTrips'),
                            _StatCard(
                              label: isDriver ? 'Saved Routes' : 'Saved Items',
                              value: '${_routes.length}',
                            ),
                            if (isDriver)
                              _StatCard(
                                label: 'Completion Rate',
                                value: '$completionRate%',
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Contact Info',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 12),
                        _InfoRow(
                          icon: Icons.badge_outlined,
                          label: isDriver ? 'Driver ID' : 'Passenger ID',
                          value: user.id,
                        ),
                        const SizedBox(height: 10),
                        _InfoRow(
                          icon: Icons.mail_outline,
                          label: 'Email',
                          value: user.email,
                        ),
                        const SizedBox(height: 10),
                        _InfoRow(
                          icon: Icons.person_outline,
                          label: 'Role',
                          value: user.role,
                        ),
                        const SizedBox(height: 10),
                        _InfoRow(
                          icon: Icons.phone_outlined,
                          label: 'Phone',
                          value: _safeValue(user.phone),
                        ),
                        const SizedBox(height: 10),
                        _InfoRow(
                          icon: Icons.wc_outlined,
                          label: 'Gender',
                          value: _safeValue(user.gender),
                        ),
                        const SizedBox(height: 10),
                        _InfoRow(
                          icon: Icons.cake_outlined,
                          label: 'Age',
                          value: user.age == null ? 'Not set' : '${user.age}',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (isDriver)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Vehicle',
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 12),
                          _InfoRow(
                            icon: Icons.directions_car_outlined,
                            label: 'Car Model',
                            value: _safeValue(user.carModel),
                          ),
                          const SizedBox(height: 10),
                          _InfoRow(
                            icon: Icons.confirmation_number_outlined,
                            label: 'Car Plate',
                            value: _safeValue(user.carPlate),
                          ),
                          const SizedBox(height: 10),
                          _InfoRow(
                            icon: Icons.badge,
                            label: 'Driver ID',
                            value: _safeValue(user.driverLicenseId),
                          ),
                          if ((user.carModel ?? '').isEmpty &&
                              (user.carPlate ?? '').isEmpty &&
                              (user.driverLicenseId ?? '').isEmpty)
                            const Text(
                              'Complete vehicle details in signup/profile setup.',
                              style: TextStyle(
                                color: Colors.black54,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                        ],
                      ),
                    ),
                  if (isDriver) const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Settings',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 8),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(
                            Icons.language,
                            color: Colors.indigo,
                          ),
                          title: const Text(
                            'Language',
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                          subtitle: Text(
                            _langLabel(_locale),
                            style: const TextStyle(color: Colors.black54),
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () async {
                            final target = _locale?.languageCode == 'mn'
                                ? const Locale('en')
                                : const Locale('mn');
                            await _languageController.setLocale(target);
                            if (!mounted) {
                              return;
                            }
                            setState(() => _locale = target);
                          },
                        ),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(
                            Icons.notifications,
                            color: Colors.indigo,
                          ),
                          title: const Text(
                            'Notifications',
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                          subtitle: const Text(
                            'Activity comes from backend trips and chat',
                            style: TextStyle(color: Colors.black54),
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.of(
                            context,
                          ).pushNamed(AppRoutes.notificationCenter),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _signOut,
                      icon: const Icon(Icons.logout),
                      label: const Text(
                        'Log Out',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.withOpacity(0.10),
                        foregroundColor: Colors.red.shade700,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _safeValue(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'Not set';
    }
    return trimmed;
  }

  String _initials(String value) {
    final parts = value.split(' ').where((part) => part.isNotEmpty).toList();
    if (parts.isEmpty) {
      return '?';
    }
    return parts.take(2).map((part) => part[0].toUpperCase()).join();
  }

  String _monthYear(DateTime value) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[value.month - 1]} ${value.year}';
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.indigo.withOpacity(0.10),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: Colors.indigo),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.black54,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 6),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10, right: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 18,
              color: Colors.indigo,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.black54,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
