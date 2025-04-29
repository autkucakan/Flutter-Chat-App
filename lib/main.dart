import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:flutter_chat_app/services/api_service.dart';
import 'package:flutter_chat_app/helper/database_helper.dart';

import 'package:flutter_chat_app/repos/auth_repository.dart';
import 'package:flutter_chat_app/repos/chat_repository.dart';
import 'package:flutter_chat_app/repos/message_repository.dart';

import 'package:flutter_chat_app/bloc/auth/auth_bloc.dart';
import 'package:flutter_chat_app/views/login_view.dart';
import 'package:flutter_chat_app/views/register_view.dart';
import 'package:flutter_chat_app/views/home_view.dart';
import 'package:flutter_chat_app/views/chat_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  final dbHelper = DatabaseHelper.instance;
  final apiService = ApiService();
  await apiService.loadToken(); // pull JWT out of SharedPreferences

  final authRepo = AuthRepository(apiService: apiService, dbHelper: dbHelper);
  final chatRepo = ChatRepository(apiService: apiService, dbHelper: dbHelper);
  final messageRepo = MessageRepository(
    apiService: apiService,
    dbHelper: dbHelper,
  );

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: apiService),
        RepositoryProvider.value(value: dbHelper),
        RepositoryProvider.value(value: authRepo),
        RepositoryProvider.value(value: chatRepo),
        RepositoryProvider.value(value: messageRepo),
      ],
      child: BlocProvider(
        create: (_) => AuthBloc(authRepo),
        child: const MainApp(),
      ),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Chat App',
      initialRoute: '/login',
      routes: {
        '/login': (_) => const LoginView(),
        '/register': (_) => const RegisterView(),
        '/home': (_) => const HomeView(),
        '/': (c) => const HomeView(),
        // you *can* also put '/' here, but because chat needs an arg
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/chat') {
          final chatId = settings.arguments as int;
          return MaterialPageRoute(builder: (_) => ChatScreen(chatId: chatId));
        }
        // fallback (optional)
        return MaterialPageRoute(builder: (_) => const HomeView());
      },
    );
  }
}
