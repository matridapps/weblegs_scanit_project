import 'dart:convert';
import 'dart:developer';

import 'package:absolute_app/core/apis/api_calls.dart';
import 'package:absolute_app/core/utils/constants.dart';
import 'package:absolute_app/core/utils/navigation_methods.dart';
import 'package:absolute_app/core/utils/responsive_check.dart';
import 'package:absolute_app/core/utils/toast_utils.dart';
import 'package:absolute_app/screens/mobile_device_screens/barcode_camera_screen.dart';
import 'package:absolute_app/screens/mobile_device_screens/pre_order_screen.dart';
import 'package:absolute_app/screens/mobile_device_screens/settings_screen.dart';
import 'package:absolute_app/screens/web_screens/ean_for_web.dart';
import 'package:absolute_app/screens/login_screen.dart';
import 'package:absolute_app/screens/pick_list/pick_list.dart';
import 'package:absolute_app/screens/web_screens/pack_and_scan_web_new.dart';
import 'package:absolute_app/screens/web_screens/pre_order_screen_web.dart';
import 'package:absolute_app/screens/web_screens/print_node_settings_web.dart';
import 'package:absolute_app/screens/web_screens/settings_screen_web.dart';
import 'package:absolute_app/screens/web_screens/shipment_rules_screen.dart';
import 'package:absolute_app/screens/web_screens/shop_replenish_screen_web.dart';
import 'package:absolute_app/screens/web_screens/webview_for_web.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:parse_server_sdk/parse_server_sdk.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:universal_html/html.dart' as html;

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    Key? key,
    required this.accType,
    required this.authorization,
    required this.refreshToken,
    required this.userId,
    required this.profileId,
    required this.distCenterId,
    required this.distCenterName,
  }) : super(key: key);

  final String accType;
  final String authorization;
  final String refreshToken;
  final String userId;
  final int profileId;
  final int distCenterId;
  final String distCenterName;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  List<bool> isTapped = [
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false
  ];
  List<ParseObject> printNodeData = [];

  bool isFirstTimeScanCamera = true;
  bool crossVisible = false;
  bool isLoggingOut = false;
  bool isCreatingManifest = false;
  bool isManifestSuccessful = false;
  bool isError = false;
  bool isLoading = false;
  bool isDCSplitAutomatic = false;

  String error = '';
  String scanBarcodeResult = '';
  String controllerText = '';
  String apiKey = '';
  String webAppLastUpdatedLocal = 'Last Updated at 05 September, 2023 11:47 AM';
  String webAppLastUpdated = '';
  String manifestUrl = '';

  String selectedPrinter = '';
  int selectedPrinterId = 0;

  LinearGradient linearGradient1 = const LinearGradient(
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
    stops: [0.1, 0.4, 0.6, 0.9],
    colors: [
      Color.fromARGB(255, 178, 62, 3),
      Color.fromARGB(255, 181, 63, 3),
      Color.fromARGB(255, 194, 82, 3),
      Color.fromARGB(255, 221, 118, 3),
    ],
  );

  LinearGradient linearGradient2 = const LinearGradient(
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
    stops: [0.5],
    colors: [Colors.white],
  );

  @override
  void initState() {
    super.initState();
    homeInitApiCalls();
  }

  void homeInitApiCalls() async {
    setState(() {
      isLoading = true;
      isError = false;
    });
    await getPrintNodeData().whenComplete(() async {
      await getEasyPostLiveOrTestValue().then((value) async {
        await saveEasyPostLiveOrTestValue(value);
      }).whenComplete(() async {
        await SharedPreferences.getInstance().then((prefs) {
          log('Easy Post Test or Live >>---> ${prefs.getString('EasyPostTestOrLive')}');
        });
      });
    }).whenComplete(() {
      setState(() {
        isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return WillPopScope(
      onWillPop: kIsWeb == true
          ? () async {
              return true;
            }
          : showExitPopupMobile,
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: Colors.grey[100],
        resizeToAvoidBottomInset: true,
        appBar: kIsWeb == true
            ? _webAppBarBuilder(context, size)
            : _mobileAppBarBuilder(context, size),
        drawer: SafeArea(
          child: kIsWeb == true
              ? _webDrawerBuilder(context, size)
              : _mobileDrawerBuilder(context, size),
        ),
        body: isLoading == true
            ? SizedBox(
                height: size.height,
                width: size.width,
                child: const Center(
                  child: CircularProgressIndicator(color: appColor),
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
                : kIsWeb == true
                    ? ResponsiveCheck.screenBiggerThan24inch(context) == true
                        ? _screenBiggerThan24InchBuilder(context, size)
                        : _screenSmallerThan24InchBuilder(context, size)
                    : _mobileScreenBuilder(context, size),
      ),
    );
  }

  /// BUILDER METHODS

  PreferredSizeWidget? _webAppBarBuilder(BuildContext context, Size size) {
    return AppBar(
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
    );
  }

  PreferredSizeWidget? _mobileAppBarBuilder(BuildContext context, Size size) {
    return AppBar(
      backgroundColor: Colors.white,
      automaticallyImplyLeading: true,
      iconTheme: const IconThemeData(color: Colors.black),
      centerTitle: true,
      toolbarHeight: size.height * .085,
      title: Image.asset(
        'assets/logo/app_logo_with_space.jpg',
        height: size.height * .085,
        width: size.width * .5,
      ),
    );
  }

  Widget _webDrawerBuilder(BuildContext context, Size size) {
    return Drawer(
      width: 350,
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              height: 60,
              width: 350,
              color: appColor,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 30, right: 20),
                    child: Image.asset(
                      'assets/home_screen_assets/single_color/account_01.png',
                      height: 25,
                      width: 25,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Hello, ${widget.userId}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 20, left: 20, right: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Theme(
                    data: Theme.of(context).copyWith(
                      dividerColor: Colors.transparent,
                    ),
                    child: ExpansionTile(
                      textColor: appColor,
                      collapsedTextColor: Colors.black,
                      iconColor: appColor,
                      collapsedIconColor: Colors.black,
                      leading: const Icon(Icons.settings),
                      trailing: const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 15,
                      ),
                      title: const Text(
                        'Settings',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onExpansionChanged: (_) async {
                        scaffoldKey.currentState?.openEndDrawer();
                        await NavigationMethods.push(
                          context,
                          SettingsScreenWeb(userId: widget.userId),
                        );
                      },
                    ),
                  ),
                  Theme(
                    data: Theme.of(context).copyWith(
                      dividerColor: Colors.transparent,
                    ),
                    child: ExpansionTile(
                      textColor: appColor,
                      collapsedTextColor: Colors.black,
                      iconColor: appColor,
                      collapsedIconColor: Colors.black,
                      leading: const Icon(Icons.print),
                      trailing: const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 15,
                      ),
                      title: const Text(
                        'PrintNode Settings',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onExpansionChanged: (_) async {
                        scaffoldKey.currentState?.openEndDrawer();
                        await NavigationMethods.push(
                          context,
                          PrintNodeSettingsWeb(userId: widget.userId),
                        );
                      },
                    ),
                  ),
                  Theme(
                    data: Theme.of(context).copyWith(
                      dividerColor: Colors.transparent,
                    ),
                    child: ExpansionTile(
                      textColor: appColor,
                      collapsedTextColor: Colors.black,
                      iconColor: appColor,
                      collapsedIconColor: Colors.black,
                      leading:
                          const Icon(Icons.published_with_changes_outlined),
                      trailing: const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 15,
                      ),
                      title: const Text(
                        'Changelog',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onExpansionChanged: (_) async {
                        scaffoldKey.currentState?.openEndDrawer();
                        await NavigationMethods.push(
                          context,
                          const WebviewForWeb(),
                        );
                      },
                    ),
                  ),
                  Theme(
                    data: Theme.of(context).copyWith(
                      dividerColor: Colors.transparent,
                    ),
                    child: ExpansionTile(
                      textColor: appColor,
                      collapsedTextColor: Colors.black,
                      iconColor: appColor,
                      collapsedIconColor: Colors.black,
                      leading: SizedBox(
                        height: 30,
                        width: 30,
                        child: Image.asset(
                          'assets/home_screen_assets/single_color/manifest.png',
                        ),
                      ),
                      title: const Text(
                        'Manifest',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      children: [
                        GestureDetector(
                          onTap: () async {
                            setState(() {
                              isCreatingManifest = true;
                            });
                            await getPrintNodeData().whenComplete(() async {
                              await SharedPreferences.getInstance().then((prefs) async {
                                bool isTest = true;
                                setState(() {
                                  selectedPrinter = prefs.getString('selectedPrinter') == 'null'
                                      ? ''
                                      : prefs.getString('selectedPrinter') ?? '';
                                  selectedPrinterId = prefs.getInt('selectedPrinterId') ?? 0;
                                  isTest = (prefs.getString('EasyPostTestOrLive') ?? 'Test') == 'Test';
                                });
                                if(selectedPrinter.isEmpty) {
                                  ToastUtils.motionToastCentered1500MS(message: 'No Printer Selected! Please Select from PrintNode Settings', context: context);
                                } else {
                                  await createManifest(isTest).whenComplete(() async {
                                    if(isManifestSuccessful && manifestUrl.isNotEmpty) {
                                      await sendPrintJobForManifest(
                                        apiKey: apiKey,
                                        printerId: selectedPrinterId,
                                        printerName: selectedPrinter,
                                        manifestPdfUrl: manifestUrl,
                                      );
                                    }
                                  });
                                }
                              });
                            });
                          },
                          child: ListTile(
                            leading: const MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: Icon(Icons.create),
                            ),
                            title: const MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Text(
                                    'Create Manifest',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            trailing: isCreatingManifest == true
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      color: appColor,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const MouseRegion(
                                    cursor: SystemMouseCursors.click,
                                    child: Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      size: 15,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Theme(
                    data: Theme.of(context).copyWith(
                      dividerColor: Colors.transparent,
                    ),
                    child: ExpansionTile(
                      textColor: appColor,
                      collapsedTextColor: Colors.black,
                      iconColor: appColor,
                      collapsedIconColor: Colors.black,
                      leading: const Icon(Icons.person),
                      title: const Text(
                        'Account',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      children: [
                        GestureDetector(
                          onTap: () async => await logout(),
                          child: ListTile(
                            leading: const MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: Icon(Icons.logout_outlined),
                            ),
                            title: const MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Text(
                                    'Log Out',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            trailing: isLoggingOut == true
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      color: appColor,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const MouseRegion(
                                    cursor: SystemMouseCursors.click,
                                    child: Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      size: 15,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(top: 50),
                    child: Divider(),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      webAppLastUpdatedLocal,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      webAppLastUpdated == webAppLastUpdatedLocal
                          ? '* The Current Web App is the latest.'
                          : '* The Current Web App is not the latest.\n   Please Reload the Web App.',
                      overflow: TextOverflow.visible,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mobileDrawerBuilder(BuildContext context, Size size) {
    return Drawer(
      width: size.width * .8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            height: size.height * .08,
            width: size.width * .8,
            color: appColor,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 30, right: 20),
                  child: Image.asset(
                    'assets/home_screen_assets/single_color/account_01.png',
                    height: 25,
                    width: 25,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Hello, ${widget.userId}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: size.width * .06,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(5),
            child: Column(
              children: [
                Theme(
                  data: Theme.of(context).copyWith(
                    dividerColor: Colors.transparent,
                  ),
                  child: ExpansionTile(
                    textColor: appColor,
                    collapsedTextColor: Colors.black,
                    iconColor: appColor,
                    collapsedIconColor: Colors.black,
                    leading: Icon(Icons.settings, size: size.width * .06),
                    trailing: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: size.width * .055,
                    ),
                    title: Text(
                      'Settings',
                      style: TextStyle(
                        fontSize: size.width * .06,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onExpansionChanged: (_) async {
                      scaffoldKey.currentState?.openEndDrawer();
                      await NavigationMethods.push(
                        context,
                        SettingsScreen(userId: widget.userId),
                      );
                    },
                  ),
                ),
                Theme(
                  data: Theme.of(context).copyWith(
                    dividerColor: Colors.transparent,
                  ),
                  child: ExpansionTile(
                    textColor: appColor,
                    collapsedTextColor: Colors.black,
                    iconColor: appColor,
                    collapsedIconColor: Colors.black,
                    leading: Icon(Icons.person, size: size.width * .06),
                    title: Text(
                      'Account',
                      style: TextStyle(
                        fontSize: size.width * .06,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    children: [
                      GestureDetector(
                        onTap: () async => await logout(),
                        child: ListTile(
                          leading: Icon(
                            Icons.logout_outlined,
                            size: size.width * .05,
                          ),
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text(
                                'Log Out',
                                style: TextStyle(
                                  fontSize: size.width * .05,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                          trailing: isLoggingOut == true
                              ? SizedBox(
                                  height: size.width * .055,
                                  width: size.width * .055,
                                  child: const CircularProgressIndicator(
                                    color: appColor,
                                  ),
                                )
                              : Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: size.width * .05,
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _screenBiggerThan24InchBuilder(BuildContext context, Size size) {
    return SingleChildScrollView(
      child: SizedBox(
        height: size.height,
        width: size.width,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () async {
                    setState(() {
                      isTapped = [
                        true,
                        false,
                        false,
                        false,
                        false,
                        false,
                        false,
                        false
                      ];
                    });
                    await Future.delayed(const Duration(milliseconds: 400),
                        () async {
                      await NavigationMethods.push(
                        context,
                        EANForWebApp(
                          screenType: 'product',
                          accType: widget.accType,
                          authorization: widget.authorization,
                          refreshToken: widget.refreshToken,
                          profileId: widget.profileId,
                          distCenterId: widget.distCenterId,
                          distCenterName: widget.distCenterName,
                          crossVisible: crossVisible,
                          barcodeToCheck: 0,
                        ),
                      );
                    });
                  },
                  child: Card(
                    elevation: isTapped[0] ? 20 : 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Container(
                      height: 300,
                      width: 300,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: isTapped[0] == true
                            ? linearGradient1
                            : linearGradient2,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(
                            height: 200,
                            width: 200,
                            child: Image.asset(
                              isTapped[0] == true
                                  ? 'assets/home_screen_assets/multi_color/products_02.png'
                                  : 'assets/home_screen_assets/multi_color/products_01.png',
                            ),
                          ),
                          Text(
                            'Product',
                            style: TextStyle(
                              color: isTapped[0] == true
                                  ? Colors.white
                                  : Colors.black,
                              fontSize: 20,
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
                Visibility(
                  visible: widget.accType == 'Jadlam',
                  child: Padding(
                    padding: const EdgeInsets.only(left: 100),
                    child: GestureDetector(
                      onTap: () async {
                        setState(() {
                          isTapped = [
                            false,
                            true,
                            false,
                            false,
                            false,
                            false,
                            false,
                            false
                          ];
                        });
                        await getPrintNodeData().whenComplete(() async {
                          await NavigationMethods.push(
                            context,
                            PackAndScanWebNew(apiKey: apiKey),
                          );
                        });
                      },
                      child: Card(
                        elevation: isTapped[1] ? 20 : 5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Container(
                          height: 300,
                          width: 300,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: isTapped[1] == true
                                ? linearGradient1
                                : linearGradient2,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SizedBox(
                                height: 200,
                                width: 200,
                                child: Image.asset(
                                  'assets/home_screen_assets/single_color/pack_and_scan_01.png',
                                  color: isTapped[1] == true
                                      ? Colors.white
                                      : appColor,
                                ),
                              ),
                              Text(
                                'Pack & Scan',
                                style: TextStyle(
                                  color: isTapped[1] == true
                                      ? Colors.white
                                      : Colors.black,
                                  fontSize: 20,
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Visibility(
                  visible: widget.accType == 'Jadlam',
                  child: Padding(
                    padding: const EdgeInsets.only(left: 100),
                    child: GestureDetector(
                      onTap: () async {
                        setState(() {
                          isTapped = [
                            false,
                            false,
                            true,
                            false,
                            false,
                            false,
                            false,
                            false
                          ];
                        });
                        await Future.delayed(const Duration(milliseconds: 400),
                            () async {
                          await NavigationMethods.push(
                            context,
                            EANForWebApp(
                              screenType: 'jit order',
                              accType: widget.accType,
                              authorization: widget.authorization,
                              refreshToken: widget.refreshToken,
                              profileId: widget.profileId,
                              distCenterId: widget.distCenterId,
                              distCenterName: widget.distCenterName,
                              crossVisible: crossVisible,
                              barcodeToCheck: 0,
                            ),
                          );
                        });
                      },
                      child: Card(
                        elevation: isTapped[2] ? 20 : 5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Container(
                          height: 300,
                          width: 300,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: isTapped[2] == true
                                ? linearGradient1
                                : linearGradient2,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SizedBox(
                                height: 200,
                                width: 200,
                                child: Image.asset(
                                  isTapped[2] == true
                                      ? 'assets/home_screen_assets/multi_color/jit_orders_02.png'
                                      : 'assets/home_screen_assets/multi_color/jit_orders_01.png',
                                ),
                              ),
                              Text(
                                'JIT Orders',
                                style: TextStyle(
                                  color: isTapped[2] == true
                                      ? Colors.white
                                      : Colors.black,
                                  fontSize: 20,
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Visibility(
                  visible: widget.accType == 'Jadlam',
                  child: Padding(
                    padding: const EdgeInsets.only(left: 100),
                    child: GestureDetector(
                      onTap: () async {
                        setState(() {
                          isTapped = [
                            false,
                            false,
                            false,
                            true,
                            false,
                            false,
                            false,
                            false
                          ];
                        });
                        await Future.delayed(const Duration(milliseconds: 400),
                            () async {
                          await NavigationMethods.push(
                            context,
                            EANForWebApp(
                              screenType: 'transfer',
                              accType: widget.accType,
                              authorization: widget.authorization,
                              refreshToken: widget.refreshToken,
                              profileId: widget.profileId,
                              distCenterId: widget.distCenterId,
                              distCenterName: widget.distCenterName,
                              crossVisible: crossVisible,
                              barcodeToCheck: 0,
                            ),
                          );
                        });
                      },
                      child: Card(
                        elevation: isTapped[3] ? 20 : 5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Container(
                          height: 300,
                          width: 300,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: isTapped[3] == true
                                ? linearGradient1
                                : linearGradient2,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SizedBox(
                                height: 200,
                                width: 200,
                                child: Image.asset(
                                  isTapped[3] == true
                                      ? 'assets/home_screen_assets/multi_color/stock_transfer_02.png'
                                      : 'assets/home_screen_assets/multi_color/stock_transfer_01.png',
                                ),
                              ),
                              Text(
                                'Stock Transfer',
                                style: TextStyle(
                                  color: isTapped[3] == true
                                      ? Colors.white
                                      : Colors.black,
                                  fontSize: 20,
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Visibility(
              visible: widget.accType == 'Jadlam',
              child: Padding(
                padding: const EdgeInsets.only(top: 100),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        setState(() {
                          isTapped = [
                            false,
                            false,
                            false,
                            false,
                            true,
                            false,
                            false,
                            false
                          ];
                        });
                        await Future.delayed(const Duration(milliseconds: 400),
                            () async {
                          await NavigationMethods.push(
                            context,
                            const ShipmentRulesScreen(),
                          );
                        });
                      },
                      child: Card(
                        elevation: isTapped[4] ? 20 : 5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Container(
                          height: 300,
                          width: 300,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: isTapped[4] == true
                                ? linearGradient1
                                : linearGradient2,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SizedBox(
                                height: 200,
                                width: 200,
                                child: Image.asset(
                                  isTapped[4] == true
                                      ? 'assets/home_screen_assets/multi_color/shipping_rules_02.png'
                                      : 'assets/home_screen_assets/multi_color/shipping_rules_01.png',
                                  color: isTapped[4] == true
                                      ? Colors.white
                                      : appColor,
                                ),
                              ),
                              Text(
                                'Shipping Rules',
                                style: TextStyle(
                                  color: isTapped[4] == true
                                      ? Colors.white
                                      : Colors.black,
                                  fontSize: 20,
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 100),
                      child: GestureDetector(
                        onTap: () async {
                          setState(() {
                            isTapped = [
                              false,
                              false,
                              false,
                              false,
                              false,
                              true,
                              false,
                              false
                            ];
                          });
                          await getPrintNodeData().whenComplete(() async {
                            await NavigationMethods.push(
                              context,
                              PickLists(
                                accType: widget.accType,
                                authorization: widget.authorization,
                                refreshToken: widget.refreshToken,
                                profileId: widget.profileId,
                                distCenterId: widget.distCenterId,
                                distCenterName: widget.distCenterName,
                                userName: widget.userId,
                                isDCSplitAutomatic: isDCSplitAutomatic,
                              ),
                            );
                          });
                        },
                        child: Card(
                          elevation: isTapped[5] ? 20 : 5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Container(
                            height: 300,
                            width: 300,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              gradient: isTapped[5] == true
                                  ? linearGradient1
                                  : linearGradient2,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                SizedBox(
                                  height: 200,
                                  width: 200,
                                  child: Image.asset(
                                    isTapped[5] == true
                                        ? 'assets/home_screen_assets/single_color/picklist_01.png'
                                        : 'assets/home_screen_assets/single_color/picklist_01.png',
                                    color: isTapped[5] == true
                                        ? Colors.white
                                        : appColor,
                                  ),
                                ),
                                Text(
                                  'Picklist',
                                  style: TextStyle(
                                    color: isTapped[5] == true
                                        ? Colors.white
                                        : Colors.black,
                                    fontSize: 20,
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 100),
                      child: GestureDetector(
                        onTap: () async {
                          setState(() {
                            isTapped = [
                              false,
                              false,
                              false,
                              false,
                              false,
                              false,
                              true,
                              false
                            ];
                          });
                          await Future.delayed(
                              const Duration(milliseconds: 400), () async {
                            await NavigationMethods.push(
                              context,
                              const PreOrderScreenWeb(),
                            );
                          });
                        },
                        child: Card(
                          elevation: isTapped[6] ? 20 : 5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Container(
                            height: 300,
                            width: 300,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              gradient: isTapped[6] == true
                                  ? linearGradient1
                                  : linearGradient2,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                SizedBox(
                                  height: 200,
                                  width: 200,
                                  child: Image.asset(
                                    'assets/home_screen_assets/single_color/pre_order_01.png',
                                    color: isTapped[6] == true
                                        ? Colors.white
                                        : appColor,
                                  ),
                                ),
                                Text(
                                  'Pre-Orders',
                                  style: TextStyle(
                                    color: isTapped[6] == true
                                        ? Colors.white
                                        : Colors.black,
                                    fontSize: 20,
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 100),
                      child: GestureDetector(
                        onTap: () async {
                          setState(() {
                            isTapped = [
                              false,
                              false,
                              false,
                              false,
                              false,
                              false,
                              false,
                              true
                            ];
                          });
                          await Future.delayed(
                              const Duration(milliseconds: 400), () async {
                            await NavigationMethods.push(
                              context,
                              const ShopReplenishScreenWeb() /*const ShopScreen()*/,
                            );
                          });
                        },
                        child: Card(
                          elevation: isTapped[7] ? 20 : 5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Container(
                            height: 300,
                            width: 300,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              gradient: isTapped[7] == true
                                  ? linearGradient1
                                  : linearGradient2,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                SizedBox(
                                  height: 200,
                                  width: 200,
                                  child: Image.asset(
                                    'assets/home_screen_assets/single_color/store.png',
                                    color: isTapped[7] == true
                                        ? Colors.white
                                        : appColor,
                                  ),
                                ),
                                Text(
                                  'Shops',
                                  style: TextStyle(
                                    color: isTapped[7] == true
                                        ? Colors.white
                                        : Colors.black,
                                    fontSize: 20,
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _screenSmallerThan24InchBuilder(BuildContext context, Size size) {
    return SingleChildScrollView(
      child: SizedBox(
        height: size.height,
        width: size.width,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: widget.accType == 'Jadlam'
                  ? MainAxisAlignment.spaceEvenly
                  : MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () async {
                    setState(() {
                      isTapped = [
                        true,
                        false,
                        false,
                        false,
                        false,
                        false,
                        false,
                        false,
                      ];
                    });
                    await Future.delayed(const Duration(milliseconds: 400),
                        () async {
                      await NavigationMethods.push(
                        context,
                        EANForWebApp(
                          screenType: 'product',
                          accType: widget.accType,
                          authorization: widget.authorization,
                          refreshToken: widget.refreshToken,
                          profileId: widget.profileId,
                          distCenterId: widget.distCenterId,
                          distCenterName: widget.distCenterName,
                          crossVisible: crossVisible,
                          barcodeToCheck: 0,
                        ),
                      );
                    });
                  },
                  child: Card(
                    elevation: isTapped[0] ? 20 : 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Container(
                      height: size.width * .15,
                      width: size.width * .15,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: isTapped[0] == true
                            ? linearGradient1
                            : linearGradient2,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(
                            height: size.width * .1,
                            width: size.width * .1,
                            child: Image.asset(
                              isTapped[0] == true
                                  ? 'assets/home_screen_assets/multi_color/products_02.png'
                                  : 'assets/home_screen_assets/multi_color/products_01.png',
                            ),
                          ),
                          Text(
                            'Product',
                            style: TextStyle(
                              color: isTapped[0] == true
                                  ? Colors.white
                                  : Colors.black,
                              fontSize: 16,
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
                Visibility(
                  visible: widget.accType == 'Jadlam',
                  child: GestureDetector(
                    onTap: () async {
                      setState(() {
                        isTapped = [
                          false,
                          true,
                          false,
                          false,
                          false,
                          false,
                          false,
                          false,
                        ];
                      });
                      await getPrintNodeData().whenComplete(() async {
                        await NavigationMethods.push(
                          context,
                          PackAndScanWebNew(apiKey: apiKey),
                        );
                      });
                    },
                    child: Card(
                      elevation: isTapped[1] ? 20 : 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Container(
                        height: size.width * .15,
                        width: size.width * .15,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: isTapped[1] == true
                              ? linearGradient1
                              : linearGradient2,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              height: size.width * .1,
                              width: size.width * .1,
                              child: Image.asset(
                                'assets/home_screen_assets/single_color/pack_and_scan_01.png',
                                color: isTapped[1] == true
                                    ? Colors.white
                                    : appColor,
                              ),
                            ),
                            Text(
                              'Pack & Scan',
                              style: TextStyle(
                                color: isTapped[1] == true
                                    ? Colors.white
                                    : Colors.black,
                                fontSize: 16,
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Visibility(
                  visible: widget.accType == 'Jadlam',
                  child: GestureDetector(
                    onTap: () async {
                      setState(() {
                        isTapped = [
                          false,
                          false,
                          true,
                          false,
                          false,
                          false,
                          false,
                          false
                        ];
                      });
                      await Future.delayed(const Duration(milliseconds: 400),
                          () async {
                        await NavigationMethods.push(
                          context,
                          EANForWebApp(
                            screenType: 'jit order',
                            accType: widget.accType,
                            authorization: widget.authorization,
                            refreshToken: widget.refreshToken,
                            profileId: widget.profileId,
                            distCenterId: widget.distCenterId,
                            distCenterName: widget.distCenterName,
                            crossVisible: crossVisible,
                            barcodeToCheck: 0,
                          ),
                        );
                      });
                    },
                    child: Card(
                      elevation: isTapped[2] ? 20 : 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Container(
                        height: size.width * .15,
                        width: size.width * .15,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: isTapped[2] == true
                              ? linearGradient1
                              : linearGradient2,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              height: size.width * .1,
                              width: size.width * .1,
                              child: Image.asset(
                                isTapped[2] == true
                                    ? 'assets/home_screen_assets/multi_color/jit_orders_02.png'
                                    : 'assets/home_screen_assets/multi_color/jit_orders_01.png',
                              ),
                            ),
                            Text(
                              'JIT Orders',
                              style: TextStyle(
                                color: isTapped[2] == true
                                    ? Colors.white
                                    : Colors.black,
                                fontSize: 16,
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Visibility(
                  visible: widget.accType == 'Jadlam',
                  child: GestureDetector(
                    onTap: () async {
                      setState(() {
                        isTapped = [
                          false,
                          false,
                          false,
                          true,
                          false,
                          false,
                          false,
                          false
                        ];
                      });
                      await Future.delayed(const Duration(milliseconds: 400),
                          () async {
                        await NavigationMethods.push(
                          context,
                          EANForWebApp(
                            screenType: 'transfer',
                            accType: widget.accType,
                            authorization: widget.authorization,
                            refreshToken: widget.refreshToken,
                            profileId: widget.profileId,
                            distCenterId: widget.distCenterId,
                            distCenterName: widget.distCenterName,
                            crossVisible: crossVisible,
                            barcodeToCheck: 0,
                          ),
                        );
                      });
                    },
                    child: Card(
                      elevation: isTapped[3] ? 20 : 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Container(
                        height: size.width * .15,
                        width: size.width * .15,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: isTapped[3] == true
                              ? linearGradient1
                              : linearGradient2,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              height: size.width * .1,
                              width: size.width * .1,
                              child: Image.asset(
                                isTapped[3] == true
                                    ? 'assets/home_screen_assets/multi_color/stock_transfer_02.png'
                                    : 'assets/home_screen_assets/multi_color/stock_transfer_01.png',
                              ),
                            ),
                            Text(
                              'Stock Transfer',
                              style: TextStyle(
                                color: isTapped[3] == true
                                    ? Colors.white
                                    : Colors.black,
                                fontSize: 16,
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Visibility(
              visible: widget.accType == 'Jadlam',
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    onTap: () async {
                      setState(() {
                        isTapped = [
                          false,
                          false,
                          false,
                          false,
                          true,
                          false,
                          false,
                          false
                        ];
                      });
                      await Future.delayed(const Duration(milliseconds: 400),
                          () async {
                        await NavigationMethods.push(
                          context,
                          const ShipmentRulesScreen(),
                        );
                      });
                    },
                    child: Card(
                      elevation: isTapped[4] ? 20 : 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Container(
                        height: size.width * .15,
                        width: size.width * .15,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: isTapped[4] == true
                              ? linearGradient1
                              : linearGradient2,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              height: size.width * .1,
                              width: size.width * .1,
                              child: Image.asset(
                                isTapped[4] == true
                                    ? 'assets/home_screen_assets/multi_color/shipping_rules_02.png'
                                    : 'assets/home_screen_assets/multi_color/shipping_rules_01.png',
                                color: isTapped[4] == true
                                    ? Colors.white
                                    : appColor,
                              ),
                            ),
                            Text(
                              'Shipping Rules',
                              style: TextStyle(
                                color: isTapped[4] == true
                                    ? Colors.white
                                    : Colors.black,
                                fontSize: 16,
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      setState(() {
                        isTapped = [
                          false,
                          false,
                          false,
                          false,
                          false,
                          true,
                          false,
                          false,
                        ];
                      });
                      await getPrintNodeData().whenComplete(() async {
                        await NavigationMethods.push(
                          context,
                          PickLists(
                            accType: widget.accType,
                            authorization: widget.authorization,
                            refreshToken: widget.refreshToken,
                            profileId: widget.profileId,
                            distCenterId: widget.distCenterId,
                            distCenterName: widget.distCenterName,
                            userName: widget.userId,
                            isDCSplitAutomatic: isDCSplitAutomatic,
                          ),
                        );
                      });
                    },
                    child: Card(
                      elevation: isTapped[5] ? 20 : 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Container(
                        height: size.width * .15,
                        width: size.width * .15,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: isTapped[5] == true
                              ? linearGradient1
                              : linearGradient2,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              height: size.width * .1,
                              width: size.width * .1,
                              child: Image.asset(
                                isTapped[5] == true
                                    ? 'assets/home_screen_assets/single_color/picklist_01.png'
                                    : 'assets/home_screen_assets/single_color/picklist_01.png',
                                color: isTapped[5] == true
                                    ? Colors.white
                                    : appColor,
                              ),
                            ),
                            Text(
                              'Picklist',
                              style: TextStyle(
                                color: isTapped[5] == true
                                    ? Colors.white
                                    : Colors.black,
                                fontSize: 16,
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      setState(() {
                        isTapped = [
                          false,
                          false,
                          false,
                          false,
                          false,
                          false,
                          true,
                          false
                        ];
                      });
                      await Future.delayed(const Duration(milliseconds: 400),
                          () async {
                        await NavigationMethods.push(
                          context,
                          const PreOrderScreenWeb(),
                        );
                      });
                    },
                    child: Card(
                      elevation: isTapped[6] ? 20 : 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Container(
                        height: size.width * .15,
                        width: size.width * .15,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: isTapped[6] == true
                              ? linearGradient1
                              : linearGradient2,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              height: size.width * .1,
                              width: size.width * .1,
                              child: Image.asset(
                                'assets/home_screen_assets/single_color/pre_order_01.png',
                                color: isTapped[6] == true
                                    ? Colors.white
                                    : appColor,
                              ),
                            ),
                            Text(
                              'Pre-Orders',
                              style: TextStyle(
                                color: isTapped[6] == true
                                    ? Colors.white
                                    : Colors.black,
                                fontSize: 16,
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      setState(() {
                        isTapped = [
                          false,
                          false,
                          false,
                          false,
                          false,
                          false,
                          false,
                          true
                        ];
                      });
                      await Future.delayed(const Duration(milliseconds: 400),
                          () async {
                        await NavigationMethods.push(
                          context,
                          const ShopReplenishScreenWeb(),
                          /* const ShopScreen(),*/
                        );
                      });
                    },
                    child: Card(
                      elevation: isTapped[7] ? 20 : 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Container(
                        height: size.width * .15,
                        width: size.width * .15,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: isTapped[7] == true
                              ? linearGradient1
                              : linearGradient2,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              height: size.width * .1,
                              width: size.width * .1,
                              child: Image.asset(
                                'assets/home_screen_assets/single_color/store.png',
                                color: isTapped[7] == true
                                    ? Colors.white
                                    : appColor,
                              ),
                            ),
                            Text(
                              'Shops',
                              style: TextStyle(
                                color: isTapped[7] == true
                                    ? Colors.white
                                    : Colors.black,
                                fontSize: 16,
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mobileScreenBuilder(BuildContext context, Size size) {
    return SingleChildScrollView(
      child: SizedBox(
        height: size.height,
        width: size.width,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: widget.accType == 'Jadlam'
                  ? MainAxisAlignment.spaceEvenly
                  : MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () async {
                    setState(() {
                      isTapped = [
                        true,
                        false,
                        false,
                        false,
                        false,
                        false,
                        false,
                      ];
                    });
                    await Future.delayed(const Duration(milliseconds: 400),
                        () async {
                      await NavigationMethods.push(
                        context,
                        BarcodeCameraScreen(
                          accType: widget.accType,
                          authorization: widget.authorization,
                          refreshToken: widget.refreshToken,
                          crossVisible: crossVisible,
                          screenType: 'product',
                          profileId: widget.profileId,
                          distCenterName: widget.distCenterName,
                          distCenterId: widget.distCenterId,
                          barcodeToCheck: 0,
                        ),
                      );
                    });
                  },
                  child: Card(
                    elevation: isTapped[0] ? 10 : 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Container(
                      height: size.width * .4,
                      width: size.width * .4,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: isTapped[0] == true
                            ? linearGradient1
                            : linearGradient2,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(
                            height: size.width * .25,
                            width: size.width * .25,
                            child: Image.asset(isTapped[0] == true
                                ? 'assets/home_screen_assets/multi_color/products_02.png'
                                : 'assets/home_screen_assets/multi_color/products_01.png'),
                          ),
                          Text(
                            'Product',
                            style: TextStyle(
                              color: isTapped[0] == true
                                  ? Colors.white
                                  : Colors.black,
                              fontSize: 16,
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
                Visibility(
                  visible: widget.accType == 'Jadlam',
                  child: GestureDetector(
                    onTap: () async {
                      setState(() {
                        isTapped = [
                          false,
                          true,
                          false,
                          false,
                          false,
                          false,
                          false
                        ];
                      });
                      await Future.delayed(const Duration(milliseconds: 400),
                          () {
                        NavigationMethods.push(
                          context,
                          BarcodeCameraScreen(
                            accType: widget.accType,
                            authorization: widget.authorization,
                            refreshToken: widget.refreshToken,
                            crossVisible: crossVisible,
                            screenType: 'pack and scan',
                            profileId: widget.profileId,
                            distCenterName: widget.distCenterName,
                            distCenterId: widget.distCenterId,
                            barcodeToCheck: 0,
                          ),
                        );
                      });
                    },
                    child: Card(
                      elevation: isTapped[1] ? 10 : 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Container(
                        height: size.width * .4,
                        width: size.width * .4,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: isTapped[1] == true
                              ? linearGradient1
                              : linearGradient2,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              height: size.width * .25,
                              width: size.width * .25,
                              child: Image.asset(
                                'assets/home_screen_assets/single_color/pack_and_scan_01.png',
                                color: isTapped[1] == true
                                    ? Colors.white
                                    : appColor,
                              ),
                            ),
                            Text(
                              'Pack & Scan',
                              style: TextStyle(
                                color: isTapped[1] == true
                                    ? Colors.white
                                    : Colors.black,
                                fontSize: 16,
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Visibility(
              visible: widget.accType == 'Jadlam',
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    onTap: () async {
                      setState(() {
                        isTapped = [
                          false,
                          false,
                          true,
                          false,
                          false,
                          false,
                          false
                        ];
                      });
                      await Future.delayed(const Duration(milliseconds: 400),
                          () {
                        NavigationMethods.push(
                          context,
                          BarcodeCameraScreen(
                            accType: widget.accType,
                            authorization: widget.authorization,
                            refreshToken: widget.refreshToken,
                            crossVisible: crossVisible,
                            screenType: 'transfer',
                            profileId: widget.profileId,
                            distCenterName: widget.distCenterName,
                            distCenterId: widget.distCenterId,
                            barcodeToCheck: 0,
                          ),
                        );
                      });
                    },
                    child: Card(
                      elevation: isTapped[2] ? 20 : 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Container(
                        height: size.width * .4,
                        width: size.width * .4,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: isTapped[2] == true
                              ? linearGradient1
                              : linearGradient2,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              height: size.width * .25,
                              width: size.width * .25,
                              child: Image.asset(
                                isTapped[2] == true
                                    ? 'assets/home_screen_assets/multi_color/stock_transfer_02.png'
                                    : 'assets/home_screen_assets/multi_color/stock_transfer_01.png',
                              ),
                            ),
                            Text(
                              'Stock Transfer',
                              style: TextStyle(
                                color: isTapped[2] == true
                                    ? Colors.white
                                    : Colors.black,
                                fontSize: 16,
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      setState(() {
                        isTapped = [
                          false,
                          false,
                          false,
                          true,
                          false,
                          false,
                          false
                        ];
                      });
                      await Future.delayed(const Duration(milliseconds: 400),
                          () {
                        NavigationMethods.push(
                          context,
                          BarcodeCameraScreen(
                            accType: widget.accType,
                            authorization: widget.authorization,
                            refreshToken: widget.refreshToken,
                            crossVisible: crossVisible,
                            screenType: 'jit order',
                            profileId: widget.profileId,
                            distCenterName: widget.distCenterName,
                            distCenterId: widget.distCenterId,
                            barcodeToCheck: 0,
                          ),
                        );
                      });
                    },
                    child: Card(
                      elevation: isTapped[3] ? 20 : 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Container(
                        height: size.width * .4,
                        width: size.width * .4,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: isTapped[3] == true
                              ? linearGradient1
                              : linearGradient2,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              height: size.width * .25,
                              width: size.width * .25,
                              child: Image.asset(
                                isTapped[3] == true
                                    ? 'assets/home_screen_assets/multi_color/jit_orders_02.png'
                                    : 'assets/home_screen_assets/multi_color/jit_orders_01.png',
                              ),
                            ),
                            Text(
                              'JIT Orders',
                              style: TextStyle(
                                color: isTapped[3] == true
                                    ? Colors.white
                                    : Colors.black,
                                fontSize: 16,
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Visibility(
              visible: widget.accType == 'Jadlam',
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    onTap: () async {
                      setState(() {
                        isTapped = [
                          false,
                          false,
                          false,
                          false,
                          true,
                          false,
                          false
                        ];
                      });
                      await getPrintNodeData().whenComplete(() async {
                        await NavigationMethods.push(
                          context,
                          PickLists(
                            accType: widget.accType,
                            authorization: widget.authorization,
                            refreshToken: widget.refreshToken,
                            profileId: widget.profileId,
                            distCenterId: widget.distCenterId,
                            distCenterName: widget.distCenterName,
                            userName: widget.userId,
                            isDCSplitAutomatic: isDCSplitAutomatic,
                          ),
                        );
                      });
                    },
                    child: Card(
                      elevation: isTapped[4] ? 20 : 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Container(
                        height: size.width * .4,
                        width: size.width * .4,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: isTapped[4] == true
                              ? linearGradient1
                              : linearGradient2,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              height: size.width * .25,
                              width: size.width * .25,
                              child: Image.asset(
                                'assets/home_screen_assets/single_color/picklist_01.png',
                                color: isTapped[4] == true
                                    ? Colors.white
                                    : appColor,
                              ),
                            ),
                            Text(
                              'Picklist',
                              style: TextStyle(
                                color: isTapped[4] == true
                                    ? Colors.white
                                    : Colors.black,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      setState(() {
                        isTapped = [
                          false,
                          false,
                          false,
                          false,
                          false,
                          true,
                          false,
                        ];
                      });
                      await Future.delayed(const Duration(milliseconds: 400),
                          () {
                        NavigationMethods.push(
                          context,
                          const PreOrderScreen(),
                        );
                      });
                    },
                    child: Card(
                      elevation: isTapped[5] ? 20 : 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Container(
                        height: size.width * .4,
                        width: size.width * .4,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: isTapped[5] == true
                              ? linearGradient1
                              : linearGradient2,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              height: size.width * .25,
                              width: size.width * .25,
                              child: Image.asset(
                                'assets/home_screen_assets/single_color/pre_order_01.png',
                                color: isTapped[5] == true
                                    ? Colors.white
                                    : appColor,
                              ),
                            ),
                            Text(
                              'Pre-Orders',
                              style: TextStyle(
                                color: isTapped[5] == true
                                    ? Colors.white
                                    : Colors.black,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Visibility(
              visible: widget.accType == 'Jadlam',
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    onTap: () async {
                      setState(() {
                        isTapped = [
                          false,
                          false,
                          false,
                          false,
                          false,
                          false,
                          true
                        ];
                      });
                      await Future.delayed(const Duration(milliseconds: 400),
                          () async {
                        await NavigationMethods.push(
                          context,
                          BarcodeCameraScreen(
                            accType: widget.accType,
                            authorization: widget.authorization,
                            refreshToken: widget.refreshToken,
                            crossVisible: crossVisible,
                            screenType: 'shop replenish',
                            profileId: widget.profileId,
                            distCenterName: widget.distCenterName,
                            distCenterId: widget.distCenterId,
                            barcodeToCheck: 0,
                          ),
                        );
                      });
                    },
                    child: Card(
                      elevation: isTapped[6] ? 20 : 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Container(
                        height: size.width * .4,
                        width: size.width * .4,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: isTapped[6] == true
                              ? linearGradient1
                              : linearGradient2,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              height: size.width * .25,
                              width: size.width * .25,
                              child: Image.asset(
                                'assets/home_screen_assets/single_color/store.png',
                                color: isTapped[6] == true
                                    ? Colors.white
                                    : appColor,
                              ),
                            ),
                            Text(
                              'Shop Replenish',
                              style: TextStyle(
                                color: isTapped[6] == true
                                    ? Colors.white
                                    : Colors.black,
                                fontSize: 16,
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: size.width * .4,
                    width: size.width * .4,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// API METHODS

  void downloadFile(String url) {
    html.AnchorElement anchorElement = html.AnchorElement(href: url);
    anchorElement.target = 'blank';
    anchorElement.download = url;
    anchorElement.click();
  }

  Future<void> sendPrintJobForManifest({
    required String apiKey,
    required int printerId,
    required String printerName,
    required String manifestPdfUrl,
  }) async {
    String uri = 'https://api.printnode.com/printjobs';
    log('SEND PRINT JOB API URI >>---> $uri');
    log('ENCODED API KEY >>---> ${base64.encode(utf8.encode(apiKey))}');

    var header = {
      'Content-Type': 'application/json',
      'Authorization': 'Basic ${base64.encode(utf8.encode(apiKey))}'
    };

    var body = json.encode({
      "printerId": printerId,
      "title": 'Manifest - ${DateTime.now()}',
      "contentType": "pdf_uri",
      "content": manifestPdfUrl,
      "source": "Home Screen Create Manifest Option"
    });

    try {
      var response = await http.post(Uri.parse(uri), body: body, headers: header).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          Fluttertoast.showToast(msg: kTimeOut);
          return http.Response('Error', 408);
        },
      );
      log('SEND PRINT JOB API STATUS CODE >>---> ${response.statusCode}');
      if (!mounted) return;
      if (response.statusCode == 201) {
        log('Manifest Sent to Printer $printerName Successfully');
        ToastUtils.motionToastCentered800MS(
          message: 'Manifest Sent to Printer $printerName Successfully',
          context: context,
        );
      } else {
        ToastUtils.motionToastCentered1500MS(
          message: kerrorString,
          context: context,
        );
      }
    } catch (e) {
      log("SEND PRINT JOB API EXCEPTION >>---> ${e.toString()}");
    }
  }

  Future<void> createManifest(bool isTest) async {
    setState(() {
      isCreatingManifest = true;
      isManifestSuccessful = false;
    });
    String uri = 'https://weblegs.info/EasyPost/api/EasyPostManifest?IsTest=$isTest';
    log('CREATE MANIFEST API URI >>---> $uri');

    try {
      var response = await http.get(Uri.parse(uri)).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          ToastUtils.motionToastCentered1500MS(
            message: kTimeOut,
            context: context,
          );
          setState(() {
            isCreatingManifest = false;
            isManifestSuccessful = false;
          });
          return http.Response('Error', 408);
        },
      );
      log('CREATE MANIFEST API STATUS CODE >>---> ${response.statusCode}');

      if (response.statusCode == 200) {
        log('CREATE MANIFEST API RESPONSE >>---> ${jsonDecode(response.body)}');
        String manifest = '';
        String manifestAfterRemovingWhiteSpace = '';
        setState(() {
          manifest = jsonDecode(response.body)['manifestlocalUrl'].toString();
        });
        for (int i = 0; i < manifest.length; i++) {
          if (!manifest[i].contains(' ')) {
            setState(() {
              manifestAfterRemovingWhiteSpace = "$manifestAfterRemovingWhiteSpace${manifest[i]}";
            });
          } else {
            setState(() {
              manifestAfterRemovingWhiteSpace = "$manifestAfterRemovingWhiteSpace${'%20'}";
            });
          }
        }

        setState(() {
          manifestUrl = manifestAfterRemovingWhiteSpace;
          isCreatingManifest = false;
          isManifestSuccessful = true;
        });
        log('manifestUrl >>---> $manifestUrl');
      } else {
        if (!mounted) return;
        ToastUtils.motionToastCentered1500MS(
          message: jsonDecode(response.body)['message'].toString(),
          context: context,
        );
        setState(() {
          isCreatingManifest = false;
          isManifestSuccessful = false;
        });
      }
    } on Exception catch (e) {
      log('CREATE MANIFEST API EXCEPTION >>---> ${e.toString()}');
      ToastUtils.motionToastCentered1500MS(
        message: e.toString(),
        context: context,
      );
      setState(() {
        isCreatingManifest = false;
        isManifestSuccessful = false;
      });
    }
  }

  Future<void> getPrintNodeData() async {
    await ApiCalls.getPrintNodeData().then((data) {
      if (data.isEmpty) {
        setState(() {
          isError = true;
          error = 'Error in fetching PrintNode Data. Please try again!';
        });
      } else {
        printNodeData = [];
        printNodeData.addAll(data.map((e) => e));
        log('V printNodeData >>---> $printNodeData');

        setState(() {
          apiKey = printNodeData[0].get<String>('api_key') ?? '';
          webAppLastUpdated =
              printNodeData[0].get<String>('web_app_last_updated') ?? '';
          isDCSplitAutomatic =
              (printNodeData[0].get<String>('is_dc_split_automatic') ?? '') ==
                      'Yes'
                  ? true
                  : false;
        });
        log('V apiKey >>---> $apiKey');
        log('V webAppLastUpdated >>---> $webAppLastUpdated');
        log('V isDCSplitAutomatic >>---> $isDCSplitAutomatic');
      }
    });
  }

  Future<String> getEasyPostLiveOrTestValue() async {
    String str = '';
    await SharedPreferences.getInstance().then((prefs) {
      setState(() {
        str = prefs.getString('EasyPostTestOrLive') ?? '';
      });
    });
    return str;
  }

  Future<void> saveEasyPostLiveOrTestValue(String str) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if(str.isEmpty) {
      prefs.setString('EasyPostTestOrLive', 'Test');
    } else {
      prefs.setString('EasyPostTestOrLive', str);
    }
  }

  Future<void> logout() async {
    setState(() {
      isLoggingOut = true;
    });
    await ApiCalls.getWeblegsData().then((value) async {
      log('Credentials data - ${jsonEncode(value)}');
      if (value.isEmpty) {
        Fluttertoast.showToast(
          msg: 'Internet may not be available, Please try again!',
          toastLength: Toast.LENGTH_LONG,
        );
        await Future.delayed(const Duration(seconds: 1), () {
          setState(() {
            isLoggingOut = false;
          });
        });
      } else {
        await SharedPreferences.getInstance().then((prefs) {
          prefs.setBool('isLoggedOut', true);
        });
        Fluttertoast.showToast(msg: 'You are successfully logged out');
        await Future.delayed(const Duration(seconds: 1), () {
          setState(() {
            isLoggingOut = false;
          });
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => LoginScreen(dataFromDB: value),
            ),
            (Route<dynamic> route) => false,
          );
        });
      }
    });
  }

  Future<bool> showExitPopupMobile() async {
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Center(
          child: Text('Exit App'),
        ),
        content: const Text('Do you want to exit the App?'),
        actions: [
          SizedBox(
            height: MediaQuery.of(context).size.height * .075,
            width: MediaQuery.of(context).size.width,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 20),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: appColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('No'),
                  ),
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 20),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: appColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Yes'),
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Future<void> openCamera() async {
    var cameraStatus = await Permission.camera.status;
    log('camera status - ${cameraStatus.isDenied}');
    log('camera status - ${cameraStatus.isGranted}');
    log('camera status - ${cameraStatus.isLimited}');
    log('camera status - ${cameraStatus.isRestricted}');
    log('camera status - ${cameraStatus.isPermanentlyDenied}');
    if (cameraStatus.isDenied == true && isFirstTimeScanCamera == false) {
      openAppSettings();
    } else {
      setState(() {
        isFirstTimeScanCamera = false;
        controllerText = '';
        crossVisible = false;
      });
      await scanBarcode().whenComplete(() {
        if (scanBarcodeResult != "" && !(scanBarcodeResult.contains('-1'))) {
          setState(() {
            controllerText = scanBarcodeResult;
            crossVisible = true;
          });
        } else {
          setState(() {
            controllerText = '';
            crossVisible = false;
          });
        }
      });
    }
  }

  Future<void> scanBarcode() async {
    String barcodeScanRes;
    try {
      barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
          '#ff6666', 'Cancel', true, ScanMode.BARCODE);
      log("barcodeScanRes - $barcodeScanRes");
    } on PlatformException {
      barcodeScanRes = 'Failed to get platform version.';
    }
    if (!mounted) return;

    setState(() {
      scanBarcodeResult = barcodeScanRes;
    });
    log('scanBarcodeResult - $scanBarcodeResult');
  }
}





















































//// The Shimmer Effect Code - to be used later.

const _shimmerGradient = LinearGradient(
  colors: [
    Color(0xFFEBEBF4),
    Color(0xFFF4F4F4),
    Color(0xFFEBEBF4),
  ],
  stops: [
    0.1,
    0.3,
    0.4,
  ],
  begin: Alignment(-1.0, -0.3),
  end: Alignment(1.0, 0.3),
  tileMode: TileMode.clamp,
);

class ExampleUiLoadingAnimation extends StatefulWidget {
  const ExampleUiLoadingAnimation({
    super.key,
  });

  @override
  State<ExampleUiLoadingAnimation> createState() =>
      _ExampleUiLoadingAnimationState();
}

class _ExampleUiLoadingAnimationState extends State<ExampleUiLoadingAnimation> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Shimmer(
        linearGradient: _shimmerGradient,
        child: ListView(
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildListItem(),
            _buildListItem(),
            _buildListItem(),
          ],
        ),
      ),
    );
  }

  Widget _buildListItem() {
    return ShimmerLoading(
      isLoading: true,
      child: CardListItem(
        isLoading: true,
      ),
    );
  }
}

class Shimmer extends StatefulWidget {
  static ShimmerState? of(BuildContext context) {
    return context.findAncestorStateOfType<ShimmerState>();
  }

  const Shimmer({
    super.key,
    required this.linearGradient,
    this.child,
  });

  final LinearGradient linearGradient;
  final Widget? child;

  @override
  ShimmerState createState() => ShimmerState();
}

class ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();

    _shimmerController = AnimationController.unbounded(vsync: this)
      ..repeat(min: -0.5, max: 1.5, period: const Duration(milliseconds: 1000));
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }
// code-excerpt-closing-bracket

  LinearGradient get _gradient => LinearGradient(
    colors: widget.linearGradient.colors,
    stops: widget.linearGradient.stops,
    begin: widget.linearGradient.begin,
    end: widget.linearGradient.end,
    transform: _SlidingGradientTransform(slidePercent: _shimmerController.value),
  );

  bool get isSized => (context.findRenderObject() as RenderBox).hasSize;

  Size get size => (context.findRenderObject() as RenderBox).size;

  Offset getDescendantOffset({
    required RenderBox descendant,
    Offset offset = Offset.zero,
  }) {
    final shimmerBox = context.findRenderObject() as RenderBox;
    return descendant.localToGlobal(offset, ancestor: shimmerBox);
  }

  Listenable get shimmerChanges => _shimmerController;

  @override
  Widget build(BuildContext context) {
    return widget.child ?? const SizedBox();
  }
}

class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform({
    required this.slidePercent,
  });

  final double slidePercent;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * slidePercent, 0.0, 0.0);
  }
}

class ShimmerLoading extends StatefulWidget {
  const ShimmerLoading({
    super.key,
    required this.isLoading,
    required this.child,
  });

  final bool isLoading;
  final Widget child;

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading> {
  Listenable? _shimmerChanges;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_shimmerChanges != null) {
      _shimmerChanges!.removeListener(_onShimmerChange);
    }
    _shimmerChanges = Shimmer.of(context)?.shimmerChanges;
    if (_shimmerChanges != null) {
      _shimmerChanges!.addListener(_onShimmerChange);
    }
  }

  @override
  void dispose() {
    _shimmerChanges?.removeListener(_onShimmerChange);
    super.dispose();
  }

  void _onShimmerChange() {
    if (widget.isLoading) {
      setState(() {
        // update the shimmer painting.
      });
    }
  }
// code-excerpt-closing-bracket

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoading) {
      return widget.child;
    }

    // Collect ancestor shimmer info.
    final shimmer = Shimmer.of(context)!;
    if (!shimmer.isSized) {
      // The ancestor Shimmer widget has not laid
      // itself out yet. Return an empty box.
      return const SizedBox();
    }
    final shimmerSize = shimmer.size;
    final gradient = shimmer._gradient;
    final offsetWithinShimmer = shimmer.getDescendantOffset(
      descendant: context.findRenderObject() as RenderBox,
    );

    return ShaderMask(
      blendMode: BlendMode.srcATop,
      shaderCallback: (bounds) {
        return gradient.createShader(
          Rect.fromLTWH(
            -offsetWithinShimmer.dx,
            -offsetWithinShimmer.dy,
            shimmerSize.width,
            shimmerSize.height,
          ),
        );
      },
      child: widget.child,
    );
  }
}

class CardListItem extends StatelessWidget {
  const CardListItem({super.key,
    required this.isLoading,
  });

  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildImage(),
          const SizedBox(height: 16),
          _buildText(),
        ],
      ),
    );
  }

  Widget _buildImage() {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(16),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.network(
            'https://docs.flutter.dev/cookbook'
                '/img-files/effects/split-check/Food1.jpg',
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  Widget _buildText() {
    if (isLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: 250,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ],
      );
    } else {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 8),
        child: Text(
          'check',
        ),
      );
    }
  }
}