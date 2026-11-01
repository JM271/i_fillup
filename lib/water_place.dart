import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import 'photo_field.dart';
import 'texts.dart';

/// One place per owner for travelers: the place under the owner's UID, or an
/// owner's only older place. Owners with several older places must choose.
List<WaterPlace> listedPlaces(Iterable<WaterPlace> all) {
  final byOwner = <String?, List<WaterPlace>>{};
  for (final place in all) {
    byOwner.putIfAbsent(place.ownerId, () => []).add(place);
  }
  return [
    for (final group in byOwner.values)
      if (group.any((place) => place.isAccountPlace))
        ...group.where((place) => place.isAccountPlace)
      else if (group.length == 1)
        group.single,
  ];
}

String vehicleSummary(List<String> vehicles) =>
    vehicles.map((key) => vehicleAccess[key]).nonNulls.join(' · ');

const placeServiceIcons = {
  'farmShop': Icons.agriculture_outlined,
  'shop': Icons.storefront_outlined,
  'food': Icons.restaurant_outlined,
  'fuel': Icons.local_gas_station_outlined,
  'campsite': Icons.rv_hookup_outlined,
  'dump': Icons.water_damage_outlined,
  'electricity': Icons.electrical_services_outlined,
  'repairs': Icons.build_outlined,
};

String serviceSummary(List<String> services) =>
    services.map((key) => placeServices[key]).nonNulls.join(' · ');

/// Accepts an empty value or an http(s) address with a host.
bool validWebsite(String value) {
  if (value.isEmpty) return true;
  final uri = Uri.tryParse(value);
  return uri != null &&
      (uri.scheme == 'https' || uri.scheme == 'http') &&
      uri.host.contains('.');
}

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
    this.openingTimes = 'on-request',
    this.id,
    this.ownerId,
    this.photo,
    this.vehicles = const [],
    this.services = const [],
    this.businessInfo = '',
    this.website = '',
    this.hose,
    this.selfService,
    this.isActive = true,
  });
  final String name, area, host, price, description;
  final bool private;
  final IconData icon;
  final LatLng location;
  final String openingTimes;
  final String? id;
  final String? ownerId;
  final Uint8List? photo;

  /// Keys of [vehicleAccess] that can reach the water point.
  final List<String> vehicles;

  /// Keys of [placeServices]: the host's business and other offers.
  final List<String> services;

  /// The host's pitch for their business, and its website.
  final String businessInfo, website;

  /// Whether a hose is there to use, and whether travelers can fill up
  /// without the host; null for places saved before these questions.
  final bool? hose, selfService;

  /// False once travelers' reports have hidden the place from the list.
  final bool isActive;

  bool get promotesBusiness =>
      services.isNotEmpty || businessInfo.isNotEmpty || website.isNotEmpty;

  /// Whether this is its owner's one listed place, stored under the owner's
  /// UID. Places created before the one-place rule have other IDs.
  bool get isAccountPlace => id == null || id == ownerId;

  /// Older app versions saved this note as every new place's description.
  static const _oldDefaults = {
    'Contact and water suitability must be confirmed before visiting.',
    'Kontakt und Wasserqualität müssen vor dem Besuch geklärt werden.',
    'Le contact et la qualité de l’eau doivent être confirmés avant la visite.',
  };

  static String withoutOldDefault(String description) =>
      _oldDefaults.contains(description) ? '' : description;

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
      withoutOldDefault(data['description'] as String),
      isPrivate ? Icons.cottage_outlined : Icons.local_parking_outlined,
      LatLng(latitude.toDouble(), longitude.toDouble()),
      openingTimes: data['openingTimes'] as String,
      id: id,
      ownerId: data['ownerUid'] as String?,
      photo: decodePhoto(data['photo']),
      vehicles: [
        for (final key in data['vehicles'] as List? ?? const [])
          if (key is String && vehicleAccess.containsKey(key)) key,
      ],
      services: [
        for (final key in data['services'] as List? ?? const [])
          if (key is String && placeServices.containsKey(key)) key,
      ],
      businessInfo: data['businessInfo'] as String? ?? '',
      website: data['website'] as String? ?? '',
      hose: data['hose'] as bool?,
      selfService: data['selfService'] as bool?,
      isActive: data['isActive'] != false,
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
    vehicles: ['campervan'],
    hose: false,
    selfService: false,
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
    vehicles: ['campervan', 'motorhome', 'large', 'trailer'],
    hose: true,
    selfService: true,
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
    vehicles: ['campervan', 'motorhome'],
    hose: true,
    selfService: false,
    services: ['farmShop', 'dump'],
    businessInfo:
        'Our farm shop sells eggs, cheese and bread. Open Saturday mornings.',
  ),
];
