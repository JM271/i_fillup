import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import 'app_style.dart';
import 'water_place.dart';
import 'texts.dart';

/// The same filtered places as discovery, optionally with the planned route.
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
    appBar: AppBar(title: Text(tr.waterPlaces)),
    body: Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Text(tr.tapDrop),
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
                          message:
                              '${place.name} · ${displayPrice(place.price)}',
                          child: IconButton.filled(
                            key: ValueKey('map-${place.name}'),
                            tooltip: tr.viewPlace(place.name),
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
        SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Text(tr.mapLegend, textAlign: TextAlign.center),
          ),
        ),
      ],
    ),
  );
}
