import 'package:flutter/material.dart';

import '../widgets/task_widgets.dart';

class SplashScreen extends StatelessWidget {
  final Object? error;
  final VoidCallback? onRetry;

  const SplashScreen({super.key, this.error, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 3),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 62,
                      width: 62,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(17),
                        border: Border.all(color: TaskPalette.line),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0B172033),
                            blurRadius: 18,
                            offset: Offset(0, 7),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.task_alt_rounded,
                          size: 35, color: TaskPalette.primary),
                    ),
                    const SizedBox(height: 21),
                    const Text(
                      'Firebase Task Manager',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: TaskPalette.ink,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 7),
                    const Text(
                      'A simple task manager powered by Flutter & Firebase',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: TaskPalette.muted, fontSize: 11, height: 1.5),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(flex: 2),
            if (error == null) ...[
              const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: TaskPalette.primary),
              ),
              const SizedBox(height: 9),
              const Text('Initializing app...',
                  style: TextStyle(color: TaskPalette.muted, fontSize: 10)),
            ] else ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 26),
                child: Text(
                  'Could not start the app.\n$error',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: TaskPalette.muted, fontSize: 11, height: 1.5),
                ),
              ),
              const SizedBox(height: 5),
              TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 17),
                label: const Text('Try again'),
              ),
            ],
            const Spacer(),
            const Padding(
              padding: EdgeInsets.only(bottom: 17),
              child: Text(
                'FLUTTER  •  FIREBASE',
                style: TextStyle(
                    color: Color(0xFFA4AFC0),
                    fontSize: 9,
                    letterSpacing: 1.3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
