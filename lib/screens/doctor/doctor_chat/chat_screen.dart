
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
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
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<bool> _isTyping = ValueNotifier<bool>(false);

  bool _isSending = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();

    // Mark messages as read when screen opens
    _markMessagesAsRead();

    // Auto-scroll to bottom on init
    _scrollController.addListener(_handleScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    _animationController.dispose();
    _isTyping.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (_scrollController.position.atEdge && _scrollController.position.pixels == 0) {
      _markMessagesAsRead();
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
    _isTyping.value = false;

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
        0.0,
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
      return DateFormat('HH:mm').format(dateTime);
    } else if (difference.inDays == 1) {
      return 'Yesterday ${DateFormat('HH:mm').format(dateTime)}';
    } else {
      return '${DateFormat('dd/MM').format(dateTime)} ${DateFormat('HH:mm').format(dateTime)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildMessageList()),
            _buildMessageInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final colors = _getAvatarColors(widget.userName);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios_new, color: Colors.grey[700], size: 24),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Hero(
            tag: 'avatar_${widget.chatId}',
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: colors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: colors[0].withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  widget.userName.isNotEmpty ? widget.userName[0].toUpperCase() : 'U',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
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
                  style: TextStyle(
                    color: Colors.grey[900],
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                StreamBuilder<Map<String, bool>>(
                  stream: _chatService.getTypingStatus(widget.chatId, widget.doctorId),
                  builder: (context, snapshot) {
                    final isOtherTyping = snapshot.data?[widget.userId] ?? false;
                    return Text(
                      isOtherTyping ? 'Typing...' : 'Patient',
                      style: TextStyle(
                        color: isOtherTyping ? Colors.blue[600] : colors[0],
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.videocam_rounded, color: colors[0], size: 28),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Video call feature coming soon!')),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.phone_rounded, color: colors[0], size: 28),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Voice call feature coming soon!')),
              );
            },
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: Colors.grey[700]),
            onSelected: (value) async {
              if (value == 'clear') {
                await _chatService.clearChat(widget.chatId);
              } else if (value == 'delete') {
                await _chatService.deleteChat(widget.chatId);
                Navigator.pop(context);
              }
            },
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
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore.collection('chats').doc(widget.chatId).snapshots(),
      builder: (context, snapshot) {
        // Only show loading if we've never had data before
        if (!snapshot.hasData && snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }

        // Handle case where document doesn't exist yet
        if (!snapshot.hasData || snapshot.data?.data() == null) {
          return _buildEmptyState();
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final messages = List<Map<String, dynamic>>.from(data['messages'] ?? []);

        if (messages.isEmpty) {
          return _buildEmptyState();
        }
        return FadeTransition(
          opacity: _fadeAnimation,
          child: ListView.builder(
            controller: _scrollController,
            reverse: true,
            padding: const EdgeInsets.all(16),
            itemCount: messages.length + (messages.isNotEmpty ? messages.length - 1 : 0),
            itemBuilder: (context, index) {
              if (index.isOdd) {
                final msgIndex = (index ~/ 2);
                final msg = messages[messages.length - 1 - msgIndex];
                final showTimestamp = _shouldShowTimestamp(messages, msgIndex);
                if (showTimestamp) {
                  return _buildTimestamp(msg['timestamp']);
                }
                return const SizedBox.shrink();
              }

              final msgIndex = index ~/ 2;
              final message = messages[messages.length - 1 - msgIndex];
              return MessageBubble(
                key: ValueKey(message['messageId']),
                message: message,
                encryptionKey: widget.encryptionKey,
                currentUserId: widget.doctorId,
                otherUserName: widget.userName,
                formatMessageTime: _formatMessageTime,
              );
            },
          ),
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
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: true,
        child: Row(
          children: [
            IconButton(
              icon: Icon(Icons.attach_file, color: Colors.grey[500]),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('File attachment coming soon!')),
                );
              },
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  ),
                  minLines: 1,
                  maxLines: 4,
                  onChanged: (text) {
                    _isTyping.value = text.trim().isNotEmpty;
                    _chatService.updateTypingStatus(widget.chatId, widget.doctorId, _isTyping.value);
                  },
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            ValueListenableBuilder<bool>(
              valueListenable: _isTyping,
              builder: (context, isTyping, child) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    gradient: isTyping
                        ? LinearGradient(
                      colors: [Colors.blue[600]!, Colors.blue[800]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                        : LinearGradient(
                      colors: [Colors.grey[300]!, Colors.grey[400]!],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: isTyping
                            ? Colors.blue[600]!.withOpacity(0.3)
                            : Colors.grey[300]!.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: isTyping && !_isSending ? _sendMessage : null,
                      child: Center(
                        child: _isSending
                            ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                            : Icon(
                          isTyping ? Icons.send_rounded : Icons.mic,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                );
              },
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

  List<Color> _getAvatarColors(String name) {
    final colors = [
      [Colors.blue[500]!, Colors.blue[700]!],
      [Colors.purple[500]!, Colors.purple[700]!],
      [Colors.green[500]!, Colors.green[700]!],
      [Colors.orange[500]!, Colors.orange[700]!],
      [Colors.pink[500]!, Colors.pink[700]!],
      [Colors.teal[500]!, Colors.teal[700]!],
      [Colors.indigo[500]!, Colors.indigo[700]!],
      [Colors.red[500]!, Colors.red[700]!],
    ];

    final index = name.hashCode % colors.length;
    return colors[index.abs()];
  }
}

class MessageBubble extends StatelessWidget {
  final Map<String, dynamic> message;
  final String encryptionKey;
  final String currentUserId;
  final String otherUserName;
  final String Function(Timestamp) formatMessageTime;

  const MessageBubble({
    Key? key,
    required this.message,
    required this.encryptionKey,
    required this.currentUserId,
    required this.otherUserName,
    required this.formatMessageTime,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isMe = message['senderId'] == currentUserId;
    String content;
    try {
      content = EncryptionService.decryptMessage(
        message['encryptedContent'] ?? '',
        encryptionKey,
      );
      print('Decrypted content: $content'); // Debug
    } catch (e) {
      print('Decryption error: $e, Message: ${message['encryptedContent']}'); // Debug
      content = 'Error decrypting message: $e';
    }

    final colors = _getAvatarColors(isMe ? 'Doctor' : otherUserName);

    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 300),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, double value, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12, left: 8, right: 8),
        child: Row(
          mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isMe) ...[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: colors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: colors[0].withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    otherUserName.isNotEmpty ? otherUserName[0].toUpperCase() : 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Flexible(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                ),
                decoration: BoxDecoration(
                  gradient: isMe
                      ? LinearGradient(
                    colors: colors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                      : null,
                  color: isMe ? null : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(20),
                    topRight: const Radius.circular(20),
                    bottomLeft: Radius.circular(isMe ? 20 : 4),
                    bottomRight: Radius.circular(isMe ? 4 : 20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      content,
                      style: TextStyle(
                        color: isMe ? Colors.white : Colors.grey[900],
                        fontSize: 16,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          formatMessageTime(message['timestamp']),
                          style: TextStyle(
                            color: isMe ? Colors.white70 : Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                        if (isMe && message['isRead'] == true) ...[
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.done_all,
                            size: 12,
                            color: Colors.white70,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (isMe) ...[
              const SizedBox(width: 12),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: colors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: colors[0].withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'D',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<Color> _getAvatarColors(String name) {
    final colors = [
      [Colors.blue[500]!, Colors.blue[700]!],
      [Colors.purple[500]!, Colors.purple[700]!],
      [Colors.green[500]!, Colors.green[700]!],
      [Colors.orange[500]!, Colors.orange[700]!],
      [Colors.pink[500]!, Colors.pink[700]!],
      [Colors.teal[500]!, Colors.teal[700]!],
      [Colors.indigo[500]!, Colors.indigo[700]!],
      [Colors.red[500]!, Colors.red[700]!],
    ];

    final index = name.hashCode % colors.length;
    return colors[index.abs()];
  }
}