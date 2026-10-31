import 'app_switch_button.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app_style.dart';
import 'firebase_options_taker.dart' as taker_options;
import 'firebase_startup.dart';
import 'water_place.dart';
export 'app_style.dart';
export 'water_place.dart';

import 'water_repository.dart';
import 'water_places_map.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final repository = await FirebaseWaterRepository.connect(
      taker_options.DefaultFirebaseOptions.currentPlatform,
    );
    runApp(MyApp(repository: repository));
  } on FirebaseException catch (error, stackTrace) {
    debugPrintStack(stackTrace: stackTrace);
    runApp(
      FirebaseStartupError(error: error, onRetry: main, preview: const MyApp()),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.repository});
  final WaterRepository? repository;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'i fillup · Take water',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFF6F8F4),
      colorScheme: ColorScheme.fromSeed(seedColor: teal),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w800,
          color: ink,
          height: 1.12,
        ),
        titleLarge: TextStyle(fontWeight: FontWeight.w700, color: ink),
      ),
    ),
    home: RefillHome(repository: repository),
  );
}

class RefillHome extends StatefulWidget {
  const RefillHome({super.key, this.repository});
  final WaterRepository? repository;

  @override
  State<RefillHome> createState() => _RefillHomeState();
}

class _RefillHomeState extends State<RefillHome> {
  String query = '';
  String filter = 'All places';
  int page = 0;
  final List<String> demoRequests = [];

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
              Icon(place.icon, size: 48, color: teal),
              const SizedBox(height: 16),
              Text(
                place.name,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Text('${place.area} · ${place.price}'),
              const SizedBox(height: 12),
              Text('Opening times: ${place.openingTimes}'),
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
    final form = GlobalKey<FormState>();
    final message = TextEditingController();
    final liters = TextEditingController(text: '80');
    final submitted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Plan your fill-up'),
        content: SingleChildScrollView(
          child: Form(
            key: form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('To ${place.host}'),
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
        final visible = allPlaces
            .where(
              (p) =>
                  '${p.name} ${p.area} ${p.host}'.toLowerCase().contains(
                    query.toLowerCase(),
                  ) &&
                  (filter == 'All places' ||
                      (filter == 'Private hosts' ? p.private : !p.private)),
            )
            .toList();
        return Scaffold(
          appBar: AppBar(
            backgroundColor: const Color(0xFFF6F8F4),
            title: const Row(
              children: [
                Icon(Icons.water_drop, color: teal),
                SizedBox(width: 8),
                Text(
                  'i fillup · Take',
                  style: TextStyle(fontWeight: FontWeight.w800, color: ink),
                ),
              ],
            ),
            actions: const [AppSwitchButton(toGiver: true)],
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
                        padding: const EdgeInsets.all(24),
                        children: [
                          const Text(
                            'LESS SEARCHING. MORE EXPLORING.',
                            style: TextStyle(
                              color: teal,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Fresh water.\nOpen roads.',
                            style: Theme.of(context).textTheme.headlineLarge,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Find a refill stop for your campervan.\nConnect with local places and friendly private hosts.',
                            style: TextStyle(
                              color: Color(0xFF617575),
                              height: 1.5,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 24),
                          TextField(
                            onChanged: (value) => setState(() => query = value),
                            decoration: InputDecoration(
                              hintText: 'Search a town or place',
                              prefixIcon: const Icon(Icons.search),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            children:
                                ['All places', 'Private hosts', 'Refill stops']
                                    .map(
                                      (label) => ChoiceChip(
                                        label: Text(label),
                                        selected: filter == label,
                                        onSelected: (_) =>
                                            setState(() => filter = label),
                                      ),
                                    )
                                    .toList(),
                          ),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: visible.isEmpty
                                ? null
                                : () async {
                                    final selected = await Navigator.of(context)
                                        .push<WaterPlace>(
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                WaterPlacesMap(places: visible),
                                          ),
                                        );
                                    if (selected != null && mounted) {
                                      await showPlace(selected);
                                    }
                                  },
                            icon: const Icon(Icons.map_outlined),
                            label: Text('Show ${visible.length} places on map'),
                          ),
                          const SizedBox(height: 26),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Discover a refill',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              Text(
                                '${visible.length} ${repository.isDemo ? 'demo ' : ''}places',
                                style: const TextStyle(
                                  color: Color(0xFF617575),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            repository.isDemo
                                ? 'Sample places in Switzerland · No live location used'
                                : 'Live community listings',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF617575),
                            ),
                          ),
                          const SizedBox(height: 16),
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
                            const Padding(
                              padding: EdgeInsets.all(24),
                              child: Text(
                                'No places match. Try a different town or filter.',
                              ),
                            ),
                          ...visible.map(
                            (place) => Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Card(
                                elevation: 0,
                                color: Colors.white,
                                margin: EdgeInsets.zero,
                                clipBehavior: Clip.antiAlias,
                                child: InkWell(
                                  onTap: () => showPlace(place),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        height: 112,
                                        color: place.private
                                            ? const Color(0xFFDDEBE0)
                                            : const Color(0xFFDCECEE),
                                        padding: const EdgeInsets.all(20),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Icon(
                                              place.icon,
                                              size: 64,
                                              color: teal,
                                            ),
                                            Chip(
                                              label: Text(
                                                place.private
                                                    ? 'Private host'
                                                    : 'Refill stop',
                                              ),
                                              backgroundColor: Colors.white,
                                              side: BorderSide.none,
                                            ),
                                          ],
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(18),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              place.name,
                                              style: const TextStyle(
                                                fontSize: 19,
                                                fontWeight: FontWeight.w700,
                                                color: ink,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              place.area,
                                              style: const TextStyle(
                                                color: Color(0xFF617575),
                                              ),
                                            ),
                                            const SizedBox(height: 16),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    place.price,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: ink,
                                                    ),
                                                  ),
                                                ),
                                                const Text(
                                                  'View place',
                                                  style: TextStyle(
                                                    color: teal,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                const Icon(
                                                  Icons.arrow_forward,
                                                  size: 18,
                                                  color: teal,
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              'A small stop. A big help for your next adventure.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: teal),
                            ),
                          ),
                        ],
                      )
                    : ListView(
                        padding: const EdgeInsets.all(24),
                        children: [
                          Text(
                            'Your requests',
                            style: Theme.of(context).textTheme.headlineLarge,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            repository.isDemo
                                ? 'Demo previews only. Nothing is sent, and previews clear when the app restarts.'
                                : 'Your refill requests and their status appear here.',
                          ),
                          const SizedBox(height: 24),
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
