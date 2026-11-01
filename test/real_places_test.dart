import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:i_fillup/offer_water_form.dart';
import 'package:i_fillup/offer_water_home.dart';
import 'package:i_fillup/take_water_home.dart';
import 'package:i_fillup/water_place.dart';
import 'package:latlong2/latlong.dart';

import 'offer_water_home_test.dart' show LegacyRepository;
import 'traveler_profile_test.dart' show ProfileRepository;

void main() {
  testWidgets('Hosts must be at a new pin to save it', (tester) async {
    tester.view.physicalSize = const Size(800, 3600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var here = const LatLng(46.76, 7.63);
    WaterPlace? saved;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OfferWaterForm(
            isDemo: false,
            locate: () async => here,
            onSave: (place) async => saved = place,
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(TextFormField).at(0), 'Garden tap');
    await tester.enterText(find.byType(TextFormField).at(1), 'Thun');
    await tester.tap(find.text('Use my current location'));
    await tester.pumpAndSettle();
    expect(find.text('Pin: 46.76000, 7.63000'), findsOneWidget);
    await tester.tap(find.text('Campervan up to 6 m'));

    // About 11 km north of the pin.
    here = const LatLng(46.86, 7.63);
    await tester.tap(find.text('Save offer'));
    await tester.pumpAndSettle();
    expect(saved, isNull);
    expect(
      find.text(
        'You are 11 km away from the pin. Be at your water place to list it.',
      ),
      findsWidgets,
    );

    here = const LatLng(46.7605, 7.6305);
    await tester.tap(find.text('Save offer'));
    await tester.pumpAndSettle();
    expect(saved?.location, const LatLng(46.76, 7.63));
  });

  testWidgets('Travelers report a place with a reason', (tester) async {
    final repository = ProfileRepository();
    await tester.pumpWidget(
      MaterialApp(home: RefillHome(repository: repository)),
    );
    final dynamic state = tester.state(find.byType(RefillHome));
    state.showPlace(places.first);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Report a problem'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Report a problem'));
    await tester.pumpAndSettle();
    expect(
      find.text('What is wrong with ${places.first.name}?'),
      findsOneWidget,
    );
    await tester.tap(find.text('The place does not exist'));
    await tester.pumpAndSettle();
    expect(repository.reported, [(null, 'doesNotExist')]);
    expect(find.textContaining('Thank you.'), findsOneWidget);
  });

  testWidgets('Hosts see when reports hid their place', (tester) async {
    final repository = LegacyRepository();
    repository.myPlaces
      ..clear()
      ..add(
        WaterPlace(
          'Garden tap',
          'Thun, Switzerland',
          'Anna',
          true,
          'Free',
          '',
          Icons.cottage_outlined,
          places.first.location,
          id: 'me',
          ownerId: 'me',
          isActive: false,
        ),
      );
    await tester.pumpWidget(
      MaterialApp(home: GiverHome(repository: repository)),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Your water place is hidden'), findsOneWidget);
  });
}
