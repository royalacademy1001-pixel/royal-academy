class CacheManager {
  static final Map<String, DateTime> _times = {};

  static bool isValid(String key, int seconds) {
    if (!_times.containsKey(key)) return false;

    return DateTime.now()
            .difference(_times[key]!)
            .inSeconds <
        seconds;
  }

  static void set(String key) {
    _times[key] = DateTime.now();
  }

  static void clear() {
    _times.clear();
  }

  static void remove(String key) {
    _times.remove(key);
  }
}
