import 'package:flutter/material.dart';

import '../../system/localization/app_localizations.dart';
import '../../system/models/chat_message_model.dart';
import '../../system/models/trip_model.dart';
import '../../system/models/user_model.dart';
import '../../system/services/backend_api_service.dart';

class ChatScreen extends StatefulWidget {
  final String role;
  final String contactName;
  final String? contactRole;
  final String? rideId;
  final String? tripInfo;
  final VoidCallback? onBack;
  final VoidCallback? onCall;
  final VoidCallback? onVideoCall;

  const ChatScreen({
    super.key,
    this.role = 'passenger',
    this.contactName = '',
    this.contactRole,
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
  final _api = BackendApiService();
  final _scrollController = ScrollController();
  final _inputController = TextEditingController();

  UserModel? _currentUser;
  UserModel? _contact;
  TripModel? _trip;
  List<ChatMessageModel> _messages = const [];
  bool _isLoading = true;
  bool _isSending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadChat();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _inputController.dispose();
    super.dispose();
  }

  Future<void> _loadChat() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final currentUser = await _api.getCurrentUser();
      if (currentUser == null) {
        throw Exception('Please sign in again.');
      }
      if (widget.rideId == null || widget.rideId!.isEmpty) {
        throw Exception('Trip ID is required to load chat.');
      }

      final trips = await _api.getTripsForUser(currentUser.id);
      final trip = trips.cast<TripModel?>().firstWhere(
        (item) => item?.id == widget.rideId,
        orElse: () => null,
      );
      if (trip == null) {
        throw Exception('Trip not found for this user.');
      }

      final contactId = currentUser.role == 'driver'
          ? trip.passengerId
          : trip.driverId;
      final contact = contactId == null
          ? null
          : await _api.getUserProfile(contactId);
      final messages = await _api.getChatMessages(tripId: widget.rideId!);

      if (!mounted) {
        return;
      }
      setState(() {
        _currentUser = currentUser;
        _trip = trip;
        _contact = contact;
        _messages = messages;
        _isLoading = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
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

  Future<void> _sendMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty ||
        _currentUser == null ||
        widget.rideId == null ||
        _isSending) {
      return;
    }

    setState(() => _isSending = true);
    try {
      await _api.sendChatMessage(
        tripId: widget.rideId!,
        senderId: _currentUser!.id,
        message: text,
      );
      _inputController.clear();
      await _loadChat();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) {
      return;
    }
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: widget.onBack ?? () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back),
          ),
        ),
        body: Center(
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
                  onPressed: _loadChat,
                  child: Text(context.l10n.text('tryAgain')),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final contactName = widget.contactName.isNotEmpty
        ? widget.contactName
        : (_contact?.name?.isNotEmpty == true
              ? _contact!.name!
              : (_contact?.email ?? 'Contact'));
    final contactRole =
        widget.contactRole ??
        (_contact?.role == 'driver' ? 'Driver' : 'Passenger');
    final tripInfo =
        widget.tripInfo ??
        '${_trip?.route?.from ?? 'Pickup'} → ${_trip?.route?.to ?? 'Destination'}';

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              color: Colors.white,
              child: Row(
                children: [
                  IconButton(
                    onPressed:
                        widget.onBack ?? () => Navigator.of(context).pop(),
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
                      contactName.isNotEmpty
                          ? contactName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: Colors.indigo,
                      ),
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
                                contactName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.indigo.withOpacity(0.10),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                contactRole,
                                style: const TextStyle(
                                  color: Colors.indigo,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          tripInfo,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.black54,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: widget.onCall,
                    icon: const Icon(Icons.phone),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.grey.shade100,
                      shape: const CircleBorder(),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _messages.isEmpty
                  ? const Center(
                      child: Text(
                        'No chat messages yet for this trip.',
                        style: TextStyle(
                          color: Colors.black54,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(12, 14, 12, 6),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        final isMe = message.senderId == _currentUser?.id;
                        final bubbleColor = isMe ? Colors.indigo : Colors.white;
                        final bubbleTextColor = isMe
                            ? Colors.white
                            : Colors.black87;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Align(
                            alignment: isMe
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 260),
                              child: Column(
                                crossAxisAlignment: isMe
                                    ? CrossAxisAlignment.end
                                    : CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: bubbleColor,
                                      borderRadius: BorderRadius.only(
                                        topLeft: const Radius.circular(18),
                                        topRight: const Radius.circular(18),
                                        bottomLeft: isMe
                                            ? const Radius.circular(18)
                                            : const Radius.circular(6),
                                        bottomRight: isMe
                                            ? const Radius.circular(6)
                                            : const Radius.circular(18),
                                      ),
                                    ),
                                    child: Text(
                                      message.message,
                                      style: TextStyle(
                                        color: bubbleTextColor,
                                        fontSize: 13,
                                        height: 1.3,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${message.createdAt.toLocal()}'
                                        .split('.')
                                        .first,
                                    style: TextStyle(
                                      color: isMe
                                          ? Colors.white70
                                          : Colors.black54,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
              color: Colors.white,
              child: Row(
                children: [
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
                        decoration: InputDecoration(
                          hintText: context.l10n.text('typeMessage'),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed:
                        _inputController.text.trim().isEmpty || _isSending
                        ? null
                        : _sendMessage,
                    icon: Icon(
                      _isSending ? Icons.hourglass_top : Icons.send,
                      color: Colors.white,
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
