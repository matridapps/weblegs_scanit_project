import 'dart:developer';

import 'package:flutter/material.dart';

class SelectorForPackAndScan extends StatefulWidget {
  const SelectorForPackAndScan({super.key});

  @override
  State<SelectorForPackAndScan> createState() => _SelectorForPackAndScanState();
}

class _SelectorForPackAndScanState extends State<SelectorForPackAndScan> {
  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      // appBar: AppBar(
      //   backgroundColor: Colors.white,
      //   elevation: 5,
      //   automaticallyImplyLeading: true,
      //   toolbarHeight: AppBar().preferredSize.height,
      //   centerTitle: true,
      //   title: Text(
      //     'Choose',
      //     style: TextStyle(
      //       color: Colors.black,
      //       fontSize: size.width * .06,
      //     ),
      //   ),
      // ),
      body: Center(
        child: SizedBox(
          height: 40,
          width: 100,
          child: ElevatedButton(
            onPressed: () {
              log('height >> ${MediaQuery.of(context).size.height}');
              log('width >> ${MediaQuery.of(context).size.width}');
              log('status bar height >> ${MediaQuery.of(context).viewPadding.top}');
              log('device Pixel ratio >> ${MediaQuery.of(context).devicePixelRatio}');
              log('bottom height >> ${MediaQuery.of(context).viewPadding.bottom}');
            },
            child: const Text("check"),
          ),
        ),
      ),
    );
  }
}
