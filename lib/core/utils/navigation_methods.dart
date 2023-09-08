import 'package:flutter/material.dart';

class NavigationMethods {
  static const beg = Offset(1.0, 0.0);
  static const end = Offset.zero;
  static const curv = Curves.ease;
  static var tween = Tween(begin: beg, end: end).chain(CurveTween(curve: curv));

  static Future<bool> pushWithResult(BuildContext ctx, Widget widget) async {
    return await Navigator.push(
      ctx,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => widget,
        transitionsBuilder: (context, animation, secondaryAnimation, _) {
          return SlideTransition(position: animation.drive(tween), child: _);
        },
      ),
    );
  }

  static Future<bool> pushRepWithResult(BuildContext ctx, Widget widget) async {
    return await Navigator.pushReplacement(
      ctx,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => widget,
        transitionsBuilder: (context, animation, secondaryAnimation, _) {
          return SlideTransition(position: animation.drive(tween), child: _);
        },
      ),
    );
  }

  static Future<Object?> push(BuildContext ctx, Widget widget) async {
    return await Navigator.push(
      ctx,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => widget,
        transitionsBuilder: (context, animation, secondaryAnimation, _) {
          return SlideTransition(position: animation.drive(tween), child: _);
        },
      ),
    );
  }

    static Future<Object?> pushReplacement(BuildContext ct, Widget widget) async {
    return await Navigator.pushReplacement(
      ct,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => widget,
        transitionsBuilder: (context, animation, secondaryAnimation, _) {
          return SlideTransition(position: animation.drive(tween), child: _);
        },
      ),
    );
  }
}
