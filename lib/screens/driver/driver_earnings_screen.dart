import 'package:flutter/material.dart';

import '../../system/localization/app_localizations.dart';
import '../../system/models/trip_model.dart';
import '../../system/state/auth_controller.dart';
import '../../system/state/driver_controller.dart';

class DriverEarningsScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const DriverEarningsScreen({super.key, this.onBack});

  @override
  State<DriverEarningsScreen> createState() => _DriverEarningsScreenState();
}

enum _TimePeriod { daily, weekly, monthly }

class _DriverEarningsScreenState extends State<DriverEarningsScreen> {
  final _authController = AuthController();
  final _driverController = DriverController();

  _TimePeriod timePeriod = _TimePeriod.weekly;
  List<TripModel> _trips = const [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  Future<void> _loadTrips() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = await _authController.getCurrentUser();
      if (user == null) {
        throw Exception('Please sign in again.');
      }

      final trips = await _driverController.getDriverTrips(user.id);
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

  List<Map<String, Object?>> get _chartData {
    switch (timePeriod) {
      case _TimePeriod.daily:
        return _buildDailyData();
      case _TimePeriod.weekly:
        return _buildWeeklyData();
      case _TimePeriod.monthly:
        return _buildMonthlyData();
    }
  }

  int get _totalEstimatedEarnings {
    return _sumEstimated(_filteredTrips());
  }

  String get _comparisonText {
    switch (timePeriod) {
      case _TimePeriod.daily:
        return 'based on today\'s trips';
      case _TimePeriod.weekly:
        return 'based on the last 7 days';
      case _TimePeriod.monthly:
        return 'based on the last 4 weeks';
    }
  }

  int get _completedTrips =>
      _trips.where((trip) => trip.status == 'completed').length;

  int get _activeTrips => _trips
      .where((trip) => trip.status == 'active' || trip.status == 'accepted')
      .length;

  double get _completionRate {
    if (_trips.isEmpty) {
      return 0;
    }
    return (_completedTrips / _trips.length) * 100;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.text('earnings')),
        leading: IconButton(
          onPressed: widget.onBack ?? () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
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
                onPressed: _loadTrips,
                child: Text(context.l10n.text('tryAgain')),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTrips,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.indigo.withOpacity(0.08),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.indigo.withOpacity(0.18)),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Estimated Earnings',
                            style: TextStyle(
                              color: Colors.black54,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '₮$_totalEstimatedEarnings',
                            style: const TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.indigo.withOpacity(0.20),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.wallet, color: Colors.indigo),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  _comparisonText,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Amounts are derived from live trip records until explicit fare fields are added in the backend.',
                  style: TextStyle(
                    color: Colors.black45,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _PeriodChip(
                label: 'Daily',
                selected: timePeriod == _TimePeriod.daily,
                onTap: () => setState(() => timePeriod = _TimePeriod.daily),
              ),
              const SizedBox(width: 8),
              _PeriodChip(
                label: 'Weekly',
                selected: timePeriod == _TimePeriod.weekly,
                onTap: () => setState(() => timePeriod = _TimePeriod.weekly),
              ),
              const SizedBox(width: 8),
              _PeriodChip(
                label: 'Monthly',
                selected: timePeriod == _TimePeriod.monthly,
                onTap: () => setState(() => timePeriod = _TimePeriod.monthly),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.text('tripActivityOverview'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 180,
                  child: _chartData.isEmpty
                      ? const Center(
                          child: Text(
                            'No trip data yet for this period.',
                            style: TextStyle(
                              color: Colors.black54,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        )
                      : _EarningsChart(data: _chartData),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _SmallMetric(
                  icon: Icons.check_circle_outline,
                  label: 'Completed Trips',
                  value: '$_completedTrips',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SmallMetric(
                  icon: Icons.local_taxi_outlined,
                  label: 'Active Trips',
                  value: '$_activeTrips',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.text('performance'),
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _PerfStat(
                      label: 'Completion Rate',
                      value: '${_completionRate.toStringAsFixed(0)}%',
                      trend: '${_completedTrips} done',
                      positive: true,
                    ),
                    _PerfStat(
                      label: 'Trips Logged',
                      value: '${_trips.length}',
                      trend: 'from database',
                      positive: true,
                    ),
                    _PerfStat(
                      label: 'Active Now',
                      value: '$_activeTrips',
                      trend: 'live status',
                      positive: _activeTrips > 0,
                    ),
                    _PerfStat(
                      label: 'Route Stops',
                      value: '${_averageStops().toStringAsFixed(1)}',
                      trend: 'avg midpoints',
                      positive: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.text('recentTrips'),
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 10),
                if (_trips.isEmpty)
                  const Text(
                    'No trips found for this driver.',
                    style: TextStyle(
                      color: Colors.black54,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                else
                  ..._trips.take(6).map((trip) {
                    final isActive =
                        trip.status == 'active' || trip.status == 'accepted';
                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.grey.shade200),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: Colors.indigo.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.route,
                              color: Colors.indigo,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${trip.route?.from ?? 'Unknown'} to ${trip.route?.to ?? 'Unknown'}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${trip.createdAt.toLocal()}'
                                      .split('.')
                                      .first,
                                  style: const TextStyle(
                                    color: Colors.black54,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '₮${_estimateTripValue(trip)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? Colors.orange.withOpacity(0.12)
                                      : Colors.green.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  isActive ? trip.status : 'completed',
                                  style: TextStyle(
                                    color: isActive
                                        ? Colors.orange.shade800
                                        : Colors.green.shade700,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<TripModel> _filteredTrips() {
    final now = DateTime.now();
    return _trips.where((trip) {
      switch (timePeriod) {
        case _TimePeriod.daily:
          return _sameDay(trip.createdAt, now);
        case _TimePeriod.weekly:
          return trip.createdAt.isAfter(now.subtract(const Duration(days: 7)));
        case _TimePeriod.monthly:
          return trip.createdAt.isAfter(now.subtract(const Duration(days: 28)));
      }
    }).toList();
  }

  List<Map<String, Object?>> _buildDailyData() {
    final now = DateTime.now();
    final periods = <String, List<TripModel>>{
      'Morning': [],
      'Noon': [],
      'Evening': [],
      'Night': [],
    };

    for (final trip in _trips.where((trip) => _sameDay(trip.createdAt, now))) {
      final hour = trip.createdAt.hour;
      if (hour < 11) {
        periods['Morning']!.add(trip);
      } else if (hour < 16) {
        periods['Noon']!.add(trip);
      } else if (hour < 21) {
        periods['Evening']!.add(trip);
      } else {
        periods['Night']!.add(trip);
      }
    }

    return periods.entries
        .map(
          (entry) => <String, Object?>{
            'name': entry.key,
            'earnings': _sumEstimated(entry.value),
          },
        )
        .toList();
  }

  List<Map<String, Object?>> _buildWeeklyData() {
    final now = DateTime.now();
    final labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final values = <String, List<TripModel>>{
      for (final label in labels) label: <TripModel>[],
    };

    for (final trip in _trips.where(
      (trip) => trip.createdAt.isAfter(now.subtract(const Duration(days: 7))),
    )) {
      final label = labels[trip.createdAt.weekday - 1];
      values[label]!.add(trip);
    }

    return labels
        .map(
          (label) => <String, Object?>{
            'name': label,
            'earnings': _sumEstimated(values[label]!),
          },
        )
        .toList();
  }

  List<Map<String, Object?>> _buildMonthlyData() {
    final now = DateTime.now();
    return List.generate(4, (index) {
      final start = now.subtract(Duration(days: (3 - index) * 7 + 7));
      final end = now.subtract(Duration(days: (3 - index) * 7));
      final trips = _trips.where((trip) {
        return trip.createdAt.isAfter(start) && trip.createdAt.isBefore(end);
      }).toList();
      return <String, Object?>{
        'name': 'Week ${index + 1}',
        'earnings': _sumEstimated(trips),
      };
    });
  }

  int _sumEstimated(List<TripModel> trips) {
    return trips.fold<int>(0, (sum, trip) => sum + _estimateTripValue(trip));
  }

  int _estimateTripValue(TripModel trip) {
    final midpointBonus = (trip.route?.midpoints.length ?? 0) * 1200;
    final statusBonus = trip.status == 'completed' ? 2000 : 1000;
    return 3500 + midpointBonus + statusBonus;
  }

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  double _averageStops() {
    if (_trips.isEmpty) {
      return 0;
    }
    final totalStops = _trips.fold<int>(
      0,
      (sum, trip) => sum + (trip.route?.midpoints.length ?? 0),
    );
    return totalStops / _trips.length;
  }
}

class _PeriodChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PeriodChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: Colors.indigo.withOpacity(0.12),
        backgroundColor: Colors.grey.shade200,
      ),
    );
  }
}

class _EarningsChart extends StatelessWidget {
  final List<Map<String, Object?>> data;

  const _EarningsChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final earningsValues = data
        .map((entry) => (entry['earnings'] as num?)?.toDouble() ?? 0)
        .toList(growable: false);
    final maxValue = earningsValues.isEmpty
        ? 1
        : earningsValues
              .reduce((a, b) => a > b ? a : b)
              .clamp(1, double.infinity);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(data.length, (index) {
        final value = earningsValues[index];
        final heightFactor = (value / maxValue).clamp(0, 1);
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  height: 120 * heightFactor + 10,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: const LinearGradient(
                      colors: [Colors.indigo, Color(0xFF6366F1)],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  data[index]['name'] as String? ?? '',
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class _SmallMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SmallMetric({
    required this.icon,
    required this.label,
    required this.value,
  });

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
          Row(
            children: [
              Icon(icon, size: 16, color: Colors.indigo),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.black54,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            context.l10n.text('fromBackendTrips'),
            style: const TextStyle(
              color: Colors.black54,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _PerfStat extends StatelessWidget {
  final String label;
  final String value;
  final String trend;
  final bool positive;

  const _PerfStat({
    required this.label,
    required this.value,
    required this.trend,
    required this.positive,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              trend,
              style: TextStyle(
                color: positive
                    ? Colors.green.shade700
                    : Colors.orange.shade800,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
