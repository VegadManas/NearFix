import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_config.dart'; // still used for image URLs
import '../supabase_client.dart';

class ProviderChatMessageScreen extends StatefulWidget {
  final int currentUserId;
  final int peerId;
  final String peerName;
  final String? peerImageUrl;

  const ProviderChatMessageScreen({
    super.key,
    required this.currentUserId,
    required this.peerId,
    required this.peerName,
    this.peerImageUrl,
  });

  @override
  State<ProviderChatMessageScreen> createState() => _ProviderChatMessageScreenState();
}

class _ProviderChatMessageScreenState extends State<ProviderChatMessageScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<dynamic> _messages = [];
  Timer? _timer;

  // Provider & Chat State
  String _peerPhone = "Loading...";
  String _peerProfession = "Partner";
  int _peerJobs = 0;
  double _peerRating = 0.0;
  String? _serverImageUrl;
  int _unreadFromPeer = 0; // Tracks unread messages for the AppBar badge

  final String _baseUrl = "${AppConfig.baseUrl}/";

  @override
  void initState() {
    super.initState();
    _fetchMessages();
    _fetchPeerDetails();
    // Polling every 2 seconds to keep chat and read status in sync
    _timer = Timer.periodic(const Duration(seconds: 2), (t) => _fetchMessages());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // --- UTILS: PHONE CALL ---
  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber.replaceAll(RegExp(r'\s+'), ''),
    );
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Could not open dialer")),
          );
        }
      }
    } catch (e) {
      debugPrint("Call Error: $e");
    }
  }

  // --- API: FETCH PROVIDER DETAILS ---
  Future<void> _fetchPeerDetails() async {
    try {
      final response = await supabase
          .rpc('get_provider_profile', params: {'p_provider_id': widget.peerId});

      if (response['success'] == true) {
        setState(() {
          _peerPhone = response['data']['phone'] ?? "N/A";
          _peerProfession = response['data']['category'] ?? "Partner";
          _peerJobs = response['data']['total_jobs'] ?? 0;
          _peerRating = (response['data']['rating'] ?? 0.0).toDouble();

          String rawImg = response['data']['photo'] ?? "";
          if (rawImg.isNotEmpty) {
            _serverImageUrl = rawImg.startsWith('http') ? rawImg : "$_baseUrl$rawImg";
          }
        });
      }
    } catch (e) {
      debugPrint("Detail Fetch Error: $e");
    }
  }

  // --- API: CHAT LOGIC ---
  Future<void> _fetchMessages() async {
    try {
      final data = await supabase.rpc('fetch_conversation', params: {
        'p_user1': widget.currentUserId,
        'p_user2': widget.peerId,
      });

      if (data['success'] == true) {
        // Update unread count and message list
        setState(() {
          _unreadFromPeer = data['unread_count'] ?? 0;
          // Only update UI if message count changed or read status changed
          _messages = data['data'];
        });

        // Auto-scroll on new messages
        if (_scrollController.hasClients) {
          _scrollToBottom();
        }
      }
    } catch (e) {
      debugPrint("Chat Fetch Error: $e");
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    final text = _messageController.text.trim();
    _messageController.clear();
    try {
      await supabase.from('messages').insert({
        "sender_id": widget.currentUserId,
        "receiver_id": widget.peerId,
        "message": text,
      });
      _fetchMessages();
    } catch (e) {
      debugPrint("Send Error: $e");
    }
  }

  // --- UI: PROVIDER MODAL ---
  void _showProviderDetails() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 24),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.2), width: 2)),
                  child: CircleAvatar(
                    radius: 35,
                    backgroundColor: const Color(0xFFF3E5F5),
                    backgroundImage: (_serverImageUrl ?? widget.peerImageUrl) != null
                        ? NetworkImage(_serverImageUrl ?? widget.peerImageUrl!)
                        : null,
                    child: (_serverImageUrl == null && widget.peerImageUrl == null)
                        ? Text(widget.peerName[0], style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF8B5CF6)))
                        : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.peerName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF1A1C3A))),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: const Color(0xFF8B5CF6).withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                        child: Text(_peerProfession.trim(), style: const TextStyle(color: Color(0xFF8B5CF6), fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: const Color(0xFFF8F9FE), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFEEEFF8))),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _statTile(Icons.star_rounded, "$_peerRating", "Rating", Colors.amber),
                  Container(height: 30, width: 1, color: Colors.grey[300]),
                  _statTile(Icons.check_circle_rounded, "$_peerJobs", "Jobs", Colors.blue),
                  Container(height: 30, width: 1, color: Colors.grey[300]),
                  _statTile(Icons.verified_rounded, "Pro", "Status", Colors.green),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(backgroundColor: Color(0xFFF4F5FB), child: Icon(Icons.phone_android, color: Colors.black87, size: 20)),
              title: const Text("Contact Number", style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
              subtitle: Text(_peerPhone, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black)),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: () {
                  if (_peerPhone != "Loading..." && _peerPhone != "N/A") {
                    _makePhoneCall(_peerPhone);
                  }
                },
                icon: const Icon(Icons.call, color: Colors.white),
                label: const Text("Call Partner", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 15),
          ],
        ),
      ),
    );
  }

  Widget _statTile(IconData icon, String val, String label, Color col) => Column(
    children: [
      Icon(icon, color: col, size: 22),
      Text(val, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
      Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.w600)),
    ],
  );

  // --- MAIN BUILD ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black),
        title: GestureDetector(
          onTap: _showProviderDetails,
          behavior: HitTestBehavior.opaque,
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFFF4F5FB),
                backgroundImage: (_serverImageUrl ?? widget.peerImageUrl) != null
                    ? NetworkImage(_serverImageUrl ?? widget.peerImageUrl!)
                    : null,
                child: (_serverImageUrl == null && widget.peerImageUrl == null) ? Text(widget.peerName[0]) : null,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(widget.peerName, style: const TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.bold)),
                      if (_unreadFromPeer > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
                          child: Text("$_unreadFromPeer", style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ],
                  ),
                  const Text("Online • View Profile", style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? const Center(child: Text("No messages yet", style: TextStyle(color: Colors.grey)))
                : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                bool isMe = msg['sender_id'].toString() == widget.currentUserId.toString();
                return _buildBubble(msg, isMe);
              },
            ),
          ),
          _buildInput(),
        ],
      ),
    );
  }

  Widget _buildBubble(dynamic msgData, bool isMe) {
    String message = msgData['message'] ?? "";
    String rawTime = msgData['created_at'] ?? "";
    bool isRead = msgData['is_read'].toString() == "1";

    String formattedTime = "";
    if (rawTime.isNotEmpty) {
      try {
        DateTime dt = DateTime.parse(rawTime);
        formattedTime = DateFormat('hh:mm a').format(dt);
      } catch (_) {}
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
            decoration: BoxDecoration(
              color: isMe ? const Color(0xFF33365D) : const Color(0xFFF1F2F7),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
                bottomRight: isMe ? Radius.zero : const Radius.circular(16),
              ),
            ),
            child: Text(message, style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 14)),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0, left: 4, right: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(formattedTime, style: const TextStyle(fontSize: 9, color: Colors.grey)),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    isRead ? Icons.done_all_rounded : Icons.done_rounded,
                    size: 14,
                    color: isRead ? const Color(0xFF8B5CF6) : Colors.grey,
                  ),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput() => Container(
    padding: const EdgeInsets.fromLTRB(16, 8, 8, 20),
    decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey[200]!))),
    child: Row(children: [
      Expanded(child: TextField(
        controller: _messageController,
        decoration: InputDecoration(
          hintText: "Write a message...",
          filled: true,
          fillColor: const Color(0xFFF4F5FB),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
        ),
      )),
      const SizedBox(width: 8),
      CircleAvatar(
        backgroundColor: const Color(0xFF33365D),
        child: IconButton(icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20), onPressed: _sendMessage),
      ),
    ]),
  );
}