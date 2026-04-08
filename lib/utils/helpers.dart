import 'package:cloud_firestore/cloud_firestore.dart';

double amount(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? "") ?? 0;
}

DateTime? asDate(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is String) return DateTime.tryParse(value);
  return null;
}

String formatDate(dynamic value) {
  final date = asDate(value);
  if (date == null) return "";
  final d = date.day.toString().padLeft(2, '0');
  final m = date.month.toString().padLeft(2, '0');
  final y = date.year.toString();
  return "$y-$m-$d";
}