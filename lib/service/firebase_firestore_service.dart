import 'dart:async';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../model/message.dart';
import '../model/user.dart';
import 'firebase_storage_service.dart';

class FirebaseFirestoreService {
  static final firestore = FirebaseFirestore.instance;
  static final auth = FirebaseAuth.instance;

  static Future<void> createUser({
    required String name,
    required String email,
    required String uid,
    String? image,
  }) async {
    try {
      // Check if user already exists
      final userDoc = await firestore.collection('users').doc(uid).get();
      if (userDoc.exists) {
        print('User already exists');
        return;
      }

      final newUser = UserModel(
        uid: uid,
        name: name,
        email: email,
        image: image,
        isOnline: true,
        lastActive: DateTime.now(),
      );

      await firestore.collection('users').doc(uid).set(newUser.toJson());
      print('User created successfully: $name ($email)');
    } catch (e) {
      print('Error creating user: $e');
      rethrow;
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
      final currentUser = auth.currentUser;
      if (currentUser == null) return;

      await firestore
          .collection('users')
          .doc(currentUser.uid)
          .update(data);
    } catch (e) {
      print('Error updating user data: $e');
      rethrow;
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

  static Stream<List<UserModel>> getUsers() {
    return firestore
        .collection('users')
        .where('uid', isNotEqual: auth.currentUser?.uid)
        .snapshots()
        .map((snapshot) {
      final users = snapshot.docs
          .map((doc) => UserModel.fromJson(doc.data()))
          .toList();

      // Remove duplicates based on email
      final uniqueUsers = users.fold<Map<String, UserModel>>(
        {},
        (map, user) {
          if (!map.containsKey(user.email)) {
            map[user.email] = user;
          }
          return map;
        },
      ).values.toList();

      print('Fetched ${uniqueUsers.length} unique users');
      return uniqueUsers;
    });
  }
}
