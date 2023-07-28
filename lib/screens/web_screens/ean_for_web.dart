import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:absolute_app/core/utils/constants.dart';
import 'package:absolute_app/core/utils/responsive_check.dart';
import 'package:absolute_app/screens/web_screens/order_screen_web.dart';
import 'package:absolute_app/screens/web_screens/product_details_web.dart';
import 'package:absolute_app/screens/web_screens/scan_for_transfer_web.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class EANForWebApp extends StatefulWidget {
  const EANForWebApp(
      {Key? key,
      required this.screenType,
      required this.accType,
      required this.authorization,
      required this.refreshToken,
      required this.profileId,
      required this.distCenterId,
      required this.distCenterName,
      required this.crossVisible,
      required this.barcodeToCheck})
      : super(key: key);

  final String screenType;
  final String accType;
  final String authorization;
  final String refreshToken;
  final int profileId;
  final int distCenterId;
  final String distCenterName;
  final bool crossVisible;
  final int barcodeToCheck;

  @override
  State<EANForWebApp> createState() => _EANForWebAppState();
}

class _EANForWebAppState extends State<EANForWebApp> {
  bool _isEANFocused = false;
  late TextEditingController _eANController;

  @override
  void initState() {
    _eANController = TextEditingController();
    Timer.periodic(const Duration(milliseconds: 10), (Timer t) {
      if (_eANController.text.toString().isNotEmpty) {
        HapticFeedback.heavyImpact();
        t.cancel();
        checkForBarcodeValue();
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    FocusScopeNode currentFocus = FocusScope.of(context);
    return WillPopScope(
      onWillPop: widget.screenType == 'picklist details'
          ? () async {
              Navigator.pop(context, false);
              return false;
            }
          : () async {
              return true;
            },
      child: Scaffold(
        appBar: (MediaQuery.of(context).size.height > 1200 &&
                MediaQuery.of(context).size.width > 1920)
            ? AppBar(
                backgroundColor: Colors.white,
                automaticallyImplyLeading: true,
                iconTheme: const IconThemeData(color: Colors.black),
                centerTitle: true,
                toolbarHeight: 60,
                title: Image.asset(
                  'assets/logo/app_logo_with_space.jpg',
                  height: 60,
                  width: 200,
                ),
              )
            : AppBar(
                backgroundColor: Colors.white,
                automaticallyImplyLeading: true,
                iconTheme: const IconThemeData(color: Colors.black),
                centerTitle: true,
                toolbarHeight: size.height * .08,
                title: Image.asset(
                  'assets/logo/app_logo_with_space.jpg',
                  height: size.height * .05,
                  width: size.width * .4,
                ),
              ),
        body: GestureDetector(
          onTap: () {
            FocusScope.of(context).requestFocus(FocusNode());
            if (!currentFocus.hasPrimaryFocus) {
              currentFocus.unfocus();
            }
          },
          child: SizedBox(
              height: size.height,
              width: size.width,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  (MediaQuery.of(context).size.height > 1200 &&
                          MediaQuery.of(context).size.width > 1920)
                      ? Padding(
                          padding: const EdgeInsets.fromLTRB(80, 0, 80, 0),
                          child: Card(
                            elevation: 10,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: SizedBox(
                              height: 60,
                              width: 560,
                              child: Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: ThemeData().colorScheme.copyWith(
                                        primary: appColor,
                                      ),
                                ),
                                child: FocusScope(
                                  child: Focus(
                                    onFocusChange: (isFocused) {
                                      setState(() {
                                        _isEANFocused = isFocused;
                                        log('_isEANFocused - $_isEANFocused');
                                      });
                                    },
                                    child: TextFormField(
                                      autofocus: true,
                                      controller: _eANController,
                                      decoration: InputDecoration(
                                        filled: true,
                                        fillColor: _isEANFocused
                                            ? Colors.white
                                            : Colors.grey.shade100,
                                        prefixIcon: Image.asset(
                                          'assets/ean_for_web/barcode.png',
                                          height: 100,
                                          width: 100,
                                          color:
                                              _isEANFocused ? appColor : null,
                                        ),
                                        labelText: "Enter Barcode (EAN)",
                                        border: InputBorder.none,
                                        focusedBorder: OutlineInputBorder(
                                          borderSide: const BorderSide(
                                            color: appColor,
                                            width: 1,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        focusColor: appColor,
                                      ),
                                      validator: (value) {
                                        if (value!.isEmpty) {
                                          return "EAN cannot be empty";
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        )

                  /// >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

                      : Padding(
                          padding: EdgeInsets.fromLTRB(
                              size.width * .05, 0, size.width * .05, 0),
                          child: Card(
                            elevation: 10,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            child: SizedBox(
                              height: ResponsiveCheck.isLargeScreen(context)
                                  ? size.height * .075
                                  : ResponsiveCheck.isMediumScreen(context)
                                      ? size.height * .065
                                      : size.height * .055,
                              width: ResponsiveCheck.isSmallScreen(context)
                                  ? size.width * .35
                                  : size.width * .25,
                              child: Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: ThemeData().colorScheme.copyWith(
                                        primary: appColor,
                                      ),
                                ),
                                child: FocusScope(
                                  child: Focus(
                                    onFocusChange: (isFocused) {
                                      setState(() {
                                        _isEANFocused = isFocused;
                                        log('_isEANFocused - $_isEANFocused');
                                      });
                                    },
                                    child: TextFormField(
                                      autofocus: true,
                                      controller: _eANController,
                                      decoration: InputDecoration(
                                        filled: true,
                                        fillColor: _isEANFocused
                                            ? Colors.white
                                            : Colors.grey.shade100,
                                        prefixIcon: Image.asset(
                                          'assets/ean_for_web/barcode.png',
                                          height: size.width * .06,
                                          width: size.width * .06,
                                          color:
                                              _isEANFocused ? appColor : null,
                                        ),
                                        labelText: "Enter Barcode (EAN)",
                                        border: InputBorder.none,
                                        focusedBorder: OutlineInputBorder(
                                          borderSide: const BorderSide(
                                            color: appColor,
                                            width: 1,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        focusColor: appColor,
                                      ),
                                      validator: (value) {
                                        if (value!.isEmpty) {
                                          return "EAN cannot be empty";
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                  Visibility(
                    visible: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 30),
                      child: ElevatedButton(
                        onPressed: () async {
                          await checkAPI();
                        },
                        child: const Text('check'),
                      ),
                    ),
                  )
                ],
              )),
        ),
      ),
    );
  }

  Future<void> checkAPI() async {
    String uri = 'https://api.printnode.com/printjobs';
    var headers = {
      'Content-Type': 'application/json',
      'Authorization':
          'Basic VUJiZDBCY24wS3pZQmlsMGpVbHI4dnh6d29Nc1FTZ1BteDE3MERLaVVuVTo='
    };

    var body = {
      "printerId": 72321716,
      "title": "My Test PrintJob 6",
      "contentType": "pdf_uri",
      "content":
          "https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf",
      "source": "api documentation"
    };

    try {
      var response = await http
          .post(Uri.parse(uri), body: jsonEncode(body), headers: headers)
          .timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          return http.Response('Error', 408);
        },
      );

      if (response.statusCode == 200) {
        log('response >> ${jsonDecode(response.body)}');
      } else {
        log('status code >> ${response.statusCode}');
      }
    } catch (e) {
      log('exception in checkAPI >> ${e.toString()}');
    }
  }

  void checkForBarcodeValue() async {
    if (widget.screenType == 'product') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ProductDetailsWeb(
            ean: _eANController.text.toString(),
            location: '',
            accType: widget.accType,
            authorization: widget.authorization,
            refreshToken: widget.refreshToken,
            profileId: widget.profileId,
            distCenterId: widget.distCenterId,
            distCenterName: widget.distCenterName,
          ),
        ),
      );
    } else if (widget.screenType == 'jit order') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => OrderScreenWeb(
            ean: _eANController.text.toString(),
            isFiltered: true,
          ),
        ),
      );
    } else if (widget.screenType == 'transfer') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ScanForTransferWeb(
            accType: widget.accType,
            authorization: widget.authorization,
            refreshToken: widget.refreshToken,
            controllerText: _eANController.text.toString(),
            crossVisible: widget.crossVisible,
            profileId: widget.profileId,
          ),
        ),
      );
    } else if (widget.screenType == 'picklist details') {
      if (int.parse(_eANController.text.toString() == ""
              ? '0'
              : _eANController.text.toString()) ==
          widget.barcodeToCheck) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            duration: Duration(milliseconds: 600),
            content: Text('Barcode Matched!'),
            backgroundColor: Colors.green,
          ),
        );
        await Future.delayed(const Duration(seconds: 1), () {
          Navigator.pop(context, true);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            duration: Duration(milliseconds: 600),
            content: Text('Barcode Not Matched!'),
            backgroundColor: Colors.red,
          ),
        );
        await Future.delayed(const Duration(seconds: 1), () {
          Navigator.pop(context, false);
        });
      }
    }
  }
}
