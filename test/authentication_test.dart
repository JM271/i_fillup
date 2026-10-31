import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:i_fillup/authentication.dart';
import 'package:i_fillup/offer_water_home.dart';
import 'package:i_fillup/take_water_home.dart';

class TestAuth extends Fake implements FirebaseAuth {
  String? signedInEmail;
  String? registeredEmail;
  String? resetEmail;
  bool fail = false;
  User? user;
  bool signedOut = false;

  @override
  User? get currentUser => user;

  @override
  Future<void> signOut() async {
    signedOut = true;
    user = null;
  }

  @override
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    if (fail) throw FirebaseAuthException(code: 'invalid-credential');
    signedInEmail = email;
    return TestCredential();
  }

  @override
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    registeredEmail = email;
    return TestCredential();
  }

  @override
  Future<void> sendPasswordResetEmail({
    required String email,
    ActionCodeSettings? actionCodeSettings,
  }) async {
    resetEmail = email;
  }
}

class TestCredential extends Fake implements UserCredential {}

class EmailUser extends Fake implements User {
  String? password;
  bool deleted = false;
  @override
  String? get email => 'lea@example.com';
  @override
  Future<UserCredential> reauthenticateWithCredential(
    AuthCredential credential,
  ) async {
    final given = (credential as EmailAuthCredential).password;
    if (given != 'secret123') {
      throw FirebaseAuthException(code: 'invalid-credential');
    }
    password = given;
    return TestCredential();
  }

  @override
  Future<void> delete() async => deleted = true;
}

class AnonymousUser extends Fake implements User {
  AuthCredential? linkedCredential;
  @override
  bool get isAnonymous => true;
  @override
  Future<UserCredential> linkWithCredential(AuthCredential credential) async {
    linkedCredential = credential;
    return TestCredential();
  }
}

void main() {
  Future<void> open(WidgetTester tester, TestAuth auth) =>
      tester.pumpWidget(MaterialApp(home: LoginScreen(auth: auth)));

  testWidgets('Login validates fields, reports errors and allows retry', (
    tester,
  ) async {
    final auth = TestAuth()..fail = true;
    await open(tester, auth);
    await tester.tap(find.widgetWithText(FilledButton, 'Log in'));
    await tester.pump();
    expect(find.text('Enter a valid email address.'), findsOneWidget);
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'person@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'secret123');
    await tester.tap(find.widgetWithText(FilledButton, 'Log in'));
    await tester.pumpAndSettle();
    expect(find.text('Email or password is incorrect.'), findsOneWidget);
    auth.fail = false;
    await tester.tap(find.widgetWithText(FilledButton, 'Log in'));
    await tester.pumpAndSettle();
    expect(auth.signedInEmail, 'person@example.com');
  });

  testWidgets('Registration and reset use the entered email', (tester) async {
    final auth = TestAuth();
    await open(tester, auth);
    await tester.tap(find.text('Create an account'));
    await tester.pump();
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'person@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'secret123');
    await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
    await tester.pumpAndSettle();
    expect(auth.registeredEmail, 'person@example.com');
    await tester.tap(find.text('Forgot password?'));
    await tester.pumpAndSettle();
    expect(auth.resetEmail, 'person@example.com');
    expect(
      find.textContaining('a password reset link has been sent'),
      findsOneWidget,
    );
  });
  testWidgets(
    'Registration upgrades the anonymous identity without creating another account',
    (tester) async {
      final anonymous = AnonymousUser();
      final auth = TestAuth()..user = anonymous;
      await open(tester, auth);
      await tester.tap(find.text('Create an account'));
      await tester.pump();
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'person@example.com',
      );
      await tester.enterText(find.byType(TextFormField).at(1), 'secret123');
      await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
      await tester.pumpAndSettle();
      expect(anonymous.linkedCredential, isA<EmailAuthCredential>());
      expect(auth.registeredEmail, isNull);
      expect(auth.user, same(anonymous));
    },
  );

  testWidgets('Account provides sign out', (tester) async {
    final auth = TestAuth();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(actions: [AccountButton(auth: auth)]),
        ),
      ),
    );
    await tester.tap(find.byTooltip('Account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    expect(auth.signedOut, isTrue);
    expect(find.text('Your account'), findsNothing);
  });
  testWidgets('Account and app switching fit a phone header', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final auth = TestAuth();
    await tester.pumpWidget(MaterialApp(home: RefillHome(auth: auth)));
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(MaterialApp(home: GiverHome(auth: auth)));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Accounts can be deleted after confirming the password', (
    tester,
  ) async {
    final user = EmailUser();
    final auth = TestAuth()..user = user;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(actions: [AccountButton(auth: auth)]),
        ),
      ),
    );
    await tester.tap(find.byTooltip('Account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete account'));
    await tester.pumpAndSettle();
    expect(find.text('Delete your account?'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'wrong');
    await tester.tap(find.widgetWithText(FilledButton, 'Delete account'));
    await tester.pumpAndSettle();
    expect(find.text('The password is incorrect.'), findsOneWidget);
    expect(user.deleted, isFalse);

    await tester.enterText(find.byType(TextField), 'secret123');
    await tester.tap(find.widgetWithText(FilledButton, 'Delete account'));
    await tester.pumpAndSettle();
    expect(user.deleted, isTrue);
    expect(find.text('Delete your account?'), findsNothing);
  });
}
