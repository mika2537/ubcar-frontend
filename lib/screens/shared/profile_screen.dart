import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  final String role; // passenger | driver
  final VoidCallback? onBack;

  const ProfileScreen({
    super.key,
    this.role = 'passenger',
    this.onBack,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool isEditing = false;
  bool showLanguageModal = false;
  String language = 'en';

  final profile = {
    'name': 'Rahul Sharma',
    'phone': '+91 98765 43210',
    'email': 'rahul.sharma@email.com',
    'address': 'Salt Lake, Kolkata',
    'ratingAvg': 4.8,
    'ratingCount': 156,
    'joinDate': 'Member since Jan 2024',
  };

  final driverStats = {
    'totalEarnings': '₹45,200',
    'completionRate': '96%',
    'acceptanceRate': '92%',
    'hoursOnline': '320h',
  };

  final vehicle = {
    'make': 'Maruti Suzuki',
    'model': 'Swift Dzire',
    'licensePlate': 'WB 02 AB 1234',
    'capacity': '4 seats',
  };

  String _langLabel(String code) => code == 'en' ? 'English' : 'Монгол';

  @override
  Widget build(BuildContext context) {
    final isDriver = widget.role == 'driver';
    final initials = (profile['name'] as String).split(' ').where((s) => s.isNotEmpty).map((s) => s[0]).join();

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
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(26)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.18),
                          shape: const CircleBorder(),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => setState(() => isEditing = !isEditing),
                        icon: const Icon(Icons.edit),
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
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                  const SizedBox(height: 14),
                  Stack(
                    children: [
                      Container(
                        width: 104,
                        height: 104,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.25),
                          border: Border.all(color: Colors.white.withOpacity(0.35), width: 4),
                        ),
                        child: Center(
                          child: Text(
                            initials,
                            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: Colors.white),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 6,
                        right: 10,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.35),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt, color: Colors.white),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    profile['name'] as String,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        '${profile['ratingAvg']} • ${(profile['ratingCount'] as int)} ratings',
                        style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w700, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    profile['joinDate'] as String,
                    style: TextStyle(color: Colors.white.withOpacity(0.85), fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
                children: [
                  if (isDriver) ...[
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
                          const Text('Driver Stats', style: TextStyle(fontWeight: FontWeight.w900)),
                          const SizedBox(height: 12),
                          GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            childAspectRatio: 1.2,
                            children: driverStats.entries.map((e) {
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
                                      e.value,
                                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.indigo),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      e.key == 'totalEarnings'
                                          ? 'Total Earnings'
                                          : e.key == 'completionRate'
                                              ? 'Completion Rate'
                                              : e.key == 'acceptanceRate'
                                                  ? 'Acceptance Rate'
                                                  : 'Hours Online',
                                      style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w700, fontSize: 12),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          )
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
                          const Text('Vehicle', style: TextStyle(fontWeight: FontWeight.w900)),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: Colors.indigo.withOpacity(0.10),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(Icons.directions_car, color: Colors.indigo),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('${vehicle['make']} ${vehicle['model']}', style: const TextStyle(fontWeight: FontWeight.w900)),
                                    const SizedBox(height: 6),
                                    Text('${vehicle['licensePlate']} • ${vehicle['capacity']}', style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w700, fontSize: 12)),
                                  ],
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Contact info
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
                        const Text('Contact Info', style: TextStyle(fontWeight: FontWeight.w900)),
                        const SizedBox(height: 12),
                        _ContactRow(
                          icon: Icons.phone,
                          label: 'Phone',
                          value: profile['phone'] as String,
                          editable: isEditing,
                        ),
                        const SizedBox(height: 10),
                        _ContactRow(
                          icon: Icons.mail_outline,
                          label: 'Email',
                          value: profile['email'] as String,
                          editable: isEditing,
                        ),
                        const SizedBox(height: 10),
                        _ContactRow(
                          icon: Icons.location_on_outlined,
                          label: 'Address',
                          value: profile['address'] as String,
                          editable: isEditing,
                        ),
                      ],
                    ),
                  ),

                  if (isEditing)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () => setState(() => isEditing = false),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          ),
                          child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.w900)),
                        ),
                      ),
                    ),

                  const SizedBox(height: 14),

                  // Menu sections
                  _MenuSection(
                    title: 'Account',
                    items: [
                      _MenuItem(title: 'Verification', subtitle: 'Verified', icon: Icons.shield, onTap: () {}),
                      _MenuItem(title: 'Notifications', subtitle: 'Enabled', icon: Icons.notifications, onTap: () {}),
                      _MenuItem(title: 'Language', subtitle: language == 'mn' ? 'Монгол' : 'English', icon: Icons.language, onTap: () => setState(() => showLanguageModal = true)),
                      _MenuItem(title: 'Dark Mode', subtitle: 'Off', icon: Icons.brightness_6, onTap: () {}),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _MenuSection(
                    title: 'Support',
                    items: [
                      _MenuItem(title: 'Help & Support', subtitle: '', icon: Icons.help_outline, onTap: () {}),
                      _MenuItem(title: 'Terms & Privacy', subtitle: '', icon: Icons.description_outlined, onTap: () {}),
                    ],
                  ),

                  const SizedBox(height: 14),
                  // Find the Log Out button at the bottom of the ListView
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // FIX: Navigate to Role Selection and remove all previous screens from the stack
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          '/role-selection', // Make sure this matches AppRoutes.roleSelection
                              (route) => false,
                        );
                      },
                      icon: const Icon(Icons.logout),
                      label: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.w900)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.withOpacity(0.10),
                        foregroundColor: Colors.red.shade700,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Language modal
            if (showLanguageModal)
              Positioned.fill(
                child: Container(
                  color: Colors.black54,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 54,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text('Select Language', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                          const SizedBox(height: 12),
                          _LangOption(
                            label: 'English',
                            selected: language == 'en',
                            onTap: () {
                              setState(() => language = 'en');
                              setState(() => showLanguageModal = false);
                            },
                          ),
                          const SizedBox(height: 10),
                          _LangOption(
                            label: 'Монгол',
                            selected: language == 'mn',
                            onTap: () {
                              setState(() => language = 'mn');
                              setState(() => showLanguageModal = false);
                            },
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 46,
                            child: OutlinedButton(
                              onPressed: () => setState(() => showLanguageModal = false),
                              child: const Text('Close', style: TextStyle(fontWeight: FontWeight.w900)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool editable;

  const _ContactRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.editable,
  });

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
              Text(label, style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w700, fontSize: 12)),
              const SizedBox(height: 6),
              editable
                  ? TextField(
                      controller: TextEditingController(text: value),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    )
                  : Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
            ],
          ),
        ),
      ],
    );
  }
}

class _MenuSection extends StatelessWidget {
  final String title;
  final List<_MenuItem> items;

  const _MenuSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          ...items.map((it) {
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(it.icon, color: Colors.indigo),
              ),
              title: Text(it.title, style: const TextStyle(fontWeight: FontWeight.w900)),
              subtitle: it.subtitle.isEmpty ? null : Text(it.subtitle, style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w700)),
              trailing: const Icon(Icons.chevron_right),
              onTap: it.onTap,
            );
          }).toList(),
        ],
      ),
    );
  }
}

class _MenuItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _MenuItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });
}

class _LangOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LangOption({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: TextStyle(fontWeight: FontWeight.w900)),
      trailing: selected ? const Icon(Icons.check, color: Colors.indigo) : null,
      onTap: onTap,
    );
  }
}
