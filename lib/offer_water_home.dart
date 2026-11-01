import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'app_style.dart';
import 'authentication.dart';
import 'offer_water_form.dart';
import 'opening_times.dart';
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
    this.showRequests,
  });
  final VoidCallback? onHome;

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

  Future<void> editOffer(WaterPlace place) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (pageContext) => Scaffold(
          appBar: AppBar(title: Text(tr.editPlace)),
          body: OfferWaterForm(
            initial: place,
            isDemo: repository.isDemo,
            onSave: (updated) async {
              if (repository.isDemo) {
                final index = demoOffers.indexOf(place);
                if (index >= 0) setState(() => demoOffers[index] = updated);
              } else {
                await repository.updateOffer(updated);
              }
              if (pageContext.mounted) Navigator.pop(pageContext, true);
            },
          ),
        ),
      ),
    );
    if (saved == true && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(tr.changesSaved)));
    }
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
                        if (offers.any((place) => !place.isActive))
                          Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            color: Theme.of(context).colorScheme.errorContainer,
                            child: ListTile(
                              leading: const Icon(
                                Icons.visibility_off_outlined,
                              ),
                              title: Text(tr.placeHidden),
                            ),
                          ),
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
                          (place) => _PlaceCard(
                            place: place,
                            choosing: mustChoosePlace(offers),
                            onEdit: () => editOffer(place),
                            onMap: () => Navigator.of(context).push<WaterPlace>(
                              MaterialPageRoute(
                                builder: (_) => WaterPlacesMap(places: [place]),
                              ),
                            ),
                            onDelete: () => deleteOffer(place),
                            onKeep: () => keepOnlyOffer(place, offers),
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (offers.isEmpty)
                          FilledButton.icon(
                            onPressed: () => setState(() => page = 1),
                            icon: const Icon(Icons.add),
                            label: Text(tr.offerWater),
                          ),
                        const SizedBox(height: 8),
                        _Note(
                          icon: Icons.visibility_outlined,
                          text: repository.isDemo
                              ? tr.demoOffersNote
                              : tr.activeOffersNote,
                        ),
                        _Note(icon: Icons.info_outline, text: tr.onePlaceRule),
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
                        if (!mustChoosePlace(offers))
                          FilledButton.icon(
                            onPressed: () => editOffer(offers.single),
                            icon: const Icon(Icons.edit_outlined),
                            label: Text(tr.editPlace),
                          ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
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
                                    if (request.arrivedAt case final arrivedAt?)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.where_to_vote,
                                              color: teal,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              tr.arrivedAt(
                                                formatTime(
                                                  TimeOfDay.fromDateTime(
                                                    arrivedAt.toLocal(),
                                                  ),
                                                ),
                                              ),
                                              style: const TextStyle(
                                                color: teal,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
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

/// The host's water place: a header, one detail per line, and the actions
/// underneath.
class _PlaceCard extends StatelessWidget {
  const _PlaceCard({
    required this.place,
    required this.choosing,
    required this.onEdit,
    required this.onMap,
    required this.onDelete,
    required this.onKeep,
  });
  final WaterPlace place;

  /// Whether the owner must still choose which of their older places to keep.
  final bool choosing;
  final VoidCallback onEdit, onMap, onDelete, onKeep;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final details = <(IconData, String)>[
      (Icons.schedule, describeOpeningTimes(place.openingTimes)),
      (Icons.payments_outlined, displayPrice(place.price)),
      if (place.vehicles.isNotEmpty)
        (Icons.airport_shuttle_outlined, vehicleSummary(place.vehicles)),
      if (place.hose case final hose?)
        (Icons.water, hose ? tr.hoseAvailable : tr.bringOwnHose),
      if (place.selfService case final selfService?)
        selfService
            ? (Icons.touch_app_outlined, tr.selfService)
            : (Icons.person_outline, tr.hostPresent),
      if (place.services.isNotEmpty)
        (
          Icons.storefront_outlined,
          tr.alsoHereList(serviceSummary(place.services)),
        ),
    ];
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (place.photo case final photo?)
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.memory(photo, fit: BoxFit.cover),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                WaterIcon(place.icon, size: 44),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(place.name, style: theme.textTheme.titleLarge),
                      Text(place.area, style: const TextStyle(color: muted)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (place.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(place.description),
            ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Column(
              children: [
                for (final (icon, text) in details)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(icon, size: 20, color: teal),
                        const SizedBox(width: 12),
                        Expanded(child: Text(text)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          if (choosing && !place.isAccountPlace)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                tr.notListed,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 4, 4),
            child: Row(
              children: [
                if (choosing)
                  TextButton.icon(
                    onPressed: onKeep,
                    icon: const Icon(Icons.check_circle_outline),
                    label: Text(tr.keepThisOne),
                  )
                else
                  TextButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined),
                    label: Text(tr.edit),
                  ),
                TextButton.icon(
                  onPressed: onMap,
                  icon: const Icon(Icons.map_outlined),
                  label: Text(tr.map),
                ),
                const Spacer(),
                IconButton(
                  tooltip: tr.deletePlace,
                  onPressed: onDelete,
                  icon: Icon(
                    Icons.delete_outline,
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A short muted line with an icon, for hints under the place.
class _Note extends StatelessWidget {
  const _Note({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: muted),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: const TextStyle(color: muted)),
        ),
      ],
    ),
  );
}
