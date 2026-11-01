import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';

import 'address_search.dart';
import 'texts.dart';

const googlePlacesChannel = MethodChannel('i_fillup/google_places');

Future<AddressMatch?> chooseGoogleAddress(String query) async {
  final result = await googlePlacesChannel.invokeMapMethod<String, dynamic>(
    'chooseAddress',
    {'query': query},
  );
  if (result == null) return null;
  final label = result['address'];
  final lat = result['latitude'];
  final lon = result['longitude'];
  if (label is! String ||
      label.trim().isEmpty ||
      lat is! num ||
      lon is! num ||
      !lat.isFinite ||
      !lon.isFinite ||
      lat.abs() > 90 ||
      lon.abs() > 180) {
    throw PlatformException(
      code: 'invalid_address',
      message: tr.googleIncompleteAddress,
    );
  }
  return AddressMatch(label, LatLng(lat.toDouble(), lon.toDouble()));
}
