import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import 'app_style.dart';
import 'water_place.dart';

/// The same filtered places as discovery, shown at illustrative demo coordinates.
class WaterPlacesMap extends StatelessWidget {
  const WaterPlacesMap({
    super.key,
    required this.places,
    this.route,
    this.tileProvider,
  });

  final List<WaterPlace> places;

  /// Driving route to draw beneath the places, when one is planned.
  final List<LatLng>? route;
  final TileProvider? tileProvider;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Water places')),
    body: Column(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Text(
            'Demo locations near each town — not verified refill addresses. Tap a water drop for details.',
          ),
        ),
        Expanded(
          child: FlutterMap(
            options: MapOptions(
              initialCenter: places.first.location,
              initialZoom: 12,
              initialCameraFit: CameraFit.bounds(
                bounds: LatLngBounds.fromPoints([
                  ...places.map((p) => p.location),
                  ...?route,
                ]),
                padding: const EdgeInsets.all(64),
                maxZoom: 13,
              ),
              minZoom: 3,
              maxZoom: 18,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.i_fillup',
                maxNativeZoom: 19,
                tileProvider: tileProvider,
              ),
              if (route case final path?)
                PolylineLayer(
                  polylines: [
                    Polyline(points: path, strokeWidth: 5, color: ink),
                  ],
                ),
              MarkerLayer(
                markers: places
                    .map(
                      (place) => Marker(
                        point: place.location,
                        width: 56,
                        height: 56,
                        child: Tooltip(
                          message: '${place.name} · ${place.price}',
                          child: IconButton.filled(
                            key: ValueKey('map-${place.name}'),
                            tooltip: 'View ${place.name}',
                            style: IconButton.styleFrom(
                              backgroundColor: place.private ? teal : ink,
                            ),
                            onPressed: () => Navigator.pop(context, place),
                            icon: const Icon(
                              Icons.water_drop,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              RichAttributionWidget(
                attributions: [
                  TextSourceAttribution(
                    'OpenStreetMap contributors',
                    onTap: () => launchUrl(
                      Uri.parse('https://www.openstreetmap.org/copyright'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              'Teal: private host · Dark: refill stop\nDrag to explore · Pinch to zoom · Map requires internet',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    ),
  );
}
