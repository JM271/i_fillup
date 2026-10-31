import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class WaterPlace {
  const WaterPlace(
    this.name,
    this.area,
    this.host,
    this.private,
    this.price,
    this.description,
    this.icon,
    this.location, {
    this.openingTimes = 'By arrangement with the host',
    this.id,
    this.ownerId,
  });
  final String name, area, host, price, description;
  final bool private;
  final IconData icon;
  final LatLng location;
  final String openingTimes;
  final String? id;
  final String? ownerId;

  /// Whether this is its owner's one listed place, stored under the owner's
  /// UID. Places created before the one-place rule have other IDs.
  bool get isAccountPlace => id == null || id == ownerId;

  factory WaterPlace.fromFirestore(String id, Map<String, dynamic> data) {
    final latitude = data['latitude'];
    final longitude = data['longitude'];
    if (latitude is! num || longitude is! num) {
      throw FormatException('Water place $id has invalid coordinates.');
    }

    final isPrivate = data['private'] == true;
    return WaterPlace(
      data['name'] as String,
      data['area'] as String,
      data['host'] as String,
      isPrivate,
      data['price'] as String,
      data['description'] as String,
      isPrivate ? Icons.cottage_outlined : Icons.local_parking_outlined,
      LatLng(latitude.toDouble(), longitude.toDouble()),
      openingTimes: data['openingTimes'] as String,
      id: id,
      ownerId: data['ownerUid'] as String?,
    );
  }
}

const places = [
  WaterPlace(
    'A little stop by the lake',
    'Thun, Switzerland',
    'Anna',
    true,
    'CHF 5 / fill',
    'A private driveway with an outdoor tap. Bring your own hose. Contact Anna to agree on access and a time before arriving.',
    Icons.cottage_outlined,
    LatLng(46.758, 7.628),
  ),
  WaterPlace(
    'Riverside camper stop',
    'Interlaken, Switzerland',
    'Riverside campsite',
    false,
    'CHF 8 / fill',
    'A refill point at a campsite with space for campervans. Ask the operator about opening hours, water suitability and hose connections.',
    Icons.local_parking_outlined,
    LatLng(46.686, 7.863),
  ),
  WaterPlace(
    'Fresh water on the farm',
    'Spiez, Switzerland',
    'Lukas',
    true,
    'CHF 4 / fill',
    'A private farm stop with room to park while filling. Arrange a visit with Lukas and confirm your tank size and connection.',
    Icons.agriculture_outlined,
    LatLng(46.687, 7.680),
  ),
];
