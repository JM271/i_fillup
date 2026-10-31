import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

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
    ? '${(meters / 1000).toStringAsFixed(1)} km'
    : '${(meters / 1000).round()} km';

const routeRadiiKm = [1, 2, 5, 10, 25];

String routeStopLabel(PlannedRoute route, RouteStop stop) {
  if (route.aroundStart) {
    return stop.along < 100
        ? 'At your location'
        : '${formatKm(stop.along)} away';
  }
  return [
    stop.along < 100 ? 'At your start' : 'After ${formatKm(stop.along)}',
    stop.offRoute < 100 ? 'on route' : '${formatKm(stop.offRoute)} off route',
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
  String filter = 'All places';
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
              Text('${place.area} · ${place.price}'),
              const SizedBox(height: 12),
              Text('Opening times: ${place.openingTimes}'),
              if (place.vehicles.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Suitable for: ${vehicleSummary(place.vehicles)}'),
              ],
              const SizedBox(height: 20),
              Text(
                place.description,
                style: const TextStyle(fontSize: 16, height: 1.5),
              ),
              const SizedBox(height: 16),
              Text(
                repository.isDemo
                    ? 'Demo listing. Water quality, availability and prices have not been verified. Confirm drinking-water suitability with the host.'
                    : 'Confirm water suitability, access and availability with the host before arriving.',
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    requestWater(place);
                  },
                  child: Text('Arrange a fill-up with ${place.host}'),
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
      showMessage('Could not load your profile. Please try again.');
      return;
    }
    if (!mounted) return;
    profile ??= await Navigator.of(context).push<TravelerProfile>(
      MaterialPageRoute(
        builder: (_) => ProfilePage(
          onSave: repository.saveMyProfile,
          intro: 'Before your first request, tell hosts who is coming. They see this profile on the requests you send them.',
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
        title: const Text('Plan a fill-up'),
        content: SingleChildScrollView(
          child: Form(
            key: form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('To ${place.host}'),
                Text(
                  'From ${requester.name} · ${requester.vehicle}',
                  style: const TextStyle(color: Color(0xFF617575)),
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
                        label: const Text('ASAP'),
                        tooltip: 'Request a fill-up as soon as possible',
                        onPressed: () => selectTiming('ASAP'),
                      ),
                      ActionChip(
                        label: const Text('Today'),
                        onPressed: () => selectTiming('Today'),
                      ),
                      ActionChip(
                        label: const Text('Tomorrow'),
                        onPressed: () => selectTiming('Tomorrow'),
                      ),
                      ActionChip(
                        avatar: const Icon(
                          Icons.calendar_today_outlined,
                          size: 20,
                        ),
                        label: const Text('Choose date & time'),
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
                              const SnackBar(
                                content: Text(
                                  'Choose an arrival time in the future.',
                                ),
                              ),
                            );
                            return;
                          }
                          final labels = MaterialLocalizations.of(
                            dialogContext,
                          );
                          selectTiming(
                            '${labels.formatFullDate(date)} at ${labels.formatTimeOfDay(time)}',
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
                  decoration: const InputDecoration(
                    labelText: 'Water needed (liters)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => (int.tryParse(value ?? '') ?? 0) > 0
                      ? null
                      : 'Enter a positive number',
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: message,
                  maxLines: 3,
                  maxLength: 1000,
                  decoration: const InputDecoration(
                    labelText: 'Arrival time & message',
                    hintText: 'Tomorrow at 10:00, with a 6 m campervan…',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Add your arrival time and a message'
                      : null,
                ),
                const SizedBox(height: 12),
                if (repository.isDemo)
                  const Text('Demo only. No message is sent to a host.'),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (form.currentState!.validate()) {
                Navigator.pop(dialogContext, true);
              }
            },
            child: Text(
              repository.isDemo ? 'Save demo request' : 'Send refill request',
            ),
          ),
        ],
      ),
    );
    if (submitted == true && mounted) {
      try {
        if (repository.isDemo) {
          demoRequests.add(
            '${place.name}\n${liters.text} liters · ${message.text.trim()}',
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
            SnackBar(content: Text('Could not send request: ${error.message}')),
          );
        }
      }
    }
    // Dialog route animations finish before the controllers are disposed.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    message.dispose();
    liters.dispose();
  }

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
    'Locating…',
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
      'Planning…',
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
              label: Text(busy ?? 'Use my location'),
            )
          : OutlinedButton.icon(
              onPressed: busy == null ? () => planRoute(allPlaces) : null,
              icon: busy == null ? const Icon(Icons.search) : busyIndicator(),
              label: Text(busy ?? 'Choose a destination'),
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
                            ? 'Near your location'
                            : 'To ${planned.destination}',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: ink,
                        ),
                      ),
                      Text(
                        aroundMe
                            ? 'Driving distance from where you are'
                            : '${formatKm(planned.meters)} drive from your location',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF617575),
                        ),
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
                    tooltip: 'Update my location',
                    onPressed: () => findNearby(allPlaces),
                    icon: const Icon(Icons.my_location),
                  )
                else ...[
                  IconButton(
                    tooltip: 'Change destination',
                    onPressed: () => planRoute(allPlaces),
                    icon: const Icon(Icons.edit_location_alt_outlined),
                  ),
                  IconButton(
                    tooltip: 'Clear route',
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
                  const Text('Within'),
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
    const destinations = [
      NavigationDestination(
        icon: Icon(Icons.explore_outlined),
        selectedIcon: Icon(Icons.explore),
        label: 'Find water',
      ),
      NavigationDestination(
        icon: Icon(Icons.chat_bubble_outline),
        label: 'Requests',
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
            (filter == 'All places' ||
                (filter == 'Private hosts' ? p.private : !p.private));
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
            backgroundColor: const Color(0xFFF6F8F4),
            leading: IconButton(
              tooltip: 'Home',
              icon: const Icon(Icons.home_outlined),
              onPressed: widget.onHome ?? () => setState(() => page = 0),
            ),
            titleSpacing: 0,
            title: const Text(
              'Take water',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontWeight: FontWeight.w800, color: ink),
            ),
            actions: [
              if (widget.onOfferWater != null)
                TextButton.icon(
                  onPressed: widget.onOfferWater,
                  icon: const Icon(Icons.swap_horiz),
                  label: const Text('Offer water'),
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
                          Text(
                            'Fresh water.\nOpen roads.',
                            style: Theme.of(context).textTheme.headlineLarge,
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Refill stops and private hosts for your campervan.',
                            style: TextStyle(color: Color(0xFF617575)),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            onChanged: (value) => setState(() => query = value),
                            decoration: InputDecoration(
                              hintText: 'Search a town or place',
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
                                        'All places',
                                        'Private hosts',
                                        'Refill stops',
                                      ]
                                      .map(
                                        (label) => Padding(
                                          padding: const EdgeInsets.only(
                                            right: 8,
                                          ),
                                          child: ChoiceChip(
                                            label: Text(label),
                                            selected: filter == label,
                                            onSelected: (_) =>
                                                setState(() => filter = label),
                                          ),
                                        ),
                                      )
                                      .toList(),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SegmentedButton<DistanceMode>(
                            showSelectedIcon: false,
                            segments: const [
                              ButtonSegment(
                                value: DistanceMode.all,
                                label: Text('All'),
                              ),
                              ButtonSegment(
                                value: DistanceMode.nearMe,
                                label: Text('Near me'),
                              ),
                              ButtonSegment(
                                value: DistanceMode.onRoute,
                                label: Text('On my route'),
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
                                      'Discover a refill',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge,
                                    ),
                                    Text(
                                      route != null
                                          ? '${visible.length} ${visible.length == 1 ? 'place' : 'places'} within $radiusKm km of ${route!.aroundStart ? 'you' : 'your route'}'
                                          : '${visible.length} ${repository.isDemo ? 'demo ' : ''}places · ${repository.isDemo ? 'Sample places in Switzerland' : 'Live community listings'}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF617575),
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
                                label: const Text('Map'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (placesSnapshot.hasError)
                            Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                'Could not load places: ${placesSnapshot.error}',
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
                                    ? 'No places within $radiusKm km of ${route!.aroundStart ? 'you' : 'your route'}. Try a wider distance.'
                                    : 'No places match. Try a different town or filter.',
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
                                                ? const Color(0xFFDDEBE0)
                                                : const Color(0xFFDCECEE),
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
                                                '${place.area} · ${place.private ? 'Private host' : 'Refill stop'}',
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  color: Color(0xFF617575),
                                                ),
                                              ),
                                              Text(
                                                place.price,
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
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              'A small stop. A big help for your next adventure.',
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
                            'Your requests',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            repository.isDemo
                                ? 'Demo previews only. Nothing is sent, and previews clear when the app restarts.'
                                : 'Your refill requests and their status appear here.',
                          ),
                          const SizedBox(height: 12),
                          if (repository.isDemo && demoRequests.isEmpty)
                            const ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(Icons.chat_bubble_outline),
                              title: Text('Your next stop starts here'),
                              subtitle: Text(
                                'Choose a place and arrange a fill-up.',
                              ),
                            ),
                          if (!repository.isDemo)
                            StreamBuilder<List<RefillRequest>>(
                              stream: requestsStream,
                              builder: (context, requestSnapshot) {
                                if (requestSnapshot.hasError) {
                                  return ListTile(
                                    title: Text(
                                      'Could not load requests: ${requestSnapshot.error}',
                                    ),
                                  );
                                }
                                final savedRequests =
                                    requestSnapshot.data ?? const [];
                                if (savedRequests.isEmpty) {
                                  return const ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: Icon(Icons.chat_bubble_outline),
                                    title: Text('Your next stop starts here'),
                                    subtitle: Text(
                                      'Choose a place and arrange a fill-up.',
                                    ),
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
                                              '${request.liters} liters · ${request.message}\nStatus: ${request.status}',
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
                                  'Demo · ${request.split('\n').skip(1).join('\n')}',
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
