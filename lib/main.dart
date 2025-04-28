import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_app/services/auth_repository.dart';
import 'bloc/auth_bloc.dart';
import 'bloc/auth_event.dart';
import 'bloc/auth_state.dart';

void main() {
  runApp(
    RepositoryProvider(
      create: (_) => AuthRepository(),
      child: BlocProvider(
        create: (ctx) => AuthBloc(ctx.read<AuthRepository>()),
        child: const MainApp(),
      ),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthFailure) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(state.error)));
          }
        },
        child: const LoginPage(),
      ),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _username = TextEditingController();
  final _pass = TextEditingController();

  @override
  void dispose() {
    _username.dispose();
    _pass.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(controller: _username, decoration: const InputDecoration(labelText: 'Username')),
            const SizedBox(height: 16),
            TextField(controller: _pass, obscureText: true, decoration: const InputDecoration(labelText: 'Password')),
            const SizedBox(height: 24),
            BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                if (state is AuthLoading) {
                  return const CircularProgressIndicator();
                }
                if (state is AuthAuthenticated) {
                  return Column(
                    children: [
                      Text('Welcome !'),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => context.read<AuthBloc>().add(AuthLogoutRequested()),
                        child: const Text('Logout'),
                      ),
                    ],
                  );
                }
                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      context.read<AuthBloc>().add(
                        AuthLoginRequested(_username.text, _pass.text),
                      );
                    },
                    child: const Text('Login'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
