import 'package:flutter/material.dart';
final Size size = MediaQueryData.fromView(WidgetsBinding.instance.window).size;


double get w=> size.width;
double get h=> size.height;