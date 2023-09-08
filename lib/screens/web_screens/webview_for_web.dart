import 'dart:developer';

import 'package:absolute_app/core/utils/constants.dart';
import 'package:flutter/material.dart' as m;
import 'package:url_launcher/url_launcher.dart';
import 'package:absolute_app/core/utils/platform_view_directory/html_element_view.dart' as web;

class WebviewForWeb extends m.StatefulWidget {
  const WebviewForWeb({super.key});

  @override
  m.State<WebviewForWeb> createState() => _WebviewForWebState();
}

class _WebviewForWebState extends m.State<WebviewForWeb> {
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loading();
  }

  void _loading() async {
    setState(() {
      isLoading = true;
    });
    await Future.delayed(const Duration(seconds: 3), () {
      setState(() {
        isLoading = false;
      });
    });
  }

  @override
  m.Widget build(m.BuildContext context) {
    final m.Size size = m.MediaQuery.of(context).size;
    m.Color backgroundColor = const m.Color.fromARGB(255, 244, 244, 245);
    return m.Scaffold(
      backgroundColor: backgroundColor,
      appBar: m.AppBar(
        backgroundColor: m.Colors.white,
        automaticallyImplyLeading: true,
        iconTheme: const m.IconThemeData(color: m.Colors.black),
        centerTitle: true,
        toolbarHeight: m.AppBar().preferredSize.height,
        elevation: 5,
        title: const m.Text(
          'Changelog',
          style: m.TextStyle(fontSize: 25, color: m.Colors.black),
        ),
        actions: [
          m.IconButton(
            onPressed: () async {
              await _launchUrl('https://weblegs-scanit.changelogfy.com/');
            },
            icon: const m.Icon(m.Icons.open_in_new_rounded),
            tooltip: 'Open in new tab for Changelogfy sign in options',
          )
        ],
      ),
      body: m.SingleChildScrollView(
        child: m.Column(
          mainAxisAlignment: m.MainAxisAlignment.start,
          crossAxisAlignment: m.CrossAxisAlignment.center,
          children: [
            m.SizedBox(
              height: size.height * .03,
              width: size.width,
              child: m.Row(
                mainAxisAlignment: m.MainAxisAlignment.center,
                children: [
                  const m.Text(
                    '* For signing in to Changelogfy,',
                    style: m.TextStyle(fontSize: 14),
                  ),
                  m.TextButton(
                    onPressed: () async {
                      await _launchUrl(
                        'https://weblegs-scanit.changelogfy.com/',
                      );
                    },
                    child: const m.Text(
                      'Open in new tab',
                      style: m.TextStyle(
                        fontSize: 14,
                        color: m.Colors.lightBlue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            m.SizedBox(
              width: size.width,
              height: size.height * .9,
              child: isLoading == true
                  ? const m.Center(
                      child: m.CircularProgressIndicator(color: appColor),
                    )
                  : const web.HtmlElementView(viewType: 'iframeElement'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    try {
      await launchUrl(Uri.parse(url));
    } catch (e) {
      /// Exception in launching the changelogfy personal app dashboard.
      log('Exception in Launching >>>>> ${e.toString()}');
    }
  }
}
