import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'app_style.dart';
import 'authentication.dart';
import 'offer_water_form.dart';
import 'push_notifications.dart';
import 'traveler_profile.dart';
import 'water_place.dart';
import 'water_places_map.dart';
import 'water_repository.dart';
import 'texts.dart';

/// Accounts from before the one-place rule may hold several places.
bool mustChoosePlace(List<WaterPlace> offers) => offers.length > 1;

class GiverHome extends StatefulWidget {
  const GiverHome({
    super.key,
    this.repository,
    this.auth,
    this.onHome,
    this.onTakeWater,
    this.showRequests,
  });
  final VoidCallback? onHome;
  final VoidCallback? onTakeWater;

  /// Switches to Requests whenever it notifies, e.g. on a tapped push.
  final Listenable? showRequests;
  final FirebaseAuth? auth;

  final WaterRepository? repository;

  @override
  State<GiverHome> createState() => _GiverHomeState();
}

class _GiverHomeState extends State<GiverHome> {
  int page = 0;
  final demoOffers = <WaterPlace>[];

  void openRequests() => setState(() => page = 2);

  @override
  void initState() {
    super.initState();
    widget.showRequests?.addListener(openRequests);
  }

  @override
  void dispose() {
    widget.showRequests?.removeListener(openRequests);
    super.dispose();
  }

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
        title: Text(tr.keepPlaceTitle(keep.name)),
        content: Text(
          others.isEmpty ? tr.keepPlaceOnly : tr.keepPlaceOthers(others.length),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(tr.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(tr.keepThisOne),
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
        SnackBar(content: Text(tr.placesUpdateFailed('${error.message}'))),
      );
      return;
    }
    messenger.showSnackBar(SnackBar(content: Text(tr.isYourPlace(keep.name))));
  }

  Future<void> deleteOffer(WaterPlace place) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(tr.deletePlaceTitle(place.name)),
        content: Text(tr.deletePlaceBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(tr.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(tr.delete),
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
          SnackBar(content: Text(tr.placeDeleteFailed('${error.message}'))),
        );
        return;
      }
    }
    messenger.showSnackBar(
      SnackBar(content: Text(tr.placeDeleted(place.name))),
    );
  }

  Future<void> deleteRequest(RefillRequest request) async {
    final traveler = request.requester?.name ?? tr.theTraveler;
    final pending = request.status == 'pending';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(tr.deleteRequestTitle),
        content: Text(
          pending
              ? tr.deleteReceivedPendingBody(traveler)
              : tr.deleteRequestBody,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(tr.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(pending ? tr.declineAndDelete : tr.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await repository.deleteIncomingRequest(request);
    } on FirebaseException catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text(tr.deleteRequestFailed('${error.message}'))),
      );
      return;
    }
    messenger.showSnackBar(SnackBar(content: Text(tr.requestDeleted)));
  }

  Future<void> updateRequest(RefillRequest request, String status) async {
    try {
      await repository.updateRequestStatus(request, status);
    } on FirebaseException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr.requestUpdateFailed('${error.message}'))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: IconButton(
        tooltip: tr.home,
        icon: const Icon(Icons.home_outlined),
        onPressed: widget.onHome ?? () => setState(() => page = 0),
      ),
      titleSpacing: 0,
      title: Text(
        tr.offerWater,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontWeight: FontWeight.w800, color: ink),
      ),
      actions: [
        if (widget.onTakeWater != null)
          TextButton.icon(
            onPressed: widget.onTakeWater,
            icon: const Icon(Icons.swap_horiz),
            label: Text(tr.switchToTake),
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
      destinations: [
        NavigationDestination(
          icon: Icon(Icons.water_drop_outlined),
          label: tr.myPlaces,
        ),
        NavigationDestination(
          icon: Icon(Icons.add_location_alt_outlined),
          label: tr.offerWater,
        ),
        NavigationDestination(
          icon: Icon(Icons.inbox_outlined),
          label: tr.requests,
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
              // Hosts are asked for notification permission once they offer
              // a place, so they hear about requests straight away.
              if (offers.isNotEmpty) PushNotifications.enable(repository);
              return IndexedStack(
                index: page,
                children: [
                  if (snapshot.hasError)
                    Center(
                      child: Text(tr.placesLoadFailed('${snapshot.error}')),
                    )
                  else
                    ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Text(
                          tr.yourWaterPlaces,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(tr.yourWaterPlacesIntro),
                        const SizedBox(height: 12),
                        if (offers.isEmpty) Text(tr.noPlacesYet),
                        if (mustChoosePlace(offers))
                          Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            color: Theme.of(context).colorScheme.errorContainer,
                            child: ListTile(
                              leading: Icon(Icons.warning_amber_rounded),
                              title: Text(tr.chooseOnePlace),
                              subtitle: Text(tr.chooseOnePlaceBody),
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
                                        Text(
                                          tr.areaPrice(
                                            place.area,
                                            displayPrice(place.price),
                                          ),
                                        ),
                                        if (place.vehicles.isNotEmpty)
                                          Text(
                                            vehicleSummary(place.vehicles),
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall,
                                          ),
                                        if (place.services.isNotEmpty)
                                          Text(
                                            tr.alsoHereList(
                                              serviceSummary(place.services),
                                            ),
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
                                            tr.notListed,
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
                                              label: Text(tr.keepThisOne),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: tr.viewOnMap,
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
                                    tooltip: tr.deletePlace,
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
                            label: Text(tr.offerWater),
                          ),
                        const SizedBox(height: 16),
                        Text(
                          repository.isDemo
                              ? tr.demoOffersNote
                              : tr.activeOffersNote,
                        ),
                        const SizedBox(height: 4),
                        Text(tr.onePlaceRule),
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
                          tr.alreadyOffer,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(tr.alreadyOfferBody),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: () => setState(() => page = 0),
                          icon: const Icon(Icons.water_drop_outlined),
                          label: Text(tr.goToMyPlaces),
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
                            tr.requestsLoadFailed('${snapshot.error}'),
                          ),
                        );
                      }
                      final requests = snapshot.data ?? const <RefillRequest>[];
                      return ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          Text(
                            tr.incomingRequests,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 12),
                          if (requests.isEmpty) Text(tr.incomingRequestsEmpty),
                          ...requests.map(
                            (request) => Card(
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            request.placeName,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium,
                                          ),
                                        ),
                                        if (!repository.isDemo)
                                          IconButton(
                                            tooltip: tr.deleteRequest,
                                            onPressed: () =>
                                                deleteRequest(request),
                                            icon: Icon(
                                              Icons.delete_outline,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .error,
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    RequesterSummary(
                                      profile: request.requester,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(tr.litersCount(request.liters)),
                                    Text(request.message),
                                    const SizedBox(height: 8),
                                    Text(
                                      tr.statusLine(
                                        requestStatus(request.status),
                                      ),
                                    ),
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
                                            child: Text(tr.accept),
                                          ),
                                          TextButton(
                                            onPressed: () => updateRequest(
                                              request,
                                              'declined',
                                            ),
                                            child: Text(tr.decline),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(tr.paymentsNote),
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
