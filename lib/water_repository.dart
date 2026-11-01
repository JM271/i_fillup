import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import 'photo_field.dart';
import 'traveler_profile.dart';
import 'water_place.dart';
import 'texts.dart';

class RefillRequest {
  const RefillRequest({
    required this.id,
    required this.placeName,
    required this.liters,
    required this.message,
    required this.status,
    this.requester,
    this.hostHidden = false,
    this.requesterHidden = false,
    this.arrivedAt,
  });

  final String id;
  final String placeName;
  final int liters;
  final String message;
  final String status;

  /// The water taker's profile as it was when the request was sent.
  final TravelerProfile? requester;

  /// Whether the host deleted the request from their list.
  final bool hostHidden;

  /// Whether the water taker deleted the request from their list.
  final bool requesterHidden;

  /// When the water taker announced they arrived at the place.
  final DateTime? arrivedAt;

  /// Water takers can announce their arrival once, until the request is
  /// declined or cancelled.
  bool get canAnnounceArrival =>
      arrivedAt == null && (status == 'pending' || status == 'accepted');

  factory RefillRequest.fromFirestore(String id, Map<String, dynamic> data) =>
      RefillRequest(
        id: id,
        placeName: data['placeName'] as String,
        liters: data['liters'] as int,
        message: data['message'] as String,
        status: data['status'] as String,
        requester: TravelerProfile.fromMap(data['requester']),
        hostHidden: data['hostHidden'] == true,
        requesterHidden: data['requesterHidden'] == true,
        arrivedAt: (data['arrivedAt'] as Timestamp?)?.toDate(),
      );
}

abstract interface class WaterRepository {
  bool get isDemo;

  Stream<List<WaterPlace>> watchPlaces();
  Stream<List<WaterPlace>> watchMyPlaces();
  Stream<List<RefillRequest>> watchMyRequests();
  Stream<List<RefillRequest>> watchIncomingRequests();

  Future<TravelerProfile?> loadMyProfile();
  Future<void> saveMyProfile(TravelerProfile profile);

  /// Push addresses of this user's devices, used to notify hosts.
  Future<void> savePushToken(String token);
  Future<void> removePushToken(String token);

  Future<void> saveOffer(WaterPlace place);
  Future<void> updateOffer(WaterPlace place);
  Future<void> deleteOffer(WaterPlace place);

  /// Makes [keep] the account's one place and deletes all [others].
  Future<void> keepOnlyOffer(WaterPlace keep, List<WaterPlace> others);
  Future<void> createRequest({
    required WaterPlace place,
    required int liters,
    required String message,
    required TravelerProfile requester,
  });
  Future<void> updateRequestStatus(RefillRequest request, String status);

  /// Removes a request from the host's list, declining it if still pending.
  Future<void> deleteIncomingRequest(RefillRequest request);

  /// Removes a request from the water taker's list, cancelling it if still
  /// pending.
  Future<void> deleteMyRequest(RefillRequest request);

  /// Tells the host that the water taker has arrived at the place.
  Future<void> announceArrival(RefillRequest request);
}

class DemoWaterRepository implements WaterRepository {
  const DemoWaterRepository();

  @override
  bool get isDemo => true;

  @override
  Stream<List<WaterPlace>> watchPlaces() => Stream.value(places);

  @override
  Stream<List<WaterPlace>> watchMyPlaces() => Stream.value(const []);

  @override
  Stream<List<RefillRequest>> watchMyRequests() => Stream.value(const []);

  @override
  Stream<List<RefillRequest>> watchIncomingRequests() => Stream.value(const []);

  @override
  Future<TravelerProfile?> loadMyProfile() async =>
      const TravelerProfile(name: 'Demo traveler', vehicle: 'Campervan');

  @override
  Future<void> saveMyProfile(TravelerProfile profile) async {}

  @override
  Future<void> savePushToken(String token) async {}

  @override
  Future<void> removePushToken(String token) async {}

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
  }) async {}

  @override
  Future<void> updateRequestStatus(
    RefillRequest request,
    String status,
  ) async {}

  @override
  Future<void> deleteIncomingRequest(RefillRequest request) async {}

  @override
  Future<void> deleteMyRequest(RefillRequest request) async {}

  @override
  Future<void> announceArrival(RefillRequest request) async {}
}

class FirebaseWaterRepository implements WaterRepository {
  FirebaseWaterRepository._({required this._firestore, required this._userId});

  final FirebaseFirestore _firestore;
  final String _userId;

  @override
  bool get isDemo => false;

  factory FirebaseWaterRepository.forUser(FirebaseApp app, String userId) =>
      FirebaseWaterRepository._(
        firestore: FirebaseFirestore.instanceFor(app: app),
        userId: userId,
      );

  @override
  Stream<List<WaterPlace>> watchPlaces() => _firestore
      .collection('waterPlaces')
      .where('isActive', isEqualTo: true)
      .snapshots()
      .map(
        (snapshot) => listedPlaces(
          snapshot.docs.map(
            (document) =>
                WaterPlace.fromFirestore(document.id, document.data()),
          ),
        ),
      );

  @override
  Stream<List<WaterPlace>> watchMyPlaces() => _firestore
      .collection('waterPlaces')
      .where('ownerUid', isEqualTo: _userId)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map(
              (document) =>
                  WaterPlace.fromFirestore(document.id, document.data()),
            )
            .toList(),
      );

  @override
  Stream<List<RefillRequest>> watchMyRequests() =>
      _requestStream('requesterUid').map(
        (requests) =>
            requests.where((request) => !request.requesterHidden).toList(),
      );

  @override
  Stream<List<RefillRequest>> watchIncomingRequests() =>
      _requestStream('hostUid').map(
        (requests) => requests.where((request) => !request.hostHidden).toList(),
      );

  Stream<List<RefillRequest>> _requestStream(String ownerField) => _firestore
      .collection('refillRequests')
      .where(ownerField, isEqualTo: _userId)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map(
              (document) =>
                  RefillRequest.fromFirestore(document.id, document.data()),
            )
            .toList(),
      );

  @override
  Future<TravelerProfile?> loadMyProfile() async => TravelerProfile.fromMap(
    (await _firestore.collection('profiles').doc(_userId).get()).data(),
  );

  @override
  Future<void> saveMyProfile(TravelerProfile profile) => _firestore
      .collection('profiles')
      .doc(_userId)
      .set({...profile.toMap(), 'updatedAt': FieldValue.serverTimestamp()});

  @override
  Future<void> savePushToken(String token) =>
      _firestore.collection('devices').doc(_userId).set({
        'tokens': FieldValue.arrayUnion([token]),
        // The notify function writes the push message in this language.
        'language': tr.localeName,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

  @override
  Future<void> removePushToken(String token) =>
      _firestore.collection('devices').doc(_userId).set({
        'tokens': FieldValue.arrayRemove([token]),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

  Map<String, Object?> _placeFields(WaterPlace place) => {
    'name': place.name,
    'area': place.area,
    'host': place.host,
    'private': place.private,
    'price': place.price,
    'description': place.description,
    'openingTimes': place.openingTimes,
    'latitude': place.location.latitude,
    'longitude': place.location.longitude,
    'photo': encodePhoto(place.photo),
    'vehicles': place.vehicles,
    'services': place.services,
    'businessInfo': place.businessInfo,
    'website': place.website,
    'hose': place.hose ?? false,
    'selfService': place.selfService ?? false,
    'isActive': true,
    'updatedAt': FieldValue.serverTimestamp(),
  };

  @override
  Future<void> saveOffer(WaterPlace place) async {
    // One place per account: the rules only allow the owner's UID as its ID.
    await _firestore.collection('waterPlaces').doc(_userId).set({
      ..._placeFields(place),
      'ownerUid': _userId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> updateOffer(WaterPlace place) => _firestore
      .collection('waterPlaces')
      .doc(_userId)
      .update(_placeFields(place));

  @override
  Future<void> keepOnlyOffer(WaterPlace keep, List<WaterPlace> others) async {
    final places = _firestore.collection('waterPlaces');
    final batch = _firestore.batch();
    if (keep.id != _userId) {
      final accountPlace = places.doc(_userId);
      if (others.any((place) => place.id == _userId)) {
        batch.update(accountPlace, _placeFields(keep));
      } else {
        batch.set(accountPlace, {
          ..._placeFields(keep),
          'ownerUid': _userId,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    }
    for (final place in [keep, ...others]) {
      if (place.id case final id? when id != _userId) {
        batch.delete(places.doc(id));
      }
    }
    await batch.commit();
  }

  @override
  Future<void> createRequest({
    required WaterPlace place,
    required int liters,
    required String message,
    required TravelerProfile requester,
  }) async {
    final placeId = place.id;
    final hostId = place.ownerId;
    if (placeId == null || hostId == null) {
      throw StateError('A saved water place is required for a live request.');
    }
    await _firestore.collection('refillRequests').add({
      'placeId': placeId,
      'placeName': place.name,
      'hostUid': hostId,
      'requesterUid': _userId,
      'liters': liters,
      'message': message,
      'requester': requester.toMap(),
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> deleteOffer(WaterPlace place) async {
    final id = place.id;
    if (id == null) throw ArgumentError.value(place, 'place', 'has no id');
    await _firestore.collection('waterPlaces').doc(id).delete();
  }

  @override
  Future<void> updateRequestStatus(RefillRequest request, String status) async {
    if (status != 'accepted' && status != 'declined') {
      throw ArgumentError.value(status, 'status');
    }
    await _firestore.collection('refillRequests').doc(request.id).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> deleteIncomingRequest(RefillRequest request) =>
      _firestore.collection('refillRequests').doc(request.id).update({
        if (request.status == 'pending') 'status': 'declined',
        'hostHidden': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  @override
  Future<void> deleteMyRequest(RefillRequest request) =>
      _firestore.collection('refillRequests').doc(request.id).update({
        if (request.status == 'pending') 'status': 'cancelled',
        'requesterHidden': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  @override
  Future<void> announceArrival(RefillRequest request) =>
      _firestore.collection('refillRequests').doc(request.id).update({
        'arrivedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
}
