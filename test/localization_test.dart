import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:i_fillup/language.dart';
import 'package:i_fillup/main.dart';
import 'package:i_fillup/texts.dart';
import 'package:i_fillup/water_place.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(() {
    tr = lookupAppLocalizations(const Locale('en'));
    appLanguage.value = null;
  });

  Future<void> openIn(WidgetTester tester, Locale locale) async {
    tester.platformDispatcher.localesTestValue = [locale];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    tester.view.physicalSize = const Size(400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const FillupApp());
    await tester.pumpAndSettle();
  }

  testWidgets('The app follows a German device', (tester) async {
    await openIn(tester, const Locale('de', 'CH'));
    expect(find.text('Willkommen bei i fillup'), findsOneWidget);
    await tester.tap(find.text('Wasser holen'));
    await tester.pumpAndSettle();
    expect(find.text('Wasserstelle entdecken'), findsOneWidget);
    expect(find.text('CHF 5 / Füllung'), findsOneWidget);
  });

  testWidgets('The app follows a French device', (tester) async {
    await openIn(tester, const Locale('fr', 'CH'));
    expect(find.text('Bienvenue sur i fillup'), findsOneWidget);
    await tester.tap(find.text('Offrir de l’eau'));
    await tester.pumpAndSettle();
    expect(find.text('Mes lieux'), findsOneWidget);
  });

  testWidgets('Other languages fall back to English', (tester) async {
    await openIn(tester, const Locale('it'));
    expect(find.text('Welcome to i fillup'), findsOneWidget);
  });

  test('Stored prices and statuses are shown in the reader’s language', () {
    tr = lookupAppLocalizations(const Locale('fr'));
    expect(displayPrice('Free'), 'Gratuit');
    expect(displayPrice('CHF 5.00 / fill'), 'CHF 5.00 / plein');
    expect(displayPrice('10 EUR'), '10 EUR');
    expect(requestStatus('accepted'), 'acceptée');
    expect(vehicleSummary(['campervan']), 'Fourgon jusqu’à 6 m');
  });

  testWidgets('A chosen language overrides the device and is remembered', (
    tester,
  ) async {
    await openIn(tester, const Locale('en', 'US'));
    await tester.tap(find.byTooltip('Language'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Français'));
    await tester.pumpAndSettle();
    expect(find.text('Bienvenue sur i fillup'), findsOneWidget);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('language'), 'fr');

    await tester.tap(find.byTooltip('Langue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Langue de l\u2019appareil'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome to i fillup'), findsOneWidget);
    expect(preferences.getString('language'), isNull);

    appLanguage.value = null;
    preferences.setString('language', 'de');
    await loadAppLanguage();
    expect(appLanguage.value, const Locale('de'));
  });
}
