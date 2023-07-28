import 'dart:convert';
import 'dart:developer';

import 'package:absolute_app/core/utils/constants.dart';
import 'package:absolute_app/core/utils/toast_utils.dart';
import 'package:absolute_app/models/get_pre_orders_response.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_search_bar/easy_search_bar.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_network/image_network.dart';
import 'package:rounded_loading_button/rounded_loading_button.dart';

class PreOrderScreen extends StatefulWidget {
  const PreOrderScreen({super.key});

  @override
  State<PreOrderScreen> createState() => _PreOrderScreenState();
}

class _PreOrderScreenState extends State<PreOrderScreen> {
  final RoundedLoadingButtonController createController =
      RoundedLoadingButtonController();

  List<SkuPreOrders> preOrdersList = [];
  List<bool> checkBoxValueListForPreOrders = [];
  List<String> skuSuggestions = [];

  bool isLoading = false;
  bool isError = false;
  bool isAllSelected = false;
  // bool isCreatingPicklist = true;

  String error = '';
  String searchValue = '';

  @override
  void initState() {
    super.initState();
    preOrderInitCall();
  }

  void preOrderInitCall() async {
    await getAllPreOrders();
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return SelectionArea(
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        resizeToAvoidBottomInset: true,
        appBar: EasySearchBar(
            backgroundColor: Colors.white,
            title: const Center(
              child: Text(
                'Pre-Orders',
                style: TextStyle(
                  fontSize: 25,
                  color: Colors.black,
                ),
              ),
            ),
            searchHintText: 'Search SKU',
            searchHintStyle: const TextStyle(
              fontSize: 18,
              color: Colors.black,
            ),
            searchTextStyle: const TextStyle(
              fontSize: 18,
              color: Colors.black,
            ),
            suggestionTextStyle: const TextStyle(
              fontSize: 16,
              color: Colors.black,
            ),
            onSearch: (value) async {
              setState(() {
                searchValue = value;
              });
              await getPreOrdersBySKU(sku: value);
            },
            asyncSuggestions: (value) async {
              return await _fetchSuggestions(value);
            }),
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
                        style: TextStyle(
                          fontSize: size.width * .045,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  )
                : Stack(
                    children: [
                      SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 10,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _selectAllTab(context, size),
                              _createPicklistButton(context, size),
                              ..._preOrdersListMaker(size),
                            ],
                          ),
                        ),
                      ),
                      // Visibility(
                      //   visible: isCreatingPicklist,
                      //   child: Container(
                      //     height: size.height,
                      //     width: size.width,
                      //     color: Colors.grey.shade300.withOpacity(0.5),
                      //   ),
                      // ),
                    ],
                  ),
      ),
    );
  }

  /// BUILDER METHODS

  /// SELECT ALL TAB
  Widget _selectAllTab(BuildContext context, Size size) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Card(
        elevation: 2,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: SizedBox(
            width: size.width,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Select All',
                  style: TextStyle(fontSize: 20),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 20),
                  child: Checkbox(
                    value: isAllSelected,
                    activeColor: appColor,
                    onChanged: (bool? value) {
                      setState(() {
                        isAllSelected = !isAllSelected;
                      });
                      log('V isAllSelected >>---> $isAllSelected');
                      if (isAllSelected == true) {
                        List<bool> temp = [];
                        for (int i = 0;
                            i < checkBoxValueListForPreOrders.length;
                            i++) {
                          temp.add(true);
                        }
                        checkBoxValueListForPreOrders = [];
                        checkBoxValueListForPreOrders
                            .addAll(temp.map((e) => e));
                        log('ALL SELECTED >>---> ${checkBoxValueListForPreOrders.every((e) => e == true) ? 'Yes' : 'No'}');
                      } else {
                        List<bool> temp = [];
                        for (int i = 0;
                            i < checkBoxValueListForPreOrders.length;
                            i++) {
                          temp.add(false);
                        }
                        checkBoxValueListForPreOrders = [];
                        checkBoxValueListForPreOrders
                            .addAll(temp.map((e) => e));
                        log('ALL DE-SELECTED >>---> ${checkBoxValueListForPreOrders.every((e) => e == false) ? 'Yes' : 'No'}');
                      }
                    },
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Create Picklist Button
  Widget _createPicklistButton(BuildContext context, Size size) {
    return Visibility(
      visible: checkBoxValueListForPreOrders.any((e) => e == true),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: SizedBox(
          width: size.width,
          child: Center(
            child: RoundedLoadingButton(
              color: Colors.green,
              borderRadius: 10,
              elevation: 10,
              height: 40,
              width: 200,
              successIcon: Icons.check_rounded,
              failedIcon: Icons.close_rounded,
              successColor: Colors.green,
              errorColor: appColor,
              controller: createController,
              onPressed: () async {
                await Future.delayed(const Duration(seconds: 1), () {
                  createController.reset();
                });
              },
              child: const Text(
                'Create Picklist',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// LIST GENERATOR FOR PRE-ORDERS
  List<Widget> _preOrdersListMaker(Size size) {
    return List.generate(
      10,
      (index) => GestureDetector(
        onTap: () {
          setState(() {
            checkBoxValueListForPreOrders[index] =
                !(checkBoxValueListForPreOrders[index]);
          });
          log('V checkBoxValueListForPreOrders At $index >>---> ${checkBoxValueListForPreOrders[index]}');
          if (checkBoxValueListForPreOrders.every((e) => e == true)) {
            setState(() {
              isAllSelected = true;
            });
          } else {
            setState(() {
              isAllSelected = false;
            });
          }
        },
        child: Card(
          elevation: 2,
          color: checkBoxValueListForPreOrders[index] == true
              ? preOrderColor
              : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              children: [
                SizedBox(
                  height: 60,
                  width: size.width * .9,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          preOrdersList[index].title,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                          style: TextStyle(
                            fontSize: size.width * .045,
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                  elevation: 5,
                  child: Center(
                    child: preOrdersList[index].imageUrl.isEmpty
                        ? Image.asset(
                            'assets/no_image/no_image.png',
                            height: size.width * .8,
                            width: size.width * .8,
                            fit: BoxFit.contain,
                          )
                        : ImageNetwork(
                            image: preOrdersList[index].imageUrl,
                            imageCache: CachedNetworkImageProvider(
                              preOrdersList[index].imageUrl,
                            ),
                            height: size.width * .8,
                            width: size.width * .8,
                            duration: 100,
                            fitAndroidIos: BoxFit.contain,
                            fitWeb: BoxFitWeb.contain,
                            onLoading: const Center(
                              child: CircularProgressIndicator(
                                color: appColor,
                              ),
                            ),
                            onError: Image.asset(
                              'assets/no_image/no_image.png',
                              height: size.width * .8,
                              width: size.width * .8,
                              fit: BoxFit.contain,
                            ),
                          ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 160,
                      width: size.width * .75,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: 160,
                            width: size.width * .35,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Order Number ',
                                  style: TextStyle(
                                    fontSize: size.width * .04,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                Text(
                                  'SKU ',
                                  style: TextStyle(
                                    fontSize: size.width * .04,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                Text(
                                  'Order Date ',
                                  style: TextStyle(
                                    fontSize: size.width * .04,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                Flexible(
                                  child: Text(
                                    'Warehouse Location ',
                                    overflow: TextOverflow.visible,
                                    style: TextStyle(
                                      fontSize: size.width * .04,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: 160,
                            width: size.width * .4,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  preOrdersList[index].orderNumber,
                                  style: TextStyle(
                                    fontSize: size.width * .04,
                                    color: Colors.black,
                                  ),
                                ),
                                Text(
                                  preOrdersList[index].sku,
                                  style: TextStyle(
                                    fontSize: size.width * .04,
                                    color: Colors.black,
                                  ),
                                ),
                                Flexible(
                                  child: Text(
                                    preOrdersList[index].orderDate,
                                    overflow: TextOverflow.visible,
                                    style: TextStyle(
                                      fontSize: size.width * .04,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                                Flexible(
                                  child: Text(
                                    preOrdersList[index].warehouseLocation,
                                    overflow: TextOverflow.visible,
                                    style: TextStyle(
                                      fontSize: size.width * .04,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 160,
                      width: size.width * .1,
                      child: Center(
                        child: Checkbox(
                          activeColor: appColor,
                          value: checkBoxValueListForPreOrders[index],
                          onChanged: (bool? newValue) {
                            setState(() {
                              checkBoxValueListForPreOrders[index] =
                                  !(checkBoxValueListForPreOrders[index]);
                            });
                            log('V checkBoxValueListForPreOrders At $index >>---> ${checkBoxValueListForPreOrders[index]}');
                            if (checkBoxValueListForPreOrders
                                .every((e) => e == true)) {
                              setState(() {
                                isAllSelected = true;
                              });
                            } else {
                              setState(() {
                                isAllSelected = false;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// API METHODS

  /// THIS API IS FOR FETCHING SKU SEARCH SUGGESTIONS
  Future<List<String>> _fetchSuggestions(String searchValue) async {
    await Future.delayed(const Duration(milliseconds: 500));

    return skuSuggestions.where((element) {
      return element.toLowerCase().contains(searchValue.toLowerCase());
    }).toList();
  }

  /// THIS API IS TO BE USED FOR FETCHING ALL PRE-ORDERS OF LAST 1 YEAR.
  Future<void> getAllPreOrders() async {
    setState(() {
      error = '';
      isLoading = true;
      isError = false;
    });
    String uri = 'https://weblegs.info/JadlamApp/api/GetPreOrdersfirst';
    log('GET ALL PRE-ORDERS API URI >>---> $uri');

    try {
      var response = await http.get(Uri.parse(uri)).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          ToastUtils.showCenteredShortToast(message: kTimeOut);
          setState(() {
            isLoading = false;
            isError = true;
            error = kTimeOut;
          });
          return http.Response('Error', 408);
        },
      );
      log('GET ALL PRE-ORDERS API STATUS CODE >>---> ${response.statusCode}');
      if (response.statusCode == 200) {
        GetPreOrdersResponse getPreOrdersResponse =
            GetPreOrdersResponse.fromJson(jsonDecode(response.body));
        log('V getPreOrdersResponse >>---> ${jsonEncode(getPreOrdersResponse)}');

        if (getPreOrdersResponse.sku.isEmpty) {
          setState(() {
            isLoading = false;
            isError = true;
            error = 'No Orders found!';
          });
        } else {
          preOrdersList = [];
          preOrdersList.addAll(getPreOrdersResponse.sku.map((e) => e));
          log('V preOrdersList >>---> ${jsonEncode(preOrdersList)}');

          checkBoxValueListForPreOrders = [];
          checkBoxValueListForPreOrders.addAll(preOrdersList.map((e) => false));
          log('V checkBoxValueListForPreOrders >>---> $checkBoxValueListForPreOrders');

          skuSuggestions = [];
          List<String> tempListForSKUSuggestions = [];
          tempListForSKUSuggestions.addAll(preOrdersList.map((e) => e.sku));
          skuSuggestions
              .addAll(tempListForSKUSuggestions.toSet().toList().map((e) => e));
          log('V tempListForSKUSuggestions >>---> $tempListForSKUSuggestions');
          log('V skuSuggestions >>---> $skuSuggestions');

          setState(() {
            isLoading = false;
            isError = false;
            error = '';
          });
        }
      } else {
        ToastUtils.showCenteredShortToast(message: kerrorString);
        setState(() {
          isLoading = false;
          isError = true;
          error = kerrorString;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        isError = true;
        error = e.toString();
      });
      log("GET ALL PRE-ORDERS API EXCEPTION >>---> ${e.toString()}");
    }
  }

  /// THIS API IS TO BE USED FOR FETCHING PRE-ORDERS BY SKU.
  Future<void> getPreOrdersBySKU({required String sku}) async {
    setState(() {
      error = '';
      isLoading = true;
      isError = false;
    });
    String uri =
        'https://weblegs.info/JadlamApp/api/GetPreOrdersfirst?SKU=$sku';
    log('GET PRE-ORDERS BY SKU API URI >>---> $uri');

    try {
      var response = await http.get(Uri.parse(uri)).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          ToastUtils.showCenteredShortToast(message: kTimeOut);
          setState(() {
            isLoading = false;
            isError = true;
            error = kTimeOut;
          });
          return http.Response('Error', 408);
        },
      );
      log('GET PRE-ORDERS BY SKU API STATUS CODE >>---> ${response.statusCode}');
      if (response.statusCode == 200) {
        GetPreOrdersResponse getPreOrdersResponse =
            GetPreOrdersResponse.fromJson(jsonDecode(response.body));
        log('V getPreOrdersResponse >>---> ${jsonEncode(getPreOrdersResponse)}');

        if (getPreOrdersResponse.sku.isEmpty) {
          setState(() {
            isLoading = false;
            isError = true;
            error = 'No Orders found!';
          });
        } else {
          preOrdersList = [];
          preOrdersList.addAll(getPreOrdersResponse.sku.map((e) => e));
          log('V preOrdersList >>---> ${jsonEncode(preOrdersList)}');

          checkBoxValueListForPreOrders = [];
          checkBoxValueListForPreOrders.addAll(preOrdersList.map((e) => false));
          log('V checkBoxValueListForPreOrders >>---> $checkBoxValueListForPreOrders');

          setState(() {
            isLoading = false;
            isError = false;
            error = '';
          });
        }
      } else {
        ToastUtils.showCenteredShortToast(message: kerrorString);
        setState(() {
          isLoading = false;
          isError = true;
          error = kerrorString;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        isError = true;
        error = e.toString();
      });
      log("GET PRE-ORDERS BY SKU API EXCEPTION >>---> ${e.toString()}");
    }
  }

  // /// THIS API IS USED FOR CREATING PICKLIST OUT OF PRE-ORDERS
  // Future<void> createPicklistOutOfPreOrders({
  //   required String selectedOrders,
  // }) async {
  //   setState(() {
  //     isLoading = true;
  //   });
  //   String uri =
  //       'https://weblegs.info/JadlamApp/api/CreatingPicklistOutOfPreOrders?OrderNumbers=$selectedOrders';
  //   log('CREATE PICKLIST OUT OF PREORDERS URI >>---> $uri');
  //
  //   try {
  //     var response = await http.get(Uri.parse(uri)).timeout(
  //       const Duration(seconds: 30),
  //       onTimeout: () {
  //         ToastUtils.showCenteredShortToast(message: kTimeOut);
  //         setState(() {
  //           isLoading = false;
  //           isError = true;
  //           error = kTimeOut;
  //         });
  //         return http.Response('Error', 408);
  //       },
  //     );
  //     log('GET PRE-ORDERS BY SKU API STATUS CODE >>---> ${response.statusCode}');
  //     if (response.statusCode == 200) {
  //       GetPreOrdersResponse getPreOrdersResponse =
  //           GetPreOrdersResponse.fromJson(jsonDecode(response.body));
  //       log('V getPreOrdersResponse >>---> ${jsonEncode(getPreOrdersResponse)}');
  //
  //       if (getPreOrdersResponse.sku.isEmpty) {
  //         setState(() {
  //           isLoading = false;
  //           isError = true;
  //           error = 'No Orders found!';
  //         });
  //       } else {
  //         preOrdersList = [];
  //         preOrdersList.addAll(getPreOrdersResponse.sku.map((e) => e));
  //         log('V preOrdersList >>---> ${jsonEncode(preOrdersList)}');
  //
  //         checkBoxValueListForPreOrders = [];
  //         checkBoxValueListForPreOrders.addAll(preOrdersList.map((e) => false));
  //         log('V checkBoxValueListForPreOrders >>---> $checkBoxValueListForPreOrders');
  //
  //         setState(() {
  //           isLoading = false;
  //           isError = false;
  //           error = '';
  //         });
  //       }
  //     } else {
  //       ToastUtils.showCenteredShortToast(message: kerrorString);
  //       setState(() {
  //         isLoading = false;
  //         isError = true;
  //         error = kerrorString;
  //       });
  //     }
  //   } catch (e) {
  //     setState(() {
  //       isLoading = false;
  //       isError = true;
  //       error = e.toString();
  //     });
  //     log("GET PRE-ORDERS BY SKU API EXCEPTION >>---> ${e.toString()}");
  //   }
  // }
}
