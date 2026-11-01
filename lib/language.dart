import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_style.dart';
import 'push_notifications.dart';
import 'texts.dart';

const _languageKey = 'language';

/// The language chosen in the app, or null to follow the device.
final appLanguage = ValueNotifier<Locale?>(null);

/// Restores the language chosen on this device.
Future<void> loadAppLanguage() async {
  try {
    final code = (await SharedPreferences.getInstance()).getString(
      _languageKey,
    );
    if (appLocales.any((locale) => locale.languageCode == code)) {
      appLanguage.value = Locale(code!);
    }
  } catch (error) {
    debugPrint('Could not load the app language: $error');
  }
}

Future<void> setAppLanguage(Locale? locale) async {
  appLanguage.value = locale;
  // Push messages are written in the language stored with the device, which
  // follows the new texts once the app has rebuilt with them.
  WidgetsBinding.instance.addPostFrameCallback(
    (_) => PushNotifications.refreshLanguage(),
  );
  try {
    final preferences = await SharedPreferences.getInstance();
    locale == null
        ? await preferences.remove(_languageKey)
        : await preferences.setString(_languageKey, locale.languageCode);
  } catch (error) {
    debugPrint('Could not save the app language: $error');
  }
}

/// Opens the language choice; each language is named in itself.
class LanguageButton extends StatelessWidget {
  const LanguageButton({super.key});

  static const names = {'en': 'English', 'de': 'Deutsch', 'fr': 'Français'};

  @override
  Widget build(BuildContext context) => IconButton(
    icon: const Icon(Icons.translate),
    tooltip: tr.language,
    onPressed: () => showDialog<void>(
      context: context,
      builder: (dialogContext) {
        Widget option(String label, Locale? locale) => ListTile(
          title: Text(label),
          trailing: appLanguage.value?.languageCode == locale?.languageCode
              ? const Icon(Icons.check, color: teal)
              : null,
          onTap: () {
            Navigator.pop(dialogContext);
            setAppLanguage(locale);
          },
        );
        return SimpleDialog(
          title: Text(tr.language),
          children: [
            option(tr.languageAuto, null),
            for (final locale in appLocales)
              option(names[locale.languageCode]!, locale),
          ],
        );
      },
    ),
  );
}
