import 'dart:convert';
import 'dart:math' as math;

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import 'water_place.dart';
import 'texts.dart';

class PlannedRoute {
  const PlannedRoute({
    required this.destination,
    required this.start,
    required this.end,
    required this.path,
    required this.meters,
  }) : aroundStart = false;

  /// A zero-length route whose stops are measured by driving from [origin].
  PlannedRoute.around(LatLng origin)
    : destination = '',
      start = origin,
      end = origin,
      path = [origin],
      meters = 0,
      aroundStart = true;

  final String destination;
  final LatLng start, end;
  final List<LatLng> path;
  final double meters;
  final bool aroundStart;
}

/// A water place reachable from a route, measured by driving distance.
class RouteStop {
  const RouteStop(this.place, {required this.along, required this.offRoute});
  final WaterPlace place;

  /// Meters driven from the start to the place.
  final double along;

  /// Meters driven from the route to the place: half the detour there and back.
  final double offRoute;
}

abstract interface class RouteService {
  Future<PlannedRoute> route(LatLng start, LatLng end, String destination);
  Future<List<RouteStop>> stopsAlong(
    PlannedRoute route,
    List<WaterPlace> places, {
    required double maxOffRoute,
  });
}

/// Driving routes from OSRM. The public demo server has no availability
/// guarantee; set ROUTING_URL to a hosted instance for production.
class OsrmRouteService implements RouteService {
  OsrmRouteService({http.Client? client}) : client = client ?? http.Client();
  final http.Client client;

  static const endpoint = String.fromEnvironment(
    'ROUTING_URL',
    defaultValue: 'https://router.project-osrm.org/',
  );

  // OSRM's default table limit is 100 coordinates; two are start and end.
  static const maxCandidates = 98;

  String _coordinates(Iterable<LatLng> points) =>
      points.map((p) => '${p.longitude},${p.latitude}').join(';');

  Future<Map<String, dynamic>> _get(
    String path,
    Map<String, String> query,
  ) async {
    final response = await client
        .get(Uri.parse(endpoint).resolve(path).replace(queryParameters: query))
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      throw Exception(tr.routeUnavailable);
    }
    final data =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    if (data['code'] != 'Ok') {
      throw Exception(tr.noRouteFound);
    }
    return data;
  }

  @override
  Future<PlannedRoute> route(
    LatLng start,
    LatLng end,
    String destination,
  ) async {
    final data = await _get('route/v1/driving/${_coordinates([start, end])}', {
      'overview': 'simplified',
      'geometries': 'geojson',
    });
    final route = (data['routes'] as List).first as Map<String, dynamic>;
    final path = [
      for (final point in route['geometry']['coordinates'] as List)
        LatLng((point[1] as num).toDouble(), (point[0] as num).toDouble()),
    ];
    return PlannedRoute(
      destination: destination,
      start: start,
      end: end,
      path: path,
      meters: (route['distance'] as num).toDouble(),
    );
  }

  @override
  Future<List<RouteStop>> stopsAlong(
    PlannedRoute route,
    List<WaterPlace> places, {
    required double maxOffRoute,
  }) async {
    // Driving off the route is never shorter than the straight line to it.
    final nearby =
        [
            for (final place in places)
              (place, distanceToPath(place.location, route.path)),
          ].where((entry) => entry.$2 <= maxOffRoute).toList()
          ..sort((a, b) => a.$2.compareTo(b.$2));
    final candidates = nearby
        .take(maxCandidates)
        .map((entry) => entry.$1)
        .toList();
    if (candidates.isEmpty) return const [];

    final placeIndexes = [for (var i = 0; i < candidates.length; i++) i + 2];
    final data = await _get(
      'table/v1/driving/${_coordinates([route.start, route.end, ...candidates.map((p) => p.location)])}',
      {
        'sources': [0, ...placeIndexes].join(';'),
        'destinations': [1, ...placeIndexes].join(';'),
        'annotations': 'distance',
      },
    );
    final distances = data['distances'] as List;
    final fromStart = distances[0] as List;
    final stops = <RouteStop>[];
    for (var i = 0; i < candidates.length; i++) {
      final along = fromStart[i + 1];
      final toEnd = (distances[i + 1] as List)[0];
      if (along is! num || toEnd is! num) continue;
      final offRoute = math.max(0.0, (along + toEnd - route.meters) / 2);
      if (offRoute > maxOffRoute) continue;
      stops.add(
        RouteStop(candidates[i], along: along.toDouble(), offRoute: offRoute),
      );
    }
    return stops..sort((a, b) => a.along.compareTo(b.along));
  }
}

/// Straight-line meters from [point] to the nearest segment of [path].
double distanceToPath(LatLng point, List<LatLng> path) {
  if (path.isEmpty) return double.infinity;
  if (path.length == 1) return const Distance().distance(point, path.first);
  // Local equirectangular projection is accurate at route-corridor scale.
  const earthRadius = 6371000.0;
  final cosLat = math.cos(point.latitudeInRad);
  math.Point<double> project(LatLng p) => math.Point(
    (p.longitudeInRad - point.longitudeInRad) * cosLat * earthRadius,
    (p.latitudeInRad - point.latitudeInRad) * earthRadius,
  );
  var best = double.infinity;
  var a = project(path.first);
  for (final next in path.skip(1)) {
    final b = project(next);
    final dx = b.x - a.x, dy = b.y - a.y;
    final lengthSquared = dx * dx + dy * dy;
    final t = lengthSquared == 0
        ? 0.0
        : ((-a.x * dx - a.y * dy) / lengthSquared).clamp(0.0, 1.0);
    final x = a.x + t * dx, y = a.y + t * dy;
    best = math.min(best, math.sqrt(x * x + y * y));
    a = b;
  }
  return best;
}
