import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app_style.dart';
import 'authentication.dart';
import 'fillup_home.dart';
import 'firebase_options.dart';
import 'firebase_startup.dart';
import 'water_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final app = await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    runApp(FillupApp(auth: FirebaseAuth.instanceFor(app: app)));
  } on FirebaseException catch (error, stackTrace) {
    debugPrintStack(stackTrace: stackTrace);
    runApp(
      FirebaseStartupError(
        error: error,
        onRetry: main,
        preview: const FillupApp(),
      ),
    );
  }
}

class FillupApp extends StatelessWidget {
  const FillupApp({super.key, this.repository, this.auth});
  final FirebaseAuth? auth;
  final WaterRepository? repository;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'i fillup',
    debugShowCheckedModeBanner: false,
    theme: waterTheme,
    home: auth == null
        ? FillupHome(repository: repository)
        : AuthenticationGate(
            auth: auth!,
            builder: (repository) =>
                FillupHome(repository: repository, auth: auth),
          ),
  );
}
