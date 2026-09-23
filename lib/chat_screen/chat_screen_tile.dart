import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import '../app_config.dart'; // still used for image URLs
import '../supabase_client.dart';
import 'chatscreen.dart' show ProviderChatMessageScreen;

const Color _primary = Color(0xFF33365D);
const Color _accent = Color(0xFF8B5CF6); // Nearfix Purple
const Color _bg = Color(0xFFF4F5FB);

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<dynamic> _chatList = [];
  bool _isLoading = true;
  int? _currentUserId;

  final String _baseUrl = "${AppConfig.baseUrl}/";

  @override
  void initState() {
    super.initState();
    _loadUserAndChats();
  }

  Future<void> _loadUserAndChats() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentUserId = prefs.getInt('provider_id') ?? prefs.getInt('user_id');
    });
    _fetchChatList();
  }

  Future<void> _fetchChatList() async {
    if (_currentUserId == null) return;

    try {
      final data = await supabase
          .rpc('get_chat_list', params: {'p_user_id': _currentUserId});
      setState(() {
        _chatList = data ?? [];
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Chat List Error: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          // ── Header ──────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(20, topPad + 15, 20, 25),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1C1F3E), Color(0xFF33365D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Messages",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() => _isLoading = true);
                    _fetchChatList();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.refresh_rounded, size: 20, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),

          // ── Body ─────────────────────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: _primary))
                : _chatList.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
              color: _primary,
              onRefresh: _fetchChatList,
              child: ListView.separated(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                itemCount: _chatList.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final chat = _chatList[index];

                  int pId = 0;
                  int unreadCount = 0;
                  try {
                    pId = int.parse(chat['contact_id'].toString());
                    unreadCount = int.parse(chat['unread_count']?.toString() ?? "0");
                  } catch (e) {
                    debugPrint("ID Parsing Error: $e");
                  }

                  return _ChatCard(
                    currentUserId: _currentUserId ?? 0,
                    peerId: pId,
                    name: chat['contact_name'] ?? "User",
                    message: chat['message'] ?? "",
                    time: chat['created_at'] ?? "",
                    imageUrl: chat['contact_image'],
                    baseUrl: _baseUrl,
                    unreadCount: unreadCount, // Passing unread count here
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.chat_bubble_outline_rounded, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text("No conversations found",
              style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A1C3A), fontSize: 16)),
          const Text("New messages from bookings will appear here",
              style: TextStyle(color: Colors.grey, fontSize: 13)),
        ],
      ),
    );
  }
}

class _ChatCard extends StatelessWidget {
  final int currentUserId;
  final int peerId;
  final String name;
  final String message;
  final String time;
  final String? imageUrl;
  final String baseUrl;
  final int unreadCount;

  const _ChatCard({
    required this.currentUserId,
    required this.peerId,
    required this.name,
    required this.message,
    required this.time,
    required this.baseUrl,
    this.imageUrl,
    this.unreadCount = 0,
  });

  String _formatTime(String raw) {
    if (raw.isEmpty) return "";
    try {
      DateTime dt = DateTime.parse(raw);
      if (DateTime.now().day == dt.day) {
        return DateFormat('hh:mm a').format(dt);
      } else {
        return DateFormat('dd MMM').format(dt);
      }
    } catch (_) {
      return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isUnread = unreadCount > 0;
    final String fullImageUrl = imageUrl != null && imageUrl!.isNotEmpty
        ? (imageUrl!.startsWith('http') ? imageUrl! : "$baseUrl$imageUrl")
        : "";
    final String initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : "?";

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () {
          if (peerId == 0) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProviderChatMessageScreen(
                currentUserId: currentUserId,
                peerId: peerId,
                peerName: name,
                peerImageUrl: fullImageUrl,
              ),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: isUnread
                ? Border.all(color: _primary.withOpacity(0.16), width: 1.4)
                : Border.all(color: Colors.black.withOpacity(0.04), width: 1),
            boxShadow: [
              BoxShadow(
                color: isUnread
                    ? _primary.withOpacity(0.14)
                    : Colors.black.withOpacity(0.045),
                blurRadius: isUnread ? 20 : 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar with a gradient ring when there's something unread
              Container(
                padding: EdgeInsets.all(isUnread ? 2.5 : 0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: isUnread
                      ? LinearGradient(colors: [_primary, _accent])
                      : null,
                ),
                child: CircleAvatar(
                  radius: 27,
                  backgroundColor: _primary.withOpacity(0.10),
                  backgroundImage:
                      fullImageUrl.isNotEmpty ? NetworkImage(fullImageUrl) : null,
                  child: fullImageUrl.isEmpty
                      ? Text(
                          initial,
                          style: TextStyle(
                            color: _primary,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: isUnread ? FontWeight.w800 : FontWeight.w700,
                              color: const Color(0xFF1A1C3A),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatTime(time),
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: isUnread ? _primary : Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            message,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: isUnread ? FontWeight.w600 : FontWeight.w400,
                              color: isUnread ? const Color(0xFF3A3D5C) : Colors.grey[600],
                            ),
                          ),
                        ),
                        if (isUnread) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [_primary, _accent]),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              unreadCount > 9 ? "9+" : "$unreadCount",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
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
