import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:i_fillup/address_search.dart';
import 'package:i_fillup/route_planner.dart';
import 'package:i_fillup/take_water_home.dart';
import 'package:i_fillup/water_place.dart';
import 'package:latlong2/latlong.dart';

const thun = LatLng(46.758, 7.628);
const interlaken = LatLng(46.686, 7.863);

class FakeRouteService implements RouteService {
  @override
  Future<PlannedRoute> route(
    LatLng start,
    LatLng end,
    String destination,
  ) async => PlannedRoute(
    destination: destination,
    start: start,
    end: end,
    path: [start, end],
    meters: 30700,
  );

  @override
  Future<List<RouteStop>> stopsAlong(
    PlannedRoute route,
    List<WaterPlace> places, {
    required double maxOffRoute,
  }) async => [
    RouteStop(places[2], along: 14000, offRoute: 500),
    RouteStop(places[1], along: 30000, offRoute: 8000),
    RouteStop(places[0], along: 50, offRoute: 20),
  ];
}

void main() {
  test('Distance to path measures to the nearest segment', () {
    // Spiez lies about 5.6 km off the straight Thun–Interlaken line.
    final meters = distanceToPath(const LatLng(46.687, 7.680), [
      thun,
      interlaken,
    ]);
    expect(meters, inInclusiveRange(5000, 6000));
    expect(distanceToPath(thun, [thun, interlaken]), lessThan(1));
    expect(distanceToPath(thun, const []), double.infinity);
  });

  test(
    'OSRM route and table give driving distance along and off route',
    () async {
      final requests = <Uri>[];
      final service = OsrmRouteService(
        client: MockClient((request) async {
          requests.add(request.url);
          final body = request.url.path.contains('/route/')
              ? {
                  'code': 'Ok',
                  'routes': [
                    {
                      'distance': 30700,
                      'geometry': {
                        'coordinates': [
                          [7.628, 46.758],
                          [7.680, 46.690],
                          [7.863, 46.686],
                        ],
                      },
                    },
                  ],
                }
              : {
                  'code': 'Ok',
                  'distances': [
                    [30700, 14000],
                    [17700, 0],
                  ],
                };
          return http.Response(jsonEncode(body), 200);
        }),
      );
      final planned = await service.route(thun, interlaken, 'Interlaken');
      expect(planned.path, hasLength(3));
      const zurich = WaterPlace(
        'City tap',
        'Zurich, Switzerland',
        'Mia',
        true,
        'Free',
        'Far from the route.',
        Icons.cottage_outlined,
        LatLng(47.37, 8.54),
      );
      final stops = await service.stopsAlong(planned, [
        places[2],
        zurich,
      ], maxOffRoute: 5000);
      // Only Spiez is near enough to the route to be checked by driving.
      expect(stops.single.place.area, 'Spiez, Switzerland');
      expect(stops.single.along, 14000);
      expect(stops.single.offRoute, 500);
      expect(requests.last.queryParameters['sources'], '0;2');
      expect(requests.last.queryParameters['destinations'], '1;2');
    },
  );

  test('OSRM reports when no route exists', () async {
    final service = OsrmRouteService(
      client: MockClient(
        (_) async => http.Response(jsonEncode({'code': 'NoRoute'}), 200),
      ),
    );
    expect(
      service.route(thun, interlaken, 'Interlaken'),
      throwsA(
        isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('No driving route'),
        ),
      ),
    );
  });

  testWidgets('Plan a route shows places within the chosen distance', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: RefillHome(
          routeService: FakeRouteService(),
          locate: () async => thun,
          chooseDestination: (_) async =>
              const AddressMatch('Interlaken', interlaken),
        ),
      ),
    );
    await tester.tap(find.text('On my route'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose a destination'));
    await tester.pumpAndSettle();
    expect(find.text('To Interlaken'), findsOneWidget);
    expect(find.text('31 km drive from your location'), findsOneWidget);
    expect(find.text('2 places within 5 km of your route'), findsOneWidget);
    expect(find.text('At your start · on route'), findsOneWidget);
    expect(find.text('After 14 km · 0.5 km off route'), findsOneWidget);
    expect(find.text('Riverside camper stop'), findsNothing);

    await tester.tap(find.text('10'));
    await tester.pumpAndSettle();
    expect(find.text('3 places within 10 km of your route'), findsOneWidget);
    expect(find.text('After 30 km · 8.0 km off route'), findsOneWidget);

    // Each tab keeps its own results and distance.
    await tester.tap(find.text('Near me'));
    await tester.pumpAndSettle();
    expect(find.text('Near your location'), findsOneWidget);
    expect(find.text('1 place within 5 km of you'), findsOneWidget);
    await tester.tap(find.text('On my route'));
    await tester.pumpAndSettle();
    expect(find.text('To Interlaken'), findsOneWidget);
    expect(find.text('3 places within 10 km of your route'), findsOneWidget);

    await tester.tap(find.text('All'));
    await tester.pumpAndSettle();
    expect(find.textContaining('3 demo places'), findsOneWidget);

    await tester.tap(find.text('On my route'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Clear route'));
    await tester.pumpAndSettle();
    expect(find.text('Choose a destination'), findsOneWidget);
  });

  testWidgets('Near me shows places within driving distance of you', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: RefillHome(
          routeService: FakeRouteService(),
          locate: () async => thun,
          chooseDestination: (_) async => null,
        ),
      ),
    );
    await tester.tap(find.text('Near me'));
    await tester.pumpAndSettle();
    expect(find.text('Near your location'), findsOneWidget);
    expect(find.text('1 place within 5 km of you'), findsOneWidget);
    expect(find.text('At your location'), findsOneWidget);

    await tester.tap(find.text('25'));
    await tester.pumpAndSettle();
    expect(find.text('2 places within 25 km of you'), findsOneWidget);
    expect(find.text('14 km away'), findsOneWidget);
    expect(find.text('Riverside camper stop'), findsNothing);

    await tester.tap(find.text('All'));
    await tester.pumpAndSettle();
    expect(find.textContaining('3 demo places'), findsOneWidget);
  });
}
