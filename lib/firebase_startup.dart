import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'texts.dart';

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
                    Text(
                      tr.cloudUnavailable,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      setupMissing
                          ? tr.firebaseAuthNotConfigured
                          : tr.firebaseConnectFailed,
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
                      child: Text(retrying ? tr.connecting : tr.retryCloud),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: () => runApp(widget.preview),
                      child: Text(tr.openPreview),
                    ),
                    const SizedBox(height: 12),
                    Text(tr.previewNote),
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
