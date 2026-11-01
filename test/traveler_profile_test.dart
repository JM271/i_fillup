import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:i_fillup/offer_water_home.dart';
import 'package:i_fillup/take_water_home.dart';
import 'package:i_fillup/traveler_profile.dart';
import 'package:i_fillup/water_place.dart';
import 'package:i_fillup/water_repository.dart';

const lea = TravelerProfile(
  name: 'Lea',
  vehicle: 'Campervan, 6 m',
  phone: '+41 79 123 45 67',
  about: 'Two kids and a dog, own hose',
);

class ProfileRepository implements WaterRepository {
  ProfileRepository({
    this.profile,
    this.incoming = const [],
    this.mine = const [],
  });
  TravelerProfile? profile;
  final List<RefillRequest> incoming;
  final List<RefillRequest> mine;
  final sent = <TravelerProfile>[];
  final deletedRequests = <String>[];

  @override
  bool get isDemo => false;
  @override
  Stream<List<WaterPlace>> watchPlaces() => Stream.value(places);
  @override
  Stream<List<WaterPlace>> watchMyPlaces() => Stream.value(const []);
  @override
  Stream<List<RefillRequest>> watchMyRequests() => Stream.value(mine);
  @override
  Stream<List<RefillRequest>> watchIncomingRequests() => Stream.value(incoming);
  @override
  Future<TravelerProfile?> loadMyProfile() async => profile;
  @override
  Future<void> saveMyProfile(TravelerProfile value) async => profile = value;
  @override
  Future<void> saveOffer(WaterPlace place) async {}
  @override
  Future<void> updateOffer(WaterPlace place) async {}
  @override
  Future<void> deleteOffer(WaterPlace place) async {}
  @override
  Future<void> keepOnlyOffer(WaterPlace keep, List<WaterPlace> others) async {}
  @override
  Future<void> createRequest({
    required WaterPlace place,
    required int liters,
    required String message,
    required TravelerProfile requester,
  }) async => sent.add(requester);
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
  test('Profiles round-trip and reject missing names', () {
    final copy = TravelerProfile.fromMap(lea.toMap())!;
    expect(copy.name, 'Lea');
    expect(copy.phone, '+41 79 123 45 67');
    expect(TravelerProfile.fromMap({'name': '', 'vehicle': 'Van'}), isNull);
    expect(TravelerProfile.fromMap(null), isNull);
  });

  test('Photos and vehicle access survive storage', () {
    final photo = Uint8List.fromList([1, 2, 3, 250]);
    final profile = TravelerProfile.fromMap(
      const TravelerProfile(name: 'Lea', vehicle: 'Van').toMap()
        ..['photo'] = TravelerProfile(
          name: 'Lea',
          vehicle: 'Van',
          photo: photo,
        ).toMap()['photo']!,
    )!;
    expect(profile.photo, photo);

    final place = WaterPlace.fromFirestore('me', {
      'name': 'Tap',
      'area': 'Thun',
      'host': 'Anna',
      'private': true,
      'price': 'Free',
      'description': '',
      'openingTimes': 'Always',
      'latitude': 46.7,
      'longitude': 7.6,
      'ownerUid': 'me',
      'photo': TravelerProfile(
        name: 'x',
        vehicle: 'x',
        photo: photo,
      ).toMap()['photo'],
      'vehicles': ['campervan', 'spaceship', 'trailer'],
    });
    expect(place.photo, photo);
    expect(place.vehicles, ['campervan', 'trailer']);
    expect(
      vehicleSummary(place.vehicles),
      'Campervan up to 6 m · Caravan or trailer',
    );
  });

  testWidgets('The first request asks the water taker for a profile', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = ProfileRepository();
    await tester.pumpWidget(
      MaterialApp(home: RefillHome(repository: repository)),
    );
    final dynamic state = tester.state(find.byType(RefillHome));
    state.requestWater(places.first);
    await tester.pumpAndSettle();
    expect(find.text('Your profile'), findsOneWidget);

    await tester.ensureVisible(find.text('Save profile'));
    await tester.tap(find.text('Save profile'));
    await tester.pump();
    expect(find.text('Please fill in this field'), findsNWidgets(2));

    await tester.enterText(find.byType(TextFormField).at(0), 'Lea');
    await tester.enterText(find.byType(TextFormField).at(1), 'Campervan, 6 m');
    await tester.ensureVisible(find.text('Save profile'));
    await tester.tap(find.text('Save profile'));
    await tester.pumpAndSettle();
    expect(find.text('From Lea · Campervan, 6 m'), findsOneWidget);

    await tester.tap(find.widgetWithText(ActionChip, 'ASAP'));
    await tester.pump();
    await tester.tap(find.text('Send refill request'));
    await tester.pumpAndSettle();
    expect(repository.sent.single.name, 'Lea');
    expect(repository.profile?.vehicle, 'Campervan, 6 m');
  });

  testWidgets('Incoming requests show the water taker profile', (tester) async {
    final repository = ProfileRepository(
      incoming: const [
        RefillRequest(
          id: 'r1',
          placeName: 'Garden tap',
          liters: 80,
          message: 'Tomorrow',
          status: 'pending',
          requester: lea,
        ),
        RefillRequest(
          id: 'r2',
          placeName: 'Garden tap',
          liters: 40,
          message: 'Old request',
          status: 'accepted',
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp(home: GiverHome(repository: repository)),
    );
    await tester.tap(find.text('Requests'));
    await tester.pumpAndSettle();
    expect(find.text('Lea'), findsOneWidget);
    expect(find.text('Campervan, 6 m'), findsOneWidget);
    expect(find.text('Two kids and a dog, own hose'), findsOneWidget);
    expect(find.text('Call +41 79 123 45 67'), findsOneWidget);
    expect(find.textContaining('No traveler profile'), findsOneWidget);
  });

  testWidgets('Hosts can delete incoming requests', (tester) async {
    tester.view.physicalSize = const Size(400, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = ProfileRepository(
      incoming: const [
        RefillRequest(
          id: 'r1',
          placeName: 'Garden tap',
          liters: 80,
          message: 'Tomorrow',
          status: 'pending',
          requester: lea,
        ),
        RefillRequest(
          id: 'r2',
          placeName: 'Garden tap',
          liters: 40,
          message: 'Last week',
          status: 'accepted',
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp(home: GiverHome(repository: repository)),
    );
    await tester.tap(find.text('Requests'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Delete request').first);
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Lea will see that it was declined'),
      findsOneWidget,
    );
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(repository.deletedRequests, isEmpty);

    await tester.tap(find.byTooltip('Delete request').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Decline and delete'));
    await tester.pumpAndSettle();
    expect(repository.deletedRequests, ['r1']);
    expect(find.text('Request deleted'), findsOneWidget);

    await tester.tap(find.byTooltip('Delete request').last);
    await tester.pumpAndSettle();
    expect(find.text('It is removed from your requests.'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(repository.deletedRequests, ['r1', 'r2']);
  });

  test('Hidden requests are flagged from storage', () {
    final request = RefillRequest.fromFirestore('r', {
      'placeName': 'Tap',
      'liters': 10,
      'message': 'Hi',
      'status': 'declined',
      'hostHidden': true,
    });
    expect(request.hostHidden, isTrue);
    expect(request.requesterHidden, isFalse);
  });

  testWidgets('Water takers can delete their requests', (tester) async {
    final repository = ProfileRepository(
      mine: const [
        RefillRequest(
          id: 'm1',
          placeName: 'Garden tap',
          liters: 80,
          message: 'Tomorrow',
          status: 'pending',
        ),
        RefillRequest(
          id: 'm2',
          placeName: 'Farm well',
          liters: 40,
          message: 'Last week',
          status: 'declined',
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp(home: RefillHome(repository: repository)),
    );
    await tester.tap(find.text('Requests'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Delete request').first);
    await tester.pumpAndSettle();
    expect(
      find.textContaining('The host will see that you cancelled it'),
      findsOneWidget,
    );
    await tester.tap(find.text('Keep'));
    await tester.pumpAndSettle();
    expect(repository.deletedRequests, isEmpty);

    await tester.tap(find.byTooltip('Delete request').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel and delete'));
    await tester.pumpAndSettle();
    expect(repository.deletedRequests, ['m1']);

    await tester.tap(find.byTooltip('Delete request').last);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(repository.deletedRequests, ['m1', 'm2']);
  });

  testWidgets('Demo requests can be deleted', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: RefillHome()));
    final dynamic state = tester.state(find.byType(RefillHome));
    state.requestWater(places.first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ActionChip, 'ASAP'));
    await tester.pump();
    await tester.tap(find.text('Save demo request'));
    await tester.pumpAndSettle();
    expect(find.text(places.first.name), findsOneWidget);

    await tester.tap(find.byTooltip('Delete request'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel and delete'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Delete request'), findsNothing);
  });

  testWidgets('A tapped answer notification opens My requests', (tester) async {
    final showRequests = ValueNotifier(0);
    addTearDown(showRequests.dispose);
    await tester.pumpWidget(
      MaterialApp(home: RefillHome(showRequests: showRequests)),
    );
    expect(find.text('Your next stop starts here'), findsNothing);
    showRequests.value++;
    await tester.pumpAndSettle();
    expect(find.text('Your next stop starts here'), findsOneWidget);
  });

  testWidgets('Water takers announce their arrival once', (tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = ProfileRepository(
      mine: [
        const RefillRequest(
          id: 'm1',
          placeName: 'Garden tap',
          liters: 80,
          message: 'ASAP',
          status: 'accepted',
        ),
        RefillRequest(
          id: 'm2',
          placeName: 'Farm well',
          liters: 40,
          message: 'ASAP',
          status: 'accepted',
          arrivedAt: DateTime(2026, 11, 1, 14, 5),
        ),
        const RefillRequest(
          id: 'm3',
          placeName: 'Old tap',
          liters: 40,
          message: 'Last week',
          status: 'declined',
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp(home: RefillHome(repository: repository)),
    );
    await tester.tap(find.text('Requests'));
    await tester.pumpAndSettle();
    expect(find.text('I’ve arrived'), findsOneWidget);
    expect(find.text('Arrival announced'), findsOneWidget);

    await tester.tap(find.text('I’ve arrived'));
    await tester.pumpAndSettle();
    expect(
      find.text('Garden tap gets a notification that you are there.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(repository.arrived, isEmpty);

    await tester.tap(find.text('I’ve arrived'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Announce'));
    await tester.pumpAndSettle();
    expect(repository.arrived, ['m1']);
  });

  testWidgets('Hosts see when the water taker arrived', (tester) async {
    final repository = ProfileRepository(
      incoming: [
        RefillRequest(
          id: 'r1',
          placeName: 'Garden tap',
          liters: 80,
          message: 'ASAP',
          status: 'accepted',
          requester: lea,
          arrivedAt: DateTime(2026, 11, 1, 14, 5),
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp(home: GiverHome(repository: repository)),
    );
    await tester.tap(find.text('Requests'));
    await tester.pumpAndSettle();
    expect(find.text('Arrived · 14:05'), findsOneWidget);
  });
}
