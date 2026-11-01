import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'app_style.dart';

/// Photos are stored inside Firestore documents, so they are kept small.
const maxPhotoBytes = 200 * 1024;

typedef PhotoSource = Future<Uint8List?> Function(ImageSource source);

Future<Uint8List?> pickPhoto(ImageSource source) async {
  final file = await ImagePicker().pickImage(
    source: source,
    maxWidth: 800,
    maxHeight: 800,
    imageQuality: 70,
  );
  return file?.readAsBytes();
}

String encodePhoto(Uint8List? photo) =>
    photo == null ? '' : base64Encode(photo);

Uint8List? decodePhoto(Object? data) {
  if (data is! String || data.isEmpty) return null;
  try {
    return base64Decode(data);
  } on FormatException {
    return null;
  }
}

class PhotoField extends StatelessWidget {
  const PhotoField({
    super.key,
    required this.label,
    required this.photo,
    required this.onChanged,
    this.pick = pickPhoto,
  });

  final String label;
  final Uint8List? photo;
  final ValueChanged<Uint8List?> onChanged;
  final PhotoSource pick;

  Future<void> choose(BuildContext context, ImageSource source) async {
    final Uint8List? bytes;
    try {
      bytes = await pick(source);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the photo.')),
        );
      }
      return;
    }
    if (bytes == null) return;
    if (bytes.length > maxPhotoBytes) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This photo is too large. Choose another one.'),
          ),
        );
      }
      return;
    }
    onChanged(bytes);
  }

  @override
  Widget build(BuildContext context) {
    final image = photo;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: image == null
                ? const ColoredBox(
                    color: foam,
                    child: Icon(
                      Icons.photo_camera_outlined,
                      size: 40,
                      color: teal,
                    ),
                  )
                : Image.memory(image, fit: BoxFit.cover),
          ),
        ),
        Wrap(
          spacing: 8,
          children: [
            TextButton.icon(
              onPressed: () => choose(context, ImageSource.camera),
              icon: const Icon(Icons.photo_camera_outlined),
              label: const Text('Take photo'),
            ),
            TextButton.icon(
              onPressed: () => choose(context, ImageSource.gallery),
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Choose photo'),
            ),
            if (image != null)
              TextButton.icon(
                onPressed: () => onChanged(null),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Remove'),
              ),
          ],
        ),
      ],
    );
  }
}
