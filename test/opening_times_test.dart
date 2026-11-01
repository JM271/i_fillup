import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:i_fillup/opening_times.dart';
import 'package:i_fillup/texts.dart';

void main() {
  tearDown(() => tr = lookupAppLocalizations(const Locale('en')));

  test('Opening times are stored without language and read back', () {
    const times = OpeningTimes(
      mode: OpeningMode.usual,
      weekdays: DayHours(
        TimeOfDay(hour: 7, minute: 30),
        TimeOfDay(hour: 19, minute: 0),
      ),
    );
    expect(times.encode(), 'weekdays=07:30-19:00;weekend=closed');
    final read = OpeningTimes.parse(times.encode())!;
    expect(read.mode, OpeningMode.usual);
    expect(read.weekdays.toString(), '07:30-19:00');
    expect(read.weekend, isNull);
    expect(OpeningTimes.parse('on-request')!.mode, OpeningMode.onRequest);
    expect(OpeningTimes.parse('always')!.mode, OpeningMode.always);
    expect(const OpeningTimes(mode: OpeningMode.always).encode(), 'always');
    expect(OpeningTimes.parse('Mon–Fri 08:00–18:00'), isNull);
  });

  test('Opening times are shown in the reader’s language', () {
    const stored = 'weekdays=08:00-18:00;weekend=09:00-12:00';
    expect(
      describeOpeningTimes(stored),
      'Mon–Fri 08:00–18:00 · Sat–Sun 09:00–12:00',
    );
    tr = lookupAppLocalizations(const Locale('de'));
    expect(
      describeOpeningTimes(stored),
      'Mo–Fr 08:00–18:00 · Sa–So 09:00–12:00',
    );
    expect(describeOpeningTimes('on-request'), 'Auf Anfrage');
    expect(
      describeOpeningTimes('always'),
      'Rund um die Uhr geöffnet, jeden Tag',
    );
    expect(
      describeOpeningTimes('weekdays=closed;weekend=10:00-16:00'),
      'Mo–Fr geschlossen · Sa–So 10:00–16:00',
    );
    expect(describeOpeningTimes('Bitte anrufen'), 'Bitte anrufen');
  });

  test('Usual times need an open day in the right order', () {
    expect(const OpeningTimes().problem, isNull);
    expect(
      const OpeningTimes(mode: OpeningMode.usual, weekdays: null).problem,
      'Open on weekdays or weekends, or choose On request.',
    );
    expect(
      const OpeningTimes(
        mode: OpeningMode.usual,
        weekdays: DayHours(
          TimeOfDay(hour: 18, minute: 0),
          TimeOfDay(hour: 8, minute: 0),
        ),
      ).problem,
      'The closing time must be after the opening time.',
    );
  });

  testWidgets('Hosts switch between on request and usual times', (
    tester,
  ) async {
    var value = const OpeningTimes();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => OpeningTimesField(
              value: value,
              onChanged: (next) => setState(() => value = next),
            ),
          ),
        ),
      ),
    );
    expect(find.text('Monday–Friday'), findsNothing);
    await tester.tap(find.text('Hours'));
    await tester.pumpAndSettle();
    expect(find.text('Monday–Friday'), findsOneWidget);
    expect(find.text('08:00'), findsOneWidget);
    await tester.tap(find.byType(Switch).last);
    await tester.pumpAndSettle();
    expect(value.encode(), 'weekdays=08:00-18:00;weekend=08:00-18:00');
    await tester.tap(find.text('24/7'));
    await tester.pumpAndSettle();
    expect(value.encode(), 'always');
    expect(find.text('Monday–Friday'), findsNothing);
    await tester.tap(find.text('On request'));
    await tester.pumpAndSettle();
    expect(value.encode(), 'on-request');
  });
}
