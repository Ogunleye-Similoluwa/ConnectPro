import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String? image;
  final bool isOnline;
  final DateTime lastActive;
  final String? token;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.image,
    required this.isOnline,
    required this.lastActive,
    this.token,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    uid: json['uid'] ?? '',
    name: json['name'] ?? '',
    email: json['email'] ?? '',
    image: json['image'],
    isOnline: json['isOnline'] ?? false,
    lastActive: (json['lastActive'] as Timestamp).toDate(),
    token: json['token'],
  );

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'name': name,
    'email': email,
    'image': image,
    'isOnline': isOnline,
    'lastActive': Timestamp.fromDate(lastActive),
    'token': token,
  };
}
