import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'app_style.dart';
import 'authentication.dart';
import 'giver_app.dart';
import 'main.dart' show RefillHome;
import 'water_repository.dart';

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

  void open(int value) => setState(() => section = value);

  @override
  Widget build(BuildContext context) => IndexedStack(
    index: section,
    children: [
      Scaffold(
        appBar: AppBar(
          title: const Text('i fillup'),
          actions: [AccountButton(auth: widget.auth)],
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.water_drop_outlined,
                      size: 64,
                      color: teal,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Welcome to i fillup',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Fresh water. Shared journeys.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    _HomeChoice(
                      title: 'Take water',
                      description: 'Find a refill place, check the details and arrange your next fill-up.',
                      icon: Icons.water_drop_outlined,
                      onTap: () => open(1),
                    ),
                    const SizedBox(height: 16),
                    _HomeChoice(
                      title: 'Offer water',
                      description: 'Share your water point, set your price and manage traveler requests.',
                      icon: Icons.add_location_alt_outlined,
                      onTap: () => open(2),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'One app. Take water or offer water whenever you need.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      RefillHome(
        repository: widget.repository,
        auth: widget.auth,
        onHome: () => open(0),
        onOfferWater: () => open(2),
      ),
      GiverHome(
        repository: widget.repository,
        auth: widget.auth,
        onHome: () => open(0),
        onTakeWater: () => open(1),
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
        padding: const EdgeInsets.all(24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: teal, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(description),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward, color: teal),
          ],
        ),
      ),
    ),
  );
}
