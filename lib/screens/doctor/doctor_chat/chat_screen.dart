import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_service.dart';
import 'encryption_service.dart';

class DoctorChatScreen extends StatefulWidget {
  final String chatId;
  final String doctorId;
  final String userId;
  final String userName;
  final String encryptionKey;

  const DoctorChatScreen({
    Key? key,
    required this.chatId,
    required this.doctorId,
    required this.userId,
    required this.userName,
    required this.encryptionKey,
  }) : super(key: key);

  @override
  State<DoctorChatScreen> createState() => _DoctorChatScreenState();
}

class _DoctorChatScreenState extends State<DoctorChatScreen>
    with TickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _messageFocusNode = FocusNode();

  bool _isOnline = true; // Placeholder for online status
  bool _isTyping = false;
  bool _isSending = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Mark messages as read when screen opens
    _markMessagesAsRead();

    // Listen to text changes for typing indicator
    _messageController.addListener(_onTextChanged);

    // Auto-scroll to bottom on init
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _messageFocusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _messageController.text.trim().isNotEmpty;
    if (hasText != _isTyping) {
      setState(() => _isTyping = hasText);
      // Update typing status in Firestore (optional, requires ChatService method)
      _chatService.updateTypingStatus(widget.chatId, widget.doctorId, hasText);
    }
  }

  void _markMessagesAsRead() async {
    try {
      await _chatService.markMessagesAsRead(widget.chatId, widget.doctorId);
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    _messageController.clear();

    // Add haptic feedback
    HapticFeedback.lightImpact();

    try {
      // Send plain text, let ChatService handle encryption
      await _chatService.sendMessage(
        widget.chatId,
        widget.doctorId,
        'doctor',
        text,
      );

      // Auto-scroll to bottom after sending
      _scrollToBottom();
    } catch (e) {
      // Show error and restore message
      _showErrorSnackBar('Failed to send message. Please try again.');
      _messageController.text = text;
    } finally {
      setState(() => _isSending = false);
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  String _formatMessageTime(Timestamp timestamp) {
    final dateTime = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return TimeOfDay.fromDateTime(dateTime).format(context);
    } else if (difference.inDays == 1) {
      return 'Yesterday ${TimeOfDay.fromDateTime(dateTime).format(context)}';
    } else {
      return '${dateTime.day}/${dateTime.month} ${TimeOfDay.fromDateTime(dateTime).format(context)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(child: _buildMessageList()),
          _buildMessageInput(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      title: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.blue[100],
            child: Text(
              widget.userName.isNotEmpty ? widget.userName[0].toUpperCase() : 'U',
              style: TextStyle(
                color: Colors.blue[700],
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.userName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                StreamBuilder<Map<String, bool>>(
                  stream: _chatService.getTypingStatus(widget.chatId, widget.doctorId),
                  builder: (context, snapshot) {
                    final isOtherTyping = snapshot.data?[widget.userId] ?? false;
                    return Text(
                      isOtherTyping
                          ? 'Typing...'
                          : _isOnline
                          ? 'Online'
                          : 'Last seen recently',
                      style: TextStyle(
                        fontSize: 12,
                        color: isOtherTyping
                            ? Colors.blue[600]
                            : _isOnline
                            ? Colors.green[600]
                            : Colors.grey[600],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.videocam_outlined),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Video call feature coming soon')),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.call_outlined),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Voice call feature coming soon')),
            );
          },
        ),
        PopupMenuButton(
          icon: const Icon(Icons.more_vert),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'clear',
              child: Text('Clear Chat'),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Text('Delete Chat'),
            ),
          ],
          onSelected: (value) async {
            if (value == 'clear') {
              await _chatService.clearChat(widget.chatId);
            } else if (value == 'delete') {
              await _chatService.deleteChat(widget.chatId);
              Navigator.pop(context);
            }
          },
        ),
      ],
    );
  }

  Widget _buildMessageList() {
    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore.collection('chats').doc(widget.chatId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorState();
        }

        if (!snapshot.hasData || snapshot.data?.data() == null) {
          return _buildLoadingState();
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final messages = List<Map<String, dynamic>>.from(data['messages'] ?? []);

        if (messages.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          controller: _scrollController,
          reverse: true,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final msg = messages[messages.length - 1 - index];
            final isDoctor = msg['senderId'] == widget.doctorId;
            final showTimeStamp = _shouldShowTimestamp(messages, index);

            return Column(
              children: [
                if (showTimeStamp) _buildTimestamp(msg['timestamp']),
                _buildMessageBubble(msg, isDoctor),
              ],
            );
          },
        );
      },
    );
  }

  bool _shouldShowTimestamp(List<Map<String, dynamic>> messages, int index) {
    if (index == messages.length - 1) return true;

    final currentMsg = messages[messages.length - 1 - index];
    final nextMsg = messages[messages.length - 2 - index];

    final currentTime = (currentMsg['timestamp'] as Timestamp).toDate();
    final nextTime = (nextMsg['timestamp'] as Timestamp).toDate();

    return currentTime.difference(nextTime).inMinutes > 15;
  }

  Widget _buildTimestamp(Timestamp timestamp) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        _formatMessageTime(timestamp),
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg, bool isDoctor) {
    print('Raw encrypted content: ${msg['encryptedContent']}'); // Debug
    print('Encryption key: ${widget.encryptionKey}'); // Debug
    String content;
    try {
      content = EncryptionService.decryptMessage(
        msg['encryptedContent'] ?? '',
        widget.encryptionKey,
      );
      print('Decrypted content: $content'); // Debug
    } catch (e) {
      print('Decryption error: $e, Message: ${msg['encryptedContent']}'); // Debug
      content = 'Error decrypting message: $e';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isDoctor ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isDoctor) ...[
            CircleAvatar(
              radius: 12,
              backgroundColor: Colors.grey[300],
              child: Text(
                widget.userName.isNotEmpty ? widget.userName[0].toUpperCase() : 'U',
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDoctor ? Colors.blue[600] : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isDoctor ? 20 : 4),
                  bottomRight: Radius.circular(isDoctor ? 4 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                content,
                style: TextStyle(
                  color: isDoctor ? Colors.white : Colors.black87,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            ),
          ),
          if (isDoctor) ...[
            const SizedBox(width: 8),
            Icon(
              Icons.done_all,
              size: 16,
              color: msg['read'] == true ? Colors.blue[600] : Colors.grey[400],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.attach_file, color: Colors.grey),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('File attachment coming soon')),
                );
              },
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _messageController,
                  focusNode: _messageFocusNode,
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 4,
                  minLines: 1,
                  decoration: const InputDecoration(
                    hintText: 'Type a message...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 48,
              height: 48,
              child: Material(
                color: _isTyping ? Colors.blue[600] : Colors.grey[300],
                borderRadius: BorderRadius.circular(24),
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: _isTyping ? _sendMessage : null,
                  child: _isSending
                      ? const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  )
                      : Icon(
                    _isTyping ? Icons.send : Icons.mic,
                    color: _isTyping ? Colors.white : Colors.grey[600],
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading conversation...', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Start the conversation',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Send a message to begin chatting with ${widget.userName}',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            'Unable to load messages',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => setState(() {}),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}