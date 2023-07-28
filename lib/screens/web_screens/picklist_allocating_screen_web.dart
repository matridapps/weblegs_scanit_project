import 'dart:convert';
import 'dart:developer';

import 'package:absolute_app/core/utils/constants.dart';
import 'package:absolute_app/core/utils/toast_utils.dart';
import 'package:absolute_app/models/get_picklist_details_response.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:parse_server_sdk/parse_server_sdk.dart';
import 'package:rounded_loading_button/rounded_loading_button.dart';

class PicklistAllocatingScreenWeb extends StatefulWidget {
  const PicklistAllocatingScreenWeb({
    Key? key,
    required this.batchId,
    required this.appBarName,
    required this.picklist,
    required this.status,
    required this.showPickedOrders,
    required this.totalQty,
    required this.picklistLength,
  }) : super(key: key);

  final String batchId;
  final String appBarName;
  final String picklist;
  final String status;
  final bool showPickedOrders;
  final String totalQty;
  final int picklistLength;

  @override
  State<PicklistAllocatingScreenWeb> createState() =>
      _PicklistAllocatingScreenWebState();
}

class _PicklistAllocatingScreenWebState extends State<PicklistAllocatingScreenWeb> {
  final RoundedLoadingButtonController allocateController =
      RoundedLoadingButtonController();

  List<SkuXX> details = [];
  List<String> locationsList = [];
  Map<String, int> quantityMap = {};
  List<bool> checkBoxValueList = [];

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
        body: isScreenVisible == false
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
                        padding: const EdgeInsets.only(top: 30),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text(
                              'Total Qty to Pick -',
                              style: TextStyle(
                                fontSize: 22,
                              ),
                            ),
                            Text(
                              widget.totalQty,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 30),
                        child: Row(
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
                                            'Split Location',
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
                                            'Location',
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
                      ),
                      Visibility(
                        visible: locationsList.length > 1,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 30),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SizedBox(
                                height: 35,
                                width: 200,
                                child: RoundedLoadingButton(
                                  color: appColor,
                                  borderRadius: 0,
                                  elevation: 10,
                                  height: 50,
                                  width: 200,
                                  successIcon: Icons.check_rounded,
                                  failedIcon: Icons.close_rounded,
                                  successColor: Colors.green,
                                  errorColor: appColor,
                                  controller: allocateController,
                                  onPressed: () async {
                                    if (checkBoxValueList
                                        .any((e) => e == true)) {
                                      if (locationsList.contains(
                                          'Warehouse Location Not Available')) {
                                        if (checkBoxValueList
                                                .where((e) => e == true)
                                                .toList()
                                                .length >=
                                            checkBoxValueList.length - 1) {
                                          /// THROW TOAST
                                          ToastUtils.motionToastCentered(
                                              message:
                                                  'All Locations cannot Split. Please un-tick at least one location.',
                                              context: context);
                                          allocateController.reset();
                                        } else {
                                          List<int> tempList = [];
                                          List<String> locationsToSent = [];
                                          for (int i = 0;
                                              i < checkBoxValueList.length;
                                              i++) {
                                            if (checkBoxValueList[i] == true) {
                                              tempList.add(i);
                                            }
                                          }
                                          log('V tempList >>---> $tempList');

                                          for (int i = 0;
                                              i < tempList.length;
                                              i++) {
                                            locationsToSent.add(
                                                locationsList[tempList[i]]);
                                          }
                                          log('V locationsToSent >>---> $locationsToSent');

                                          await splitPicklist(
                                                  batchId: widget.batchId,
                                                  locations:
                                                      locationsToSent.join(','))
                                              .whenComplete(() => savePickListData(
                                                  picklist:
                                                      '${widget.picklist}-${locationsToSent[locationsToSent.length - 1]}',
                                                  pickListLength: widget
                                                          .picklistLength +
                                                      locationsToSent.length))
                                              .whenComplete(() async =>
                                                  await Future.delayed(
                                                      const Duration(
                                                          seconds: 1), () {
                                                    allocateController.reset();
                                                    Navigator.pop(
                                                        context, true);
                                                  }));
                                        }
                                      } else {
                                        /// DOES NOT HAVE 'NA' LOCATIONS >> JUST
                                        /// CHECK THAT NOT ALL CHECK BOXES ARE
                                        /// TICKED.
                                        if (checkBoxValueList
                                            .every((e) => e == true)) {
                                          /// THROW TOAST
                                          ToastUtils.motionToastCentered(
                                              message:
                                                  'All Locations cannot Split. Please un-tick at least one location.',
                                              context: context);
                                          allocateController.reset();
                                        } else {
                                          List<int> tempList = [];
                                          List<String> locationsToSent = [];
                                          for (int i = 0;
                                              i < checkBoxValueList.length;
                                              i++) {
                                            if (checkBoxValueList[i] == true) {
                                              tempList.add(i);
                                            }
                                          }
                                          log('V tempList >>---> $tempList');

                                          for (int i = 0;
                                              i < tempList.length;
                                              i++) {
                                            locationsToSent.add(
                                                locationsList[tempList[i]]);
                                          }
                                          log('V locationsToSent >>---> $locationsToSent');

                                          await splitPicklist(
                                                  batchId: widget.batchId,
                                                  locations:
                                                      locationsToSent.join(','))
                                              .whenComplete(() => savePickListData(
                                                  picklist:
                                                      '${widget.picklist}-${locationsToSent[locationsToSent.length - 1]}',
                                                  pickListLength: widget
                                                          .picklistLength +
                                                      locationsToSent.length))
                                              .whenComplete(() async =>
                                                  await Future.delayed(
                                                      const Duration(
                                                          seconds: 1), () {
                                                    allocateController.reset();
                                                    Navigator.pop(
                                                        context, true);
                                                  }));
                                        }
                                      }
                                    } else {
                                      Navigator.pop(context, false);
                                    }
                                  },
                                  child: const Text(
                                    'Allocate Picklist',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  List<TableRow> _listOfTableRowForAllocationScreen() {
    return List.generate(
        locationsList.length,
        (index) => TableRow(
              children: <TableCell>[
                TableCell(
                  child: SizedBox(
                    height: 40,
                    child: Center(
                      child: locationsList.length == 1
                          ? const SizedBox()
                          : locationsList[index] ==
                                  'Warehouse Location Not Available'
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
                        locationsList[index],
                        style: const TextStyle(
                          fontSize: 18,
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
                        '${quantityMap[locationsList[index]]}',
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

  void detailsApis() async {
    if (widget.status != 'Processing.......') {
      await getPickListDetailsForAllocation(
        batchId: widget.batchId,
        showPickedOrders: widget.showPickedOrders,
      );
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
    required String locations,
  }) async {
    String uri =
        'https://weblegs.info/JadlamApp/api/SplitPicklist?BatchId=$batchId&locations=$locations';
    log('SPLIT PICKLIST API URI >>---> $uri');

    try {
      var response = await http.get(Uri.parse(uri)).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          ToastUtils.motionToastCentered1500MS(
              message: kTimeOut, context: context);
          return http.Response('Error', 408);
        },
      );

      if (response.statusCode == 200) {
        log('SPLIT PICKLIST API RESPONSE >>---> ${jsonDecode(response.body)}');

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
      log(e.toString());
      ToastUtils.showCenteredLongToast(message: e.toString());
    }
  }

  Future<void> getPickListDetailsForAllocation({
    required String batchId,
    required bool showPickedOrders,
  }) async {
    String uri =
        'https://weblegs.info/JadlamApp/api/GetPicklistByBatchId?BatchId=$batchId&ShowPickedOrders=$showPickedOrders';
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
        log('getPickListDetails response >>>>> ${jsonDecode(response.body)}');

        GetPicklistDetailsResponse getPicklistDetailsResponse =
            GetPicklistDetailsResponse.fromJson(jsonDecode(response.body));
        log('getPicklistDetailsResponse >>>>>>>> ${jsonEncode(getPicklistDetailsResponse)}');

        details = [];
        details.addAll(getPicklistDetailsResponse.sku.map((e) => e));

        locationsList = [];
        List<String> tempList = [];
        tempList.addAll(details.map((e) => e.warehouseLocation.isEmpty
            ? 'Warehouse Location Not Available'
            : e.warehouseLocation));
        log('V tempList >>---> $tempList');
        locationsList.addAll(tempList.toSet().toList().map((e) => e));
        log('V locationsList >>---> $locationsList');

        checkBoxValueList = [];
        checkBoxValueList
            .addAll(List.generate(locationsList.length, (index) => false));
        log('V checkBoxValueList >>---> $checkBoxValueList');

        quantityMap = {};
        for (var x in tempList) {
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
