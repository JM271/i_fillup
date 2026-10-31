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
  ProfileRepository({this.profile, this.incoming = const []});
  TravelerProfile? profile;
  final List<RefillRequest> incoming;
  final sent = <TravelerProfile>[];

  @override
  bool get isDemo => false;
  @override
  Stream<List<WaterPlace>> watchPlaces() => Stream.value(places);
  @override
  Stream<List<WaterPlace>> watchMyPlaces() => Stream.value(const []);
  @override
  Stream<List<RefillRequest>> watchMyRequests() => Stream.value(const []);
  @override
  Stream<List<RefillRequest>> watchIncomingRequests() => Stream.value(incoming);
  @override
  Future<TravelerProfile?> loadMyProfile() async => profile;
  @override
  Future<void> saveMyProfile(TravelerProfile value) async => profile = value;
  @override
  Future<void> saveOffer(WaterPlace place) async {}
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
}

void main() {
  test('Profiles round-trip and reject missing names', () {
    final copy = TravelerProfile.fromMap(lea.toMap())!;
    expect(copy.name, 'Lea');
    expect(copy.phone, '+41 79 123 45 67');
    expect(TravelerProfile.fromMap({'name': '', 'vehicle': 'Van'}), isNull);
    expect(TravelerProfile.fromMap(null), isNull);
  });

  testWidgets('The first request asks the water taker for a profile', (
    tester,
  ) async {
    final repository = ProfileRepository();
    await tester.pumpWidget(
      MaterialApp(home: RefillHome(repository: repository)),
    );
    final dynamic state = tester.state(find.byType(RefillHome));
    state.requestWater(places.first);
    await tester.pumpAndSettle();
    expect(find.text('Your profile'), findsOneWidget);

    await tester.tap(find.text('Save profile'));
    await tester.pump();
    expect(find.text('Please fill in this field'), findsNWidgets(2));

    await tester.enterText(find.byType(TextFormField).at(0), 'Lea');
    await tester.enterText(find.byType(TextFormField).at(1), 'Campervan, 6 m');
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
}
