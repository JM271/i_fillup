import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'app_style.dart';
import 'push_notifications.dart';
import 'water_repository.dart';
import 'texts.dart';

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
      tooltip: tr.account,
      onPressed: () => showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(tr.yourAccount),
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
                  label: Text(tr.editProfile),
                ),
              TextButton.icon(
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
                onPressed: () {
                  Navigator.pop(dialogContext);
                  showDialog<void>(
                    context: context,
                    builder: (_) => DeleteAccountDialog(auth: auth!),
                  );
                },
                icon: const Icon(Icons.person_remove_outlined),
                label: Text(tr.deleteAccount),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(tr.close),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                try {
                  await PushNotifications.disable();
                  await auth!.signOut();
                } catch (_) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(tr.signOutFailed)));
                  }
                }
              },
              child: Text(tr.signOut),
            ),
          ],
        ),
      ),
    );
  }
}

/// Deletes the signed-in account after the password is confirmed. The
/// deleteUserData Cloud Function then removes the account's data.
class DeleteAccountDialog extends StatefulWidget {
  const DeleteAccountDialog({super.key, required this.auth});
  final FirebaseAuth auth;

  @override
  State<DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<DeleteAccountDialog> {
  final password = TextEditingController();
  bool busy = false;
  String? error;

  @override
  void dispose() {
    password.dispose();
    super.dispose();
  }

  Future<void> delete() async {
    final user = widget.auth.currentUser;
    final email = user?.email;
    if (user == null || email == null) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      // Firebase only deletes accounts that signed in recently.
      await user.reauthenticateWithCredential(
        EmailAuthProvider.credential(email: email, password: password.text),
      );
      await PushNotifications.disable();
      await user.delete();
      if (mounted) Navigator.pop(context);
    } on FirebaseAuthException catch (exception) {
      if (!mounted) return;
      setState(() {
        busy = false;
        error =
            const {
              'wrong-password',
              'invalid-credential',
            }.contains(exception.code)
            ? tr.passwordIncorrect
            : tr.deleteAccountFailed;
      });
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(tr.deleteAccountTitle),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(tr.deleteAccountBody),
        const SizedBox(height: 16),
        TextField(
          controller: password,
          obscureText: true,
          enabled: !busy,
          decoration: InputDecoration(
            labelText: tr.password,
            errorText: error,
            border: const OutlineInputBorder(),
          ),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: busy ? null : () => Navigator.pop(context),
        child: Text(tr.keepAccount),
      ),
      FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
        onPressed: busy ? null : delete,
        child: Text(busy ? tr.deleting : tr.deleteAccount),
      ),
    ],
  );
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
        setState(() => message = tr.enterEmailFirst);
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
          setState(() => message = tr.resetSent);
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
            'email-already-in-use' ||
            'credential-already-in-use' => tr.emailInUse,
            'invalid-email' => tr.invalidEmail,
            'weak-password' => tr.weakPassword,
            'invalid-credential' ||
            'wrong-password' ||
            'user-not-found' => tr.wrongCredentials,
            'too-many-requests' => tr.tooManyRequests,
            'network-request-failed' => tr.checkConnection,
            'operation-not-allowed' ||
            'configuration-not-found' => tr.signInDisabled,
            _ => tr.authFailed,
          },
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => message = tr.couldNotConnect);
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
                    const Center(child: WaterIcon(Icons.water_drop, size: 72)),
                    const SizedBox(height: 16),
                    Text(
                      'i fillup',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tr.loginTagline,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: muted),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      registering ? tr.createYourAccount : tr.logIn,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: email,
                      enabled: !busy,
                      decoration: InputDecoration(
                        labelText: tr.email,
                        prefixIcon: Icon(Icons.mail_outline),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      textCapitalization: TextCapitalization.none,
                      autofillHints: const [AutofillHints.email],
                      validator: (value) =>
                          value == null ||
                              !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                  .hasMatch(value.trim())
                          ? tr.invalidEmail
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
                        labelText: tr.password,
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          tooltip: hidePassword
                              ? tr.showPassword
                              : tr.hidePassword,
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
                          ? tr.enterPassword
                          : registering && value.length < 6
                          ? tr.passwordTooShort
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
                            ? tr.pleaseWait
                            : registering
                            ? tr.createAccount
                            : tr.logIn,
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
                        registering ? tr.haveAccount : tr.createAnAccount,
                      ),
                    ),
                    TextButton(
                      onPressed: busy ? null : () => submit(reset: true),
                      child: Text(tr.forgotPassword),
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
