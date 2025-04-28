import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'chats.dart';
import 'bloc/auth_bloc.dart';
import 'bloc/auth_event.dart';

class User {
  final int id;
  final String name;
  final String avatarUrl;

  User({required this.id, required this.name, required this.avatarUrl});

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'] as int,
    name: json['name'] as String? ?? 'User ${json['id']}',
    avatarUrl:
        json['avatar_url'] as String? ??
        'https://www.idsurfaces.co.uk/media/.../default.png',
  );
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Future<List<User>> fetchUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if (token == null) {
      throw Exception('Not authenticated: no JWT found');
    }

    final res = await http.get(
      Uri.parse('http://172.16.12.215:8000/api/users'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as List<dynamic>;
      return data.map((e) => User.fromJson(e as Map<String, dynamic>)).toList();
    } else if (res.statusCode == 401) {
      throw Exception('Unauthorized (401)');
    } else {
      throw Exception('Error ${res.statusCode}: ${res.body}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'logout') {
                context.read<AuthBloc>().add(AuthLogoutRequested());
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'logout',
                child: Text('Logout'),
              ),
            ],
          ),
        ],
      ),
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
            itemBuilder: (context, i) {
              final u = users[i];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(u.avatarUrl),
                  ),
                  title: Text(u.name),
                  subtitle: Text('ID: ${u.id}'),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ChatsPage()),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}