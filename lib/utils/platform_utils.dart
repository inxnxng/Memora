import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;

class PlatformUtils {
  static bool get isIOS => defaultTargetPlatform == TargetPlatform.iOS;
  static bool get isMacOS => defaultTargetPlatform == TargetPlatform.macOS;
  static bool get isAndroid => defaultTargetPlatform == TargetPlatform.android;
  static bool get isWindows => defaultTargetPlatform == TargetPlatform.windows;
  static bool get isWeb => kIsWeb;

  static bool get isMobile => isAndroid || isIOS;
  static bool get isDesktop => kIsWeb || isMacOS || isWindows;
  static bool get isApple => isIOS || isMacOS;
}
