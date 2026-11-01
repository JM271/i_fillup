import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import 'address_search.dart';
import 'app_style.dart';
import 'authentication.dart';
import 'google_address_picker.dart';
import 'location_picker.dart';
import 'route_planner.dart';
import 'traveler_profile.dart';
import 'water_place.dart';
import 'water_places_map.dart';
import 'water_repository.dart';
import 'opening_times.dart';
import 'texts.dart';

class RefillHome extends StatefulWidget {
  const RefillHome({
    super.key,
    this.repository,
    this.auth,
    this.onHome,
    this.onOfferWater,
    this.routeService,
    this.locate = currentRefillLocation,
    this.chooseDestination = chooseRouteDestination,
  });
  final VoidCallback? onHome;
  final VoidCallback? onOfferWater;
  final FirebaseAuth? auth;
  final WaterRepository? repository;
  final RouteService? routeService;
  final Future<LatLng> Function() locate;
  final Future<AddressMatch?> Function(BuildContext context) chooseDestination;

  @override
  State<RefillHome> createState() => _RefillHomeState();
}

Future<AddressMatch?> chooseRouteDestination(BuildContext context) {
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    return chooseGoogleAddress('');
  }
  return Navigator.of(context).push<AddressMatch>(
    MaterialPageRoute(builder: (_) => const AddressSearchPage()),
  );
}

String formatKm(double meters) => meters < 10000
    // German and French write 2,5 km.
    ? '${(meters / 1000).toStringAsFixed(1).replaceAll('.', tr.localeName == 'en' ? '.' : ',')} km'
    : '${(meters / 1000).round()} km';

const routeRadiiKm = [1, 2, 5, 10, 25];

String routeStopLabel(PlannedRoute route, RouteStop stop) {
  if (route.aroundStart) {
    return stop.along < 100
        ? tr.atYourLocation
        : tr.distanceAway(formatKm(stop.along));
  }
  return [
    stop.along < 100 ? tr.atYourStart : tr.afterDistance(formatKm(stop.along)),
    stop.offRoute < 100 ? tr.onRoute : tr.offRoute(formatKm(stop.offRoute)),
  ].join(' · ');
}

/// Driving meters that the distance filter compares with the chosen radius.
double filterDistance(PlannedRoute route, RouteStop stop) =>
    route.aroundStart ? stop.along : stop.offRoute;

enum DistanceMode { all, nearMe, onRoute }

/// One distance tab's results, kept while the user switches tabs.
class DistanceFilter {
  PlannedRoute? route;
  List<RouteStop>? stops;
  List<WaterPlace>? places;
  int radiusKm = 5;
}

class _RefillHomeState extends State<RefillHome> {
  String query = '';

  /// 0: all places, 1: private hosts, 2: refill stops.
  int filter = 0;
  int page = 0;
  final List<String> demoRequests = [];
  DistanceMode mode = DistanceMode.all;
  final nearMe = DistanceFilter();
  final onRoute = DistanceFilter();
  String? busy;

  DistanceFilter? get active => switch (mode) {
    DistanceMode.all => null,
    DistanceMode.nearMe => nearMe,
    DistanceMode.onRoute => onRoute,
  };
  PlannedRoute? get route => active?.route;
  List<RouteStop>? get stops => active?.stops;
  int get radiusKm => active?.radiusKm ?? 5;

  late final RouteService routeService =
      widget.routeService ?? OsrmRouteService();

  late final WaterRepository repository =
      widget.repository ?? const DemoWaterRepository();
  late final Stream<List<WaterPlace>> placesStream = repository.watchPlaces();
  late final Stream<List<RefillRequest>> requestsStream = repository
      .watchMyRequests();

  Future<void> showPlace(WaterPlace place) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (place.photo case final photo?)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.memory(photo, fit: BoxFit.cover),
                  ),
                )
              else
                Icon(place.icon, size: 48, color: teal),
              const SizedBox(height: 16),
              Text(
                place.name,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Text(tr.areaPrice(place.area, displayPrice(place.price))),
              const SizedBox(height: 12),
              Text(
                tr.openingTimesValue(describeOpeningTimes(place.openingTimes)),
              ),
              if (place.vehicles.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(tr.suitableFor(vehicleSummary(place.vehicles))),
              ],
              if (place.promotesBusiness) ...[
                const SizedBox(height: 20),
                Text(
                  tr.alsoHere,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final key in place.services)
                      Chip(
                        avatar: Icon(
                          placeServiceIcons[key],
                          size: 18,
                          color: teal,
                        ),
                        label: Text(placeServices[key]!),
                      ),
                  ],
                ),
                if (place.businessInfo.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(place.businessInfo),
                ],
                if (place.website.isNotEmpty)
                  TextButton.icon(
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                    onPressed: () => launchUrl(
                      Uri.parse(place.website),
                      mode: LaunchMode.externalApplication,
                    ),
                    icon: const Icon(Icons.open_in_new),
                    label: Text(Uri.parse(place.website).host),
                  ),
              ],
              const SizedBox(height: 20),
              Text(
                place.description,
                style: const TextStyle(fontSize: 16, height: 1.5),
              ),
              const SizedBox(height: 16),
              Text(repository.isDemo ? tr.demoListingNote : tr.confirmWithHost),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    requestWater(place);
                  },
                  child: Text(tr.arrangeFillUp(place.host)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> requestWater(WaterPlace place) async {
    TravelerProfile? profile;
    try {
      profile = await repository.loadMyProfile();
    } catch (_) {
      showMessage(tr.profileLoadRetry);
      return;
    }
    if (!mounted) return;
    profile ??= await Navigator.of(context).push<TravelerProfile>(
      MaterialPageRoute(
        builder: (_) => ProfilePage(
          onSave: repository.saveMyProfile,
          intro: tr.firstRequestIntro,
        ),
      ),
    );
    if (profile == null || !mounted) return;
    final requester = profile;
    final form = GlobalKey<FormState>();
    final message = TextEditingController();
    final liters = TextEditingController(text: '80');
    String? selectedTiming;
    void selectTiming(String value) {
      var existing = message.text.trim();
      final previous = selectedTiming;
      if (previous != null) {
        if (existing == previous) {
          existing = '';
        } else if (existing.startsWith('$previous\n')) {
          existing = existing.substring(previous.length).trimLeft();
        }
      }
      selectedTiming = value;
      message.text = existing.isEmpty ? value : '$value\n$existing';
      message.selection = TextSelection.collapsed(offset: message.text.length);
    }

    final submitted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(tr.planFillUp),
        content: SingleChildScrollView(
          child: Form(
            key: form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(tr.toHost(place.host)),
                Text(
                  tr.fromRequester(requester.name, requester.vehicle),
                  style: const TextStyle(color: muted),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ActionChip(
                        avatar: const Icon(Icons.bolt, size: 20),
                        label: Text(tr.asap),
                        tooltip: tr.asapTooltip,
                        onPressed: () => selectTiming(tr.asap),
                      ),
                      ActionChip(
                        label: Text(tr.today),
                        onPressed: () => selectTiming(tr.today),
                      ),
                      ActionChip(
                        label: Text(tr.tomorrow),
                        onPressed: () => selectTiming(tr.tomorrow),
                      ),
                      ActionChip(
                        avatar: const Icon(
                          Icons.calendar_today_outlined,
                          size: 20,
                        ),
                        label: Text(tr.chooseDateTime),
                        onPressed: () async {
                          final now = DateTime.now();
                          final date = await showDatePicker(
                            context: dialogContext,
                            initialDate: now,
                            firstDate: DateTime(now.year, now.month, now.day),
                            lastDate: DateTime(
                              now.year + 2,
                              now.month,
                              now.day,
                            ),
                          );
                          if (date == null || !dialogContext.mounted) return;
                          final time = await showTimePicker(
                            context: dialogContext,
                            initialTime: TimeOfDay.now(),
                          );
                          if (time == null || !dialogContext.mounted) return;
                          final arrival = DateTime(
                            date.year,
                            date.month,
                            date.day,
                            time.hour,
                            time.minute,
                          );
                          if (!arrival.isAfter(DateTime.now())) {
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              SnackBar(content: Text(tr.arrivalInFuture)),
                            );
                            return;
                          }
                          final labels = MaterialLocalizations.of(
                            dialogContext,
                          );
                          selectTiming(
                            tr.dateAtTime(
                              labels.formatFullDate(date),
                              labels.formatTimeOfDay(time),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: liters,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: tr.litersNeeded),
                  validator: (value) => (int.tryParse(value ?? '') ?? 0) > 0
                      ? null
                      : tr.positiveNumber,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: message,
                  maxLines: 3,
                  maxLength: 1000,
                  decoration: InputDecoration(
                    labelText: tr.arrivalMessage,
                    hintText: tr.arrivalMessageHint,
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? tr.arrivalMessageMissing
                      : null,
                ),
                const SizedBox(height: 12),
                if (repository.isDemo) Text(tr.demoNoMessage),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(tr.cancel),
          ),
          FilledButton(
            onPressed: () {
              if (form.currentState!.validate()) {
                Navigator.pop(dialogContext, true);
              }
            },
            child: Text(
              repository.isDemo ? tr.saveDemoRequest : tr.sendRequest,
            ),
          ),
        ],
      ),
    );
    if (submitted == true && mounted) {
      try {
        if (repository.isDemo) {
          demoRequests.add(
            '${place.name}\n${tr.litersAndMessage(int.parse(liters.text), message.text.trim())}',
          );
        } else {
          await repository.createRequest(
            place: place,
            liters: int.parse(liters.text),
            message: message.text.trim(),
            requester: requester,
          );
        }
        if (mounted) setState(() => page = 1);
      } on FirebaseException catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(tr.sendRequestFailed('${error.message}'))),
          );
        }
      }
    }
    // Dialog route animations finish before the controllers are disposed.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    message.dispose();
    liters.dispose();
  }

  Widget deleteRequestButton({
    required bool pending,
    required Future<void> Function() onDelete,
  }) => IconButton(
    tooltip: tr.deleteRequest,
    icon: Icon(
      Icons.delete_outline,
      color: Theme.of(context).colorScheme.error,
    ),
    onPressed: () async {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(tr.deleteRequestTitle),
          content: Text(
            pending ? tr.deleteSentPendingBody : tr.deleteRequestBody,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(tr.keep),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(dialogContext).colorScheme.error,
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(pending ? tr.cancelAndDelete : tr.delete),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
      try {
        await onDelete();
      } on FirebaseException catch (error) {
        showMessage(tr.deleteRequestFailed('${error.message}'));
        return;
      }
      showMessage(tr.requestDeleted);
    },
  );

  void showMessage(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
    );
  }

  Future<void> applyRoute(
    DistanceFilter target,
    List<WaterPlace> allPlaces,
    String busyLabel,
    Future<PlannedRoute> Function() plan,
  ) async {
    setState(() => busy = busyLabel);
    try {
      final planned = await plan();
      final found = await routeService.stopsAlong(
        planned,
        allPlaces,
        maxOffRoute: routeRadiiKm.last * 1000,
      );
      if (!mounted) return;
      setState(() {
        target
          ..route = planned
          ..stops = found
          ..places = allPlaces;
      });
    } catch (error) {
      showMessage(error);
    } finally {
      if (mounted) setState(() => busy = null);
    }
  }

  Future<LatLng> locate() =>
      widget.locate().timeout(const Duration(seconds: 20));

  Future<void> findNearby(List<WaterPlace> allPlaces) => applyRoute(
    nearMe,
    allPlaces,
    tr.locating,
    () async => PlannedRoute.around(await locate()),
  );

  Future<void> planRoute(List<WaterPlace> allPlaces) async {
    final AddressMatch? destination;
    try {
      destination = await widget.chooseDestination(context);
    } catch (error) {
      showMessage(error);
      return;
    }
    if (destination == null || !mounted) return;
    await applyRoute(
      onRoute,
      allPlaces,
      tr.planning,
      () async => routeService.route(
        await locate(),
        destination!.location,
        destination.label,
      ),
    );
  }

  void selectMode(DistanceMode value, List<WaterPlace> allPlaces) {
    setState(() => mode = value);
    if (value == DistanceMode.nearMe && nearMe.route == null && busy == null) {
      findNearby(allPlaces);
    }
  }

  /// Keeps tab results current when listings change while they are shown.
  Future<void> refreshStops(
    DistanceFilter target,
    List<WaterPlace> allPlaces,
  ) async {
    final planned = target.route;
    if (planned == null) return;
    target.places = allPlaces;
    try {
      final found = await routeService.stopsAlong(
        planned,
        allPlaces,
        maxOffRoute: routeRadiiKm.last * 1000,
      );
      if (mounted && identical(target.route, planned)) {
        setState(() => target.stops = found);
      }
    } catch (error) {
      showMessage(error);
    }
  }

  Widget busyIndicator() => const SizedBox.square(
    dimension: 18,
    child: CircularProgressIndicator(strokeWidth: 2),
  );

  Widget distancePanel(List<WaterPlace> allPlaces) {
    final target = active;
    if (target == null) return const SizedBox.shrink();
    final planned = target.route;
    if (planned == null) {
      return mode == DistanceMode.nearMe
          ? OutlinedButton.icon(
              onPressed: busy == null ? () => findNearby(allPlaces) : null,
              icon: busy == null
                  ? const Icon(Icons.my_location)
                  : busyIndicator(),
              label: Text(busy ?? tr.useMyLocation),
            )
          : OutlinedButton.icon(
              onPressed: busy == null ? () => planRoute(allPlaces) : null,
              icon: busy == null ? const Icon(Icons.search) : busyIndicator(),
              label: Text(busy ?? tr.chooseDestination),
            );
    }
    final aroundMe = planned.aroundStart;
    return Card(
      elevation: 0,
      color: Colors.white,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 4, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  aroundMe ? Icons.near_me_outlined : Icons.route_outlined,
                  color: teal,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        aroundMe
                            ? tr.nearYourLocation
                            : tr.toDestination(planned.destination),
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: ink,
                        ),
                      ),
                      Text(
                        aroundMe
                            ? tr.drivingFromYou
                            : tr.driveFromYou(formatKm(planned.meters)),
                        style: const TextStyle(fontSize: 12, color: muted),
                      ),
                    ],
                  ),
                ),
                if (busy != null)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: busyIndicator(),
                  )
                else if (aroundMe)
                  IconButton(
                    tooltip: tr.updateMyLocation,
                    onPressed: () => findNearby(allPlaces),
                    icon: const Icon(Icons.my_location),
                  )
                else ...[
                  IconButton(
                    tooltip: tr.changeDestination,
                    onPressed: () => planRoute(allPlaces),
                    icon: const Icon(Icons.edit_location_alt_outlined),
                  ),
                  IconButton(
                    tooltip: tr.clearRoute,
                    onPressed: () => setState(() {
                      onRoute
                        ..route = null
                        ..stops = null
                        ..places = null;
                    }),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Row(
                children: [
                  Text(tr.within),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SegmentedButton<int>(
                      showSelectedIcon: false,
                      segments: [
                        for (final km in routeRadiiKm)
                          ButtonSegment(value: km, label: Text('$km')),
                      ],
                      selected: {target.radiusKm},
                      onSelectionChanged: (value) =>
                          setState(() => target.radiusKm = value.single),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('km'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final destinations = [
      NavigationDestination(
        icon: Icon(Icons.explore_outlined),
        selectedIcon: Icon(Icons.explore),
        label: tr.findWater,
      ),
      NavigationDestination(
        icon: Icon(Icons.chat_bubble_outline),
        label: tr.requests,
      ),
    ];
    // Hot reload can retain the removed third tab from the combined app.
    final selectedPage = page >= 0 && page < destinations.length ? page : 0;
    return StreamBuilder<List<WaterPlace>>(
      stream: placesStream,
      initialData: repository.isDemo ? places : null,
      builder: (context, placesSnapshot) {
        final allPlaces = placesSnapshot.data ?? const <WaterPlace>[];
        if (busy == null && placesSnapshot.hasData) {
          for (final target in [nearMe, onRoute]) {
            if (target.route != null && !identical(target.places, allPlaces)) {
              refreshStops(target, allPlaces);
            }
          }
        }
        bool matches(WaterPlace p) =>
            '${p.name} ${p.area} ${p.host}'.toLowerCase().contains(
              query.toLowerCase(),
            ) &&
            (filter == 0 || (filter == 1 ? p.private : !p.private));
        final routeStops = {
          for (final stop in stops ?? const <RouteStop>[])
            if (filterDistance(route!, stop) <= radiusKm * 1000 &&
                matches(stop.place))
              stop.place: stop,
        };
        final visible = route == null
            ? allPlaces.where(matches).toList()
            : routeStops.keys.toList();
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              tooltip: tr.home,
              icon: const Icon(Icons.home_outlined),
              onPressed: widget.onHome ?? () => setState(() => page = 0),
            ),
            titleSpacing: 0,
            title: Text(
              tr.takeWater,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontWeight: FontWeight.w800, color: ink),
            ),
            actions: [
              if (widget.onOfferWater != null)
                TextButton.icon(
                  onPressed: widget.onOfferWater,
                  icon: const Icon(Icons.swap_horiz),
                  label: Text(tr.switchToOffer),
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
            selectedIndex: selectedPage,
            onDestinationSelected: (value) => setState(() => page = value),
            destinations: destinations,
          ),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: selectedPage == 0
                    ? ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          WaterBanner(
                            title: tr.bannerTakeTitle,
                            subtitle: tr.bannerTakeSubtitle,
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            onChanged: (value) => setState(() => query = value),
                            decoration: InputDecoration(
                              hintText: tr.searchPlaceHint,
                              prefixIcon: const Icon(Icons.search),
                              isDense: true,
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children:
                                  [
                                        tr.allPlaces,
                                        tr.privateHosts,
                                        tr.refillStops,
                                      ].indexed
                                      .map(
                                        (entry) => Padding(
                                          padding: const EdgeInsets.only(
                                            right: 8,
                                          ),
                                          child: ChoiceChip(
                                            label: Text(entry.$2),
                                            selected: filter == entry.$1,
                                            onSelected: (_) => setState(
                                              () => filter = entry.$1,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SegmentedButton<DistanceMode>(
                            showSelectedIcon: false,
                            segments: [
                              ButtonSegment(
                                value: DistanceMode.all,
                                label: Text(tr.all),
                              ),
                              ButtonSegment(
                                value: DistanceMode.nearMe,
                                label: Text(tr.nearMe),
                              ),
                              ButtonSegment(
                                value: DistanceMode.onRoute,
                                label: Text(tr.onMyRoute),
                              ),
                            ],
                            selected: {mode},
                            onSelectionChanged: (value) =>
                                selectMode(value.single, allPlaces),
                          ),
                          if (mode != DistanceMode.all) ...[
                            const SizedBox(height: 8),
                            distancePanel(allPlaces),
                          ],
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tr.discoverRefill,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge,
                                    ),
                                    Text(
                                      route != null
                                          ? route!.aroundStart
                                                ? tr.placesWithinYou(
                                                    visible.length,
                                                    radiusKm,
                                                  )
                                                : tr.placesWithinRoute(
                                                    visible.length,
                                                    radiusKm,
                                                  )
                                          : repository.isDemo
                                          ? tr.demoPlacesCount(visible.length)
                                          : tr.livePlacesCount(visible.length),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              FilledButton.tonalIcon(
                                onPressed: visible.isEmpty
                                    ? null
                                    : () async {
                                        final selected =
                                            await Navigator.of(
                                              context,
                                            ).push<WaterPlace>(
                                              MaterialPageRoute(
                                                builder: (_) => WaterPlacesMap(
                                                  places: visible,
                                                  route:
                                                      route?.aroundStart ==
                                                          false
                                                      ? route!.path
                                                      : null,
                                                ),
                                              ),
                                            );
                                        if (selected != null && mounted) {
                                          await showPlace(selected);
                                        }
                                      },
                                icon: const Icon(Icons.map_outlined),
                                label: Text(tr.map),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (placesSnapshot.hasError)
                            Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                tr.placesLoadFailed('${placesSnapshot.error}'),
                              ),
                            )
                          else if (!placesSnapshot.hasData &&
                              !repository.isDemo)
                            const Padding(
                              padding: EdgeInsets.all(24),
                              child: CircularProgressIndicator(),
                            )
                          else if (visible.isEmpty)
                            Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                route != null
                                    ? route!.aroundStart
                                          ? tr.noPlacesNearYou(radiusKm)
                                          : tr.noPlacesNearRoute(radiusKm)
                                    : tr.noPlacesMatch,
                              ),
                            ),
                          ...visible.map(
                            (place) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Card(
                                elevation: 0,
                                color: Colors.white,
                                margin: EdgeInsets.zero,
                                clipBehavior: Clip.antiAlias,
                                child: InkWell(
                                  onTap: () => showPlace(place),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 48,
                                          height: 48,
                                          clipBehavior: Clip.antiAlias,
                                          decoration: BoxDecoration(
                                            color: place.private
                                                ? foam
                                                : sky.withValues(alpha: 0.18),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: place.photo == null
                                              ? Icon(place.icon, color: teal)
                                              : Image.memory(
                                                  place.photo!,
                                                  fit: BoxFit.cover,
                                                ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                place.name,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w700,
                                                  color: ink,
                                                ),
                                              ),
                                              Text(
                                                '${place.area} · ${place.private ? tr.privateHost : tr.refillStop}',
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  color: muted,
                                                ),
                                              ),
                                              if (place.services.isNotEmpty)
                                                Text(
                                                  tr.alsoHereList(
                                                    serviceSummary(
                                                      place.services,
                                                    ),
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    color: ink,
                                                  ),
                                                ),
                                              Text(
                                                displayPrice(place.price),
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  color: ink,
                                                ),
                                              ),
                                              if (routeStops[place]
                                                  case final stop?)
                                                Text(
                                                  routeStopLabel(route!, stop),
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                    color: teal,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        const Icon(
                                          Icons.chevron_right,
                                          color: teal,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              tr.listFooter,
                              textAlign: TextAlign.center,
                              style: TextStyle(color: teal),
                            ),
                          ),
                        ],
                      )
                    : ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          Text(
                            tr.yourRequests,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            repository.isDemo
                                ? tr.demoRequestsNote
                                : tr.requestsIntro,
                          ),
                          const SizedBox(height: 12),
                          if (repository.isDemo && demoRequests.isEmpty)
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(Icons.chat_bubble_outline),
                              title: Text(tr.nextStopTitle),
                              subtitle: Text(tr.nextStopHint),
                            ),
                          if (!repository.isDemo)
                            StreamBuilder<List<RefillRequest>>(
                              stream: requestsStream,
                              builder: (context, requestSnapshot) {
                                if (requestSnapshot.hasError) {
                                  return ListTile(
                                    title: Text(
                                      tr.requestsLoadFailed(
                                        '${requestSnapshot.error}',
                                      ),
                                    ),
                                  );
                                }
                                final savedRequests =
                                    requestSnapshot.data ?? const [];
                                if (savedRequests.isEmpty) {
                                  return ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: Icon(Icons.chat_bubble_outline),
                                    title: Text(tr.nextStopTitle),
                                    subtitle: Text(tr.nextStopHint),
                                  );
                                }
                                return Column(
                                  children: savedRequests
                                      .map(
                                        (request) => Card(
                                          child: ListTile(
                                            isThreeLine: true,
                                            leading: const Icon(
                                              Icons.water_drop_outlined,
                                              color: teal,
                                            ),
                                            title: Text(request.placeName),
                                            subtitle: Text(
                                              tr.requestSummary(
                                                request.liters,
                                                request.message,
                                                requestStatus(request.status),
                                              ),
                                            ),
                                            trailing: deleteRequestButton(
                                              pending:
                                                  request.status == 'pending',
                                              onDelete: () => repository
                                                  .deleteMyRequest(request),
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                );
                              },
                            ),
                          ...demoRequests.map(
                            (request) => Card(
                              child: ListTile(
                                isThreeLine: true,
                                leading: const Icon(
                                  Icons.water_drop_outlined,
                                  color: teal,
                                ),
                                title: Text(request.split('\n').first),
                                subtitle: Text(
                                  tr.demoPrefix(
                                    request.split('\n').skip(1).join('\n'),
                                  ),
                                ),
                                trailing: deleteRequestButton(
                                  pending: true,
                                  onDelete: () async => setState(
                                    () => demoRequests.remove(request),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        );
      },
    );
  }
}
