import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'app_style.dart';
import 'authentication.dart';
import 'offer_water_form.dart';
import 'traveler_profile.dart';
import 'water_place.dart';
import 'water_places_map.dart';
import 'water_repository.dart';

/// Accounts from before the one-place rule may hold several places.
bool mustChoosePlace(List<WaterPlace> offers) => offers.length > 1;

const onePlaceRule =
    'Each account can offer one water place, to keep listings trustworthy.';

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
      if (demoOffers.isNotEmpty) return;
      setState(() {
        demoOffers.add(place);
        page = 0;
      });
      return;
    }

    await repository.saveOffer(place);
    if (mounted) setState(() => page = 0);
  }

  Future<void> keepOnlyOffer(WaterPlace keep, List<WaterPlace> offers) async {
    final others = offers.where((place) => place != keep).toList();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Keep ${keep.name}?'),
        content: Text(
          others.isEmpty
              ? 'It becomes your one water place and is listed for travelers again.'
              : 'It becomes your one water place. Your other ${others.length == 1 ? 'place' : '${others.length} places'} will be deleted. Requests you already received stay in Requests.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Keep this one'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await repository.keepOnlyOffer(keep, others);
    } on FirebaseException catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not update places: ${error.message}')),
      );
      return;
    }
    messenger.showSnackBar(
      SnackBar(content: Text('${keep.name} is your water place')),
    );
  }

  Future<void> deleteOffer(WaterPlace place) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Delete ${place.name}?'),
        content: const Text(
          'Travelers will no longer see this place. Requests you already received stay in Requests.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    if (repository.isDemo) {
      setState(() => demoOffers.remove(place));
    } else {
      try {
        await repository.deleteOffer(place);
      } on FirebaseException catch (error) {
        messenger.showSnackBar(
          SnackBar(content: Text('Could not delete place: ${error.message}')),
        );
        return;
      }
    }
    messenger.showSnackBar(SnackBar(content: Text('${place.name} deleted')));
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
      leading: IconButton(
        tooltip: 'Home',
        icon: const Icon(Icons.home_outlined),
        onPressed: widget.onHome ?? () => setState(() => page = 0),
      ),
      titleSpacing: 0,
      title: const Text(
        'Offer water',
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontWeight: FontWeight.w800, color: ink),
      ),
      actions: [
        if (widget.onTakeWater != null)
          TextButton.icon(
            onPressed: widget.onTakeWater,
            icon: const Icon(Icons.swap_horiz),
            label: const Text('Take water'),
          ),
        AccountButton(
          auth: widget.auth,
          onEditProfile: () => editProfile(
            context,
            load: repository.loadMyProfile,
            save: repository.saveMyProfile,
          ),
        ),
      ],
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
          child: StreamBuilder<List<WaterPlace>>(
            stream: placesStream,
            initialData: repository.isDemo ? const [] : null,
            builder: (context, snapshot) {
              final offers = repository.isDemo
                  ? demoOffers
                  : snapshot.data ?? const <WaterPlace>[];
              final loading = !repository.isDemo && snapshot.data == null;
              return IndexedStack(
                index: page,
                children: [
                  if (snapshot.hasError)
                    Center(
                      child: Text('Could not load places: ${snapshot.error}'),
                    )
                  else
                    ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Text(
                          'Your water places',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Manage the places where travelers can refill.',
                        ),
                        const SizedBox(height: 12),
                        if (offers.isEmpty)
                          const Text(
                            'No places yet. Add your first water offer below.',
                          ),
                        if (mustChoosePlace(offers))
                          Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            color: Theme.of(context).colorScheme.errorContainer,
                            child: const ListTile(
                              leading: Icon(Icons.warning_amber_rounded),
                              title: Text('Choose your one water place'),
                              subtitle: Text(
                                'Places marked "Not listed" are hidden from travelers. Tap "Keep this one" on the place you want to offer; the others are deleted.',
                              ),
                            ),
                          ),
                        ...offers.map(
                          (place) => Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          place.name,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium,
                                        ),
                                        Text('${place.area} · ${place.price}'),
                                        if (place.vehicles.isNotEmpty)
                                          Text(
                                            vehicleSummary(place.vehicles),
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall,
                                          ),
                                        Text(
                                          place.openingTimes,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall,
                                        ),
                                        if (mustChoosePlace(offers) &&
                                            !place.isAccountPlace)
                                          Text(
                                            'Not listed',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .error,
                                            ),
                                          ),
                                        if (mustChoosePlace(offers))
                                          Align(
                                            alignment: Alignment.centerLeft,
                                            child: TextButton.icon(
                                              onPressed: () =>
                                                  keepOnlyOffer(place, offers),
                                              icon: const Icon(
                                                Icons.check_circle_outline,
                                              ),
                                              label: const Text(
                                                'Keep this one',
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'View on map',
                                    onPressed: () => Navigator.of(context)
                                        .push<WaterPlace>(
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                WaterPlacesMap(places: [place]),
                                          ),
                                        ),
                                    icon: const Icon(
                                      Icons.map_outlined,
                                      color: teal,
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'Delete place',
                                    onPressed: () => deleteOffer(place),
                                    icon: Icon(
                                      Icons.delete_outline,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .error,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (offers.isEmpty)
                          FilledButton.icon(
                            onPressed: () => setState(() => page = 1),
                            icon: const Icon(Icons.add),
                            label: const Text('Offer water'),
                          ),
                        const SizedBox(height: 16),
                        Text(
                          repository.isDemo
                              ? 'Demo only. Offers are not shared with the water taker app.'
                              : 'Your active offers are visible in Find water.',
                        ),
                        const SizedBox(height: 4),
                        const Text(onePlaceRule),
                      ],
                    ),
                  if (snapshot.hasError || loading)
                    const Center(child: CircularProgressIndicator())
                  else if (offers.isEmpty)
                    OfferWaterForm(onSave: saveOffer, isDemo: repository.isDemo)
                  else
                    ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Text(
                          'You already offer a place',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          '$onePlaceRule Delete your place in My places to offer a different one.',
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: () => setState(() => page = 0),
                          icon: const Icon(Icons.water_drop_outlined),
                          label: const Text('Go to My places'),
                        ),
                      ],
                    ),
                  StreamBuilder<List<RefillRequest>>(
                    stream: requestsStream,
                    initialData: repository.isDemo ? const [] : null,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Could not load requests: ${snapshot.error}',
                          ),
                        );
                      }
                      final requests = snapshot.data ?? const <RefillRequest>[];
                      return ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          Text(
                            'Incoming requests',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 12),
                          if (requests.isEmpty)
                            const Text(
                              'New traveler requests will appear here.',
                            ),
                          ...requests.map(
                            (request) => Card(
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      request.placeName,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium,
                                    ),
                                    const SizedBox(height: 8),
                                    RequesterSummary(
                                      profile: request.requester,
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
                                            onPressed: () => updateRequest(
                                              request,
                                              'accepted',
                                            ),
                                            child: const Text('Accept'),
                                          ),
                                          TextButton(
                                            onPressed: () => updateRequest(
                                              request,
                                              'declined',
                                            ),
                                            child: const Text('Decline'),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Payments are arranged directly with travelers. The app does not collect payments or record earnings.',
                          ),
                        ],
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ),
      ),
    ),
  );
}
