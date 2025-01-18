import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_chat_app/view/screens/search_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../model/user.dart';
import '../../provider/firebase_provider.dart';
import '../../service/firebase_firestore_service.dart';
import '../../service/notification_service.dart';
import '../widgets/user_item.dart';

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key});

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen>
    with WidgetsBindingObserver {
  final notificationService = NotificationsService();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Provider.of<FirebaseProvider>(context, listen: false)
        .getAllUsers();

    notificationService.firebaseNotification(context);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        FirebaseFirestoreService.updateUserData({
          'lastActive': DateTime.now(),
          'isOnline': true,
        });
        break;

      case AppLifecycleState.inactive:

      case AppLifecycleState.paused:

      case AppLifecycleState.detached:
        FirebaseFirestoreService.updateUserData(
            {'isOnline': false});
        break;
      case AppLifecycleState.hidden:

    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  final userData = [
    UserModel(
      uid: '1',
      name: 'Hazy',
      email: 'test@test.test',
      image: 'https://i.pravatar.cc/150?img=0',
      isOnline: true,
      lastActive: DateTime.now(),
    ),
    UserModel(
      uid: '1',
      name: 'Charlotte',
      email: 'test@test.test',
      image: 'https://i.pravatar.cc/150?img=1',
      isOnline: false,
      lastActive: DateTime.now(),
    ),
    UserModel(
      uid: '2',
      name: 'Ahmed',
      email: 'test@test.test',
      image: 'https://i.pravatar.cc/150?img=2',
      isOnline: true,
      lastActive: DateTime.now(),
    ),
    UserModel(
      uid: '3',
      name: 'Prateek',
      email: 'test@test.test',
      image: 'https://i.pravatar.cc/150?img=3',
      isOnline: false,
      lastActive: DateTime.now(),
    ),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Chats'),
          actions: [
            IconButton(
              onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) =>
                          const UsersSearchScreen())),
              icon: const Icon(Icons.search,
                  color: Colors.black),
            ),
            IconButton(
              onPressed: () =>
                  FirebaseAuth.instance.signOut(),
              icon: const Icon(Icons.logout,
                  color: Colors.black),
            ),
          ],
        ),
        body: Consumer<FirebaseProvider>(
            builder: (context, value, child) {
          return ListView.separated(
            padding:
                const EdgeInsets.symmetric(horizontal: 16),
            itemCount: value.users.length,
            separatorBuilder: (context, index) =>
                const SizedBox(height: 10),
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) => value
                        .users[index].uid !=
                    FirebaseAuth.instance.currentUser?.uid
                ? UserItem(user: value.users[index])
                : const SizedBox(),
          );
        }),
      );
}
