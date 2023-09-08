import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:absolute_app/core/utils/constants.dart';
import 'package:absolute_app/core/utils/navigation_methods.dart';
import 'package:absolute_app/core/utils/responsive_check.dart';
import 'package:absolute_app/core/utils/toast_utils.dart';
import 'package:absolute_app/core/utils/common_screen_widgets/widgets.dart';
import 'package:absolute_app/models/get_locked_picklist_response.dart';
import 'package:absolute_app/models/get_picklist_details_response.dart';
import 'package:absolute_app/screens/mobile_device_screens/barcode_camera_screen.dart';
import 'package:absolute_app/screens/web_screens/ean_for_web.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_network/image_network.dart';
import 'package:intl/intl.dart';
import 'package:parse_server_sdk/parse_server_sdk.dart';
import 'package:rounded_loading_button/rounded_loading_button.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;

class PickListDetails extends StatefulWidget {
  const PickListDetails({
    Key? key,
    required this.batchId,
    required this.requestType,
    required this.appBarName,
    required this.isSKUAvailable,
    required this.status,
    required this.orderPicked,
    required this.partialOrders,
    required this.totalOrders,
    required this.accType,
    required this.authorization,
    required this.refreshToken,
    required this.profileId,
    required this.distCenterName,
    required this.distCenterId,
    required this.isStatusComplete,
    required this.showPickedOrders,
  }) : super(key: key);

  final String batchId;
  final String requestType;
  final String appBarName;
  final bool isSKUAvailable;
  final String status;
  final String orderPicked;
  final String partialOrders;
  final String totalOrders;
  final String accType;
  final String authorization;
  final String refreshToken;
  final int profileId;
  final String distCenterName;
  final int distCenterId;
  final bool isStatusComplete;
  final bool showPickedOrders;

  @override
  State<PickListDetails> createState() => _PickListDetailsState();
}

class _PickListDetailsState extends State<PickListDetails> {
  final RoundedLoadingButtonController validateController =
      RoundedLoadingButtonController();
  final RoundedLoadingButtonController printController =
      RoundedLoadingButtonController();
  final RoundedLoadingButtonController cancelController =
      RoundedLoadingButtonController();

  List<SkuXX> details = [];
  List<String> qtyToPick = [];
  List<List<String>> listOfOrderNumberList = [];
  List<List<TableRow>> tableForPicklistDetails = [];
  List<String> isLabelPrintedForNonMSMQW = [];
  List<ParseObject> savedLockedPicklistData = [];
  List<MsgX> lockedPicklistList = [];

  Map<dynamic, dynamic> skuInOrder = {};

  DateFormat dateFormat = DateFormat("M/d/yyyy h:mm:ss a");

  bool isDetailsVisible = false;
  bool isNextButton = false;
  bool isPrevButton = false;
  bool qtyToPickVisible = true;
  bool isUpdatedSuccessfully = false;
  bool isFlagUpdated = false;

  String flagError = '';
  String labelUrl = '';
  String labelError = '';

  int orderStart = 1;
  int totalOrder = 0;
  int skuStart = 1;
  int id = 1;

  @override
  void initState() {
    super.initState();
    detailsApis();
    Timer.periodic(const Duration(minutes: 30), (Timer t) async {
      await getSavedLockedPicklistData()
          .whenComplete(() => deleteOlderLockedPicklists())
          .whenComplete(() => Navigator.pop(context));
      t.cancel();
    });
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final FocusNode currentFocus = FocusScope.of(context);
    return WillPopScope(
      onWillPop: () async {
        await getSavedLockedPicklistData()
            .whenComplete(() async => deleteLockedPicklistData(
                id: lockedPicklistList[lockedPicklistList
                        .indexWhere((e) => e.batchId == widget.batchId)]
                    .id))
            .whenComplete(
              () => Navigator.pop(context),
            );
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          backgroundColor: Colors.white,
          automaticallyImplyLeading: (kIsWeb == true) ? false : true,
          leading: IconButton(
            tooltip: 'Back to Dashboard',
            onPressed: () async {
              await getSavedLockedPicklistData()
                  .whenComplete(() async => deleteLockedPicklistData(
                      id: lockedPicklistList[lockedPicklistList
                              .indexWhere((e) => e.batchId == widget.batchId)]
                          .id))
                  .whenComplete(() {
                Navigator.of(context).popUntil((route) => route.isFirst);
              });
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
        body: isDetailsVisible == false
            ? const Center(
                child: CircularProgressIndicator(
                  color: appColor,
                ),
              )
            : widget.isSKUAvailable == false && widget.showPickedOrders == false
                ? Center(
                    child: Text(
                      widget.status,
                      style: TextStyle(
                        fontSize: kIsWeb == true ? 25 : size.width * .045,
                      ),
                    ),
                  )
                : widget.isStatusComplete == true &&
                        widget.showPickedOrders == false
                    ? Center(
                        child: Text(
                          widget.requestType == 'MSMQW'
                              ? 'Picklist Status Complete\nAll Orders Picked!'
                              : 'Picklist Status Complete\nAll SKUs Picked!',
                          style: TextStyle(
                            fontSize: kIsWeb == true ? 25 : size.width * .045,
                          ),
                        ),
                      )
                    : GestureDetector(
                        onTap: () {
                          FocusScope.of(context).requestFocus(FocusNode());
                          if (!currentFocus.hasPrimaryFocus) {
                            currentFocus.unfocus();
                          }
                        },
                        child: kIsWeb == true
                            ? ResponsiveCheck.screenBiggerThan24inch(context)
                                ? _screenBiggerThan24InchBuilder(context, size)
                                : _screenSmallerThan24InchBuilder(context, size)
                            : _mobileScreenBuilder(context, size),
                      ),
      ),
    );
  }

  Widget _screenBiggerThan24InchBuilder(BuildContext context, Size size) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 10,
        horizontal: 60,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                },
                child: const MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Text(
                    'Go Back To Picklists',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.lightBlue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      widget.requestType == 'MSMQW'
                          ? 'Order $orderStart/${widget.showPickedOrders == true ? widget.orderPicked : totalOrder} Pick SKU $skuStart/${skuInOrder[details[id - 1].siteOrderId]}'
                          : 'Pick SKU $id/${details.length}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  ],
                ),
              )
            ],
          ),
          SingleChildScrollView(
            child: SizedBox(
              height: 750,
              width: size.width,
              child: isNextButton == true || isPrevButton == true
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: appColor,
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text(
                              details[id - 1].title == ''
                                  ? 'Not Available'
                                  : details[id - 1].title,
                              style: const TextStyle(fontSize: 20),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 10,
                          width: size.width,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            const Text(
                              "Location : ",
                              style: TextStyle(
                                fontSize: 20,
                              ),
                            ),
                            Text(
                              details[id - 1].warehouseLocation == ''
                                  ? 'Not Available'
                                  : details[id - 1].warehouseLocation,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 10,
                          width: size.width,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            const Text(
                              "Barcode : ",
                              style: TextStyle(
                                fontSize: 20,
                              ),
                            ),
                            Text(
                              details[id - 1].ean == ''
                                  ? 'Not Available'
                                  : details[id - 1].ean,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Visibility(
                          visible: widget.appBarName.substring(0, 4) != 'Shop',
                          child: SizedBox(
                            height: 10,
                            width: size.width,
                          ),
                        ),
                        Visibility(
                          visible: widget.appBarName.substring(0, 4) != 'Shop',
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              const Text(
                                "SKU : ",
                                style: TextStyle(
                                  fontSize: 20,
                                ),
                              ),
                              Text(
                                details[id - 1].sku == ''
                                    ? 'Not Available'
                                    : details[id - 1].sku,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Visibility(
                          visible: /*widget.requestType == 'MSMQW'*/ true,
                          child: SizedBox(
                            height: 10,
                            width: size.width,
                          ),
                        ),
                        Visibility(
                          visible: widget.appBarName.substring(0, 4) != 'Shop',
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              const Text(
                                "Order Id : ",
                                style: TextStyle(
                                  fontSize: 20,
                                ),
                              ),
                              Text(
                                details[id - 1].orderNumber == ''
                                    ? 'Not Available'
                                    : details[id - 1].orderNumber,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Visibility(
                          visible: widget.appBarName.substring(0, 4) != 'Shop',
                          child: SizedBox(
                            height: 10,
                            width: size.width,
                          ),
                        ),
                        Visibility(
                          visible: widget.appBarName.substring(0, 4) != 'Shop',
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              const Text(
                                "Shipping Carrier : ",
                                style: TextStyle(fontSize: 20),
                              ),
                              Text(
                                widget.requestType == 'MSMQW'
                                    ? details[id - 1].shippingCarrierForMsmqw ==
                                            ''
                                        ? 'Not Available'
                                        : details[id - 1]
                                            .shippingCarrierForMsmqw
                                    : details[id - 1]
                                        .orderQuantity
                                        .map((e) => e.shippingCarrier)
                                        .join(', '),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Visibility(
                          visible: widget.appBarName.substring(0, 4) != 'Shop',
                          child: SizedBox(
                            height: 10,
                            width: size.width,
                          ),
                        ),
                        Visibility(
                          visible: widget.appBarName.substring(0, 4) != 'Shop',
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              const Text(
                                "Shipping Class : ",
                                style: TextStyle(fontSize: 20),
                              ),
                              Text(
                                widget.requestType == 'MSMQW'
                                    ? details[id - 1].shippingClassForMsmqw ==
                                            ''
                                        ? 'Not Available'
                                        : details[id - 1].shippingClassForMsmqw
                                    : details[id - 1]
                                        .orderQuantity
                                        .map((e) => e.shippingClass)
                                        .join(', '),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Visibility(
                          visible: /*widget.requestType == 'MSMQW' &&*/
                              widget.showPickedOrders == true &&
                                  widget.appBarName.substring(0, 4) != 'Shop',
                          child: SizedBox(
                            height: 10,
                            width: size.width,
                          ),
                        ),
                        Visibility(
                          visible: /*widget.requestType == 'MSMQW' &&*/
                              widget.showPickedOrders == true &&
                                  widget.appBarName.substring(0, 4) != 'Shop',
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              const Text(
                                "Label Printed : ",
                                style: TextStyle(fontSize: 20),
                              ),
                              Text(
                                widget.requestType == 'MSMQW'
                                    ? (details[id - 1]
                                                .shippingClassForMsmqw
                                                .toLowerCase()
                                                .contains('prime') ||
                                            details[id - 1]
                                                .shippingCarrierForMsmqw
                                                .toLowerCase()
                                                .contains('prime'))
                                        ? details[id - 1].amazonLabelPrinted ==
                                                true
                                            ? 'Yes'
                                            : 'No'
                                        : details[id - 1]
                                                    .easyPostLabelPrinted ==
                                                true
                                            ? 'Yes'
                                            : 'No'
                                    : isLabelPrintedForNonMSMQW[id - 1],
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Visibility(
                          visible: /*widget.requestType != 'MSMQW'*/ false,
                          child: SizedBox(
                            height: 10,
                            width: size.width,
                          ),
                        ),
                        Visibility(
                          visible: /*widget.requestType != 'MSMQW'*/ false,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Table(
                                  border: TableBorder.all(
                                      color: Colors.black, width: 1),
                                  columnWidths: <int, TableColumnWidth>{
                                    0: FixedColumnWidth(size.width * .1),
                                    1: FixedColumnWidth(size.width * .2),
                                    2: FixedColumnWidth(size.width * .2),
                                    3: FixedColumnWidth(size.width * .1),
                                  },
                                  children: [
                                    TableRow(
                                      children: <TableCell>[
                                        TableCell(
                                          child: Container(
                                            height: 30,
                                            color: Colors.grey.shade200,
                                            child: const Center(
                                              child: Text(
                                                'Order Number',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        TableCell(
                                          child: Container(
                                            height: 30,
                                            color: Colors.grey.shade200,
                                            child: const Center(
                                              child: Text(
                                                'Shipping Carrier',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        TableCell(
                                          child: Container(
                                            height: 30,
                                            color: Colors.grey.shade200,
                                            child: const Center(
                                              child: Text(
                                                'Shipping Class',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        if (widget.showPickedOrders == true)
                                          TableCell(
                                            child: Container(
                                              height: 30,
                                              color: Colors.grey.shade200,
                                              child: const Center(
                                                child: Text(
                                                  'Label Printed',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    ...tableForPicklistDetails[id - 1],
                                  ]),
                            ],
                          ),
                        ),
                        Visibility(
                          visible: widget.requestType == 'MSMQW',
                          child: SizedBox(
                            height: 10,
                            width: size.width,
                          ),
                        ),
                        Visibility(
                          visible: widget.requestType == 'MSMQW',
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              const Text(
                                "Distribution Center : ",
                                style: TextStyle(
                                  fontSize: 10,
                                ),
                              ),
                              Text(
                                details[id - 1].distributionCenter == ''
                                    ? 'Not Available'
                                    : details[id - 1].distributionCenter,
                                style: TextStyle(
                                  fontSize: size.width * .012,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: 15,
                          width: size.width,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              height: 400,
                              width: 400,
                              child: Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                elevation: 10,
                                child: details[id - 1].url.isEmpty
                                    ? Image.asset(
                                        'assets/no_image/no_image.png',
                                        height: 400,
                                        width: 400,
                                        fit: BoxFit.contain,
                                      )
                                    : ImageNetwork(
                                        image: details[id - 1].url,
                                        imageCache: CachedNetworkImageProvider(
                                          details[id - 1].url,
                                        ),
                                        height: 400,
                                        width: 400,
                                        duration: 50,
                                        fitAndroidIos: BoxFit.contain,
                                        fitWeb: BoxFitWeb.contain,
                                        onLoading: Shimmer(
                                          duration: const Duration(seconds: 3),
                                          interval: const Duration(seconds: 5),
                                          color: Colors.white,
                                          colorOpacity: 1,
                                          enabled: true,
                                          direction:
                                              const ShimmerDirection.fromLTRB(),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              color: const Color.fromARGB(
                                                160,
                                                192,
                                                192,
                                                192,
                                              ),
                                            ),
                                          ),
                                        ),
                                        onError: Image.asset(
                                          'assets/no_image/no_image.png',
                                          height: 400,
                                          width: 400,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 20,
                          width: size.width,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              widget.showPickedOrders == true
                                  ? "Picked Quantity : "
                                  : "Qty to Pick : ",
                              style: const TextStyle(
                                fontSize: 20,
                              ),
                            ),
                            qtyToPickVisible == false
                                ? const Center(
                                    child: SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: FittedBox(
                                        child: CircularProgressIndicator(
                                          color: appColor,
                                        ),
                                      ),
                                    ),
                                  )
                                : Text(
                                    qtyToPick[id - 1],
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red,
                                    ),
                                  ),
                          ],
                        ),
                        SizedBox(
                          height: 20,
                          width: size.width,
                        ),
                        Visibility(
                          visible: widget.appBarName.substring(0, 4) != 'Shop',
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              details[id - 1].ean == ''
                                  ? Row(
                                      children: [
                                        const SelectableText(
                                          "Barcode missing for this SKU : ",
                                          style: TextStyle(
                                              color: Colors.red, fontSize: 20),
                                        ),
                                        SelectableText(
                                          details[id - 1].sku,
                                          style: const TextStyle(
                                            color: Colors.red,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 20,
                                          ),
                                        )
                                      ],
                                    )
                                  : Visibility(
                                      visible: widget.showPickedOrders == false,
                                      child: RoundedLoadingButton(
                                        color: appColor,
                                        borderRadius: 0,
                                        elevation: 10,
                                        height: 50,
                                        width: 100,
                                        successIcon: Icons.check_rounded,
                                        failedIcon: Icons.close_rounded,
                                        successColor: Colors.green,
                                        errorColor: appColor,
                                        controller: validateController,
                                        onPressed: () async => validate(
                                          screen: EANForWebApp(
                                            accType: widget.accType,
                                            authorization: widget.authorization,
                                            refreshToken: widget.refreshToken,
                                            crossVisible: false,
                                            screenType: 'picklist details',
                                            profileId: widget.profileId,
                                            distCenterName:
                                                widget.distCenterName,
                                            distCenterId: widget.distCenterId,
                                            barcodeToCheck: int.parse(
                                                details[id - 1].ean.isEmpty
                                                    ? '0'
                                                    : details[id - 1].ean),
                                          ),
                                        ),
                                        child: const Text(
                                          "Validate Scan",
                                          style: TextStyle(fontSize: 25),
                                        ),
                                      ),
                                    )
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              TextButton(
                onPressed: () async {
                  if (id > 1) {
                    if (skuStart > 1) {
                      skuStart = skuStart - 1;
                    } else if (skuStart == 1) {
                      skuStart = skuInOrder[details[id - 2].siteOrderId];
                    }
                    if (details[id - 1].siteOrderId !=
                        details[id - 2].siteOrderId) {
                      setState(() {
                        orderStart = orderStart - 1;
                      });
                    }

                    setState(() {
                      isPrevButton = true;
                      id = id - 1;
                    });
                    log("V id >>---> $id");
                    await Future.delayed(const Duration(milliseconds: 300), () {
                      setState(() {
                        isPrevButton = false;
                      });
                    });
                  }
                },
                child: Text(
                  'Previous',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: id == 1 ? Colors.grey : Colors.lightBlue,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () async {
                        if (id < details.length) {
                          if (skuStart <
                              skuInOrder[details[id - 1].siteOrderId]) {
                            skuStart = skuStart + 1;
                          }
                          if (details[id - 1].siteOrderId !=
                              details[id].siteOrderId) {
                            setState(() {
                              orderStart = orderStart + 1;
                              skuStart = 1;
                            });
                          }

                          setState(() {
                            isNextButton = true;
                            id = id + 1;
                          });
                          log("V id >>---> $id");
                          await Future.delayed(
                              const Duration(milliseconds: 300), () {
                            setState(() {
                              isNextButton = false;
                            });
                          });
                        }
                      },
                      child: Text(
                        'Next',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: id == details.length
                              ? Colors.grey
                              : Colors.lightBlue,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _screenSmallerThan24InchBuilder(BuildContext context, Size size) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: size.height * .005,
        horizontal: size.width * .035,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () async {
                  await getSavedLockedPicklistData()
                      .whenComplete(() async => deleteLockedPicklistData(
                          id: lockedPicklistList[lockedPicklistList.indexWhere(
                                  (e) => e.batchId == widget.batchId)]
                              .id))
                      .whenComplete(
                        () => Navigator.pop(context),
                      );
                },
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Text(
                    'Go Back To Picklists',
                    style: TextStyle(
                      fontSize: size.width * .01,
                      fontWeight: FontWeight.bold,
                      color: Colors.lightBlue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      widget.requestType == 'MSMQW'
                          ? 'Order $orderStart/${widget.showPickedOrders == true ? widget.orderPicked : totalOrder} ${widget.showPickedOrders ? 'Picked' : 'Pick'} SKU $skuStart/${skuInOrder[details[id - 1].siteOrderId]}'
                          : '${widget.showPickedOrders ? 'Picked' : 'Pick'} SKU $id/${details.length}',
                      style: TextStyle(
                        fontSize: size.width * .01,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  ],
                ),
              )
            ],
          ),
          SizedBox(
            height: size.height * .01,
            width: size.width,
          ),
          SizedBox(
            height: size.height * .81,
            width: size.width,
            child: isNextButton == true || isPrevButton == true
                ? const Center(
                    child: CircularProgressIndicator(
                      color: appColor,
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      SelectionArea(
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Text(
                                  details[id - 1].title == ''
                                      ? 'Not Available'
                                      : details[id - 1].title,
                                  style: TextStyle(
                                    fontSize: size.width * .012,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(
                              height: size.height * .008,
                              width: size.width,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Text(
                                  "Location : ",
                                  style: TextStyle(
                                    fontSize: size.width * .012,
                                  ),
                                ),
                                Text(
                                  details[id - 1].warehouseLocation == ''
                                      ? 'Not Available'
                                      : details[id - 1].warehouseLocation,
                                  style: TextStyle(
                                    fontSize: size.width * .012,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(
                              height: size.height * .008,
                              width: size.width,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Text(
                                  "Barcode : ",
                                  style: TextStyle(
                                    fontSize: size.width * .012,
                                  ),
                                ),
                                Text(
                                  details[id - 1].ean == ''
                                      ? 'Not Available'
                                      : details[id - 1].ean,
                                  style: TextStyle(
                                    fontSize: size.width * .012,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Visibility(
                              visible:
                                  widget.appBarName.substring(0, 4) != 'Shop',
                              child: SizedBox(
                                height: size.height * .008,
                                width: size.width,
                              ),
                            ),
                            Visibility(
                              visible:
                                  widget.appBarName.substring(0, 4) != 'Shop',
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Text(
                                    "SKU : ",
                                    style: TextStyle(
                                      fontSize: size.width * .012,
                                    ),
                                  ),
                                  Text(
                                    details[id - 1].sku == ''
                                        ? 'Not Available'
                                        : details[id - 1].sku,
                                    style: TextStyle(
                                      fontSize: size.width * .012,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Visibility(
                              visible: /*widget.requestType == 'MSMQW'*/ true,
                              child: SizedBox(
                                height: size.height * .008,
                                width: size.width,
                              ),
                            ),
                            Visibility(
                              visible:
                                  widget.appBarName.substring(0, 4) != 'Shop',
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Text(
                                    "Order Id : ",
                                    style: TextStyle(
                                      fontSize: size.width * .012,
                                    ),
                                  ),
                                  Text(
                                    details[id - 1].orderNumber == ''
                                        ? 'Not Available'
                                        : details[id - 1].orderNumber,
                                    style: TextStyle(
                                      fontSize: size.width * .012,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Visibility(
                              visible:
                                  widget.appBarName.substring(0, 4) != 'Shop',
                              child: SizedBox(
                                height: size.height * .008,
                                width: size.width,
                              ),
                            ),
                            Visibility(
                              visible:
                                  widget.appBarName.substring(0, 4) != 'Shop',
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Text(
                                    "Shipping Carrier : ",
                                    style:
                                        TextStyle(fontSize: size.width * .012),
                                  ),
                                  Text(
                                    widget.requestType == 'MSMQW'
                                        ? details[id - 1]
                                                    .shippingCarrierForMsmqw ==
                                                ''
                                            ? 'Not Available'
                                            : details[id - 1]
                                                .shippingCarrierForMsmqw
                                        : details[id - 1]
                                            .orderQuantity
                                            .map((e) => e.shippingCarrier)
                                            .join(', '),
                                    style: TextStyle(
                                      fontSize: size.width * .012,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Visibility(
                              visible:
                                  widget.appBarName.substring(0, 4) != 'Shop',
                              child: SizedBox(
                                height: size.height * .008,
                                width: size.width,
                              ),
                            ),
                            Visibility(
                              visible:
                                  widget.appBarName.substring(0, 4) != 'Shop',
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Text(
                                    "Shipping Class : ",
                                    style:
                                        TextStyle(fontSize: size.width * .012),
                                  ),
                                  Text(
                                    widget.requestType == 'MSMQW'
                                        ? details[id - 1]
                                                    .shippingClassForMsmqw ==
                                                ''
                                            ? 'Not Available'
                                            : details[id - 1]
                                                .shippingClassForMsmqw
                                        : details[id - 1]
                                            .orderQuantity
                                            .map((e) => e.shippingClass)
                                            .join(', '),
                                    style: TextStyle(
                                      fontSize: size.width * .012,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Visibility(
                              visible: /*widget.requestType == 'MSMQW' &&*/
                                  widget.showPickedOrders == true &&
                                      widget.appBarName.substring(0, 4) !=
                                          'Shop',
                              child: SizedBox(
                                height: size.height * .008,
                                width: size.width,
                              ),
                            ),
                            Visibility(
                              visible: /*widget.requestType == 'MSMQW' &&*/
                                  widget.showPickedOrders == true &&
                                      widget.appBarName.substring(0, 4) !=
                                          'Shop',
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Text(
                                    "Label Printed : ",
                                    style:
                                        TextStyle(fontSize: size.width * .012),
                                  ),
                                  Text(
                                    widget.requestType == 'MSMQW'
                                        ? (details[id - 1]
                                                    .shippingClassForMsmqw
                                                    .toLowerCase()
                                                    .contains('prime') ||
                                                details[id - 1]
                                                    .shippingCarrierForMsmqw
                                                    .toLowerCase()
                                                    .contains('prime'))
                                            ? details[id - 1]
                                                        .amazonLabelPrinted ==
                                                    true
                                                ? 'Yes'
                                                : 'No'
                                            : details[id - 1]
                                                        .easyPostLabelPrinted ==
                                                    true
                                                ? 'Yes'
                                                : 'No'
                                        : isLabelPrintedForNonMSMQW[id - 1],
                                    style: TextStyle(
                                      fontSize: size.width * .012,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Visibility(
                              visible: /*widget.requestType != 'MSMQW'*/ false,
                              child: SizedBox(
                                height: size.height * .008,
                                width: size.width,
                              ),
                            ),
                            Visibility(
                              visible: /*widget.requestType != 'MSMQW'*/ false,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Table(
                                      border: TableBorder.all(
                                          color: Colors.black, width: 1),
                                      columnWidths: <int, TableColumnWidth>{
                                        0: FixedColumnWidth(size.width * .1),
                                        1: FixedColumnWidth(size.width * .2),
                                        2: FixedColumnWidth(size.width * .2),
                                        3: FixedColumnWidth(size.width * .1),
                                      },
                                      children: [
                                        TableRow(
                                          children: <TableCell>[
                                            TableCell(
                                              child: Container(
                                                height: 30,
                                                color: Colors.grey.shade200,
                                                child: const Center(
                                                  child: Text(
                                                    'Order Number',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            TableCell(
                                              child: Container(
                                                height: 30,
                                                color: Colors.grey.shade200,
                                                child: const Center(
                                                  child: Text(
                                                    'Shipping Carrier',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            TableCell(
                                              child: Container(
                                                height: 30,
                                                color: Colors.grey.shade200,
                                                child: const Center(
                                                  child: Text(
                                                    'Shipping Class',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            if (widget.showPickedOrders == true)
                                              TableCell(
                                                child: Container(
                                                  height: 30,
                                                  color: Colors.grey.shade200,
                                                  child: const Center(
                                                    child: Text(
                                                      'Label Printed',
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        ...tableForPicklistDetails[id - 1],
                                      ]),
                                ],
                              ),
                            ),
                            Visibility(
                              visible: widget.requestType == 'MSMQW',
                              child: SizedBox(
                                height: size.height * .008,
                                width: size.width,
                              ),
                            ),
                            Visibility(
                              visible: widget.requestType == 'MSMQW',
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Text(
                                    "Distribution Center : ",
                                    style: TextStyle(
                                      fontSize: size.width * .012,
                                    ),
                                  ),
                                  Text(
                                    details[id - 1].distributionCenter == ''
                                        ? 'Not Available'
                                        : details[id - 1].distributionCenter,
                                    style: TextStyle(
                                      fontSize: size.width * .012,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              height: size.height * .01,
                              width: size.width,
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              height: webImageSizeIfOrdersMoreThan3(size),
                              width: webImageSizeIfOrdersMoreThan3(size),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.grey,
                                  width: 0.25,
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Center(
                                child: details[id - 1].url.isEmpty
                                    ? Image.asset(
                                        'assets/no_image/no_image.png',
                                        height:
                                            webImageSizeIfOrdersMoreThan3(size),
                                        width:
                                            webImageSizeIfOrdersMoreThan3(size),
                                        fit: BoxFit.contain,
                                      )
                                    : ImageNetwork(
                                        borderRadius: BorderRadius.circular(20),
                                        image: details[id - 1].url,
                                        imageCache: CachedNetworkImageProvider(
                                          details[id - 1].url,
                                        ),
                                        height:
                                            webImageSizeIfOrdersMoreThan3(size),
                                        width:
                                            webImageSizeIfOrdersMoreThan3(size),
                                        fitWeb: BoxFitWeb.contain,
                                        onLoading: Shimmer(
                                          duration: const Duration(seconds: 2),
                                          colorOpacity: 1,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              color: const Color.fromARGB(
                                                  160, 192, 192, 192),
                                            ),
                                          ),
                                        ),
                                        onError: Image.asset(
                                          'assets/no_image/no_image.png',
                                          height: webImageSizeIfOrdersMoreThan3(
                                              size),
                                          width: webImageSizeIfOrdersMoreThan3(
                                              size),
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                              ),
                            ),
                            SizedBox(
                              height: size.height * .02,
                              width: size.width,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SelectableText(
                                  widget.showPickedOrders == true
                                      ? "Picked Quantity : "
                                      : "Qty to Pick : ",
                                  style: TextStyle(
                                    fontSize: size.width * .012,
                                  ),
                                ),
                                qtyToPickVisible == false
                                    ? const Center(
                                        child: SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: FittedBox(
                                            child: CircularProgressIndicator(
                                              color: appColor,
                                            ),
                                          ),
                                        ),
                                      )
                                    : SelectableText(
                                        qtyToPick[id - 1],
                                        style: TextStyle(
                                          fontSize: size.width * .012,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.red,
                                        ),
                                      ),
                              ],
                            ),
                            SizedBox(
                              height: size.height * .02,
                              width: size.width,
                            ),
                            Visibility(
                              visible:
                                  widget.appBarName.substring(0, 4) != 'Shop',
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  details[id - 1].ean == ''
                                      ? Row(children: [
                                          const SelectableText(
                                            "Barcode missing for this SKU : ",
                                            style: TextStyle(
                                                color: Colors.red,
                                                fontSize: 20),
                                          ),
                                          SelectableText(
                                            details[id - 1].sku,
                                            style: const TextStyle(
                                              color: Colors.red,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 20,
                                            ),
                                          )
                                        ])
                                      : Visibility(
                                          visible:
                                              parseToInt(qtyToPick[id - 1]) > 0,
                                          child: Visibility(
                                            visible: widget.showPickedOrders ==
                                                false,
                                            child: RoundedLoadingButton(
                                              color: appColor,
                                              borderRadius: 0,
                                              elevation: 10,
                                              height: size.width * .03,
                                              width: size.width * .6,
                                              successIcon: Icons.check_rounded,
                                              failedIcon: Icons.close_rounded,
                                              successColor: Colors.green,
                                              errorColor: appColor,
                                              controller: validateController,
                                              onPressed: () async => validate(
                                                screen: EANForWebApp(
                                                  accType: widget.accType,
                                                  authorization:
                                                      widget.authorization,
                                                  refreshToken:
                                                      widget.refreshToken,
                                                  crossVisible: false,
                                                  screenType:
                                                      'picklist details',
                                                  profileId: widget.profileId,
                                                  distCenterName:
                                                      widget.distCenterName,
                                                  distCenterId:
                                                      widget.distCenterId,
                                                  barcodeToCheck: int.parse(
                                                      details[id - 1]
                                                              .ean
                                                              .isEmpty
                                                          ? '0'
                                                          : details[id - 1]
                                                              .ean),
                                                ),
                                              ),
                                              child: Text(
                                                "Validate Scan",
                                                style: TextStyle(
                                                  fontSize: size.width * .015,
                                                ),
                                              ),
                                            ),
                                          ),
                                        )
                                ],
                              ),
                            ),
                            SizedBox(
                              height: size.height * .02,
                              width: size.width,
                            ),
                            Visibility(
                              visible:
                                  widget.appBarName.substring(0, 4) != 'Shop',
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Visibility(
                                    visible: details[id - 1].ean == '' &&
                                        widget.showPickedOrders == false,
                                    child: RoundedLoadingButton(
                                      color: appColor,
                                      borderRadius: 0,
                                      elevation: 10,
                                      height: size.width * .03,
                                      width: size.width * .6,
                                      successIcon: Icons.check_rounded,
                                      failedIcon: Icons.close_rounded,
                                      successColor: Colors.green,
                                      errorColor: appColor,
                                      controller: validateController,
                                      onPressed: () async {
                                        await SharedPreferences.getInstance().then((prefs) async {
                                          if (widget.requestType == 'MSMQW') {
                                            await printLabel(
                                              siteOrderId:
                                              details[id - 1].siteOrderId,
                                              isAmazonPrime:
                                              details[id - 1].siteName ==
                                                  'Amazon UK-prime',
                                              isTest: (prefs.getString('EasyPostTestOrLive') ?? 'Test') == 'Test',
                                            ).whenComplete(() async {
                                              if (labelError.isNotEmpty) {
                                                await Future.delayed(
                                                    const Duration(
                                                        milliseconds: 100), () {
                                                  ToastUtils
                                                      .motionToastCentered1500MS(
                                                    message: labelError,
                                                    context: context,
                                                  );
                                                }).whenComplete(() {
                                                  validateController.reset();
                                                });
                                              } else {
                                                await print(labelUrl)
                                                    .whenComplete(() {
                                                  validateController.reset();
                                                });
                                              }
                                            });
                                          }
                                          else {
                                            if (details[id - 1]
                                                .orderQuantity
                                                .length ==
                                                1) {
                                              await printLabel(
                                                siteOrderId: details[id - 1]
                                                    .orderQuantity[0]
                                                    .siteOrderId,
                                                isAmazonPrime: details[id - 1]
                                                    .orderQuantity[0]
                                                    .siteName ==
                                                    'Amazon UK-prime',
                                                isTest: (prefs.getString('EasyPostTestOrLive') ?? 'Test') == 'Test',
                                              ).whenComplete(() async {
                                                if (labelError.isNotEmpty) {
                                                  await Future.delayed(
                                                      const Duration(
                                                          milliseconds: 100), () {
                                                    ToastUtils
                                                        .motionToastCentered1500MS(
                                                      message: labelError,
                                                      context: context,
                                                    );
                                                  }).whenComplete(() {
                                                    validateController.reset();
                                                  });
                                                } else {
                                                  await print(labelUrl)
                                                      .whenComplete(() {
                                                    validateController.reset();
                                                  });
                                                }
                                              });
                                            } else {
                                              String selectedOrder =
                                                  '${details[id - 1].orderQuantity[0].orderNumber}';
                                              await showDialog(
                                                context: context,
                                                barrierDismissible: false,
                                                builder: (context) {
                                                  return StatefulBuilder(
                                                    builder:
                                                        (context, setStateSB) {
                                                      return AlertDialog(
                                                        shape:
                                                        RoundedRectangleBorder(
                                                          borderRadius:
                                                          BorderRadius
                                                              .circular(25),
                                                        ),
                                                        elevation: 5,
                                                        titleTextStyle: TextStyle(
                                                          color: Colors.black,
                                                          fontSize:
                                                          size.width * .042,
                                                          fontWeight:
                                                          FontWeight.bold,
                                                        ),
                                                        title: Text(
                                                          'Select a Order for printing Label',
                                                          style: TextStyle(
                                                              fontSize:
                                                              size.width *
                                                                  .015),
                                                        ),
                                                        content: Container(
                                                          height:
                                                          size.height * .08,
                                                          width: size.width * .2,
                                                          decoration:
                                                          BoxDecoration(
                                                            color: const Color
                                                                .fromARGB(255,
                                                                255, 255, 255),
                                                            border: Border.all(
                                                              width: 1,
                                                              color: Colors.black,
                                                            ),
                                                            borderRadius:
                                                            BorderRadius
                                                                .circular(10),
                                                          ),
                                                          child: Padding(
                                                            padding:
                                                            const EdgeInsets
                                                                .all(8.0),
                                                            child:
                                                            DropdownButtonHideUnderline(
                                                              child:
                                                              DropdownButton(
                                                                elevation: 0,
                                                                value:
                                                                selectedOrder,
                                                                icon: SizedBox(
                                                                  height: 35,
                                                                  width: 35,
                                                                  child:
                                                                  FittedBox(
                                                                    child: Image
                                                                        .asset(
                                                                        'assets/add_new_rule_assets/dd_icon.png'),
                                                                  ),
                                                                ),
                                                                items: details[
                                                                id - 1]
                                                                    .orderQuantity
                                                                    .map((e) => e
                                                                    .orderNumber)
                                                                    .toList()
                                                                    .map(
                                                                      (value) =>
                                                                      DropdownMenuItem(
                                                                        value:
                                                                        '$value',
                                                                        child:
                                                                        Text(
                                                                          '$value',
                                                                          style: TextStyle(
                                                                              fontSize:
                                                                              size.width * .012),
                                                                        ),
                                                                      ),
                                                                )
                                                                    .toList(),
                                                                onChanged: (Object?
                                                                newValue) {
                                                                  selectedOrder =
                                                                  newValue
                                                                  as String;
                                                                  setStateSB(
                                                                          () {});
                                                                  log('selectedOrder >>>>> $selectedOrder');
                                                                },
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                        actions: <Widget>[
                                                          Row(
                                                            mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .start,
                                                            children: [
                                                              Padding(
                                                                padding:
                                                                const EdgeInsets
                                                                    .only(
                                                                    left: 13),
                                                                child:
                                                                RoundedLoadingButton(
                                                                  color:
                                                                  Colors.red,
                                                                  borderRadius:
                                                                  10,
                                                                  height:
                                                                  size.width *
                                                                      .03,
                                                                  width:
                                                                  size.width *
                                                                      .07,
                                                                  successIcon: Icons
                                                                      .check_rounded,
                                                                  failedIcon: Icons
                                                                      .close_rounded,
                                                                  successColor:
                                                                  Colors
                                                                      .green,
                                                                  controller:
                                                                  cancelController,
                                                                  onPressed:
                                                                      () async {
                                                                    await Future.delayed(
                                                                        const Duration(
                                                                            milliseconds:
                                                                            500),
                                                                            () {
                                                                          cancelController
                                                                              .reset();
                                                                          Navigator.pop(
                                                                              context);
                                                                        });
                                                                  },
                                                                  child: const Text(
                                                                      'Cancel'),
                                                                ),
                                                              ),
                                                              Expanded(
                                                                child: Row(
                                                                  mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .end,
                                                                  children: [
                                                                    Padding(
                                                                      padding: const EdgeInsets
                                                                          .only(
                                                                          right:
                                                                          13),
                                                                      child:
                                                                      RoundedLoadingButton(
                                                                        color: Colors
                                                                            .green,
                                                                        borderRadius:
                                                                        10,
                                                                        height:
                                                                        size.width *
                                                                            .03,
                                                                        width: size
                                                                            .width *
                                                                            .07,
                                                                        successIcon:
                                                                        Icons
                                                                            .check_rounded,
                                                                        failedIcon:
                                                                        Icons
                                                                            .close_rounded,
                                                                        successColor:
                                                                        Colors
                                                                            .green,
                                                                        controller:
                                                                        printController,
                                                                        onPressed:
                                                                            () async {
                                                                          await SharedPreferences.getInstance().then((prefs) async {
                                                                            await printLabel(
                                                                              siteOrderId: details[id - 1]
                                                                                  .orderQuantity[details[id - 1].orderQuantity.indexWhere((e) => e.orderNumber == parseToInt(selectedOrder))]
                                                                                  .siteOrderId,
                                                                              isAmazonPrime: details[id - 1].orderQuantity[details[id - 1].orderQuantity.indexWhere((e) => e.orderNumber == parseToInt(selectedOrder))].siteName == 'Amazon UK-prime',
                                                                              isTest: (prefs.getString('EasyPostTestOrLive') ?? 'Test') == 'Test',
                                                                            ).whenComplete(
                                                                                    () async {
                                                                                  if (labelError
                                                                                      .isNotEmpty) {
                                                                                    await Future.delayed(const Duration(milliseconds: 100),
                                                                                            () {
                                                                                          ToastUtils.motionToastCentered1500MS(
                                                                                            message: labelError,
                                                                                            context: context,
                                                                                          );
                                                                                        }).whenComplete(() {
                                                                                      validateController.reset();
                                                                                    });
                                                                                  } else {
                                                                                    await print(labelUrl).whenComplete(() {
                                                                                      validateController.reset();
                                                                                    });
                                                                                  }
                                                                                }).whenComplete(() =>
                                                                                Navigator.pop(context));
                                                                          });
                                                                        },
                                                                        child:
                                                                        const Text(
                                                                          'Create',
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ],
                                                      );
                                                    },
                                                  );
                                                },
                                              );
                                            }
                                          }
                                        });
                                      },
                                      child: Text(
                                        "Print Shipping Label",
                                        style: TextStyle(
                                          fontSize: size.width * .015,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              TextButton(
                onPressed: () async {
                  if (id > 1) {
                    if (skuStart > 1) {
                      skuStart = skuStart - 1;
                    } else if (skuStart == 1) {
                      skuStart = skuInOrder[details[id - 2].siteOrderId];
                    }
                    if (details[id - 1].siteOrderId !=
                        details[id - 2].siteOrderId) {
                      setState(() {
                        orderStart = orderStart - 1;
                      });
                    }

                    setState(() {
                      isPrevButton = true;
                      id = id - 1;
                    });
                    log("V id >>---> $id");
                    await Future.delayed(const Duration(milliseconds: 300), () {
                      setState(() {
                        isPrevButton = false;
                      });
                    });
                  }
                },
                child: Text(
                  'Previous',
                  style: TextStyle(
                    fontSize: size.width * .01,
                    fontWeight: FontWeight.bold,
                    color: id == 1 ? Colors.grey : Colors.lightBlue,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () async {
                        if (id < details.length) {
                          if (skuStart <
                              skuInOrder[details[id - 1].siteOrderId]) {
                            skuStart = skuStart + 1;
                          }
                          if (details[id - 1].siteOrderId !=
                              details[id].siteOrderId) {
                            setState(() {
                              orderStart = orderStart + 1;
                              skuStart = 1;
                            });
                          }
                          setState(() {
                            isNextButton = true;
                            id = id + 1;
                          });
                          log("V id >>---> $id");
                          await Future.delayed(
                              const Duration(milliseconds: 300), () {
                            setState(() {
                              isNextButton = false;
                            });
                          });
                        }
                      },
                      child: Text(
                        'Next',
                        style: TextStyle(
                          fontSize: size.width * .01,
                          fontWeight: FontWeight.bold,
                          color: id == details.length
                              ? Colors.grey
                              : Colors.lightBlue,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _mobileScreenBuilder(BuildContext context, Size size) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: size.height * .01,
        horizontal: size.width * .025,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: size.height * .005),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Go Back To Picklists',
                    style: TextStyle(
                      fontSize: size.width * .038,
                      fontWeight: FontWeight.bold,
                      color: Colors.lightBlue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        widget.requestType == 'MSMQW'
                            ? 'Order $orderStart/${widget.showPickedOrders == true ? widget.orderPicked : totalOrder} Pick $skuStart/${skuInOrder[details[id - 1].siteOrderId]}'
                            : 'Pick $id/${details.length}',
                        style: TextStyle(
                          fontSize: size.width * .038,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top: size.height * .015),
            child: SizedBox(
              height: size.height * .77,
              width: size.width,
              child: isNextButton == true || isPrevButton == true
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: appColor,
                      ),
                    )
                  : Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Flexible(
                              child: Text(
                                details[id - 1].title == ''
                                    ? 'Product title Not Available'
                                    : details[id - 1].title,
                                overflow: TextOverflow.visible,
                                style: TextStyle(
                                  fontSize: size.width * .042,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: size.height * .01,
                          width: size.width,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            SelectableText(
                              "Location : ",
                              style: TextStyle(fontSize: size.width * .04),
                            ),
                            SelectableText(
                              details[id - 1].warehouseLocation == ''
                                  ? 'Not Available'
                                  : details[id - 1].warehouseLocation,
                              style: TextStyle(
                                fontSize: size.width * .04,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: size.height * .01,
                          width: size.width,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            SelectableText(
                              "Barcode : ",
                              style: TextStyle(fontSize: size.width * .04),
                            ),
                            SelectableText(
                              details[id - 1].ean == ''
                                  ? 'Not Available'
                                  : details[id - 1].ean,
                              style: TextStyle(
                                  fontSize: size.width * .04,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        Visibility(
                          visible: widget.appBarName.substring(0, 4) != 'Shop',
                          child: SizedBox(
                            height: size.height * .01,
                            width: size.width,
                          ),
                        ),
                        Visibility(
                          visible: widget.appBarName.substring(0, 4) != 'Shop',
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              SelectableText(
                                "SKU : ",
                                style: TextStyle(fontSize: size.width * .04),
                              ),
                              SelectableText(
                                details[id - 1].sku == ''
                                    ? 'Not Available'
                                    : details[id - 1].sku,
                                style: TextStyle(
                                    fontSize: size.width * .04,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: size.height * .01,
                          width: size.width,
                        ),
                        Visibility(
                          visible: widget.appBarName.substring(0, 4) != 'Shop',
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              SelectableText(
                                "Order Id : ",
                                style: TextStyle(
                                  fontSize: size.width * .04,
                                ),
                              ),
                              Flexible(
                                child: SelectableText(
                                  details[id - 1].orderNumber == ''
                                      ? 'Not Available'
                                      : details[id - 1].orderNumber.trim(),
                                  style: TextStyle(
                                    overflow: TextOverflow.visible,
                                    fontSize: size.width * .04,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Visibility(
                          visible: widget.appBarName.substring(0, 4) != 'Shop',
                          child: SizedBox(
                            height: size.height * .01,
                            width: size.width,
                          ),
                        ),
                        Visibility(
                          visible: widget.appBarName.substring(0, 4) != 'Shop',
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              SelectableText(
                                "Shipping Carrier : ",
                                style: TextStyle(
                                  fontSize: size.width * .04,
                                ),
                              ),
                              Flexible(
                                child: SelectableText(
                                  details[id - 1].shippingCarrierForMsmqw == ''
                                      ? 'Not Available'
                                      : details[id - 1]
                                          .shippingCarrierForMsmqw
                                          .trim(),
                                  style: TextStyle(
                                    overflow: TextOverflow.visible,
                                    fontSize: size.width * .04,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Visibility(
                          visible: widget.appBarName.substring(0, 4) != 'Shop',
                          child: SizedBox(
                            height: size.height * .01,
                            width: size.width,
                          ),
                        ),
                        Visibility(
                          visible: widget.appBarName.substring(0, 4) != 'Shop',
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              SelectableText(
                                "Shipping Class : ",
                                style: TextStyle(fontSize: size.width * .04),
                              ),
                              Flexible(
                                child: SelectableText(
                                  details[id - 1].shippingClassForMsmqw == ''
                                      ? 'Not Available'
                                      : details[id - 1]
                                          .shippingClassForMsmqw
                                          .trim(),
                                  style: TextStyle(
                                    overflow: TextOverflow.visible,
                                    fontSize: size.width * .04,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: size.height * .02,
                          width: size.width,
                        ),
                        SizedBox(
                          height: mobileImageSize(size),
                          width: mobileImageSize(size),
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            elevation: 10,
                            child: Center(
                              child: details[id - 1].url.toString().isEmpty
                                  ? Image.asset(
                                      'assets/no_image/no_image.png',
                                      height: mobileImageSize(size),
                                      width: mobileImageSize(size),
                                      fit: BoxFit.contain,
                                    )
                                  : ImageNetwork(
                                      image: details[id - 1].url,
                                      imageCache: CachedNetworkImageProvider(
                                        details[id - 1].url,
                                      ),
                                      height: mobileImageSize(size),
                                      width: mobileImageSize(size),
                                      duration: 100,
                                      fitAndroidIos: BoxFit.contain,
                                      fitWeb: BoxFitWeb.contain,
                                      onLoading: Shimmer(
                                        duration: const Duration(seconds: 3),
                                        interval: const Duration(seconds: 5),
                                        color: const Color.fromARGB(
                                            160, 192, 192, 192),
                                        colorOpacity: 1,
                                        enabled: true,
                                        direction:
                                            const ShimmerDirection.fromLTRB(),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            color: const Color.fromARGB(
                                                160, 192, 192, 192),
                                          ),
                                        ),
                                      ),
                                      onError: Image.asset(
                                        'assets/no_image/no_image.png',
                                        height: mobileImageSize(size),
                                        width: mobileImageSize(size),
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: size.height * .02,
                          width: size.width,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              widget.showPickedOrders == true
                                  ? "Picked Quantity : "
                                  : "Qty to Pick : ",
                              style: TextStyle(
                                fontSize: size.width * .045,
                              ),
                            ),
                            qtyToPickVisible == false
                                ? const Center(
                                    child: SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: FittedBox(
                                        child: CircularProgressIndicator(
                                          color: appColor,
                                        ),
                                      ),
                                    ),
                                  )
                                : Text(
                                    qtyToPick[id - 1] == ''
                                        ? 'Not Available'
                                        : qtyToPick[id - 1],
                                    style: TextStyle(
                                      fontSize: size.width * .045,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red,
                                    ),
                                  ),
                          ],
                        ),
                        SizedBox(
                          height: size.height * .02,
                          width: size.width,
                        ),
                        Visibility(
                          visible: widget.appBarName.substring(0, 4) != 'Shop',
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              details[id - 1].ean == ''
                                  ? Column(children: [
                                      const SelectableText(
                                        "Barcode missing for this SKU : ",
                                        style: TextStyle(
                                            color: Colors.red, fontSize: 15),
                                      ),
                                      SelectableText(
                                        details[id - 1].sku,
                                        style: const TextStyle(
                                          color: Colors.red,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      )
                                    ])
                                  : Visibility(
                                      visible: widget.showPickedOrders == false,
                                      child: RoundedLoadingButton(
                                        color: appColor,
                                        borderRadius: 10,
                                        elevation: 10,
                                        height: size.width * .12,
                                        width: size.width * .8,
                                        successIcon: Icons.check_rounded,
                                        failedIcon: Icons.close_rounded,
                                        successColor: Colors.green,
                                        errorColor: appColor,
                                        controller: validateController,
                                        onPressed: () async => validate(
                                          screen: BarcodeCameraScreen(
                                            accType: widget.accType,
                                            authorization: widget.authorization,
                                            refreshToken: widget.refreshToken,
                                            crossVisible: false,
                                            screenType: 'picklist details',
                                            profileId: widget.profileId,
                                            distCenterName: widget.distCenterName,
                                            distCenterId: widget.distCenterId,
                                            barcodeToCheck: int.parse(
                                                details[id - 1].ean.isEmpty
                                                    ? '0'
                                                    : details[id - 1].ean),
                                          ),
                                        ),
                                        child: Text(
                                          "Validate Scan",
                                          style: TextStyle(
                                            fontSize: size.width * .05,
                                          ),
                                        ),
                                      ),
                                    )
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(bottom: size.height * .01),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () async {
                    if (id > 1) {
                      if (skuStart > 1) {
                        skuStart = skuStart - 1;
                      } else if (skuStart == 1) {
                        skuStart = skuInOrder[details[id - 2].siteOrderId];
                      }
                      if (details[id - 1].siteOrderId !=
                          details[id - 2].siteOrderId) {
                        setState(() {
                          orderStart = orderStart - 1;
                        });
                      }

                      setState(() {
                        isPrevButton = true;
                        id = id - 1;
                      });
                      log("V id >>---> $id");
                      await Future.delayed(const Duration(milliseconds: 300),
                          () {
                        setState(() {
                          isPrevButton = false;
                        });
                      });
                    }
                  },
                  child: Text(
                    'Previous',
                    style: TextStyle(
                      fontSize: size.width * .045,
                      fontWeight: FontWeight.bold,
                      color: id == 1 ? Colors.grey : Colors.lightBlue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: () async {
                          if (id < details.length) {
                            if (skuStart <
                                skuInOrder[details[id - 1].siteOrderId]) {
                              skuStart = skuStart + 1;
                            }
                            if (details[id - 1].siteOrderId !=
                                details[id].siteOrderId) {
                              setState(() {
                                orderStart = orderStart + 1;
                                skuStart = 1;
                              });
                            }

                            setState(() {
                              isNextButton = true;
                              id = id + 1;
                            });
                            log("V id >>---> $id");
                            await Future.delayed(
                                const Duration(milliseconds: 300), () {
                              setState(() {
                                isNextButton = false;
                              });
                            });
                          }
                        },
                        child: Text(
                          'Next',
                          style: TextStyle(
                            fontSize: size.width * .045,
                            fontWeight: FontWeight.bold,
                            color: id == details.length
                                ? Colors.grey
                                : Colors.lightBlue,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  double mobileImageSize(Size size) {
    return (widget.requestType == 'SIW' &&
            details[id - 1].orderNumber.length > 45)

        /// more than 4 orders
        ? size.height * .15
        : (widget.requestType == 'SIW' &&
                details[id - 1].orderNumber.length > 23)

            /// more than 2 orders
            ? size.height * .22
            : size.height * .3;
  }

  double webImageSizeIfOrdersMoreThan3(Size size) {
    return details[id - 1].orderQuantity.length > 3
        ? (size.height * .35) -
            (30 * (details[id - 1].orderQuantity.length - 3))
        : size.height * .35;
  }

  void detailsApis() async {
    if (widget.status != 'Processing.......') {
      await getSavedLockedPicklistData().whenComplete(
        () async => await getPickListDetails(
          batchId: widget.batchId,
          showPickedOrders: widget.showPickedOrders,
        ),
      );
    } else {
      setState(() {
        isDetailsVisible = true;
      });
    }
  }

  Future<void> print(String url) async {
    final pdf = pw.Document();
    try {
      pdf.addPage(pw.Page(
          pageFormat: const PdfPageFormat(
            4 * PdfPageFormat.inch,
            6 * PdfPageFormat.inch,
          ),
          build: (pw.Context context) {
            return pw.Image(pw.MemoryImage(base64Decode(url)));
          }));
      await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => pdf.save());
    } catch (e) {
      log("EXCEPTION IN PRINTING IN PICKLIST DETAILS SCREEN >>---> ${e.toString()}");
    }
  }

  Future<void> printLabel({
    required String siteOrderId,
    required bool isAmazonPrime,
    required bool isTest,
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
        : 'https://weblegs.info/EasyPostv2/api/EasyPostVersion2?OrderNumber=$siteOrderIdToSent&IsTest=$isTest';
    log('PRINT LABEL FOR PICKLIST DETAILS SCREEN PROCESS');
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
          labelUrl = jsonDecode(response.body)['Base64'].toString();
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

  Future<void> getSavedLockedPicklistData() async {
    setState(() {
      isDetailsVisible = false;
    });
    String uri = 'https://weblegs.info/JadlamApp/api/GetLoackingEntries';
    log('GET SAVED LOCKED PICKLIST DATA URI >>---> $uri');

    try {
      var response = await http.get(Uri.parse(uri)).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          ToastUtils.motionToastCentered1500MS(
            message: kTimeOut,
            context: context,
          );
          return http.Response('Error', 408);
        },
      );

      if (response.statusCode == 200) {
        log('GET SAVED LOCKED PICKLIST DATA RESPONSE >>---> ${jsonDecode(response.body)}');

        GetLockedPicklistResponse getLockedPicklistResponse =
            GetLockedPicklistResponse.fromJson(jsonDecode(response.body));
        log('V getLockedPicklistResponse >>---> ${jsonEncode(getLockedPicklistResponse)}');

        lockedPicklistList = [];
        if (getLockedPicklistResponse.message.isNotEmpty) {
          lockedPicklistList
              .addAll(getLockedPicklistResponse.message.map((e) => e));
        }
        log('V lockedPicklistList >>---> ${jsonEncode(lockedPicklistList)}');

        setState(() {
          isDetailsVisible = true;
        });
      } else {
        if (!mounted) return;
        ToastUtils.motionToastCentered1500MS(
          message: kerrorString,
          context: context,
        );
        setState(() {
          isDetailsVisible = false;
        });
      }
    } on Exception catch (e) {
      log('EXCEPTION IN GET SAVED LOCKED PICKLIST DATA API >>---> ${e.toString()}');
      ToastUtils.motionToastCentered1500MS(
        message: e.toString(),
        context: context,
      );
      setState(() {
        isDetailsVisible = false;
      });
    }
  }

  ///THIS API IS USED FOR DELETE THE LOCKED PICKLIST OLDER THAN 30 MINUTES IN
  ///THE LIST OF LOCKED PICKLISTS.
  void deleteOlderLockedPicklists() async {
    DateTime britishTimeNow =
        DateTime.now().toUtc().add(const Duration(hours: 1));
    log('V britishTimeNow >>---> $britishTimeNow');

    List<MsgX> picklistsToDelete = [];
    if (lockedPicklistList
        .where((e) =>
            (britishTimeNow
                .difference(dateFormat.parse(e.createdDate))
                .compareTo(const Duration(minutes: 30))) ==
            1)
        .toList()
        .isNotEmpty) {
      picklistsToDelete.addAll(lockedPicklistList
          .where((e) =>
              (britishTimeNow
                  .difference(dateFormat.parse(e.createdDate))
                  .compareTo(const Duration(minutes: 30))) ==
              1)
          .map((e) => e));
      for (int i = 0; i < picklistsToDelete.length; i++) {
        deleteLockedPicklistData(id: picklistsToDelete[i].id);
        log('DELETED OLDER LOCKED PICKLIST >>---> $i');
      }
    }
  }

  Future<void> deleteLockedPicklistData({required String id}) async {
    String uri = 'https://weblegs.info/JadlamApp/api/DeleteLock?id=$id';
    log('ID TO DELETE >>---> $id');
    log('DELETE LOCKED PICKLIST DATA URI >>---> $uri');

    try {
      var response = await http.get(Uri.parse(uri)).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          ToastUtils.motionToastCentered1500MS(
            message: kTimeOut,
            context: context,
          );
          return http.Response('Error', 408);
        },
      );

      if (response.statusCode == 200) {
        log('DELETE LOCKED PICKLIST DATA RESPONSE >>---> ${jsonDecode(response.body)}');
      } else {
        if (!mounted) return;
        ToastUtils.motionToastCentered1500MS(
          message: kerrorString,
          context: context,
        );
      }
    } on Exception catch (e) {
      log('EXCEPTION IN DELETE LOCKED PICKLIST DATA API >>---> ${e.toString()}');
      ToastUtils.motionToastCentered1500MS(
        message: e.toString(),
        context: context,
      );
    }
  }

  Future<void> validate({
    required Widget screen,
  }) async {
    if (int.parse(qtyToPick[id - 1].isEmpty ? '0' : qtyToPick[id - 1]) > 0) {
      bool isBarcodesMatched = await NavigationMethods.pushWithResult(
        context,
        screen,
      );

      if (isBarcodesMatched == true) {
        setState(() {
          qtyToPickVisible = false;
        });

        /// MSMQW PICKLIST CASE (FULL QUANTITY OF ONE SKU FROM MULTIPLE SKUs PRESENT IN THAT ORDER) -- ONLY ONE CASE>>>>>>>>>>

        if (widget.requestType == 'MSMQW') {
          if (!mounted) return;
          await updateQtyToPick(
                  batchId: widget.batchId,
                  sku: details[id - 1].sku,
                  ean: details[id - 1].ean,
                  orderNumber: details[id - 1].orderNumber,
                  type: 'MSMQW',
                  isWeb: true,
                  context: context,
                  quantity: qtyToPick[id - 1])
              .whenComplete(() async {
            if (isUpdatedSuccessfully == true) {
              setState(() {
                qtyToPick[id - 1] = '0';
              });

              await Future.delayed(const Duration(milliseconds: 300), () async {
                setState(() {
                  qtyToPickVisible = true;
                });
                validateController.reset();
                await Future.delayed(const Duration(milliseconds: 300),
                    () async {
                  if (id < details.length) {
                    if (skuStart < skuInOrder[details[id - 1].siteOrderId]) {
                      skuStart = skuStart + 1;
                    }

                    if (details[id - 1].siteOrderId !=
                        details[id].siteOrderId) {
                      setState(() {
                        orderStart = orderStart + 1;
                        skuStart = 1;
                      });
                    }

                    setState(() {
                      isNextButton = true;
                      id = id + 1;
                    });
                    log("V id (MSMQW) >>---> $id");

                    await Future.delayed(const Duration(milliseconds: 300), () {
                      setState(() {
                        isNextButton = false;
                      });
                    });
                  } else if (id == details.length) {
                    await Future.delayed(const Duration(milliseconds: 300), () {
                      Navigator.pop(context);
                    }).whenComplete(() => Navigator.pop(context));
                  }
                });
              });
            } else {
              /// TOAST FROM THE API WILL BE SHOWN AND NOTHING WILL HAPPEN ELSE, JUST RESETTING THE BUTTON CONTROLLER AND SCREEN WILL BE STILL
              await Future.delayed(const Duration(seconds: 1), () {
                validateController.reset();
              });
            }
          });
        }

        /// SSMQW PICKLIST CASE (TWO CASES HANDLING) >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

        if (widget.requestType == 'SSMQW') {
          await SharedPreferences.getInstance().then((prefs) async {
            if ((prefs.getBool('SingleSkuAtOnce') ?? false) == true) {
              /// SCAN ONE ORDER OF BUNDLED SKU AT ONCE
              if (!mounted) return;
              log('UPDATING FOR ORDER NUMBER >>---> ${listOfOrderNumberList[id - 1][0]}');
              String updatingQuantity =
                  '${details[id - 1].orderQuantity[details[id - 1].orderQuantity.indexWhere((e) => e.orderNumber == int.parse(listOfOrderNumberList[id - 1][0]))].quantity}';
              log('UPDATING QUANTITY >>---> $updatingQuantity');
              await updateQtyToPick(
                batchId: widget.batchId,
                sku: details[id - 1].sku,
                ean: details[id - 1].ean,
                orderNumber: listOfOrderNumberList[id - 1][0],
                type: 'SSMQW',
                isWeb: true,
                context: context,
                quantity: updatingQuantity,
              ).whenComplete(() async {
                if (isUpdatedSuccessfully == true) {
                  setState(() {
                    qtyToPick[id - 1] =
                        '${int.parse(qtyToPick[id - 1]) - int.parse(updatingQuantity)}';
                    listOfOrderNumberList[id - 1].removeAt(0);
                  });
                  log('V listOfOrderNumberList (After Update) >>---> ${listOfOrderNumberList[id - 1].isEmpty ? 'Empty' : listOfOrderNumberList[id - 1]}');

                  await Future.delayed(const Duration(milliseconds: 300),
                      () async {
                    setState(() {
                      qtyToPickVisible = true;
                    });
                    validateController.reset();
                    if (listOfOrderNumberList[id - 1].isEmpty) {
                      await Future.delayed(const Duration(milliseconds: 300),
                          () async {
                        if (id < details.length) {
                          setState(() {
                            isNextButton = true;
                            id = id + 1;
                          });
                          log("V id (SSMQW) >>---> $id");

                          await Future.delayed(
                              const Duration(milliseconds: 300), () {
                            setState(() {
                              isNextButton = false;
                            });
                          });
                        } else if (id == details.length) {
                          await Future.delayed(
                              const Duration(milliseconds: 300), () {
                            Navigator.pop(context);
                          }).whenComplete(() => Navigator.pop(context));
                        }
                      });
                    }
                  });
                } else {
                  /// TOAST FROM THE API WILL BE SHOWN AND NOTHING WILL HAPPEN ELSE, JUST RESETTING THE BUTTON CONTROLLER AND SCREEN WILL BE STILL
                  await Future.delayed(const Duration(seconds: 1), () {
                    validateController.reset();
                  });
                }
              });
            } else {
              /// SCAN ALL ORDER PRESENT IN BUNDLED SKU AT ONCE
              if (!mounted) return;
              await updateQtyToPick(
                      batchId: widget.batchId,
                      sku: details[id - 1].sku,
                      ean: details[id - 1].ean,
                      orderNumber: details[id - 1].orderNumber,
                      type: 'SSMQW',
                      isWeb: true,
                      context: context,
                      quantity: qtyToPick[id - 1])
                  .whenComplete(() async {
                if (isUpdatedSuccessfully == true) {
                  setState(() {
                    qtyToPick[id - 1] = '0';
                  });

                  await Future.delayed(const Duration(milliseconds: 300),
                      () async {
                    setState(() {
                      qtyToPickVisible = true;
                    });
                    validateController.reset();
                    await Future.delayed(const Duration(milliseconds: 300),
                        () async {
                      if (id < details.length) {
                        setState(() {
                          isNextButton = true;
                          id = id + 1;
                        });
                        log("id SSMQW >>>> $id");

                        await Future.delayed(const Duration(milliseconds: 300),
                            () {
                          setState(() {
                            isNextButton = false;
                          });
                        });
                      } else if (id == details.length) {
                        await Future.delayed(const Duration(milliseconds: 300),
                            () {
                          Navigator.pop(context);
                        }).whenComplete(() => Navigator.pop(context));
                      }
                    });
                  });
                } else {
                  /// TOAST FROM THE API WILL BE SHOWN AND NOTHING WILL HAPPEN ELSE, JUST RESETTING THE BUTTON CONTROLLER AND SCREEN WILL BE STILL
                  await Future.delayed(const Duration(seconds: 1), () {
                    validateController.reset();
                  });
                }
              });
            }
          });
        }

        /// SIW PICKLIST CASE (TWO CASES HANDLING) >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

        if (widget.requestType == 'SIW') {
          await SharedPreferences.getInstance().then((prefs) async {
            if ((prefs.getBool('SingleSkuAtOnce') ?? false) == true) {
              /// SCAN ONE ORDER OF BUNDLED SKU AT ONCE
              if (!mounted) return;
              log('Updating For Order Number ${listOfOrderNumberList[id - 1][0]}');
              await updateQtyToPick(
                batchId: widget.batchId,
                sku: details[id - 1].sku,
                ean: details[id - 1].ean,
                orderNumber: listOfOrderNumberList[id - 1][0],
                type: 'SIW',
                isWeb: true,
                context: context,
                quantity: '1',
              ).whenComplete(() async {
                if (isUpdatedSuccessfully == true) {
                  setState(() {
                    qtyToPick[id - 1] = '${int.parse(qtyToPick[id - 1]) - 1}';
                    listOfOrderNumberList[id - 1].removeAt(0);
                  });
                  log('listOfOrderNumberList after update >> ${listOfOrderNumberList[id - 1].isEmpty ? 'Empty' : listOfOrderNumberList[id - 1]}');

                  await Future.delayed(const Duration(milliseconds: 300),
                      () async {
                    setState(() {
                      qtyToPickVisible = true;
                    });
                    validateController.reset();
                    if (listOfOrderNumberList[id - 1].isEmpty) {
                      await Future.delayed(const Duration(milliseconds: 300),
                          () async {
                        if (id < details.length) {
                          setState(() {
                            isNextButton = true;
                            id = id + 1;
                          });
                          log("id SIW >>>> $id");

                          await Future.delayed(
                              const Duration(milliseconds: 300), () {
                            setState(() {
                              isNextButton = false;
                            });
                          });
                        } else if (id == details.length) {
                          await Future.delayed(
                              const Duration(milliseconds: 300), () {
                            Navigator.pop(context);
                          }).whenComplete(() => Navigator.pop(context));
                        }
                      });
                    }
                  });
                } else {
                  /// TOAST FROM THE API WILL BE SHOWN AND NOTHING WILL HAPPEN ELSE, JUST RESETTING THE BUTTON CONTROLLER AND SCREEN WILL BE STILL
                  await Future.delayed(const Duration(seconds: 1), () {
                    validateController.reset();
                  });
                }
              });
            } else {
              /// SCAN ALL ORDER PRESENT IN BUNDLED SKU AT ONCE
              if (!mounted) return;
              await updateQtyToPick(
                      batchId: widget.batchId,
                      sku: details[id - 1].sku,
                      ean: details[id - 1].ean,
                      orderNumber: details[id - 1].orderNumber,
                      type: 'SIW',
                      isWeb: true,
                      context: context,
                      quantity: qtyToPick[id - 1])
                  .whenComplete(() async {
                if (isUpdatedSuccessfully == true) {
                  setState(() {
                    qtyToPick[id - 1] = '0';
                  });

                  await Future.delayed(const Duration(milliseconds: 300),
                      () async {
                    setState(() {
                      qtyToPickVisible = true;
                    });
                    validateController.reset();
                    await Future.delayed(const Duration(milliseconds: 300),
                        () async {
                      if (id < details.length) {
                        setState(() {
                          isNextButton = true;
                          id = id + 1;
                        });
                        log("id SIW >>>> $id");

                        await Future.delayed(const Duration(milliseconds: 300),
                            () {
                          setState(() {
                            isNextButton = false;
                          });
                        });
                      } else if (id == details.length) {
                        await Future.delayed(const Duration(milliseconds: 300),
                            () {
                          Navigator.pop(context);
                        }).whenComplete(() => Navigator.pop(context));
                      }
                    });
                  });
                } else {
                  /// TOAST FROM THE API WILL BE SHOWN AND NOTHING WILL HAPPEN ELSE, JUST RESETTING THE BUTTON CONTROLLER AND SCREEN WILL BE STILL
                  await Future.delayed(const Duration(seconds: 1), () {
                    validateController.reset();
                  });
                }
              });
            }
          });
        }
      } else {
        Future.delayed(const Duration(seconds: 1), () {
          validateController.reset();
        });
      }
    } else {
      ToastUtils.motionToastCentered(
          message: 'No More Quantity to Pick!', context: context);
      Future.delayed(const Duration(seconds: 1), () {
        validateController.reset();
      });
    }
  }

  Future<void> updateQtyToPick({
    required String batchId,
    required String sku,
    required String ean,
    required String orderNumber,
    required String type,
    required bool isWeb,
    required BuildContext context,
    required String quantity,
  }) async {
    setState(() {
      isUpdatedSuccessfully = false;
    });
    String uri =
        'https://weblegs.info/JadlamApp/api/UpdatePicksVersion2?BatchId=$batchId&SKU=$sku&OrderNumber=$orderNumber&type=$type&updateall=false';
    log('updateQtyToPick uri - $uri');

    try {
      var response = await http.get(Uri.parse(uri)).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          if (isWeb == true) {
            ToastUtils.motionToastCentered(
                message: 'Connection Timeout! Please try again',
                context: context);
          } else {
            ToastUtils.showCenteredShortToast(
                message: 'Connection Timeout! Please try again');
          }
          setState(() {
            isUpdatedSuccessfully = false;
          });
          return http.Response('Error', 408);
        },
      );

      if (response.statusCode == 200) {
        log('updateQtyToPick response >>>>> ${jsonDecode(response.body)}');

        setState(() {
          isUpdatedSuccessfully = true;
        });
        if (isWeb == true) {
          if (!mounted) return;
          ToastUtils.motionToastCentered1500MS(
              message: '$quantity Quantity of $ean is picked for $orderNumber',
              context: context);
        } else {
          ToastUtils.showCenteredShortToast(
            message: '$quantity Quantity of $ean is picked for $orderNumber',
          );
        }
      } else {
        setState(() {
          isUpdatedSuccessfully = false;
        });
        if (isWeb == true) {
          if (!mounted) return;
          ToastUtils.motionToastCentered(
              message: jsonDecode(response.body)['message'].toString(),
              context: context);
        } else {
          ToastUtils.showCenteredShortToast(
              message: jsonDecode(response.body)['message'].toString());
        }
      }
    } on Exception catch (e) {
      log('Exception in updateQtyToPick api >>> ${e.toString()}');
      setState(() {
        isUpdatedSuccessfully = false;
      });
      if (isWeb == true) {
        if (!mounted) return;
        ToastUtils.motionToastCentered(message: e.toString(), context: context);
      } else {
        ToastUtils.showCenteredShortToast(message: e.toString());
      }
    }
  }

  Future<void> getPickListDetails({
    required String batchId,
    required bool showPickedOrders,
  }) async {
    String uri =
        'https://weblegs.info/JadlamApp/api/GetPicklistByBatchId?BatchId=$batchId&ShowPickedOrders=$showPickedOrders';
    log('getPickListDetails uri - $uri');
    setState(() {
      isDetailsVisible = false;
    });
    try {
      var response = await http.get(Uri.parse(uri)).timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          Fluttertoast.showToast(msg: "Connection Timeout.\nPlease try again.");
          setState(() {
            isDetailsVisible = true;
          });
          return http.Response('Error', 408);
        },
      );

      if (response.statusCode == 200) {
        GetPicklistDetailsResponse getPicklistDetailsResponse =
            GetPicklistDetailsResponse.fromJson(jsonDecode(response.body));

        details = [];
        details.addAll(getPicklistDetailsResponse.sku.map((e) => e));

        List<String> siteOrderIDs = [];
        siteOrderIDs.addAll(details.map((e) => e.siteOrderId));

        for (var e in siteOrderIDs) {
          skuInOrder[e] =
              !skuInOrder.containsKey(e) ? (1) : (skuInOrder[e] + 1);
        }
        log('skuInOrder > $skuInOrder');

        qtyToPick.addAll(details.map((e) => e.qtyToPick));
        log('qtyToPick - ${jsonEncode(qtyToPick)}');

        setState(() {
          totalOrder = parseToInt(widget.totalOrders) -
              parseToInt(widget.orderPicked) +
              parseToInt(widget.partialOrders);
        });

        listOfOrderNumberList = [];
        listOfOrderNumberList
            .addAll(details.map((e) => (e.orderNumber).split(',')));
        for (int i = 0; i < listOfOrderNumberList.length; i++) {
          for (int j = 0; j < listOfOrderNumberList[i].length; j++) {
            listOfOrderNumberList[i][j] = listOfOrderNumberList[i][j].trim();
          }
        }
        log('listOfOrderNumberList >> ${jsonEncode(listOfOrderNumberList)}');

        isLabelPrintedForNonMSMQW = [];
        isLabelPrintedForNonMSMQW =
            List.generate(details.length, (index) => 'No');
        for (int i = 0; i < details.length; i++) {
          for (int j = 0; j < details[i].orderQuantity.length; j++) {
            if (details[i].orderQuantity[j].amazonLabel == true ||
                details[i].orderQuantity[j].easyPostLabel == true) {
              isLabelPrintedForNonMSMQW.removeAt(i);
              isLabelPrintedForNonMSMQW.insert(i, 'Yes');
            } else {
              isLabelPrintedForNonMSMQW.removeAt(i);
              isLabelPrintedForNonMSMQW.insert(i, 'No');
            }
          }
        }

        log('isLabelPrintedForNonMSMQW >> $isLabelPrintedForNonMSMQW');

        tableForPicklistDetails = [];
        tableForPicklistDetails.addAll(List.generate(
            details.length,
            (index) => List.generate(
                details[index].orderQuantity.length,
                (index2) => TableRow(
                      children: <TableCell>[
                        TableCell(
                          child: SizedBox(
                            height: 30,
                            child: Center(
                              child: Text(
                                '${details[index].orderQuantity[index2].orderNumber}',
                                style: const TextStyle(
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                        TableCell(
                          child: SizedBox(
                            height: 30,
                            child: Center(
                              child: Text(
                                details[index]
                                    .orderQuantity[index2]
                                    .shippingCarrier,
                                style: const TextStyle(
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                        TableCell(
                          child: SizedBox(
                            height: 30,
                            child: Center(
                              child: Text(
                                details[index]
                                    .orderQuantity[index2]
                                    .shippingClass,
                                style: const TextStyle(
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (widget.showPickedOrders == true)
                          TableCell(
                            child: SizedBox(
                              height: 30,
                              child: Center(
                                child: Text(
                                  (details[index]
                                              .orderQuantity[index2]
                                              .shippingClass
                                              .toLowerCase()
                                              .contains('prime') ||
                                          details[index]
                                              .orderQuantity[index2]
                                              .shippingCarrier
                                              .toLowerCase()
                                              .contains('prime'))
                                      ? details[index]
                                                  .orderQuantity[index2]
                                                  .amazonLabel ==
                                              true
                                          ? 'Yes'
                                          : 'No'
                                      : details[index]
                                                  .orderQuantity[index2]
                                                  .easyPostLabel ==
                                              true
                                          ? 'Yes'
                                          : 'No',
                                  style: const TextStyle(
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ))).map((e) => e));

        setState(() {
          isDetailsVisible = true;
        });
      } else {
        ToastUtils.showCenteredShortToast(
            message: jsonDecode(response.body)['message'].toString());
        setState(() {
          isDetailsVisible = true;
        });
      }
    } on Exception catch (e) {
      log(e.toString());
      ToastUtils.showCenteredLongToast(message: e.toString());
      setState(() {
        isDetailsVisible = true;
      });
    }
  }
}
