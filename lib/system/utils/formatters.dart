class Formatters {
  static String formatMoney(double amount, {String currency = 'USD'}) {
    // TODO: localize/format with intl package when you add it.
    return '$currency ${amount.toStringAsFixed(2)}';
  }

  static String formatDateTime(DateTime value) {
    // TODO: replace with intl once you add it.
    final date = '${value.year}-${_two(value.month)}-${_two(value.day)}';
    final time = '${_two(value.hour)}:${_two(value.minute)}';
    return '$date $time';
  }

  static String formatDistanceKm(double km) {
    if (km < 1) return '${(km * 1000).toStringAsFixed(0)} m';
    return '${km.toStringAsFixed(1)} km';
  }

  static String formatPercent(double value) {
    return '${(value * 100).toStringAsFixed(0)}%';
  }

  static String _two(int v) => v.toString().padLeft(2, '0');
}

