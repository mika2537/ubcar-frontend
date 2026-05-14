import 'package:flutter/material.dart';

import '../../system/models/trip_model.dart';
import '../../system/state/auth_controller.dart';
import '../../system/state/driver_controller.dart';
import '../../system/state/passenger_controller.dart';

class WalletScreen extends StatefulWidget {
  final String role;
  final VoidCallback? onBack;

  const WalletScreen({super.key, this.role = 'passenger', this.onBack});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final _authController = AuthController();
  final _driverController = DriverController();
  final _passengerController = PassengerController();

  List<TripModel> _trips = const [];
  bool _isLoading = true;
  String? _error;
  String _activeTab = 'transactions';

  @override
  void initState() {
    super.initState();
    _loadWallet();
  }

  Future<void> _loadWallet() async {
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

      if (!mounted) {
        return;
      }
      setState(() {
        _trips = trips;
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

  int get _balance {
    final completedTrips = _trips
        .where((trip) => trip.status == 'completed')
        .toList();
    return completedTrips.fold<int>(0, (sum, trip) {
      final amount = _estimateAmount(trip);
      return sum + amount;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDriver = widget.role == 'driver';
    return Container(
      color: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              child: Row(
                children: [
                  IconButton(
                    onPressed:
                        widget.onBack ?? () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.grey.shade100,
                      shape: const CircleBorder(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Wallet',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.indigo, Colors.indigo.shade800],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isDriver
                          ? 'Completed Trip Earnings'
                          : 'Completed Trip Spend',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '₮$_balance',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'This screen now reads trip-based transaction data from the backend. Payment methods are not stored yet.',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
            _TabSwitcher(
              activeTab: _activeTab,
              onChanged: (value) => setState(() => _activeTab = value),
            ),
            Expanded(child: _buildBody(isDriver)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(bool isDriver) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
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
                onPressed: _loadWallet,
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (_activeTab == 'cards') {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No payment methods are stored in the backend yet.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black54,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }

    if (_trips.isEmpty) {
      return const Center(
        child: Text(
          'No trip transactions found yet.',
          style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w700),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadWallet,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
        children: [
          for (final trip in _trips)
            _TransactionTile(
              trip: trip,
              isDriver: isDriver,
              amount: _estimateAmount(trip),
            ),
        ],
      ),
    );
  }

  int _estimateAmount(TripModel trip) {
    return 3500 + ((trip.route?.midpoints.length ?? 0) * 1200);
  }
}

class _TabSwitcher extends StatelessWidget {
  final String activeTab;
  final ValueChanged<String> onChanged;

  const _TabSwitcher({required this.activeTab, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            _TabBtn(
              label: 'Transactions',
              active: activeTab == 'transactions',
              onTap: () => onChanged('transactions'),
            ),
            _TabBtn(
              label: 'Methods',
              active: activeTab == 'cards',
              onTap: () => onChanged('cards'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabBtn extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _TabBtn({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: active ? Colors.indigo : Colors.black54,
            ),
          ),
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final TripModel trip;
  final bool isDriver;
  final int amount;

  const _TransactionTile({
    required this.trip,
    required this.isDriver,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    final isCredit = isDriver;
    final title = isDriver ? 'Ride Earnings' : 'Ride Payment';
    final description =
        '${trip.route?.from ?? 'Unknown'} → ${trip.route?.to ?? 'Unknown'}';

    return Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: isCredit
                ? Colors.green.withOpacity(0.1)
                : Colors.grey.shade100,
            child: Icon(
              isCredit ? Icons.add : Icons.remove,
              color: isCredit ? Colors.green : Colors.black54,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  description,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
                Text(
                  '${trip.createdAt.toLocal()}'.split('.').first,
                  style: const TextStyle(fontSize: 12, color: Colors.black45),
                ),
              ],
            ),
          ),
          Text(
            '${isCredit ? '+' : '-'}₮$amount',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isCredit ? Colors.green : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
