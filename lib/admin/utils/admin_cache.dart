class AdminCache {
  static Map<String, dynamic>? stats;
  static bool loading = false;

  static void clear() {
    stats = null;
    loading = false;
  }
}