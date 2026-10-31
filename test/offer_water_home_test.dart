import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:i_fillup/offer_water_home.dart';
import 'package:i_fillup/water_place.dart';

void main() {
  testWidgets('Your water places can be deleted after confirmation', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: GiverHome()));
    final dynamic state = tester.state(find.byType(GiverHome));
    await state.saveOffer(places.first);
    await tester.pumpAndSettle();
    expect(find.text(places.first.name), findsOneWidget);

    await tester.tap(find.byTooltip('Delete place'));
    await tester.pumpAndSettle();
    expect(find.text('Delete ${places.first.name}?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text(places.first.name), findsOneWidget);

    await tester.tap(find.byTooltip('Delete place'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(find.text(places.first.name), findsNothing);
    expect(find.text('${places.first.name} deleted'), findsOneWidget);
    expect(find.textContaining('No places yet'), findsOneWidget);
  });
}
