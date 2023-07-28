import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:absolute_app/core/apis/api_calls.dart';
import 'package:absolute_app/core/utils/constants.dart';
import 'package:absolute_app/core/utils/navigation_methods.dart';
import 'package:absolute_app/core/utils/toast_utils.dart';
import 'package:absolute_app/core/utils/widgets.dart';
import 'package:absolute_app/models/get_pack_and_scan_response.dart';
import 'package:absolute_app/models/scanned_order_model.dart';
import 'package:absolute_app/screens/mobile_device_screens/barcode_camera_screen.dart';
import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_network/image_network.dart';
import 'package:parse_server_sdk/parse_server_sdk.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:http/http.dart' as http;
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:rounded_loading_button/rounded_loading_button.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

/// TO CHANGE THE PRINT METHOD TO USE LABEL URL INSTEAD OF BASE 64 IMAGE WHICH
/// IS USED FOR THE WEB APP.

class PackAndScan extends StatefulWidget {
  const PackAndScan({
    Key? key,
    required this.ean,
    required this.accType,
    required this.authorization,
    required this.refreshToken,
    required this.crossVisible,
    required this.screenType,
    required this.profileId,
    required this.distCenterId,
    required this.distCenterName,
    required this.barcodeToCheck,
  }) : super(key: key);

  final String ean;
  final String accType;
  final String authorization;
  final String refreshToken;
  final bool crossVisible;
  final String screenType;
  final int profileId;
  final int distCenterId;
  final String distCenterName;
  final int barcodeToCheck;

  @override
  State<PackAndScan> createState() => _PackAndScanState();
}

class _PackAndScanState extends State<PackAndScan> {
  List<RoundedLoadingButtonController> printController =
      <RoundedLoadingButtonController>[];
  RoundedLoadingButtonController printForMSMQWController =
      RoundedLoadingButtonController();
  final TextEditingController barcodeController = TextEditingController();
  final TextEditingController eanOrOrderController = TextEditingController();
  final TextEditingController selectedPicklistController =
      TextEditingController();

  List<Sku> orderListForPackAndScan = [];
  List<List<Sku>> orderListForPackAndScanBarcodeMSMQW = [];
  List<String> uniqueOrderNumberListForBarcodeMSMQWCase = [];
  List<List<Sku>> orderListForBarcodeMSMQWCase = [];
  List<ParseObject> labelDataPAndSDB = [];
  List<String> pickListTypes = ['SIW', 'SSMQW', 'MSMQW'];
  List<String> eanOrOrder = ['Barcode', 'Order Number'];
  List<String> orderNumberListForEmptyCase = [];
  List<String> eanListForOrderNumberCase = [];
  List<String> siteNameListForOrderNumberCase = [];
  List<bool> isAllSKUPicked = [];
  List<bool> isOrderSavedToDBForMSMQW = [];
  List<String> partiallyPickedOrdersForMSMQW = [];
  List<ScannedOrderModel> scannedOrdersList = [];
  List<ScannedOrderModel> scannedOrdersListToSave = [];

  bool isEmptyOnFirstSearch = false;
  bool isEmptyAfterFirstSearch = false;
  bool errorVisible = false;
  bool isPrintingLabel = false;
  bool isLoading = false;
  bool buttonLoading = false;
  bool showingPartialOrderTable = false;

  String printingLabel = 'Printing Label.........';
  String labelUrl = '';
  String labelError = '';
  String encryptedLabel = '';
  String selectedPicklist = 'SIW';
  String eanOrOrderSelected = 'Barcode';

  int serialNoDB = 0;

  @override
  void initState() {
    super.initState();
    setState(() {
      barcodeController.text = widget.ean;
    });
    initApiCallOuter();
  }

  Future<void> goToBarcodeScreen() async {
    setState(() {
      isEmptyOnFirstSearch = false;
      isEmptyAfterFirstSearch = false;
    });
    await Future.delayed(const Duration(milliseconds: 400), () {
      NavigationMethods.pushReplacement(
        context,
        BarcodeCameraScreen(
          accType: widget.accType,
          authorization: widget.authorization,
          refreshToken: widget.refreshToken,
          crossVisible: false,
          screenType: 'pack and scan',
          profileId: widget.profileId,
          distCenterName: widget.distCenterName,
          distCenterId: widget.distCenterId,
          barcodeToCheck: 0,
        ),
      );
    });
  }

  void initApiCallOuter() async {
    setState(() {
      isLoading = true;
    });
    await SharedPreferences.getInstance()
        .then((prefs) {
          setState(() {
            eanOrOrderController.text =
                prefs.getString('eanOrOrderNumber') ?? 'Barcode';
            eanOrOrderSelected =
                prefs.getString('eanOrOrderNumber') ?? 'Barcode';
            selectedPicklistController.text =
                prefs.getString('picklistType') ?? 'SIW';
            selectedPicklist = prefs.getString('picklistType') ?? 'SIW';
          });
        })
        .whenComplete(() => initApiCallInner())
        .whenComplete(() {
          if (barcodeController.text.length > 4) {
            apiCall();
          }
        });
  }

  void initApiCallInner() async {
    setState(() {
      isLoading = true;
    });

    await Future.delayed(const Duration(seconds: 1), () async {
      await (selectedPicklist == 'MSMQW'
              ? getScannedMSMQWOrders()
              : getScannedOrders())
          .whenComplete(() {
        /// THIS PART IS TO HANDLE THE CASE WHEN SEARCHED VIA ORDER NUMBER, THEN
        /// TO SAVE THAT ORDER ACCORDING TO ITS TYPE
        if (eanOrOrderSelected == 'Order Number') {
          /// SEARCHED VIA ORDER NUMBER FOR MSMQW IS PENDING HERE
          if (scannedOrdersList.length == 1) {
            /// SELECTED DATA HAD ONLY ONE ROW MEANS EITHER SIW OR SSMQW BUT NOT
            /// MSMQW CASE
            setState(() {
              selectedPicklist = parseToInt(scannedOrdersList[0].qtyToPick) == 1
                  ? 'SIW'
                  : 'SSMQW';
            });
          } else {
            if (scannedOrdersList[0].orderNumber ==
                scannedOrdersList[1].orderNumber) {
              /// IF ORDER NUMBER OF FIRST ROW MATCHES WITH ORDER NUMBER OF SECOND
              /// ROW, MEANS MSMQW CASE
              setState(() {
                selectedPicklist = 'MSMQW';
              });
            } else {
              setState(() {
                selectedPicklist =
                    parseToInt(scannedOrdersList[0].qtyToPick) == 1
                        ? 'SIW'
                        : 'SSMQW';
              });
            }
          }
        }
      }).whenComplete(() {
        if (scannedOrdersList
            .where((e) => e.picklistType == selectedPicklist)
            .toList()
            .isNotEmpty) {
          if (selectedPicklist != 'MSMQW') {
            printController = [];
            printController.addAll(List.generate(
                scannedOrdersList
                    .where((e) => e.picklistType == selectedPicklist)
                    .toList()
                    .length,
                (index) => RoundedLoadingButtonController()));
            log('LENGTH OF PRINT CONTROLLER LIST FOR SIW AND SSMQW >>---> ${printController.length}');
          }
        }
      });
    });
  }

  void apiCall() async {
    await getLabelDataPackAndScan().whenComplete(() async =>
        await Future.delayed(const Duration(milliseconds: 100), () async {
          if (eanOrOrderSelected == 'Order Number') {
            await getOrdersForPackAndScan(
              type: '',
              ean: '',
              orderNumber: barcodeController.text,
            );
          } else {
            await getOrdersForPackAndScan(
              type: selectedPicklist,
              ean: barcodeController.text,
              orderNumber: '',
            );
          }
        }).whenComplete(() async {
          setState(() {
            errorVisible = false;
          });
          if (eanOrOrderSelected == 'Barcode') {
            if (selectedPicklist == 'MSMQW') {
              if (orderListForPackAndScanBarcodeMSMQW.isNotEmpty) {
                if (isOrderSavedToDBForMSMQW[0] == true) {
                  if (isAllSKUPicked[0] == true) {
                    /// ORDER IS SAVED PREVIOUSLY AND ALL SKUs ARE PICKED NOW >>>> PRINT LABEL AND CHANGE THE LABEL FROM 'NA' TO ACTUAL LABEL IN THE DB
                    await labelPrinting().whenComplete(() async {
                      await Future.delayed(const Duration(seconds: 8), () {
                        log('init called MSMQW');
                        initApiCallInner();
                      });
                    });
                  }
                } else {
                  if (isAllSKUPicked[0] == true) {
                    /// ORDER IS NOT SAVED PREVIOUSLY AND ALL SKUs ARE PICKED >>>> PRINT LABEL AND SAVE THE LABEL TO THE DB
                    await labelPrinting().whenComplete(() async {
                      await Future.delayed(const Duration(seconds: 8), () {
                        log('init called MSMQW');
                        initApiCallInner();
                      });
                    });
                  } else {
                    /// ORDER IS NOT SAVED PREVIOUSLY AND ALL SKUs NOT PICKED >>>>>>>> SHOW MESSAGE AND SAVE 'NA' LABEL TO THE DB
                    saveLabelData(
                      serialNo: serialNoDB + 1,
                      isShippedOrder:
                          'Partial Picked MSMQW Order - Label Not Printed',
                      orderId:
                          orderListForPackAndScanBarcodeMSMQW[0][0].orderNumber,
                      ean: orderListForPackAndScanBarcodeMSMQW[0]
                          .map((e) => e.ean)
                          .toList()
                          .join(','),
                      siteName: orderListForPackAndScanBarcodeMSMQW[0]
                          .map((e) => e.siteName)
                          .toList()
                          .join(','),
                      siteOrderId:
                          orderListForPackAndScanBarcodeMSMQW[0][0].siteOrderId,
                      encryptedLabel: 'NA',
                    );

                    /// FOLLOWING SNIPPET IS FOR RESETTING SCREEN AFTER PARTIAL
                    /// PICKED ORDER WAS SCANNED.
                    /// CURRENTLY THIS FEATURE IS OFF.
                    // await Future.delayed(
                    //     Duration(
                    //       seconds:
                    //           orderListForPackAndScanBarcodeMSMQW[0].length > 4
                    //               ? 8
                    //               : 5,
                    //     ), () {
                    //   setState(() {
                    //     errorVisible = false;
                    //     showingPartialOrderTable = false;
                    //     isLoading = false;
                    //   });
                    //   barcodeController.clear();
                    //   FocusScope.of(context).requestFocus(barcodeFocus);
                    // });
                  }
                }
              }
            } else {
              if (orderListForPackAndScan.isNotEmpty) {
                await labelPrinting().whenComplete(() async {
                  await Future.delayed(const Duration(seconds: 6), () {
                    log('init called');
                    initApiCallInner();
                  });
                });
              }
            }
          } else {
            if (orderListForPackAndScan.isNotEmpty) {
              await labelPrinting().whenComplete(() async {
                await Future.delayed(const Duration(seconds: 6), () {
                  log('init called');
                  initApiCallInner();
                });
              });
            }
          }
        }));
  }

  Future<void> labelPrinting() async {
    setState(() {
      buttonLoading = true;
    });
    log('PRINT LABEL API START >>---> ${DateTime.now().toUtc().add(const Duration(hours: 1))}');
    await printLabel(
      siteOrderId:
          (eanOrOrderSelected == 'Barcode' && selectedPicklist == 'MSMQW')
              ? orderListForPackAndScanBarcodeMSMQW[0][0].siteOrderId
              : orderListForPackAndScan[0].siteOrderId,
      isAmazonPrime:
          ((eanOrOrderSelected == 'Barcode' && selectedPicklist == 'MSMQW')
                      ? orderListForPackAndScanBarcodeMSMQW[0][0].siteName
                      : orderListForPackAndScan[0].siteName) ==
                  'Amazon UK-prime'
              ? true
              : false,
    ).whenComplete(() async {
      if (labelError.isNotEmpty) {
        setState(() {
          isPrintingLabel = false;
        });
        Fluttertoast.showToast(msg: labelError).whenComplete(() async {
          setState(() {
            isLoading = true;
          });
          await Future.delayed(const Duration(milliseconds: 100), () {
            setState(() {
              errorVisible = true;
              isLoading = false;
            });
          }).whenComplete(() async {
            setState(() {
              buttonLoading = false;
            });
            if (labelError.contains('shipped') == true) {
              if (eanOrOrderSelected == 'Order Number') {
                saveLabelData(
                  serialNo: serialNoDB + 1,
                  isShippedOrder: 'Yes',
                  orderId: orderListForPackAndScan[0].orderNumber,
                  ean: eanListForOrderNumberCase.join(','),
                  siteName: siteNameListForOrderNumberCase.join(','),
                  siteOrderId: orderListForPackAndScan[0].siteOrderId,
                  encryptedLabel: 'NA',
                );

                /// ERROR IN LABEL AND ORDER NUMBER SELECTED CASE
                /// SAVING DATA FOR SHOWING LAST 5 SCANNED ORDER FOR SIW AND
                /// SSMQW ORDERS
                if (selectedPicklist == 'MSMQW') {
                  /// ADDED HANDLING FOR ORDER NUMBER -- LABEL ERROR -- MSMQW CASE
                  saveScannedOrdersForMSMQWData(
                    picklistType: 'MSMQW',
                    title: orderListForPackAndScan.map((e) => e.title).toList(),
                    sku: orderListForPackAndScan.map((e) => e.sku).toList(),
                    barcode: orderListForPackAndScan.map((e) => e.ean).toList(),
                    orderNumber: orderListForPackAndScan[0].orderNumber,
                    qtyToPick: orderListForPackAndScan
                        .map((e) => e.qtyToPick)
                        .toList(),
                    url: orderListForPackAndScan.map((e) => e.url).toList(),
                    siteOrderId: orderListForPackAndScan[0].siteOrderId,
                    siteName:
                        orderListForPackAndScan.map((e) => e.siteName).toList(),
                    labelError: labelError,
                    labelUrl: labelUrl,
                  );
                } else {
                  saveScannedOrdersData(
                    picklistType:
                        parseToInt(orderListForPackAndScan[0].qtyToPick) == 1
                            ? 'SIW'
                            : 'SSMQW',
                    title: orderListForPackAndScan[0].title,
                    sku: orderListForPackAndScan[0].sku,
                    barcode: orderListForPackAndScan[0].ean,
                    orderNumber: orderListForPackAndScan[0].orderNumber,
                    qtyToPick: orderListForPackAndScan[0].qtyToPick,
                    url: orderListForPackAndScan[0].url,
                    siteOrderId: orderListForPackAndScan[0].siteOrderId,
                    siteName: orderListForPackAndScan[0].siteName,
                    labelError: labelError,
                    labelUrl: labelUrl,
                    packagingType:
                        orderListForPackAndScan[0].packagingType.isEmpty
                            ? 'NA'
                            : orderListForPackAndScan[0].packagingType,
                  );
                }
              } else {
                if (selectedPicklist == 'MSMQW') {
                  saveLabelData(
                    serialNo: serialNoDB + 1,
                    isShippedOrder: 'Yes',
                    orderId:
                        orderListForPackAndScanBarcodeMSMQW[0][0].orderNumber,
                    ean: orderListForPackAndScanBarcodeMSMQW[0]
                        .map((e) => e.ean)
                        .toList()
                        .join(','),
                    siteName: orderListForPackAndScanBarcodeMSMQW[0]
                        .map((e) => e.siteName)
                        .toList()
                        .join(','),
                    siteOrderId:
                        orderListForPackAndScanBarcodeMSMQW[0][0].siteOrderId,
                    encryptedLabel: 'NA',
                  );

                  /// ADDED HANDLING FOR BARCODE -- LABEL ERROR -- MSMQW CASE
                  saveScannedOrdersForMSMQWData(
                    picklistType: 'MSMQW',
                    title: orderListForPackAndScanBarcodeMSMQW[0]
                        .map((e) => e.title)
                        .toList(),
                    sku: orderListForPackAndScanBarcodeMSMQW[0]
                        .map((e) => e.sku)
                        .toList(),
                    barcode: orderListForPackAndScanBarcodeMSMQW[0]
                        .map((e) => e.ean)
                        .toList(),
                    orderNumber:
                        orderListForPackAndScanBarcodeMSMQW[0][0].orderNumber,
                    qtyToPick: orderListForPackAndScanBarcodeMSMQW[0]
                        .map((e) => e.qtyToPick)
                        .toList(),
                    url: orderListForPackAndScanBarcodeMSMQW[0]
                        .map((e) => e.url)
                        .toList(),
                    siteOrderId:
                        orderListForPackAndScanBarcodeMSMQW[0][0].siteOrderId,
                    siteName: orderListForPackAndScanBarcodeMSMQW[0]
                        .map((e) => e.siteName)
                        .toList(),
                    labelError: labelError,
                    labelUrl: labelUrl,
                  );
                } else {
                  saveLabelData(
                    serialNo: serialNoDB + 1,
                    isShippedOrder: 'Yes',
                    orderId: orderListForPackAndScan[0].orderNumber,
                    ean: orderListForPackAndScan[0].ean,
                    siteName: orderListForPackAndScan[0].siteName,
                    siteOrderId: orderListForPackAndScan[0].siteOrderId,
                    encryptedLabel: 'NA',
                  );

                  /// ERROR IN LABEL AND BARCODE SELECTED CASE
                  /// SAVING DATA FOR SHOWING LAST 5 SCANNED ORDER FOR SIW AND
                  /// SSMQW ORDERS
                  saveScannedOrdersData(
                    picklistType: selectedPicklist,
                    title: orderListForPackAndScan[0].title,
                    sku: orderListForPackAndScan[0].sku,
                    barcode: orderListForPackAndScan[0].ean,
                    orderNumber: orderListForPackAndScan[0].orderNumber,
                    qtyToPick: orderListForPackAndScan[0].qtyToPick,
                    url: orderListForPackAndScan[0].url,
                    siteOrderId: orderListForPackAndScan[0].siteOrderId,
                    siteName: orderListForPackAndScan[0].siteName,
                    labelError: labelError,
                    labelUrl: labelUrl,
                    packagingType:
                        orderListForPackAndScan[0].packagingType.isEmpty
                            ? 'NA'
                            : orderListForPackAndScan[0].packagingType,
                  );
                }
              }
            }
            await Future.delayed(
                Duration(seconds: labelError.length >= 60 ? 8 : 3), () async {
              setState(() {
                errorVisible = false;
                orderListForPackAndScan = [];
                orderListForPackAndScanBarcodeMSMQW = [];
                isLoading = false;
              });
              barcodeController.clear();
              await goToBarcodeScreen();
            });
          });
        });
      } else {
        setState(() {
          isPrintingLabel = true;
        });
        await Future.delayed(const Duration(milliseconds: 100), () {
          log('${DateTime.now().toUtc().add(const Duration(hours: 1))}');
          print(labelUrl).whenComplete(() async {
            await Future.delayed(const Duration(milliseconds: 100), () async {
              setState(() {
                buttonLoading = false;
                isLoading = true;
                isPrintingLabel = false;
              });

              const encryptionKey = "This 32 char key have 256 bits..";

              encrypt.Encrypted encrypted =
                  encryptWithAES(encryptionKey, labelUrl);
              String encryptedBase64 = encrypted.base64;
              log('Encrypted data in base64 encoding: $encryptedBase64');
              setState(() {
                encryptedLabel = encryptedBase64;
              });

              String decryptedText = decryptWithAES(encryptionKey, encrypted);
              log('Decrypted data: $decryptedText');

              await Future.delayed(const Duration(milliseconds: 100), () async {
                if (eanOrOrderSelected == 'Order Number') {
                  saveLabelData(
                    serialNo: serialNoDB + 1,
                    isShippedOrder: 'No',
                    orderId: orderListForPackAndScan[0].orderNumber,
                    ean: eanListForOrderNumberCase.join(','),
                    siteName: siteNameListForOrderNumberCase.join(','),
                    siteOrderId: orderListForPackAndScan[0].siteOrderId,
                    encryptedLabel: encryptedLabel,
                  );

                  if (selectedPicklist == 'MSMQW') {
                    /// ADDED HANDLING FOR ORDER NUMBER -- LABEL PRINTED -- MSMQW CASE
                    saveScannedOrdersForMSMQWData(
                      picklistType: 'MSMQW',
                      title:
                          orderListForPackAndScan.map((e) => e.title).toList(),
                      sku: orderListForPackAndScan.map((e) => e.sku).toList(),
                      barcode:
                          orderListForPackAndScan.map((e) => e.ean).toList(),
                      orderNumber: orderListForPackAndScan[0].orderNumber,
                      qtyToPick: orderListForPackAndScan
                          .map((e) => e.qtyToPick)
                          .toList(),
                      url: orderListForPackAndScan.map((e) => e.url).toList(),
                      siteOrderId: orderListForPackAndScan[0].siteOrderId,
                      siteName: orderListForPackAndScan
                          .map((e) => e.siteName)
                          .toList(),
                      labelError: labelError,
                      labelUrl: labelUrl,
                    );
                  } else {
                    /// ORDER NUMBER SELECTED CASE
                    /// SAVING DATA FOR SHOWING LAST 5 SCANNED ORDER FOR SIW AND
                    /// SSMQW ORDERS
                    saveScannedOrdersData(
                      picklistType:
                          parseToInt(orderListForPackAndScan[0].qtyToPick) == 1
                              ? 'SIW'
                              : 'SSMQW',
                      title: orderListForPackAndScan[0].title,
                      sku: orderListForPackAndScan[0].sku,
                      barcode: orderListForPackAndScan[0].ean,
                      orderNumber: orderListForPackAndScan[0].orderNumber,
                      qtyToPick: orderListForPackAndScan[0].qtyToPick,
                      url: orderListForPackAndScan[0].url,
                      siteOrderId: orderListForPackAndScan[0].siteOrderId,
                      siteName: orderListForPackAndScan[0].siteName,
                      labelError: '',
                      labelUrl: labelUrl,
                      packagingType:
                          orderListForPackAndScan[0].packagingType.isEmpty
                              ? 'NA'
                              : orderListForPackAndScan[0].packagingType,
                    );
                  }
                } else {
                  if (selectedPicklist == 'MSMQW') {
                    if (isOrderSavedToDBForMSMQW[0] == true &&
                        isAllSKUPicked[0] == true) {
                      /// ORDER IS SAVED PREVIOUSLY AND ALL SKUs ARE PICKED NOW >>>> PRINT LABEL AND CHANGE THE LABEL FROM 'NA' TO ACTUAL LABEL IN THE DB
                      updateLabelData(
                        objectId: labelDataPAndSDB[labelDataPAndSDB.indexWhere(
                                    (e) =>
                                        (e.get<String>('order_id') ?? '') ==
                                        orderListForPackAndScanBarcodeMSMQW[0]
                                                [0]
                                            .orderNumber)]
                                .get<String>('objectId') ??
                            '',
                        isShippedOrder:
                            'Was Partial Picked MSMQW Order - Label Printed Now',
                        encryptedLabel: encryptedLabel,
                      );
                    }

                    if (isOrderSavedToDBForMSMQW[0] == false &&
                        isAllSKUPicked[0] == true) {
                      /// ORDER IS NOT SAVED PREVIOUSLY AND ALL SKUs ARE PICKED >>>> PRINT LABEL AND SAVE THE LABEL TO THE DB
                      saveLabelData(
                        serialNo: serialNoDB + 1,
                        isShippedOrder: 'No',
                        orderId: orderListForPackAndScanBarcodeMSMQW[0][0]
                            .orderNumber,
                        ean: orderListForPackAndScanBarcodeMSMQW[0]
                            .map((e) => e.ean)
                            .toList()
                            .join(','),
                        siteName: orderListForPackAndScanBarcodeMSMQW[0]
                            .map((e) => e.siteName)
                            .toList()
                            .join(','),
                        siteOrderId: orderListForPackAndScanBarcodeMSMQW[0][0]
                            .siteOrderId,
                        encryptedLabel: encryptedLabel,
                      );
                    }

                    /// ADD HANDLING FOR BARCODE -- LABEL PRINTED -- MSMQW CASE
                    saveScannedOrdersForMSMQWData(
                      picklistType: 'MSMQW',
                      title: orderListForPackAndScanBarcodeMSMQW[0]
                          .map((e) => e.title)
                          .toList(),
                      sku: orderListForPackAndScanBarcodeMSMQW[0]
                          .map((e) => e.sku)
                          .toList(),
                      barcode: orderListForPackAndScanBarcodeMSMQW[0]
                          .map((e) => e.ean)
                          .toList(),
                      orderNumber:
                          orderListForPackAndScanBarcodeMSMQW[0][0].orderNumber,
                      qtyToPick: orderListForPackAndScanBarcodeMSMQW[0]
                          .map((e) => e.qtyToPick)
                          .toList(),
                      url: orderListForPackAndScanBarcodeMSMQW[0]
                          .map((e) => e.url)
                          .toList(),
                      siteOrderId:
                          orderListForPackAndScanBarcodeMSMQW[0][0].siteOrderId,
                      siteName: orderListForPackAndScanBarcodeMSMQW[0]
                          .map((e) => e.siteName)
                          .toList(),
                      labelError: labelError,
                      labelUrl: labelUrl,
                    );
                  } else {
                    saveLabelData(
                      serialNo: serialNoDB + 1,
                      isShippedOrder: 'No',
                      orderId: orderListForPackAndScan[0].orderNumber,
                      ean: orderListForPackAndScan[0].ean,
                      siteName: orderListForPackAndScan[0].siteName,
                      siteOrderId: orderListForPackAndScan[0].siteOrderId,
                      encryptedLabel: encryptedLabel,
                    );

                    /// BARCODE SELECTED CASE
                    /// SAVING DATA FOR SHOWING LAST 5 SCANNED ORDER FOR SIW
                    /// AND SSMQW ORDERS
                    saveScannedOrdersData(
                      picklistType: selectedPicklist,
                      title: orderListForPackAndScan[0].title,
                      sku: orderListForPackAndScan[0].sku,
                      barcode: orderListForPackAndScan[0].ean,
                      orderNumber: orderListForPackAndScan[0].orderNumber,
                      qtyToPick: orderListForPackAndScan[0].qtyToPick,
                      url: orderListForPackAndScan[0].url,
                      siteOrderId: orderListForPackAndScan[0].siteOrderId,
                      siteName: orderListForPackAndScan[0].siteName,
                      labelError: '',
                      labelUrl: labelUrl,
                      packagingType:
                          orderListForPackAndScan[0].packagingType.isEmpty
                              ? 'NA'
                              : orderListForPackAndScan[0].packagingType,
                    );
                  }
                }
                setState(() {
                  errorVisible = false;
                  orderListForPackAndScan = [];
                  orderListForPackAndScanBarcodeMSMQW = [];
                  isLoading = false;
                });
                barcodeController.clear();
                await goToBarcodeScreen();
              });
            });
          });
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    FocusScopeNode currentFocus = FocusScope.of(context);
    return Scaffold(
      backgroundColor: Colors.grey[100],
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.white,
        automaticallyImplyLeading: true,
        iconTheme: const IconThemeData(color: Colors.black),
        centerTitle: true,
        toolbarHeight: AppBar().preferredSize.height,
        elevation: 5,
        title: const Text(
          'Pack & Scan',
          style: TextStyle(
            fontSize: 25,
            color: Colors.black,
          ),
        ),
      ),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).requestFocus(FocusNode());
          if (!currentFocus.hasPrimaryFocus) {
            currentFocus.unfocus();
          }
        },
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: size.width * .01),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(top: size.width * .01),
                  child: SizedBox(
                    height: 50,
                    width: size.width,
                    child: Row(
                      children: [
                        Padding(
                          padding: EdgeInsets.only(left: size.width * .015),
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width * .5,
                            child: CustomDropdown(
                              items: eanOrOrder,
                              controller: eanOrOrderController,
                              hintText: '',
                              selectedStyle: const TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                              ),
                              borderRadius: BorderRadius.circular(5),
                              borderSide: BorderSide(
                                color: Colors.grey[700]!,
                                width: 1,
                              ),
                              excludeSelected: true,
                              onChanged: (_) {
                                setState(() {
                                  eanOrOrderSelected =
                                      eanOrOrderController.text;
                                });
                                log('V eanOrOrderController.text >>---> ${eanOrOrderController.text}');
                                log('V eanOrOrderSelected >>---> $eanOrOrderSelected');
                                if (barcodeController.text.length > 4) {
                                  apiCall();
                                }
                              },
                            ),
                          ),
                        ),
                        SizedBox(
                          width: MediaQuery.of(context).size.width * .45,
                          child: Visibility(
                            visible: eanOrOrderSelected == 'Barcode',
                            child: CustomDropdown(
                              items: pickListTypes,
                              controller: selectedPicklistController,
                              hintText: '',
                              selectedStyle: const TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                              ),
                              borderRadius: BorderRadius.circular(5),
                              borderSide: BorderSide(
                                color: Colors.grey[700]!,
                                width: 1,
                              ),
                              excludeSelected: true,
                              onChanged: (_) {
                                setState(() {
                                  selectedPicklist =
                                      selectedPicklistController.text;
                                });
                                log('V selectedPicklistController.text >>---> ${selectedPicklistController.text}');
                                log('V selectedPicklist >>---> $selectedPicklist');
                                if (barcodeController.text.length > 4) {
                                  apiCall();
                                } else {
                                  initApiCallInner();
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(top: size.height * .01),
                  child: SizedBox(
                    height: 50,
                    width: size.width * .95,
                    child: TextFormField(
                      controller: barcodeController,
                      style: const TextStyle(
                        fontSize: 16,
                      ),
                      decoration: InputDecoration(
                        hintText: eanOrOrderSelected == 'Barcode'
                            ? 'Product Barcode'
                            : 'Order Number',
                        hintStyle: const TextStyle(
                          fontSize: 16,
                        ),
                        contentPadding: const EdgeInsets.all(5),
                        border: const OutlineInputBorder(
                          borderSide: BorderSide(width: 0.5),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.black,
                            width: 1,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        suffixIcon: Visibility(
                          visible: barcodeController.text.isNotEmpty,
                          child: IconButton(
                            onPressed: () {
                              barcodeController.clear();
                              setState(() {
                                isEmptyOnFirstSearch = false;
                                isEmptyAfterFirstSearch = false;
                              });
                              if (selectedPicklist == "MSMQW") {
                                setState(() {
                                  errorVisible = false;
                                  showingPartialOrderTable = false;
                                  orderListForPackAndScanBarcodeMSMQW = [];
                                });
                                initApiCallInner();
                              }
                            },
                            icon: const Icon(
                              Icons.close,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                      onChanged: (_) {
                        setState(() {
                          isEmptyOnFirstSearch = false;
                          isEmptyAfterFirstSearch = false;
                        });
                        if (barcodeController.text.length > 4) {
                          log('PACK AND SCAN START >>---> ${DateTime.now().toUtc().add(const Duration(hours: 1))}');
                          apiCall();
                        }
                      },
                    ),
                  ),
                ),
                isLoading == true
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: appColor,
                        ),
                      )
                    : (eanOrOrderSelected == 'Barcode' &&
                                    selectedPicklist == 'MSMQW'
                                ? orderListForPackAndScanBarcodeMSMQW
                                : orderListForPackAndScan)
                            .isEmpty
                        ? isEmptyOnFirstSearch == true
                            ? SizedBox(
                                height: 200,
                                width: size.width * .8,
                                child: const Center(
                                  child: Text(
                                    'No Orders Found!',
                                    style: TextStyle(
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                              )
                            : isEmptyAfterFirstSearch == true
                                ? SizedBox(
                                    height: 200,
                                    width: size.width * .8,
                                    child: eanOrOrderSelected == 'Barcode' &&
                                            selectedPicklist == 'MSMQW'
                                        ? Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  SelectableText(
                                                    partiallyPickedOrdersForMSMQW
                                                            .toSet()
                                                            .toList()
                                                            .isNotEmpty
                                                        ? partiallyPickedOrdersForMSMQW
                                                                    .toSet()
                                                                    .toList()
                                                                    .length >
                                                                1
                                                            ? 'Orders '
                                                            : 'Order '
                                                        : 'Label Printed Already for Order ${orderListForBarcodeMSMQWCase.map((e) => e[0].orderNumber).toList().length > 1 ? 'Numbers' : 'Number'}',
                                                    style: const TextStyle(
                                                      fontSize: 18,
                                                    ),
                                                  ),
                                                  SelectableText(
                                                    partiallyPickedOrdersForMSMQW
                                                            .toSet()
                                                            .toList()
                                                            .isNotEmpty
                                                        ? partiallyPickedOrdersForMSMQW
                                                            .toSet()
                                                            .toList()
                                                            .join(', ')
                                                        : orderListForBarcodeMSMQWCase
                                                            .map((e) => e[0]
                                                                .orderNumber)
                                                            .toList()
                                                            .join(', '),
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 18,
                                                    ),
                                                  ),
                                                  SelectableText(
                                                    partiallyPickedOrdersForMSMQW
                                                            .toSet()
                                                            .toList()
                                                            .isNotEmpty
                                                        ? ' have partially picked SKUs'
                                                        : '',
                                                    style: const TextStyle(
                                                      fontSize: 18,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          )
                                        : Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  SelectableText(
                                                    'Label Printed Already for Order ${orderNumberListForEmptyCase.length > 1 ? 'Numbers' : 'Number'}',
                                                    style: const TextStyle(
                                                      fontSize: 18,
                                                    ),
                                                  ),
                                                  SelectableText(
                                                    orderNumberListForEmptyCase
                                                        .join(', '),
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 18,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                  )

                                /// isLoading, isEmptyOnFirstSearch,
                                /// isEmptyAfterFirstSearch ALL VALUES ARE FALSE
                                /// MEANS PACK AND SCAN IS NOT WORKING CURRENTLY
                                /// SHOW LAST 5 ORDERS FOR SIW AND SSMQW PICKLIST
                                /// AND LAST 1 ORDER FOR MSMQW PICKLIST
                                : selectedPicklist == 'MSMQW'
                                    ? Visibility(
                                        visible: scannedOrdersList
                                            .where((e) =>
                                                e.picklistType == 'MSMQW')
                                            .toList()
                                            .isNotEmpty,
                                        child: _msmqwScanOffBuilder(
                                          context,
                                          size,
                                        ),
                                      )
                                    : Visibility(
                                        visible: scannedOrdersList
                                            .where((e) =>
                                                e.picklistType ==
                                                selectedPicklist)
                                            .toList()
                                            .isNotEmpty,
                                        child: _siwAndSSMQWScanOffBuilder(
                                          context,
                                          size,
                                        ),
                                      )
                        : Padding(
                            padding: EdgeInsets.only(top: size.width * .025),
                            child: Center(
                              child: eanOrOrderSelected == 'Barcode'
                                  ? selectedPicklist == 'MSMQW'
                                      ? (parseToInt(
                                                  orderListForPackAndScanBarcodeMSMQW[0]
                                                          [0]
                                                      .totalSkUs
                                                      .toString()) ==
                                              parseToInt(
                                                  orderListForPackAndScanBarcodeMSMQW[0]
                                                          [0]
                                                      .pickedSkUs
                                                      .toString()))
                                          ? Table(
                                              border: TableBorder.all(
                                                color: Colors.black,
                                                width: 1,
                                              ),
                                              columnWidths: {
                                                0: FixedColumnWidth(
                                                    size.width * .55),
                                                1: FixedColumnWidth(
                                                    size.width * .1),
                                                2: FixedColumnWidth(
                                                    size.width * .2),
                                                3: FixedColumnWidth(
                                                    size.width * .1),
                                              },
                                              children: [
                                                TableRow(
                                                  children: <TableCell>[
                                                    TableCell(
                                                      child: Container(
                                                        height: 50,
                                                        color: Colors
                                                            .grey.shade200,
                                                        child: const Center(
                                                          child: Text(
                                                              'Order Details'),
                                                        ),
                                                      ),
                                                    ),
                                                    TableCell(
                                                      child: Container(
                                                        height: 50,
                                                        color: Colors
                                                            .grey.shade200,
                                                        child: const Center(
                                                          child: Text('QTY'),
                                                        ),
                                                      ),
                                                    ),
                                                    TableCell(
                                                      child: Container(
                                                        height: 50,
                                                        color: Colors
                                                            .grey.shade200,
                                                        child: const Center(
                                                          child: Text('Image'),
                                                        ),
                                                      ),
                                                    ),
                                                    TableCell(
                                                      child: Container(
                                                        height: 50,
                                                        color: Colors
                                                            .grey.shade200,
                                                        child: const Center(
                                                          child:
                                                              Text('Is Picked'),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                ...List.generate(
                                                    orderListForPackAndScanBarcodeMSMQW[
                                                            0]
                                                        .length,
                                                    (index) => TableRow(
                                                            children: <
                                                                TableCell>[
                                                              TableCell(
                                                                child: SizedBox(
                                                                  height: 120,
                                                                  child:
                                                                      Padding(
                                                                    padding: const EdgeInsets
                                                                            .all(
                                                                        10.0),
                                                                    child: Column(
                                                                        children: [
                                                                          Row(
                                                                            children: [
                                                                              const SelectableText(
                                                                                'Name : ',
                                                                                style: TextStyle(
                                                                                  fontWeight: FontWeight.bold,
                                                                                ),
                                                                              ),
                                                                              Flexible(
                                                                                child: SelectableText(
                                                                                  orderListForPackAndScanBarcodeMSMQW[0][index].title,
                                                                                  style: const TextStyle(
                                                                                    overflow: TextOverflow.visible,
                                                                                  ),
                                                                                ),
                                                                              )
                                                                            ],
                                                                          ),
                                                                          const SizedBox(
                                                                            height:
                                                                                10,
                                                                          ),
                                                                          Row(
                                                                            children: [
                                                                              const SelectableText(
                                                                                'SKU : ',
                                                                                style: TextStyle(
                                                                                  fontWeight: FontWeight.bold,
                                                                                ),
                                                                              ),
                                                                              SelectableText(
                                                                                orderListForPackAndScanBarcodeMSMQW[0][index].sku,
                                                                              )
                                                                            ],
                                                                          ),
                                                                          const SizedBox(
                                                                            height:
                                                                                10,
                                                                          ),
                                                                          Row(
                                                                            children: [
                                                                              const SelectableText(
                                                                                'Barcode : ',
                                                                                style: TextStyle(fontWeight: FontWeight.bold),
                                                                              ),
                                                                              SelectableText(
                                                                                orderListForPackAndScanBarcodeMSMQW[0][index].ean,
                                                                              )
                                                                            ],
                                                                          ),
                                                                          const SizedBox(
                                                                            height:
                                                                                10,
                                                                          ),
                                                                          Row(
                                                                            children: [
                                                                              const SelectableText(
                                                                                'Order Number : ',
                                                                                style: TextStyle(fontWeight: FontWeight.bold),
                                                                              ),
                                                                              SelectableText(
                                                                                orderListForPackAndScanBarcodeMSMQW[0][index].orderNumber,
                                                                              )
                                                                            ],
                                                                          )
                                                                        ]),
                                                                  ),
                                                                ),
                                                              ),
                                                              TableCell(
                                                                child: SizedBox(
                                                                  height: 120,
                                                                  child: Center(
                                                                    child:
                                                                        SelectableText(
                                                                      orderListForPackAndScanBarcodeMSMQW[0]
                                                                              [
                                                                              index]
                                                                          .qtyToPick,
                                                                      style: const TextStyle(
                                                                          fontSize:
                                                                              25,
                                                                          fontWeight:
                                                                              FontWeight.bold),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                              TableCell(
                                                                child: SizedBox(
                                                                  height: 115,
                                                                  width: 115,
                                                                  child: Center(
                                                                    child: orderListForPackAndScanBarcodeMSMQW[0][index]
                                                                            .url
                                                                            .isEmpty
                                                                        ? Image
                                                                            .asset(
                                                                            'assets/no_image/no_image.png',
                                                                            height:
                                                                                115,
                                                                            width:
                                                                                115,
                                                                            fit:
                                                                                BoxFit.contain,
                                                                          )
                                                                        : ImageNetwork(
                                                                            image:
                                                                                orderListForPackAndScanBarcodeMSMQW[0][index].url,
                                                                            height:
                                                                                115,
                                                                            width:
                                                                                115,
                                                                            duration:
                                                                                100,
                                                                            fitAndroidIos:
                                                                                BoxFit.contain,
                                                                            fitWeb:
                                                                                BoxFitWeb.contain,
                                                                            onLoading:
                                                                                Shimmer(
                                                                              duration: const Duration(seconds: 2),
                                                                              colorOpacity: 1,
                                                                              child: Container(
                                                                                decoration: const BoxDecoration(
                                                                                  color: Color.fromARGB(160, 192, 192, 192),
                                                                                ),
                                                                              ),
                                                                            ),
                                                                            onError:
                                                                                Image.asset(
                                                                              'assets/no_image/no_image.png',
                                                                              height: 115,
                                                                              width: 115,
                                                                              fit: BoxFit.contain,
                                                                            ),
                                                                          ),
                                                                  ),
                                                                ),
                                                              ),
                                                              TableCell(
                                                                child: SizedBox(
                                                                  height: 120,
                                                                  child: Center(
                                                                    child: SelectableText(
                                                                        orderListForPackAndScanBarcodeMSMQW[0][index].isPicked == 'true'
                                                                            ? 'Yes'
                                                                            : 'No',
                                                                        style: const TextStyle(
                                                                            fontSize:
                                                                                22,
                                                                            fontWeight:
                                                                                FontWeight.bold)),
                                                                  ),
                                                                ),
                                                              ),
                                                            ]))
                                              ],
                                            )
                                          : Visibility(
                                              visible:
                                                  showingPartialOrderTable ==
                                                      true,
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      SelectableText(
                                                        'Only ${parseToInt(orderListForPackAndScanBarcodeMSMQW[0][0].pickedSkUs.toString())} ${(parseToInt(orderListForPackAndScanBarcodeMSMQW[0][0].pickedSkUs.toString()) > 1) ? 'SKUs are' : 'SKU is'} picked out of total ${parseToInt(orderListForPackAndScanBarcodeMSMQW[0][0].totalSkUs.toString())} SKUs in Order ',
                                                        style: const TextStyle(
                                                          fontSize: 18,
                                                        ),
                                                      ),
                                                      SelectableText(
                                                        orderListForPackAndScanBarcodeMSMQW[
                                                                0][0]
                                                            .orderNumber,
                                                        style: const TextStyle(
                                                          fontSize: 18,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            top: 15),
                                                    child: Table(
                                                        border: TableBorder.all(
                                                            color: Colors.black,
                                                            width: 1),
                                                        columnWidths: <int,
                                                            TableColumnWidth>{
                                                          0: FixedColumnWidth(
                                                              size.width * .55),
                                                          1: FixedColumnWidth(
                                                              size.width * .1),
                                                          2: FixedColumnWidth(
                                                              size.width * .2),
                                                          3: FixedColumnWidth(
                                                              size.width * .1),
                                                        },
                                                        children: [
                                                          TableRow(
                                                            children: <
                                                                TableCell>[
                                                              TableCell(
                                                                child:
                                                                    Container(
                                                                  height: 50,
                                                                  color: Colors
                                                                      .grey
                                                                      .shade200,
                                                                  child:
                                                                      const Center(
                                                                    child: Text(
                                                                        'Order Details'),
                                                                  ),
                                                                ),
                                                              ),
                                                              TableCell(
                                                                child:
                                                                    Container(
                                                                  height: 50,
                                                                  color: Colors
                                                                      .grey
                                                                      .shade200,
                                                                  child:
                                                                      const Center(
                                                                    child: Text(
                                                                        'QTY'),
                                                                  ),
                                                                ),
                                                              ),
                                                              TableCell(
                                                                child:
                                                                    Container(
                                                                  height: 50,
                                                                  color: Colors
                                                                      .grey
                                                                      .shade200,
                                                                  child:
                                                                      const Center(
                                                                    child: Text(
                                                                        'Image'),
                                                                  ),
                                                                ),
                                                              ),
                                                              TableCell(
                                                                child:
                                                                    Container(
                                                                  height: 50,
                                                                  color: Colors
                                                                      .grey
                                                                      .shade200,
                                                                  child:
                                                                      const Center(
                                                                    child: Text(
                                                                        'Is Picked'),
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          ...List.generate(
                                                              orderListForPackAndScanBarcodeMSMQW[
                                                                      0]
                                                                  .length,
                                                              (index) =>
                                                                  TableRow(
                                                                      children: <
                                                                          TableCell>[
                                                                        TableCell(
                                                                          child:
                                                                              SizedBox(
                                                                            height:
                                                                                120,
                                                                            child:
                                                                                Padding(
                                                                              padding: const EdgeInsets.all(10.0),
                                                                              child: Column(children: [
                                                                                Row(
                                                                                  children: [
                                                                                    const SelectableText(
                                                                                      'Name : ',
                                                                                      style: TextStyle(
                                                                                        fontWeight: FontWeight.bold,
                                                                                      ),
                                                                                    ),
                                                                                    Flexible(
                                                                                      child: SelectableText(
                                                                                        orderListForPackAndScanBarcodeMSMQW[0][index].title,
                                                                                        style: const TextStyle(
                                                                                          overflow: TextOverflow.visible,
                                                                                        ),
                                                                                      ),
                                                                                    )
                                                                                  ],
                                                                                ),
                                                                                const SizedBox(
                                                                                  height: 10,
                                                                                ),
                                                                                Row(
                                                                                  children: [
                                                                                    const SelectableText(
                                                                                      'SKU : ',
                                                                                      style: TextStyle(
                                                                                        fontWeight: FontWeight.bold,
                                                                                      ),
                                                                                    ),
                                                                                    SelectableText(
                                                                                      orderListForPackAndScanBarcodeMSMQW[0][index].sku,
                                                                                    )
                                                                                  ],
                                                                                ),
                                                                                const SizedBox(
                                                                                  height: 10,
                                                                                ),
                                                                                Row(
                                                                                  children: [
                                                                                    const SelectableText(
                                                                                      'Barcode : ',
                                                                                      style: TextStyle(fontWeight: FontWeight.bold),
                                                                                    ),
                                                                                    SelectableText(
                                                                                      orderListForPackAndScanBarcodeMSMQW[0][index].ean.isEmpty ? 'NA' : orderListForPackAndScanBarcodeMSMQW[0][index].ean,
                                                                                    )
                                                                                  ],
                                                                                ),
                                                                                const SizedBox(
                                                                                  height: 10,
                                                                                ),
                                                                                Row(
                                                                                  children: [
                                                                                    const SelectableText(
                                                                                      'Order Number : ',
                                                                                      style: TextStyle(fontWeight: FontWeight.bold),
                                                                                    ),
                                                                                    SelectableText(
                                                                                      orderListForPackAndScanBarcodeMSMQW[0][index].orderNumber,
                                                                                    )
                                                                                  ],
                                                                                )
                                                                              ]),
                                                                            ),
                                                                          ),
                                                                        ),
                                                                        TableCell(
                                                                          child:
                                                                              SizedBox(
                                                                            height:
                                                                                120,
                                                                            child:
                                                                                Center(
                                                                              child: SelectableText(
                                                                                orderListForPackAndScanBarcodeMSMQW[0][index].qtyToPick,
                                                                                style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                                                                              ),
                                                                            ),
                                                                          ),
                                                                        ),
                                                                        TableCell(
                                                                          child:
                                                                              SizedBox(
                                                                            height:
                                                                                115,
                                                                            width:
                                                                                115,
                                                                            child:
                                                                                Center(
                                                                              child: orderListForPackAndScanBarcodeMSMQW[0][index].url.isEmpty
                                                                                  ? Image.asset(
                                                                                      'assets/no_image/no_image.png',
                                                                                      height: 115,
                                                                                      width: 115,
                                                                                      fit: BoxFit.contain,
                                                                                    )
                                                                                  : ImageNetwork(
                                                                                      image: orderListForPackAndScanBarcodeMSMQW[0][index].url,
                                                                                      height: 115,
                                                                                      width: 115,
                                                                                      duration: 100,
                                                                                      fitAndroidIos: BoxFit.contain,
                                                                                      fitWeb: BoxFitWeb.contain,
                                                                                      onLoading: Shimmer(
                                                                                        duration: const Duration(seconds: 2),
                                                                                        colorOpacity: 1,
                                                                                        child: Container(
                                                                                          decoration: const BoxDecoration(
                                                                                            color: Color.fromARGB(160, 192, 192, 192),
                                                                                          ),
                                                                                        ),
                                                                                      ),
                                                                                      onError: Image.asset(
                                                                                        'assets/no_image/no_image.png',
                                                                                        height: 115,
                                                                                        width: 115,
                                                                                        fit: BoxFit.contain,
                                                                                      ),
                                                                                    ),
                                                                            ),
                                                                          ),
                                                                        ),
                                                                        TableCell(
                                                                          child:
                                                                              SizedBox(
                                                                            height:
                                                                                120,
                                                                            child:
                                                                                Center(
                                                                              child: SelectableText(
                                                                                orderListForPackAndScanBarcodeMSMQW[0][index].isPicked == 'true' ? 'Yes' : 'No',
                                                                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                                                                              ),
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      ]))
                                                        ]),
                                                  )
                                                ],
                                              ),
                                            )
                                      : selectedPicklist == 'SIW'
                                          ? Table(
                                              border: TableBorder.all(
                                                  color: Colors.black,
                                                  width: 1),
                                              columnWidths: <int,
                                                  TableColumnWidth>{
                                                  0: FixedColumnWidth(
                                                      size.width * .45),
                                                  1: FixedColumnWidth(
                                                      size.width * .1),
                                                  2: FixedColumnWidth(
                                                      size.width * .1),
                                                  3: FixedColumnWidth(
                                                      size.width * .3),
                                                },
                                              children: [
                                                  TableRow(
                                                    children: <TableCell>[
                                                      TableCell(
                                                        child: Container(
                                                          height: 50,
                                                          color: Colors
                                                              .grey.shade200,
                                                          child: const Center(
                                                            child: Text(
                                                                'Order Details'),
                                                          ),
                                                        ),
                                                      ),
                                                      TableCell(
                                                        child: Container(
                                                          height: 50,
                                                          color: Colors
                                                              .grey.shade200,
                                                          child: const Center(
                                                            child: Text('QTY'),
                                                          ),
                                                        ),
                                                      ),
                                                      TableCell(
                                                        child: Container(
                                                          height: 50,
                                                          color: Colors
                                                              .grey.shade200,
                                                          child: const Center(
                                                            child: Text(
                                                                'Packaging Type'),
                                                          ),
                                                        ),
                                                      ),
                                                      TableCell(
                                                        child: Container(
                                                          height: 50,
                                                          color: Colors
                                                              .grey.shade200,
                                                          child: const Center(
                                                            child:
                                                                Text('Image'),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  TableRow(
                                                    children: <TableCell>[
                                                      TableCell(
                                                        child: SizedBox(
                                                          height: 145,
                                                          child: Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .all(10.0),
                                                            child: Column(
                                                                children: [
                                                                  Row(
                                                                    children: [
                                                                      const SelectableText(
                                                                        'Name : ',
                                                                        style:
                                                                            TextStyle(
                                                                          fontWeight:
                                                                              FontWeight.bold,
                                                                        ),
                                                                      ),
                                                                      Flexible(
                                                                        child:
                                                                            SelectableText(
                                                                          orderListForPackAndScan[0]
                                                                              .title,
                                                                          style:
                                                                              const TextStyle(
                                                                            overflow:
                                                                                TextOverflow.visible,
                                                                          ),
                                                                        ),
                                                                      )
                                                                    ],
                                                                  ),
                                                                  const SizedBox(
                                                                    height: 10,
                                                                  ),
                                                                  Row(
                                                                    children: [
                                                                      const SelectableText(
                                                                        'SKU : ',
                                                                        style:
                                                                            TextStyle(
                                                                          fontWeight:
                                                                              FontWeight.bold,
                                                                        ),
                                                                      ),
                                                                      SelectableText(
                                                                        orderListForPackAndScan[0]
                                                                            .sku,
                                                                      )
                                                                    ],
                                                                  ),
                                                                  const SizedBox(
                                                                    height: 10,
                                                                  ),
                                                                  Row(
                                                                    children: [
                                                                      const SelectableText(
                                                                        'Barcode : ',
                                                                        style: TextStyle(
                                                                            fontWeight:
                                                                                FontWeight.bold),
                                                                      ),
                                                                      SelectableText(
                                                                        orderListForPackAndScan[0]
                                                                            .ean,
                                                                      )
                                                                    ],
                                                                  ),
                                                                  const SizedBox(
                                                                    height: 10,
                                                                  ),
                                                                  Row(
                                                                    children: [
                                                                      const SelectableText(
                                                                        'Order Number : ',
                                                                        style: TextStyle(
                                                                            fontWeight:
                                                                                FontWeight.bold),
                                                                      ),
                                                                      SelectableText(
                                                                        orderListForPackAndScan[0]
                                                                            .orderNumber,
                                                                      )
                                                                    ],
                                                                  ),
                                                                  const SizedBox(
                                                                    height: 10,
                                                                  ),
                                                                  Row(
                                                                    children: const [
                                                                      SelectableText(
                                                                        'Status : ',
                                                                        style:
                                                                            TextStyle(
                                                                          fontWeight:
                                                                              FontWeight.bold,
                                                                        ),
                                                                      ),
                                                                      SelectableText(
                                                                        "Picked Not Printed",
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ]),
                                                          ),
                                                        ),
                                                      ),
                                                      TableCell(
                                                        child: SizedBox(
                                                          height: 145,
                                                          child: Center(
                                                            child:
                                                                SelectableText(
                                                              orderListForPackAndScan[
                                                                      0]
                                                                  .qtyToPick,
                                                              style: const TextStyle(
                                                                  fontSize: 25,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      TableCell(
                                                        child: SizedBox(
                                                          height: 145,
                                                          child: Center(
                                                            child:
                                                                SelectableText(
                                                              orderListForPackAndScan[
                                                                          0]
                                                                      .packagingType
                                                                      .isEmpty
                                                                  ? 'NA'
                                                                  : orderListForPackAndScan[
                                                                          0]
                                                                      .packagingType,
                                                              style: const TextStyle(
                                                                  fontSize: 25,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      TableCell(
                                                        child: SizedBox(
                                                          height: 140,
                                                          width: 140,
                                                          child: Center(
                                                            child: orderListForPackAndScan[
                                                                        0]
                                                                    .url
                                                                    .isEmpty
                                                                ? Image.asset(
                                                                    'assets/no_image/no_image.png',
                                                                    height: 140,
                                                                    width: 140,
                                                                    fit: BoxFit
                                                                        .contain,
                                                                  )
                                                                : ImageNetwork(
                                                                    image:
                                                                        orderListForPackAndScan[0]
                                                                            .url,
                                                                    height: 140,
                                                                    width: 140,
                                                                    duration:
                                                                        100,
                                                                    fitAndroidIos:
                                                                        BoxFit
                                                                            .contain,
                                                                    fitWeb: BoxFitWeb
                                                                        .contain,
                                                                    onLoading:
                                                                        const CircularProgressIndicator(
                                                                      color: Colors
                                                                          .indigoAccent,
                                                                    ),
                                                                    onError: Image
                                                                        .asset(
                                                                      'assets/no_image/no_image.png',
                                                                      height:
                                                                          140,
                                                                      width:
                                                                          140,
                                                                      fit: BoxFit
                                                                          .contain,
                                                                    ),
                                                                  ),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ])
                                          : Table(
                                              border: TableBorder.all(
                                                  color: Colors.black,
                                                  width: 1),
                                              columnWidths: <int,
                                                  TableColumnWidth>{
                                                  0: FixedColumnWidth(
                                                      size.width * .55),
                                                  1: FixedColumnWidth(
                                                      size.width * .1),
                                                  2: FixedColumnWidth(
                                                      size.width * .3),
                                                },
                                              children: [
                                                  TableRow(
                                                    children: <TableCell>[
                                                      TableCell(
                                                        child: Container(
                                                          height: 50,
                                                          color: Colors
                                                              .grey.shade200,
                                                          child: const Center(
                                                            child: Text(
                                                                'Order Details'),
                                                          ),
                                                        ),
                                                      ),
                                                      TableCell(
                                                        child: Container(
                                                          height: 50,
                                                          color: Colors
                                                              .grey.shade200,
                                                          child: const Center(
                                                            child: Text('QTY'),
                                                          ),
                                                        ),
                                                      ),
                                                      TableCell(
                                                        child: Container(
                                                          height: 50,
                                                          color: Colors
                                                              .grey.shade200,
                                                          child: const Center(
                                                            child:
                                                                Text('Image'),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  TableRow(
                                                    children: <TableCell>[
                                                      TableCell(
                                                        child: SizedBox(
                                                          height: 145,
                                                          child: Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .all(10.0),
                                                            child: Column(
                                                                children: [
                                                                  Row(
                                                                    children: [
                                                                      const SelectableText(
                                                                        'Name : ',
                                                                        style:
                                                                            TextStyle(
                                                                          fontWeight:
                                                                              FontWeight.bold,
                                                                        ),
                                                                      ),
                                                                      Flexible(
                                                                        child:
                                                                            SelectableText(
                                                                          orderListForPackAndScan[0]
                                                                              .title,
                                                                          style:
                                                                              const TextStyle(
                                                                            overflow:
                                                                                TextOverflow.visible,
                                                                          ),
                                                                        ),
                                                                      )
                                                                    ],
                                                                  ),
                                                                  const SizedBox(
                                                                    height: 10,
                                                                  ),
                                                                  Row(
                                                                    children: [
                                                                      const SelectableText(
                                                                        'SKU : ',
                                                                        style:
                                                                            TextStyle(
                                                                          fontWeight:
                                                                              FontWeight.bold,
                                                                        ),
                                                                      ),
                                                                      SelectableText(
                                                                        orderListForPackAndScan[0]
                                                                            .sku,
                                                                      )
                                                                    ],
                                                                  ),
                                                                  const SizedBox(
                                                                    height: 10,
                                                                  ),
                                                                  Row(
                                                                    children: [
                                                                      const SelectableText(
                                                                        'Barcode : ',
                                                                        style: TextStyle(
                                                                            fontWeight:
                                                                                FontWeight.bold),
                                                                      ),
                                                                      SelectableText(
                                                                        orderListForPackAndScan[0]
                                                                            .ean,
                                                                      )
                                                                    ],
                                                                  ),
                                                                  const SizedBox(
                                                                    height: 10,
                                                                  ),
                                                                  Row(
                                                                    children: [
                                                                      const SelectableText(
                                                                        'Order Number : ',
                                                                        style: TextStyle(
                                                                            fontWeight:
                                                                                FontWeight.bold),
                                                                      ),
                                                                      SelectableText(
                                                                        orderListForPackAndScan[0]
                                                                            .orderNumber,
                                                                      )
                                                                    ],
                                                                  ),
                                                                  const SizedBox(
                                                                    height: 10,
                                                                  ),
                                                                  Row(
                                                                    children: const [
                                                                      SelectableText(
                                                                        'Status : ',
                                                                        style:
                                                                            TextStyle(
                                                                          fontWeight:
                                                                              FontWeight.bold,
                                                                        ),
                                                                      ),
                                                                      SelectableText(
                                                                        "Picked Not Printed",
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ]),
                                                          ),
                                                        ),
                                                      ),
                                                      TableCell(
                                                        child: SizedBox(
                                                          height: 145,
                                                          child: Center(
                                                            child:
                                                                SelectableText(
                                                              orderListForPackAndScan[
                                                                      0]
                                                                  .qtyToPick,
                                                              style: const TextStyle(
                                                                  fontSize: 25,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      TableCell(
                                                        child: SizedBox(
                                                          height: 140,
                                                          width: 140,
                                                          child: Center(
                                                            child: orderListForPackAndScan[
                                                                        0]
                                                                    .url
                                                                    .isEmpty
                                                                ? Image.asset(
                                                                    'assets/no_image/no_image.png',
                                                                    height: 140,
                                                                    width: 140,
                                                                    fit: BoxFit
                                                                        .contain,
                                                                  )
                                                                : ImageNetwork(
                                                                    image:
                                                                        orderListForPackAndScan[0]
                                                                            .url,
                                                                    height: 140,
                                                                    width: 140,
                                                                    duration:
                                                                        100,
                                                                    fitAndroidIos:
                                                                        BoxFit
                                                                            .contain,
                                                                    fitWeb: BoxFitWeb
                                                                        .contain,
                                                                    onLoading:
                                                                        const CircularProgressIndicator(
                                                                      color: Colors
                                                                          .indigoAccent,
                                                                    ),
                                                                    onError: Image
                                                                        .asset(
                                                                      'assets/no_image/no_image.png',
                                                                      height:
                                                                          140,
                                                                      width:
                                                                          140,
                                                                      fit: BoxFit
                                                                          .contain,
                                                                    ),
                                                                  ),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ])
                                  : selectedPicklist == 'SIW'
                                      ? Table(border: TableBorder.all(color: Colors.black, width: 1), columnWidths: <
                                          int, TableColumnWidth>{
                                          0: FixedColumnWidth(size.width * .45),
                                          1: FixedColumnWidth(size.width * .1),
                                          2: FixedColumnWidth(size.width * .1),
                                          3: FixedColumnWidth(size.width * .3),
                                        }, children: [
                                          TableRow(
                                            children: <TableCell>[
                                              TableCell(
                                                child: Container(
                                                  height: 50,
                                                  color: Colors.grey.shade200,
                                                  child: const Center(
                                                    child:
                                                        Text('Order Details'),
                                                  ),
                                                ),
                                              ),
                                              TableCell(
                                                child: Container(
                                                  height: 50,
                                                  color: Colors.grey.shade200,
                                                  child: const Center(
                                                    child: Text('QTY'),
                                                  ),
                                                ),
                                              ),
                                              TableCell(
                                                child: Container(
                                                  height: 50,
                                                  color: Colors.grey.shade200,
                                                  child: const Center(
                                                    child:
                                                        Text('Packaging Type'),
                                                  ),
                                                ),
                                              ),
                                              TableCell(
                                                child: Container(
                                                  height: 50,
                                                  color: Colors.grey.shade200,
                                                  child: const Center(
                                                    child: Text('Image'),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          ..._listOfTableRowForOrderNumberSelectedCase(),
                                        ])
                                      : Table(border: TableBorder.all(color: Colors.black, width: 1), columnWidths: <
                                          int, TableColumnWidth>{
                                          0: FixedColumnWidth(size.width * .55),
                                          1: FixedColumnWidth(size.width * .1),
                                          2: FixedColumnWidth(size.width * .3),
                                        }, children: [
                                          TableRow(
                                            children: <TableCell>[
                                              TableCell(
                                                child: Container(
                                                  height: 50,
                                                  color: Colors.grey.shade200,
                                                  child: const Center(
                                                    child:
                                                        Text('Order Details'),
                                                  ),
                                                ),
                                              ),
                                              TableCell(
                                                child: Container(
                                                  height: 50,
                                                  color: Colors.grey.shade200,
                                                  child: const Center(
                                                    child: Text('QTY'),
                                                  ),
                                                ),
                                              ),
                                              TableCell(
                                                child: Container(
                                                  height: 50,
                                                  color: Colors.grey.shade200,
                                                  child: const Center(
                                                    child: Text('Image'),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          ..._listOfTableRowForOrderNumberSelectedCase(),
                                        ]),
                            ),
                          ),
                Visibility(
                  visible: errorVisible == true,
                  child: Padding(
                    padding: EdgeInsets.only(top: size.width * .025),
                    child: SizedBox(
                      height: size.height * .025,
                      width: size.width,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Center(
                            child: Text(
                              labelError,
                              style: const TextStyle(
                                fontSize: 15,
                                color: Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Visibility(
                  visible: isPrintingLabel == true,
                  child: Padding(
                    padding: EdgeInsets.only(top: size.width * .025),
                    child: SizedBox(
                      height: size.height * .025,
                      width: size.width,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Center(
                            child: Text(
                              printingLabel,
                              style: const TextStyle(
                                fontSize: 15,
                                color: Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Visibility(
                  visible: buttonVisible(),
                  child: Padding(
                    padding: EdgeInsets.only(top: size.width * .008),
                    child: SizedBox(
                      height: size.height * .05,
                      width: size.width,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green),
                            onPressed: buttonLoading == true
                                ? null
                                : () async {
                                    if (orderListForPackAndScan.isNotEmpty) {
                                      await labelPrinting();
                                    }
                                  },
                            child: Center(
                              child: buttonLoading == true
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                  : const Text(
                                      'Print Label',
                                      style: TextStyle(color: Colors.white),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                verticalSpacer(context, size.height * .1)
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// ALL SCREEN BUILDERS - START //////////////////////////////////////////////

  Widget _siwAndSSMQWScanOffBuilder(BuildContext context, Size size) {
    return Padding(
      padding: EdgeInsets.only(
        top: size.height * .03,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SelectableText(
                  'Showing Last',
                  style: TextStyle(
                    fontSize: 16,
                  ),
                ),
                SelectableText(
                  '${scannedOrdersList.where((e) => e.picklistType == selectedPicklist).toList().length}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SelectableText(
                  'Scanned',
                  style: TextStyle(
                    fontSize: 16,
                  ),
                ),
                SelectableText(
                  selectedPicklist,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SelectableText(
                  scannedOrdersList
                              .where((e) => e.picklistType == selectedPicklist)
                              .toList()
                              .length >
                          1
                      ? 'Orders'
                      : 'Order',
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          selectedPicklist == 'SIW'
              ? Table(
                  border: TableBorder.all(
                    color: Colors.black,
                    width: 1,
                  ),
                  columnWidths: {
                      0: FixedColumnWidth(
                        size.width * .3,
                      ),
                      1: FixedColumnWidth(
                        size.width * .1,
                      ),
                      2: FixedColumnWidth(
                        size.width * .2,
                      ),
                      3: FixedColumnWidth(
                        size.width * .2,
                      ),
                      4: FixedColumnWidth(
                        size.width * .15,
                      ),
                    },
                  children: [
                      TableRow(
                        children: <TableCell>[
                          TableCell(
                            child: Container(
                              height: 50,
                              color: Colors.grey.shade200,
                              child: const Center(
                                child: Text('Order Details'),
                              ),
                            ),
                          ),
                          TableCell(
                            child: Container(
                              height: 50,
                              color: Colors.grey.shade200,
                              child: const Center(
                                child: Text('QTY'),
                              ),
                            ),
                          ),
                          TableCell(
                            child: Container(
                              height: 50,
                              color: Colors.grey.shade200,
                              child: const Center(
                                child: Text('Packaging Type'),
                              ),
                            ),
                          ),
                          TableCell(
                            child: Container(
                              height: 50,
                              color: Colors.grey.shade200,
                              child: const Center(
                                child: Text('Image'),
                              ),
                            ),
                          ),
                          TableCell(
                            child: Container(
                              height: 50,
                              color: Colors.grey.shade200,
                              child: const Center(
                                child: Text('Print Label'),
                              ),
                            ),
                          ),
                        ],
                      ),
                      ...List.generate(
                          scannedOrdersList
                              .where((e) => e.picklistType == selectedPicklist)
                              .toList()
                              .length,
                          (index) => TableRow(children: <TableCell>[
                                TableCell(
                                  child: SizedBox(
                                    height: 400,
                                    child: Padding(
                                      padding: const EdgeInsets.all(10.0),
                                      child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const SelectableText(
                                              'Name : ',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            SelectableText(
                                              scannedOrdersList
                                                  .where((e) =>
                                                      e.picklistType ==
                                                      selectedPicklistController
                                                          .text)
                                                  .toList()[index]
                                                  .title,
                                              style: const TextStyle(
                                                overflow: TextOverflow.visible,
                                              ),
                                            ),
                                            const SizedBox(
                                              height: 10,
                                            ),
                                            const SelectableText(
                                              'SKU : ',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            SelectableText(
                                              scannedOrdersList
                                                  .where((e) =>
                                                      e.picklistType ==
                                                      selectedPicklistController
                                                          .text)
                                                  .toList()[index]
                                                  .sku,
                                            ),
                                            const SizedBox(
                                              height: 10,
                                            ),
                                            const SelectableText(
                                              'Barcode : ',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            SelectableText(
                                              scannedOrdersList
                                                  .where((e) =>
                                                      e.picklistType ==
                                                      selectedPicklistController
                                                          .text)
                                                  .toList()[index]
                                                  .barcode,
                                            ),
                                            const SizedBox(
                                              height: 10,
                                            ),
                                            const SelectableText(
                                              'Order Number : ',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            SelectableText(
                                              scannedOrdersList
                                                  .where((e) =>
                                                      e.picklistType ==
                                                      selectedPicklistController
                                                          .text)
                                                  .toList()[index]
                                                  .orderNumber,
                                            ),
                                          ]),
                                    ),
                                  ),
                                ),
                                TableCell(
                                  child: SizedBox(
                                    height: 120,
                                    width: size.width * .1,
                                    child: Center(
                                      child: SelectableText(
                                        scannedOrdersList
                                            .where((e) =>
                                                e.picklistType ==
                                                selectedPicklist)
                                            .toList()[index]
                                            .qtyToPick,
                                        style: const TextStyle(
                                            fontSize: 25,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                ),
                                TableCell(
                                  child: SizedBox(
                                    height: 120,
                                    width: size.width * .1,
                                    child: Center(
                                      child: SelectableText(
                                        scannedOrdersList
                                            .where((e) =>
                                                e.picklistType ==
                                                selectedPicklist)
                                            .toList()[index]
                                            .packagingType!,
                                        style: const TextStyle(
                                            fontSize: 25,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                ),
                                TableCell(
                                  child: SizedBox(
                                    height: 115,
                                    width: 115,
                                    child: Center(
                                      child: scannedOrdersList
                                              .where((e) =>
                                                  e.picklistType ==
                                                  selectedPicklistController
                                                      .text)
                                              .toList()[index]
                                              .url
                                              .isEmpty
                                          ? Image.asset(
                                              'assets/no_image/no_image.png',
                                              height: 115,
                                              width: 115,
                                              fit: BoxFit.contain,
                                            )
                                          : ImageNetwork(
                                              image: scannedOrdersList
                                                  .where((e) =>
                                                      e.picklistType ==
                                                      selectedPicklistController
                                                          .text)
                                                  .toList()[index]
                                                  .url,
                                              height: 115,
                                              width: 115,
                                              duration: 100,
                                              fitAndroidIos: BoxFit.contain,
                                              fitWeb: BoxFitWeb.contain,
                                              onLoading: Shimmer(
                                                duration:
                                                    const Duration(seconds: 2),
                                                colorOpacity: 1,
                                                child: Container(
                                                  decoration:
                                                      const BoxDecoration(
                                                    color: Color.fromARGB(
                                                        160, 192, 192, 192),
                                                  ),
                                                ),
                                              ),
                                              onError: Image.asset(
                                                'assets/no_image/no_image.png',
                                                height: 115,
                                                width: 115,
                                                fit: BoxFit.contain,
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                                TableCell(
                                  child: SizedBox(
                                    height: 120,
                                    width: size.width * .1,
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          height: 40,
                                          width: 100,
                                          child: RoundedLoadingButton(
                                            color: Colors.green,
                                            borderRadius: 5,
                                            elevation: 5,
                                            height: 40,
                                            width: 100,
                                            controller: printController[index],
                                            onPressed: () async {
                                              await print(
                                                scannedOrdersList
                                                    .where((e) =>
                                                        e.picklistType ==
                                                        selectedPicklistController
                                                            .text)
                                                    .toList()[index]
                                                    .labelUrl,
                                              ).whenComplete(() {
                                                printController[index].reset();
                                              });
                                            },
                                            child: const Center(
                                              child: Text(
                                                'RePrint Label',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ]))
                    ])
              : Table(
                  border: TableBorder.all(
                    color: Colors.black,
                    width: 1,
                  ),
                  columnWidths: {
                      0: FixedColumnWidth(
                        size.width * .55,
                      ),
                      1: FixedColumnWidth(
                        size.width * .1,
                      ),
                      2: FixedColumnWidth(
                        size.width * .2,
                      ),
                      3: FixedColumnWidth(
                        size.width * .1,
                      ),
                    },
                  children: [
                      TableRow(
                        children: <TableCell>[
                          TableCell(
                            child: Container(
                              height: 50,
                              color: Colors.grey.shade200,
                              child: const Center(
                                child: Text('Order Details'),
                              ),
                            ),
                          ),
                          TableCell(
                            child: Container(
                              height: 50,
                              color: Colors.grey.shade200,
                              child: const Center(
                                child: Text('QTY'),
                              ),
                            ),
                          ),
                          TableCell(
                            child: Container(
                              height: 50,
                              color: Colors.grey.shade200,
                              child: const Center(
                                child: Text('Image'),
                              ),
                            ),
                          ),
                          TableCell(
                            child: Container(
                              height: 50,
                              color: Colors.grey.shade200,
                              child: const Center(
                                child: Text('Print Label'),
                              ),
                            ),
                          ),
                        ],
                      ),
                      ...List.generate(
                          scannedOrdersList
                              .where((e) => e.picklistType == selectedPicklist)
                              .toList()
                              .length,
                          (index) => TableRow(children: <TableCell>[
                                TableCell(
                                  child: SizedBox(
                                    height: 120,
                                    child: Padding(
                                      padding: const EdgeInsets.all(10.0),
                                      child: Column(children: [
                                        Row(
                                          children: [
                                            const SelectableText(
                                              'Name : ',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Flexible(
                                              child: SelectableText(
                                                scannedOrdersList
                                                    .where((e) =>
                                                        e.picklistType ==
                                                        selectedPicklistController
                                                            .text)
                                                    .toList()[index]
                                                    .title,
                                                style: const TextStyle(
                                                  overflow:
                                                      TextOverflow.visible,
                                                ),
                                              ),
                                            )
                                          ],
                                        ),
                                        const SizedBox(
                                          height: 10,
                                        ),
                                        Row(
                                          children: [
                                            const SelectableText(
                                              'SKU : ',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            SelectableText(
                                              scannedOrdersList
                                                  .where((e) =>
                                                      e.picklistType ==
                                                      selectedPicklistController
                                                          .text)
                                                  .toList()[index]
                                                  .sku,
                                            )
                                          ],
                                        ),
                                        const SizedBox(
                                          height: 10,
                                        ),
                                        Row(
                                          children: [
                                            const SelectableText(
                                              'Barcode : ',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            SelectableText(
                                              scannedOrdersList
                                                  .where((e) =>
                                                      e.picklistType ==
                                                      selectedPicklistController
                                                          .text)
                                                  .toList()[index]
                                                  .barcode,
                                            )
                                          ],
                                        ),
                                        const SizedBox(
                                          height: 10,
                                        ),
                                        Row(
                                          children: [
                                            const SelectableText(
                                              'Order Number : ',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            SelectableText(
                                              scannedOrdersList
                                                  .where((e) =>
                                                      e.picklistType ==
                                                      selectedPicklistController
                                                          .text)
                                                  .toList()[index]
                                                  .orderNumber,
                                            )
                                          ],
                                        )
                                      ]),
                                    ),
                                  ),
                                ),
                                TableCell(
                                  child: SizedBox(
                                    height: 120,
                                    width: size.width * .1,
                                    child: Center(
                                      child: SelectableText(
                                        scannedOrdersList
                                            .where((e) =>
                                                e.picklistType ==
                                                selectedPicklist)
                                            .toList()[index]
                                            .qtyToPick,
                                        style: const TextStyle(
                                            fontSize: 25,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                ),
                                TableCell(
                                  child: SizedBox(
                                    height: 115,
                                    width: 115,
                                    child: Center(
                                      child: scannedOrdersList
                                              .where((e) =>
                                                  e.picklistType ==
                                                  selectedPicklistController
                                                      .text)
                                              .toList()[index]
                                              .url
                                              .isEmpty
                                          ? Image.asset(
                                              'assets/no_image/no_image.png',
                                              height: 115,
                                              width: 115,
                                              fit: BoxFit.contain,
                                            )
                                          : ImageNetwork(
                                              image: scannedOrdersList
                                                  .where((e) =>
                                                      e.picklistType ==
                                                      selectedPicklistController
                                                          .text)
                                                  .toList()[index]
                                                  .url,
                                              height: 115,
                                              width: 115,
                                              duration: 100,
                                              fitAndroidIos: BoxFit.contain,
                                              fitWeb: BoxFitWeb.contain,
                                              onLoading: Shimmer(
                                                duration:
                                                    const Duration(seconds: 2),
                                                colorOpacity: 1,
                                                child: Container(
                                                  decoration:
                                                      const BoxDecoration(
                                                    color: Color.fromARGB(
                                                        160, 192, 192, 192),
                                                  ),
                                                ),
                                              ),
                                              onError: Image.asset(
                                                'assets/no_image/no_image.png',
                                                height: 115,
                                                width: 115,
                                                fit: BoxFit.contain,
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                                TableCell(
                                  child: SizedBox(
                                    height: 120,
                                    width: size.width * .1,
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          height: 40,
                                          width: 100,
                                          child: RoundedLoadingButton(
                                            color: Colors.green,
                                            borderRadius: 5,
                                            elevation: 5,
                                            height: 40,
                                            width: 100,
                                            controller: printController[index],
                                            onPressed: () async {
                                              await print(
                                                scannedOrdersList
                                                    .where((e) =>
                                                        e.picklistType ==
                                                        selectedPicklistController
                                                            .text)
                                                    .toList()[index]
                                                    .labelUrl,
                                              ).whenComplete(() {
                                                printController[index].reset();
                                              });
                                            },
                                            child: const Center(
                                              child: Text(
                                                'RePrint Label',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ]))
                    ]),
        ],
      ),
    );
  }

  Widget _msmqwScanOffBuilder(BuildContext context, Size size) {
    return Padding(
      padding: EdgeInsets.only(
        top: size.width * .01,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SelectableText(
                  'Showing Last Scanned',
                  style: TextStyle(
                    fontSize: 18,
                  ),
                ),
                const SelectableText(
                  'MSMQW',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SelectableText(
                  'Order',
                  style: TextStyle(
                    fontSize: 18,
                  ),
                ),
                Visibility(
                  visible: scannedOrdersList
                      .where((e) => e.picklistType == 'MSMQW')
                      .toList()
                      .isNotEmpty,
                  child: SelectableText(
                    scannedOrdersList.isNotEmpty
                        ? scannedOrdersList
                            .where((e) => e.picklistType == 'MSMQW')
                            .toList()[0]
                            .orderNumber
                        : '',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Table(
              border: TableBorder.all(
                color: Colors.black,
                width: 1,
              ),
              columnWidths: {
                0: FixedColumnWidth(
                  size.width * .55,
                ),
                1: FixedColumnWidth(
                  size.width * .1,
                ),
                2: FixedColumnWidth(
                  size.width * .3,
                ),
              },
              children: [
                TableRow(
                  children: <TableCell>[
                    TableCell(
                      child: Container(
                        height: 50,
                        color: Colors.grey.shade200,
                        child: const Center(
                          child: Text('Order Details'),
                        ),
                      ),
                    ),
                    TableCell(
                      child: Container(
                        height: 50,
                        color: Colors.grey.shade200,
                        child: const Center(
                          child: Text('QTY'),
                        ),
                      ),
                    ),
                    TableCell(
                      child: Container(
                        height: 50,
                        color: Colors.grey.shade200,
                        child: const Center(
                          child: Text('Image'),
                        ),
                      ),
                    ),
                  ],
                ),
                ...List.generate(
                    scannedOrdersList
                        .where((e) => e.picklistType == 'MSMQW')
                        .toList()
                        .length,
                    (index) => TableRow(children: <TableCell>[
                          TableCell(
                            child: SizedBox(
                              height: 120,
                              child: Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: Column(children: [
                                  Row(
                                    children: [
                                      const SelectableText(
                                        'Name : ',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Flexible(
                                        child: SelectableText(
                                          scannedOrdersList
                                              .where((e) =>
                                                  e.picklistType == 'MSMQW')
                                              .toList()[index]
                                              .title,
                                          style: const TextStyle(
                                            overflow: TextOverflow.visible,
                                          ),
                                        ),
                                      )
                                    ],
                                  ),
                                  const SizedBox(
                                    height: 10,
                                  ),
                                  Row(
                                    children: [
                                      const SelectableText(
                                        'SKU : ',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SelectableText(
                                        scannedOrdersList
                                            .where((e) =>
                                                e.picklistType == 'MSMQW')
                                            .toList()[index]
                                            .sku,
                                      )
                                    ],
                                  ),
                                  const SizedBox(
                                    height: 10,
                                  ),
                                  Row(
                                    children: [
                                      const SelectableText(
                                        'Barcode : ',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      SelectableText(
                                        scannedOrdersList
                                            .where((e) =>
                                                e.picklistType == 'MSMQW')
                                            .toList()[index]
                                            .barcode,
                                      )
                                    ],
                                  ),
                                  const SizedBox(
                                    height: 10,
                                  ),
                                  Row(
                                    children: [
                                      const SelectableText(
                                        'Order Number : ',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      SelectableText(
                                        scannedOrdersList
                                            .where((e) =>
                                                e.picklistType == 'MSMQW')
                                            .toList()[index]
                                            .orderNumber,
                                      )
                                    ],
                                  )
                                ]),
                              ),
                            ),
                          ),
                          TableCell(
                            child: SizedBox(
                              height: 120,
                              width: size.width * .1,
                              child: Center(
                                child: SelectableText(
                                  scannedOrdersList
                                      .where((e) => e.picklistType == 'MSMQW')
                                      .toList()[index]
                                      .qtyToPick,
                                  style: const TextStyle(
                                      fontSize: 25,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ),
                          TableCell(
                            child: SizedBox(
                              height: 115,
                              width: 115,
                              child: Center(
                                child: scannedOrdersList
                                        .where((e) => e.picklistType == 'MSMQW')
                                        .toList()[index]
                                        .url
                                        .isEmpty
                                    ? Image.asset(
                                        'assets/no_image/no_image.png',
                                        height: 115,
                                        width: 115,
                                        fit: BoxFit.contain,
                                      )
                                    : ImageNetwork(
                                        image: scannedOrdersList
                                            .where((e) =>
                                                e.picklistType == 'MSMQW')
                                            .toList()[index]
                                            .url,
                                        height: 115,
                                        width: 115,
                                        duration: 100,
                                        fitAndroidIos: BoxFit.contain,
                                        fitWeb: BoxFitWeb.contain,
                                        onLoading: Shimmer(
                                          duration: const Duration(seconds: 2),
                                          colorOpacity: 1,
                                          child: Container(
                                            decoration: const BoxDecoration(
                                              color: Color.fromARGB(
                                                  160, 192, 192, 192),
                                            ),
                                          ),
                                        ),
                                        onError: Image.asset(
                                          'assets/no_image/no_image.png',
                                          height: 115,
                                          width: 115,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ]))
              ]),
          Padding(
            padding: const EdgeInsets.only(top: 30.0),
            child: SizedBox(
              height: 40,
              width: 100,
              child: RoundedLoadingButton(
                color: Colors.green,
                borderRadius: 5,
                elevation: 5,
                height: 40,
                width: 100,
                controller: printForMSMQWController,
                onPressed: () async {
                  await print(
                    scannedOrdersList
                        .where((e) => e.picklistType == 'MSMQW')
                        .toList()[0]
                        .labelUrl,
                  ).whenComplete(() {
                    printForMSMQWController.reset();
                  });
                },
                child: const Center(
                  child: Text(
                    'RePrint Label',
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  /// ALL SCREEN BUILDERS - END ////////////////////////////////////////////////

  List<TableRow> _listOfTableRowForOrderNumberSelectedCase() {
    return List.generate(
        orderListForPackAndScan.length,
        (index) => selectedPicklist == 'SIW'
            ? TableRow(
                children: <TableCell>[
                  TableCell(
                    child: SizedBox(
                      height: 145,
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Column(children: [
                          Row(
                            children: [
                              const SelectableText(
                                'Name : ',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Flexible(
                                child: SelectableText(
                                  orderListForPackAndScan[index].title,
                                  style: const TextStyle(
                                    overflow: TextOverflow.visible,
                                  ),
                                ),
                              )
                            ],
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          Row(
                            children: [
                              const SelectableText(
                                'SKU : ',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SelectableText(
                                orderListForPackAndScan[index].sku,
                              )
                            ],
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          Row(
                            children: [
                              const SelectableText(
                                'Barcode : ',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              SelectableText(
                                orderListForPackAndScan[index].ean,
                              )
                            ],
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          Row(
                            children: [
                              const SelectableText(
                                'Order Number : ',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              SelectableText(
                                orderListForPackAndScan[index].orderNumber,
                              )
                            ],
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          Row(
                            children: const [
                              SelectableText(
                                'Status : ',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SelectableText(
                                "Picked Not Printed",
                              ),
                            ],
                          ),
                        ]),
                      ),
                    ),
                  ),
                  TableCell(
                    child: SizedBox(
                      height: 145,
                      child: Center(
                        child: SelectableText(
                          orderListForPackAndScan[index].qtyToPick,
                          style: const TextStyle(
                              fontSize: 25, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                  TableCell(
                    child: SizedBox(
                      height: 145,
                      child: Center(
                        child: SelectableText(
                          orderListForPackAndScan[index].packagingType.isEmpty
                              ? 'NA'
                              : orderListForPackAndScan[index].packagingType,
                          style: const TextStyle(
                              fontSize: 25, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                  TableCell(
                    child: SizedBox(
                      height: 140,
                      width: 140,
                      child: Center(
                        child: orderListForPackAndScan[index].url.isEmpty
                            ? Image.asset(
                                'assets/no_image/no_image.png',
                                height: 140,
                                width: 140,
                                fit: BoxFit.contain,
                              )
                            : ImageNetwork(
                                image: orderListForPackAndScan[index].url,
                                height: 140,
                                width: 140,
                                duration: 100,
                                fitAndroidIos: BoxFit.contain,
                                fitWeb: BoxFitWeb.contain,
                                onLoading: const CircularProgressIndicator(
                                  color: Colors.indigoAccent,
                                ),
                                onError: Image.asset(
                                  'assets/no_image/no_image.png',
                                  height: 140,
                                  width: 140,
                                  fit: BoxFit.contain,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              )
            : TableRow(
                children: <TableCell>[
                  TableCell(
                    child: SizedBox(
                      height: 145,
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Column(children: [
                          Row(
                            children: [
                              const SelectableText(
                                'Name : ',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Flexible(
                                child: SelectableText(
                                  orderListForPackAndScan[index].title,
                                  style: const TextStyle(
                                    overflow: TextOverflow.visible,
                                  ),
                                ),
                              )
                            ],
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          Row(
                            children: [
                              const SelectableText(
                                'SKU : ',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SelectableText(
                                orderListForPackAndScan[index].sku,
                              )
                            ],
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          Row(
                            children: [
                              const SelectableText(
                                'Barcode : ',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              SelectableText(
                                orderListForPackAndScan[index].ean,
                              )
                            ],
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          Row(
                            children: [
                              const SelectableText(
                                'Order Number : ',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              SelectableText(
                                orderListForPackAndScan[index].orderNumber,
                              )
                            ],
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          Row(
                            children: const [
                              SelectableText(
                                'Status : ',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SelectableText(
                                "Picked Not Printed",
                              ),
                            ],
                          ),
                        ]),
                      ),
                    ),
                  ),
                  TableCell(
                    child: SizedBox(
                      height: 145,
                      child: Center(
                        child: SelectableText(
                          orderListForPackAndScan[index].qtyToPick,
                          style: const TextStyle(
                              fontSize: 25, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                  TableCell(
                    child: SizedBox(
                      height: 140,
                      width: 140,
                      child: Center(
                        child: orderListForPackAndScan[index].url.isEmpty
                            ? Image.asset(
                                'assets/no_image/no_image.png',
                                height: 140,
                                width: 140,
                                fit: BoxFit.contain,
                              )
                            : ImageNetwork(
                                image: orderListForPackAndScan[index].url,
                                height: 140,
                                width: 140,
                                duration: 100,
                                fitAndroidIos: BoxFit.contain,
                                fitWeb: BoxFitWeb.contain,
                                onLoading: const CircularProgressIndicator(
                                  color: Colors.indigoAccent,
                                ),
                                onError: Image.asset(
                                  'assets/no_image/no_image.png',
                                  height: 140,
                                  width: 140,
                                  fit: BoxFit.contain,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ));
  }

  bool buttonVisible() {
    return eanOrOrderSelected == 'Barcode'
        ? selectedPicklist == 'MSMQW'
            ? orderListForPackAndScanBarcodeMSMQW.isNotEmpty
                ? parseToInt(orderListForPackAndScanBarcodeMSMQW[0][0]
                            .totalSkUs
                            .toString()) ==
                        parseToInt(orderListForPackAndScanBarcodeMSMQW[0][0]
                            .pickedSkUs
                            .toString())
                    ? true
                    : false
                : false
            : orderListForPackAndScan.isNotEmpty
                ? true
                : false
        : orderListForPackAndScan.isNotEmpty
            ? true
            : false;
  }

  void saveLabelData({
    required int serialNo,
    required String isShippedOrder,
    required String orderId,
    required String ean,
    required String siteName,
    required String siteOrderId,
    required String encryptedLabel,
  }) async {
    var labelPrintingData = ParseObject('labels_data_pack_and_scan');
    labelPrintingData.set('sr_no', serialNo);
    labelPrintingData.set('is_shipped_order', isShippedOrder);
    labelPrintingData.set('order_id', orderId);
    labelPrintingData.set('label_print_date', DateTime.now().toUtc());
    labelPrintingData.set('ean', ean);
    labelPrintingData.set('site_name', siteName);
    labelPrintingData.set('site_order_id', siteOrderId);
    labelPrintingData.set('encrypted_label', encryptedLabel);
    await labelPrintingData.save();
  }

  void updateLabelData({
    required String objectId,
    required String isShippedOrder,
    required String encryptedLabel,
  }) async {
    var labelPrintingData = ParseObject('labels_data_pack_and_scan')
      ..objectId = objectId
      ..set('is_shipped_order', isShippedOrder)
      ..set('encrypted_label', encryptedLabel);
    await labelPrintingData.save();
  }

  Future<void> getLabelDataPackAndScan() async {
    isLoading = true;
    await ApiCalls.getLabelsDataPackAndScan().then((data) {
      log('LABEL DATA PACK AND SCAN >>---> $data');

      labelDataPAndSDB = [];
      labelDataPAndSDB.addAll(data.map((e) => e));
      log('V labelDataPAndSDB >>---> $labelDataPAndSDB');

      setState(() {
        serialNoDB = labelDataPAndSDB.isEmpty ? 0 : labelDataPAndSDB.length;
      });
      log('V serialNoDB >>---> $serialNoDB');
    });
  }

  Future<void> getScannedOrders() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String encodedData = prefs.getString('scanned_pack_and_scan_orders') ?? '';

    scannedOrdersList = [];
    if (encodedData.isNotEmpty) {
      scannedOrdersList = ScannedOrderModel.decode(encodedData);
    }
  }

  Future<void> getScannedMSMQWOrders() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String encodedData =
        prefs.getString('scanned_pack_and_scan_orders_msmqw') ?? '';

    scannedOrdersList = [];
    if (encodedData.isNotEmpty) {
      scannedOrdersList = ScannedOrderModel.decode(encodedData);
    }
  }

  void saveScannedOrdersData({
    required String picklistType,
    required String title,
    required String sku,
    required String barcode,
    required String orderNumber,
    required String qtyToPick,
    required String url,
    required String siteOrderId,
    required String siteName,
    required String labelError,
    required String labelUrl,
    required String packagingType,
  }) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    scannedOrdersListToSave = [];
    scannedOrdersListToSave.addAll(scannedOrdersList.map((e) => e));

    if (scannedOrdersList.isEmpty) {
      scannedOrdersListToSave.add(
        ScannedOrderModel(
          picklistType: picklistType,
          title: title,
          sku: sku,
          barcode: barcode,
          orderNumber: orderNumber,
          qtyToPick: qtyToPick,
          url: url,
          siteOrderId: siteOrderId,
          siteName: siteName,
          labelError: labelError,
          labelUrl: labelUrl,
          packagingType: packagingType,
        ),
      );
    } else if (scannedOrdersList
            .where((e) =>
                e.picklistType == (parseToInt(qtyToPick) > 1 ? 'SSMQW' : 'SIW'))
            .toList()
            .length <
        5) {
      scannedOrdersListToSave.insert(
        0,
        ScannedOrderModel(
          picklistType: picklistType,
          title: title,
          sku: sku,
          barcode: barcode,
          orderNumber: orderNumber,
          qtyToPick: qtyToPick,
          url: url,
          siteOrderId: siteOrderId,
          siteName: siteName,
          labelError: labelError,
          labelUrl: labelUrl,
          packagingType: packagingType,
        ),
      );
    } else {
      scannedOrdersListToSave.removeAt(scannedOrdersListToSave.lastIndexWhere(
          (e) =>
              e.picklistType == (parseToInt(qtyToPick) > 1 ? 'SSMQW' : 'SIW')));
      scannedOrdersListToSave.insert(
        0,
        ScannedOrderModel(
          picklistType: picklistType,
          title: title,
          sku: sku,
          barcode: barcode,
          orderNumber: orderNumber,
          qtyToPick: qtyToPick,
          url: url,
          siteOrderId: siteOrderId,
          siteName: siteName,
          labelError: labelError,
          labelUrl: labelUrl,
          packagingType: packagingType,
        ),
      );
    }

    final String encodedData =
        ScannedOrderModel.encode(scannedOrdersListToSave);

    await prefs.setString('scanned_pack_and_scan_orders', encodedData);
  }

  void saveScannedOrdersForMSMQWData({
    required String picklistType,
    required List<String> title,
    required List<String> sku,
    required List<String> barcode,
    required String orderNumber,
    required List<String> qtyToPick,
    required List<String> url,
    required String siteOrderId,
    required List<String> siteName,
    required String labelError,
    required String labelUrl,
  }) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    scannedOrdersListToSave = [];
    for (int i = 0; i < title.length; i++) {
      scannedOrdersListToSave.add(ScannedOrderModel(
        picklistType: picklistType,
        title: title[i],
        sku: sku[i],
        barcode: barcode[i],
        orderNumber: orderNumber,
        qtyToPick: qtyToPick[i],
        url: url[i],
        siteOrderId: siteOrderId,
        siteName: siteName[i],
        labelError: labelError,
        labelUrl: labelUrl,
      ));
    }

    final String encodedData =
        ScannedOrderModel.encode(scannedOrdersListToSave);

    await prefs.setString('scanned_pack_and_scan_orders_msmqw', encodedData);
  }

  ///Accepts encrypted data and decrypt it. Returns plain text
  String decryptWithAES(String key, encrypt.Encrypted encryptedData) {
    final cipherKey = encrypt.Key.fromUtf8(key);
    final encryptService =
        encrypt.Encrypter(encrypt.AES(cipherKey, mode: encrypt.AESMode.cbc));
    final initVector = encrypt.IV.fromUtf8(key.substring(0, 16));
    return encryptService.decrypt(encryptedData, iv: initVector);
  }

  ///Encrypts the given plainText using the key. Returns encrypted data
  encrypt.Encrypted encryptWithAES(String key, String plainText) {
    final cipherKey = encrypt.Key.fromUtf8(key);
    final encryptService =
        encrypt.Encrypter(encrypt.AES(cipherKey, mode: encrypt.AESMode.cbc));
    final initVector = encrypt.IV.fromUtf8(key.substring(0, 16));
    encrypt.Encrypted encryptedData =
        encryptService.encrypt(plainText, iv: initVector);
    return encryptedData;
  }

  Future<void> print(String url) async {
    final pdf = pw.Document();
    try {
      final netImage = await networkImage(url);
      pdf.addPage(pw.Page(build: (pw.Context context) {
        return pw.Center(
          child: pw.Image(
            netImage,
          ),
        );
      }));

      final info = await Printing.info();
      log('info - $info');

      // final printers = await Printing.listPrinters();
      // log('printers - $printers');
      // await Printing.directPrintPdf(
      //     printer: printers.first, onLayout: (PdfPageFormat format) async => pdf.save());

      await Printing.directPrintPdf(
          printer: const Printer(url: ''),
          onLayout: (PdfPageFormat format) async => pdf.save());
    } catch (e) {
      log("Exception in Printing >>>>>> ${e.toString()}");
    }
  }

  /// PRINT LABEL METHOD COMBINED FOR AMAZON PRIME AND NON-AMAZON PRIME ORDERS
  /// AND ALSO OPTIMIZED FOR SEPARATE CASES AND LOGS
  /// DATED - 22 JUNE, 2023
  Future<void> printLabel({
    required String siteOrderId,
    required bool isAmazonPrime,
  }) async {
    setState(() {
      labelUrl = '';
      labelError = '';
    });
    String siteOrderIdToSent = '';
    if (siteOrderId.startsWith('#')) {
      setState(() {
        siteOrderIdToSent = siteOrderId.replaceFirst('#', '%23');
      });
    } else {
      setState(() {
        siteOrderIdToSent = siteOrderId;
      });
    }
    String uri = isAmazonPrime
        ? 'https://pickpackquick.azurewebsites.net/api/JadlamLabel?OrderNumber=$siteOrderIdToSent'
        : 'https://weblegs.info/EasyPostv2/api/EasyPostVersion2?OrderNumber=$siteOrderIdToSent';
    log('V siteOrderIdToSent >>---> $siteOrderIdToSent');
    log('PRINT LABEL API URI >>---> $uri');

    try {
      var response = await http.get(Uri.parse(uri)).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          Fluttertoast.showToast(msg: kTimeOut);
          return http.Response('Error', 408);
        },
      );
      log('PRINT LABEL API STATUS CODE >>---> ${response.statusCode}');
      if (response.statusCode == 200) {
        setState(() {
          labelUrl = jsonDecode(response.body)['LabelUrl'].toString();
        });
        log('PRINT LABEL API RESPONSE >>---> ${jsonDecode(response.body)}');
        log('V labelUrl >>---> $labelUrl');
      } else if (response.statusCode == 500) {
        setState(() {
          labelError = (jsonDecode(response.body)['message']).toString();
        });
        log('PRINT LABEL API ERROR RESPONSE >>---> ${jsonDecode(response.body)}');
        log('V labelError >>---> $labelError');
      } else {
        ToastUtils.showCenteredShortToast(message: kerrorString);
        setState(() {
          labelError = kerrorString;
        });
        log('V labelError >>---> $labelError');
      }
    } catch (e) {
      setState(() {
        labelError = 'An error has occurred';
      });
      log('V labelError >>---> $labelError');
      log("PRINT LABEL API EXCEPTION >>---> ${e.toString()}");
    }
  }

  Future<void> getOrdersForPackAndScan({
    required String type,
    required String ean,
    required String orderNumber,
  }) async {
    setState(() {
      isLoading = true;
      isEmptyOnFirstSearch = false;
      isEmptyAfterFirstSearch = false;
    });
    String uri =
        'https://weblegs.info/JadlamApp/api/GetPickedOrdersVersion2?type=$type&ean=$ean&Order=$orderNumber';
    log('GET ORDERS FOR PACK AND SCAN API URI >>---> $uri');

    try {
      var response = await http.get(Uri.parse(uri)).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          Fluttertoast.showToast(msg: kTimeOut);
          isLoading = false;
          return http.Response('Error', 408);
        },
      );
      log('GET ORDERS FOR PACK AND SCAN API STATUS CODE >>---> ${response.statusCode}');

      if (response.statusCode == 200) {
        log('GET ORDERS FOR PACK AND SCAN API RESPONSE >>---> ${jsonDecode(response.body)}');

        GetPackAndScanResponse getPackAndScanResponse =
            GetPackAndScanResponse.fromJson(jsonDecode(response.body));

        if (getPackAndScanResponse.sku.isEmpty) {
          setState(() {
            orderListForPackAndScan = [];
            isEmptyOnFirstSearch = true;
            isEmptyAfterFirstSearch = false;
          });
        } else {
          orderListForPackAndScan = [];
          orderListForPackAndScan
              .addAll(getPackAndScanResponse.sku.map((e) => e));

          orderNumberListForEmptyCase = [];
          orderNumberListForEmptyCase.addAll(orderListForPackAndScan
              .where((et) => labelDataPAndSDB.any(
                  (e) => (e.get<String>('order_id') ?? '') == et.orderNumber))
              .map((e) => e.orderNumber));

          if (eanOrOrderSelected == 'Order Number') {
            eanListForOrderNumberCase = [];
            siteNameListForOrderNumberCase = [];

            eanListForOrderNumberCase
                .addAll(orderListForPackAndScan.map((e) => e.ean));
            siteNameListForOrderNumberCase
                .addAll(orderListForPackAndScan.map((e) => e.siteName));
          }

          if (eanOrOrderSelected == 'Barcode') {
            if (selectedPicklist == 'MSMQW') {
              uniqueOrderNumberListForBarcodeMSMQWCase = [];
              orderListForPackAndScanBarcodeMSMQW = [];
              orderListForBarcodeMSMQWCase = [];
              isAllSKUPicked = [];
              isOrderSavedToDBForMSMQW = [];
              partiallyPickedOrdersForMSMQW = [];

              uniqueOrderNumberListForBarcodeMSMQWCase
                  .addAll(orderListForPackAndScan.map((e) => e.orderNumber));

              for (int i = 0;
                  i <
                      (uniqueOrderNumberListForBarcodeMSMQWCase
                              .toSet()
                              .toList())
                          .length;
                  i++) {
                orderListForPackAndScanBarcodeMSMQW.add((orderListForPackAndScan
                    .where((e) =>
                        e.orderNumber ==
                        (uniqueOrderNumberListForBarcodeMSMQWCase
                            .toSet()
                            .toList())[i])
                    .toList()));
                orderListForBarcodeMSMQWCase.add((orderListForPackAndScan
                    .where((e) =>
                        e.orderNumber ==
                        (uniqueOrderNumberListForBarcodeMSMQWCase
                            .toSet()
                            .toList())[i])
                    .toList()));
              }
              log('V orderListForPackAndScanBarcodeMSMQW >>---> ${jsonEncode(orderListForPackAndScanBarcodeMSMQW)}');
              log('V orderListForBarcodeMSMQWCase >>---> ${jsonEncode(orderListForBarcodeMSMQWCase)}');

              isAllSKUPicked.addAll(List.generate(
                  orderListForPackAndScanBarcodeMSMQW.length,
                  (index) => false));
              isOrderSavedToDBForMSMQW.addAll(List.generate(
                  orderListForPackAndScanBarcodeMSMQW.length,
                  (index) => false));

              for (int i = 0; i < orderListForBarcodeMSMQWCase.length; i++) {
                log('For MSMQW Order - ${orderListForBarcodeMSMQWCase[i][0].orderNumber}');

                log('CHECK FIRST THAT ORDER IS SAVED TO DB PREVIOUSLY OR NOT');
                if (labelDataPAndSDB.any((e) =>
                        (e.get<String>('order_id') ?? '') ==
                        orderListForBarcodeMSMQWCase[i][0].orderNumber) ==
                    true) {
                  log('ORDER IS SAVED PREVIOUSLY >>>>>>>>> CHECK IF ALL SKUs PICKED OR NOT');
                  if (parseToInt(orderListForBarcodeMSMQWCase[i][0]
                          .totalSkUs
                          .toString()) >
                      parseToInt(orderListForBarcodeMSMQWCase[i][0]
                          .pickedSkUs
                          .toString())) {
                    log('ALL SKUs NOT PICKED >>>>>>>> REMOVE THIS ORDER FROM THE ORDER LIST.');

                    isAllSKUPicked.removeAt(
                        orderListForPackAndScanBarcodeMSMQW.indexWhere((e) =>
                            e[0].orderNumber ==
                            orderListForBarcodeMSMQWCase[i][0].orderNumber));
                    isOrderSavedToDBForMSMQW.removeAt(
                        orderListForPackAndScanBarcodeMSMQW.indexWhere((e) =>
                            e[0].orderNumber ==
                            orderListForBarcodeMSMQWCase[i][0].orderNumber));
                    partiallyPickedOrdersForMSMQW
                        .add(orderListForBarcodeMSMQWCase[i][0].orderNumber);
                    orderListForPackAndScanBarcodeMSMQW.removeWhere((e) =>
                        e[0].orderNumber ==
                        orderListForBarcodeMSMQWCase[i][0].orderNumber);
                  } else {
                    log('ALL SKUs ARE PICKED >>>> CHECK IF LABEL IS NA IN DB >>>> MEANS LABEL PRINTED ALREADY OR NOT');
                    if (labelDataPAndSDB[labelDataPAndSDB.indexWhere((e) =>
                                (e.get<String>('order_id') ?? '') ==
                                orderListForBarcodeMSMQWCase[i][0].orderNumber)]
                            .get('encrypted_label') ==
                        'NA') {
                      log('LABEL NOT PRINTED ALREADY >>> PRINT LABEL AND CHANGE LABEL FROM NA TO ACTUAL LABEL');

                      isAllSKUPicked.removeAt(
                          orderListForPackAndScanBarcodeMSMQW.indexWhere((e) =>
                              e[0].orderNumber ==
                              orderListForBarcodeMSMQWCase[i][0].orderNumber));
                      isAllSKUPicked.insert(
                          orderListForPackAndScanBarcodeMSMQW.indexWhere((e) =>
                              e[0].orderNumber ==
                              orderListForBarcodeMSMQWCase[i][0].orderNumber),
                          true);
                      isOrderSavedToDBForMSMQW.removeAt(
                          orderListForPackAndScanBarcodeMSMQW.indexWhere((e) =>
                              e[0].orderNumber ==
                              orderListForBarcodeMSMQWCase[i][0].orderNumber));
                      isOrderSavedToDBForMSMQW.insert(
                          orderListForPackAndScanBarcodeMSMQW.indexWhere((e) =>
                              e[0].orderNumber ==
                              orderListForBarcodeMSMQWCase[i][0].orderNumber),
                          true);
                    } else {
                      log('LABEL PRINTED ALREADY  >> REMOVE THIS ORDER FROM THE PICKLIST');

                      isAllSKUPicked.removeAt(
                          orderListForPackAndScanBarcodeMSMQW.indexWhere((e) =>
                              e[0].orderNumber ==
                              orderListForBarcodeMSMQWCase[i][0].orderNumber));
                      isOrderSavedToDBForMSMQW.removeAt(
                          orderListForPackAndScanBarcodeMSMQW.indexWhere((e) =>
                              e[0].orderNumber ==
                              orderListForBarcodeMSMQWCase[i][0].orderNumber));
                      orderListForPackAndScanBarcodeMSMQW.removeWhere((e) =>
                          e[0].orderNumber ==
                          orderListForBarcodeMSMQWCase[i][0].orderNumber);
                    }
                  }
                } else {
                  log('ORDER IS NOT SAVED PREVIOUSLY >>>>>>>>>>>> /// CHECK IF ALL SKUs PICKED OR NOT');
                  if (parseToInt(orderListForBarcodeMSMQWCase[i][0]
                          .totalSkUs
                          .toString()) >
                      parseToInt(orderListForBarcodeMSMQWCase[i][0]
                          .pickedSkUs
                          .toString())) {
                    log('ALL SKUs NOT PICKED >>>>>>>> SHOW MESSAGE AND SAVE NA LABEL TO THE DB');

                    setState(() {
                      showingPartialOrderTable = true;
                    });
                    log('showingPartialOrderTable >> $showingPartialOrderTable');

                    isAllSKUPicked.removeAt(
                        orderListForPackAndScanBarcodeMSMQW.indexWhere((e) =>
                            e[0].orderNumber ==
                            orderListForBarcodeMSMQWCase[i][0].orderNumber));
                    isAllSKUPicked.insert(
                        orderListForPackAndScanBarcodeMSMQW.indexWhere((e) =>
                            e[0].orderNumber ==
                            orderListForBarcodeMSMQWCase[i][0].orderNumber),
                        false);
                    isOrderSavedToDBForMSMQW.removeAt(
                        orderListForPackAndScanBarcodeMSMQW.indexWhere((e) =>
                            e[0].orderNumber ==
                            orderListForBarcodeMSMQWCase[i][0].orderNumber));
                    isOrderSavedToDBForMSMQW.insert(
                        orderListForPackAndScanBarcodeMSMQW.indexWhere((e) =>
                            e[0].orderNumber ==
                            orderListForBarcodeMSMQWCase[i][0].orderNumber),
                        false);
                  } else {
                    log('ALL SKUs ARE PICKED >>>> PRINT LABEL AND SAVE THE LABEL TO THE DB');

                    isAllSKUPicked.removeAt(
                        orderListForPackAndScanBarcodeMSMQW.indexWhere((e) =>
                            e[0].orderNumber ==
                            orderListForBarcodeMSMQWCase[i][0].orderNumber));
                    isAllSKUPicked.insert(
                        orderListForPackAndScanBarcodeMSMQW.indexWhere((e) =>
                            e[0].orderNumber ==
                            orderListForBarcodeMSMQWCase[i][0].orderNumber),
                        true);
                    isOrderSavedToDBForMSMQW.removeAt(
                        orderListForPackAndScanBarcodeMSMQW.indexWhere((e) =>
                            e[0].orderNumber ==
                            orderListForBarcodeMSMQWCase[i][0].orderNumber));
                    isOrderSavedToDBForMSMQW.insert(
                        orderListForPackAndScanBarcodeMSMQW.indexWhere((e) =>
                            e[0].orderNumber ==
                            orderListForBarcodeMSMQWCase[i][0].orderNumber),
                        false);
                  }
                }
              }
            } else {
              orderListForPackAndScan.removeWhere((et) => labelDataPAndSDB.any(
                  (e) => (e.get<String>('order_id') ?? '') == et.orderNumber));
            }
          }

          if ((eanOrOrderSelected == 'Barcode' && selectedPicklist == 'MSMQW'
                  ? orderListForPackAndScanBarcodeMSMQW
                  : orderListForPackAndScan)
              .isEmpty) {
            setState(() {
              isEmptyOnFirstSearch = false;
              isEmptyAfterFirstSearch = true;
            });
          }
        }
        setState(() {
          isLoading = false;
        });
      } else {
        ToastUtils.showCenteredShortToast(message: kerrorString);
        isLoading = false;
      }
    } on Exception catch (e) {
      log(e.toString());
      ToastUtils.showCenteredLongToast(message: e.toString());
      isLoading = false;
    }
  }
}
