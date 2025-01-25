import 'package:firebase_chat_app/constants.dart';
import 'package:firebase_chat_app/model/message.dart';
import 'package:firebase_chat_app/model/user.dart';
import 'package:firebase_chat_app/view/widgets/empty_widget.dart';
import 'package:firebase_chat_app/view/widgets/message_bubble.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../provider/firebase_provider.dart';
import '../widgets/chat_messages.dart';
import '../widgets/chat_text_field.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'package:firebase_chat_app/service/firebase_firestore_service.dart';
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  final String userId;
  const ChatScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  bool _isSearching = false;
  bool _isTyping = false;
  String _searchQuery = '';
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  void _initializeChat() {
    final provider = Provider.of<FirebaseProvider>(context, listen: false);
    provider.getUserById(widget.userId);
    provider.getMessages(widget.userId);
  }

  void _handleTyping(String text) {
    if (_typingTimer?.isActive ?? false) _typingTimer!.cancel();
    
    FirebaseFirestoreService.updateTypingStatus(
      widget.userId,
      text.isNotEmpty,
    );

    _typingTimer = Timer(const Duration(seconds: 3), () {
      FirebaseFirestoreService.updateTypingStatus(widget.userId, false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
        ),
        child: Column(
          children: [
            Consumer<FirebaseProvider>(
              builder: (context, provider, _) {
                if (provider.user?.isTyping ?? false) {
                  return _buildTypingIndicator();
                }
                return const SizedBox.shrink();
              },
            ),
            Expanded(
              child: Consumer<FirebaseProvider>(
                builder: (context, provider, _) {
                  if (provider.messages.isEmpty) {
                    return _buildEmptyChat();
                  }

                  final filteredMessages = _isSearching
                      ? provider.messages.where((msg) => 
                          msg.content.toLowerCase().contains(_searchQuery.toLowerCase())
                        ).toList()
                      : provider.messages;

                  return ListView.builder(
                    reverse: true,
                    controller: provider.scrollController,
                    itemCount: filteredMessages.length,
                    padding:  EdgeInsets.only(
                      left: 16, 
                      right: 16,
                      top: 16,
                      bottom: MediaQuery.of(context).padding.bottom + 16,
                    ),
                    itemBuilder: (context, index) {
                      final message = filteredMessages[index];
                      final isMe = message.senderId == FirebaseAuth.instance.currentUser?.uid;
                      
                      final showDate = index == filteredMessages.length - 1 || 
                        !_isSameDay(filteredMessages[index + 1].sentTime, message.sentTime);

                      final showTime = index == 0 || 
                        message.sentTime.hour != filteredMessages[index - 1].sentTime.hour ||
                        message.sentTime.minute != filteredMessages[index - 1].sentTime.minute;

                      return Column(
                        children: [
                          if (showDate) _buildDateDivider(message.sentTime),
                          MessageBubble(
                            message: message,
                            isMe: isMe,
                            isImage: message.type == 'image',
                            showTime: showTime,
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
            _buildBottomInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomInput() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ChatTextField(
            receiverId: widget.userId,
            onTyping: _handleTyping,
          ),
        ),
      ),
    );
  }

  Widget _buildDateDivider(DateTime date) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.grey.shade300)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              _formatDateHeader(date),
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(child: Divider(color: Colors.grey.shade300)),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 35,
                  child: Row(
                    children: List.generate(3, (index) => 
                      Container(
                        width: 5,
                        height: 5,
                        margin: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade600,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'typing...',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyChat() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, 
            size: 80, 
            color: AppTheme.primaryColor.withOpacity(0.3)
          ),
          const SizedBox(height: 16),
          Text(
            'No messages yet\nStart the conversation!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  bool _shouldShowTime(Message previous, Message current) {
    return current.sentTime.difference(previous.sentTime).inMinutes > 30;
  }

  String _formatMessageDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      return 'Today ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (messageDate == yesterday) {
      return 'Yesterday ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    }
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      return 'Today';
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year && 
           date1.month == date2.month && 
           date1.day == date2.day;
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    super.dispose();
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
        onPressed: () => Navigator.pop(context),
      ),
      title: Consumer<FirebaseProvider>(
        builder: (context, provider, _) {
          if (provider.user == null) return const SizedBox();
          return InkWell(
            onTap: () => _showUserProfile(provider.user!),
            child: Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.grey.shade100,
                      backgroundImage: provider.user!.image != null ? 
                        NetworkImage(provider.user!.image!) : null,
                      child: provider.user!.image == null ? 
                        Text(provider.user!.name[0].toUpperCase()) : null,
                    ),
                    if (provider.user!.isOnline)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        provider.user!.name,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        provider.user!.isOnline 
                            ? 'Online'
                            // ignore: unnecessary_null_comparison
                            : provider.user!.lastActive != null
                                ? 'last seen ${_formatLastSeen(provider.user!.lastActive!)}'
                                : 'Offline',
                        style: TextStyle(
                          color: provider.user!.isOnline 
                              ? Colors.green
                              : Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.videocam, color: Colors.black87),
          onPressed: _startVideoCall,
        ),
        IconButton(
          icon: const Icon(Icons.call, color: Colors.black87),
          onPressed: _startVoiceCall,
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.black87),
          onSelected: _handleMenuSelection,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'view_contact',
              child: Text('View contact'),
            ),
            const PopupMenuItem(
              value: 'media',
              child: Text('Media, links, and docs'),
            ),
            const PopupMenuItem(
              value: 'search',
              child: Text('Search'),
            ),
            const PopupMenuItem(
              value: 'mute',
              child: Text('Mute notifications'),
            ),
            const PopupMenuItem(
              value: 'wallpaper',
              child: Text('Wallpaper'),
            ),
            const PopupMenuItem(
              value: 'report',
              child: Text('Report'),
              textStyle: TextStyle(color: Colors.red),
            ),
          ],
        ),
      ],
    );
  }

  void _showUserProfile(UserModel user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: user.image != null
                    ? DecorationImage(
                        image: NetworkImage(user.image!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: user.image == null
                  ? Center(child: Text(user.name[0].toUpperCase(), style: const TextStyle(fontSize: 40)))
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              user.name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(user.email, style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 24),
            _buildProfileAction(Icons.call, 'Audio Call', _startVoiceCall),
            _buildProfileAction(Icons.videocam, 'Video Call', _startVideoCall),
            _buildProfileAction(Icons.block, 'Block User', _blockUser),
            _buildProfileAction(Icons.thumb_down, 'Report User', _reportUser, isDestructive: true),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileAction(IconData icon, String label, VoidCallback onTap, {bool isDestructive = false}) {
    return ListTile(
      leading: Icon(icon, color: isDestructive ? Colors.red : Colors.black87),
      title: Text(
        label,
        style: TextStyle(color: isDestructive ? Colors.red : Colors.black87),
      ),
      onTap: onTap,
    );
  }

  String _formatLastSeen(DateTime? lastSeen) {
    if (lastSeen == null) return 'a while ago';
    final now = DateTime.now();
    final difference = now.difference(lastSeen);
    
    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inHours < 1) {
      final mins = difference.inMinutes;
      return '$mins ${mins == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inDays < 1) {
      return 'today at ${DateFormat('HH:mm').format(lastSeen)}';
    } else if (difference.inDays == 1) {
      return 'yesterday at ${DateFormat('HH:mm').format(lastSeen)}';
    } else {
      return DateFormat('dd/MM/yy HH:mm').format(lastSeen);
    }
  }

  void _handleMenuSelection(String value) {
    switch (value) {
      case 'view_contact':
        _showUserProfile(Provider.of<FirebaseProvider>(context, listen: false).user!);
        break;
      case 'media':
        _showMediaGallery();
        break;
      case 'search':
        setState(() => _isSearching = true);
        break;
      case 'mute':
        _toggleMuteNotifications();
        break;
      case 'wallpaper':
        _showWallpaperPicker();
        break;
      case 'report':
        _showReportDialog();
        break;
    }
  }

  void _startVideoCall() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Video call feature coming soon')),
    );
  }

  void _startVoiceCall() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Voice call feature coming soon')),
    );
  }

  void _blockUser() {
    // Implement block user functionality
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('User blocked')),
    );
  }

  void _reportUser() {
    // Implement report user functionality
    Navigator.pop(context);
    _showReportDialog();
  }

  void _showMediaGallery() {
    // Show shared media, links, and documents
  }

  void _toggleMuteNotifications() {
    // Toggle mute status
  }

  void _showWallpaperPicker() {
    // Show wallpaper options
  }

  void _showReportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildReportOption('Spam'),
            _buildReportOption('Inappropriate Content'),
            _buildReportOption('Harassment'),
            _buildReportOption('Other'),
          ],
        ),
      ),
    );
  }

  Widget _buildReportOption(String reason) {
    return ListTile(
      title: Text(reason),
      onTap: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reported for $reason')),
        );
      },
    );
  }
}
