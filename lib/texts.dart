import 'package:flutter/widgets.dart';

import 'l10n/app_localizations.dart';

export 'l10n/app_localizations.dart';

/// The app's texts in the device language. FillupApp sets it from the
/// locale; until then (and in tests) the texts are English.
AppLocalizations tr = lookupAppLocalizations(const Locale('en'));

/// English first, so it is the fallback for other device languages.
const appLocales = [Locale('en'), Locale('de'), Locale('fr')];

/// Labels for the vehicle keys stored on places.
Map<String, String> get vehicleAccess => {
  'campervan': tr.vehicleCampervan,
  'motorhome': tr.vehicleMotorhome,
  'large': tr.vehicleLarge,
  'trailer': tr.vehicleTrailer,
};

/// Labels for the service keys stored on places.
Map<String, String> get placeServices => {
  'farmShop': tr.serviceFarmShop,
  'shop': tr.serviceShop,
  'food': tr.serviceFood,
  'fuel': tr.serviceFuel,
  'campsite': tr.serviceCampsite,
  'dump': tr.serviceDump,
  'electricity': tr.serviceElectricity,
  'repairs': tr.serviceRepairs,
};

/// Request statuses are stored in English; this shows them translated.
String requestStatus(String status) => switch (status) {
  'pending' => tr.statusPending,
  'accepted' => tr.statusAccepted,
  'declined' => tr.statusDeclined,
  'cancelled' => tr.statusCancelled,
  _ => status,
};

/// Prices are stored as "Free" or "CHF 5.00 / fill"; this shows them in the
/// reader's language and keeps any other text as the host wrote it.
String displayPrice(String price) {
  if (price == 'Free') return tr.free;
  final match = RegExp(r'^CHF (\d+(?:\.\d+)?) / fill$').firstMatch(price);
  return match == null ? price : tr.pricePerFill(match.group(1)!);
}
