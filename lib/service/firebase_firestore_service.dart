import 'dart:async';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../model/message.dart';
import '../model/user.dart';
import 'firebase_storage_service.dart';

class FirebaseFirestoreService {
  static final firestore = FirebaseFirestore.instance;

  static Future<void> createUser({
    required String name,
    required String email,
    required String uid,
    String? image,
  }) async {
    try {
      final user = UserModel(
        uid: uid,
        email: email,
        name: name,
        image: image ?? '',  // Use empty string if no image
        isOnline: true,
        lastActive: DateTime.now(),
      );

      // Create or update the user document
      await firestore
          .collection('users')
          .doc(uid)
          .set(user.toJson(), SetOptions(merge: true));
          
      print('User created successfully: ${user.name}');
    } catch (e) {
      print('Error creating user: $e');
    }
  }

  static Future<void> addTextMessage({
    required String content,
    required String receiverId,
  }) async {
    final message = Message(
      content: content,
      sentTime: DateTime.now(),
      receiverId: receiverId,
      messageType: MessageType.text,
      senderId: FirebaseAuth.instance.currentUser!.uid,
    );
    await _addMessageToChat(receiverId, message);
  }

  static Future<void> addImageMessage({
    required String receiverId,
    required Uint8List file,
  }) async {
    final image = await FirebaseStorageService.uploadImage(
        file, 'image/chat/${DateTime.now()}');

    final message = Message(
      content: image,
      sentTime: DateTime.now(),
      receiverId: receiverId,
      messageType: MessageType.image,
      senderId: FirebaseAuth.instance.currentUser!.uid,
    );
    await _addMessageToChat(receiverId, message);
  }

  static Future<void> _addMessageToChat(
    String receiverId,
    Message message,
  ) async {
    await firestore
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection('chat')
        .doc(receiverId)
        .collection('messages')
        .add(message.toJson());

    await firestore
        .collection('users')
        .doc(receiverId)
        .collection('chat')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection('messages')
        .add(message.toJson());
  }

  static Future<void> updateUserData(Map<String, dynamic> data) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // First check if document exists
      final docRef = firestore.collection('users').doc(user.uid);
      final docSnapshot = await docRef.get();

      if (!docSnapshot.exists) {
        // Create initial user document if it doesn't exist
        await docRef.set({
          'uid': user.uid,
          'email': user.email,
          'name': user.displayName ?? 'User',
          'image': user.photoURL,
          'lastActive': DateTime.now(),
          'isOnline': true,
        });
      }

      // Then update with new data
      await docRef.update(data);
    } catch (e) {
      print('Error updating user data: $e');
    }
  }

  static Future<void> createUserDocument(UserModel user) async {
    try {
      await firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'name': user.name,
        'email': user.email,
        'image': user.image,
        'lastActive': DateTime.now(),
        'isOnline': true,
      });
    } catch (e) {
      print('Error creating user document: $e');
    }
  }

  static Future<List<UserModel>> searchUser(
      String name) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where("name", isGreaterThanOrEqualTo: name)
        .get();

    return snapshot.docs
        .map((doc) => UserModel.fromJson(doc.data()))
        .toList();
  }
}
