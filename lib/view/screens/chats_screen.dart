import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_chat_app/constants.dart';
import 'package:firebase_chat_app/view/screens/auth/auth_page.dart';
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
  final currentUser = FirebaseAuth.instance.currentUser;
  final notificationService = NotificationsService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Load users and set online status
    _initializeUser();
  }

  Future<void> _initializeUser() async {
    try {
      // Set current user as online
      await FirebaseFirestoreService.updateUserData({
        'isOnline': true,
        'lastActive': DateTime.now(),
      });
      
      // Load all users
      Provider.of<FirebaseProvider>(context, listen: false).getAllUsers();
    } catch (e) {
      print('Error initializing user: $e');
    }
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
      uid: '4',
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
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          title: const Text(
            'ConnectPro',
            style: TextStyle(
              color: AppTheme.primaryColor,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.search, color: AppTheme.primaryColor),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UsersSearchScreen()),
              ),
            ),
            PopupMenuButton(
              icon: const Icon(Icons.more_vert, color: AppTheme.primaryColor),
              itemBuilder: (context) => [
                PopupMenuItem(
                  child: ListTile(
                    leading: const Icon(Icons.logout),
                    title: const Text('Logout'),
                    contentPadding: EdgeInsets.zero,
                    onTap: () async {
                      await FirebaseAuth.instance.signOut();
                      if (!context.mounted) return;
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const AuthPage()),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
        body: Consumer<FirebaseProvider>(
          builder: (context, provider, _) {
            if (provider.users.isEmpty) {
              return _buildEmptyState();
            }

            // Filter out duplicates and current user
            final uniqueUsers = provider.users.where((user) => 
              user.uid != currentUser?.uid).toSet().toList();

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: uniqueUsers.length,
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                final user = uniqueUsers[index];
                return UserItem(user: user);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 100,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'No Users Found',
            style: TextStyle(
              fontSize: 24,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start connecting with other users',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  void _showProfileDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Consumer<FirebaseProvider>(
        builder: (context, provider, _) {
          final currentUserData = provider.users.firstWhere(
            (user) => user.uid == currentUser?.uid,
            orElse: () => UserModel(
              uid: '',
              name: '',
              email: '',
              image: '',
              isOnline: false,
              lastActive: DateTime.now(),
            ),
          );

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: currentUserData.image != null && currentUserData.image!.isNotEmpty
                      ? NetworkImage(currentUserData.image!)
                      : null,
                  child: currentUserData.image == null || currentUserData.image!.isEmpty
                      ? Text(
                          currentUserData.name.substring(0, 1).toUpperCase(),
                          style: const TextStyle(fontSize: 32),
                        )
                      : null,
                ),
                const SizedBox(height: 16),
                Text(
                  currentUserData.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  currentUserData.email,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.access_time),
                  title: const Text('Last Active'),
                  subtitle: Text(
                    _formatDateTime(currentUserData.lastActive),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute}';
  }
}
