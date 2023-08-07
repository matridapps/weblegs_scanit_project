import 'dart:convert';
import 'dart:developer';

import 'package:absolute_app/core/utils/constants.dart';
import 'package:absolute_app/core/utils/toast_utils.dart';
import 'package:absolute_app/core/utils/widgets.dart';
import 'package:absolute_app/models/get_pre_orders_response.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_search_bar/easy_search_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_pagination/flutter_web_pagination.dart';
import 'package:http/http.dart' as http;
import 'package:image_network/image_network.dart';
import 'package:rounded_loading_button/rounded_loading_button.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

class PreOrderScreenWeb extends StatefulWidget {
  const PreOrderScreenWeb({super.key});

  @override
  State<PreOrderScreenWeb> createState() => _PreOrderScreenWebState();
}

class _PreOrderScreenWebState extends State<PreOrderScreenWeb> {
  final RoundedLoadingButtonController createController =
      RoundedLoadingButtonController();

  List<SkuPreOrders> preOrdersList = [];
  List<SkuPreOrders> preOrdersListSKUSearched = [];
  List<SkuPreOrders> paginatedPreOrdersList = [];
  List<bool> checkBoxValueList = [];
  List<bool> checkBoxValueListSKUSearched = [];
  List<String> skuSuggestions = [];
  List<SelectedOrderModel> orderListToSent = [];

  bool isLoading = false;
  bool isError = false;
  bool isAllSelected = false;
  bool isAllSelectedSkuSearched = false;
  bool skuSearched = false;
  bool movingToNextOrPrev = false;

  String error = '';
  String searchValue = '';
  String searchValueOnTap = '';

  int pageNo = 1;
  int startIndex = 0;
  int endIndex = 9;

  @override
  void initState() {
    super.initState();
    preOrderInitCall();
  }

  void preOrderInitCall() async {
    await saveOrdersToSent(selectedOrderList: []).whenComplete(() async {
      await getAllPreOrders();
    });
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
              fontSize: 20,
              color: Colors.black,
            ),
            searchTextStyle: const TextStyle(
              fontSize: 20,
              color: Colors.black,
            ),
            suggestionTextStyle: const TextStyle(
              fontSize: 20,
              color: Colors.black,
            ),
            onSuggestionTap: (value) async {
              setState(() {
                searchValue = value;
                searchValueOnTap = value;
                skuSearched = true;
              });
              await getSavedOrdersToSent().whenComplete(() async {
                await getPreOrdersBySKU(sku: value);
              });
            },
            onSearch: (value) {
              setState(() {
                searchValue = value;
              });
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
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 20,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        skuSearched
                            ? _selectAllTabSkuSearched(size)
                            : _selectAllTab(size),
                        _createPicklistButton(size),
                        _skuSearchedText(size),
                        movingToNextOrPrev
                            ? SizedBox(
                                height: size.height * .5,
                                width: size.width,
                                child: const Center(
                                    child: CircularProgressIndicator(
                                  color: appColor,
                                )),
                              )
                            : Expanded(
                                child: ListView(
                                  children: [
                                    if (!skuSearched)
                                      ..._preOrdersListMaker(size),
                                    if (skuSearched)
                                      ..._preOrdersListMakerSKUSearched(size),
                                  ],
                                ),
                              )
                      ],
                    ),
                  ),
      ),
    );
  }

  /// BUILDER METHODS -

  /// SELECT ALL TAB
  Widget _selectAllTab(Size size) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Card(
        elevation: 2,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        child: SizedBox(
          height: 40,
          width: size.width,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Text(
                'Showing ${startIndex + 1} - ${endIndex + 1} of ${preOrdersList.length}',
                style: const TextStyle(fontSize: 20),
              ),
              WebPagination(
                  currentPage: pageNo,
                  totalPage: ((preOrdersList.length) / 10).ceil(),
                  displayItemCount: 4,
                  onPageChanged: (page) async {
                    setState(() {
                      pageNo = page;
                      startIndex = (pageNo - 1) * 10;
                    });
                    if (page == ((preOrdersList.length) / 10).ceil()) {
                      setState(() {
                        endIndex = preOrdersList.length - 1;
                      });
                    } else {
                      setState(() {
                        endIndex = (pageNo * 10) - 1;
                      });
                    }
                    log('V startIndex >>---> $startIndex');
                    log('V endIndex >>---> $endIndex');

                    setState(() {
                      movingToNextOrPrev = true;
                    });
                    paginatedPreOrdersList = [];
                    if (preOrdersList.length > 10) {
                      for (int i = startIndex; i <= endIndex; i++) {
                        paginatedPreOrdersList.add(preOrdersList[i]);
                      }
                      log('Paginated Case');
                    } else {
                      log('Non-Paginated Case');
                    }
                    await Future.delayed(const Duration(milliseconds: 700), () {
                      setState(() {
                        movingToNextOrPrev = false;
                      });
                    });
                  }),
              Row(
                children: [
                  const Text(
                    'Select All',
                    style: TextStyle(fontSize: 20),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: Checkbox(
                      value: isAllSelected,
                      activeColor: appColor,
                      onChanged: (bool? value) async {
                        setState(() {
                          isAllSelected = !isAllSelected;
                        });
                        log('V isAllSelected >>---> $isAllSelected');
                        if (isAllSelected == true) {
                          List<bool> temp = [];
                          for (int i = 0; i < checkBoxValueList.length; i++) {
                            temp.add(true);
                          }
                          checkBoxValueList = [];
                          checkBoxValueList.addAll(temp.map((e) => e));
                          List<SelectedOrderModel> tempList = [];
                          for(int i=0; i<preOrdersList.length; i++) {
                            tempList.add(SelectedOrderModel(orderNumber: preOrdersList[i].orderNumber, sku: preOrdersList[i].sku, orderType: preOrdersList[i].orderType,totalCount: preOrdersList[i].totalCount,),);
                          }
                          await saveOrdersToSent(selectedOrderList: tempList)
                              .whenComplete(() async {
                            await getSavedOrdersToSent();
                          });
                        } else {
                          List<bool> temp = [];
                          for (int i = 0; i < checkBoxValueList.length; i++) {
                            temp.add(false);
                          }
                          checkBoxValueList = [];
                          checkBoxValueList.addAll(temp.map((e) => e));
                          await saveOrdersToSent(selectedOrderList: [],).whenComplete(() async {
                            await getSavedOrdersToSent();
                          });
                        }
                      },
                    ),
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// SELECT ALL TAB WHEN SKU IS SEARCHED
  Widget _selectAllTabSkuSearched(Size size) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Card(
        elevation: 2,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        child: SizedBox(
          height: 40,
          width: size.width,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  const Text(
                    'Select All',
                    style: TextStyle(fontSize: 20),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: Checkbox(
                      value: isAllSelectedSkuSearched,
                      activeColor: appColor,
                      onChanged: (bool? value) async {
                        setState(() {
                          isAllSelectedSkuSearched = !isAllSelectedSkuSearched;
                        });
                        log('V isAllSelectedSkuSearched >>---> $isAllSelectedSkuSearched');
                        if (isAllSelectedSkuSearched == true) {
                          List<bool> temp = [];
                          for (int i = 0;
                              i < checkBoxValueListSKUSearched.length;
                              i++) {
                            temp.add(true);
                          }
                          checkBoxValueListSKUSearched = [];
                          checkBoxValueListSKUSearched
                              .addAll(temp.map((e) => e));
                          List<SelectedOrderModel> tempList = [];
                          for(int i=0; i<orderListToSent.length; i++) {
                            tempList.add(SelectedOrderModel(orderNumber: orderListToSent[i].orderNumber, sku: orderListToSent[i].sku, orderType: orderListToSent[i].orderType,totalCount: orderListToSent[i].totalCount,),);
                          }
                          for(int i=0; i<preOrdersListSKUSearched.length; i++) {
                            tempList.add(SelectedOrderModel(orderNumber: preOrdersListSKUSearched[i].orderNumber, sku: preOrdersListSKUSearched[i].sku, orderType: preOrdersListSKUSearched[i].orderType,totalCount: preOrdersListSKUSearched[i].totalCount,),);
                          }

                          await saveOrdersToSent(selectedOrderList: tempList,)
                              .whenComplete(() async {
                            await getSavedOrdersToSent();
                          });
                        } else {
                          List<bool> temp = [];
                          for (int i = 0;
                              i < checkBoxValueListSKUSearched.length;
                              i++) {
                            temp.add(false);
                          }
                          checkBoxValueListSKUSearched = [];
                          checkBoxValueListSKUSearched.addAll(temp.map((e) => e));
                          List<SelectedOrderModel> tempList = [];
                          for(int i=0; i<orderListToSent.length; i++) {
                            tempList.add(SelectedOrderModel(orderNumber: orderListToSent[i].orderNumber, sku: orderListToSent[i].sku, orderType: orderListToSent[i].orderType, totalCount: orderListToSent[i].totalCount,),);
                          }
                          for (int i = 0; i<preOrdersListSKUSearched.length; i++) {
                            tempList.removeWhere((e) => e.orderNumber == preOrdersListSKUSearched[i].orderNumber && e.sku == preOrdersListSKUSearched[i].sku);
                          }
                          await saveOrdersToSent(selectedOrderList: tempList,)
                              .whenComplete(() async {
                            await getSavedOrdersToSent();
                          });
                        }
                      },
                    ),
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Create Picklist Button
  Widget _createPicklistButton(Size size) {
    return Visibility(
      visible: orderListToSent.isNotEmpty,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: Card(
          elevation: 2,
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
          child: SizedBox(
            height: 50,
            width: size.width,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '${orderListToSent.length} Selected',
                  style: const TextStyle(
                    fontSize: 18,
                  ),
                ),
                RoundedLoadingButton(
                  color: Colors.green,
                  borderRadius: 10,
                  elevation: 10,
                  height: 50,
                  width: 200,
                  successIcon: Icons.check_rounded,
                  failedIcon: Icons.close_rounded,
                  successColor: Colors.green,
                  errorColor: appColor,
                  controller: createController,
                  onPressed: () async {
                    /// ACTUAL LIST WHICH WILL BE SENT FOR PICKLIST CREATION
                    List<SelectedOrderModel> tempMSMQWList = [];
                    /// THE LIST FROM WHICH NO ORDERS WILL BE DELETED AND
                    /// THUS WILL BE USED FOR INDEXING MANAGEMENT
                    List<SelectedOrderModel> tempMSMQWCheckList = [];
                    /// THE LIST IN WHICH ALL THE DELETED ORDERS WILL BE
                    /// STORED
                    List<SelectedOrderModel> tempMSMQWDeletedList = [];
                    await getSavedOrdersToSent().whenComplete(() async {
                      if(orderListToSent.any((e) => e.orderType == 'MSMQW')) {
                        tempMSMQWList.addAll(orderListToSent.where((e) => e.orderType == 'MSMQW').map((e) => e));
                        tempMSMQWCheckList.addAll(orderListToSent.where((e) => e.orderType == 'MSMQW').map((e) => e));
                        log('COUNT OF MSMQW ORDER/SKU SELECTED >>---> ${tempMSMQWCheckList.length}');

                        for(int i=0; i<tempMSMQWCheckList.length; i++) {
                          if(tempMSMQWCheckList.where((e) => e.orderNumber == tempMSMQWCheckList[i].orderNumber).length == parseToInt(tempMSMQWCheckList[i].totalCount)) {
                            log('MSMQW ORDER ${tempMSMQWCheckList[i].orderNumber} IS SELECTED WITH ALL SKUS');
                          } else {
                            tempMSMQWDeletedList.add(tempMSMQWCheckList[i]);
                            tempMSMQWList.removeWhere((e) => e.orderNumber == tempMSMQWCheckList[i].orderNumber && e.sku == tempMSMQWCheckList[i].sku);
                            log('NEW COUNT OF MSMQW ORDER/SKU TO SENT >>---> ${tempMSMQWList.length}');
                          }
                        }

                        List<String> listForToast = [];
                        listForToast.addAll(tempMSMQWDeletedList.map((e) => e.orderNumber).toSet().toList().map((e) => e));

                        if(tempMSMQWDeletedList.isNotEmpty) {
                          ToastUtils.motionToastCentered(message: '${listForToast.length > 1 ? 'Picklists' : 'Picklist'} for MSMQW ${listForToast.length > 1 ? 'Orders' : 'Order'} ${listForToast.join(',')} cannot be created as all Skus are not selected for ${listForToast.length > 1 ? 'them' : 'it'}', context: context,);
                        }
                      }

                      /// FIRST ALL MSMQW ORDERS ARE REMOVED
                      orderListToSent.removeWhere((e) => e.orderType == 'MSMQW');
                      if(tempMSMQWList.isNotEmpty) {
                        /// THEN IF THERE ARE MSMQW ORDERS WITH ALL SKUS SELECTED
                        /// IT WILL BE ADDED TO ORDER LIST TO SENT
                        orderListToSent.addAll(tempMSMQWList.map((e) => e));
                      }
                      if(orderListToSent.isNotEmpty) {
                        log('ORDERS SENT FOR PICKLIST CREATION >>--> ${orderListToSent.map((e) => e.orderNumber).toSet().toList().join(',')}');
                        await createPicklistForSelectedOrders(
                          selectedOrders: orderListToSent.map((e) => e.orderNumber).toSet().toList().join(','),
                          isPartiallySelectedMSMQWOrder: tempMSMQWDeletedList.isNotEmpty,
                        );
                      }
                    }).whenComplete(() async {
                      setState(() {
                        skuSearched = false;
                      });
                      await Future.delayed(const Duration(seconds: 1), () async {
                        await saveOrdersToSent(selectedOrderList: tempMSMQWDeletedList).whenComplete(() async {
                          await getSavedOrdersToSent();
                        }).whenComplete(() async {
                          await getAllPreOrders();
                        });
                      });
                    }).whenComplete(() => createController.reset());
                  },
                  child: const Text(
                    'Create Picklist',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    setState(() {
                      skuSearched = false;
                    });
                    await saveOrdersToSent(selectedOrderList: []).whenComplete(() async {
                      await getSavedOrdersToSent();
                    }).whenComplete(() async {
                      await getAllPreOrders();
                    });
                  },
                  child: const Text(
                    'Clear Selection',
                    style: TextStyle(
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// SKU Searched Text Builder
  Widget _skuSearchedText(Size size) {
    return Visibility(
      visible: skuSearched,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: Card(
          elevation: 2,
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
          child: SizedBox(
            height: 40,
            width: size.width,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text(
                  'Showing Results for $searchValueOnTap',
                  style: const TextStyle(
                    fontSize: 18,
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    setState(() {
                      skuSearched = false;
                    });
                    await getSavedOrdersToSent().whenComplete(() async {
                      await getAllPreOrders();
                    });
                  },
                  child: const Text(
                    'Go to All Pre-Orders',
                    style: TextStyle(
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// LIST GENERATOR FOR PRE-ORDERS WHEN SCREEN FIRST OPENED
  List<Widget> _preOrdersListMaker(Size size) {
    return List.generate(
      countToShowInPreOrdersListMaker(),
      (index) => GestureDetector(
        onTap: () async => onTapPreOrdersListMaker(index),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Card(
            elevation: 2,
            color: checkBoxValueList[indexForCheckList(index, pageNo)] == true
                ? preOrderColor
                : Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          orderListChooser()[index].title,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                          style: const TextStyle(
                            fontSize: 20,
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: SizedBox(
                      height: 220,
                      width: size.width,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: 220,
                            width: 220,
                            child: Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5),
                              ),
                              elevation: 5,
                              child: Center(
                                child: orderListChooser()[index]
                                        .imageUrl
                                        .isEmpty
                                    ? Image.asset(
                                        'assets/no_image/no_image.png',
                                        height: 215,
                                        width: 215,
                                        fit: BoxFit.contain,
                                      )
                                    : ImageNetwork(
                                        image:
                                            orderListChooser()[index].imageUrl,
                                        imageCache: CachedNetworkImageProvider(
                                          orderListChooser()[index].imageUrl,
                                        ),
                                        height: 215,
                                        width: 215,
                                        duration: 100,
                                        fitWeb: BoxFitWeb.contain,
                                        onLoading: Shimmer(
                                          duration: const Duration(seconds: 1),
                                          interval: const Duration(seconds: 2),
                                          color: Colors.white,
                                          colorOpacity: 1,
                                          enabled: true,
                                          direction:
                                              const ShimmerDirection.fromLTRB(),
                                          child: Container(
                                            color: const Color.fromARGB(
                                                160, 192, 192, 192),
                                          ),
                                        ),
                                        onError: Image.asset(
                                          'assets/no_image/no_image.png',
                                          height: 215,
                                          width: 215,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 50),
                            child: SizedBox(
                              height: 220,
                              width: size.width - 370,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  const Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Order Number ',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                      Text(
                                        'SKU ',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                      Text(
                                        'Quantity ',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                      Text(
                                        'Order Date ',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                      Text(
                                        'Order Type ',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                      Flexible(
                                        child: Text(
                                          'Warehouse Location ',
                                          overflow: TextOverflow.visible,
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        orderListChooser()[index].orderNumber,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          color: Colors.black,
                                        ),
                                      ),
                                      Text(
                                        orderListChooser()[index].sku,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          color: Colors.black,
                                        ),
                                      ),
                                      Text(
                                        orderListChooser()[index].quantity,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          color: Colors.black,
                                        ),
                                      ),
                                      Flexible(
                                        child: Text(
                                          orderListChooser()[index].orderDate,
                                          overflow: TextOverflow.visible,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        orderListChooser()[index].orderType,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Flexible(
                                        child: Text(
                                          orderListChooser()[index]
                                              .warehouseLocation,
                                          overflow: TextOverflow.visible,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Expanded(
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        SizedBox(
                                          height: 220,
                                          width: 50,
                                          child: Center(
                                            child: Checkbox(
                                              activeColor: appColor,
                                              value: checkBoxValueList[
                                                  indexForCheckList(
                                                      index, pageNo)],
                                              onChanged: (_) async =>
                                                  onTapPreOrdersListMaker(
                                                      index),
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
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// LIST GENERATOR WHEN SKU IS SEARCHED.
  List<Widget> _preOrdersListMakerSKUSearched(Size size) {
    return List.generate(
      preOrdersListSKUSearched.length,
      (index) => GestureDetector(
        onTap: () async => onTapPreOrdersListMakerSKUSearched(index),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Card(
            elevation: 2,
            color: checkBoxValueListSKUSearched[index] == true
                ? preOrderColor
                : Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          preOrdersListSKUSearched[index].title,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                          style: const TextStyle(
                            fontSize: 20,
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: SizedBox(
                      height: 220,
                      width: size.width,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: 220,
                            width: 220,
                            child: Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5),
                              ),
                              elevation: 5,
                              child: Center(
                                child: preOrdersListSKUSearched[index]
                                        .imageUrl
                                        .isEmpty
                                    ? Image.asset(
                                        'assets/no_image/no_image.png',
                                        height: 215,
                                        width: 215,
                                        fit: BoxFit.contain,
                                      )
                                    : ImageNetwork(
                                        image: preOrdersListSKUSearched[index]
                                            .imageUrl,
                                        imageCache: CachedNetworkImageProvider(
                                          preOrdersListSKUSearched[index]
                                              .imageUrl,
                                        ),
                                        height: 215,
                                        width: 215,
                                        duration: 100,
                                        fitWeb: BoxFitWeb.contain,
                                        onLoading: Shimmer(
                                          duration: const Duration(seconds: 1),
                                          interval: const Duration(seconds: 2),
                                          color: Colors.white,
                                          colorOpacity: 1,
                                          enabled: true,
                                          direction:
                                              const ShimmerDirection.fromLTRB(),
                                          child: Container(
                                            color: const Color.fromARGB(
                                                160, 192, 192, 192),
                                          ),
                                        ),
                                        onError: Image.asset(
                                          'assets/no_image/no_image.png',
                                          height: 215,
                                          width: 215,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 50),
                            child: SizedBox(
                              height: 220,
                              width: size.width - 370,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  const Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Order Number ',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                      Text(
                                        'SKU ',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                      Text(
                                        'Quantity ',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                      Text(
                                        'Order Date ',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                      Text(
                                        'Order Type ',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                      Flexible(
                                        child: Text(
                                          'Warehouse Location ',
                                          overflow: TextOverflow.visible,
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        preOrdersListSKUSearched[index]
                                            .orderNumber,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          color: Colors.black,
                                        ),
                                      ),
                                      Text(
                                        preOrdersListSKUSearched[index].sku,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          color: Colors.black,
                                        ),
                                      ),
                                      Text(
                                        preOrdersListSKUSearched[index]
                                            .quantity,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          color: Colors.black,
                                        ),
                                      ),
                                      Flexible(
                                        child: Text(
                                          preOrdersListSKUSearched[index]
                                              .orderDate,
                                          overflow: TextOverflow.visible,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        preOrdersListSKUSearched[index].orderType,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Flexible(
                                        child: Text(
                                          preOrdersListSKUSearched[index]
                                              .warehouseLocation,
                                          overflow: TextOverflow.visible,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Expanded(
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        SizedBox(
                                          height: 220,
                                          width: 50,
                                          child: Center(
                                            child: Checkbox(
                                              activeColor: appColor,
                                              value:
                                                  checkBoxValueListSKUSearched[
                                                      index],
                                              onChanged: (_) async =>
                                                  onTapPreOrdersListMakerSKUSearched(
                                                      index),
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
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<SkuPreOrders> orderListChooser() {
    return preOrdersList.isEmpty
        ? []
        : preOrdersList.length > 10
            ? paginatedPreOrdersList
            : preOrdersList;
  }

  int countToShowInPreOrdersListMaker() {
    return preOrdersList.isEmpty
        ? 0
        : preOrdersList.length > 10
            ? endIndex == preOrdersList.length - 1
                ? preOrdersList.length % 10
                : 10
            : preOrdersList.length;
  }

  int indexForCheckList(int index, int pageNo) {
    return orderListChooser() == paginatedPreOrdersList
        ? index + ((pageNo - 1) * 10)
        : index;
  }

  void onTapPreOrdersListMaker(int index) async {
    setState(() {
      checkBoxValueList[indexForCheckList(index, pageNo)] =
          !(checkBoxValueList[indexForCheckList(index, pageNo)]);
    });
    log('V checkBoxValueList At ${indexForCheckList(index, pageNo)} >>---> ${checkBoxValueList[indexForCheckList(index, pageNo)]}');
    if (checkBoxValueList.every((e) => e == true)) {
      setState(() {
        isAllSelected = true;
      });
    } else {
      setState(() {
        isAllSelected = false;
      });
    }
    List<SelectedOrderModel> tempList = [];
    for(int i=0; i<orderListToSent.length; i++) {
      tempList.add(SelectedOrderModel(orderNumber: orderListToSent[i].orderNumber, sku: orderListToSent[i].sku, orderType: orderListToSent[i].orderType, totalCount: orderListToSent[i].totalCount,),);
    }
    if (checkBoxValueList[indexForCheckList(index, pageNo)] == true) {
      if(preOrdersList[indexForCheckList(index, pageNo)].orderType == 'MSMQW') {
        if (tempList.map((e) => e.orderNumber).toList().contains(preOrdersList[indexForCheckList(index, pageNo)].orderNumber) == true) {
          if(tempList.where((e) => e.orderNumber == preOrdersList[indexForCheckList(index, pageNo)].orderNumber).map((e) => e.sku).toList().contains(preOrdersList[indexForCheckList(index, pageNo)].sku) == false) {
            tempList.add(SelectedOrderModel(orderNumber: preOrdersList[indexForCheckList(index, pageNo)].orderNumber, sku: preOrdersList[indexForCheckList(index, pageNo)].sku, orderType: 'MSMQW', totalCount: preOrdersList[indexForCheckList(index, pageNo)].totalCount,),);
          }
        } else {
          tempList.add(SelectedOrderModel(orderNumber: preOrdersList[indexForCheckList(index, pageNo)].orderNumber, sku: preOrdersList[indexForCheckList(index, pageNo)].sku, orderType: 'MSMQW', totalCount: preOrdersList[indexForCheckList(index, pageNo)].totalCount,),);
        }
      } else {
        if (tempList.map((e) => e.orderNumber).toList().contains(preOrdersList[indexForCheckList(index, pageNo)].orderNumber) == false) {
          tempList.add(SelectedOrderModel(orderNumber: preOrdersList[indexForCheckList(index, pageNo)].orderNumber, sku: preOrdersList[indexForCheckList(index, pageNo)].sku, orderType: preOrdersList[indexForCheckList(index, pageNo)].orderType,totalCount: '1',),);
        }
      }
    } else {
      if(preOrdersList[indexForCheckList(index, pageNo)].orderType == 'MSMQW') {
        if (tempList.map((e) => e.orderNumber).toList().contains(preOrdersList[indexForCheckList(index, pageNo)].orderNumber) == true) {
          if(tempList.where((e) => e.orderNumber == preOrdersList[indexForCheckList(index, pageNo)].orderNumber).map((e) => e.sku).toList().contains(preOrdersList[indexForCheckList(index, pageNo)].sku) == true) {
            tempList.removeWhere((e) => e.orderNumber == preOrdersList[indexForCheckList(index, pageNo)].orderNumber && e.sku == preOrdersList[indexForCheckList(index, pageNo)].sku);
          }
        }
      } else {
        if (tempList.map((e) => e.orderNumber).toList().contains(preOrdersList[indexForCheckList(index, pageNo)].orderNumber) == true) {
          tempList.removeWhere((e) => e.orderNumber == preOrdersList[indexForCheckList(index, pageNo)].orderNumber);
        }
      }
    }
    await saveOrdersToSent(selectedOrderList: tempList).whenComplete(() async {
      await getSavedOrdersToSent();
    });
  }

  void onTapPreOrdersListMakerSKUSearched(int index) async {
    setState(() {
      checkBoxValueListSKUSearched[index] =
          !(checkBoxValueListSKUSearched[index]);
    });
    log('V checkBoxValueListSKUSearched At $index >>---> ${checkBoxValueListSKUSearched[index]}');
    if (checkBoxValueListSKUSearched.every((e) => e == true)) {
      setState(() {
        isAllSelectedSkuSearched = true;
      });
    } else {
      setState(() {
        isAllSelectedSkuSearched = false;
      });
    }
    List<SelectedOrderModel> tempList = [];
    for(int i=0; i<orderListToSent.length; i++) {
      tempList.add(SelectedOrderModel(orderNumber: orderListToSent[i].orderNumber, sku: orderListToSent[i].sku, orderType: orderListToSent[i].orderType, totalCount: orderListToSent[i].totalCount),);
    }
    if (checkBoxValueListSKUSearched[index] == true) {
      if(preOrdersListSKUSearched[index].orderType == 'MSMQW') {
        if (tempList.map((e) => e.orderNumber).toList().contains(preOrdersListSKUSearched[index].orderNumber) == true) {
          if(tempList.where((e) => e.orderNumber == preOrdersListSKUSearched[index].orderNumber).map((e) => e.sku).toList().contains(preOrdersListSKUSearched[index].sku) == false) {
            tempList.add(SelectedOrderModel(orderNumber: preOrdersListSKUSearched[index].orderNumber, sku: preOrdersListSKUSearched[index].sku, orderType: 'MSMQW', totalCount: preOrdersListSKUSearched[index].totalCount,));
          }
        } else {
          tempList.add(SelectedOrderModel(orderNumber: preOrdersListSKUSearched[index].orderNumber, sku: preOrdersListSKUSearched[index].sku, orderType: 'MSMQW', totalCount: preOrdersListSKUSearched[index].totalCount,));
        }
      } else {
        if (tempList.map((e) => e.orderNumber).toList().contains(preOrdersListSKUSearched[index].orderNumber) == false) {
          tempList.add(SelectedOrderModel(orderNumber: preOrdersListSKUSearched[index].orderNumber, sku: preOrdersListSKUSearched[index].sku, orderType: preOrdersListSKUSearched[index].orderType,totalCount: '1',));
        }
      }
    } else {
      if(preOrdersListSKUSearched[index].orderType == 'MSMQW') {
        if (tempList.map((e) => e.orderNumber).toList().contains(preOrdersListSKUSearched[index].orderNumber) == true) {
          if(tempList.where((e) => e.orderNumber == preOrdersListSKUSearched[index].orderNumber).map((e) => e.sku).toList().contains(preOrdersListSKUSearched[index].sku) == true) {
            tempList.removeWhere((e) => e.orderNumber == preOrdersListSKUSearched[index].orderNumber && e.sku == preOrdersListSKUSearched[index].sku);
          }
        }
      } else {
        if (tempList.map((e) => e.orderNumber).toList().contains(preOrdersListSKUSearched[index].orderNumber) == true) {
          tempList.removeWhere((e) => e.orderNumber == preOrdersListSKUSearched[index].orderNumber);
        }
      }
    }
    await saveOrdersToSent(selectedOrderList: tempList).whenComplete(() async {
      await getSavedOrdersToSent();
    });
  }

  /// API METHODS -

  /// THIS API IS FOR FETCHING SKU SEARCH SUGGESTIONS
  Future<List<String>> _fetchSuggestions(String searchValue) async {
    await Future.delayed(const Duration(milliseconds: 500));

    return skuSuggestions.where((element) {
      return element.toLowerCase().contains(searchValue.toLowerCase());
    }).toList();
  }

  /// THIS API IS USED FOR FETCHING THE SAVED LIST OF SELECTED ORDERS FOR
  /// PICKLIST CREATION
  Future<void> getSavedOrdersToSent() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String encodedData = prefs.getString('order_list_for_picklist_creation') ?? '';

    orderListToSent = [];
    if (encodedData.isNotEmpty) {
      orderListToSent = SelectedOrderModel.decode(encodedData);
    }
    log('getSavedOrdersToSent order length >>---> ${orderListToSent.length}');
  }

  /// THIS API IS USED FOR SAVING THE LIST OF SELECTED ORDERS FOR PICKLIST
  /// CREATION
  Future<void> saveOrdersToSent({required List<SelectedOrderModel> selectedOrderList,}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final String encodedData = SelectedOrderModel.encode(selectedOrderList);
    prefs.setString('order_list_for_picklist_creation', encodedData);
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
          ToastUtils.motionToastCentered1500MS(
              message: kTimeOut, context: context);
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
          log('ORDER COUNT >>---> ${preOrdersList.length}');

          checkBoxValueList = [];
          checkBoxValueList.addAll(preOrdersList.map((e) => false));
          log('V checkBoxValueList >>---> $checkBoxValueList');
          log('CHECK BOX VALUE LIST LENGTH >>---> ${checkBoxValueList.length}');

          if (orderListToSent.isNotEmpty) {
            for (int i = 0; i < orderListToSent.length; i++) {
              setState(() {
                checkBoxValueList[preOrdersList.indexWhere((e) => e.orderNumber == orderListToSent[i].orderNumber && e.sku == orderListToSent[i].sku)] = true;
              });
            }
          }

          if (checkBoxValueList.every((e) => e == true)) {
            setState(() {
              isAllSelected = true;
            });
          } else {
            setState(() {
              isAllSelected = false;
            });
          }

          skuSuggestions = [];
          List<String> tempListForSKUSuggestions = [];
          tempListForSKUSuggestions.addAll(preOrdersList.map((e) => e.sku));
          skuSuggestions
              .addAll(tempListForSKUSuggestions.toSet().toList().map((e) => e));
          log('V tempListForSKUSuggestions >>---> $tempListForSKUSuggestions');
          log('V skuSuggestions >>---> $skuSuggestions');

          paginatedPreOrdersList = [];
          if (preOrdersList.length > 10) {
            for (int i = startIndex; i <= endIndex; i++) {
              paginatedPreOrdersList.add(preOrdersList[i]);
            }
            log('Paginated Case');
          } else {
            log('Non-Paginated Case');
          }

          setState(() {
            isLoading = false;
            isError = false;
            error = '';
          });
        }
      } else {
        if (!mounted) return;
        ToastUtils.motionToastCentered1500MS(
            message: kerrorString, context: context);
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
      ToastUtils.motionToastCentered1500MS(
          message: e.toString(), context: context);
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
          ToastUtils.motionToastCentered1500MS(
              message: kTimeOut, context: context);
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
          preOrdersListSKUSearched = [];
          preOrdersListSKUSearched
              .addAll(getPreOrdersResponse.sku.map((e) => e));
          log('V preOrdersListSKUSearched >>---> ${jsonEncode(preOrdersListSKUSearched)}');

          checkBoxValueListSKUSearched = [];
          checkBoxValueListSKUSearched
              .addAll(preOrdersListSKUSearched.map((e) => false));
          log('V checkBoxValueListSKUSearched >>---> $checkBoxValueListSKUSearched');

          if (orderListToSent.isNotEmpty) {
            for (int i = 0; i < preOrdersListSKUSearched.length; i++) {
              if (orderListToSent.map((e) => e.orderNumber).toList().contains(preOrdersListSKUSearched[i].orderNumber)) {
                if(orderListToSent[orderListToSent.indexWhere((e) => e.orderNumber == preOrdersListSKUSearched[i].orderNumber)].sku == preOrdersListSKUSearched[i].sku) {
                  setState(() {
                    checkBoxValueListSKUSearched[i] = true;
                  });
                }
              }
            }
          }

          if (checkBoxValueListSKUSearched.every((e) => e == true)) {
            setState(() {
              isAllSelectedSkuSearched = true;
            });
          } else {
            setState(() {
              isAllSelectedSkuSearched = false;
            });
          }

          setState(() {
            isLoading = false;
            isError = false;
            error = '';
          });
        }
      } else {
        if (!mounted) return;
        ToastUtils.motionToastCentered1500MS(
            message: kerrorString, context: context);
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
      ToastUtils.motionToastCentered1500MS(
          message: e.toString(), context: context);
      log("GET PRE-ORDERS BY SKU API EXCEPTION >>---> ${e.toString()}");
    }
  }

  /// THIS API IS TO BE USED FOR CREATING PICKLIST FOR SELECTED ORDERS
  Future<void> createPicklistForSelectedOrders({
    required String selectedOrders,
    required bool isPartiallySelectedMSMQWOrder
  }) async {
    setState(() {
      error = '';
      isLoading = true;
      isError = false;
    });
    String uri =
        'https://weblegs.info/JadlamApp/api/CreatingPicklistOutOfPreOrders?OrderNumbers=$selectedOrders';
    log('CREATE PICKLIST FOR SELECTED ORDERS API URI >>---> $uri');

    try {
      var response = await http.get(Uri.parse(uri)).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          ToastUtils.motionToastBottom(
              message: kTimeOut, context: context);
          setState(() {
            isLoading = false;
            isError = true;
            error = kTimeOut;
          });
          return http.Response('Error', 408);
        },
      );
      log('CREATE PICKLIST FOR SELECTED ORDERS API STATUS CODE >>---> ${response.statusCode}');
      if (response.statusCode == 200) {
        log('CREATE PICKLIST FOR SELECTED ORDERS API RESPONSE >>---> ${jsonDecode(response.body)}');
        if (!mounted) return;
        if(!isPartiallySelectedMSMQWOrder) {
          ToastUtils.motionToastCentered1500MS(
            message: jsonDecode(response.body)['message'].toString(),
            context: context,
          );
        }
        setState(() {
          isLoading = true;
          isError = false;
          error = '';
        });
      } else {
        if (!mounted) return;
        ToastUtils.motionToastBottom(
            message: kerrorString, context: context);
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
      ToastUtils.motionToastBottom(
          message: e.toString(), context: context);
      log("CREATE PICKLIST FOR SELECTED ORDERS API EXCEPTION >>---> ${e.toString()}");
    }
  }
}

class SelectedOrderModel {
  final String orderNumber;
  final String sku;
  final String orderType;
  final String totalCount;

  SelectedOrderModel({
    required this.orderNumber,
    required this.sku,
    required this.orderType,
    required this.totalCount,
  });

  factory SelectedOrderModel.fromJson(Map<String, dynamic> jsonData) {
    return SelectedOrderModel(
      orderNumber: jsonData['OrderNumber'] ?? '',
      sku: jsonData['Sku'] ?? '',
      orderType: jsonData['OrderType'] ?? '',
      totalCount: jsonData['TotalCount'] ?? '',
    );
  }

  static Map<String, dynamic> toMap(SelectedOrderModel selectedOrderModel) {
    return {
      'OrderNumber': selectedOrderModel.orderNumber,
      'Sku': selectedOrderModel.sku,
      'OrderType': selectedOrderModel.orderType,
      'TotalCount': selectedOrderModel.totalCount,
    };
  }

  static String encode(List<SelectedOrderModel> selectedOrderModels) {
    return json.encode(
      selectedOrderModels
          .map<Map<String, dynamic>>((value) => SelectedOrderModel.toMap(value))
          .toList(),
    );
  }

  static List<SelectedOrderModel> decode(String selectedOrderModels) {
    return (json.decode(selectedOrderModels) as List<dynamic>)
        .map<SelectedOrderModel>((item) => SelectedOrderModel.fromJson(item))
        .toList();
  }
}
