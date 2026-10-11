import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../widgets/task_widgets.dart';
import 'login_screen.dart';
import 'splash_screen.dart';
import 'task_list_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService.instance.authChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Could not connect to Firebase.\n${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: TaskPalette.muted)),
              ),
            ),
          );
        }
        return snapshot.hasData ? const TaskListScreen() : const LoginScreen();
      },
    );
  }
}
