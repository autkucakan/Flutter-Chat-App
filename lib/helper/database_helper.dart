import 'dart:async';
import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  DatabaseHelper();
  static final DatabaseHelper instance = DatabaseHelper();
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDir = await getApplicationDocumentsDirectory();
    String path = join(documentsDir.path, 'app.db');
    print('Opening database at: $path');
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY,
        username TEXT NOT NULL,
        email TEXT NOT NULL,
        avatarUrl TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE chats (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE messages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        chatId INTEGER NOT NULL,
        senderId INTEGER NOT NULL,
        content TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        FOREIGN KEY (chatId)   REFERENCES chats (id),
        FOREIGN KEY (senderId) REFERENCES users (id)
      )
    ''');
  }

  // --------------------- Users CRUD ---------------------

  Future<int> insertUser(Map<String, dynamic> user) async {
    final db = await database;
    return await db.insert(
      'users',
      user,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getUsers() async {
    final db = await database;
    return await db.query('users');
  }

  Future<int> updateUser(Map<String, dynamic> user) async {
    final db = await database;
    return await db.update(
      'users',
      user,
      where: 'id = ?',
      whereArgs: [user['id']],
    );
  }

  Future<int> deleteUser(int id) async {
    final db = await database;
    return await db.delete('users', where: 'id = ?', whereArgs: [id]);
  }

  // --------------------- Chats CRUD ---------------------

  Future<int> insertChat(Map<String, dynamic> chat) async {
    final db = await database;
    // only keep the columns we declared (id: int, name: String)
    final sanitized = <String, dynamic>{
      'id': chat['id'] as int,
      'name': chat['name'] as String,
    };
    return await db.insert(
      'chats',
      sanitized,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getChats() async {
    final db = await database;
    return await db.query('chats');
  }

  Future<int> updateChat(Map<String, dynamic> chat) async {
    final db = await database;
    final sanitized = <String, dynamic>{
      'id': chat['id'] as int,
      'name': chat['name'] as String,
    };
    return await db.update(
      'chats',
      sanitized,
      where: 'id = ?',
      whereArgs: [chat['id']],
    );
  }

  Future<int> deleteChat(int id) async {
    final db = await database;
    return await db.delete('chats', where: 'id = ?', whereArgs: [id]);
  }

  // -------------------- Messages CRUD -------------------

  Future<int> insertMessage(Map<String, dynamic> message) async {
    final db = await database;

    // build a clean map, never passing null into NOT NULL columns
    final sanitized = <String, dynamic>{
      if (message['id'] != null) 'id': message['id'],
      'chatId': message['chatId'],
      'senderId': message['senderId'],
      'content': message['content'],
      'timestamp': message['timestamp'] ?? DateTime.now().toIso8601String(),
    };

    return await db.insert(
      'messages',
      sanitized,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getMessagesForChat(int chatId) async {
    final db = await database;
    return await db.query(
      'messages',
      where: 'chatId = ?',
      whereArgs: [chatId],
      orderBy: 'timestamp ASC',
    );
  }

  Future<int> updateMessage(Map<String, dynamic> message) async {
    final db = await database;
    return await db.update(
      'messages',
      message,
      where: 'id = ?',
      whereArgs: [message['id']],
    );
  }

  Future<int> deleteMessage(int id) async {
    final db = await database;
    return await db.delete('messages', where: 'id = ?', whereArgs: [id]);
  }
}
