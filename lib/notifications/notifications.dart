import 'package:flutter/material.dart';

const Color primaryColor = Color(0xFF33365D);

// ─── Mock Data ────────────────────────────────────────────────────────────────

enum NotifType { chat, booking, reminder }

class AppNotification {
  final NotifType type;
  final String title;
  final String message;
  final String timeAgo;
  bool isRead;

  AppNotification({
    required this.type,
    required this.title,
    required this.message,
    required this.timeAgo,
    this.isRead = false,
  });
}

final List<AppNotification> mockNotifications = [
  AppNotification(
    type: NotifType.booking,
    title: "Booking Confirmed",
    message: "Ramesh Kumar confirmed your AC repair for tomorrow.",
    timeAgo: "2m ago",
    isRead: false,
  ),
  AppNotification(
    type: NotifType.chat,
    title: "New Message",
    message:
        "Ramesh Kumar: I will arrive by 10am, please keep the unit accessible.",
    timeAgo: "10m ago",
    isRead: false,
  ),
  AppNotification(
    type: NotifType.reminder,
    title: "Upcoming Appointment",
    message:
        "You have an AC repair service scheduled for tomorrow at 10:00 AM.",
    timeAgo: "1h ago",
    isRead: false,
  ),
  AppNotification(
    type: NotifType.booking,
    title: "Booking Cancelled",
    message: "Your plumbing service was cancelled by the provider.",
    timeAgo: "3h ago",
    isRead: true,
  ),
  AppNotification(
    type: NotifType.chat,
    title: "New Message",
    message: "Suresh Patel: Can we reschedule to next Monday?",
    timeAgo: "5h ago",
    isRead: true,
  ),
  AppNotification(
    type: NotifType.reminder,
    title: "Don't Forget!",
    message: "Your cleaning service is scheduled for today at 3:00 PM.",
    timeAgo: "Yesterday",
    isRead: true,
  ),
];

// ─── Screen ───────────────────────────────────────────────────────────────────

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  late List<AppNotification> notifications;

  @override
  void initState() {
    super.initState();
    notifications = List.from(mockNotifications);
  }

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  void _markAllRead() {
    setState(() {
      for (var n in notifications) {
        n.isRead = true;
      }
    });
  }

  void _markRead(AppNotification n) {
    setState(() => n.isRead = true);
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  IconData _icon(NotifType type) {
    switch (type) {
      case NotifType.chat:
        return Icons.chat_bubble_rounded;
      case NotifType.booking:
        return Icons.check_circle_rounded;
      case NotifType.reminder:
        return Icons.alarm_rounded;
    }
  }

  Color _color(NotifType type) {
    switch (type) {
      case NotifType.chat:
        return Colors.blue;
      case NotifType.booking:
        return Colors.green;
      case NotifType.reminder:
        return Colors.orange;
    }
  }

  String _label(NotifType type) {
    switch (type) {
      case NotifType.chat:
        return "Chat";
      case NotifType.booking:
        return "Booking";
      case NotifType.reminder:
        return "Reminder";
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final unread = notifications.where((n) => !n.isRead).toList();
    final read = notifications.where((n) => n.isRead).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Notifications",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            if (unreadCount > 0)
              Text(
                "$unreadCount unread",
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
          ],
        ),
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: _markAllRead,
              child: const Text(
                "Mark all read",
                style: TextStyle(color: primaryColor, fontSize: 13),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          // ── Unread Section ──
          if (unread.isNotEmpty) ...[
            _sectionHeader("New"),
            ...unread.map((n) => _tile(n)),
            const SizedBox(height: 8),
          ],

          // ── Read Section ──
          if (read.isNotEmpty) ...[
            _sectionHeader("Earlier"),
            ...read.map((n) => _tile(n)),
          ],
        ],
      ),
    );
  }

  Widget _sectionHeader(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Colors.black45,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _tile(AppNotification notif) {
    final color = _color(notif.type);

    return GestureDetector(
      onTap: () => _markRead(notif),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: notif.isRead ? Colors.white : const Color(0xFFEEEFF8),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: notif.isRead
                ? Colors.transparent
                : primaryColor.withOpacity(0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              CircleAvatar(
                radius: 22,
                backgroundColor: color.withOpacity(0.12),
                child: Icon(_icon(notif.type), color: color, size: 22),
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge + time + unread dot
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _label(notif.type),
                            style: TextStyle(
                              fontSize: 11,
                              color: color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          notif.timeAgo,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                        if (!notif.isRead) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: primaryColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Title
                    Text(
                      notif.title,
                      style: TextStyle(
                        fontWeight: notif.isRead
                            ? FontWeight.w500
                            : FontWeight.bold,
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 3),

                    // Message
                    Text(
                      notif.message,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
