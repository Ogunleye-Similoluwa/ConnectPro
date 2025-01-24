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

class ChatScreen extends StatelessWidget {
  final String userId;
  const ChatScreen({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Consumer<FirebaseProvider>(
          builder: (context, provider, _) {
            if (provider.user == null) return const SizedBox();
            return Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.grey.shade100,
                  backgroundImage: provider.user!.image != null ? 
                    NetworkImage(provider.user!.image!) : null,
                  child: provider.user!.image == null ? 
                    Text(provider.user!.name[0].toUpperCase()) : null,
                ),
                const SizedBox(width: 12),
                Column(
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
                      provider.user!.isOnline ? 'Online' : 'Offline',
                      style: TextStyle(
                        color: provider.user!.isOnline ? Colors.green : Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
        ),
        child: Column(
          children: [
            Expanded(
              child: Consumer<FirebaseProvider>(
                builder: (context, provider, _) {
                  if (provider.messages.isEmpty) {
                    provider.getMessages(userId);
                    return _buildEmptyChat();
                  }
                  return ListView.builder(
                    controller: provider.scrollController,
                    itemCount: provider.messages.length,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemBuilder: (context, index) {
                      final message = provider.messages[index];
                      final isMe = message.senderId == FirebaseAuth.instance.currentUser?.uid;
                      return MessageBubble(
                        message: message,
                        isMe: isMe,
                        isImage: message.type == 'image',
                      );
                    },
                  );
                },
              ),
            ),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: SafeArea(
                child: ChatTextField(receiverId: userId),
              ),
            ),
          ],
        ),
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
}
