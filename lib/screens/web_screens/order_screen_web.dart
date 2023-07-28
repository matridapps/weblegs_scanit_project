import 'dart:convert';
import 'dart:developer';
import 'package:absolute_app/core/apis/api_calls.dart';
import 'package:absolute_app/core/utils/constants.dart';
import 'package:absolute_app/core/utils/responsive_check.dart';
import 'package:absolute_app/core/utils/toast_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:parse_server_sdk/parse_server_sdk.dart';
import 'package:rounded_loading_button/rounded_loading_button.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:photo_view/photo_view.dart';
import 'package:url_launcher/url_launcher.dart';

class OrderScreenWeb extends StatefulWidget {
  const OrderScreenWeb({
    Key? key,
    required this.ean,
    required this.isFiltered,
  }) : super(key: key);

  final String ean;
  final bool isFiltered;

  @override
  State<OrderScreenWeb> createState() => _OrderScreenWebState();
}

class _OrderScreenWebState extends State<OrderScreenWeb> {
  List<RoundedLoadingButtonController> printController =
      <RoundedLoadingButtonController>[];

  List<OrderModel> orderList = [];
  List<dynamic> orderValue = [];

  List<ParseObject> labelPrintingDataDB = [];

  String serialNoFromDB = '0';

  String labelUrl = '';
  String labelError = '';

  bool isLoading = true;
  bool orderLoading = false;

  int orderIndex = 0;

  DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");

  @override
  void initState() {
    hitScreenApi();

    super.initState();
  }

  void hitScreenApi() async {
    isLoading == true;
    await getOrdersByProductId(ean: widget.ean, isFiltered: widget.isFiltered)
        .whenComplete(() => loadingLabelPrintingData(isFirstTime: true))
        .whenComplete(() {
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
        toolbarHeight: size.height * .08,
        elevation: 5,
        title: Text(
          'Orders',
          style: TextStyle(
              fontSize: ResponsiveCheck.isLargeScreen(context)
                  ? size.width * .02
                  : ResponsiveCheck.isMediumScreen(context)
                      ? size.width * .025
                      : size.width * .03,
              color: Colors.black),
        ),
      ),
      body: SizedBox(
        height: size.height,
        width: size.width,
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: EdgeInsets.only(top: size.width * .05),
                child: Container(
                  height: size.height * .07,
                  width: size.width * .95,
                  color: Colors.grey.shade200,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Padding(
                            padding: EdgeInsets.only(left: size.width * .05),
                            child: const Text('Barcode(EAN) : '),
                          ),
                          Text(
                            widget.ean,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          )
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                height: size.width * .05,
                width: size.width,
              ),
              isLoading == true
                  ? SizedBox(
                      height:
                          size.height - size.width * .05 - size.height * .07,
                      width: size.width * .95,
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: appColor,
                        ),
                      ),
                    )
                  : SizedBox(
                      height: size.height,
                      width: size.width * .95,
                      child: Column(
                        children: [
                          Container(
                            height: size.height * .05,
                            width: size.width * .95,
                            color: Colors.grey.shade200,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Padding(
                                  padding:
                                      EdgeInsets.only(left: size.width * .05),
                                  child: Text(
                                      'Showing ${orderList.isEmpty ? 0 : orderIndex + 1} of ${orderList.length}'),
                                ),
                              ],
                            ),
                          ),
                          allOrders(size).isEmpty
                              ? Padding(
                                  padding:
                                      EdgeInsets.only(top: size.height * .03),
                                  child: SizedBox(
                                      height: size.height -
                                          size.width * .05 -
                                          size.height * .07 -
                                          size.height * .1,
                                      width: size.width * .95,
                                      child: const Center(
                                        child: Text('No Orders available.'),
                                      )),
                                )
                              : Padding(
                                  padding:
                                      EdgeInsets.only(top: size.height * .03),
                                  child: SizedBox(
                                    height: size.height * .8,
                                    width: size.width * .95,
                                    child: orderLoading == true
                                        ? const Center(
                                            child: CircularProgressIndicator(
                                              color: appColor,
                                            ),
                                          )
                                        : Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Container(
                                                height: size.height * .07,
                                                width: size.width * .95,
                                                color: Colors.grey.shade200,
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .center,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment
                                                          .start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Padding(
                                                          padding:
                                                              EdgeInsets.only(
                                                                  left: size
                                                                          .width *
                                                                      .05),
                                                          child: Text(
                                                            'Order Id : ',
                                                            style: TextStyle(
                                                              fontWeight: FontWeight.bold,
                                                              fontSize: ResponsiveCheck.isLargeScreen(
                                                                  context)
                                                                  ? size.width * .015
                                                                  : ResponsiveCheck.isMediumScreen(context)
                                                                  ? size.width * .02
                                                                  : size.width * .025,
                                                            ),
                                                          ),
                                                        ),
                                                        Text(
                                                          '${orderList[orderIndex].orderId}',
                                                          style: TextStyle(
                                                            fontWeight: FontWeight.bold,
                                                            color: Colors.red,
                                                            fontSize: ResponsiveCheck.isLargeScreen(context)
                                                                ? size.width * .015
                                                                : ResponsiveCheck.isMediumScreen(context)
                                                                ? size.width * .02
                                                                : size.width * .025,
                                                          ),
                                                        )
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              SizedBox(
                                                height: size.height * .06,
                                                width: size.width * .95,
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment
                                                          .start,
                                                  children: [
                                                    SizedBox(
                                                      height:
                                                          size.height * .06,
                                                      width: size.width * .95,
                                                      child: Column(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .start,
                                                        children: [
                                                          Padding(
                                                            padding: EdgeInsets.only(
                                                                left:
                                                                    size.width *
                                                                        .05,
                                                                top:
                                                                    size.width *
                                                                        .03),
                                                            child: Row(
                                                              children: [
                                                                Text(
                                                                  'Date : ',
                                                                  style:
                                                                  TextStyle(
                                                                    color: Colors.grey,
                                                                    fontSize: ResponsiveCheck.isLargeScreen(
                                                                        context)
                                                                        ? size.width * .015
                                                                        : ResponsiveCheck.isMediumScreen(
                                                                        context)
                                                                        ? size.width * .02
                                                                        : size.width * .025,
                                                                    fontWeight: FontWeight.bold,
                                                                  ),
                                                                ),
                                                                Text(
                                                                  orderList[
                                                                          orderIndex]
                                                                      .createdDate,
                                                                  style:
                                                                  TextStyle(
                                                                    color: Colors.black,
                                                                    fontWeight: FontWeight.bold,
                                                                    fontSize: ResponsiveCheck.isLargeScreen(
                                                                        context)
                                                                        ? size.width * .015
                                                                        : ResponsiveCheck.isMediumScreen(
                                                                        context)
                                                                        ? size.width * .02
                                                                        : size.width * .025,
                                                                  ),
                                                                )
                                                              ],
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              SizedBox(
                                                height: size.height * .06,
                                                width: size.width * .95,
                                                child: Padding(
                                                  padding: EdgeInsets.only(
                                                    left: size.width * .05,
                                                    bottom: size.width * .03,
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      Text(
                                                        'Site Name : ',
                                                        style: TextStyle(
                                                          color: Colors.grey,
                                                          fontSize:
                                                              size.width *
                                                                  .045,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      Text(
                                                        '${orderList[orderIndex].siteName}',
                                                        style: TextStyle(
                                                          color: Colors.grey,
                                                          fontSize: ResponsiveCheck.isLargeScreen(context)
                                                              ? size.width * .015
                                                              : ResponsiveCheck.isMediumScreen(context)
                                                              ? size.width * .02
                                                              : size.width * .025,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      )
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              SizedBox(
                                                height: size.height * .07,
                                                width: size.width * .95,
                                                child: Center(
                                                  child: RoundedLoadingButton(
                                                    color: Colors.green,
                                                    borderRadius: 0,
                                                    height: size.height * .07,
                                                    width: size.width * .95,
                                                    successIcon:
                                                        Icons.check_rounded,
                                                    failedIcon:
                                                        Icons.close_rounded,
                                                    successColor:
                                                        Colors.green,
                                                    controller:
                                                        printController[
                                                            orderIndex],
                                                    onPressed: () async {
                                                      if ('${orderList[orderIndex].siteName}' ==
                                                          'Amazon UK-prime') {
                                                        await printLabelAmazonPrime(
                                                                siteOrderId:
                                                                    '${orderList[orderIndex].siteOrderId}')
                                                            .whenComplete(
                                                                () async {
                                                          if (labelError
                                                              .isNotEmpty) {
                                                            Fluttertoast.showToast(
                                                                msg:
                                                                    labelError,
                                                                toastLength: Toast
                                                                    .LENGTH_LONG);
                                                            await Future.delayed(
                                                                const Duration(
                                                                    seconds:
                                                                        1),
                                                                () {
                                                              printController[
                                                                      orderIndex]
                                                                  .reset();
                                                            });
                                                          } else {
                                                            await _launchUrl(
                                                                    labelUrl)
                                                                .whenComplete(
                                                                    () async {
                                                              await Future.delayed(
                                                                  const Duration(
                                                                      milliseconds:
                                                                          200),
                                                                  () {
                                                                saveLabelData(
                                                                  orderId: orderList[
                                                                          orderIndex]
                                                                      .orderId,
                                                                  orderDate: orderList[
                                                                          orderIndex]
                                                                      .createdDate,
                                                                  siteOrderId:
                                                                      orderList[orderIndex]
                                                                          .siteOrderId,
                                                                  siteName: orderList[
                                                                          orderIndex]
                                                                      .siteName,
                                                                  serialNo:
                                                                      '${int.parse(serialNoFromDB) + 1}',
                                                                );
                                                              }).whenComplete(
                                                                  () async {
                                                                await Future.delayed(
                                                                    const Duration(
                                                                        seconds:
                                                                            1),
                                                                    () {
                                                                  loadingLabelPrintingData(
                                                                      isFirstTime:
                                                                          false);
                                                                });
                                                              }).whenComplete(
                                                                  () async {
                                                                printController[
                                                                        orderIndex]
                                                                    .reset();
                                                                if (orderIndex ==
                                                                    orderList
                                                                            .length -
                                                                        1) {
                                                                  Navigator.pop(
                                                                      context);
                                                                } else {
                                                                  setState(
                                                                      () {
                                                                    orderLoading =
                                                                        true;
                                                                  });
                                                                  await Future.delayed(
                                                                      const Duration(
                                                                          seconds:
                                                                              1),
                                                                      () {
                                                                    setState(
                                                                        () {
                                                                      orderIndex =
                                                                          orderIndex +
                                                                              1;
                                                                      orderLoading =
                                                                          false;
                                                                    });
                                                                  });
                                                                }
                                                              });
                                                            });
                                                          }
                                                        });
                                                      } else {
                                                        await printLabelOthers(
                                                                siteOrderId:
                                                                    '${orderList[orderIndex].siteOrderId}')
                                                            .whenComplete(
                                                                () async {
                                                          if (labelError
                                                              .isNotEmpty) {
                                                            Fluttertoast.showToast(
                                                                msg:
                                                                    labelError,
                                                                toastLength: Toast
                                                                    .LENGTH_LONG);
                                                            await Future.delayed(
                                                                const Duration(
                                                                    seconds:
                                                                        1),
                                                                () {
                                                              printController[
                                                                      orderIndex]
                                                                  .reset();
                                                            });
                                                          } else {
                                                            await _launchUrl(
                                                                    labelUrl)
                                                                .whenComplete(
                                                                    () async {
                                                              await Future.delayed(
                                                                  const Duration(
                                                                      milliseconds:
                                                                          200),
                                                                  () {
                                                                saveLabelData(
                                                                  orderId: orderList[
                                                                          orderIndex]
                                                                      .orderId,
                                                                  orderDate: orderList[
                                                                          orderIndex]
                                                                      .createdDate,
                                                                  siteOrderId:
                                                                      orderList[orderIndex]
                                                                          .siteOrderId,
                                                                  siteName: orderList[
                                                                          orderIndex]
                                                                      .siteName,
                                                                  serialNo:
                                                                      '${int.parse(serialNoFromDB) + 1}',
                                                                );
                                                              }).whenComplete(
                                                                  () async {
                                                                await Future.delayed(
                                                                    const Duration(
                                                                        seconds:
                                                                            1),
                                                                    () {
                                                                  loadingLabelPrintingData(
                                                                      isFirstTime:
                                                                          false);
                                                                });
                                                              }).whenComplete(
                                                                  () async {
                                                                printController[
                                                                        orderIndex]
                                                                    .reset();
                                                                if (orderIndex ==
                                                                    orderList
                                                                            .length -
                                                                        1) {
                                                                  Navigator.pop(
                                                                      context);
                                                                } else {
                                                                  setState(
                                                                      () {
                                                                    orderLoading =
                                                                        true;
                                                                  });
                                                                  await Future.delayed(
                                                                      const Duration(
                                                                          seconds:
                                                                              1),
                                                                      () {
                                                                    setState(
                                                                        () {
                                                                      orderIndex =
                                                                          orderIndex +
                                                                              1;
                                                                      orderLoading =
                                                                          false;
                                                                    });
                                                                  });
                                                                }
                                                              });
                                                            });
                                                          }
                                                        });
                                                      }
                                                    },
                                                    child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        SizedBox(
                                                          height:
                                                              size.height *
                                                                  .05,
                                                          width: size.height *
                                                              .05,
                                                          child: Image.asset(
                                                            'assets/new_order_screen/orderpage-print.png',
                                                            color:
                                                                Colors.white,
                                                          ),
                                                        ),
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                      .only(
                                                                  left: 10),
                                                          child: Text(
                                                            'Print Label',
                                                            style: TextStyle(
                                                              fontSize:
                                                                  size.height *
                                                                      .025,
                                                              color: Colors
                                                                  .white,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              )
                                            ],
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
    );
  }

  List<Widget> allOrders(Size size) {
    return orderList.isEmpty
        ? []
        : List.generate(
            orderList.length,
            (index) => SizedBox(
              height: (index == orderList.length - 1)
                  ? ResponsiveCheck.isLargeScreen(context)
                      ? size.height * .6
                      : size.height * .42
                  : ResponsiveCheck.isLargeScreen(context)
                      ? size.height * .5
                      : size.height * .3,
              width: size.width * .95,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: size.height * .07,
                    width: size.width * .95,
                    color: Colors.grey.shade200,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Padding(
                              padding: EdgeInsets.only(left: size.width * .05),
                              child: Text(
                                'Order Id : ',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: ResponsiveCheck.isLargeScreen(
                                          context)
                                      ? size.width * .015
                                      : ResponsiveCheck.isMediumScreen(context)
                                          ? size.width * .02
                                          : size.width * .025,
                                ),
                              ),
                            ),
                            Text(
                              '${orderList[index].orderId}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                                fontSize: ResponsiveCheck.isLargeScreen(context)
                                    ? size.width * .015
                                    : ResponsiveCheck.isMediumScreen(context)
                                        ? size.width * .02
                                        : size.width * .025,
                              ),
                            )
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: ResponsiveCheck.isLargeScreen(context) ||
                            ResponsiveCheck.isMediumScreen(context)
                        ? size.height * .1
                        : size.height * .06,
                    width: size.width * .95,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: ResponsiveCheck.isLargeScreen(context) ||
                                  ResponsiveCheck.isMediumScreen(context)
                              ? size.height * .1
                              : size.height * .06,
                          width: size.width * .95,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Padding(
                                padding: EdgeInsets.only(
                                    left: size.width * .05,
                                    top: size.width * .03),
                                child: Row(
                                  children: [
                                    Text(
                                      'Date : ',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: ResponsiveCheck.isLargeScreen(
                                                context)
                                            ? size.width * .015
                                            : ResponsiveCheck.isMediumScreen(
                                                    context)
                                                ? size.width * .02
                                                : size.width * .025,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      orderList[index].createdDate,
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                        fontSize: ResponsiveCheck.isLargeScreen(
                                                context)
                                            ? size.width * .015
                                            : ResponsiveCheck.isMediumScreen(
                                                    context)
                                                ? size.width * .02
                                                : size.width * .025,
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: ResponsiveCheck.isLargeScreen(context)
                        ? size.height * .1
                        : size.height * .06,
                    width: size.width * .95,
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: size.width * .05,
                        bottom: size.width * .03,
                      ),
                      child: Row(
                        children: [
                          Text(
                            'Site Name : ',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: ResponsiveCheck.isLargeScreen(context)
                                  ? size.width * .015
                                  : ResponsiveCheck.isMediumScreen(context)
                                      ? size.width * .02
                                      : size.width * .025,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${orderList[index].siteName}',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: ResponsiveCheck.isLargeScreen(context)
                                  ? size.width * .015
                                  : ResponsiveCheck.isMediumScreen(context)
                                      ? size.width * .02
                                      : size.width * .025,
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    height: size.height * .07,
                    width: size.width * .95,
                    child: Center(
                      child: RoundedLoadingButton(
                        color: Colors.green,
                        borderRadius: 0,
                        height: size.height * .07,
                        width: size.width * .95,
                        successIcon: Icons.check_rounded,
                        failedIcon: Icons.close_rounded,
                        successColor: Colors.green,
                        controller: printController[index],
                        onPressed: () async {
                          if ('${orderList[index].siteName}' ==
                              'Amazon UK-prime') {
                            await printLabelAmazonPrime(
                                    siteOrderId:
                                        '${orderList[index].siteOrderId}')
                                .whenComplete(() async {
                              if (labelError.isNotEmpty) {
                                Fluttertoast.showToast(
                                    msg: labelError,
                                    toastLength: Toast.LENGTH_LONG);
                                await Future.delayed(const Duration(seconds: 1),
                                    () {
                                  printController[index].reset();
                                });
                              } else {
                                if (defaultTargetPlatform ==
                                        TargetPlatform.windows ||
                                    defaultTargetPlatform ==
                                        TargetPlatform.fuchsia ||
                                    defaultTargetPlatform ==
                                        TargetPlatform.linux ||
                                    defaultTargetPlatform ==
                                        TargetPlatform.macOS) {
                                  _launchUrl(labelUrl).whenComplete(() async {
                                    await Future.delayed(
                                        const Duration(milliseconds: 200), () {
                                      printController[index].reset();
                                    });
                                  });
                                } else {
                                  await print(labelUrl).whenComplete(() async {
                                    await Future.delayed(
                                        const Duration(milliseconds: 200), () {
                                      printController[index].reset();
                                    });
                                  });
                                }
                              }
                            });
                          } else {
                            await printLabelOthers(
                                    siteOrderId:
                                        '${orderList[index].siteOrderId}')
                                .whenComplete(() async {
                              if (labelError.isNotEmpty) {
                                Fluttertoast.showToast(
                                    msg: labelError,
                                    toastLength: Toast.LENGTH_LONG);
                                await Future.delayed(const Duration(seconds: 1),
                                    () {
                                  printController[index].reset();
                                });
                              } else {
                                if (defaultTargetPlatform ==
                                        TargetPlatform.windows ||
                                    defaultTargetPlatform ==
                                        TargetPlatform.fuchsia ||
                                    defaultTargetPlatform ==
                                        TargetPlatform.linux ||
                                    defaultTargetPlatform ==
                                        TargetPlatform.macOS) {
                                  _launchUrl(labelUrl).whenComplete(() async {
                                    await Future.delayed(
                                        const Duration(milliseconds: 200), () {
                                      printController[index].reset();
                                    });
                                  });
                                } else {
                                  await print(labelUrl).whenComplete(() async {
                                    await Future.delayed(
                                        const Duration(milliseconds: 200), () {
                                      printController[index].reset();
                                    });
                                  });
                                }
                              }
                            });
                          }
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              height: size.height * .05,
                              width: size.height * .05,
                              child: Image.asset(
                                'assets/new_order_screen/orderpage-print.png',
                                color: Colors.white,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 10),
                              child: Text(
                                'Print Label',
                                style: TextStyle(
                                  fontSize: ResponsiveCheck.isLargeScreen(
                                          context)
                                      ? size.width * .015
                                      : ResponsiveCheck.isMediumScreen(context)
                                          ? size.width * .02
                                          : size.width * .025,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          );
  }

  void saveLabelData({
    required String serialNo,
    required String orderId,
    required String orderDate,
    required String siteOrderId,
    required String siteName,
  }) async {
    var labelPrintingData = ParseObject('label_printing_data');
    labelPrintingData.set('sr_no', serialNo);
    labelPrintingData.set('order_id', orderId);
    labelPrintingData.set('label_print_date', DateTime.now());
    labelPrintingData.set('ean', widget.ean);
    labelPrintingData.set('order_date', orderDate);
    labelPrintingData.set('site_order_id', siteOrderId);
    labelPrintingData.set('site_name', siteName);
    labelPrintingData.set('label_url', labelUrl);

    await labelPrintingData.save();
  }

  void loadingLabelPrintingData({required bool isFirstTime}) async {
    isLoading = true;
    await ApiCalls.getLabelPrintingData().then((data) {
      log('label printing data>>>>>${jsonEncode(data)}');

      labelPrintingDataDB = [];

      labelPrintingDataDB.addAll(data.map((e) => e));
      log('labelPrintingDataDB>>>>>${jsonEncode(labelPrintingDataDB)}');

      if (isFirstTime == true) {
        if (orderList.isNotEmpty) {
          for (int i = orderList.length - 1; i >= 0; i--) {
            if (labelPrintingDataDB.any(
                    (e) => e.get<String>('order_id') == orderList[i].orderId) ==
                true) {
              orderList.removeAt(i);

              log('removed at $i');
              log('order list length >> ${orderList.length}');
            }
          }
        }
      }

      if (labelPrintingDataDB.isNotEmpty) {
        if (serialNoFromDB !=
            (labelPrintingDataDB[labelPrintingDataDB.length - 1]
                    .get<String>('sr_no') ??
                '0')) {
          if (!mounted) return;
          setState(() {
            serialNoFromDB = labelPrintingDataDB.isEmpty
                ? '0'
                : labelPrintingDataDB[labelPrintingDataDB.length - 1]
                        .get<String>('sr_no') ??
                    '0';
          });
        }
      }

      log('serialNoFromDB >>>>>> $serialNoFromDB');

      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
    });
  }

  Future<void> _launchUrl(String url) async {
    try {
      await launchUrl(Uri.parse(url));
    } catch (e) {
      log('Exception in Launching >>>>> ${e.toString()}');
    }
  }

  Future<void> print(String url) async {
    final pdf = pw.Document();
    try {
      final netImage = await networkImage(url);
      pdf.addPage(pw.Page(
          pageFormat: const PdfPageFormat(
            4 * PdfPageFormat.inch,
            6 * PdfPageFormat.inch,
          ),
          build: (pw.Context context) {
        return pw.Image(netImage);
      }));
      await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => pdf.save());
    } catch (e) {
      log("Exception in Printing >>>>>> ${e.toString()}");
    }
  }

  Widget imageDialog(text, path, context, Size size) {
    return Dialog(
      child: SizedBox(
        height: size.height * .75,
        width: size.width * .9,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: SizedBox(
                height: size.height * .05,
                width: size.width * .9,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '$text',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.close_rounded),
                      color: Colors.black,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: size.width * .9,
              height: size.height * .6,
              child: PhotoView(
                imageProvider: NetworkImage(
                  '$path',
                ),
              ),
            ),
            SizedBox(
              width: size.width * .9,
              height: size.height * .1,
              child: GestureDetector(
                onTap: () async {
                  await print(path);
                },
                child: Center(
                  child: SizedBox(
                    width: size.width * .3,
                    height: size.height * .08,
                    child: const Card(
                      elevation: 5,
                      color: appColor,
                      child: Center(
                        child: Text(
                          'Print',
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Future<void> printLabelAmazonPrime({required siteOrderId}) async {
    String siteOrderIdToSent = '';
    log('received siteOrderId>>>>>$siteOrderId');
    if (siteOrderId.toString().startsWith('#')) {
      setState(() {
        siteOrderIdToSent = siteOrderId.toString().replaceFirst('#', '%23');
      });
    } else {
      setState(() {
        siteOrderIdToSent = siteOrderId.toString();
      });
    }
    log('siteOrderIdToSent>>>>>$siteOrderIdToSent');

    String uri =
        'https://pickpackquick.azurewebsites.net/api/JadlamLabel?OrderNumber=$siteOrderIdToSent';
    log('print Label Amazon uri>>>>>$uri');

    labelError = '';
    try {
      var response = await http.get(Uri.parse(uri)).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          Fluttertoast.showToast(msg: "Connection Timeout.\nPlease try again.");
          return http.Response('Error', 408);
        },
      );

      if (response.statusCode == 200) {
        log('print Label Amazon response>>>>>${jsonDecode(response.body)}');

        labelUrl = '';
        labelUrl = jsonDecode(response.body)['LabelUrl'];
        log('labelUrl Amazon>>>>>$labelUrl');
      } else if (response.statusCode == 500) {
        log('print Label Amazon error response>>>>>${jsonDecode(response.body)}');

        labelError = '';
        labelError = (jsonDecode(response.body)['message']).toString();
        setState(() {});
        log('labelError Amazon>>>>>$labelError');
      } else {
        ToastUtils.showCenteredShortToast(message: kerrorString);
        labelError = '';
        labelError = kerrorString;
      }
    } catch (e) {
      log(e.toString());
    }
  }

  Future<void> printLabelOthers({required siteOrderId}) async {
    String siteOrderIdToSent = '';
    log('received siteOrderId>>>>>$siteOrderId');
    if (siteOrderId.toString().startsWith('#')) {
      setState(() {
        siteOrderIdToSent = siteOrderId.toString().replaceFirst('#', '%23');
      });
    } else {
      setState(() {
        siteOrderIdToSent = siteOrderId.toString();
      });
    }
    log('siteOrderIdToSent>>>>>$siteOrderIdToSent');

    String uri =
        'https://weblegs.info/EasyPost/api/EasyPost?OrderNumber=$siteOrderIdToSent';
    log('print Label Others uri>>>>>$uri');

    labelError = '';
    try {
      var response = await http.get(Uri.parse(uri)).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          Fluttertoast.showToast(msg: "Connection Timeout.\nPlease try again.");
          return http.Response('Error', 408);
        },
      );

      if (response.statusCode == 200) {
        log('print Label Others response>>>>>${jsonDecode(response.body)}');

        labelUrl = '';
        labelUrl = jsonDecode(response.body)['LabelUrl'];
        log('labelUrl Others>>>>>$labelUrl');
      } else if (response.statusCode == 500) {
        log('print Label Others error response>>>>>${jsonDecode(response.body)}');

        labelError = '';
        labelError = (jsonDecode(response.body)['message']).toString();
        setState(() {});
        log('labelError Others>>>>>$labelError');
      } else {
        ToastUtils.showCenteredShortToast(message: kerrorString);
        labelError = '';
        labelError = kerrorString;
      }
    } catch (e) {
      log(e.toString());
    }
  }

  Future<void> getOrdersByProductId({
    required String ean,
    required bool isFiltered,
  }) async {
    String uri =
        'https://weblegs.info/JadlamApp/api/JadlamOrder?EAN=$ean&IsFiltered=$isFiltered';
    log('Orders List uri>>>>>$uri');

    try {
      var response = await http.get(Uri.parse(uri)).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          Fluttertoast.showToast(msg: "Connection Timeout.\nPlease try again.");
          return http.Response('Error', 408);
        },
      );

      if (response.statusCode == 200) {
        log('get orders list response>>>>>${jsonDecode(response.body)}');

        orderValue = [];
        orderValue.addAll(jsonDecode(response.body)['Result']);
        log('orderValue>>>>>$orderValue');

        if (orderValue.isNotEmpty) {
          orderList = List.generate(
              orderValue.length, (index) => OrderModel('', '', '', '', '', ''));
          printController = List.generate(
              orderValue.length, (index) => RoundedLoadingButtonController());
          for (int i = 0; i < orderValue.length; i++) {
            orderList[i].orderId = orderValue[i]['OrderNumber'];
            orderList[i].createdDate = orderValue[i]['OrderDate'];
            orderList[i].siteName = orderValue[i]['SiteName'];
            orderList[i].shippingStatus = orderValue[i]['ShippingStatus'];
            orderList[i].siteOrderId = orderValue[i]['SiteOrderId'];
            orderList[i].account = orderValue[i]['Account'];
          }
          orderList.removeWhere((e) => e.account != 'Jadlam Racing - UK');
        }
      } else if (response.statusCode == 500) {
        ToastUtils.showCenteredShortToast(
            message: jsonDecode(response.body)['message']);
      } else {
        ToastUtils.showCenteredShortToast(message: kerrorString);
      }
    } on Exception catch (e) {
      log(e.toString());
      ToastUtils.showCenteredLongToast(message: e.toString());
    }
  }
}

class OrderModel {
  dynamic orderId;
  dynamic createdDate;
  dynamic siteName;
  dynamic shippingStatus;
  dynamic siteOrderId;
  dynamic account;

  OrderModel(
    this.orderId,
    this.createdDate,
    this.siteName,
    this.shippingStatus,
    this.siteOrderId,
    this.account,
  );
}
