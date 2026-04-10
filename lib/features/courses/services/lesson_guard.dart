class LessonTapGuard {
  static final Map<String, DateTime> _locks = {};

  static bool canTap(String key) {
    final now = DateTime.now();

    if (_locks.containsKey(key)) {
      if (now.difference(_locks[key]!).inMilliseconds < 800) {
        return false;
      }
    }

    _locks[key] = now;
    return true;
  }
}