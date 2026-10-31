import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options_giver.dart' as giver_options;
import 'giver_app.dart';

import 'package:firebase_auth/firebase_auth.dart';

Future<void> startGiverApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final app = await Firebase.initializeApp(
      options: giver_options.DefaultFirebaseOptions.currentPlatform,
    );
    runApp(WaterGiverApp(auth: FirebaseAuth.instanceFor(app: app)));
  } on FirebaseException catch (error, stackTrace) {
    debugPrintStack(stackTrace: stackTrace);
    runApp(
      FirebaseStartupError(
        error: error,
        onRetry: startGiverApp,
        preview: const WaterGiverApp(),
      ),
    );
  }
}

class FirebaseStartupError extends StatefulWidget {
  const FirebaseStartupError({
    super.key,
    required this.error,
    required this.onRetry,
    required this.preview,
  });
  final FirebaseException error;
  final Future<void> Function() onRetry;
  final Widget preview;
  @override
  State<FirebaseStartupError> createState() => _FirebaseStartupErrorState();
}

class _FirebaseStartupErrorState extends State<FirebaseStartupError> {
  bool retrying = false;
  @override
  Widget build(BuildContext context) {
    final setupMissing =
        (widget.error.message ?? '').contains('CONFIGURATION_NOT_FOUND') ||
        widget.error.code == 'operation-not-allowed';
    return MaterialApp(
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.cloud_off_outlined, size: 56),
                    const SizedBox(height: 20),
                    const Text(
                      'Cloud connection unavailable',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      setupMissing
                          ? 'Firebase sign-in is not configured for this project. In Firebase Console → i-fillup → Authentication, complete setup and enable the Email/Password sign-in provider.'
                          : 'Could not connect to Firebase. Check your connection and Firebase setup, then retry.',
                    ),
                    const SizedBox(height: 12),
                    Text('Firebase: ${widget.error.code}'),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: retrying
                          ? null
                          : () async {
                              setState(() => retrying = true);
                              try {
                                await widget.onRetry();
                              } finally {
                                if (mounted) setState(() => retrying = false);
                              }
                            },
                      child: Text(
                        retrying ? 'Connecting…' : 'Retry cloud connection',
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: () => runApp(widget.preview),
                      child: const Text('Open preview without cloud'),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Preview data stays on this screen session. Offers and requests are not shared with other users.',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
