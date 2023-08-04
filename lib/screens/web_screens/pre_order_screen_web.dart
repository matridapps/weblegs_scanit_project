import 'dart:convert';
import 'dart:developer';

import 'package:absolute_app/core/utils/constants.dart';
import 'package:absolute_app/core/utils/toast_utils.dart';
import 'package:absolute_app/models/get_pre_orders_response.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_search_bar/easy_search_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_pagination/flutter_web_pagination.dart';
import 'package:http/http.dart' as http;
import 'package:image_network/image_network.dart';
import 'package:rounded_loading_button/rounded_loading_button.dart';
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
              await getPreOrdersBySKU(sku: value);
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
                      onChanged: (bool? value) {
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
                          log('ALL SELECTED >>---> ${checkBoxValueList.every((e) => e == true) ? 'Yes' : 'No'}');
                          log('COUNT OF SELECTED >>---> ${checkBoxValueList.where((e) => e == true).length}');
                        } else {
                          List<bool> temp = [];
                          for (int i = 0; i < checkBoxValueList.length; i++) {
                            temp.add(false);
                          }
                          checkBoxValueList = [];
                          checkBoxValueList.addAll(temp.map((e) => e));
                          log('ALL DE-SELECTED >>---> ${checkBoxValueList.every((e) => e == false) ? 'Yes' : 'No'}');
                          log('COUNT OF DE-SELECTED >>---> ${checkBoxValueList.where((e) => e == false).length}');
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
                      onChanged: (bool? value) {
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
                          log('ALL SELECTED SKU SEARCHED >>---> ${checkBoxValueListSKUSearched.every((e) => e == true) ? 'Yes' : 'No'}');
                          log('COUNT OF SELECTED SKU SEARCHED >>---> ${checkBoxValueListSKUSearched.where((e) => e == true).length}');
                        } else {
                          List<bool> temp = [];
                          for (int i = 0;
                              i < checkBoxValueListSKUSearched.length;
                              i++) {
                            temp.add(false);
                          }
                          checkBoxValueListSKUSearched = [];
                          checkBoxValueListSKUSearched
                              .addAll(temp.map((e) => e));
                          log('ALL DE-SELECTED SKU SEARCHED >>---> ${checkBoxValueListSKUSearched.every((e) => e == false) ? 'Yes' : 'No'}');
                          log('COUNT OF DE-SELECTED SKU SEARCHED >>---> ${checkBoxValueListSKUSearched.where((e) => e == false).length}');
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
      visible: checkBoxValueList.any((e) => e == true),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: SizedBox(
          width: size.width,
          child: Center(
            child: RoundedLoadingButton(
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

  /// SKU Searched Text Builder
  Widget _skuSearchedText(Size size) {
    return Visibility(
      visible: skuSearched,
      child: SizedBox(
        height: 50,
        width: size.width,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Showing Results for $searchValueOnTap',
              style: const TextStyle(
                fontSize: 18,
              ),
            ),
            IconButton(
              onPressed: () {
                setState(() {
                  skuSearched = false;
                });
              },
              icon: const Icon(Icons.close),
            ),
          ],
        ),
      ),
    );
  }

  /// LIST GENERATOR FOR PRE-ORDERS WHEN SCREEN FIRST OPENED
  List<Widget> _preOrdersListMaker(Size size) {
    return List.generate(
      countToShowInPreOrdersListMaker(),
      (index) => GestureDetector(
        onTap: () {
          setState(() {
            checkBoxValueList[index] = !(checkBoxValueList[index]);
          });
          log('V checkBoxValueList At $index >>---> ${checkBoxValueList[index]}');
          if (checkBoxValueList.every((e) => e == true)) {
            setState(() {
              isAllSelected = true;
            });
          } else {
            setState(() {
              isAllSelected = false;
            });
          }
        },
        child: Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Card(
            elevation: 2,
            color:
                checkBoxValueList[index] == true ? preOrderColor : Colors.white,
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
                      height: 200,
                      width: size.width,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: 200,
                            width: 200,
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
                                        height: 195,
                                        width: 195,
                                        fit: BoxFit.contain,
                                      )
                                    : ImageNetwork(
                                        image:
                                            orderListChooser()[index].imageUrl,
                                        imageCache: CachedNetworkImageProvider(
                                          orderListChooser()[index].imageUrl,
                                        ),
                                        height: 195,
                                        width: 195,
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
                                          height: 195,
                                          width: 195,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 50),
                            child: SizedBox(
                              height: 200,
                              width: size.width - 350,
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
                                          height: 200,
                                          width: 50,
                                          child: Center(
                                            child: Checkbox(
                                              activeColor: appColor,
                                              value: checkBoxValueList[index],
                                              onChanged: (bool? newValue) {
                                                setState(() {
                                                  checkBoxValueList[index] =
                                                      !(checkBoxValueList[
                                                          index]);
                                                });
                                                log('V checkBoxValueList At $index >>---> ${checkBoxValueList[index]}');
                                                if (checkBoxValueList
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
        onTap: () {
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
        },
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
                      height: 200,
                      width: size.width,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: 200,
                            width: 200,
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
                                        height: 195,
                                        width: 195,
                                        fit: BoxFit.contain,
                                      )
                                    : ImageNetwork(
                                        image: preOrdersListSKUSearched[index]
                                            .imageUrl,
                                        imageCache: CachedNetworkImageProvider(
                                          preOrdersListSKUSearched[index]
                                              .imageUrl,
                                        ),
                                        height: 195,
                                        width: 195,
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
                                          height: 195,
                                          width: 195,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 50),
                            child: SizedBox(
                              height: 200,
                              width: size.width - 350,
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
                                          height: 200,
                                          width: 50,
                                          child: Center(
                                            child: Checkbox(
                                              activeColor: appColor,
                                              value:
                                                  checkBoxValueListSKUSearched[
                                                      index],
                                              onChanged: (bool? newValue) {
                                                setState(() {
                                                  checkBoxValueListSKUSearched[
                                                          index] =
                                                      !(checkBoxValueListSKUSearched[
                                                          index]);
                                                });
                                                log('V checkBoxValueListSKUSearched At $index >>---> ${checkBoxValueListSKUSearched[index]}');
                                                if (checkBoxValueListSKUSearched
                                                    .every((e) => e == true)) {
                                                  setState(() {
                                                    isAllSelectedSkuSearched =
                                                        true;
                                                  });
                                                } else {
                                                  setState(() {
                                                    isAllSelectedSkuSearched =
                                                        false;
                                                  });
                                                }
                                              },
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

  /// API METHODS -

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
          log('ORDER COUNT >>---> ${preOrdersList.length}');

          checkBoxValueList = [];
          checkBoxValueList.addAll(preOrdersList.map((e) => false));
          log('V checkBoxValueList >>---> $checkBoxValueList');

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
          preOrdersListSKUSearched = [];
          preOrdersListSKUSearched
              .addAll(getPreOrdersResponse.sku.map((e) => e));
          log('V preOrdersListSKUSearched >>---> ${jsonEncode(preOrdersListSKUSearched)}');

          checkBoxValueListSKUSearched = [];
          checkBoxValueListSKUSearched
              .addAll(preOrdersListSKUSearched.map((e) => false));
          log('V checkBoxValueListSKUSearched >>---> $checkBoxValueListSKUSearched');

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
}
