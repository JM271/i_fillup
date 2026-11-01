import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:i_fillup/take_water_home.dart';
import 'package:i_fillup/water_place.dart';

import 'traveler_profile_test.dart' show ProfileRepository;

WaterPlace listed(String id, String name) => WaterPlace(
  name,
  'Thun, Switzerland',
  'Anna',
  true,
  'Free',
  '',
  Icons.cottage_outlined,
  places.first.location,
  id: id,
  ownerId: id,
);

/// Tall enough that every place in a list is built, so a missing one is
/// really filtered out.
void tallScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> showFavorites(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(ChoiceChip, 'Favorites'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Travelers save favorites and filter by them', (tester) async {
    tallScreen(tester);
    final repository = ProfileRepository(
      listed: [listed('a', 'Garden tap'), listed('b', 'Farm well')],
    );
    await tester.pumpWidget(
      MaterialApp(home: RefillHome(repository: repository)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Save as favorite').first);
    await tester.pumpAndSettle();
    expect(repository.favoriteIds, {'a'});
    expect(find.byTooltip('Remove from favorites'), findsOneWidget);

    await showFavorites(tester);
    expect(find.text('Garden tap'), findsOneWidget);
    expect(find.text('Farm well'), findsNothing);

    await tester.tap(find.byTooltip('Remove from favorites'));
    await tester.pumpAndSettle();
    expect(repository.favoriteIds, isEmpty);
    expect(find.textContaining('No favorites yet'), findsOneWidget);
  });

  testWidgets('Saved favorites load with the places', (tester) async {
    tallScreen(tester);
    final repository = ProfileRepository(
      listed: [listed('a', 'Garden tap'), listed('b', 'Farm well')],
    )..favoriteIds.add('b');
    await tester.pumpWidget(
      MaterialApp(home: RefillHome(repository: repository)),
    );
    await tester.pumpAndSettle();
    await showFavorites(tester);
    expect(find.text('Farm well'), findsOneWidget);
    expect(find.text('Garden tap'), findsNothing);
  });

  testWidgets('The place details save a favorite too', (tester) async {
    tallScreen(tester);
    final repository = ProfileRepository(listed: [listed('a', 'Garden tap')]);
    await tester.pumpWidget(
      MaterialApp(home: RefillHome(repository: repository)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Garden tap'));
    await tester.pumpAndSettle();
    // The list behind the sheet has a heart as well.
    await tester.tap(find.byTooltip('Save as favorite').last);
    await tester.pumpAndSettle();
    expect(repository.favoriteIds, {'a'});
    expect(find.byTooltip('Remove from favorites'), findsNWidgets(2));
  });

  testWidgets('Demo favorites stay for the session', (tester) async {
    tallScreen(tester);
    await tester.pumpWidget(const MaterialApp(home: RefillHome()));
    await tester.tap(find.byTooltip('Save as favorite').first);
    await tester.pumpAndSettle();
    await showFavorites(tester);
    expect(find.text(places.first.name), findsOneWidget);
    expect(find.text(places[1].name), findsNothing);
  });
}
