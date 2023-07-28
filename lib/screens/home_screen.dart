import 'dart:convert';
import 'dart:developer';

import 'package:absolute_app/core/apis/api_calls.dart';
import 'package:absolute_app/core/utils/constants.dart';
import 'package:absolute_app/core/utils/navigation_methods.dart';
import 'package:absolute_app/core/utils/responsive_check.dart';
import 'package:absolute_app/screens/mobile_device_screens/barcode_camera_screen.dart';
import 'package:absolute_app/screens/mobile_device_screens/pre_order_screen.dart';
import 'package:absolute_app/screens/mobile_device_screens/settings_screen.dart';
import 'package:absolute_app/screens/web_screens/ean_for_web.dart';
import 'package:absolute_app/screens/login_screen.dart';
import 'package:absolute_app/screens/pick_list.dart';
import 'package:absolute_app/screens/web_screens/pack_and_scan_web_new.dart';
import 'package:absolute_app/screens/web_screens/pre_order_screen_web.dart';
import 'package:absolute_app/screens/web_screens/print_node_settings_web.dart';
import 'package:absolute_app/screens/web_screens/settings_screen_web.dart';
import 'package:absolute_app/screens/web_screens/shipment_rules_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:parse_server_sdk/parse_server_sdk.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

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

  List<bool> isTapped = [false, false, false, false, false, false, false];
  List<ParseObject> printNodeData = [];

  bool isFirstTimeScanCamera = true;
  bool crossVisible = false;
  bool isLoggingOut = false;
  bool isError = false;
  bool isLoading = false;

  String error = '';
  String scanBarcodeResult = '';
  String controllerText = '';
  String apiKey = '';

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
    printNodeAPICalls();
  }

  void printNodeAPICalls() async {
    setState(() {
      isLoading = true;
      isError = false;
    });
    await getPrintNodeData().whenComplete(() {
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
      child: SizedBox(
        height: size.height * .9,
        width: 350,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
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
              padding: const EdgeInsets.only(top: 20, left: 20),
              child: SizedBox(
                height: 270,
                width: 310,
                child: ListView(
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
                              leading: const Icon(Icons.logout_outlined),
                              title: const Row(
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
                              trailing: isLoggingOut == true
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                        color: appColor,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      size: 15,
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: EdgeInsets.only(bottom: 20),
                    child: Text(
                      'Last Updated at 26 July, 2023 01:31 PM',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
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
            padding: const EdgeInsets.only(top: 10, left: 5),
            child: SizedBox(
              height: size.height * .4,
              width: size.width * .75,
              child: ListView(
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
                      leading: Icon(
                        Icons.settings,
                        size: size.width * .06,
                      ),
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
                      leading: Icon(
                        Icons.person,
                        size: size.width * .06,
                      ),
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
                            false
                          ];
                        });
                        await Future.delayed(const Duration(milliseconds: 400),
                            () async {
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
                              false
                            ];
                          });
                          await Future.delayed(const Duration(milliseconds: 400),
                              () async {
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
                              true
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
                    const Padding(
                      padding: EdgeInsets.only(left: 100),
                      child: SizedBox(
                        height: 300,
                        width: 300,
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
                          false
                        ];
                      });
                      await Future.delayed(const Duration(milliseconds: 400),
                          () async {
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
                          false
                        ];
                      });
                      await Future.delayed(const Duration(milliseconds: 400),
                          () async {
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
                          true
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
                  SizedBox(
                    height: size.width * .15,
                    width: size.width * .15,
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
    return SizedBox(
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
                    isTapped = [true, false, false, false, false, false];
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
                      isTapped = [false, true, false, false, false, false];
                    });
                    await Future.delayed(const Duration(milliseconds: 400), () {
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
                      isTapped = [false, false, true, false, false, false];
                    });
                    await Future.delayed(const Duration(milliseconds: 400), () {
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
                      isTapped = [false, false, false, true, false, false];
                    });
                    await Future.delayed(const Duration(milliseconds: 400), () {
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
                      isTapped = [false, false, false, false, true, false];
                    });
                    await Future.delayed(const Duration(milliseconds: 400), () {
                      NavigationMethods.push(
                        context,
                        PickLists(
                          accType: widget.accType,
                          authorization: widget.authorization,
                          refreshToken: widget.refreshToken,
                          profileId: widget.profileId,
                          distCenterId: widget.distCenterId,
                          distCenterName: widget.distCenterName,
                          userName: widget.userId,
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
                      isTapped = [false, false, false, false, false, true];
                    });
                    await Future.delayed(const Duration(milliseconds: 400), () {
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
          )
        ],
      ),
    );
  }

  /// API METHODS

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
        });
        log('V apiKey >>---> $apiKey');
      }
    });
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
