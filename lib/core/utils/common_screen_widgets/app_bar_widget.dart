import 'package:flutter/material.dart';

class AppBarWidget extends StatelessWidget implements PreferredSizeWidget {
  const AppBarWidget({
    super.key,
    required this.actions,
    required this.appBarName,
    required this.onBackPressed,
  });

  final String appBarName;
  final List<Widget>? actions;
  final void Function()? onBackPressed;

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    const TextStyle style = TextStyle(fontSize: 25, color: Colors.black);
    const Icon icon = const Icon(Icons.arrow_back_rounded, size: 25);
    return AppBar(
      backgroundColor: Colors.white,
      automaticallyImplyLeading: false,
      leading: IconButton(onPressed: onBackPressed, icon: icon),
      iconTheme: const IconThemeData(color: Colors.black),
      centerTitle: true,
      toolbarHeight: AppBar().preferredSize.height,
      title: Text(appBarName, style: style),
      actions: actions,
    );
  }
}
