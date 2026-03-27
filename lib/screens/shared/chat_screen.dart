import 'dart:async';

import 'package:flutter/material.dart';

enum _Sender { me, other }
enum _MessageType { text, location }
enum _MessageStatus { sent, delivered, read }

class _ChatMessage {
  final String messageId;
  final String roomId;
  final _Sender sender;
  final String text;
  final String timestamp;
  final _MessageStatus status;
  final _MessageType type;

  const _ChatMessage({
    required this.messageId,
    required this.roomId,
    required this.sender,
    required this.text,
    required this.timestamp,
    required this.status,
    required this.type,
  });
}

class ChatScreen extends StatefulWidget {
  final String role; // 'passenger' | 'driver'
  final String contactName;
  final String? contactRole;
  final double contactRating;
  final String? rideId;
  final String? tripInfo;
  final VoidCallback? onBack;
  final VoidCallback? onCall;
  final VoidCallback? onVideoCall;

  const ChatScreen({
    super.key,
    this.role = 'passenger',
    this.contactName = 'Amit Kumar',
    this.contactRole,
    this.contactRating = 4.9,
    this.rideId,
    this.tripInfo,
    this.onBack,
    this.onCall,
    this.onVideoCall,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final String resolvedContactRole;
  late final String resolvedTripInfo;

  final _scrollController = ScrollController();

  late List<_ChatMessage> messages;
  bool isTyping = false;
  final _inputController = TextEditingController();

  @override
  void initState() {
    super.initState();

    resolvedContactRole = widget.contactRole ??
        (widget.role == 'passenger' ? 'Driver' : 'Passenger');
    resolvedTripInfo = widget.tripInfo ??
        'Active Trip • Salt Lake → Park Street';

    final roomId = widget.rideId ?? 'room1';
    messages = [
      _ChatMessage(
        messageId: '1',
        roomId: roomId,
        sender: _Sender.other,
        text: "Hello! I'm on my way to the pickup point.",
        timestamp: '10:30 AM',
        status: _MessageStatus.read,
        type: _MessageType.text,
      ),
      _ChatMessage(
        messageId: '2',
        roomId: roomId,
        sender: _Sender.me,
        text: "Great, I'm waiting near the main gate.",
        timestamp: '10:31 AM',
        status: _MessageStatus.read,
        type: _MessageType.text,
      ),
      _ChatMessage(
        messageId: '3',
        roomId: roomId,
        sender: _Sender.other,
        text: "I'm in a white Suzuki Swift, plate WB 12 AB 3456",
        timestamp: '10:32 AM',
        status: _MessageStatus.read,
        type: _MessageType.text,
      ),
      _ChatMessage(
        messageId: '4',
        roomId: roomId,
        sender: _Sender.me,
        text: 'Got it, I can see you approaching!',
        timestamp: '10:33 AM',
        status: _MessageStatus.delivered,
        type: _MessageType.text,
      ),
      _ChatMessage(
        messageId: '5',
        roomId: roomId,
        sender: _Sender.other,
        text: '📍 Shared live location',
        timestamp: '10:33 AM',
        status: _MessageStatus.read,
        type: _MessageType.location,
      ),
    ];

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _inputController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  void _sendMessage() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    final roomId = widget.rideId ?? 'room1';
    final now = TimeOfDay.now();
    final timestamp = '${now.format(context)}';

    final newMsg = _ChatMessage(
      messageId: DateTime.now().millisecondsSinceEpoch.toString(),
      roomId: roomId,
      sender: _Sender.me,
      text: text,
      timestamp: timestamp,
      status: _MessageStatus.sent,
      type: _MessageType.text,
    );

    setState(() {
      messages = [...messages, newMsg];
      _inputController.clear();
      isTyping = false;
    });
    _scrollToBottom();

    // Simulate reply like React.
    Timer(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() => isTyping = true);
    });

    Timer(const Duration(milliseconds: 2500), () {
      if (!mounted) return;

      const replies = [
        'Okay, noted! 👍',
        "Sure, I'll be there shortly.",
        'No problem at all!',
        'Thanks for letting me know.',
        'On my way! 🚗',
      ];
      final replyText = replies[(DateTime.now().millisecondsSinceEpoch) % replies.length];

      setState(() {
        // Mark previous message as read-ish.
        messages = messages.map((m) {
          if (m.messageId == newMsg.messageId) {
            return _ChatMessage(
              messageId: m.messageId,
              roomId: m.roomId,
              sender: m.sender,
              text: m.text,
              timestamp: m.timestamp,
              status: _MessageStatus.read,
              type: m.type,
            );
          }
          return m;
        }).toList();

        messages = [
          ...messages,
          _ChatMessage(
            messageId: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
            roomId: roomId,
            sender: _Sender.other,
            text: replyText,
            timestamp: timestamp,
            status: _MessageStatus.read,
            type: _MessageType.text,
          ),
        ];
        isTyping = false;
      });
      _scrollToBottom();
    });
  }

  String get _typingText => 'typing...';

  String _statusIconText(_MessageStatus status) {
    switch (status) {
      case _MessageStatus.read:
        return '✓✓';
      case _MessageStatus.delivered:
        return '✓✓';
      case _MessageStatus.sent:
        return '✓';
    }
  }

  @override
  Widget build(BuildContext context) {
    final quickReplies = [
      "I'm here",
      'On my way',
      'Running late',
      'Share location',
    ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              color: Colors.white,
              child: Row(
                children: [
                  IconButton(
                    onPressed: widget.onBack,
                    icon: const Icon(Icons.arrow_back),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.grey.shade200,
                      shape: const CircleBorder(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.indigo.withOpacity(0.20),
                    child: Text(
                      widget.contactName.isNotEmpty
                          ? widget.contactName.split(' ').map((s) => s.isEmpty ? '' : s[0]).join().toUpperCase()
                          : '?',
                      style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.indigo),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.contactName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w900),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.indigo.withOpacity(0.10),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                resolvedContactRole,
                                style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.w900, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isTyping ? _typingText : resolvedTripInfo,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w700, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: widget.onCall,
                        icon: const Icon(Icons.phone),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.grey.shade100,
                          shape: const CircleBorder(),
                        ),
                      ),
                      IconButton(
                        onPressed: widget.onVideoCall,
                        icon: const Icon(Icons.videocam),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.grey.shade100,
                          shape: const CircleBorder(),
                        ),
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.more_vert),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.grey.shade100,
                          shape: const CircleBorder(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Trip info bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              color: Colors.indigo.withOpacity(0.08),
              width: double.infinity,
              child: Row(
                children: [
                  const Icon(Icons.location_on, size: 18, color: Colors.indigo),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      resolvedTripInfo,
                      style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.w700, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // Messages
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(12, 14, 12, 6),
                itemCount: messages.length + (isTyping ? 1 : 0),
                itemBuilder: (context, index) {
                  if (isTyping && index == messages.length) {
                    return Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              Container(width: 6, height: 6, decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.grey)),
                              const SizedBox(width: 6),
                              Container(width: 6, height: 6, decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.grey)),
                              const SizedBox(width: 6),
                              Container(width: 6, height: 6, decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.grey)),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  final msg = messages[index];
                  final isMe = msg.sender == _Sender.me;
                  final bubbleColor = isMe ? Colors.indigo : Colors.white;
                  final bubbleTextColor = isMe ? Colors.white : Colors.black87;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 260),
                        child: Column(
                          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: bubbleColor,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(18),
                                  topRight: const Radius.circular(18),
                                  bottomLeft: isMe ? const Radius.circular(18) : const Radius.circular(6),
                                  bottomRight: isMe ? const Radius.circular(6) : const Radius.circular(18),
                                ),
                              ),
                              child: msg.type == _MessageType.location
                                  ? Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(Icons.location_on,
                                                size: 16,
                                                color: isMe ? Colors.white : Colors.indigo),
                                            const SizedBox(width: 6),
                                            Text(
                                              'Live Location',
                                              style: TextStyle(
                                                color: bubbleTextColor,
                                                fontWeight: FontWeight.w900,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Container(
                                          height: 70,
                                          width: double.infinity,
                                          decoration: BoxDecoration(
                                            color: isMe ? Colors.white.withOpacity(0.12) : Colors.grey.shade100,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: const Center(
                                            child: Icon(Icons.place, size: 28, color: Colors.indigo),
                                          ),
                                        ),
                                      ],
                                    )
                                  : Text(
                                      msg.text,
                                      style: TextStyle(
                                        color: bubbleTextColor,
                                        fontSize: 13,
                                        height: 1.3,
                                      ),
                                    ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  msg.timestamp,
                                  style: TextStyle(
                                    color: isMe ? Colors.white70 : Colors.black54,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if (isMe) ...[
                                  const SizedBox(width: 6),
                                  Text(
                                    _statusIconText(msg.status),
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ],
                            )
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Quick replies
            SizedBox(
              height: 44,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: quickReplies.length,
                itemBuilder: (context, i) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: ActionChip(
                      label: Text(quickReplies[i]),
                      onPressed: () {
                        _inputController.text = quickReplies[i];
                        setState(() {});
                      },
                    ),
                  );
                },
              ),
            ),

            // Input bar
            Container(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
              color: Colors.white,
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.emoji_emotions_outlined),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.grey.shade100,
                      shape: const CircleBorder(),
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.image_outlined),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.grey.shade100,
                      shape: const CircleBorder(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: TextField(
                        controller: _inputController,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                        decoration: const InputDecoration(
                          hintText: 'Type a message...',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _inputController.text.trim().isEmpty ? null : _sendMessage,
                    icon: Icon(
                      _inputController.text.trim().isEmpty ? Icons.mic : Icons.send,
                      color: _inputController.text.trim().isEmpty ? Colors.indigo : Colors.white,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      shape: const CircleBorder(),
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
}
