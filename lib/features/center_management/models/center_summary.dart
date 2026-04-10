import 'package:cloud_firestore/cloud_firestore.dart';

class CenterSummary {
  final int totalCourses;
  final int totalUsers;
  final int totalPayments;
  final int approvedPayments;
  final double revenue;
  final int totalSessions;
  final int totalEvents;

  final DateTime? lastUpdated;

  const CenterSummary({
    required this.totalCourses,
    required this.totalUsers,
    required this.totalPayments,
    required this.approvedPayments,
    required this.revenue,
    required this.totalSessions,
    required this.totalEvents,
    this.lastUpdated,
  });

  factory CenterSummary.empty() {
    return const CenterSummary(
      totalCourses: 0,
      totalUsers: 0,
      totalPayments: 0,
      approvedPayments: 0,
      revenue: 0,
      totalSessions: 0,
      totalEvents: 0,
      lastUpdated: null,
    );
  }

  double get conversionRate {
    if (totalPayments == 0) return 0;
    return approvedPayments / totalPayments;
  }

  double get avgRevenuePerUser {
    if (totalUsers == 0) return 0;
    return revenue / totalUsers;
  }

  double get avgRevenuePerPayment {
    if (approvedPayments == 0) return 0;
    return revenue / approvedPayments;
  }

  bool get hasRevenue => revenue > 0;

  CenterSummary copyWith({
    int? totalCourses,
    int? totalUsers,
    int? totalPayments,
    int? approvedPayments,
    double? revenue,
    int? totalSessions,
    int? totalEvents,
    DateTime? lastUpdated,
  }) {
    return CenterSummary(
      totalCourses: totalCourses ?? this.totalCourses,
      totalUsers: totalUsers ?? this.totalUsers,
      totalPayments: totalPayments ?? this.totalPayments,
      approvedPayments: approvedPayments ?? this.approvedPayments,
      revenue: revenue ?? this.revenue,
      totalSessions: totalSessions ?? this.totalSessions,
      totalEvents: totalEvents ?? this.totalEvents,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalCourses': totalCourses,
      'totalUsers': totalUsers,
      'totalPayments': totalPayments,
      'approvedPayments': approvedPayments,
      'revenue': revenue,
      'totalSessions': totalSessions,
      'totalEvents': totalEvents,
      'lastUpdated': lastUpdated != null
          ? Timestamp.fromDate(lastUpdated!)
          : null,
    };
  }

  factory CenterSummary.fromMap(Map<String, dynamic>? map) {
    if (map == null) return CenterSummary.empty();

    return CenterSummary(
      totalCourses: _toInt(map['totalCourses']),
      totalUsers: _toInt(map['totalUsers']),
      totalPayments: _toInt(map['totalPayments']),
      approvedPayments: _toInt(map['approvedPayments']),
      revenue: _toDouble(map['revenue']),
      totalSessions: _toInt(map['totalSessions']),
      totalEvents: _toInt(map['totalEvents']),
      lastUpdated: _toDate(map['lastUpdated']),
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? "") ?? 0;
  }

  static double _toDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? "") ?? 0.0;
  }

  static DateTime? _toDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  String formatRevenue() {
    if (revenue >= 1000000) {
      return "${(revenue / 1000000).toStringAsFixed(1)}M";
    }
    if (revenue >= 1000) {
      return "${(revenue / 1000).toStringAsFixed(1)}K";
    }
    return revenue.toStringAsFixed(0);
  }

  String formatConversion() {
    return "${(conversionRate * 100).toStringAsFixed(1)}%";
  }

  @override
  String toString() {
    return 'CenterSummary(courses: $totalCourses, users: $totalUsers, revenue: $revenue)';
  }
}