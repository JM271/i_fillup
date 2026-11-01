import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:i_fillup/offer_water_form.dart';
import 'package:i_fillup/offer_water_home.dart';
import 'package:i_fillup/traveler_profile.dart';
import 'package:i_fillup/water_place.dart';
import 'package:i_fillup/water_repository.dart';

WaterPlace legacyPlace(String id, String name) => WaterPlace(
  name,
  'Thun, Switzerland',
  'Anna',
  true,
  'Free',
  'Old listing',
  Icons.cottage_outlined,
  places.first.location,
  id: id,
  ownerId: 'me',
);

class LegacyRepository implements WaterRepository {
  final kept = <(String, List<String>)>[];
  final deletedRequests = <String>[];
  final myPlaces = [
    legacyPlace('old-1', 'Old tap'),
    legacyPlace('old-2', 'Old well'),
  ];

  @override
  bool get isDemo => false;
  @override
  Stream<List<WaterPlace>> watchPlaces() => Stream.value(const []);
  @override
  Stream<List<WaterPlace>> watchMyPlaces() => Stream.value(myPlaces);
  @override
  Stream<List<RefillRequest>> watchMyRequests() => Stream.value(const []);
  @override
  Stream<List<RefillRequest>> watchIncomingRequests() => Stream.value(const []);
  @override
  Future<TravelerProfile?> loadMyProfile() async => null;
  @override
  Future<void> saveMyProfile(TravelerProfile profile) async {}
  @override
  Future<void> saveOffer(WaterPlace place) async {}
  final updated = <WaterPlace>[];
  @override
  Future<void> updateOffer(WaterPlace place) async => updated.add(place);
  @override
  Future<void> deleteOffer(WaterPlace place) async {}
  @override
  Future<void> keepOnlyOffer(WaterPlace keep, List<WaterPlace> others) async =>
      kept.add((keep.id!, [for (final place in others) place.id!]));
  @override
  Future<void> createRequest({
    required WaterPlace place,
    required int liters,
    required String message,
    required TravelerProfile requester,
  }) async {}
  @override
  Future<void> updateRequestStatus(
    RefillRequest request,
    String status,
  ) async {}
  @override
  Future<void> deleteIncomingRequest(RefillRequest request) async =>
      deletedRequests.add(request.id);
  @override
  Future<void> deleteMyRequest(RefillRequest request) async =>
      deletedRequests.add(request.id);
  final arrived = <String>[];
  @override
  Future<void> announceArrival(RefillRequest request) async =>
      arrived.add(request.id);
  @override
  Future<void> savePushToken(String token) async {}
  @override
  Future<void> removePushToken(String token) async {}
}

void main() {
  testWidgets('Your water place can be deleted after confirmation', (
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
    expect(find.textContaining('No water place yet'), findsOneWidget);
  });

  testWidgets('Each account can offer only one water place', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: GiverHome()));
    final dynamic state = tester.state(find.byType(GiverHome));
    expect(find.widgetWithText(FilledButton, 'Offer water'), findsOneWidget);

    await state.saveOffer(places.first);
    await state.saveOffer(places.last);
    await tester.pumpAndSettle();
    expect(find.text(places.first.name), findsOneWidget);
    expect(find.text(places.last.name), findsNothing);
    expect(find.widgetWithText(FilledButton, 'Offer water'), findsNothing);

    await tester.tap(find.text('Offer water').last);
    await tester.pumpAndSettle();
    expect(find.text('You already offer a place'), findsOneWidget);
    expect(find.text('Offer water.\nEarn cash.'), findsNothing);

    await tester.tap(find.text('Go to My place'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Delete place'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Offer water').last);
    await tester.pumpAndSettle();
    expect(find.text('Offer water.\nEarn cash.'), findsOneWidget);
  });

  test('Travelers see one place per owner', () {
    WaterPlace owned(String id, String owner) => WaterPlace(
      id,
      'Thun',
      'Host',
      true,
      'Free',
      '',
      Icons.cottage_outlined,
      places.first.location,
      id: id,
      ownerId: owner,
    );
    final listed = listedPlaces([
      owned('old-a', 'anna'), // Anna's only place stays listed.
      owned('old-b1', 'ben'), // Ben has not chosen yet: hidden.
      owned('old-b2', 'ben'),
      owned('cara', 'cara'), // Cara's account place wins over older ones.
      owned('old-c', 'cara'),
    ]);
    expect(listed.map((place) => place.id), ['old-a', 'cara']);
  });

  test('Only a place stored under its owner UID is the account place', () {
    expect(legacyPlace('me', 'Tap').isAccountPlace, isTrue);
    expect(legacyPlace('old-1', 'Tap').isAccountPlace, isFalse);
    expect(places.first.isAccountPlace, isTrue);
  });

  testWidgets('Owners of older places choose the one place to keep', (
    tester,
  ) async {
    final repository = LegacyRepository();
    await tester.pumpWidget(
      MaterialApp(home: GiverHome(repository: repository)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Choose your one water place'), findsOneWidget);
    expect(find.text('Not listed'), findsNWidgets(2));

    await tester.tap(find.text('Keep this one').last);
    await tester.pumpAndSettle();
    expect(find.text('Keep Old well?'), findsOneWidget);
    expect(
      find.textContaining('Your other place will be deleted'),
      findsOneWidget,
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Keep this one'));
    await tester.pumpAndSettle();
    expect(repository.kept.single.$1, 'old-2');
    expect(repository.kept.single.$2, ['old-1']);
    expect(find.text('Old well is your water place'), findsOneWidget);
  });

  testWidgets('A tapped notification opens incoming requests', (tester) async {
    final showRequests = ValueNotifier(0);
    addTearDown(showRequests.dispose);
    await tester.pumpWidget(
      MaterialApp(home: GiverHome(showRequests: showRequests)),
    );
    expect(find.text('Your water place'), findsOneWidget);
    showRequests.value++;
    await tester.pumpAndSettle();
    expect(find.text('Incoming requests'), findsOneWidget);
  });

  testWidgets('Hosts can edit their water place', (tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = LegacyRepository();
    repository.myPlaces
      ..clear()
      ..add(legacyPlace('me', 'Garden tap'));
    await tester.pumpWidget(
      MaterialApp(home: GiverHome(repository: repository)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Edit water place'));
    await tester.pumpAndSettle();
    expect(find.text('Edit your\nwater place'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Garden tap'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Garden tap'),
      'Farm tap',
    );
    // Older places have no vehicles yet, so the form asks for one.
    await tester.tap(find.text('Campervan up to 6 m'));
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    expect(repository.updated.single.name, 'Farm tap');
    expect(repository.updated.single.vehicles, ['campervan']);
    expect(find.text('Changes saved'), findsOneWidget);
    expect(find.text('Edit your\nwater place'), findsNothing);
  });

  test('Stored prices fill the price field', () {
    expect(priceAmount('Free'), '0');
    expect(priceAmount('CHF 5.00 / fill'), '5.00');
    expect(priceAmount('a coffee'), isNull);
  });
}
