import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../constants.dart';
import '../../model/message.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;
  final bool isImage;
  final bool showTime;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.isImage,
    this.showTime = true,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          top: 2,
          bottom: showTime ? 16 : 2, // More space if showing time
          left: isMe ? 48 : 0,
          right: isMe ? 0 : 48,
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: isMe ? const Color(0xFF0084FF) : Colors.white,
                borderRadius: BorderRadius.circular(20).copyWith(
                  bottomRight: isMe ? const Radius.circular(4) : null,
                  bottomLeft: !isMe ? const Radius.circular(4) : null,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.all(isImage ? 4 : 12),
                child: isImage
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          message.content,
                          width: 200,
                          height: 200,
                          fit: BoxFit.cover,
                          loadingBuilder: (_, child, loading) {
                            if (loading == null) return child;
                            return Container(
                              width: 200,
                              height: 200,
                              color: Colors.grey.shade100,
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            );
                          },
                        ),
                      )
                    : Text(
                        message.content,
                        style: TextStyle(
                          color: isMe ? Colors.white : Colors.black87,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
            if (showTime) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    DateFormat('HH:mm').format(message.sentTime),
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 11,
                    ),
                  ),
                  if (isMe) ...[
                    const SizedBox(width: 4),
                    Icon(
                      _getStatusIcon(message.status),
                      size: 14,
                      color: message.status == MessageStatus.read 
                          ? Colors.blue 
                          : Colors.grey.shade600,
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return DateFormat('HH:mm').format(time);
  }

  IconData _getStatusIcon(MessageStatus status) {
    switch (status) {
      case MessageStatus.sending:
        return Icons.access_time;
      case MessageStatus.sent:
        return Icons.check;
      case MessageStatus.delivered:
        return Icons.done_all;
      case MessageStatus.read:
        return Icons.done_all;
    }
  }

  void _showMessageOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.reply),
              title: const Text('Reply'),
              onTap: () {
                // TODO: Implement reply
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy'),
              onTap: () {
                Clipboard.setData(ClipboardData(text: message.content));
                Navigator.pop(context);
              },
            ),
            if (isMe) ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () {
                // TODO: Implement delete
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
