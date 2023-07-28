import 'dart:convert';
import 'dart:developer';

import 'package:absolute_app/core/apis/api_calls.dart';
import 'package:absolute_app/core/utils/constants.dart';
import 'package:absolute_app/core/utils/responsive_check.dart';
import 'package:absolute_app/core/utils/toast_utils.dart';
import 'package:absolute_app/models/get_product_quantity_response.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;

class StockTransferWeb extends StatefulWidget {
  const StockTransferWeb(
      {Key? key,
      required this.authorization,
      required this.refreshToken,
      required this.prodId,
      required this.fromDropDownValue,
      required this.toDropDownValue,
      required this.isUpdated})
      : super(key: key);

  final String authorization;
  final String refreshToken;
  final String prodId;
  final int fromDropDownValue;
  final int toDropDownValue;
  final bool isUpdated;

  @override
  State<StockTransferWeb> createState() => _StockTransferWebState();
}

class _StockTransferWebState extends State<StockTransferWeb> {
  late TextEditingController quanToTransferController;

  int fromDropDownValue = 0;
  int toDropDownValue = 0;
  int selectedFromDistCenter = 0;
  int selectedToDistCenter = 0;
  int fromQuantity = 0;
  int toQuantity = 0;

  int fromDropDownValueToSent = 0;
  int toDropDownValueToSent = 0;

  String selectedFromDistName = '';
  String selectedToDistName = '';

  bool isLoading = true;

  List fullList = [];
  List<String> allItems = [];
  List<int> distIds = [];
  List<int> quantitySetter = [];
  List<QuantityValue> quantityValues = [];
  List<String> toItems = [];
  List<Model> fromModelList = [];
  List<Model> toModelList = [];

  @override
  void initState() {
    quanToTransferController = TextEditingController();
    apiCallToTransferScreen();
    super.initState();
  }

  void apiCallToTransferScreen() async {
    await ApiCalls.tokenAPIWeb()
        .then((tokenXX) => getProductQuantity(tokenXX, widget.prodId)
            .then((value) => getAllDistCenter(tokenXX)))
        .whenComplete(() {
      setState(() {
        isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    FocusScopeNode currentFocus = FocusScope.of(context);
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
          'Stock Transfer',
          style: TextStyle(
            color: Colors.black,
            fontSize: ResponsiveCheck.isLargeScreen(context)
                ? size.width * .02
                : ResponsiveCheck.isMediumScreen(context)
                    ? size.width * .025
                    : size.width * .03,
          ),
        ),
      ),
      body: SizedBox(
        height: size.height,
        width: size.width,
        child: isLoading == true
            ? const Center(
                child: CircularProgressIndicator(
                  color: appColor,
                ),
              )
            : GestureDetector(
                onTap: () {
                  FocusScope.of(context).requestFocus(FocusNode());
                  if (!currentFocus.hasPrimaryFocus) {
                    currentFocus.unfocus();
                  }
                },
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.only(
                          left: size.width * .05,
                          right: size.width * .05,
                          top: size.width * .01),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            height: size.height * .05,
                            width: size.width * .9,
                            color: appColor,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'From',
                                  style: TextStyle(
                                      fontSize:
                                          ResponsiveCheck.isLargeScreen(context)
                                              ? size.width * .015
                                              : ResponsiveCheck.isMediumScreen(
                                                      context)
                                                  ? size.width * .02
                                                  : size.width * .025,
                                      color: Colors.white),
                                )
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(
                          left: size.width * .06,
                          right: size.width * .06,
                          top: size.width * .01),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Distribution Center',
                            style: TextStyle(
                                fontSize: ResponsiveCheck.isLargeScreen(context)
                                    ? size.width * .01
                                    : ResponsiveCheck.isMediumScreen(context)
                                        ? size.width * .018
                                        : size.width * .022,
                                fontWeight: FontWeight.bold),
                          ),
                          Text('Current Quantity',
                              style: TextStyle(
                                  fontSize: ResponsiveCheck.isLargeScreen(
                                          context)
                                      ? size.width * .01
                                      : ResponsiveCheck.isMediumScreen(context)
                                          ? size.width * .018
                                          : size.width * .022,
                                  fontWeight: FontWeight.bold))
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(
                          left: size.width * .05,
                          right: size.width * .05,
                          top: size.width * .01),
                      child: Container(
                        height: size.height * .08,
                        width: size.width,
                        color: Colors.grey.shade200,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.only(left: 5),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton(
                                    elevation: 0,
                                    value: fromDropDownValue,
                                    icon: const Icon(Icons.keyboard_arrow_down),
                                    items: fromModelList
                                        .map((value) => DropdownMenuItem(
                                            value: value.id,

                                            /// value is in between 0 to fullList.length-1
                                            child: Text(value.value)))
                                        .toList(),
                                    onChanged: (Object? newValue) {
                                      setState(() {
                                        fromDropDownValue = newValue as int;
                                        fromQuantity = quantitySetter[newValue];

                                        setState(() {
                                          fromDropDownValueToSent = newValue;
                                        });
                                        log('fromDropDownValueToSent - $fromDropDownValueToSent');

                                        selectedFromDistCenter =
                                            fullList[newValue]['ID'];
                                        log("selectedFromDistCenter - $selectedFromDistCenter");

                                        selectedFromDistName =
                                            fullList[newValue]['Name'];
                                        log('selectedFromDistName - $selectedFromDistName');

                                        if (newValue ==
                                            fromModelList.length - 1) {
                                          ///****************************** SELECTED DC FOR 'FROM' IS LAST ********************************///

                                          toModelList = [];
                                          toModelList.addAll(
                                              fromModelList.map((e) => e));
                                          setState(() {
                                            toDropDownValue = 0;
                                            toDropDownValueToSent = 0;
                                            selectedToDistCenter =
                                                fullList[0]['ID'];
                                            selectedToDistName =
                                                fullList[0]['Name'];
                                            toQuantity = int.parse(
                                                '${quantitySetter[0]}');
                                          });
                                          log('toDropDownValue - $toDropDownValue');
                                          log('toDropDownValueToSent - $toDropDownValueToSent');
                                          log("selectedToDistCenter - $selectedToDistCenter");
                                          log('selectedToDistName - $selectedToDistName');
                                          log('toQuantity- $toQuantity');
                                          toModelList.removeAt(newValue);
                                        } else {
                                          ///****************************** SELECTED DC FOR 'FROM' IS NOT LAST ****************************///

                                          toModelList = [];
                                          toModelList.addAll(
                                              fromModelList.map((e) => e));
                                          setState(() {
                                            toDropDownValue = newValue + 1;
                                            toDropDownValueToSent =
                                                newValue + 1;
                                            selectedToDistCenter =
                                                fullList[newValue + 1]['ID'];
                                            selectedToDistName =
                                                fullList[newValue + 1]['Name'];
                                            toQuantity = int.parse(
                                                '${quantitySetter[newValue + 1]}');
                                          });
                                          log('toDropDownValue - $toDropDownValue');
                                          log('toDropDownValueToSent - $toDropDownValueToSent');
                                          log("selectedToDistCenter - $selectedToDistCenter");
                                          log('selectedToDistName - $selectedToDistName');
                                          log('toQuantity- $toQuantity');
                                          toModelList.removeAt(newValue);
                                        }
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Card(
                                    child: SizedBox(
                                      height: size.height * .06,
                                      width: size.width * .23,
                                      child: Center(
                                        child: Text(
                                          '$fromQuantity',
                                          style: TextStyle(
                                            fontSize: ResponsiveCheck
                                                    .isLargeScreen(context)
                                                ? size.width * .015
                                                : ResponsiveCheck
                                                        .isMediumScreen(context)
                                                    ? size.width * .02
                                                    : size.width * .025,
                                          ),
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
                    ),
                    Padding(
                      padding: EdgeInsets.only(
                          left: size.width * .05,
                          right: size.width * .05,
                          top: size.width * .02),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            height: size.height * .06,
                            width: size.width * .9,
                            color: appColor,
                            child: Center(
                              child: Text(
                                'To',
                                style: TextStyle(
                                    fontSize:
                                        ResponsiveCheck.isLargeScreen(context)
                                            ? size.width * .015
                                            : ResponsiveCheck.isMediumScreen(
                                                    context)
                                                ? size.width * .02
                                                : size.width * .025,
                                    color: Colors.white),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(
                          left: size.width * .06,
                          right: size.width * .06,
                          top: size.width * .01),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Distribution Center',
                            style: TextStyle(
                                fontSize: ResponsiveCheck.isLargeScreen(context)
                                    ? size.width * .01
                                    : ResponsiveCheck.isMediumScreen(context)
                                        ? size.width * .018
                                        : size.width * .022,
                                fontWeight: FontWeight.bold),
                          ),
                          Text(' Current Quantity',
                              style: TextStyle(
                                  fontSize: ResponsiveCheck.isLargeScreen(
                                          context)
                                      ? size.width * .01
                                      : ResponsiveCheck.isMediumScreen(context)
                                          ? size.width * .018
                                          : size.width * .022,
                                  fontWeight: FontWeight.bold))
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(
                          left: size.width * .05,
                          right: size.width * .05,
                          top: size.width * .01),
                      child: Container(
                        height: size.height * .08,
                        width: size.width,
                        color: Colors.grey.shade200,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.only(left: 5),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton(
                                    elevation: 0,
                                    value: toDropDownValue,
                                    icon: const Icon(Icons.keyboard_arrow_down),
                                    items: toModelList
                                        .map((value) => DropdownMenuItem(
                                            value: value.id,
                                            child: Text(value.value)))
                                        .toList(),
                                    onChanged: (Object? newValue) {
                                      setState(() {
                                        toDropDownValue = newValue as int;
                                        toDropDownValueToSent = newValue;
                                        selectedToDistCenter =
                                            fullList[newValue]['ID'];
                                        selectedToDistName =
                                            fullList[newValue]['Name'];
                                        toQuantity = int.parse(
                                            '${quantitySetter[newValue]}');
                                      });
                                      log('toDropDownValue - $toDropDownValue');
                                      log('toDropDownValueToSent - $toDropDownValueToSent');
                                      log("selectedToDistCenter - $selectedToDistCenter");
                                      log('selectedToDistName - $selectedToDistName');
                                      log('toQuantity - $toQuantity');
                                    },
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Card(
                                    child: SizedBox(
                                      height: size.height * .06,
                                      width: size.width * .23,
                                      child: Center(
                                        child: Text(
                                          '$toQuantity',
                                          style: TextStyle(
                                            fontSize: ResponsiveCheck
                                                    .isLargeScreen(context)
                                                ? size.width * .015
                                                : ResponsiveCheck
                                                        .isMediumScreen(context)
                                                    ? size.width * .02
                                                    : size.width * .025,
                                          ),
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
                    ),
                    Padding(
                      padding: EdgeInsets.only(
                          left: size.width * .06,
                          right: size.width * .06,
                          top: size.width * .02),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Transfer Quantity',
                            style: TextStyle(
                              fontSize: ResponsiveCheck.isLargeScreen(context)
                                  ? size.width * .012
                                  : ResponsiveCheck.isMediumScreen(context)
                                      ? size.width * .018
                                      : size.width * .022,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(
                          left: size.width * .05,
                          right: size.width * .05,
                          top: size.width * .01),
                      child: Container(
                        color: Colors.grey.shade200,
                        width: size.width * .25,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              height: size.width * .04,
                              width: size.width * .04,
                              child: FittedBox(
                                child: IconButton(
                                    onPressed: () {
                                      if (int.parse(quanToTransferController
                                              .text
                                              .toString()) >
                                          0) {
                                        setState(() {
                                          quanToTransferController.text =
                                              '${int.parse(quanToTransferController.text.toString()) - 1}';
                                        });
                                      }
                                    },
                                    icon: Icon(
                                      Icons.remove,
                                      size:
                                          ResponsiveCheck.isLargeScreen(context)
                                              ? size.width * .01
                                              : ResponsiveCheck.isMediumScreen(
                                                      context)
                                                  ? size.width * .015
                                                  : size.width * .02,
                                    )),
                              ),
                            ),
                            Card(
                              child: SizedBox(
                                  height: size.height * .05,
                                  width: size.width * .15,
                                  child: Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: ThemeData()
                                          .colorScheme
                                          .copyWith(primary: appColor),
                                    ),
                                    child: TextFormField(
                                      controller: quanToTransferController,
                                      textAlign: TextAlign.center,
                                    ),
                                  )),
                            ),
                            SizedBox(
                              height: size.width * .04,
                              width: size.width * .04,
                              child: FittedBox(
                                child: IconButton(
                                  onPressed: () {
                                    setState(() {
                                      quanToTransferController.text =
                                          '${int.parse(quanToTransferController.text.toString()) + 1}';
                                    });
                                  },
                                  icon: Icon(
                                    Icons.add,
                                    size: ResponsiveCheck.isLargeScreen(context)
                                        ? size.width * .01
                                        : ResponsiveCheck.isMediumScreen(
                                                context)
                                            ? size.width * .015
                                            : size.width * .02,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(
                          left: size.width * .05,
                          right: size.width * .05,
                          top: size.width * .02),
                      child: GestureDetector(
                        onTap: () async {
                          if (quanToTransferController.text.isNotEmpty) {
                            if (int.parse(
                                    quanToTransferController.text.toString()) >=
                                0) {
                              if (fromQuantity == 0) {
                                Fluttertoast.showToast(
                                    msg: 'Not Enough Quantity to transfer.',
                                    toastLength: Toast.LENGTH_LONG);
                              }

                              if (fromQuantity > 0) {
                                if (int.parse(quanToTransferController.text
                                        .toString()) >
                                    0) {
                                  if ((fromQuantity -
                                          int.parse(quanToTransferController
                                              .text
                                              .toString())) >=
                                      0) {
                                    /// ONLY THAT MUCH QUANTITY CAN BE INCREASED, WHAT [fromQuantity] IS HAVING.

                                    setState(() {
                                      isLoading = true;
                                    });
                                    await ApiCalls.tokenAPIWeb()
                                        .then((value) async {
                                      await updateQuantity(
                                        accessToken: value,
                                        productId: widget.prodId,
                                        fromDistCenter: selectedFromDistCenter,
                                        fromQuantity: fromQuantity -
                                            int.parse(quanToTransferController
                                                .text
                                                .toString()),
                                        toDistCenter: selectedToDistCenter,
                                        toQuantity: toQuantity +
                                            int.parse(quanToTransferController
                                                .text
                                                .toString()),
                                      ).whenComplete(() async {
                                        log('sent fromDropDownValue - ${fromModelList.indexWhere((e) => e.value == selectedFromDistName)}');
                                        log('sent toDropDownValue - ${fromModelList.indexWhere((e) => e.value == selectedToDistName)}');

                                        await Navigator.pushReplacement(
                                          context,
                                          PageRouteBuilder(
                                            pageBuilder: (context, animation,
                                                    secondaryAnimation) =>
                                                StockTransferWeb(
                                              authorization:
                                                  widget.authorization,
                                              refreshToken: widget.refreshToken,
                                              prodId: widget.prodId,
                                              isUpdated: true,
                                              fromDropDownValue:
                                                  fromDropDownValueToSent,
                                              // fromModelList
                                              //     .indexWhere((e) =>
                                              //         e.value ==
                                              //         selectedFromDistName),
                                              toDropDownValue:
                                                  toDropDownValueToSent,
                                              //   fromModelList
                                              // .indexWhere((e) =>
                                              //     e.value ==
                                              //     selectedToDistName),
                                            ),
                                            transitionsBuilder: (context,
                                                animation,
                                                secondaryAnimation,
                                                child) {
                                              const begin = Offset(1.0, 0.0);
                                              const end = Offset.zero;
                                              const curve = Curves.ease;

                                              var tween = Tween(
                                                      begin: begin, end: end)
                                                  .chain(
                                                      CurveTween(curve: curve));

                                              return SlideTransition(
                                                position:
                                                    animation.drive(tween),
                                                child: child,
                                              );
                                            },
                                          ),
                                        );
                                      });
                                    });
                                  } else {
                                    Fluttertoast.showToast(
                                        msg: 'Not Enough Quantity to transfer.',
                                        toastLength: Toast.LENGTH_LONG);
                                  }
                                }
                              }
                            } else {
                              Fluttertoast.showToast(
                                  msg: 'Quantities cannot be Negative.');
                            }
                          } else {
                            Fluttertoast.showToast(
                                msg:
                                    'Quantity field cannot be empty. Please give 0 value either.');
                          }
                        },
                        child: Container(
                          color: Colors.green,
                          height: size.height * .06,
                          width: size.width * .5,
                          child: Center(
                            child: Text(
                              'Transfer',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: ResponsiveCheck.isLargeScreen(context)
                                    ? size.width * .012
                                    : ResponsiveCheck.isMediumScreen(context)
                                        ? size.width * .018
                                        : size.width * .022,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Visibility(
                      visible: widget.isUpdated,
                      child: Padding(
                        padding: EdgeInsets.only(
                            left: size.width * .05,
                            right: size.width * .05,
                            top: size.width * .02),
                        child: GestureDetector(
                          onTap: () async {
                            Navigator.popUntil(
                                context, (route) => route.isFirst);
                          },
                          child: Container(
                            color: Colors.lightBlueAccent,
                            height: size.height * .06,
                            width: size.width * .7,
                            child: Center(
                              child: Text(
                                'Scan New Barcode (EAN)',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: ResponsiveCheck.isLargeScreen(
                                          context)
                                      ? size.width * .012
                                      : ResponsiveCheck.isMediumScreen(context)
                                          ? size.width * .018
                                          : size.width * .022,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Future<String> updateQuantity({
    required String accessToken,
    required String productId,
    required int fromDistCenter,
    required int fromQuantity,
    required int toDistCenter,
    required int toQuantity,
  }) async {
    String uri =
        'https://api.channeladvisor.com/v1/Products($productId)/UpdateQuantity?$kAccessToken$accessToken';
    log('Update quantity uri - $uri');

    final body = {
      "Value": {
        "UpdateType": "InStock",
        "Updates": [
          {"DistributionCenterID": fromDistCenter, "Quantity": fromQuantity},
          {"DistributionCenterID": toDistCenter, "Quantity": toQuantity},
        ]
      }
    };

    var header = {
      "origin": "*",
      "Content-Type": "application/json"
    };

    log('body - ${jsonEncode(body)}');

    try {
      var response = await http.post(Uri.parse(uri),
          body: jsonEncode(body),
          headers: header).timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          Fluttertoast.showToast(msg: "Connection Timeout.\nPlease try again.");
          setState(() {});
          return http.Response('Error', 408);
        },
      );

      log('status code - ${response.statusCode}');

      if (response.statusCode == 204) {
        log('Quantity updated successfully');
        setState(() {});
        Fluttertoast.showToast(
            msg: 'Quantity updated successfully',
            toastLength: Toast.LENGTH_LONG);
        return 'Quantity updated successfully';
      } else {
        Fluttertoast.showToast(
            msg: '$kerrorString\nStatus code${response.statusCode}');
        setState(() {});
        return kerrorString;
      }
    } on Exception catch (e) {
      log(e.toString());
      setState(() {});
      return kerrorString;
    }
  }

  Future<void> getProductQuantity(String accessToken, String productId) async {
    String uri =
        'https://api.channeladvisor.com/v1/Products($productId)/DCQuantities?$kAccessToken$accessToken';
    log('Product Quantity uri - $uri');

    var header = {
      "origin": "*",
    };

    try {
      var response = await http.get(Uri.parse(uri), headers: header).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          Fluttertoast.showToast(msg: "Connection Timeout.\nPlease try again.");
          return http.Response('Error', 408);
        },
      );

      if (response.statusCode == 200) {
        log('get product quantity response - ${jsonDecode(response.body)}');

        GetProductQuantityResponse getProductQuantityResponse =
            GetProductQuantityResponse.fromJson(jsonDecode(response.body));
        log("getProductQuantityResponse - ${jsonEncode(getProductQuantityResponse)}");

        quantityValues = [];
        quantityValues.addAll(getProductQuantityResponse.value);
        log('quantityValues - ${jsonEncode(quantityValues)}');

        distIds = [];
        distIds.addAll(quantityValues.map((e) => e.distributionCenterId));
        log('distIds - $distIds');
      } else {
        Fluttertoast.showToast(
            msg: '$kerrorString\nStatus code - ${response.statusCode}');
      }
    } on Exception catch (e) {
      log(e.toString());
    }
  }

  Future<void> getAllDistCenter(String accessToken) async {
    String uri =
        'https://api.channeladvisor.com/v1/DistributionCenters?$kAccessToken$accessToken&${kSelect}ID,Name,Type&$kFilter(Type eq $kWareHouse or Type eq $kRetail)and IsDeleted eq false';
    log('All Distribution Centers uri - $uri');

    var header = {
      'origin': "*",
    };

    try {
      var response = await http.get(Uri.parse(uri), headers: header).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          Fluttertoast.showToast(msg: "Connection Timeout.\nPlease try again.");
          return http.Response('Error', 408);
        },
      );

      if (response.statusCode == 200) {
        log('all distribution centers response - ${jsonDecode(response.body)}');

        ///************************ COMMON FULL LIST ********************************///

        fullList = [];
        fullList.addAll((jsonDecode(response.body)['value']));
        log('fullList - $fullList');

        ///************************ COMMON ALL ITEMS *******************************///

        allItems = [];
        allItems.addAll(fullList.map((e) => e['Name']));
        log('allItems - $allItems');

        if (kIsWeb == false) {
          setState(() {
            allItems[allItems
                    .indexOf('Jadlam Toys & Models - Glastonbury Shop')] =
                'Jadlam Toys & Models\n- Glastonbury Shop';
          });
          log('Updated allItems - $allItems');
        }

        ///********************** COMMON QUANTITY SETTER ****************************///

        quantitySetter = [];
        quantitySetter = List.generate(fullList.length, (index) => 0);

        for (int j = 0; j < fullList.length; j++) {
          for (int i = 0; i < quantityValues.length; i++) {
            if (quantityValues[i].distributionCenterId == fullList[j]['ID']) {
              quantitySetter.insert(j, quantityValues[i].availableQuantity);
              quantitySetter.removeAt(j + 1);
            }
          }
        }
        log("quantitySetter - $quantitySetter");

        ///**************************  SET THE 'FROM' PART **************************///

        fromModelList = [];
        for (int i = 0; i < allItems.length; i++) {
          fromModelList.add(Model(i, allItems[i], quantitySetter[i]));
        }
        log('fromModelList Length - ${fromModelList.length}');

        setState(() {
          fromDropDownValue = widget.fromDropDownValue;
          toDropDownValue = widget.toDropDownValue;
        });

        log('fromDropDownValue - $fromDropDownValue');
        log('toDropDownValue - $toDropDownValue');

        fromQuantity = 0;
        fromQuantity = fromModelList[widget.fromDropDownValue].quantity;
        log('from quantity - $fromQuantity');

        selectedFromDistCenter = fullList[widget.fromDropDownValue]['ID'];
        selectedFromDistName = fullList[widget.fromDropDownValue]['Name'];
        log('selectedFromDistCenter - $selectedFromDistCenter');
        log('selectedFromDistName - $selectedFromDistName');

        ///****************************  SET THE 'TO' PART **************************///

        toModelList = [];
        for (int i = 0; i < allItems.length; i++) {
          toModelList.add(Model(i, allItems[i], quantitySetter[i]));
        }
        log('toModelList Length - ${toModelList.length}');

        toQuantity =
            int.parse('${toModelList[widget.toDropDownValue].quantity}');
        log('Current TO Quantity Value - $toQuantity');

        quanToTransferController.text = '';
        setState(() {
          quanToTransferController.text = '1';
        });

        selectedToDistCenter = fullList[widget.toDropDownValue]['ID'];
        selectedToDistName = fullList[widget.toDropDownValue]['Name'];

        fromDropDownValueToSent = 0;
        toDropDownValueToSent = 0;
        setState(() {
          fromDropDownValueToSent = widget.fromDropDownValue;
          toDropDownValueToSent = widget.toDropDownValue;
        });

        toModelList.removeAt(
            fromModelList.indexWhere((e) => e.value == selectedFromDistName));
        log('Updated toModelList Length - ${toModelList.length}');

        log('selectedToDistCenter - $selectedToDistCenter');
        log('selectedToDistName - $selectedToDistName');
      } else {
        ToastUtils.showCenteredShortToast(message: kerrorString);
      }
    } on Exception catch (e) {
      log(e.toString());
      ToastUtils.showCenteredLongToast(message: e.toString());
    }
  }
}

class Model {
  int id;
  String value;
  int quantity;

  Model(this.id, this.value, this.quantity);
}
