import 'package:flutter/material.dart';

class PageRefreshController {
  static final ValueNotifier<bool> refreshNotifier = ValueNotifier(false);
  static VoidCallback? onRefresh;
  static bool initialLoadCompleted = false;

  static void triggerRefresh() {
    refreshNotifier.value = !refreshNotifier.value;
  }
}
