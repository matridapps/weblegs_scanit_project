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