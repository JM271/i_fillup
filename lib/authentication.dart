import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'water_repository.dart';

class AuthenticationGate extends StatelessWidget {
  const AuthenticationGate({
    super.key,
    required this.auth,
    required this.builder,
  });
  final FirebaseAuth auth;
  final Widget Function(WaterRepository repository) builder;

  @override
  Widget build(BuildContext context) => StreamBuilder<User?>(
    stream: auth.userChanges(),
    initialData: auth.currentUser,
    builder: (context, snapshot) {
      final user = snapshot.data;
      if (user == null || user.isAnonymous) return LoginScreen(auth: auth);
      return KeyedSubtree(
        key: ValueKey(user.uid),
        child: builder(FirebaseWaterRepository.forUser(auth.app, user.uid)),
      );
    },
  );
}

class AccountButton extends StatelessWidget {
  const AccountButton({super.key, this.auth, this.onEditProfile});
  final FirebaseAuth? auth;
  final VoidCallback? onEditProfile;

  @override
  Widget build(BuildContext context) {
    if (auth == null) return const SizedBox.shrink();
    return IconButton(
      icon: const Icon(Icons.account_circle_outlined),
      tooltip: 'Account',
      onPressed: () => showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Your account'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(auth!.currentUser?.email ?? ''),
              if (onEditProfile case final edit?)
                TextButton.icon(
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    edit();
                  },
                  icon: const Icon(Icons.badge_outlined),
                  label: const Text('Edit profile'),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                try {
                  await auth!.signOut();
                } catch (_) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Could not sign out. Please try again.'),
                      ),
                    );
                  }
                }
              },
              child: const Text('Sign out'),
            ),
          ],
        ),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.auth});
  final FirebaseAuth auth;
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final form = GlobalKey<FormState>();
  final email = TextEditingController();
  final password = TextEditingController();
  bool registering = false;
  bool busy = false;
  bool hidePassword = true;
  String? message;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> submit({bool reset = false}) async {
    if (busy) return;
    if (reset) {
      if (!email.text.trim().contains('@')) {
        setState(() => message = 'Enter your email address first.');
        return;
      }
    } else if (!form.currentState!.validate()) {
      return;
    }
    setState(() {
      busy = true;
      message = null;
    });
    try {
      final address = email.text.trim();
      if (reset) {
        await widget.auth.sendPasswordResetEmail(email: address);
        if (mounted) {
          setState(
            () => message = 'If an account exists for this email, a password reset link has been sent.',
          );
        }
      } else if (registering) {
        final current = widget.auth.currentUser;
        if (current != null && current.isAnonymous) {
          await current.linkWithCredential(
            EmailAuthProvider.credential(
              email: address,
              password: password.text,
            ),
          );
        } else {
          await widget.auth.createUserWithEmailAndPassword(
            email: address,
            password: password.text,
          );
        }
      } else {
        await widget.auth.signInWithEmailAndPassword(
          email: address,
          password: password.text,
        );
      }
    } on FirebaseAuthException catch (error) {
      if (mounted) {
        setState(
          () => message = switch (error.code) {
            'email-already-in-use' || 'credential-already-in-use' =>
              'This email already has an account. Log in instead.',
            'invalid-email' => 'Enter a valid email address.',
            'weak-password' =>
              'Choose a stronger password with at least 6 characters.',
            'invalid-credential' ||
            'wrong-password' ||
            'user-not-found' => 'Email or password is incorrect.',
            'too-many-requests' => 'Too many attempts. Please try again later.',
            'network-request-failed' =>
              'Check your internet connection and try again.',
            'operation-not-allowed' || 'configuration-not-found' => 'Email/password sign-in must be enabled in Firebase Authentication.',
            _ => 'Authentication failed. Please try again.',
          },
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => message = 'Could not connect. Please try again.');
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: AutofillGroup(
              child: Form(
                key: form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.water_drop_outlined, size: 56),
                    const SizedBox(height: 16),
                    Text(
                      'i fillup',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      registering ? 'Create your account' : 'Log in',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: email,
                      enabled: !busy,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      textCapitalization: TextCapitalization.none,
                      autofillHints: const [AutofillHints.email],
                      validator: (value) =>
                          value == null ||
                              !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                  .hasMatch(value.trim())
                          ? 'Enter a valid email address.'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: password,
                      enabled: !busy,
                      obscureText: hidePassword,
                      autocorrect: false,
                      enableSuggestions: false,
                      autofillHints: [
                        registering
                            ? AutofillHints.newPassword
                            : AutofillHints.password,
                      ],
                      decoration: InputDecoration(
                        labelText: 'Password',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          tooltip: hidePassword
                              ? 'Show password'
                              : 'Hide password',
                          onPressed: () =>
                              setState(() => hidePassword = !hidePassword),
                          icon: Icon(
                            hidePassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                        ),
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Enter your password.'
                          : registering && value.length < 6
                          ? 'Use at least 6 characters.'
                          : null,
                      onFieldSubmitted: (_) => submit(),
                    ),
                    if (message != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text(message!, semanticsLabel: message),
                      ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: busy ? null : () => submit(),
                      child: Text(
                        busy
                            ? 'Please wait…'
                            : registering
                            ? 'Create account'
                            : 'Log in',
                      ),
                    ),
                    TextButton(
                      onPressed: busy
                          ? null
                          : () => setState(() {
                              registering = !registering;
                              message = null;
                            }),
                      child: Text(
                        registering
                            ? 'Already have an account? Log in'
                            : 'Create an account',
                      ),
                    ),
                    TextButton(
                      onPressed: busy ? null : () => submit(reset: true),
                      child: const Text('Forgot password?'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
