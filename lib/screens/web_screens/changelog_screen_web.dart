import 'dart:developer';

import 'package:absolute_app/core/apis/api_calls.dart';
import 'package:absolute_app/core/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:parse_server_sdk/parse_server_sdk.dart';
import 'package:universal_html/html.dart' as html;

class ChangelogScreenWeb extends StatefulWidget {
  const ChangelogScreenWeb({super.key});

  @override
  State<ChangelogScreenWeb> createState() => _ChangelogScreenWebState();
}

class _ChangelogScreenWebState extends State<ChangelogScreenWeb> {
  List<ParseObject> changelogData = [];
  List<String> pdfNamesList = [];
  List<String> pdfLinksList = [];

  bool isLoading = false;
  bool isError = false;

  String error = '';

  @override
  void initState() {
    super.initState();
    changelogApis();
  }

  void changelogApis() async {
    setState(() {
      isLoading = true;
      isError = false;
      error = '';
    });
    await getChangelogData().whenComplete(() {
      setState(() {
        isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.white,
        automaticallyImplyLeading: true,
        iconTheme: const IconThemeData(color: Colors.black),
        centerTitle: true,
        toolbarHeight: AppBar().preferredSize.height,
        elevation: 5,
        title: const Text(
          'Changelog',
          style: TextStyle(
            fontSize: 25,
            color: Colors.black,
          ),
        ),
      ),
      body: isLoading == true
          ? SizedBox(
        height: size.height,
        width: size.width,
        child: const Center(
          child: CircularProgressIndicator(
            color: appColor,
          ),
        ),
      )
          : isError == true
          ? SizedBox(
        height: size.height,
        width: size.width,
        child: Center(
          child: Text(
            error,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      )
          : SizedBox(
        height: size.height,
        width: size.width,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 50,
            vertical: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                ..._changelogListMaker(size),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _changelogListMaker(Size size) {
    return List.generate(changelogData.length, (index) {
      return GestureDetector(
        onTap: () => downloadFile(pdfLinksList[index]),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 15),
          child: Text(
            pdfNamesList[index],
            style: const TextStyle(
              fontSize: 18,
              color: Colors.blue,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      );
    });
  }

  void downloadFile(String url) {
    html.AnchorElement anchorElement = html.AnchorElement(href: url);
    anchorElement.download = url;
    anchorElement.click();
  }

  Future<void> getChangelogData() async {
    await ApiCalls.getChangelogData().then((data) {
      if (data.isEmpty) {
        setState(() {
          isError = true;
          error = 'Error in fetching Changelog Data. Please try again!';
        });
      } else {
        changelogData = [];
        changelogData.addAll(data.map((e) => e));
        log('V changelogData >>---> $changelogData');

        pdfNamesList = [];
        pdfNamesList
            .addAll(changelogData.map((e) => e.get<String>('pdf_name') ?? ''));
        log('V pdfNamesList >>---> $pdfNamesList');

        pdfLinksList = [];
        pdfLinksList
            .addAll(changelogData.map((e) => e.get<String>('pdf_links') ?? ''));
        log('V pdfLinksList >>---> $pdfLinksList');
      }
    });
  }
}