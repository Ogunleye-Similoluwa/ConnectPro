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
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.blue.shade50, Colors.white],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: _buildAppBar(context),
        body: Column(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: Consumer<FirebaseProvider>(
                  builder: (context, provider, _) {
                    if (provider.messages.isEmpty) {
                      return const Center(
                        child: EmptyWidget(
                          icon: Icons.message_outlined,
                          text: 'No messages yet\nStart chatting!',
                        ),
                      );
                    }
                    return ListView.separated(
                      controller: provider.scrollController,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(top: 16, bottom: 16),
                      itemCount: provider.messages.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final message = provider.messages[index];
                        final isMe = message.senderId == FirebaseAuth.instance.currentUser?.uid;
                        final showTime = index == 0 || 
                          _shouldShowTime(provider.messages[index - 1], message);
                        
                        return Column(
                          crossAxisAlignment: isMe 
                              ? CrossAxisAlignment.end 
                              : CrossAxisAlignment.start,
                          children: [
                            if (showTime) ...[
                              Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _formatMessageDate(message.sentTime),
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            MessageBubble(
                              message: message,
                              isMe: isMe,
                              isImage: message.type == 'image',
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 10,
                    offset: const Offset(0, -1),
                  ),
                ],
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ChatTextField(receiverId: userId),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: AppTheme.primaryColor),
        onPressed: () => Navigator.pop(context),
      ),
      title: Consumer<FirebaseProvider>(
        builder: (context, provider, _) {
          if (provider.user == null) return const SizedBox();
          
          return Row(
            children: [
              Stack(
                children: [
                  Hero(
                    tag: 'profile_${provider.user!.uid}',
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: provider.user!.image != null && 
                          provider.user!.image!.isNotEmpty
                          ? NetworkImage(provider.user!.image!)
                          : null,
                      child: provider.user!.image == null || 
                          provider.user!.image!.isEmpty
                          ? Text(
                              provider.user!.name.substring(0, 1).toUpperCase(),
                              style: const TextStyle(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            )
                          : null,
                    ),
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
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
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
                        color: AppTheme.primaryColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
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
              ),
            ],
          );
        },
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
}
