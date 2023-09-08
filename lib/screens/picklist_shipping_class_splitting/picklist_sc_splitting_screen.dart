import 'dart:convert';
import 'dart:developer';

import 'package:absolute_app/core/utils/constants.dart';
import 'package:absolute_app/core/utils/toast_utils.dart';
import 'package:absolute_app/models/get_picklist_details_response.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:parse_server_sdk/parse_server_sdk.dart';
import 'package:rounded_loading_button/rounded_loading_button.dart';
import 'package:http/http.dart' as http;

class PicklistSCSplittingScreen extends StatefulWidget {
  const PicklistSCSplittingScreen({
    super.key,
    required this.batchId,
    required this.appBarName,
    required this.picklist,
    required this.status,
    required this.picklistLength,
    required this.totalOrders,
  });

  final String batchId;
  final String appBarName;
  final String picklist;
  final String status;
  final String totalOrders;
  final int picklistLength;

  @override
  State<PicklistSCSplittingScreen> createState() =>
      _PicklistSCSplittingScreenState();
}

class _PicklistSCSplittingScreenState
    extends State<PicklistSCSplittingScreen> {
  final RoundedLoadingButtonController allocateController =
      RoundedLoadingButtonController();

  List<SkuXX> details = [];
  List<String> scList = [];
  List<bool> checkBoxValueList = [];
  Map<String, int> quantityMap = {};

  bool isScreenVisible = false;
  bool isSplitSuccessful = false;

  @override
  void initState() {
    super.initState();
    detailsApis();
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, false);
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          backgroundColor: Colors.white,
          automaticallyImplyLeading: (kIsWeb == true) ? false : true,
          leading: IconButton(
            onPressed: () {
              Navigator.pop(context, false);
            },
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          iconTheme: const IconThemeData(color: Colors.black),
          centerTitle: true,
          toolbarHeight: AppBar().preferredSize.height,
          title: Text(
            widget.appBarName,
            style: TextStyle(
              fontSize: (size.width <= 1000) ? 22 : 27,
              color: Colors.black,
            ),
          ),
        ),
        body: kIsWeb
        ? isScreenVisible == false
            ? const Center(
          child: CircularProgressIndicator(
            color: appColor,
          ),
        )
            : Padding(
          padding: EdgeInsets.symmetric(
            vertical: size.height * .01,
            horizontal: size.width * .035,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'Total Orders Count -',
                        style: TextStyle(
                          fontSize: 22,
                        ),
                      ),
                      Text(
                        widget.totalOrders,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    ],
                  ),
                ),
                Visibility(
                  visible: scList.length > 1 &&
                      checkBoxValueList.any((e) => e == true),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        RoundedLoadingButton(
                          color: Colors.green,
                          borderRadius: 10,
                          elevation: 10,
                          height: 40,
                          width: 300,
                          successIcon: Icons.check_rounded,
                          failedIcon: Icons.close_rounded,
                          successColor: Colors.green,
                          errorColor: appColor,
                          controller: allocateController,
                          onPressed: () async =>
                              splitAndAllocatePicklist(),
                          child: const Text(
                            'Split & Allocate Picklist',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Table(
                      border: TableBorder.all(
                        color: Colors.black,
                        width: 1,
                      ),
                      columnWidths: <int, TableColumnWidth>{
                        0: FixedColumnWidth(size.width * .25),
                        1: FixedColumnWidth(size.width * .25),
                        2: FixedColumnWidth(size.width * .25),
                      },
                      children: [
                        TableRow(
                          children: <TableCell>[
                            TableCell(
                              child: Container(
                                height: 40,
                                color: Colors.grey.shade200,
                                child: const Center(
                                  child: Text(
                                    'Split Shipping Class',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            TableCell(
                              child: Container(
                                height: 40,
                                color: Colors.grey.shade200,
                                child: const Center(
                                  child: Text(
                                    'Shipping Class',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            TableCell(
                              child: Container(
                                height: 40,
                                color: Colors.grey.shade200,
                                child: const Center(
                                  child: Text(
                                    'Quantity',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        ..._listOfTableRowForAllocationScreen(),
                      ],
                    )
                  ],
                ),
              ],
            ),
          ),
        )
        : isScreenVisible == false
            ? const Center(
                child: CircularProgressIndicator(
                  color: appColor,
                ),
              )
            : Padding(
                padding: EdgeInsets.symmetric(
                  vertical: size.height * .01,
                  horizontal: size.width * .025,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text(
                              'Total Orders Count -',
                              style: TextStyle(
                                fontSize: 22,
                              ),
                            ),
                            Text(
                              widget.totalOrders,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          ],
                        ),
                      ),
                      Visibility(
                        visible: scList.length > 1 &&
                            checkBoxValueList.any((e) => e == true),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 15),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              RoundedLoadingButton(
                                color: Colors.green,
                                borderRadius: 10,
                                elevation: 10,
                                height: 40,
                                width: 300,
                                successIcon: Icons.check_rounded,
                                failedIcon: Icons.close_rounded,
                                successColor: Colors.green,
                                errorColor: appColor,
                                controller: allocateController,
                                onPressed: () async =>
                                    splitAndAllocatePicklist(),
                                child: const Text(
                                  'Split & Allocate Picklist',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Table(
                            border: TableBorder.all(
                              color: Colors.black,
                              width: 1,
                            ),
                            columnWidths: <int, TableColumnWidth>{
                              0: FixedColumnWidth(size.width * .25),
                              1: FixedColumnWidth(size.width * .45),
                              2: FixedColumnWidth(size.width * .25),
                            },
                            children: [
                              TableRow(
                                children: <TableCell>[
                                  TableCell(
                                    child: Container(
                                      height: 40,
                                      color: Colors.grey.shade200,
                                      child: const Center(
                                        child: Text(
                                          'Split',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  TableCell(
                                    child: Container(
                                      height: 40,
                                      color: Colors.grey.shade200,
                                      child: const Center(
                                        child: Text(
                                          'Shipping Class',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  TableCell(
                                    child: Container(
                                      height: 40,
                                      color: Colors.grey.shade200,
                                      child: const Center(
                                        child: Text(
                                          'Quantity',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              ..._listOfTableRowForAllocationScreen(),
                            ],
                          )
                        ],
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  List<TableRow> _listOfTableRowForAllocationScreen() {
    return List.generate(
        scList.length,
        (index) => TableRow(
              children: <TableCell>[
                TableCell(
                  child: SizedBox(
                    height: 40,
                    child: Center(
                      child: scList.length == 1
                          ? const SizedBox()
                          : scList[index] == 'Shipping Class Not Available'
                              ? const SizedBox()
                              : Checkbox(
                                  activeColor: appColor,
                                  value: checkBoxValueList[index],
                                  onChanged: (bool? newValue) {
                                    setState(() {
                                      checkBoxValueList[index] =
                                          !(checkBoxValueList[index]);
                                    });
                                    log('V checkBoxValueList At $index >>---> ${checkBoxValueList[index]}');
                                  },
                                ),
                    ),
                  ),
                ),
                TableCell(
                  child: SizedBox(
                    height: 40,
                    child: Center(
                      child: Text(
                        scList[index],
                        style: const TextStyle(
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
                TableCell(
                  child: SizedBox(
                    height: 40,
                    child: Center(
                      child: Text(
                        '${quantityMap[scList[index]]}',
                        style: const TextStyle(
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ));
  }

  void splitAndAllocatePicklist() async {
    if (checkBoxValueList.any((e) => e == true)) {
      if (scList.contains('Shipping Class Not Available')) {
        if (checkBoxValueList.where((e) => e == true).toList().length >=
            checkBoxValueList.length - 1) {
          ToastUtils.motionToastCentered(
            message:
                'All Shipping Classes cannot Split. Please un-tick at least one shipping class.',
            context: context,
          );
          allocateController.reset();
        } else {
          List<int> tempList = [];
          List<String> scToSent = [];
          for (int i = 0; i < checkBoxValueList.length; i++) {
            if (checkBoxValueList[i] == true) {
              tempList.add(i);
            }
          }
          log('V tempList >>---> $tempList');

          for (int i = 0; i < tempList.length; i++) {
            scToSent.add(scList[tempList[i]]);
          }
          log('V scToSent >>---> $scToSent');

          await splitPicklist(batchId: widget.batchId, sc: scToSent.join(','))
              .whenComplete(() {
            savePickListData(
              picklist: '${widget.picklist}-${scToSent.join('-')}',
              pickListLength: widget.picklistLength + scToSent.length,
            );
          }).whenComplete(() async {
            await Future.delayed(const Duration(seconds: 1), () {
              allocateController.reset();
              Navigator.pop(context, true);
            });
          });
        }
      } else {
        /// DOES NOT HAVE 'NA' SC, CHECK THAT NOT ALL CHECK BOXES ARE TICKED.
        if (checkBoxValueList.every((e) => e == true)) {
          ToastUtils.motionToastCentered(
            message:
                'All Shipping Classes cannot Split. Please un-tick at least one shipping class.',
            context: context,
          );
          allocateController.reset();
        } else {
          List<int> tempList = [];
          List<String> scToSent = [];
          for (int i = 0; i < checkBoxValueList.length; i++) {
            if (checkBoxValueList[i] == true) {
              tempList.add(i);
            }
          }
          log('V tempList >>---> $tempList');

          for (int i = 0; i < tempList.length; i++) {
            scToSent.add(scList[tempList[i]]);
          }
          log('V scToSent >>---> $scToSent');

          await splitPicklist(batchId: widget.batchId, sc: scToSent.join(','))
              .whenComplete(() {
            savePickListData(
              picklist: '${widget.picklist}-${scToSent.join('-')}',
              pickListLength: widget.picklistLength + scToSent.length,
            );
          }).whenComplete(() async {
            await Future.delayed(const Duration(seconds: 1), () {
              allocateController.reset();
              Navigator.pop(context, true);
            });
          });
        }
      }
    } else {
      Navigator.pop(context, false);
    }
  }

  void detailsApis() async {
    if (widget.status != 'Processing.......') {
      await getPickListDetailsForAllocation(widget.batchId);
    } else {
      setState(() {
        isScreenVisible = true;
      });
    }
  }

  void savePickListData({
    required String picklist,
    required int pickListLength,
  }) async {
    var picklistData = ParseObject('picklists_data')
      ..objectId = 'tNeOL7aEYx'
      ..set('last_created_picklist', picklist)
      ..set('picklist_length', pickListLength);
    await picklistData.save();
  }

  Future<void> splitPicklist({
    required String batchId,
    required String sc,
  }) async {
    String uri =
        'https://weblegs.info/JadlamApp/api/CreatePicklistforShippingClass?BatchId=$batchId&Shippingclass=$sc';
    log('SPLIT PICKLIST SC API URI >>---> $uri');

    try {
      var response = await http.get(Uri.parse(uri)).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          ToastUtils.motionToastCentered1500MS(
              message: kTimeOut, context: context);
          return http.Response('Error', 408);
        },
      );

      log('SPLIT PICKLIST SC API STATUS CODE >>---> ${response.statusCode}');

      if (response.statusCode == 200) {
        log('SPLIT PICKLIST SC API RESPONSE >>---> ${jsonDecode(response.body)}');

        ToastUtils.showCenteredShortToast(
            message: jsonDecode(response.body)['message'].toString());
        setState(() {
          isSplitSuccessful = true;
        });
      } else {
        ToastUtils.showCenteredLongToast(
            message: jsonDecode(response.body)['message'].toString());
        setState(() {
          isSplitSuccessful = false;
        });
      }
    } on Exception catch (e) {
      log('SPLIT PICKLIST SC API EXCEPTION >>---> ${e.toString()}');
      ToastUtils.showCenteredLongToast(message: e.toString());
    }
  }

  Future<void> getPickListDetailsForAllocation(batchId) async {
    String uri =
        'https://weblegs.info/JadlamApp/api/GetPicklistByBatchId?BatchId=$batchId&ShowPickedOrders=false';
    log('getPickListDetails uri - $uri');
    setState(() {
      isScreenVisible = false;
    });
    try {
      var response = await http.get(Uri.parse(uri)).timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          ToastUtils.showShortToast(message: kTimeOut);
          setState(() {
            isScreenVisible = true;
          });
          return http.Response('Error', 408);
        },
      );

      if (response.statusCode == 200) {
        GetPicklistDetailsResponse getPicklistDetailsResponse =
            GetPicklistDetailsResponse.fromJson(jsonDecode(response.body));

        details = [];
        details.addAll(getPicklistDetailsResponse.sku.map((e) => e));

        scList = [];

        List<List<OrderQuantity>> tempList = [];
        List<String> tempScList = [];
        tempList.addAll(details.map((e) => e.orderQuantity));
        log('V tempList >>---> $tempList');

        for (int i = 0; i < tempList.length; i++) {
          tempScList.addAll(tempList[i].map((e) => e.shippingClass));
        }
        log('tempScList length >>---> ${tempScList.length}');
        log('order Count >>---> ${widget.totalOrders}');

        scList.addAll(tempScList.toSet().toList().map((e) => e));
        log('V scList >>---> $scList');

        checkBoxValueList = [];
        checkBoxValueList
            .addAll(List.generate(scList.length, (index) => false));
        log('V checkBoxValueList >>---> $checkBoxValueList');

        quantityMap = {};
        for (var x in tempScList) {
          quantityMap[x] =
              !quantityMap.containsKey(x) ? (1) : (quantityMap[x]! + 1);
        }
        log('V quantityMap >>---> $quantityMap');

        setState(() {
          isScreenVisible = true;
        });
      } else {
        ToastUtils.showCenteredShortToast(
            message: jsonDecode(response.body)['message'].toString());
        setState(() {
          isScreenVisible = true;
        });
      }
    } on Exception catch (e) {
      log(e.toString());
      ToastUtils.showCenteredLongToast(message: e.toString());
      setState(() {
        isScreenVisible = true;
      });
    }
  }
}
