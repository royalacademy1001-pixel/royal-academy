class VideoGuard {
  static bool saving = false;
  static int lastSave = 0;

  static bool canSave(int sec) {
    if (saving) return false;
    if ((sec - lastSave).abs() < 10) return false;

    lastSave = sec;
    return true;
  }
}