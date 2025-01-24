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
      final newUser = UserModel(
        uid: uid,
        name: name,
        email: email,
        image: image,
        isOnline: true,
        lastActive: DateTime.now(),
      );

      // Create users collection if it doesn't exist
      await firestore.collection('users').doc(uid).set(newUser.toJson());
      
      // Create chats collection for the user
      await firestore.collection('chats').doc(uid).set({
        'lastActive': DateTime.now(),
        'createdAt': DateTime.now(),
      });

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
    try {
      final senderId = FirebaseAuth.instance.currentUser!.uid;
      final message = Message(
        content: content,
        sentTime: DateTime.now(),
        receiverId: receiverId,
        senderId: senderId,
        type: 'text',  // Specify message type
      );

      // Add message to sender's collection
      await firestore
          .collection('chats')
          .doc(senderId)
          .collection(receiverId)
          .add(message.toJson());

      // Add message to receiver's collection
      await firestore
          .collection('chats')
          .doc(receiverId)
          .collection(senderId)
          .add(message.toJson());

      print('Text message sent: $content');
    } catch (e) {
      print('Error sending text message: $e');
      rethrow;
    }
  }

  static Future<void> addImageMessage({
    required String receiverId,
    required Uint8List file,
  }) async {
    try {
      final senderId = FirebaseAuth.instance.currentUser!.uid;
      
      // Upload image to Firebase Storage
      final imageUrl = await FirebaseStorageService.uploadImage(
        file,
        'chat_images/${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      final message = Message(
        content: imageUrl,
        sentTime: DateTime.now(),
        receiverId: receiverId,
        senderId: senderId,
        type: 'image',  // Specify message type
      );

      // Add message to sender's collection
      await firestore
          .collection('chats')
          .doc(senderId)
          .collection(receiverId)
          .add(message.toJson());

      // Add message to receiver's collection
      await firestore
          .collection('chats')
          .doc(receiverId)
          .collection(senderId)
          .add(message.toJson());

      print('Image message sent: $imageUrl');
    } catch (e) {
      print('Error sending image message: $e');
      rethrow;
    }
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
        .where('uid', isNotEqualTo: auth.currentUser?.uid)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) {
        print('No users found in collection');
        return [];
      }

      final users = snapshot.docs
          .map((doc) {
            try {
              return UserModel.fromJson(doc.data());
            } catch (e) {
              print('Error parsing user data: $e');
              return null;
            }
          })
          .where((user) => user != null)
          .cast<UserModel>()
          .toList();

      print('Found ${users.length} users');
      return users;
    });
  }

  static Future<void> initializeUser() async {
    try {
      final user = auth.currentUser;
      if (user == null) return;

      final userDoc = await firestore.collection('users').doc(user.uid).get();
      
      if (!userDoc.exists) {
        print('User document not found, creating new one');
        // Get the display name that was set during signup
        final displayName = user.displayName ?? 'User';
        await createUser(
          name: displayName,
          email: user.email ?? '',
          uid: user.uid,
          image: user.photoURL,
        );
      } else {
        await updateUserData({
          'isOnline': true,
          'lastActive': DateTime.now(),
        });
      }
    } catch (e) {
      print('Error initializing user: $e');
    }
  }

  static Future<void> updateTypingStatus(String receiverId, bool isTyping) async {
    try {
      final currentUser = auth.currentUser;
      if (currentUser == null) return;

      await firestore.collection('users').doc(currentUser.uid).update({
        'isTyping': isTyping,
        'typingTo': isTyping ? receiverId : null,
      });
    } catch (e) {
      print('Error updating typing status: $e');
    }
  }
}
