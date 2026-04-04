class AdminStatsHelper {

  static final Map<String, dynamic> _cache = {};

  static double safeDouble(dynamic v) {
    try {
      if (v == null) return 0;

      if (v is double) {
        if (v.isNaN || v.isInfinite) return 0;
        return v;
      }

      if (v is int) return v.toDouble();

      if (v is String) {
        final parsed = double.tryParse(v);
        if (parsed == null || parsed.isNaN || parsed.isInfinite) return 0;
        return parsed;
      }

      return 0;
    } catch (_) {
      return 0;
    }
  }

  static String safeString(dynamic v) {
    try {
      if (v == null) return "";
      return v.toString();
    } catch (_) {
      return "";
    }
  }

  static double safeDivide(num a, num b) {
    try {
      if (b == 0) return 0;

      final result = a / b;

      if (result.isNaN || result.isInfinite) return 0;

      return result;
    } catch (_) {
      return 0;
    }
  }

  static double growth(int current, int previous) {
    try {
      if (previous <= 0) return current > 0 ? 1 : 0;

      final result = (current - previous) / previous;

      if (result.isNaN || result.isInfinite) return 0;

      return result.clamp(-1.0, 1.0);
    } catch (_) {
      return 0;
    }
  }

  static bool isGrowing(int current, int previous) {
    return current >= previous;
  }

  static String formatMoney(int value) {
    try {
      if (value >= 1000000) {
        return "${(value / 1000000).toStringAsFixed(1)}M";
      }
      if (value >= 1000) {
        return "${(value / 1000).toStringAsFixed(1)}K";
      }
      return value.toString();
    } catch (_) {
      return "0";
    }
  }

  static void setCache(String key, dynamic value) {
    try {
      _cache[key] = value;
    } catch (_) {}
  }

  static dynamic getCache(String key) {
    try {
      return _cache[key];
    } catch (_) {
      return null;
    }
  }

  static void clearCache() {
    try {
      _cache.clear();
    } catch (_) {}
  }

  static int safe(Map<String, dynamic>? data, String key) {
    try {
      final value = data?[key];

      if (value == null) return 0;

      if (value is int) return value;

      if (value is double) {
        if (value.isNaN || value.isInfinite) return 0;
        return value.toInt();
      }

      if (value is String) {
        final parsed = int.tryParse(value);
        return parsed ?? 0;
      }

      return 0;
    } catch (_) {
      return 0;
    }
  }

  static double percent(int part, int total) {
    try {
      if (total <= 0) return 0;

      final result = part / total;

      if (result.isNaN || result.isInfinite) return 0;

      return result.clamp(0.0, 1.0);
    } catch (_) {
      return 0;
    }
  }

  static int avg(int total, int count) {
    try {
      if (count <= 0) return 0;

      final result = total / count;

      if (result.isNaN || result.isInfinite) return 0;

      return result.round();
    } catch (_) {
      return 0;
    }
  }

  static List<MapEntry<String, int>> safeMapList(dynamic value) {
    try {
      if (value is Map) {
        final map = <String, int>{};
        (value as Map).forEach((key, val) {
          map[key.toString()] = safe({'v': val}, 'v');
        });
        final list = map.entries.toList();
        list.sort((a, b) => b.value.compareTo(a.value));
        return list;
      }
      if (value is List) {
        final list = value.map<MapEntry<String, int>>((e) {
          if (e is Map) {
            final k = e['key']?.toString() ?? "";
            final v = safe(Map<String, dynamic>.from(e), 'value');
            return MapEntry(k, v);
          }
          return const MapEntry("", 0);
        }).toList();

        if (list.isEmpty) {
          return [];
        }

        return list;
      }
      return [];
    } catch (_) {
      return [];
    }
  }
}