const _monthNames = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String formatCompactDate(DateTime date, [DateTime? referenceDate]) {
  final reference = referenceDate ?? DateTime.now();
  final year = date.year == reference.year ? '' : ' ${date.year}';
  return '${_monthNames[date.month - 1]} ${date.day}$year';
}
