import 'package:flutter/material.dart';

import 'app_style.dart';
import 'texts.dart';

/// Opening hours for one group of days.
class DayHours {
  const DayHours(this.opens, this.closes);
  final TimeOfDay opens, closes;

  static const usual = DayHours(
    TimeOfDay(hour: 8, minute: 0),
    TimeOfDay(hour: 18, minute: 0),
  );

  bool get valid =>
      closes.hour * 60 + closes.minute > opens.hour * 60 + opens.minute;

  @override
  String toString() => '${formatTime(opens)}-${formatTime(closes)}';

  static DayHours? parse(String value) {
    final match = RegExp(r'^(\d\d):(\d\d)-(\d\d):(\d\d)$').firstMatch(value);
    if (match == null) return null;
    final [h1, m1, h2, m2] = [
      for (var i = 1; i <= 4; i++) int.parse(match.group(i)!),
    ];
    return DayHours(
      TimeOfDay(hour: h1, minute: m1),
      TimeOfDay(hour: h2, minute: m2),
    );
  }
}

String formatTime(TimeOfDay time) =>
    '${time.hour.toString().padLeft(2, '0')}:'
    '${time.minute.toString().padLeft(2, '0')}';

enum OpeningMode { onRequest, usual, always }

/// "On request", usual hours on weekdays and weekends (null hours mean
/// closed), or open around the clock. Stored as language-neutral text:
/// "on-request", "always" or "weekdays=08:00-18:00;weekend=closed".
class OpeningTimes {
  const OpeningTimes({
    this.mode = OpeningMode.onRequest,
    this.weekdays = DayHours.usual,
    this.weekend,
  });
  final OpeningMode mode;
  final DayHours? weekdays, weekend;

  static const onRequestValue = 'on-request';
  static const alwaysValue = 'always';

  OpeningTimes copyWith({
    OpeningMode? mode,
    DayHours? Function()? weekdays,
    DayHours? Function()? weekend,
  }) => OpeningTimes(
    mode: mode ?? this.mode,
    weekdays: weekdays == null ? this.weekdays : weekdays(),
    weekend: weekend == null ? this.weekend : weekend(),
  );

  /// Why these times cannot be saved, or null when they can.
  String? get problem {
    if (mode != OpeningMode.usual) return null;
    if (weekdays == null && weekend == null) return tr.openingNeedOne;
    if (!(weekdays?.valid ?? true) || !(weekend?.valid ?? true)) {
      return tr.openingOrder;
    }
    return null;
  }

  String encode() => switch (mode) {
    OpeningMode.onRequest => onRequestValue,
    OpeningMode.always => alwaysValue,
    OpeningMode.usual =>
      'weekdays=${weekdays ?? 'closed'};weekend=${weekend ?? 'closed'}',
  };

  /// Reads stored times; null for free text written before these choices.
  static OpeningTimes? parse(String value) {
    if (value == onRequestValue) return const OpeningTimes();
    if (value == alwaysValue) {
      return const OpeningTimes(mode: OpeningMode.always);
    }
    final match = RegExp(r'^weekdays=([^;]+);weekend=(.+)$').firstMatch(value);
    if (match == null) return null;
    DayHours? hours(String text) =>
        text == 'closed' ? null : DayHours.parse(text);
    final weekdays = hours(match.group(1)!);
    final weekend = hours(match.group(2)!);
    if (weekdays == null && match.group(1) != 'closed') return null;
    if (weekend == null && match.group(2) != 'closed') return null;
    return OpeningTimes(
      mode: OpeningMode.usual,
      weekdays: weekdays,
      weekend: weekend,
    );
  }
}

/// Stored opening times in the reader's language; older free text as written.
String describeOpeningTimes(String stored) {
  final times = OpeningTimes.parse(stored);
  if (times == null) return stored;
  switch (times.mode) {
    case OpeningMode.onRequest:
      return tr.openingOnRequest;
    case OpeningMode.always:
      return tr.openingAlways;
    case OpeningMode.usual:
  }
  String part(String days, DayHours? hours) => hours == null
      ? '$days ${tr.closed}'
      : '$days ${formatTime(hours.opens)}–${formatTime(hours.closes)}';
  return '${part(tr.weekdaysShort, times.weekdays)} · '
      '${part(tr.weekendShort, times.weekend)}';
}

class OpeningTimesField extends StatelessWidget {
  const OpeningTimesField({
    super.key,
    required this.value,
    required this.onChanged,
    this.error,
    this.previous,
  });
  final OpeningTimes value;
  final ValueChanged<OpeningTimes> onChanged;
  final String? error;

  /// Free-text times saved before these choices, shown for reference.
  final String? previous;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(tr.openingTimes, style: Theme.of(context).textTheme.titleSmall),
      const SizedBox(height: 8),
      SegmentedButton<OpeningMode>(
        showSelectedIcon: false,
        segments: [
          ButtonSegment(
            value: OpeningMode.onRequest,
            label: Text(tr.segmentOnRequest),
          ),
          ButtonSegment(value: OpeningMode.usual, label: Text(tr.segmentHours)),
          ButtonSegment(
            value: OpeningMode.always,
            label: Text(tr.openingAlwaysShort),
          ),
        ],
        selected: {value.mode},
        onSelectionChanged: (selection) =>
            onChanged(value.copyWith(mode: selection.single)),
      ),
      const SizedBox(height: 8),
      if (value.mode == OpeningMode.onRequest)
        Text(tr.openingOnRequestHelp, style: const TextStyle(color: muted))
      else if (value.mode == OpeningMode.always)
        Text(tr.openingAlways, style: const TextStyle(color: muted))
      else ...[
        _DaysRow(
          label: tr.mondayToFriday,
          hours: value.weekdays,
          onChanged: (hours) =>
              onChanged(value.copyWith(weekdays: () => hours)),
        ),
        const SizedBox(height: 8),
        _DaysRow(
          label: tr.saturdaySunday,
          hours: value.weekend,
          onChanged: (hours) => onChanged(value.copyWith(weekend: () => hours)),
        ),
      ],
      if (error != null)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      if (previous != null)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            tr.previously(previous!),
            style: const TextStyle(color: muted),
          ),
        ),
    ],
  );
}

class _DaysRow extends StatelessWidget {
  const _DaysRow({
    required this.label,
    required this.hours,
    required this.onChanged,
  });
  final String label;
  final DayHours? hours;
  final ValueChanged<DayHours?> onChanged;

  Future<void> pick(BuildContext context, {required bool opens}) async {
    final current = hours!;
    final time = await showTimePicker(
      context: context,
      initialTime: opens ? current.opens : current.closes,
      helpText: opens ? tr.opens : tr.closes,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (time == null) return;
    onChanged(
      opens ? DayHours(time, current.closes) : DayHours(current.opens, time),
    );
  }

  @override
  Widget build(BuildContext context) {
    final open = hours;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                if (open == null)
                  Text(tr.closed, style: const TextStyle(color: muted)),
                Switch(
                  value: open != null,
                  onChanged: (value) =>
                      onChanged(value ? DayHours.usual : null),
                ),
              ],
            ),
            if (open != null)
              Row(
                children: [
                  OutlinedButton(
                    onPressed: () => pick(context, opens: true),
                    child: Text(formatTime(open.opens)),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('–'),
                  ),
                  OutlinedButton(
                    onPressed: () => pick(context, opens: false),
                    child: Text(formatTime(open.closes)),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
