import 'package:flutter/material.dart';

class DriverEarningsScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const DriverEarningsScreen({super.key, this.onBack});

  @override
  State<DriverEarningsScreen> createState() => _DriverEarningsScreenState();
}

enum _TimePeriod { daily, weekly, monthly }

class _DriverEarningsScreenState extends State<DriverEarningsScreen> {
  _TimePeriod timePeriod = _TimePeriod.weekly;

  final dailyData = const [
    {'name': '6AM', 'earnings': 120},
    {'name': '9AM', 'earnings': 280},
    {'name': '12PM', 'earnings': 180},
    {'name': '3PM', 'earnings': 320},
    {'name': '6PM', 'earnings': 450},
    {'name': '9PM', 'earnings': 280},
  ];
  final weeklyData = const [
    {'name': 'Mon', 'earnings': 1240, 'trips': 12},
    {'name': 'Tue', 'earnings': 980, 'trips': 9},
    {'name': 'Wed', 'earnings': 1520, 'trips': 14},
    {'name': 'Thu', 'earnings': 1180, 'trips': 11},
    {'name': 'Fri', 'earnings': 1890, 'trips': 18},
    {'name': 'Sat', 'earnings': 2100, 'trips': 20},
    {'name': 'Sun', 'earnings': 1650, 'trips': 16},
  ];
  final monthlyData = const [
    {'name': 'Week 1', 'earnings': 8500},
    {'name': 'Week 2', 'earnings': 9200},
    {'name': 'Week 3', 'earnings': 7800},
    {'name': 'Week 4', 'earnings': 10500},
  ];

  final recentPayouts = const [
    {'id': 1, 'date': 'Today', 'amount': 1240, 'trips': 8, 'status': 'pending'},
    {'id': 2, 'date': 'Yesterday', 'amount': 1680, 'trips': 12, 'status': 'completed'},
    {'id': 3, 'date': 'Jan 14', 'amount': 2100, 'trips': 16, 'status': 'completed'},
    {'id': 4, 'date': 'Jan 13', 'amount': 1450, 'trips': 10, 'status': 'completed'},
  ];

  List<Map<String, Object?>> get chartData {
    switch (timePeriod) {
      case _TimePeriod.daily:
        return dailyData.cast<Map<String, Object?>>();
      case _TimePeriod.weekly:
        return weeklyData.cast<Map<String, Object?>>();
      case _TimePeriod.monthly:
        return monthlyData.cast<Map<String, Object?>>();
    }
  }

  String get totalEarnings {
    switch (timePeriod) {
      case _TimePeriod.daily:
        return '₹1,628';
      case _TimePeriod.weekly:
        return '₹10,560';
      case _TimePeriod.monthly:
        return '₹36,000';
    }
  }

  String get comparisonText {
    switch (timePeriod) {
      case _TimePeriod.daily:
        return 'vs yesterday';
      case _TimePeriod.weekly:
        return 'vs last week';
      case _TimePeriod.monthly:
        return 'vs last month';
    }
  }

  @override
  Widget build(BuildContext context) {
    final periodLabel = {
      _TimePeriod.daily: 'Daily',
      _TimePeriod.weekly: 'Weekly',
      _TimePeriod.monthly: 'Monthly',
    }[timePeriod]!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Earnings'),
        leading: IconButton(
          onPressed: widget.onBack ?? () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        actions: [
          IconButton(
          onPressed: () {}, // Change this to your calendar logic if needed
          icon: const Icon(Icons.calendar_month),
          ),
        ],
      ),
      body: SafeArea(
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
                            const Text('Total Earnings',
                                style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            Text(
                              totalEarnings,
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
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.trending_up, size: 14, color: Colors.green),
                            SizedBox(width: 6),
                            Text('+12.5%', style: TextStyle(color: Colors.green, fontWeight: FontWeight.w800)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        comparisonText,
                        style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w700),
                      ),
                    ],
                  )
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Tabs: daily/weekly/monthly
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
                  const Text('Earnings Overview', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 180,
                    child: _EarningsChart(data: chartData),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Online time / distance placeholders
            Row(
              children: [
                Expanded(
                  child: _SmallMetric(
                    icon: Icons.access_time,
                    label: 'Online Time',
                    value: '8h 32m',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SmallMetric(
                    icon: Icons.place,
                    label: 'Distance',
                    value: '124 km',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Performance
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
                  Row(
                    children: [
                      const Text('Performance', style: TextStyle(fontWeight: FontWeight.w900)),
                      const Spacer(),
                      TextButton(onPressed: () {}, child: const Text('Details')),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _PerfStat(label: 'Acceptance Rate', value: '94%', trend: '+2%', positive: true),
                      _PerfStat(label: 'Completion Rate', value: '98%', trend: '+1%', positive: true),
                      _PerfStat(label: 'Avg Rating', value: '4.92', trend: '+0.05', positive: true),
                      _PerfStat(label: 'Cancellation', value: '2%', trend: '-1%', positive: true),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Recent payouts
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
                  Row(
                    children: [
                      const Text('Recent Payouts', style: TextStyle(fontWeight: FontWeight.w900)),
                      const Spacer(),
                      TextButton(
                        onPressed: () {},
                        child: const Row(
                          children: [
                            Text('View all', style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.w700)),
                            Icon(Icons.chevron_right, color: Colors.indigo),
                          ],
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 10),
                  ...recentPayouts.map((p) {
                    final status = p['status'] as String;
                    final isPending = status == 'pending';
                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
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
                            child: const Icon(Icons.attach_money, color: Colors.indigo),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p['date'] as String, style: const TextStyle(fontWeight: FontWeight.w900)),
                                const SizedBox(height: 4),
                                Text(
                                  '${p['trips']} trips',
                                  style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '₹${p['amount']}',
                                style: const TextStyle(fontWeight: FontWeight.w900),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: isPending ? Colors.orange.withOpacity(0.12) : Colors.green.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  isPending ? 'Pending' : 'Paid',
                                  style: TextStyle(
                                    color: isPending ? Colors.orange.shade800 : Colors.green.shade700,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 12,
                                  ),
                                ),
                              )
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList()
                ],
              ),
            ),

            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
                child: const Text(
                  'Withdraw to Bank',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PeriodChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PeriodChip({required this.label, required this.selected, required this.onTap});

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
        .map((e) => (e['earnings'] as num).toDouble())
        .toList(growable: false);
    final maxValue = earningsValues.isEmpty ? 1 : earningsValues.reduce((a, b) => a > b ? a : b);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(data.length, (i) {
        final value = earningsValues[i];
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
                  data[i]['name'] as String,
                  style: const TextStyle(color: Colors.black54, fontSize: 11, fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                )
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

  const _SmallMetric({required this.icon, required this.label, required this.value});

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
          Row(children: [
            Icon(icon, size: 16, color: Colors.indigo),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w700, fontSize: 12)),
          ]),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          const Text('Today', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w700, fontSize: 12)),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w700, fontSize: 12)),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: positive ? Colors.green.withOpacity(0.12) : Colors.red.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      positive ? Icons.trending_up : Icons.trending_down,
                      size: 14,
                      color: positive ? Colors.green.shade700 : Colors.red.shade700,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      trend,
                      style: TextStyle(
                        color: positive ? Colors.green.shade700 : Colors.red.shade700,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ],
      ),
    );
  }
}
