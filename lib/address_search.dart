import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class AddressMatch {
  const AddressMatch(this.label, this.location);
  final String label;
  final LatLng location;
}

typedef AddressLookup = Future<List<AddressMatch>> Function(String query);

final _addressCache = <String, List<AddressMatch>>{};

Future<List<AddressMatch>> searchAddresses(String query) async {
  final key = query.trim();
  if (_addressCache.containsKey(key)) return _addressCache[key]!;
  const endpoint = String.fromEnvironment(
    'ADDRESS_SEARCH_URL',
    defaultValue: 'https://photon.komoot.io/api/',
  );
  final response = await http
      .get(
        Uri.parse(endpoint).replace(queryParameters: {'q': key, 'limit': '6'}),
      )
      .timeout(const Duration(seconds: 15));
  if (response.statusCode != 200) {
    throw Exception('Address search is unavailable. Please try again.');
  }
  final results = parseAddressMatches(
    jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>,
  );
  if (_addressCache.length >= 30) {
    _addressCache.remove(_addressCache.keys.first);
  }
  _addressCache[key] = results;
  return results;
}

List<AddressMatch> parseAddressMatches(Map<String, dynamic> data) {
  final results = <AddressMatch>[];
  for (final feature in data['features'] as List? ?? []) {
    final coordinates = feature['geometry']?['coordinates'];
    final properties = feature['properties'];
    if (coordinates is! List || coordinates.length < 2 || properties is! Map) {
      continue;
    }
    final lon = coordinates[0];
    final lat = coordinates[1];
    if (lon is! num ||
        lat is! num ||
        !lon.isFinite ||
        !lat.isFinite ||
        lon.abs() > 180 ||
        lat.abs() > 90) {
      continue;
    }
    String text(String key) => properties[key]?.toString().trim() ?? '';
    final street = [
      text('street'),
      text('housenumber'),
    ].where((s) => s.isNotEmpty).join(' ');
    final town = [
      text('postcode'),
      text('city').isEmpty ? text('town') : text('city'),
    ].where((s) => s.isNotEmpty).join(' ');
    final parts = <String>{
      text('name'),
      street,
      town,
      text('state'),
      text('country'),
    }..remove('');
    if (parts.isEmpty) continue;
    results.add(
      AddressMatch(parts.join(', '), LatLng(lat.toDouble(), lon.toDouble())),
    );
  }
  return results;
}

class AddressSearchPage extends StatefulWidget {
  const AddressSearchPage({
    super.key,
    this.initialQuery = '',
    this.lookup = searchAddresses,
  });
  final String initialQuery;
  final AddressLookup lookup;
  @override
  State<AddressSearchPage> createState() => _AddressSearchPageState();
}

class _AddressSearchPageState extends State<AddressSearchPage> {
  late final query = TextEditingController(text: widget.initialQuery);
  List<AddressMatch> matches = [];
  bool busy = false;
  bool searched = false;
  String? error;
  int revision = 0;
  @override
  void dispose() {
    query.dispose();
    super.dispose();
  }

  Future<void> search() async {
    if (busy) return;
    if (query.text.trim().length < 3) {
      setState(() => error = 'Enter at least 3 characters, including a town.');
      return;
    }
    final request = ++revision;
    FocusScope.of(context).unfocus();
    setState(() {
      busy = true;
      error = null;
      matches = [];
      searched = false;
    });
    try {
      final result = await widget.lookup(query.text.trim());
      if (!mounted || revision != request) return;
      setState(() {
        matches = result;
        searched = true;
      });
    } catch (_) {
      if (mounted && revision == request) {
        setState(
          () => error = 'Could not search addresses. Check your internet connection and try again, or enter the address and choose its map pin manually.',
        );
      }
    } finally {
      if (mounted && revision == request) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Choose an address')),
    body: SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: query,
                  textInputAction: TextInputAction.search,
                  decoration: const InputDecoration(
                    labelText: 'Street, house number and town',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => search(),
                  onChanged: (_) => setState(() {
                    revision++;
                    busy = false;
                    matches = [];
                    searched = false;
                    error = null;
                  }),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: busy ? null : search,
                  icon: const Icon(Icons.search),
                  label: const Text('Search addresses'),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Search, then choose a match below. Check the pin before saving your offer.',
                ),
                if (busy)
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: LinearProgressIndicator(),
                  ),
                if (error != null)
                  Text(
                    error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                if (searched && matches.isEmpty)
                  const ListTile(
                    title: Text('No addresses found'),
                    subtitle: Text('Try adding a postcode, town or country.'),
                  ),
                ...matches.map(
                  (match) => ListTile(
                    leading: const Icon(Icons.location_on_outlined),
                    title: Text(match.label),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.pop(context, match),
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              'Address search: Photon · © OpenStreetMap contributors',
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    ),
  );
}
