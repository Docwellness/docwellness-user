/// Shared by DietStartsSoonWidget (Diet tab) and Home's BMI/timer card -
/// both need to render "how long until this diet plan's current week
/// starts" from the same weekStartDate, so this stays in one place.
String dietCountdownText(DateTime startDate) {
  final remaining = startDate.difference(DateTime.now());
  if (remaining.isNegative) {
    // The moment has arrived but the screen hasn't refetched yet - the
    // caller's own periodic tick keeps this readable until the next real
    // data refresh swaps it out for actual diet content.
    return 'Starting any moment now';
  }
  final days = remaining.inDays;
  final hours = remaining.inHours % 24;
  final dayLabel = days == 1 ? '1 day' : '$days days';
  final hourLabel = hours == 1 ? '1 hour' : '$hours hours';
  if (days > 0 && hours > 0) return '$dayLabel $hourLabel';
  if (days > 0) return dayLabel;
  if (hours > 0) return hourLabel;
  final minutes = remaining.inMinutes % 60;
  final minuteLabel = minutes == 1 ? '1 minute' : '$minutes minutes';
  return minuteLabel;
}
