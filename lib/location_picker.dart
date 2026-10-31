import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import 'app_style.dart';

Future<LatLng> currentRefillLocation() async {
  if (!await Geolocator.isLocationServiceEnabled()) {
    throw Exception(
      'Turn on device location services, or choose a place manually.',
    );
  }
  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
  if (permission == LocationPermission.deniedForever) {
    throw Exception(
      'Location access is blocked. Enable it in device or browser settings, or tap the map manually.',
    );
  }
  if (permission == LocationPermission.denied) {
    throw Exception(
      'Location permission was denied. You can still tap the map to choose a place.',
    );
  }
  final position = await Geolocator.getCurrentPosition(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
      timeLimit: Duration(seconds: 15),
    ),
  );
  return LatLng(position.latitude, position.longitude);
}

class LocationPicker extends StatefulWidget {
  const LocationPicker({
    super.key,
    this.initial,
    this.locate = currentRefillLocation,
    this.tileProvider,
  });
  final LatLng? initial;
  final Future<LatLng> Function() locate;
  final TileProvider? tileProvider;
  @override
  State<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  final controller = MapController();
  late LatLng? selected = widget.initial;
  bool locating = false;
  int revision = 0;
  String? error;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> locate() async {
    final requestRevision = ++revision;
    setState(() {
      locating = true;
      error = null;
    });
    try {
      final point = await widget.locate().timeout(const Duration(seconds: 20));
      if (!mounted || revision != requestRevision) return;
      setState(() => selected = point);
      controller.move(point, 16);
    } catch (failure) {
      if (!mounted || revision != requestRevision) return;
      setState(
        () => error = failure is TimeoutException
            ? 'Finding your location took too long. Retry or tap the map manually.'
            : failure is Exception &&
                  failure.toString().startsWith('Exception: ')
            ? failure.toString().substring(11)
            : 'Could not access your location. Retry or tap the map manually.',
      );
    } finally {
      if (mounted && revision == requestRevision) {
        setState(() => locating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Choose your place')),
    body: Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Start at your current location, then tap to adjust the refill pin. The address is entered separately.',
          ),
        ),
        if (locating) const LinearProgressIndicator(),
        if (error != null)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        Expanded(
          child: FlutterMap(
            mapController: controller,
            options: MapOptions(
              initialCenter: selected ?? const LatLng(46.75, 7.7),
              initialZoom: selected == null ? 9 : 15,
              onMapReady: () {
                if (widget.initial == null) locate();
              },
              onTap: (_, point) => setState(() {
                revision++;
                locating = false;
                error = null;
                selected = point;
              }),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.i_fillup',
                tileProvider: widget.tileProvider,
              ),
              if (selected != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: selected!,
                      child: const Icon(
                        Icons.location_pin,
                        size: 40,
                        color: teal,
                      ),
                    ),
                  ],
                ),
              const SimpleAttributionWidget(
                source: Text('© OpenStreetMap contributors'),
              ),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OutlinedButton.icon(
                  onPressed: locating ? null : locate,
                  icon: const Icon(Icons.my_location),
                  label: const Text('My location'),
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: selected == null || locating
                      ? null
                      : () => Navigator.pop(context, selected),
                  child: const Text('Use this location'),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
