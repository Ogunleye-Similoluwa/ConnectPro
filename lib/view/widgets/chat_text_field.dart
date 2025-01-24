import 'dart:async';
import 'dart:typed_data';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:emoji_picker_flutter/locales/default_emoji_set_locale.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' as foundation;
import '../../constants.dart';
import '../../service/firebase_firestore_service.dart';
import '../../service/media_service.dart';
import '../../service/notification_service.dart';
import 'custom_text_form_field.dart';

class ChatTextField extends StatefulWidget {
  final String receiverId;
  final Function(String)? onTyping;

  const ChatTextField({
    super.key, 
    required this.receiverId,
    this.onTyping,
  });

  @override
  State<ChatTextField> createState() =>
      _ChatTextFieldState();
}

class _ChatTextFieldState extends State<ChatTextField> {
  final controller = TextEditingController();
  final notificationsService = NotificationsService();

  Uint8List? file;
  bool _isRecording = false;
  Timer? _recordingTimer;
  int _recordingDuration = 0;
  bool _showEmoji = false;
  bool _isTyping = false;

  @override
  void initState() {
    notificationsService
        .getReceiverToken(widget.receiverId);
    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Emoji Picker (Initially hidden)
        if (_showEmoji)
          SizedBox(
            height: 250,
            child: EmojiPicker(
              onEmojiSelected: (category, emoji) {
                setState(() {
                  controller.text = controller.text + emoji.emoji;
                  _isTyping = true;
                });
              },
              config: const Config(
                    height: 256,
                    checkPlatformCompatibility: true,
                    viewOrderConfig: const ViewOrderConfig(
              ),
                    emojiViewConfig: EmojiViewConfig(
                      
                     
                    ),
                    skinToneConfig: const SkinToneConfig(),
                    categoryViewConfig: const CategoryViewConfig(),
                    bottomActionBarConfig: const BottomActionBarConfig(),
                    searchViewConfig: const SearchViewConfig(),
              )
            ),
          ),
        
        // Input Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 4,
              ),
            ],
          ),
          child: Row(
            children: [
              // Emoji Button
              IconButton(
                icon: Icon(
                  _showEmoji ? Icons.keyboard : Icons.emoji_emotions_outlined,
                  color: Colors.grey.shade600,
                ),
                onPressed: _toggleEmojiKeyboard,
              ),
              
              // Attachment Button
              IconButton(
                icon: Icon(Icons.attach_file, color: Colors.grey.shade600),
                onPressed: _showAttachmentOptions,
              ),
              
              // Text Input
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller,
                          maxLines: 5,
                          minLines: 1,
                          keyboardType: TextInputType.multiline,
                          textCapitalization: TextCapitalization.sentences,
                          onChanged: (text) {
                            setState(() => _isTyping = text.isNotEmpty);
                            widget.onTyping?.call(text);
                          },
                          decoration: InputDecoration(
                            hintText: 'Message',
                            hintStyle: TextStyle(color: Colors.grey.shade600),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ),
                      // Camera Button
                      IconButton(
                        icon: Icon(Icons.camera_alt, color: Colors.grey.shade600),
                        onPressed: _takePhoto,
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(width: 8),
              
              // Send/Voice Button
              _isTyping
                  ? Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFF00A884),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.send, color: Colors.white, size: 20),
                        onPressed: () {
                          if (controller.text.trim().isNotEmpty) {
                            _sendText(context);
                            setState(() => _isTyping = false);
                          }
                        },
                      ),
                    )
                  : GestureDetector(
                      onLongPress: _startRecording,
                      onLongPressEnd: (_) => _stopRecording(),
                      child: Container(
                        decoration: BoxDecoration(
                          color: _isRecording ? Colors.red : const Color(0xFF00A884),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(
                            _isRecording ? Icons.stop : Icons.mic,
                            color: Colors.white,
                            size: 20,
                          ),
                          onPressed: null,
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _sendText(BuildContext context) async {
    final text = controller.text.trim();
    if (text.isEmpty) return;

    try {
      await FirebaseFirestoreService.addTextMessage(
        receiverId: widget.receiverId,
        content: text,
      );
      
      await notificationsService.sendNotification(
        body: text,
        senderId: FirebaseAuth.instance.currentUser!.uid,
      );
      
      controller.clear();
      FocusScope.of(context).unfocus();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending message: $e')),
      );
    }
  }

  Future<void> _sendImage() async {
    final pickedImage = await MediaService.pickImage();
    setState(() => file = pickedImage);
    if (file != null) {
      await FirebaseFirestoreService.addImageMessage(
        receiverId: widget.receiverId,
        file: file!,
      );
      await notificationsService.sendNotification(
        body: 'image........',
        senderId: FirebaseAuth.instance.currentUser!.uid,
      );
    }
  }

  void _startRecording() {
    print('Started recording');
    setState(() {
      _isRecording = true;
      _recordingDuration = 0;
    });
    _recordingTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => setState(() => _recordingDuration++),
    );
  }

  void _stopRecording() {
    print('Stopped recording at $_recordingDuration seconds');
    _recordingTimer?.cancel();
    setState(() => _isRecording = false);
    // TODO: Implement voice message sending
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Voice messages coming soon!')),
    );
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        height: 280,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _attachmentOption(
                  icon: Icons.insert_drive_file,
                  label: 'Document',
                  color: Colors.indigo,
                  onTap: () => _pickDocument(),
                ),
                _attachmentOption(
                  icon: Icons.camera_alt,
                  label: 'Camera',
                  color: Colors.pink,
                  onTap: () => _takePhoto(),
                ),
                _attachmentOption(
                  icon: Icons.image,
                  label: 'Gallery',
                  color: Colors.purple,
                  onTap: () => _sendImage(),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _attachmentOption(
                  icon: Icons.headphones,
                  label: 'Audio',
                  color: Colors.orange,
                  onTap: () => _pickAudio(),
                ),
                _attachmentOption(
                  icon: Icons.location_on,
                  label: 'Location',
                  color: Colors.green,
                  onTap: () => _shareLocation(),
                ),
                _attachmentOption(
                  icon: Icons.person,
                  label: 'Contact',
                  color: Colors.blue,
                  onTap: () => _shareContact(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _attachmentOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 30),
          ),
          const SizedBox(height: 8),
          Text(label),
        ],
      ),
    );
  }

  void _takePhoto() {
    // Implementation of taking a photo
  }

  void _pickDocument() {
    // Implementation of picking a document
  }

  void _pickAudio() {
    // Implementation of picking an audio file
  }

  void _shareLocation() {
    // Implementation of sharing location
  }

  void _shareContact() {
    // Implementation of sharing a contact
  }

  void _onBackspacePressed() {
    final text = controller.text;
    final textSelection = controller.selection;
    final selectionLength = textSelection.end - textSelection.start;

    // There is a selection.
    if (selectionLength > 0) {
      final newText = text.replaceRange(
        textSelection.start,
        textSelection.end,
        '',
      );
      controller.text = newText;
      controller.selection = textSelection.copyWith(
        baseOffset: textSelection.start,
        extentOffset: textSelection.start,
      );
      return;
    }

    // The cursor is at the beginning.
    if (textSelection.start == 0) {
      return;
    }

    // Delete the previous character
    final previousCodeUnit = text.codeUnitAt(textSelection.start - 1);
    final offset = _isUtf16Surrogate(previousCodeUnit) ? 2 : 1;
    final newStart = textSelection.start - offset;
    final newEnd = textSelection.start;
    final newText = text.replaceRange(
      newStart,
      newEnd,
      '',
    );
    controller.text = newText;
    controller.selection = textSelection.copyWith(
      baseOffset: newStart,
      extentOffset: newStart,
    );
  }

  bool _isUtf16Surrogate(int value) {
    return value & 0xF800 == 0xD800;
  }

  void _toggleEmojiKeyboard() {
    setState(() {
      _showEmoji = !_showEmoji;
    });
    
    if (_showEmoji) {
      FocusScope.of(context).unfocus();
    }
  }
}
