import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:absolute_app/core/utils/constants.dart';
import 'package:absolute_app/core/utils/toast_utils.dart';
import 'package:absolute_app/core/utils/common_screen_widgets/widgets.dart';
import 'package:absolute_app/models/get_order_details_with_label_response.dart';
import 'package:absolute_app/models/scanned_order_model.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_network/image_network.dart';
import 'package:parse_server_sdk/parse_server_sdk.dart';
import 'package:http/http.dart' as http;
import 'package:rounded_loading_button/rounded_loading_button.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

class PackAndScanWebNew extends StatefulWidget {
  const PackAndScanWebNew({Key? key, required this.apiKey}) : super(key: key);

  final String apiKey;

  @override
  State<PackAndScanWebNew> createState() => _PackAndScanWebNewState();
}

class _PackAndScanWebNewState extends State<PackAndScanWebNew> {
  List<RoundedLoadingButtonController> printController =
      <RoundedLoadingButtonController>[];
  RoundedLoadingButtonController printForMSMQWController =
      RoundedLoadingButtonController();
  final TextEditingController barcodeController = TextEditingController();
  final FocusNode barcodeFocus = FocusNode();

  List<PickedOrderXX> ordersList = [];

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

  bool isPrinterNotSelected = false;
  bool isLoading = false;
  bool isPrintingLabel = false;
  bool isSuccessfulCase = false;

  String printingLabel = 'Printing Label.........';
  String labelUrl = '';
  String labelError = '';
  String encryptedLabel = '';
  String selectedPicklist = 'SIW';
  String eanOrOrderSelected = 'Barcode';
  String selectedPrinter = '';

  int serialNoDB = 0;
  int selectedPrinterId = 0;

  @override
  void initState() {
    super.initState();
    initApiCall();
  }

  void initApiCall() async {
    setState(() {
      isLoading = true;
    });
    await SharedPreferences.getInstance().then((prefs) {
      setState(() {
        eanOrOrderSelected = prefs.getString('eanOrOrderNumber') ?? 'Barcode';
        selectedPicklist = prefs.getString('picklistType') ?? 'SIW';
        selectedPrinter = prefs.getString('selectedPrinter') == 'null'
            ? ''
            : prefs.getString('selectedPrinter') ?? '';
        selectedPrinterId = prefs.getInt('selectedPrinterId') ?? 0;
      });
    }).whenComplete(() async {
      log('V selectedPrinter >>---> $selectedPrinter');
      log('V selectedPrinterId >>---> $selectedPrinterId');
      if (selectedPrinter.isEmpty) {
        setState(() {
          isPrinterNotSelected = true;
          isLoading = false;
        });
      } else {
        if (selectedPicklist == 'MSMQW') {
          await getScannedMSMQWOrders().whenComplete(() {
            setState(() {
              isLoading = false;
            });
          });
        } else {
          await getScannedOrders().whenComplete(() {
            if (scannedOrdersList
                .where((e) => e.picklistType == selectedPicklist)
                .toList()
                .isNotEmpty) {
              printController = [];
              printController.addAll(List.generate(
                  scannedOrdersList
                      .where((e) => e.picklistType == selectedPicklist)
                      .toList()
                      .length,
                  (index) => RoundedLoadingButtonController()));
              log('LENGTH OF PRINT CONTROLLER LIST FOR SIW AND SSMQW >>---> ${printController.length}');
            }
          }).whenComplete(() {
            setState(() {
              isLoading = false;
            });
          });
        }
      }
    });
  }

  void apiCall() async {
    await SharedPreferences.getInstance().then((prefs) async {
      if (eanOrOrderSelected == 'Order Number') {
        await getOrdersDetailsWithLabel(
                type: '',
                ean: '',
                orderNumber: barcodeController.text,
                isTest:
                    (prefs.getString('EasyPostTestOrLive') ?? 'Test') == 'Test')
            .whenComplete(() async {
          if (isSuccessfulCase) {
            await sendPrintJob(
              apiKey: widget.apiKey,
              printerId: selectedPrinterId,
              printerName: selectedPrinter,
              orderNumber: ordersList[0].orderNumber,
              labelPdfUrl: labelUrl,
            );
          }
        }).whenComplete(() async {
          setState(() {
            isLoading = true;
          });
          if (ordersList.isNotEmpty) {
            if (ordersList.length > 1) {
              /// MSMQW
              saveScannedOrdersForMSMQWData(
                picklistType: 'MSMQW',
                title: ordersList.map((e) => e.title).toList(),
                sku: ordersList.map((e) => e.sku).toList(),
                barcode: ordersList.map((e) => e.ean).toList(),
                orderNumber: ordersList[0].orderNumber,
                qtyToPick: ordersList.map((e) => e.qtyToPick).toList(),
                url: ordersList.map((e) => e.url).toList(),
                siteOrderId: ordersList[0].siteOrderId,
                siteName: ordersList.map((e) => e.siteName).toList(),
                labelError: labelError,
                labelUrl: labelUrl,
              );

              setState(() {
                selectedPicklist = 'MSMQW';
              });
            } else {
              /// SIW OR SSMQW
              saveScannedOrdersData(
                picklistType:
                    parseToInt(ordersList[0].qtyToPick) > 1 ? 'SSMQW' : 'SIW',
                title: ordersList[0].title,
                sku: ordersList[0].sku,
                barcode: ordersList[0].ean,
                orderNumber: ordersList[0].orderNumber,
                qtyToPick: ordersList[0].qtyToPick,
                url: ordersList[0].url,
                siteOrderId: ordersList[0].siteOrderId,
                siteName: ordersList[0].siteName,
                labelError: labelError,
                labelUrl: labelUrl,
                packagingType: ordersList[0].packageType,
              );

              setState(() {
                selectedPicklist =
                    parseToInt(ordersList[0].qtyToPick) > 1 ? 'SSMQW' : 'SIW';
              });
            }
          }
          await Future.delayed(const Duration(seconds: 1), () async {
            if (selectedPicklist == 'MSMQW') {
              await getScannedMSMQWOrders().whenComplete(() {
                barcodeController.clear();
                barcodeFocus.requestFocus();
                setState(() {
                  ordersList = [];
                  labelUrl = '';
                });
              }).whenComplete(() {
                setState(() {
                  isLoading = false;
                });
              });
            }

            if (selectedPicklist != 'MSMQW') {
              await getScannedOrders().whenComplete(() {
                if (scannedOrdersList
                    .where((e) => e.picklistType == selectedPicklist)
                    .toList()
                    .isNotEmpty) {
                  printController = [];
                  printController.addAll(List.generate(
                      scannedOrdersList
                          .where((e) => e.picklistType == selectedPicklist)
                          .toList()
                          .length,
                      (index) => RoundedLoadingButtonController()));
                  log('LENGTH OF PRINT CONTROLLER LIST FOR SIW AND SSMQW >>---> ${printController.length}');
                }
              }).whenComplete(() {
                barcodeController.clear();
                barcodeFocus.requestFocus();
                setState(() {
                  ordersList = [];
                  labelUrl = '';
                });
              }).whenComplete(() {
                setState(() {
                  isLoading = false;
                });
              });
            }
          });
        });
      }

      ///  PRODUCT BARCODE SELECTED CASE
      else {
        await getOrdersDetailsWithLabel(
                type: selectedPicklist,
                ean: barcodeController.text,
                orderNumber: '',
                isTest:
                    (prefs.getString('EasyPostTestOrLive') ?? 'Test') == 'Test')
            .whenComplete(() async {
          if (isSuccessfulCase) {
            await sendPrintJob(
              apiKey: widget.apiKey,
              printerId: selectedPrinterId,
              printerName: selectedPrinter,
              orderNumber: ordersList[0].orderNumber,
              labelPdfUrl: labelUrl,
            );
          }
        }).whenComplete(() async {
          setState(() {
            isLoading = true;
          });
          if (ordersList.isNotEmpty) {
            if (selectedPicklist == 'MSMQW') {
              saveScannedOrdersForMSMQWData(
                picklistType: 'MSMQW',
                title: ordersList.map((e) => e.title).toList(),
                sku: ordersList.map((e) => e.sku).toList(),
                barcode: ordersList.map((e) => e.ean).toList(),
                orderNumber: ordersList[0].orderNumber,
                qtyToPick: ordersList.map((e) => e.qtyToPick).toList(),
                url: ordersList.map((e) => e.url).toList(),
                siteOrderId: ordersList[0].siteOrderId,
                siteName: ordersList.map((e) => e.siteName).toList(),
                labelError: labelError,
                labelUrl: labelUrl,
              );
            } else {
              saveScannedOrdersData(
                picklistType: selectedPicklist,
                title: ordersList[0].title,
                sku: ordersList[0].sku,
                barcode: ordersList[0].ean,
                orderNumber: ordersList[0].orderNumber,
                qtyToPick: ordersList[0].qtyToPick,
                url: ordersList[0].url,
                siteOrderId: ordersList[0].siteOrderId,
                siteName: ordersList[0].siteName,
                labelError: labelError,
                labelUrl: labelUrl,
                packagingType: ordersList[0].packageType,
              );
            }
          }
          await Future.delayed(const Duration(seconds: 1), () async {
            if (selectedPicklist == 'MSMQW') {
              await getScannedMSMQWOrders().whenComplete(() {
                barcodeController.clear();
                barcodeFocus.requestFocus();
                setState(() {
                  ordersList = [];
                  labelUrl = '';
                });
              }).whenComplete(() {
                setState(() {
                  isLoading = false;
                });
              });
            } else {
              await getScannedOrders().whenComplete(() {
                if (scannedOrdersList
                    .where((e) => e.picklistType == selectedPicklist)
                    .toList()
                    .isNotEmpty) {
                  printController = [];
                  printController.addAll(List.generate(
                      scannedOrdersList
                          .where((e) => e.picklistType == selectedPicklist)
                          .toList()
                          .length,
                      (index) => RoundedLoadingButtonController()));
                  log('LENGTH OF PRINT CONTROLLER LIST FOR SIW AND SSMQW >>---> ${printController.length}');
                }
              }).whenComplete(() {
                barcodeController.clear();
                barcodeFocus.requestFocus();
                setState(() {
                  ordersList = [];
                  labelUrl = '';
                });
              }).whenComplete(() {
                setState(() {
                  isLoading = false;
                });
              });
            }
          });
        });
      }
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
        title: Text(
          'Pack & Scan',
          style: TextStyle(
            fontSize: (size.width <= 1000) ? 25 : 30,
            color: Colors.black,
          ),
        ),
      ),
      body: isPrinterNotSelected
          ? SizedBox(
              height: size.height,
              width: size.width,
              child: const Center(
                child: Text(
                  'No Printer Selected! Please Select from PrintNode Settings',
                  style: TextStyle(fontSize: 20),
                ),
              ),
            )
          : isLoading
              ? SizedBox(
                  height: size.height,
                  width: size.width,
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: appColor,
                    ),
                  ),
                )
              : SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: size.width * .01),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(top: size.width * .025),
                          child: SizedBox(
                            height: 40,
                            width: size.width,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  height: 40,
                                  width: size.width * .1,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: appColor,
                                      width: 0.5,
                                    ),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton(
                                      elevation: 0,
                                      value: eanOrOrderSelected,
                                      icon: SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: FittedBox(
                                          child: Image.asset(
                                            'assets/add_new_rule_assets/dd_icon.png',
                                          ),
                                        ),
                                      ),
                                      selectedItemBuilder:
                                          (BuildContext context) {
                                        return eanOrOrder
                                            .map<Widget>((String item) {
                                          return SizedBox(
                                            width: size.width * .080,
                                            child: Center(
                                              child: Text(
                                                item,
                                                style: const TextStyle(
                                                  color: Colors.black,
                                                ),
                                              ),
                                            ),
                                          );
                                        }).toList();
                                      },
                                      items: eanOrOrder
                                          .map(
                                            (value) => DropdownMenuItem(
                                              value: value,
                                              child: Center(
                                                child: Text(
                                                  value,
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (Object? newValue) async {
                                        setState(() {
                                          eanOrOrderSelected =
                                              newValue as String;
                                        });
                                        log('V eanOrOrderSelected >>---> $eanOrOrderSelected');
                                        barcodeFocus.requestFocus();
                                        if (barcodeController.text.length > 4) {
                                          apiCall();
                                        } else {
                                          setState(() {
                                            isLoading = true;
                                          });
                                          if (selectedPicklist == 'MSMQW') {
                                            await getScannedMSMQWOrders()
                                                .whenComplete(() {
                                              barcodeController.clear();
                                              barcodeFocus.requestFocus();
                                              setState(() {
                                                ordersList = [];
                                                labelUrl = '';
                                              });
                                            }).whenComplete(() {
                                              setState(() {
                                                isLoading = false;
                                              });
                                            });
                                          } else {
                                            await getScannedOrders()
                                                .whenComplete(() {
                                              if (scannedOrdersList
                                                  .where((e) =>
                                                      e.picklistType ==
                                                      selectedPicklist)
                                                  .toList()
                                                  .isNotEmpty) {
                                                printController = [];
                                                printController.addAll(List.generate(
                                                    scannedOrdersList
                                                        .where((e) =>
                                                            e.picklistType ==
                                                            selectedPicklist)
                                                        .toList()
                                                        .length,
                                                    (index) =>
                                                        RoundedLoadingButtonController()));
                                                log('LENGTH OF PRINT CONTROLLER LIST FOR SIW AND SSMQW >>---> ${printController.length}');
                                              }
                                            }).whenComplete(() {
                                              barcodeController.clear();
                                              barcodeFocus.requestFocus();
                                              setState(() {
                                                ordersList = [];
                                                labelUrl = '';
                                              });
                                            }).whenComplete(() {
                                              setState(() {
                                                isLoading = false;
                                              });
                                            });
                                          }
                                        }
                                      },
                                    ),
                                  ),
                                ),
                                Visibility(
                                  visible: eanOrOrderSelected == 'Barcode',
                                  child: Container(
                                    height: 40,
                                    width: size.width * .1,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                          color: appColor, width: 0.5),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton(
                                        elevation: 0,
                                        value: selectedPicklist,
                                        icon: SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: FittedBox(
                                            child: Image.asset(
                                                'assets/add_new_rule_assets/dd_icon.png'),
                                          ),
                                        ),
                                        selectedItemBuilder:
                                            (BuildContext context) {
                                          return pickListTypes
                                              .map<Widget>((String item) {
                                            return SizedBox(
                                              width: size.width * .080,
                                              child: Center(
                                                child: Text(
                                                  item,
                                                  style: const TextStyle(
                                                    color: Colors.black,
                                                  ),
                                                ),
                                              ),
                                            );
                                          }).toList();
                                        },
                                        items: pickListTypes
                                            .map(
                                              (value) => DropdownMenuItem(
                                                value: value,
                                                child: Center(
                                                  child: Text(
                                                    value,
                                                    style: const TextStyle(
                                                      fontSize: 18,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            )
                                            .toList(),
                                        onChanged: (Object? newValue) async {
                                          setState(() {
                                            selectedPicklist =
                                                newValue as String;
                                          });
                                          log('V selectedPicklist >>---> $selectedPicklist');
                                          barcodeFocus.requestFocus();
                                          if (barcodeController.text.length >
                                              4) {
                                            apiCall();
                                          } else {
                                            setState(() {
                                              isLoading = true;
                                            });
                                            if (selectedPicklist == 'MSMQW') {
                                              await getScannedMSMQWOrders()
                                                  .whenComplete(() {
                                                barcodeController.clear();
                                                barcodeFocus.requestFocus();
                                                setState(() {
                                                  ordersList = [];
                                                  labelUrl = '';
                                                });
                                              }).whenComplete(() {
                                                setState(() {
                                                  isLoading = false;
                                                });
                                              });
                                            } else {
                                              await getScannedOrders()
                                                  .whenComplete(() {
                                                if (scannedOrdersList
                                                    .where((e) =>
                                                        e.picklistType ==
                                                        selectedPicklist)
                                                    .toList()
                                                    .isNotEmpty) {
                                                  printController = [];
                                                  printController.addAll(List.generate(
                                                      scannedOrdersList
                                                          .where((e) =>
                                                              e.picklistType ==
                                                              selectedPicklist)
                                                          .toList()
                                                          .length,
                                                      (index) =>
                                                          RoundedLoadingButtonController()));
                                                  log('LENGTH OF PRINT CONTROLLER LIST FOR SIW AND SSMQW >>---> ${printController.length}');
                                                }
                                              }).whenComplete(() {
                                                barcodeController.clear();
                                                barcodeFocus.requestFocus();
                                                setState(() {
                                                  ordersList = [];
                                                  labelUrl = '';
                                                });
                                              }).whenComplete(() {
                                                setState(() {
                                                  isLoading = false;
                                                });
                                              });
                                            }
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height: 40,
                                  width: eanOrOrderSelected == 'Barcode'
                                      ? size.width * .7
                                      : size.width * .8,
                                  child: TextFormField(
                                    focusNode: barcodeFocus,
                                    autofocus: true,
                                    controller: barcodeController,
                                    style: const TextStyle(fontSize: 16),
                                    decoration: InputDecoration(
                                      hintText: eanOrOrderSelected == 'Barcode'
                                          ? 'Product Barcode'
                                          : 'Order Number',
                                      hintStyle: const TextStyle(
                                        fontSize: 16,
                                      ),
                                      contentPadding: const EdgeInsets.all(5),
                                      border: const OutlineInputBorder(
                                        borderSide: BorderSide(
                                            color: appColor, width: 1),
                                        borderRadius: BorderRadius.zero,
                                      ),
                                      focusedBorder: const OutlineInputBorder(
                                        borderSide: BorderSide(
                                            color: appColor, width: 1),
                                        borderRadius: BorderRadius.zero,
                                      ),
                                      filled: true,
                                      fillColor: Colors.white,
                                      suffixIcon: Visibility(
                                        visible: barcodeController.text
                                            .toString()
                                            .isNotEmpty,
                                        child: IconButton(
                                          onPressed: () {
                                            barcodeController.clear();
                                            barcodeFocus.requestFocus();
                                            if (selectedPicklist == "MSMQW") {}
                                          },
                                          icon: const Icon(
                                            Icons.close,
                                            color: appColor,
                                          ),
                                        ),
                                      ),
                                    ),
                                    onChanged: (_) {
                                      if (barcodeController.text.length > 4) {
                                        apiCall();
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Visibility(
                          visible: isPrintingLabel,
                          child: Padding(
                            padding: EdgeInsets.only(top: size.width * .015),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(
                                  color: appColor,
                                ),
                                Padding(
                                  padding: EdgeInsets.only(left: 30),
                                  child: Text(
                                    'Printing Label .....',
                                    style: TextStyle(
                                      fontSize: 18,
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                        selectedPicklist == 'MSMQW'
                            ? Visibility(
                                visible: scannedOrdersList
                                    .where((e) => e.picklistType == 'MSMQW')
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
                                        e.picklistType == selectedPicklist)
                                    .toList()
                                    .isNotEmpty,
                                child: _siwAndSSMQWScanOffBuilder(
                                  context,
                                  size,
                                ),
                              ),
                        verticalSpacer(context, size.height * .1)
                      ],
                    ),
                  ),
                ),
    );
  }

  /// SCREEN BUILDERS

  Widget _siwAndSSMQWScanOffBuilder(BuildContext context, Size size) {
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
                  'Showing Last',
                  style: TextStyle(
                    fontSize: 18,
                  ),
                ),
                SelectableText(
                  '${scannedOrdersList.where((e) => e.picklistType == selectedPicklist).toList().length}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SelectableText(
                  'Scanned',
                  style: TextStyle(
                    fontSize: 18,
                  ),
                ),
                SelectableText(
                  selectedPicklist,
                  style: const TextStyle(
                    fontSize: 18,
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
                    fontSize: 18,
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
                        size.width * .45,
                      ),
                      1: FixedColumnWidth(
                        size.width * .1,
                      ),
                      2: FixedColumnWidth(
                        size.width * .1,
                      ),
                      3: FixedColumnWidth(
                        size.width * .2,
                      ),
                      4: FixedColumnWidth(
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
                                                        selectedPicklist)
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
                                        const SizedBox(height: 10),
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
                                                      selectedPicklist)
                                                  .toList()[index]
                                                  .sku,
                                            )
                                          ],
                                        ),
                                        const SizedBox(height: 10),
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
                                                      selectedPicklist)
                                                  .toList()[index]
                                                  .barcode,
                                            )
                                          ],
                                        ),
                                        const SizedBox(height: 10),
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
                                                      selectedPicklist)
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
                                                  selectedPicklist)
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
                                                      selectedPicklist)
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
                                              await sendPrintJob(
                                                apiKey: widget.apiKey,
                                                printerId: selectedPrinterId,
                                                printerName: selectedPrinter,
                                                orderNumber: scannedOrdersList
                                                    .where((e) =>
                                                        e.picklistType ==
                                                        selectedPicklist)
                                                    .toList()[index]
                                                    .orderNumber,
                                                labelPdfUrl: scannedOrdersList
                                                    .where((e) =>
                                                        e.picklistType ==
                                                        selectedPicklist)
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
                      0: FixedColumnWidth(size.width * .55),
                      1: FixedColumnWidth(size.width * .1),
                      2: FixedColumnWidth(size.width * .2),
                      3: FixedColumnWidth(size.width * .1),
                    },
                  children: [
                      TableRow(
                        children: <TableCell>[
                          TableCell(
                            child: Container(
                              height: 50,
                              color: Colors.grey.shade200,
                              child: const Center(child: Text('Order Details')),
                            ),
                          ),
                          TableCell(
                            child: Container(
                              height: 50,
                              color: Colors.grey.shade200,
                              child: const Center(child: Text('QTY')),
                            ),
                          ),
                          TableCell(
                            child: Container(
                              height: 50,
                              color: Colors.grey.shade200,
                              child: const Center(child: Text('Image')),
                            ),
                          ),
                          TableCell(
                            child: Container(
                              height: 50,
                              color: Colors.grey.shade200,
                              child: const Center(child: Text('Print Label')),
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
                                                        selectedPicklist)
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
                                        const SizedBox(height: 10),
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
                                                      selectedPicklist)
                                                  .toList()[index]
                                                  .sku,
                                            )
                                          ],
                                        ),
                                        const SizedBox(height: 10),
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
                                                      selectedPicklist)
                                                  .toList()[index]
                                                  .barcode,
                                            )
                                          ],
                                        ),
                                        const SizedBox(height: 10),
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
                                                      selectedPicklist)
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
                                                  selectedPicklist)
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
                                                      selectedPicklist)
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
                                              await sendPrintJob(
                                                apiKey: widget.apiKey,
                                                printerId: selectedPrinterId,
                                                printerName: selectedPrinter,
                                                orderNumber: scannedOrdersList
                                                    .where((e) =>
                                                        e.picklistType ==
                                                        selectedPicklist)
                                                    .toList()[index]
                                                    .orderNumber,
                                                labelPdfUrl: scannedOrdersList
                                                    .where((e) =>
                                                        e.picklistType ==
                                                        selectedPicklist)
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
      padding: EdgeInsets.only(top: size.width * .01),
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
                  style: TextStyle(fontSize: 18),
                ),
                const SelectableText(
                  'MSMQW',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SelectableText(
                  'Order',
                  style: TextStyle(fontSize: 18),
                ),
                Visibility(
                  visible: scannedOrdersList
                      .where((e) => e.picklistType == 'MSMQW')
                      .toList()
                      .isNotEmpty,
                  child: SelectableText(
                    scannedOrdersList
                            .where((e) => e.picklistType == 'MSMQW')
                            .toList()
                            .isNotEmpty
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
              border: TableBorder.all(color: Colors.black, width: 1),
              columnWidths: {
                0: FixedColumnWidth(size.width * .55),
                1: FixedColumnWidth(size.width * .1),
                2: FixedColumnWidth(size.width * .3),
              },
              children: [
                TableRow(
                  children: <TableCell>[
                    TableCell(
                      child: Container(
                        height: 50,
                        color: Colors.grey.shade200,
                        child: const Center(child: Text('Order Details')),
                      ),
                    ),
                    TableCell(
                      child: Container(
                        height: 50,
                        color: Colors.grey.shade200,
                        child: const Center(child: Text('QTY')),
                      ),
                    ),
                    TableCell(
                      child: Container(
                        height: 50,
                        color: Colors.grey.shade200,
                        child: const Center(child: Text('Image')),
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
                                  const SizedBox(height: 10),
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
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      const SelectableText(
                                        'Barcode : ',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
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
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      const SelectableText(
                                        'Order Number : ',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
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
                                    fontWeight: FontWeight.bold,
                                  ),
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
                  await sendPrintJob(
                    apiKey: widget.apiKey,
                    printerId: selectedPrinterId,
                    printerName: selectedPrinter,
                    orderNumber: scannedOrdersList
                        .where((e) => e.picklistType == selectedPicklist)
                        .toList()[0]
                        .orderNumber,
                    labelPdfUrl: scannedOrdersList
                        .where((e) => e.picklistType == selectedPicklist)
                        .toList()[0]
                        .labelUrl,
                  ).whenComplete(() {
                    printForMSMQWController.reset();
                  });
                },
                child: const Center(
                  child: Text(
                    'RePrint Label',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  /// API METHODS

  Future<void> getScannedOrders() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String encodedData = prefs.getString('scanned_pack_and_scan_orders') ?? '';

    scannedOrdersList = [];
    if (encodedData.isNotEmpty) {
      scannedOrdersList = ScannedOrderModel.decode(encodedData);
      log('THERE ARE PREVIOUSLY SCANNED ORDERS');
    } else {
      log('NO PREVIOUSLY SCANNED ORDERS');
    }
  }

  Future<void> getScannedMSMQWOrders() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String encodedData =
        prefs.getString('scanned_pack_and_scan_orders_msmqw') ?? '';

    scannedOrdersList = [];
    if (encodedData.isNotEmpty) {
      scannedOrdersList = ScannedOrderModel.decode(encodedData);
      log('THERE ARE PREVIOUSLY SCANNED MSMQW ORDERS');
    } else {
      log('NO PREVIOUSLY SCANNED MSMQW ORDERS');
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

  Future<void> getOrdersDetailsWithLabel({
    required String type,
    required String ean,
    required String orderNumber,
    required bool isTest,
  }) async {
    setState(() {
      isPrintingLabel = true;
      isSuccessfulCase = false;
    });
    String uri =
        'https://weblegs.info/EasyPost/api/EasyPostSpeedCheck?type=$type&ean=$ean&OrderNumber=$orderNumber&IsTest=$isTest';
    log('GET ORDERS DETAILS WITH LABEL API URI >>---> $uri');

    try {
      var response = await http.get(Uri.parse(uri)).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          Fluttertoast.showToast(msg: kTimeOut);
          setState(() {
            isPrintingLabel = false;
          });
          return http.Response('Error', 408);
        },
      );
      log('GET ORDERS DETAILS WITH LABEL API STATUS CODE >>---> ${response.statusCode}');

      if (response.statusCode == 200) {
        log('GET ORDERS DETAILS WITH LABEL API RESPONSE >>---> ${jsonDecode(response.body)}');

        GetOrderDetailsWithLabelResponse getOrderDetailsWithLabelResponse =
            GetOrderDetailsWithLabelResponse.fromJson(
                jsonDecode(response.body));
        log('V getOrderDetailsWithLabelResponse >>---> $getOrderDetailsWithLabelResponse');

        ordersList = [];
        ordersList
            .addAll(getOrderDetailsWithLabelResponse.pickedOrder.map((e) => e));
        log('V ordersList >>---> $ordersList');

        setState(() {
          labelUrl = getOrderDetailsWithLabelResponse.pdfLabelUrl;
        });
        log('V labelUrl >>---> $labelUrl');
        if (labelUrl.isNotEmpty) {
          setState(() {
            isSuccessfulCase = true;
          });
        }

        if (ordersList.isEmpty) {
          if (!mounted) return;
          ToastUtils.motionToastCentered1500MS(
            message: 'No Orders Found!',
            context: context,
          );
        }
        setState(() {
          isPrintingLabel = false;
        });
      } else if (response.statusCode == 500) {
        if (!mounted) return;
        ToastUtils.motionToastCentered1500MS(
          message: jsonDecode(response.body)['message'],
          context: context,
        );
        setState(() {
          isPrintingLabel = false;
        });
      } else {
        if (!mounted) return;
        ToastUtils.motionToastCentered1500MS(
          message: kerrorString,
          context: context,
        );
        setState(() {
          isPrintingLabel = false;
        });
      }
    } on Exception catch (e) {
      log('GET ORDERS DETAILS WITH LABEL API EXCEPTION >>---> ${e.toString()}');
      ToastUtils.motionToastCentered1500MS(
        message: e.toString(),
        context: context,
      );
      setState(() {
        isPrintingLabel = false;
      });
    }
  }

  ///NEW PRINT NODE API
  Future<void> sendPrintJob({
    required String apiKey,
    required int printerId,
    required String printerName,
    required String orderNumber,
    required String labelPdfUrl,
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
      "title": 'Order - $orderNumber',
      "contentType": "pdf_uri",
      "content": labelPdfUrl,
      "source": "Pack and Scan Web New"
    });

    try {
      var response =
          await http.post(Uri.parse(uri), body: body, headers: header).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          Fluttertoast.showToast(msg: kTimeOut);
          return http.Response('Error', 408);
        },
      );
      log('SEND PRINT JOB API STATUS CODE >>---> ${response.statusCode}');
      if (!mounted) return;
      if (response.statusCode == 201) {
        log('Label Sent to Printer $printerName Successfully');
        ToastUtils.motionToastCentered800MS(
          message: 'Label Sent to Printer $printerName Successfully',
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
}
