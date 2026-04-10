class NavGuard {
  static bool navigating = false;

  static void go(Function action) {
    if (navigating) return;
    navigating = true;

    action();

    Future.delayed(const Duration(milliseconds: 400), () {
      navigating = false;
    });
  }
}