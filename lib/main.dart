import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_style.dart';
import 'authentication.dart';
import 'fillup_home.dart';
import 'firebase_options.dart';
import 'firebase_startup.dart';
import 'texts.dart';
import 'water_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Texts for anything shown before MaterialApp picks the locale.
  tr = lookupAppLocalizations(
    basicLocaleListResolution(
      WidgetsBinding.instance.platformDispatcher.locales,
      appLocales,
    ),
  );
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
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: appLocales,
    builder: (context, child) {
      tr = AppLocalizations.of(context);
      // Rebuilds every screen with the new texts when the language changes.
      return KeyedSubtree(key: ValueKey(tr.localeName), child: child!);
    },
    home: auth == null
        ? FillupHome(repository: repository)
        : AuthenticationGate(
            auth: auth!,
            builder: (repository) =>
                FillupHome(repository: repository, auth: auth),
          ),
  );
}
