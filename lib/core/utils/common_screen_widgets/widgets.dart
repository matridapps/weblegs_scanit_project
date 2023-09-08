import 'package:absolute_app/core/utils/constants.dart';
import 'package:absolute_app/core/utils/toast_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

Widget verticalSpacer(BuildContext context, double height) {
  return SizedBox(
    height: height,
    width: MediaQuery.of(context).size.width,
  );
}

int parseToInt(String str) {
  return str.isEmpty ? 0 : int.parse(str);
}

Widget loader() {
  return const Center(
    child: CircularProgressIndicator(
      color: appColor,
    ),
  );
}

dynamic commonToastCentered({
  required String msg,
  required BuildContext context,
}) {
  return kIsWeb
      ? ToastUtils.motionToastCentered(message: msg, context: context)
      : ToastUtils.showCenteredLongToast(message: msg);
}

Size calcTextSize(String text, BuildContext context) {
  final TextPainter textPainter = TextPainter(
    text: TextSpan(text: text),
    textDirection: TextDirection.ltr,
    textScaleFactor: MediaQuery.of(context).textScaleFactor,
  )..layout();
  return textPainter.size;
}


