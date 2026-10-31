import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'authentication.dart';
import 'offer_water_form.dart';
import 'water_place.dart';
import 'water_places_map.dart';
import 'water_repository.dart';

class GiverHome extends StatefulWidget {
  const GiverHome({
    super.key,
    this.repository,
    this.auth,
    this.onHome,
    this.onTakeWater,
  });
  final VoidCallback? onHome;
  final VoidCallback? onTakeWater;
  final FirebaseAuth? auth;

  final WaterRepository? repository;

  @override
  State<GiverHome> createState() => _GiverHomeState();
}

class _GiverHomeState extends State<GiverHome> {
  int page = 0;
  final demoOffers = <WaterPlace>[];

  late final WaterRepository repository =
      widget.repository ?? const DemoWaterRepository();
  late final Stream<List<WaterPlace>> placesStream = repository.watchMyPlaces();
  late final Stream<List<RefillRequest>> requestsStream = repository
      .watchIncomingRequests();

  Future<void> saveOffer(WaterPlace place) async {
    if (repository.isDemo) {
      setState(() {
        demoOffers.add(place);
        page = 0;
      });
      return;
    }

    await repository.saveOffer(place);
    if (mounted) setState(() => page = 0);
  }

  Future<void> updateRequest(RefillRequest request, String status) async {
    try {
      await repository.updateRequestStatus(request, status);
    } on FirebaseException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update request: ${error.message}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('i fillup · Give'),
      actions: [AccountButton(auth: widget.auth)],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              onPressed: widget.onHome ?? () => setState(() => page = 0),
              icon: const Icon(Icons.home_outlined),
              label: const Text('Home'),
            ),
            if (widget.onTakeWater != null)
              TextButton.icon(
                onPressed: widget.onTakeWater,
                icon: const Icon(Icons.swap_horiz),
                label: const Text('Take water'),
              ),
          ],
        ),
      ),
    ),
    bottomNavigationBar: NavigationBar(
      selectedIndex: page,
      onDestinationSelected: (value) => setState(() => page = value),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.water_drop_outlined),
          label: 'My places',
        ),
        NavigationDestination(
          icon: Icon(Icons.add_location_alt_outlined),
          label: 'Offer water',
        ),
        NavigationDestination(
          icon: Icon(Icons.inbox_outlined),
          label: 'Requests',
        ),
      ],
    ),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: IndexedStack(
            index: page,
            children: [
              StreamBuilder<List<WaterPlace>>(
                stream: placesStream,
                initialData: repository.isDemo ? const [] : null,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Could not load places: ${snapshot.error}'),
                    );
                  }
                  final offers = repository.isDemo
                      ? demoOffers
                      : snapshot.data ?? const <WaterPlace>[];
                  return ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      Text(
                        'Your water places',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Manage the places where travelers can refill.',
                      ),
                      const SizedBox(height: 16),
                      if (offers.isEmpty)
                        const Text(
                          'No places yet. Add your first water offer below.',
                        ),
                      ...offers.map(
                        (place) => Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  place.name,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                Text(place.area),
                                const SizedBox(height: 8),
                                Text(place.price),
                                Text('Opening times: ${place.openingTimes}'),
                                TextButton.icon(
                                  onPressed: () => Navigator.of(context)
                                      .push<WaterPlace>(
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              WaterPlacesMap(places: [place]),
                                        ),
                                      ),
                                  icon: const Icon(Icons.map_outlined),
                                  label: const Text('View on map'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        onPressed: () => setState(() => page = 1),
                        icon: const Icon(Icons.add),
                        label: const Text('Offer water'),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        repository.isDemo
                            ? 'Demo only. Offers are not shared with the water taker app.'
                            : 'Your active offers are visible in Find water.',
                      ),
                    ],
                  );
                },
              ),
              OfferWaterForm(onSave: saveOffer, isDemo: repository.isDemo),
              StreamBuilder<List<RefillRequest>>(
                stream: requestsStream,
                initialData: repository.isDemo ? const [] : null,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Could not load requests: ${snapshot.error}'),
                    );
                  }
                  final requests = snapshot.data ?? const <RefillRequest>[];
                  return ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      Text(
                        'Incoming requests',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 16),
                      if (requests.isEmpty)
                        const Text('New traveler requests will appear here.'),
                      ...requests.map(
                        (request) => Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  request.placeName,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 8),
                                Text('${request.liters} liters'),
                                Text(request.message),
                                const SizedBox(height: 8),
                                Text('Status: ${request.status}'),
                                if (request.status == 'pending' &&
                                    !repository.isDemo)
                                  Wrap(
                                    spacing: 8,
                                    children: [
                                      TextButton(
                                        onPressed: () =>
                                            updateRequest(request, 'accepted'),
                                        child: const Text('Accept'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            updateRequest(request, 'declined'),
                                        child: const Text('Decline'),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Payments are arranged directly with travelers. The app does not collect payments or record earnings.',
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
