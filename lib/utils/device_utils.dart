import 'package:flutter/material.dart';

class DeviceUtils {
  static void hideKeyboard(BuildContext context) {
    FocusScope.of(context).unfocus();
  }

  static bool isIOS(BuildContext context) {
    return Theme.of(context).platform == TargetPlatform.iOS;
  }

  static bool isAndroid(BuildContext context) {
    return Theme.of(context).platform == TargetPlatform.android;
  }
}
