import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String? image;
  final bool isOnline;
  final DateTime lastActive;
  final String? token;
  final bool isTyping;
  final String? typingTo;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.image,
    required this.isOnline,
    required this.lastActive,
    this.token,
    this.isTyping = false,
    this.typingTo,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    uid: json['uid'] ?? '',
    name: json['name'] ?? '',
    email: json['email'] ?? '',
    image: json['image'],
    isOnline: json['isOnline'] ?? false,
    lastActive: (json['lastActive'] as Timestamp).toDate(),
    token: json['token'],
    isTyping: json['isTyping'] ?? false,
    typingTo: json['typingTo'],
  );

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'name': name,
    'email': email,
    'image': image,
    'isOnline': isOnline,
    'lastActive': Timestamp.fromDate(lastActive),
    'token': token,
    'isTyping': isTyping,
    'typingTo': typingTo,
  };
}
