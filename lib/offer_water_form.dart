import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';

import 'google_address_picker.dart';
import 'address_search.dart';

import 'package:flutter/material.dart';

import 'location_picker.dart';
import 'photo_field.dart';

import 'package:latlong2/latlong.dart';

import 'water_place.dart';

class OfferWaterForm extends StatefulWidget {
  const OfferWaterForm({
    super.key,
    required this.onSave,
    this.addressLookup = searchAddresses,
    this.isDemo = true,
  });
  final Future<void> Function(WaterPlace) onSave;
  final AddressLookup addressLookup;
  final bool isDemo;
  @override
  State<OfferWaterForm> createState() => _OfferWaterFormState();
}

class _OfferWaterFormState extends State<OfferWaterForm> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController();
  final address = TextEditingController();
  final hours = TextEditingController();
  final price = TextEditingController(text: '5.00');
  LatLng? location;
  Uint8List? photo;
  final vehicles = <String>{};
  bool missingLocation = false;
  bool missingVehicles = false;
  bool saving = false;
  bool get useGoogle =>
      !kIsWeb &&
      defaultTargetPlatform == TargetPlatform.android &&
      widget.addressLookup == searchAddresses;

  @override
  void dispose() {
    name.dispose();
    address.dispose();
    hours.dispose();
    price.dispose();
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
          Text(
            'Offer water.\nEarn cash.',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 12),
          const Text(
            'Set your price for a campervan refill, add your place and choose your opening times.',
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: name,
            decoration: const InputDecoration(
              labelText: 'Place name',
              hintText: 'Water at our farm',
              border: OutlineInputBorder(),
            ),
            validator: requiredText,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: address,
            onChanged: (_) => setState(() => location = null),
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Address / place',
              hintText: 'Street, house number, postcode, town, country',
              border: OutlineInputBorder(),
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
                      content: Text(
                        error.message ??
                            'Could not open Google address search.',
                      ),
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
                });
              }
            },
            icon: const Icon(Icons.search),
            label: Text(
              useGoogle
                  ? 'Choose address with Google'
                  : 'Choose address from list',
            ),
          ),
          const SizedBox(height: 12),
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
                });
              }
            },
            icon: const Icon(Icons.pin_drop_outlined),
            label: Text(
              location == null ? 'Choose place on map' : 'Change map location',
            ),
          ),
          if (location != null)
            Text(
              'Pin: ${location!.latitude.toStringAsFixed(5)}, ${location!.longitude.toStringAsFixed(5)}',
            ),
          if (missingLocation)
            Text(
              'Choose your place on the map.',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          const SizedBox(height: 16),
          TextFormField(
            controller: hours,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Opening times',
              alignLabelWithHint: true,
              hintText: 'Mon–Fri: 08:00–18:00\nSat: 09:00–12:00\nSun: closed',
              helperText:
                  'Include days, local times and any appointment requirements.',
              helperMaxLines: 2,
              border: OutlineInputBorder(),
            ),
            validator: requiredText,
          ),
          const SizedBox(height: 16),
          // One child, so the error line cannot shift the fields around it.
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Which vehicles can reach the water?',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
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
                Text(
                  'Choose at least one vehicle type.',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
            ],
          ),
          const SizedBox(height: 16),
          PhotoField(
            label: 'Photo of the water place (optional)',
            photo: photo,
            onChanged: (value) => setState(() => photo = value),
          ),
          const SizedBox(height: 16),
          TextFormField(
            key: const ValueKey('offer-price'),
            controller: price,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Price per fill-up',
              prefixText: 'CHF ',
              helperText:
                  'One price per refill. Enter 0 to offer water for free.',
              helperMaxLines: 2,
              border: OutlineInputBorder(),
            ),
            validator: (value) => refillPriceLabel(value ?? '') == null
                ? 'Enter a price of 0 or more, with up to 2 decimals'
                : null,
          ),
          const SizedBox(height: 12),
          const Text(
            'Payment is arranged directly with the traveler. The app does not collect payments or pay out earnings.',
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: saving
                ? null
                : () async {
                    final valid = form.currentState!.validate();
                    setState(() {
                      missingLocation = location == null;
                      missingVehicles = vehicles.isEmpty;
                    });
                    if (!valid || location == null || vehicles.isEmpty) {
                      return;
                    }
                    setState(() => saving = true);
                    try {
                      await widget.onSave(
                        WaterPlace(
                          name.text.trim(),
                          address.text.trim(),
                          'Local host',
                          true,
                          refillPriceLabel(price.text)!,
                          'Contact and water suitability must be confirmed before visiting.',
                          Icons.cottage_outlined,
                          location!,
                          openingTimes: hours.text.trim(),
                          photo: photo,
                          vehicles: [
                            for (final key in vehicleAccess.keys)
                              if (vehicles.contains(key)) key,
                          ],
                        ),
                      );
                    } catch (error) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              error is FirebaseException
                                  ? 'Could not save offer: ${error.message}'
                                  : 'Could not save offer. Please try again.',
                            ),
                          ),
                        );
                      }
                      return;
                    } finally {
                      if (mounted) setState(() => saving = false);
                    }
                    if (!mounted) return;
                    name.clear();
                    address.clear();
                    hours.clear();
                    price.text = '5.00';
                    setState(() {
                      location = null;
                      photo = null;
                      vehicles.clear();
                    });
                  },
            icon: const Icon(Icons.save_outlined),
            label: Text(saving ? 'Saving…' : 'Save offer'),
          ),
          const SizedBox(height: 12),
          Text(
            widget.isDemo
                ? 'Preview only: offers stay in this session and are not shared with travelers.'
                : 'Your place will appear in Find water so travelers can send you refill requests.',
          ),
        ],
      ),
    ),
  );

  String? requiredText(String? value) => value == null || value.trim().isEmpty
      ? 'Please fill in this field'
      : null;
}

/// Formats the entered CHF amount without accepting negative or non-finite values.
String? refillPriceLabel(String input) {
  final normalized = input.trim().replaceAll(',', '.');
  if (!RegExp(r'^\d{1,6}(\.\d{1,2})?$').hasMatch(normalized)) return null;
  final amount = double.parse(normalized);
  return amount == 0 ? 'Free' : 'CHF ${amount.toStringAsFixed(2)} / fill';
}
