import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_style.dart';
import 'authentication.dart';
import 'language.dart';
import 'offer_water_home.dart';
import 'push_notifications.dart';
import 'take_water_home.dart';
import 'traveler_profile.dart';
import 'water_repository.dart';
import 'texts.dart';

/// Keeps both sides mounted so switching home does not discard an offer draft.
class FillupHome extends StatefulWidget {
  const FillupHome({super.key, this.repository, this.auth});
  final WaterRepository? repository;
  final FirebaseAuth? auth;

  @override
  State<FillupHome> createState() => _FillupHomeState();
}

class _FillupHomeState extends State<FillupHome> {
  int section = 0;
  final showRequests = ValueNotifier(0);
  final showMyRequests = ValueNotifier(0);
  var pushSubscriptions = const <StreamSubscription<RemoteMessage>>[];

  void open(int value) => setState(() => section = value);

  /// Hosts see incoming requests; travelers see the answers to theirs.
  void openRequests(bool answer) {
    if (answer) {
      open(1);
      showMyRequests.value++;
    } else {
      open(2);
      showRequests.value++;
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.auth == null) return;
    pushSubscriptions = PushNotifications.listen(
      onMessage: (text, answer) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(text),
          action: SnackBarAction(
            label: tr.view,
            onPressed: () => openRequests(answer),
          ),
        ),
      ),
      onOpen: openRequests,
    );
  }

  @override
  void dispose() {
    for (final subscription in pushSubscriptions) {
      subscription.cancel();
    }
    showRequests.dispose();
    showMyRequests.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IndexedStack(
    index: section,
    children: [
      Scaffold(
        body: AnnotatedRegion<SystemUiOverlayStyle>(
          // White status bar icons on the dark water header.
          value: SystemUiOverlayStyle.light,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                WaveHeader(
                  child: SafeArea(
                    bottom: false,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'i fillup',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const LanguageButton(),
                            AccountButton(
                              auth: widget.auth,
                              onEditProfile: () {
                                final repository =
                                    widget.repository ??
                                    const DemoWaterRepository();
                                editProfile(
                                  context,
                                  load: repository.loadMyProfile,
                                  save: repository.saveMyProfile,
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const DropBadge(size: 80),
                        const SizedBox(height: 16),
                        Text(
                          tr.welcome,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineLarge
                              ?.copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          tr.tagline,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _HomeChoice(
                            title: tr.takeWater,
                            description: tr.takeWaterDescription,
                            icon: Icons.water_drop_outlined,
                            onTap: () => open(1),
                          ),
                          const SizedBox(height: 12),
                          _HomeChoice(
                            title: tr.offerWater,
                            description: tr.offerWaterDescription,
                            icon: Icons.add_location_alt_outlined,
                            onTap: () => open(2),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            tr.homeFooter,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: muted),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      RefillHome(
        repository: widget.repository,
        auth: widget.auth,
        onHome: () => open(0),
        showRequests: showMyRequests,
      ),
      GiverHome(
        repository: widget.repository,
        auth: widget.auth,
        onHome: () => open(0),
        showRequests: showRequests,
      ),
    ],
  );
}

class _HomeChoice extends StatelessWidget {
  const _HomeChoice({
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
  });
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            WaterIcon(icon, size: 52),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(description, style: const TextStyle(color: muted)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios_rounded, color: teal, size: 18),
          ],
        ),
      ),
    ),
  );
}
