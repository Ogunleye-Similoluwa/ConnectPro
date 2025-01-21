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
      print('Fetching users...');
      final snapshots = await FirebaseFirestore.instance
          .collection('users')
          .orderBy('lastActive', descending: true)
          .get();
          
      print('Found ${snapshots.docs.length} users');
      
      users = snapshots.docs.map((doc) {
        try {
          return UserModel.fromJson(doc.data());
        } catch (e) {
          print('Error parsing user document ${doc.id}: $e');
          return null;
        }
      }).whereType<UserModel>().toList();
          
      print('Processed users: ${users.length}');
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

  List<Message> getMessages(String receiverId) {
    FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection('chat')
        .doc(receiverId)
        .collection('messages')
        .orderBy('sentTime', descending: false)
        .snapshots(includeMetadataChanges: true)
        .listen((messages) {
      this.messages = messages.docs
          .map((doc) => Message.fromJson(doc.data()))
          .toList();
      notifyListeners();

      scrollDown();
    });
    return messages;
  }

  void scrollDown() =>
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (scrollController.hasClients) {
          scrollController.jumpTo(
              scrollController.position.maxScrollExtent);
        }
      });

  Future<void> searchUser(String name) async {
    search =
        await FirebaseFirestoreService.searchUser(name);
    notifyListeners();
  }
}
