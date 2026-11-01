import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:i_fillup/address_search.dart';
import 'package:i_fillup/offer_water_form.dart';
import 'package:i_fillup/take_water_home.dart';
import 'package:i_fillup/water_place.dart';
import 'package:latlong2/latlong.dart';

void main() {
  test('Websites must be full http(s) addresses', () {
    expect(validWebsite(''), isTrue);
    expect(validWebsite('https://hof-anna.ch'), isTrue);
    expect(validWebsite('http://www.hof-anna.ch/shop'), isTrue);
    expect(validWebsite('hof-anna.ch'), isFalse);
    expect(validWebsite('https://localhost'), isFalse);
    expect(validWebsite('javascript:alert(1)'), isFalse);
  });

  test('Business details survive storage and ignore unknown services', () {
    final data = {
      'name': 'Tap',
      'area': 'Spiez',
      'host': 'Lukas',
      'private': true,
      'price': 'Free',
      'description': '',
      'openingTimes': 'Always',
      'latitude': 46.7,
      'longitude': 7.6,
      'ownerUid': 'me',
      'services': ['farmShop', 'casino', 'fuel'],
      'businessInfo': 'Eggs and cheese',
      'website': 'https://hof.ch',
    };
    final place = WaterPlace.fromFirestore('me', data);
    expect(place.services, ['farmShop', 'fuel']);
    expect(place.businessInfo, 'Eggs and cheese');
    expect(place.website, 'https://hof.ch');
    expect(place.promotesBusiness, isTrue);
    expect(place.hose, isNull, reason: 'older places did not say');
    expect(
      WaterPlace.fromFirestore('me', {
        ...data,
        'hose': true,
        'selfService': true,
      }).selfService,
      isTrue,
    );
    expect(places.first.promotesBusiness, isFalse);
  });

  testWidgets('Travelers see what else a host offers', (tester) async {
    tester.view.physicalSize = const Size(400, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(home: RefillHome()));
    await tester.pumpAndSettle();
    expect(
      find.text('Also here: Farm shop · Waste water disposal'),
      findsOneWidget,
    );

    await tester.tap(find.text('Fresh water on the farm'));
    await tester.pumpAndSettle();
    expect(find.text('Also here'), findsOneWidget);
    expect(find.widgetWithText(Chip, 'Farm shop'), findsOneWidget);
    expect(find.widgetWithText(Chip, 'Waste water disposal'), findsOneWidget);
    expect(find.textContaining('eggs, cheese and bread'), findsOneWidget);
    expect(find.widgetWithText(Chip, 'Hose available'), findsOneWidget);
    expect(find.widgetWithText(Chip, 'Host lets you fill up'), findsOneWidget);
  });

  testWidgets('Hosts can promote their business with an offer', (tester) async {
    tester.view.physicalSize = const Size(800, 3600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    WaterPlace? saved;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OfferWaterForm(
            onSave: (place) async => saved = place,
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
    await tester.tap(find.text('Campervan up to 6 m'));
    await tester.tap(find.text('Hose available'));
    await tester.tap(find.text('Farm shop'));
    await tester.tap(find.text('Fuel'));
    await tester.enterText(find.byType(TextFormField).at(3), 'Eggs, cheese');
    await tester.enterText(find.byType(TextFormField).at(4), 'hof.ch');
    await tester.tap(find.text('Save offer'));
    await tester.pumpAndSettle();
    expect(
      find.text('Enter a full address starting with https://'),
      findsOneWidget,
    );
    expect(saved, isNull);

    await tester.enterText(find.byType(TextFormField).at(4), 'https://hof.ch');
    await tester.tap(find.text('Save offer'));
    await tester.pumpAndSettle();
    expect(saved!.services, ['farmShop', 'fuel']);
    expect(saved!.businessInfo, 'Eggs, cheese');
    expect(saved!.website, 'https://hof.ch');
    expect(saved!.hose, isTrue);
    expect(saved!.selfService, isFalse);
  });
}
