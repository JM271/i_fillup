import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AppSwitchButton extends StatelessWidget {
  const AppSwitchButton({super.key, required this.toGiver});
  final bool toGiver;

  @override
  Widget build(BuildContext context) => TextButton.icon(
    icon: const Icon(Icons.swap_horiz),
    label: Text(toGiver ? 'Give water' : 'Take water'),
    onPressed: () async {
      final messenger = ScaffoldMessenger.of(context);
      if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              'Switching between installed apps is currently available on Android.',
            ),
          ),
        );
        return;
      }
      var opened = false;
      try {
        opened = await launchUrl(
          Uri.parse(toGiver ? 'ifillup-giver://home' : 'ifillup-taker://home'),
          mode: LaunchMode.externalApplication,
        );
      } catch (_) {
        // Report an unavailable companion app without interrupting the current app.
      }
      if (!opened && context.mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'Install i fillup ${toGiver ? 'Give' : 'Take'} on this device to switch apps.',
            ),
          ),
        );
      }
    },
  );
}
