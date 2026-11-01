import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';

import 'google_address_picker.dart';
import 'address_search.dart';
import 'app_style.dart';

import 'package:flutter/material.dart';

import 'location_picker.dart';
import 'opening_times.dart';
import 'photo_field.dart';
import 'take_water_home.dart' show formatKm;

import 'package:latlong2/latlong.dart';

import 'water_place.dart';
import 'texts.dart';

class OfferWaterForm extends StatefulWidget {
  const OfferWaterForm({
    super.key,
    required this.onSave,
    this.addressLookup = searchAddresses,
    this.isDemo = true,
    this.initial,
    this.locate = currentRefillLocation,
  });
  final Future<void> Function(WaterPlace) onSave;

  /// The place being edited; null when offering a new one.
  final WaterPlace? initial;
  final AddressLookup addressLookup;
  final bool isDemo;

  /// The phone's position, to check that hosts list a place where they are.
  final Future<LatLng> Function() locate;

  /// How far from a new pin the host may be when saving it.
  static const onSiteMeters = 200.0;

  @override
  State<OfferWaterForm> createState() => _OfferWaterFormState();
}

class _OfferWaterFormState extends State<OfferWaterForm> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController();
  final address = TextEditingController();
  var openingTimes = const OpeningTimes();
  String? openingError;
  final price = TextEditingController(text: '5.00');
  final businessInfo = TextEditingController();
  final website = TextEditingController();
  final services = <String>{};
  LatLng? location;
  Uint8List? photo;
  final vehicles = <String>{};
  bool hose = false;
  bool selfService = false;
  bool missingLocation = false;

  /// Why the pin cannot be saved from where the host is.
  String? siteError;
  bool missingVehicles = false;
  bool saving = false;
  bool get useGoogle =>
      !kIsWeb &&
      defaultTargetPlatform == TargetPlatform.android &&
      widget.addressLookup == searchAddresses;

  @override
  void initState() {
    super.initState();
    final place = widget.initial;
    if (place == null) return;
    name.text = place.name;
    address.text = place.area;
    openingTimes = OpeningTimes.parse(place.openingTimes) ?? openingTimes;
    price.text = priceAmount(place.price) ?? price.text;
    businessInfo.text = place.businessInfo;
    website.text = place.website;
    location = place.location;
    photo = place.photo;
    vehicles.addAll(place.vehicles);
    services.addAll(place.services);
    hose = place.hose ?? false;
    selfService = place.selfService ?? false;
  }

  @override
  void dispose() {
    name.dispose();
    address.dispose();
    price.dispose();
    businessInfo.dispose();
    website.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Form(
    key: form,
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          WaterBanner(
            title: widget.initial == null
                ? tr.bannerOfferTitle
                : tr.editPlaceTitle,
            subtitle: widget.initial == null
                ? tr.bannerOfferSubtitle
                : tr.editPlaceSubtitle,
          ),
          const SizedBox(height: 16),
          _FormSection(
            icon: Icons.place_outlined,
            title: tr.sectionPlace,
            children: [
              TextFormField(
                controller: name,
                decoration: InputDecoration(
                  labelText: tr.placeName,
                  hintText: tr.placeNameHint,
                ),
                validator: requiredText,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: address,
                onChanged: (_) => setState(() => location = null),
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: tr.addressPlace,
                  hintText: tr.addressPlaceHint,
                ),
                validator: requiredText,
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  AddressMatch? match;
                  try {
                    if (useGoogle) {
                      match = await chooseGoogleAddress(address.text);
                    } else {
                      match = await Navigator.of(context).push<AddressMatch>(
                        MaterialPageRoute(
                          builder: (_) => AddressSearchPage(
                            initialQuery: address.text,
                            lookup: widget.addressLookup,
                          ),
                        ),
                      );
                    }
                  } on PlatformException catch (error) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(error.message ?? tr.googleSearchFailed),
                        ),
                      );
                    }
                    return;
                  }
                  final selected = match;
                  if (selected != null && mounted) {
                    setState(() {
                      address.text = selected.label;
                      location = selected.location;
                      missingLocation = false;
                      siteError = null;
                    });
                  }
                },
                icon: const Icon(Icons.search),
                label: Text(
                  useGoogle ? tr.chooseAddressGoogle : tr.chooseAddressList,
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: useMyLocation,
                icon: const Icon(Icons.my_location),
                label: Text(tr.useMyLocation),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () async {
                  final selected = await Navigator.of(context).push<LatLng>(
                    MaterialPageRoute(
                      builder: (_) => LocationPicker(initial: location),
                    ),
                  );
                  if (selected != null && mounted) {
                    setState(() {
                      location = selected;
                      missingLocation = false;
                      siteError = null;
                    });
                  }
                },
                icon: const Icon(Icons.pin_drop_outlined),
                label: Text(
                  location == null ? tr.choosePlaceOnMap : tr.changeMapLocation,
                ),
              ),
              if (location != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: teal, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          tr.pinAt(
                            location!.latitude.toStringAsFixed(5),
                            location!.longitude.toStringAsFixed(5),
                          ),
                          style: const TextStyle(color: muted),
                        ),
                      ),
                    ],
                  ),
                ),
              for (final error in [
                if (missingLocation) tr.chooseOnMapError,
                ?siteError,
              ])
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    error,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  tr.onSiteNote,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: muted),
                ),
              ),
            ],
          ),
          _FormSection(
            icon: Icons.schedule,
            title: tr.openingTimes,
            children: [
              OpeningTimesField(
                showTitle: false,
                value: openingTimes,
                error: openingError,
                previous:
                    widget.initial != null &&
                        OpeningTimes.parse(widget.initial!.openingTimes) == null
                    ? widget.initial!.openingTimes
                    : null,
                onChanged: (value) => setState(() {
                  openingTimes = value;
                  if (openingError != null) openingError = value.problem;
                }),
              ),
            ],
          ),
          _FormSection(
            icon: Icons.payments_outlined,
            title: tr.sectionPrice,
            children: [
              TextFormField(
                key: const ValueKey('offer-price'),
                controller: price,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: tr.pricePerFillUp,
                  prefixText: 'CHF ',
                  helperText: tr.priceHelper,
                  helperMaxLines: 2,
                ),
                validator: (value) => refillPriceLabel(value ?? '') == null
                    ? tr.priceError
                    : null,
              ),
              const SizedBox(height: 12),
              Text(tr.paymentNoteForm, style: const TextStyle(color: muted)),
            ],
          ),
          _FormSection(
            icon: Icons.airport_shuttle_outlined,
            title: tr.whichVehicles,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final MapEntry(:key, :value) in vehicleAccess.entries)
                    FilterChip(
                      label: Text(value),
                      selected: vehicles.contains(key),
                      onSelected: (selected) => setState(() {
                        selected ? vehicles.add(key) : vehicles.remove(key);
                        if (vehicles.isNotEmpty) missingVehicles = false;
                      }),
                    ),
                ],
              ),
              if (missingVehicles)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    tr.chooseVehicle,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
            ],
          ),
          _FormSection(
            icon: Icons.water,
            title: tr.atTheTap,
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(tr.hoseAvailable),
                subtitle: Text(tr.hoseAvailableHelp),
                value: hose,
                onChanged: (value) => setState(() => hose = value),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(tr.selfService),
                subtitle: Text(tr.selfServiceHelp),
                value: selfService,
                onChanged: (value) => setState(() => selfService = value),
              ),
            ],
          ),
          _FormSection(
            icon: Icons.photo_camera_outlined,
            title: tr.placePhoto,
            children: [
              PhotoField(
                photo: photo,
                onChanged: (value) => setState(() => photo = value),
              ),
            ],
          ),
          _FormSection(
            icon: Icons.storefront_outlined,
            title: tr.promoteBusiness,
            subtitle: tr.promoteBusinessIntro,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final MapEntry(:key, :value) in placeServices.entries)
                    FilterChip(
                      showCheckmark: false,
                      avatar: Icon(
                        services.contains(key)
                            ? Icons.check
                            : placeServiceIcons[key],
                        size: 18,
                      ),
                      label: Text(value),
                      selected: services.contains(key),
                      onSelected: (selected) => setState(
                        () =>
                            selected ? services.add(key) : services.remove(key),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: businessInfo,
                maxLines: 3,
                maxLength: 500,
                decoration: InputDecoration(
                  labelText: tr.aboutBusiness,
                  alignLabelWithHint: true,
                  hintText: tr.aboutBusinessHint,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: website,
                keyboardType: TextInputType.url,
                maxLength: 200,
                decoration: InputDecoration(
                  labelText: tr.website,
                  hintText: 'https://www.example.ch',
                ),
                validator: (value) =>
                    validWebsite(value?.trim() ?? '') ? null : tr.websiteError,
              ),
            ],
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: saving
                ? null
                : () async {
                    final valid = form.currentState!.validate();
                    setState(() {
                      missingLocation = location == null;
                      missingVehicles = vehicles.isEmpty;
                      openingError = openingTimes.problem;
                    });
                    if (!valid ||
                        location == null ||
                        vehicles.isEmpty ||
                        openingError != null) {
                      return;
                    }
                    setState(() => saving = true);
                    final problem = await onSiteProblem();
                    if (problem != null) {
                      if (!mounted) return;
                      setState(() {
                        saving = false;
                        siteError = problem;
                      });
                      ScaffoldMessenger.of(this.context)
                          .showSnackBar(SnackBar(content: Text(problem)));
                      return;
                    }
                    try {
                      await widget.onSave(
                        WaterPlace(
                          name.text.trim(),
                          address.text.trim(),
                          widget.initial?.host ?? tr.localHost,
                          widget.initial?.private ?? true,
                          refillPriceLabel(price.text)!,
                          widget.initial?.description ?? '',
                          widget.initial?.icon ?? Icons.cottage_outlined,
                          location!,
                          id: widget.initial?.id,
                          ownerId: widget.initial?.ownerId,
                          openingTimes: openingTimes.encode(),
                          photo: photo,
                          vehicles: [
                            for (final key in vehicleAccess.keys)
                              if (vehicles.contains(key)) key,
                          ],
                          services: [
                            for (final key in placeServices.keys)
                              if (services.contains(key)) key,
                          ],
                          businessInfo: businessInfo.text.trim(),
                          website: website.text.trim(),
                          hose: hose,
                          selfService: selfService,
                        ),
                      );
                    } catch (error) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              error is FirebaseException
                                  ? tr.saveOfferFailedWith('${error.message}')
                                  : tr.saveOfferFailed,
                            ),
                          ),
                        );
                      }
                      return;
                    } finally {
                      if (mounted) setState(() => saving = false);
                    }
                    if (!mounted || widget.initial != null) return;
                    name.clear();
                    address.clear();
                    price.text = '5.00';
                    businessInfo.clear();
                    website.clear();
                    setState(() {
                      openingTimes = const OpeningTimes();
                      location = null;
                      photo = null;
                      vehicles.clear();
                      services.clear();
                      hose = false;
                      selfService = false;
                    });
                  },
            icon: const Icon(Icons.save_outlined),
            label: Text(
              saving
                  ? tr.saving
                  : widget.initial == null
                  ? tr.saveOffer
                  : tr.saveChanges,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.isDemo ? tr.previewOfferNote : tr.liveOfferNote,
            textAlign: TextAlign.center,
            style: const TextStyle(color: muted),
          ),
        ],
      ),
    ),
  );

  Future<void> useMyLocation() async {
    try {
      final here = await widget.locate();
      if (!mounted) return;
      setState(() {
        location = here;
        missingLocation = false;
        siteError = null;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr.onSiteCheckFailed(errorText(error)))),
      );
    }
  }

  /// Why the host cannot save the pin from where they are, or null. Only new
  /// or moved pins are checked, so hosts can edit other details anywhere.
  Future<String?> onSiteProblem() async {
    final pin = location!;
    if (widget.isDemo || pin == widget.initial?.location) return null;
    try {
      final meters = const Distance()(await widget.locate(), pin);
      return meters > OfferWaterForm.onSiteMeters
          ? tr.notAtPlace(formatKm(meters))
          : null;
    } catch (error) {
      return tr.onSiteCheckFailed(errorText(error));
    }
  }

  /// Location errors carry translated messages inside an Exception.
  static String errorText(Object error) =>
      '$error'.replaceFirst('Exception: ', '');

  String? requiredText(String? value) =>
      value == null || value.trim().isEmpty ? tr.fillInField : null;
}

/// A white card for one group of fields, headed by an icon and a title.
class _FormSection extends StatelessWidget {
  const _FormSection({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.children,
  });
  final IconData icon;
  final String title;
  final String? subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              WaterIcon(icon, size: 36),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    if (subtitle case final subtitle?)
                      Text(subtitle, style: const TextStyle(color: muted)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    ),
  );
}

/// Formats the entered CHF amount without accepting negative or non-finite values.
String? refillPriceLabel(String input) {
  final normalized = input.trim().replaceAll(',', '.');
  if (!RegExp(r'^\d{1,6}(\.\d{1,2})?$').hasMatch(normalized)) return null;
  final amount = double.parse(normalized);
  return amount == 0 ? 'Free' : 'CHF ${amount.toStringAsFixed(2)} / fill';
}

/// The amount in a stored price label, for the price field: "0" for free.
String? priceAmount(String label) {
  if (label == 'Free') return '0';
  return RegExp(r'^CHF (\d+(?:\.\d+)?) / fill$').firstMatch(label)?.group(1);
}
