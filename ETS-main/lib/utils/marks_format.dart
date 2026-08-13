import 'package:flutter/services.dart';

/// Marks are stored as doubles so half-points ("8.5") can be awarded, but most
/// scores are still whole numbers and must not read as "8.0" in the UI.
///
/// A value of -1 means "not marked yet" and renders as a dash.
String formatMarks(num marks) {
  if (marks == -1) return '-';
  final double value = marks.toDouble();
  if (value == value.roundToDouble()) return value.toStringAsFixed(0);
  return value.toString();
}

/// Same as [formatMarks] but keeps the sentinel visible, for CSV columns that
/// stay numeric and pivotable.
String formatMarksNumeric(num marks) {
  if (marks == -1) return '-1';
  return formatMarks(marks);
}

/// Keyboard for marks entry — the decimal point has to be reachable on mobile.
const TextInputType marksInputType = TextInputType.numberWithOptions(
  decimal: true,
  signed: true,
);

/// Restricts typing to a single optionally-signed decimal number.
final List<TextInputFormatter> marksInputFormatters = [
  FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*')),
];
