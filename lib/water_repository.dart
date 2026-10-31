import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import 'water_place.dart';

class RefillRequest {
  const RefillRequest({
    required this.id,
    required this.placeName,
    required this.liters,
    required this.message,
    required this.status,
  });

  final String id;
  final String placeName;
  final int liters;
  final String message;
  final String status;

  factory RefillRequest.fromFirestore(String id, Map<String, dynamic> data) =>
      RefillRequest(
        id: id,
        placeName: data['placeName'] as String,
        liters: data['liters'] as int,
        message: data['message'] as String,
        status: data['status'] as String,
      );
}

abstract interface class WaterRepository {
  bool get isDemo;

  Stream<List<WaterPlace>> watchPlaces();
  Stream<List<WaterPlace>> watchMyPlaces();
  Stream<List<RefillRequest>> watchMyRequests();
  Stream<List<RefillRequest>> watchIncomingRequests();

  Future<void> saveOffer(WaterPlace place);
  Future<void> deleteOffer(WaterPlace place);
  Future<void> createRequest({
    required WaterPlace place,
    required int liters,
    required String message,
  });
  Future<void> updateRequestStatus(RefillRequest request, String status);
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
  Future<void> saveOffer(WaterPlace place) async {}

  @override
  Future<void> deleteOffer(WaterPlace place) async {}

  @override
  Future<void> createRequest({
    required WaterPlace place,
    required int liters,
    required String message,
  }) async {}

  @override
  Future<void> updateRequestStatus(
    RefillRequest request,
    String status,
  ) async {}
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
        (snapshot) => snapshot.docs
            .map(
              (document) =>
                  WaterPlace.fromFirestore(document.id, document.data()),
            )
            .toList(),
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
      _requestStream('requesterUid');

  @override
  Stream<List<RefillRequest>> watchIncomingRequests() =>
      _requestStream('hostUid');

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
  Future<void> saveOffer(WaterPlace place) async {
    await _firestore.collection('waterPlaces').add({
      'name': place.name,
      'area': place.area,
      'host': place.host,
      'private': place.private,
      'price': place.price,
      'description': place.description,
      'openingTimes': place.openingTimes,
      'latitude': place.location.latitude,
      'longitude': place.location.longitude,
      'ownerUid': _userId,
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> createRequest({
    required WaterPlace place,
    required int liters,
    required String message,
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
}
