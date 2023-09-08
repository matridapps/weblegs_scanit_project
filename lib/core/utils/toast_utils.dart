import 'package:absolute_app/core/utils/common_screen_widgets/widgets.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/material.dart';
import 'package:motion_toast/motion_toast.dart';
import 'package:motion_toast/resources/arrays.dart';

class ToastUtils {
  ToastUtils._();

  static showShortToast({required String message}) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
    );
  }

  static showCenteredShortToast({required String message}) {
    Fluttertoast.showToast(
      msg: message,
      gravity: ToastGravity.CENTER,
      toastLength: Toast.LENGTH_SHORT,
    );
  }

  static showLongToast({required String message}) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
    );
  }

  static showCenteredLongToast({required String message}) {
    Fluttertoast.showToast(
      msg: message,
      gravity: ToastGravity.CENTER,
      toastLength: Toast.LENGTH_LONG,
    );
  }

  static motionToastBottom({
    required String message,
    required BuildContext context,
  }) {
    MotionToast(
      primaryColor: Colors.grey.shade900,
      backgroundType: BackgroundType.solid,
      description: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
      ),
      toastDuration: const Duration(milliseconds: 1500),
      displayBorder: false,
      displaySideBar: false,
      position: MotionToastPosition.bottom,
    ).show(context);
  }

  static motionToastCentered({
    required String message,
    required BuildContext context,
  }) {
    MotionToast(
      primaryColor: Colors.grey.shade900,
      backgroundType: BackgroundType.solid,
      description: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
      ),
      displayBorder: false,
      displaySideBar: false,
      position: MotionToastPosition.center,
    ).show(context);
  }

  static motionToastCentered1500MS({
    required String message,
    required BuildContext context,
  }) {
    MotionToast(
      height: 40,
      width: calcTextSize(message, context).width + 40,
      primaryColor: Colors.grey.shade900,
      backgroundType: BackgroundType.solid,
      toastDuration: const Duration(milliseconds: 1500),
      description: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(message, style: const TextStyle(color: Colors.white)),
        ],
      ),
      displayBorder: false,
      displaySideBar: false,
      position: MotionToastPosition.center,
    ).show(context);
  }

  static motionToastCentered800MS({
    required String message,
    required BuildContext context,
  }) {
    MotionToast(
      primaryColor: Colors.grey.shade900,
      backgroundType: BackgroundType.solid,
      toastDuration: const Duration(milliseconds: 1500),
      description: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          message,
          style: const TextStyle(color: Colors.white),
          textAlign: TextAlign.center,
        ),
      ),
      displayBorder: false,
      displaySideBar: false,
      position: MotionToastPosition.center,
    ).show(context);
  }
}
