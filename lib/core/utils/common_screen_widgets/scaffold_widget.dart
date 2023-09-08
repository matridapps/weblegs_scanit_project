import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

class ScaffoldWidget extends StatelessWidget {
  const ScaffoldWidget({
    super.key,
    required this.scaffoldKey,
    required this.appBarWidget,
    required this.drawerWidget,
    required this.webBodyWidget,
    required this.mobileBodyWidget,
  });

  final Key? scaffoldKey;
  final PreferredSizeWidget? appBarWidget;
  final Widget? drawerWidget;
  final Widget? webBodyWidget;
  final Widget? mobileBodyWidget;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: Colors.grey[100],
      resizeToAvoidBottomInset: true,
      appBar: appBarWidget,
      drawer: drawerWidget,
      body: kIsWeb ? webBodyWidget : mobileBodyWidget,
    );
  }
}
