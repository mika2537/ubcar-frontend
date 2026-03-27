import 'package:flutter/material.dart';

enum _NotificationType { ride, payment, promo, rating, alert, message }
enum _NotificationFilter { all, unread, rides, payments }

class _Notification {
  final String id;
  final _NotificationType type;
  final String title;
  final String message;
  final String time;
  final bool read;
  final String? action;

  const _Notification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.time,
    required this.read,
    this.action,
  });
}

class NotificationCenterScreen extends StatefulWidget {
  final String role; // passenger | driver
  final VoidCallback? onBack;

  const NotificationCenterScreen({
    super.key,
    this.role = 'passenger',
    this.onBack,
  });

  @override
  State<NotificationCenterScreen> createState() => _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  late List<_Notification> notifications;
  _NotificationFilter filter = _NotificationFilter.all;
  bool showSettings = false;
  bool pushEnabled = true;

  @override
  void initState() {
    super.initState();
    notifications = const [
      _Notification(
        id: '1',
        type: _NotificationType.ride,
        title: 'Ride Completed',
        message: 'Your trip to Park Street Metro has been completed. Total fare: ₹180',
        time: '2 min ago',
        read: false,
        action: 'Rate your ride',
      ),
      _Notification(
        id: '2',
        type: _NotificationType.promo,
        title: 'Weekend Special!',
        message: 'Get 25% off on your next 3 rides. Use code WEEKEND25',
        time: '15 min ago',
        read: false,
        action: 'Apply Now',
      ),
      _Notification(
        id: '3',
        type: _NotificationType.payment,
        title: 'Payment Successful',
        message: 'Your wallet has been topped up with ₹500. New balance: ₹1,240',
        time: '1 hour ago',
        read: false,
      ),
      _Notification(
        id: '4',
        type: _NotificationType.rating,
        title: 'You received a 5-star rating!',
        message: 'Amit Kumar rated your ride 5 stars: "Great driver, very punctual!"',
        time: '2 hours ago',
        read: true,
      ),
      _Notification(
        id: '5',
        type: _NotificationType.alert,
        title: 'Safety Alert',
        message: 'Heavy traffic reported on your usual route.',
        time: '3 hours ago',
        read: true,
      ),
      _Notification(
        id: '6',
        type: _NotificationType.ride,
        title: 'Ride Cancelled',
        message: 'Your scheduled ride to Airport has been cancelled.',
        time: '5 hours ago',
        read: true,
        action: 'Book Again',
      ),
      _Notification(
        id: '7',
        type: _NotificationType.message,
        title: 'Message from Driver',
        message: 'Hi! I am waiting at the pickup point.',
        time: 'Yesterday',
        read: true,
      ),
    ];
  }

  int get unreadCount => notifications.where((n) => !n.read).length;

  List<_Notification> get filteredNotifications {
    switch (filter) {
      case _NotificationFilter.all:
        return notifications;
      case _NotificationFilter.unread:
        return notifications.where((n) => !n.read).toList();
      case _NotificationFilter.rides:
        return notifications.where((n) => n.type == _NotificationType.ride).toList();
      case _NotificationFilter.payments:
        return notifications.where((n) => n.type == _NotificationType.payment).toList();
    }
  }

  IconData _iconForType(_NotificationType type) {
    switch (type) {
      case _NotificationType.ride:
        return Icons.directions_car;
      case _NotificationType.payment:
        return Icons.wallet;
      case _NotificationType.promo:
        return Icons.card_giftcard;
      case _NotificationType.rating:
        return Icons.star;
      case _NotificationType.alert:
        return Icons.warning_amber;
      case _NotificationType.message:
        return Icons.message;
    }
  }

  Color _colorForType(_NotificationType type) {
    switch (type) {
      case _NotificationType.ride:
        return Colors.indigo;
      case _NotificationType.payment:
        return Colors.green;
      case _NotificationType.promo:
        return Colors.orange;
      case _NotificationType.rating:
        return Colors.amber.shade700;
      case _NotificationType.alert:
        return Colors.red;
      case _NotificationType.message:
        return Colors.blue;
    }
  }

  void markAsRead(String id) {
    setState(() {
      notifications = notifications
          .map((n) => n.id == id ? _Notification(id: n.id, type: n.type, title: n.title, message: n.message, time: n.time, read: true, action: n.action) : n)
          .toList();
    });
  }

  void markAllAsRead() {
    setState(() {
      notifications = notifications
          .map((n) => _Notification(id: n.id, type: n.type, title: n.title, message: n.message, time: n.time, read: true, action: n.action))
          .toList();
    });
  }

  void deleteNotification(String id) {
    setState(() {
      notifications = notifications.where((n) => n.id != id).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.grey.shade200,
                          shape: const CircleBorder(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Row(
                          children: [
                            const Text(
                              'Notifications',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                            ),
                            if (unreadCount > 0) ...[
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.indigo,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  '$unreadCount',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12),
                                ),
                              ),
                            ]
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => setState(() => showSettings = !showSettings),
                        icon: const Icon(Icons.settings),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.grey.shade200,
                          shape: const CircleBorder(),
                        ),
                      ),
                    ],
                  ),
                ),

                if (!pushEnabled)
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.10),
                      border: Border.all(color: Colors.red.withOpacity(0.20)),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.notifications_off, color: Colors.red),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text('Push notifications are off', style: TextStyle(fontWeight: FontWeight.w900)),
                              SizedBox(height: 4),
                              Text('You may miss important updates about your rides', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () => setState(() => pushEnabled = true),
                          child: const Text('Enable', style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.w900)),
                        ),
                      ],
                    ),
                  ),

                // Filter chips
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _FilterChip(
                          label: 'All',
                          selected: filter == _NotificationFilter.all,
                          onTap: () => setState(() => filter = _NotificationFilter.all),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Unread',
                          selected: filter == _NotificationFilter.unread,
                          onTap: () => setState(() => filter = _NotificationFilter.unread),
                          badge: unreadCount > 0 ? '$unreadCount' : null,
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Rides',
                          selected: filter == _NotificationFilter.rides,
                          onTap: () => setState(() => filter = _NotificationFilter.rides),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Payments',
                          selected: filter == _NotificationFilter.payments,
                          onTap: () => setState(() => filter = _NotificationFilter.payments),
                        ),
                      ],
                    ),
                  ),
                ),

                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                    children: [
                      if (filteredNotifications.isEmpty)
                        const SizedBox(
                          height: 200,
                          child: Center(
                            child: Text(
                              "You're all caught up! Check back later.",
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w700),
                            ),
                          ),
                        )
                      else
                        ...filteredNotifications.map((n) {
                          final c = _colorForType(n.type);
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: n.read ? Colors.white : Colors.indigo.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(color: n.read ? Colors.grey.shade200 : Colors.indigo.withOpacity(0.25)),
                            ),
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              onTap: () => markAsRead(n.id),
                              leading: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: c.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(_iconForType(n.type), color: c),
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      n.title,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        color: n.read ? Colors.black87 : Colors.indigo,
                                      ),
                                    ),
                                  ),
                                  if (!n.read)
                                    Container(
                                      width: 10,
                                      height: 10,
                                      decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.indigo),
                                    ),
                                ],
                              ),
                              subtitle: Text(
                                n.message,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.black54,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              trailing: IconButton(
                                onPressed: () => deleteNotification(n.id),
                                icon: const Icon(Icons.close),
                                color: Colors.black54,
                              ),
                            ),
                          );
                        }).toList(),
                    ],
                  ),
                ),

                Container(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                  child: SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.notifications),
                      label: const Text('Test Push Notification', style: TextStyle(fontWeight: FontWeight.w900)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade200,
                        foregroundColor: Colors.black87,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            if (showSettings)
              Positioned(
                right: 16,
                top: 86,
                child: Container(
                  width: 260,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 14,
                        color: Colors.black12,
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Settings', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(pushEnabled ? Icons.notifications : Icons.notifications_off, color: Colors.indigo),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Push Notifications',
                              style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w700),
                            ),
                          ),
                          Switch(
                            value: pushEnabled,
                            onChanged: (v) => setState(() => pushEnabled = v),
                          )
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () {
                          markAllAsRead();
                          setState(() => showSettings = false);
                        },
                        child: const Text('Mark all as read', style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.w900)),
                      ),
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => setState(() => showSettings = false),
                          child: const Text('Close', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w700)),
                        ),
                      )
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final String? badge;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Row(
        children: [
          Text(label),
          if (badge != null) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: selected ? Colors.indigo.withOpacity(0.12) : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                badge!,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ],
      ),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: Colors.indigo.withOpacity(0.12),
      backgroundColor: Colors.grey.shade200,
    );
  }
}
