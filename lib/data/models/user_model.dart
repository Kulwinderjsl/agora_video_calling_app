import 'package:equatable/equatable.dart';

class User extends Equatable {
  final int id;
  final String name;
  final String username;
  final String email;
  final String avatarUrl;

  const User({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    required this.avatarUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      username: json['username'],
      email: json['email'],
      avatarUrl: 'https://i.pravatar.cc/150?img=${json['id']}',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'email': email,
      'avatarUrl': avatarUrl,
    };
  }

  @override
  List<Object?> get props => [id, name, username, email, avatarUrl];
}
