import 'package:firebase_core/firebase_core.dart';
import 'package:i_fillup/firebase_startup.dart';
import 'package:flutter/services.dart';
import 'package:i_fillup/google_address_picker.dart';
import 'package:i_fillup/address_search.dart';

import 'dart:async';

import 'package:i_fillup/giver_app.dart';

import 'package:latlong2/latlong.dart';
import 'package:i_fillup/location_picker.dart';

import 'dart:convert';

import 'package:flutter_map/flutter_map.dart';
import 'package:i_fillup/water_places_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:i_fillup/main.dart';
import 'package:i_fillup/offer_water_form.dart';

class TestTiles extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      MemoryImage(
        base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVQIHWP4z8DwHwAFgAI/ScLbtAAAAABJRU5ErkJggg==',
        ),
      );
}

void main() {
  testWidgets(
    'Missing Firebase configuration offers retry and explicit preview',
    (tester) async {
      var retries = 0;
      await tester.pumpWidget(
        FirebaseStartupError(
          error: FirebaseException(
            plugin: 'firebase_auth',
            code: 'unknown',
            message: 'CONFIGURATION_NOT_FOUND',
          ),
          onRetry: () async {
            retries++;
          },
          preview: const MyApp(),
        ),
      );
      expect(
        find.textContaining('Email/Password sign-in provider'),
        findsOneWidget,
      );
      await tester.tap(find.text('Retry cloud connection'));
      await tester.pumpAndSettle();
      expect(retries, 1);
      expect(find.text('Open preview without cloud'), findsOneWidget);
    },
  );

  testWidgets(
    'Google picker returns a selected address and handles cancellation',
    (tester) async {
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(googlePlacesChannel, (call) async {
        expect(call.method, 'chooseAddress');
        expect(call.arguments['query'], 'Thun');
        return {
          'address': 'Main street 1, Thun',
          'latitude': 46.76,
          'longitude': 7.63,
        };
      });
      addTearDown(
        () => messenger.setMockMethodCallHandler(googlePlacesChannel, null),
      );
      final selected = await chooseGoogleAddress('Thun');
      expect(selected!.label, 'Main street 1, Thun');
      expect(selected.location.latitude, 46.76);
      messenger.setMockMethodCallHandler(
        googlePlacesChannel,
        (_) async => null,
      );
      expect(await chooseGoogleAddress(''), isNull);
      messenger.setMockMethodCallHandler(
        googlePlacesChannel,
        (_) async => {'address': '', 'latitude': 900, 'longitude': 0},
      );
      await expectLater(
        chooseGoogleAddress(''),
        throwsA(isA<PlatformException>()),
      );
    },
  );

  testWidgets(
    'Choosing an address fills the address and pin in a saved offer',
    (tester) async {
      WaterPlace? saved;
      var calls = 0;
      var pending = Completer<void>();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OfferWaterForm(
              onSave: (place) async {
                calls++;
                await pending.future;
                saved = place;
              },
              addressLookup: (query) async => [
                const AddressMatch('Main street 1, Thun', LatLng(46.76, 7.63)),
              ],
            ),
          ),
        ),
      );
      await tester.enterText(find.byType(TextFormField).at(0), 'Garden tap');
      await tester.tap(find.text('Choose address from list'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Main street Thun');
      await tester.tap(find.text('Search addresses'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Main street 1, Thun'));
      await tester.pumpAndSettle();
      expect(find.text('Pin: 46.76000, 7.63000'), findsOneWidget);
      await tester.enterText(
        find.byType(TextFormField).at(2),
        'Mon–Fri 08:00–18:00',
      );
      await tester.ensureVisible(find.text('Save offer'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save offer'));
      await tester.pump();
      expect(find.text('Saving…'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'Saving…'))
            .onPressed,
        isNull,
      );
      expect(calls, 1);
      pending.completeError(Exception('offline'));
      await tester.pumpAndSettle();
      expect(
        find.text('Could not save offer. Please try again.'),
        findsOneWidget,
      );
      expect(find.text('Garden tap'), findsOneWidget);
      expect(find.text('Pin: 46.76000, 7.63000'), findsOneWidget);
      pending = Completer<void>();
      await tester.tap(find.text('Save offer'));
      await tester.pump();
      pending.complete();
      await tester.pumpAndSettle();
      expect(calls, 2);
      expect(saved!.area, 'Main street 1, Thun');
      expect(saved!.location.latitude, 46.76);
      expect(saved!.openingTimes, 'Mon–Fri 08:00–18:00');
    },
  );

  testWidgets('Address search handles empty results and connection errors', (
    tester,
  ) async {
    var fail = false;
    await tester.pumpWidget(
      MaterialApp(
        home: AddressSearchPage(
          lookup: (_) async {
            if (fail) throw Exception('offline');
            return [];
          },
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), 'Thun');
    await tester.tap(find.text('Search addresses'));
    await tester.pumpAndSettle();
    expect(find.text('No addresses found'), findsOneWidget);
    fail = true;
    await tester.tap(find.text('Search addresses'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Could not search addresses'), findsOneWidget);
  });

  test('Photon coordinates convert from longitude/latitude and reject invalid points', () {
    final matches = parseAddressMatches({
      'features': [
        {
          'geometry': {
            'coordinates': [7.63, 46.76],
          },
          'properties': {
            'street': 'Main street',
            'housenumber': '1',
            'city': 'Thun',
          },
        },
        {
          'geometry': {
            'coordinates': [999, 999],
          },
          'properties': {'name': 'Invalid'},
        },
      ],
    });
    expect(matches.single.label, 'Main street 1, Thun');
    expect(matches.single.location.latitude, 46.76);
    expect(matches.single.location.longitude, 7.63);
  });

  testWidgets('Taker recovers a removed tab retained by hot reload', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.tap(find.text('Take water'));
    await tester.pumpAndSettle();
    final dynamic state = tester.state(find.byType(RefillHome));
    state.page = 2;
    tester.element(find.byType(RefillHome)).markNeedsBuild();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      0,
    );
    expect(find.text('Fresh water.\nOpen roads.'), findsOneWidget);
    await tester.tap(find.text('Requests'));
    await tester.pumpAndSettle();
    expect(find.text('Your requests'), findsOneWidget);
  });

  testWidgets(
    'Location picker centers on current position and handles failure',
    (tester) async {
      final result = Completer<LatLng>();
      await tester.pumpWidget(
        MaterialApp(
          home: LocationPicker(
            locate: () => result.future,
            tileProvider: TestTiles(),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      result.complete(const LatLng(47.37, 8.54));
      await tester.pumpAndSettle();
      final map = tester.widget<FlutterMap>(find.byType(FlutterMap));
      expect(map.mapController!.camera.center.latitude, closeTo(47.37, 0.0001));
      expect(map.mapController!.camera.zoom, 16);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Use this location'),
            )
            .onPressed,
        isNotNull,
      );
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        MaterialApp(
          home: LocationPicker(
            locate: () async =>
                throw Exception('Location permission was denied.'),
            tileProvider: TestTiles(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Location permission was denied.'), findsOneWidget);
      expect(find.byType(FlutterMap), findsOneWidget);
      expect(find.text('My location'), findsOneWidget);
    },
  );

  test('Refill pricing accepts CHF decimals and free refills', () {
    expect(refillPriceLabel('5,50'), 'CHF 5.50 / fill');
    expect(refillPriceLabel('0'), 'Free');
    for (final value in ['', '-5', 'NaN', 'Infinity', '1.234', 'abc']) {
      expect(refillPriceLabel(value), isNull);
    }
  });

  testWidgets('Offer requires a place, opening times and map pin', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    WaterPlace? saved;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OfferWaterForm(onSave: (place) async => saved = place),
        ),
      ),
    );
    await tester.ensureVisible(find.text('Save offer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save offer'));
    await tester.pumpAndSettle();
    expect(find.text('Please fill in this field'), findsNWidgets(3));
    expect(find.text('Choose your place on the map.'), findsOneWidget);
    expect(saved, isNull);
    await tester.enterText(find.byType(TextFormField).at(0), 'Garden tap');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'Main street 1, Thun',
    );
    await tester.enterText(
      find.byType(TextFormField).at(2),
      'Mon–Fri 08:00–18:00; weekends closed',
    );
    await tester.ensureVisible(find.text('Save offer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save offer'));
    await tester.pumpAndSettle();
    expect(find.text('Please fill in this field'), findsNothing);
    expect(saved, isNull);
  });

  testWidgets('Map shows filtered markers and returns the selected place', (
    tester,
  ) async {
    WaterPlace? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                selected = await Navigator.of(context).push<WaterPlace>(
                  MaterialPageRoute(
                    builder: (_) => WaterPlacesMap(
                      places: [places[1]],
                      tileProvider: TestTiles(),
                    ),
                  ),
                );
              },
              child: const Text('Open map'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open map'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('map-A little stop by the lake')),
      findsNothing,
    );
    await tester.tap(find.byKey(const ValueKey('map-Riverside camper stop')));
    await tester.pumpAndSettle();
    expect(selected, same(places[1]));
  });

  testWidgets('Find places, filter and save a demo refill request', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.tap(find.text('Take water'));
    await tester.pumpAndSettle();
    expect(find.text('Fresh water.\nOpen roads.'), findsOneWidget);
    await tester.tap(find.text('Refill stops'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('1 demo places'),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('1 demo places'), findsOneWidget);
    expect(find.text('A little stop by the lake'), findsNothing);
    await tester.scrollUntilVisible(
      find.text('Riverside camper stop'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Riverside camper stop'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Arrange a fill-up with Riverside campsite'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save demo request'));
    await tester.pumpAndSettle();
    expect(find.text('Add your arrival time and a message'), findsOneWidget);
    await tester.enterText(
      find.byType(TextFormField).last,
      'Tomorrow at 10:00',
    );
    await tester.tap(find.text('Save demo request'));
    await tester.pumpAndSettle();
    expect(find.text('Your requests'), findsOneWidget);
    expect(
      find.textContaining('80 liters · Tomorrow at 10:00'),
      findsOneWidget,
    );
  });

  testWidgets('Search shows empty state and offer tab explains host flow', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.tap(find.text('Take water'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'unknown town');
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.textContaining('No places match'),
      150,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('No places match'), findsOneWidget);
    expect(find.text('Offer water'), findsOneWidget);
    await tester.pumpWidget(const WaterGiverApp());
    await tester.tap(find.text('Offer water'));
    await tester.pumpAndSettle();
    expect(find.text('Your water places'), findsOneWidget);
    await tester.tap(find.text('Offer water').last);
    await tester.pumpAndSettle();
    expect(find.text('Offer water.\nEarn cash.'), findsOneWidget);
    expect(find.text('Find water'), findsNothing);
  });
  testWidgets('i fillup home opens both sides and preserves an offer draft', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    expect(find.text('Welcome to i fillup'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Take water'));
    await tester.pumpAndSettle();
    expect(find.text('Fresh water.\nOpen roads.'), findsOneWidget);
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome to i fillup'), findsOneWidget);
    await tester.tap(find.text('Offer water'));
    await tester.pumpAndSettle();
    expect(find.text('Your water places'), findsOneWidget);
    await tester.tap(find.text('Offer water').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'My draft refill');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Offer water'));
    await tester.pumpAndSettle();
    expect(find.text('My draft refill'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'Fill-up timing choices preserve the message and submit the selected timing',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: RefillHome()));
      final dynamic state = tester.state(find.byType(RefillHome));
      state.requestWater(places.first);
      await tester.pumpAndSettle();
      expect(find.text('Plan a fill-up'), findsOneWidget);
      for (final label in ['ASAP', 'Today', 'Tomorrow', 'Choose date & time']) {
        expect(find.widgetWithText(ActionChip, label), findsOneWidget);
      }
      await tester.enterText(
        find.byType(TextFormField).last,
        'Bringing my own hose',
      );
      await tester.tap(find.widgetWithText(ActionChip, 'Today'));
      await tester.pump();
      await tester.tap(find.widgetWithText(ActionChip, 'Tomorrow'));
      await tester.pump();
      expect(find.text('Tomorrow\nBringing my own hose'), findsOneWidget);
      await tester.tap(find.widgetWithText(ActionChip, 'Choose date & time'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel').last);
      await tester.pumpAndSettle();
      expect(find.text('Tomorrow\nBringing my own hose'), findsOneWidget);
      await tester.tap(find.widgetWithText(ActionChip, 'ASAP'));
      await tester.tap(find.widgetWithText(ActionChip, 'ASAP'));
      await tester.pump();
      expect(find.text('ASAP\nBringing my own hose'), findsOneWidget);
      await tester.tap(find.text('Save demo request'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('80 liters · ASAP\nBringing my own hose'),
        findsOneWidget,
      );
    },
  );
}
