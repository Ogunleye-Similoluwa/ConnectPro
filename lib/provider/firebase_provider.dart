import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../model/message.dart';
import '../model/user.dart';
import '../service/firebase_firestore_service.dart';

class FirebaseProvider extends ChangeNotifier {
  ScrollController scrollController = ScrollController();

  List<UserModel> users = [];
  UserModel? user;
  List<Message> messages = [];
  List<UserModel> search = [];

  Future<void> getAllUsers() async {
    try {
      final snapshots = await FirebaseFirestore.instance
          .collection('users')
          .where('uid', isNotEqualTo: FirebaseAuth.instance.currentUser?.uid)
          .get();

      // Convert to Set to remove duplicates based on email
      final uniqueUsers = <String, UserModel>{};
      for (var doc in snapshots.docs) {
        final user = UserModel.fromJson(doc.data());
        uniqueUsers[user.email] = user;
      }

      users = uniqueUsers.values.toList();
      
      print('Unique users loaded: ${users.length}');
      for (var user in users) {
        print('User: ${user.name} (${user.email})');
      }
      
      notifyListeners();
    } catch (e) {
      print('Error getting users: $e');
    }
  }

  Future<void> getUserById(String userId) async {
    int retries = 3;
    while (retries > 0) {
      try {
        final getUser = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();

        if (!getUser.exists || getUser.data() == null) {
          return;
        }

        user = UserModel.fromJson(getUser.data()!);
        notifyListeners();
        return; // Success, exit the retry loop
      } catch (e) {
        print('Error getting user by ID (retries left: ${retries-1}): $e');
        retries--;
        if (retries > 0) {
          await Future.delayed(Duration(seconds: 2)); // Wait before retrying
        }
      }
    }
  }

  void getMessages(String receiverId) {
    final senderId = FirebaseAuth.instance.currentUser!.uid;
    
    FirebaseFirestore.instance
        .collection('chats')
        .doc(senderId)
        .collection(receiverId)
        .orderBy('sentTime', descending: true)
        .snapshots()
        .listen((snapshot) {
      messages = snapshot.docs
          .map((doc) => Message.fromJson(doc.data()))
          .toList();
      notifyListeners();
      scrollDown();
    });
  }

  void scrollDown() => 
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

  Future<void> searchUser(String name) async {
    search =
        await FirebaseFirestoreService.searchUser(name);
    notifyListeners();
  }
}
