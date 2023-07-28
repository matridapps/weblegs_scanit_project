import 'package:flutter/material.dart';

class ResponsiveCheck {
  ResponsiveCheck._();

  static bool isSmallScreen(BuildContext context) {
    return MediaQuery.of(context).size.width < 800;
  }

  static bool isLargeScreen(BuildContext context) {
    return MediaQuery.of(context).size.width > 1200;
  }

  static bool isMediumScreen(BuildContext context) {
    return MediaQuery.of(context).size.width >= 800 &&
        MediaQuery.of(context).size.width <= 1200;
  }

  static bool screenBiggerThan24inch(BuildContext context) {
    return MediaQuery.of(context).size.height > 1200 &&
        MediaQuery.of(context).size.width > 1920;
  }
}
