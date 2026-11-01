import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'photo_field.dart';

/// What a water taker shares with the hosts they send requests to.
class TravelerProfile {
  const TravelerProfile({
    required this.name,
    required this.vehicle,
    this.phone = '',
    this.about = '',
    this.photo,
  });

  final String name, vehicle, phone, about;

  /// Photo of the traveler's vehicle.
  final Uint8List? photo;

  static TravelerProfile? fromMap(Object? data) {
    if (data is! Map) return null;
    final name = data['name'], vehicle = data['vehicle'];
    if (name is! String || name.isEmpty || vehicle is! String) return null;
    final phone = data['phone'], about = data['about'];
    return TravelerProfile(
      name: name,
      vehicle: vehicle,
      phone: phone is String ? phone : '',
      about: about is String ? about : '',
      photo: decodePhoto(data['photo']),
    );
  }

  Map<String, String> toMap() => {
    'name': name,
    'vehicle': vehicle,
    'phone': phone,
    'about': about,
    'photo': encodePhoto(photo),
  };
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
    this.initial,
    required this.onSave,
    this.intro,
  });

  final TravelerProfile? initial;
  final Future<void> Function(TravelerProfile profile) onSave;
  final String? intro;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final form = GlobalKey<FormState>();
  late final name = TextEditingController(text: widget.initial?.name);
  late final vehicle = TextEditingController(text: widget.initial?.vehicle);
  late final phone = TextEditingController(text: widget.initial?.phone);
  late final about = TextEditingController(text: widget.initial?.about);
  late Uint8List? photo = widget.initial?.photo;
  bool saving = false;

  @override
  void dispose() {
    name.dispose();
    vehicle.dispose();
    phone.dispose();
    about.dispose();
    super.dispose();
  }

  String? required(String? value) => value == null || value.trim().isEmpty
      ? 'Please fill in this field'
      : null;

  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    final profile = TravelerProfile(
      name: name.text.trim(),
      vehicle: vehicle.text.trim(),
      phone: phone.text.trim(),
      about: about.text.trim(),
      photo: photo,
    );
    setState(() => saving = true);
    try {
      await widget.onSave(profile);
      if (mounted) Navigator.pop(context, profile);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save your profile. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Your profile')),
    body: Form(
      key: form,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.intro ?? 'Hosts see your profile on the refill requests you send them.',
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: name,
              maxLength: 60,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'First name or nickname',
              ),
              validator: required,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: vehicle,
              maxLength: 80,
              decoration: const InputDecoration(
                labelText: 'Vehicle',
                hintText: 'Campervan, 6 m',
              ),
              validator: required,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: phone,
              maxLength: 30,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone (optional)',
                hintText: '+41 79 123 45 67',
                helperText: 'Only shared with hosts you send a request to.',
                helperMaxLines: 2,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: about,
              maxLength: 300,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'About me (optional)',
                hintText: 'Travelling with two kids and a dog, own hose',
              ),
            ),
            const SizedBox(height: 8),
            PhotoField(
              label: 'Photo of your vehicle (optional)',
              photo: photo,
              onChanged: (value) => setState(() => photo = value),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: saving ? null : save,
              child: Text(saving ? 'Saving…' : 'Save profile'),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Opens the profile form prefilled with the saved profile.
Future<TravelerProfile?> editProfile(
  BuildContext context, {
  required Future<TravelerProfile?> Function() load,
  required Future<void> Function(TravelerProfile profile) save,
  String? intro,
}) async {
  final TravelerProfile? current;
  try {
    current = await load();
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not load your profile.')),
      );
    }
    return null;
  }
  if (!context.mounted) return null;
  return Navigator.of(context).push<TravelerProfile>(
    MaterialPageRoute(
      builder: (_) => ProfilePage(initial: current, onSave: save, intro: intro),
    ),
  );
}

/// The water taker's profile as a host sees it on an incoming request.
class RequesterSummary extends StatelessWidget {
  const RequesterSummary({super.key, required this.profile});
  final TravelerProfile? profile;

  @override
  Widget build(BuildContext context) {
    final traveler = profile;
    final muted = Theme.of(context).textTheme.bodySmall;
    if (traveler == null) {
      return Text(
        'No traveler profile (sent before profiles existed)',
        style: muted,
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 28,
          backgroundImage: traveler.photo == null
              ? null
              : MemoryImage(traveler.photo!),
          child: traveler.photo == null
              ? Text(traveler.name.characters.first.toUpperCase())
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                traveler.name,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              Text(traveler.vehicle),
              if (traveler.about.isNotEmpty) Text(traveler.about, style: muted),
              if (traveler.phone.isNotEmpty)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                    onPressed: () => launchUrl(
                      Uri(
                        scheme: 'tel',
                        path: traveler.phone.replaceAll(' ', ''),
                      ),
                    ),
                    icon: const Icon(Icons.call_outlined),
                    label: Text('Call ${traveler.phone}'),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
