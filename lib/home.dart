// lib/home.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Simple User model matching your API response
class User {
  final int id;
  final String name;
  final String avatarUrl;

  User({required this.id, required this.name, required this.avatarUrl});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      name: json['name'] as String? ?? 'User ${json['id']}',
      avatarUrl: json['avatar_url'] as String? ??
          'https://www.idsurfaces.co.uk/media/.../default.png',
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  Future<List<User>> fetchUsers() async {
    // 1. pull your token out of SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if (token == null) {
      throw Exception('Not authenticated: no JWT found in storage');
    }

    // 2. include it in your request
    final res = await http.get(
      Uri.parse('http://172.16.12.215:8000/api/users'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (res.statusCode == 200) {
      final List<dynamic> data = jsonDecode(res.body);
      return data.map((e) => User.fromJson(e)).toList();
    } else if (res.statusCode == 401) {
      throw Exception('Unauthorized (401): your token was rejected');
    } else {
      throw Exception('Failed to load users: ${res.statusCode} ${res.body}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: FutureBuilder<List<User>>(
        future: fetchUsers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final users = snapshot.data!;
          if (users.isEmpty) {
            return const Center(child: Text('No users found'));
          }
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (_, i) {
              final u = users[i];
              return Card(
                margin:
                    const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(u.avatarUrl),
                  ),
                  title: Text(u.name),
                  subtitle: Text('ID: ${u.id}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
