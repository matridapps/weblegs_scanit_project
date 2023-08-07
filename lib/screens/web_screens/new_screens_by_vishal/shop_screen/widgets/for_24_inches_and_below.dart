// ignore_for_file: camel_case_types

import 'package:absolute_app/core/utils/app_export.dart';
import 'package:absolute_app/core/utils/constants.dart';
import 'package:absolute_app/models/shop_replinsh_model.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_network/image_network.dart';
import 'package:modal_side_sheet/modal_side_sheet.dart';
import 'package:rounded_loading_button/rounded_loading_button.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

import 'image_view_for_web.dart';
import 'scanner_web_shop.dart';

// ignore: must_be_immutable
class ShopScreenForWeb extends StatefulWidget {
  ShopScreenForWeb(
      {super.key,
      required this.data,
      required this.constraints,
      required this.scanProducts});

  final List<ShopReplenishSku> data;
  final BoxConstraints constraints;
  List<ScanProductModel> scanProducts;

  @override
  State<ShopScreenForWeb> createState() => _ShopScreenForWebState();
}

class _ShopScreenForWebState extends State<ShopScreenForWeb> {
  final RoundedLoadingButtonController createController =
      RoundedLoadingButtonController();

  final ScrollController controller = ScrollController();

  bool _isProductScan({required ShopReplenishSku itemFromMainList}) {
    return widget.scanProducts
        .where((element) => element.productEAN == itemFromMainList.ean)
        .isNotEmpty;
  }

  int _returningQuantity(
      {required int orignalQuantity, required int numberOfTimeProductScan}) {
    return (orignalQuantity - numberOfTimeProductScan) <= 0
        ? 0
        : orignalQuantity - numberOfTimeProductScan;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // bottomNavigationBar: ,
      body: Scrollbar(
        controller: controller,
        trackVisibility: true,
        thumbVisibility: true,
        thickness: 6,
        child: AnimatedSwitcher(
          duration: const Duration(seconds: 1),
          child: widget.constraints.maxWidth < 994
              ? widget.constraints.maxWidth > 800
                  ? SingleChildScrollView(
                      controller: controller,
                      child: Column(
                        children: [
                          Padding(
                            padding: EdgeInsets.symmetric(
                                vertical: 8.0,
                                horizontal:
                                    MediaQuery.of(context).size.width / 4),
                            child: ScannerWebForShop(
                              scanProducts: widget.scanProducts,
                              orignalProducts: widget.data,
                              focusNode: FocusNode(),
                            ),
                          ),
                          _paginationButtons(),
                          ..._preOrdersListMaker(
                            Size(
                              widget.constraints.maxWidth,
                              widget.constraints.maxHeight,
                            ),
                          )
                        ],
                      ),
                    )
                  : SizedBox(
                      width: widget.constraints.maxWidth,
                      child: SingleChildScrollView(
                        child: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            alignment: WrapAlignment.center,
                            // spacing:5,
                            children: [
                              Padding(
                                padding: EdgeInsets.symmetric(
                                    vertical: 8.0,
                                    horizontal:
                                        MediaQuery.of(context).size.width / 4),
                                child: ScannerWebForShop(
                                  scanProducts: widget.scanProducts,
                                  orignalProducts: widget.data,
                                  focusNode: FocusNode(),
                                ),
                              ),
                              _paginationButtons(),
                              ..._forMobileTypeView(
                                width: 600,
                                height: widget.constraints.maxHeight,
                              )
                            ]),
                      ),
                    )
              : SingleChildScrollView(
                  controller: controller,
                  child: Wrap(
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(
                            vertical: 8.0,
                            horizontal: MediaQuery.of(context).size.width / 4),
                        child: ScannerWebForShop(
                          scanProducts: widget.scanProducts,
                          orignalProducts: widget.data,
                          focusNode: FocusNode(),
                        ),
                      ),
                      _paginationButtons(),
                      ..._forGridView(
                        width: widget.constraints.maxWidth,
                        height: widget.constraints.maxHeight,
                      )
                    ],
                  ),
                ),
        ),

        // ListView(
        //   controller: controller,
        //   shrinkWrap: true,
        //   physics: const AlwaysScrollableScrollPhysics(),
        //   children: [
        //     const SizedBox(
        //       height: 10,
        //     ),
        //     Padding(
        //       padding: const EdgeInsets.only(bottom: 5),
        //       child: SizedBox(
        //         width: MediaQuery.of(context).size.width,
        //         child: Center(
        //           child: RoundedLoadingButton(
        //             color: Colors.green,
        //             borderRadius: 10,
        //             elevation: 10,
        //             height: 50,
        //             width: 200,
        //             successIcon: Icons.check_rounded,
        //             failedIcon: Icons.close_rounded,
        //             successColor: Colors.green,
        //             errorColor: appColor,
        //             controller: createController,
        //             onPressed: () async {
        //               await Future.delayed(const Duration(seconds: 1), () {
        //                 createController.reset();
        //               });
        //             },
        //             child: const Text(
        //               'Create Picklist',
        //               style: TextStyle(
        //                 fontSize: 18,
        //                 color: Colors.white,
        //               ),
        //             ),
        //           ),
        //         ),
        //       ),
        //     ),
        //
        //   ],
        // ),
      ),
    );
  }

  List<Widget> _preOrdersListMaker(
    Size size,
  ) {
    return List.generate(
      getCurrentPageItems().length,
      (index) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Card(
          elevation: 2,
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
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
                        getCurrentPageItems()[index].title,
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
                FittedBox(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: SizedBox(
                      height: .27 * widget.constraints.maxHeight,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Card(
                            child: Center(
                              child: ImageNetwork(
                                image: getCurrentPageItems()[index].url,
                                height: .15 * widget.constraints.maxHeight,
                                width: .25 * widget.constraints.maxWidth,
                                imageCache: CachedNetworkImageProvider(
                                  getCurrentPageItems()[index].url,
                                ),
                                duration: 100,
                                fitWeb: BoxFitWeb.fill,
                                onLoading: Shimmer(
                                  duration: const Duration(seconds: 1),
                                  interval: const Duration(seconds: 2),
                                  color: Colors.white,
                                  colorOpacity: 1,
                                  enabled: true,
                                  direction: const ShimmerDirection.fromLTRB(),
                                  child: Container(
                                    color: const Color.fromARGB(
                                        160, 192, 192, 192),
                                  ),
                                ),
                                onError: Image.asset(
                                  'assets/no_image/no_image.png',
                                  height: .12 * widget.constraints.maxHeight,
                                  width: .12 * widget.constraints.maxHeight,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 50),
                            child: SizedBox(
                              height: .22 * widget.constraints.maxHeight,
                              width: size.width - .27 * widget.constraints.maxWidth,
                              child: Row(
                                children: [
                                  const Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'EAN ',
                                        style: TextStyle(
                                          fontSize: 18+2,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                      Text(
                                        'SKU ',
                                        style: TextStyle(
                                          fontSize: 18+2,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                      Text(
                                        'Quantity ',
                                        style: TextStyle(
                                          fontSize: 18+2,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                      Flexible(
                                        child: Text(
                                          'Warehouse Location ',
                                          overflow: TextOverflow.visible,
                                          style: TextStyle(
                                            fontSize: 18+2,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(
                                    width: 50,
                                  ),
                                  Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _copyTextWidget(ean: getCurrentPageItems()[index].ean, width: size.width),
                                      // Text(
                                      //   getCurrentPageItems()[index].ean,
                                      //   style: const TextStyle(
                                      //     fontSize: 18,
                                      //     color: Colors.black,
                                      //   ),
                                      // ),
                                      Text(
                                        getCurrentPageItems()[index].sku,
                                        style: TextStyle(
                                          fontSize: 020 ,
                                          color: Colors.black,
                                        ),
                                      ),
                                      Text(
                                        getCurrentPageItems()[index].quantity,
                                        style: TextStyle(
                                          fontSize: 020 ,
                                          color: Colors.black,
                                        ),
                                      ),
                                      Flexible(
                                        child: Text(
                                          getCurrentPageItems()[index]
                                              .warehouseLocation,
                                          overflow: TextOverflow.visible,
                                          style: TextStyle(
                                            fontSize: 020 ,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                    ],
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _forGridView({
    required double width,
    required double height,
  }) {
    return List.generate(
      getCurrentPageItems().length,
      (index) => SizedBox(
        height: .37 * height,
        width: .5 * width,
        child: Card(
          elevation: 2,
          color: _isProductScan(itemFromMainList: getCurrentPageItems()[index])
              ? appColor.withOpacity(.2)
              : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                AutoSizeText(
                  getCurrentPageItems()[index].title,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                  style: const TextStyle(
                    fontSize: 20,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                FittedBox(
                  child: SizedBox(
                    height: .28 * height,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        FittedBox(
                          child: SizedBox(
                            height: .24 * height,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 20),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                  Card(
                                    child: Center(
                                      child: ImageNetwork(
                                        image:
                                            getCurrentPageItems()[index].url,
                                        height: .15 *
                                            height,
                                        width:
                                            .13 * width,
                                        imageCache:
                                            CachedNetworkImageProvider(
                                          getCurrentPageItems()[index].url,
                                        ),
                                        duration: 100,
                                        fitWeb: BoxFitWeb.cover,
                                        onLoading: Shimmer(
                                          duration:
                                              const Duration(seconds: 1),
                                          interval:
                                              const Duration(seconds: 2),
                                          color: Colors.white,
                                          colorOpacity: 1,
                                          enabled: true,
                                          direction: const ShimmerDirection
                                              .fromLTRB(),
                                          child: Container(
                                            color: const Color.fromARGB(
                                                160, 192, 192, 192),
                                          ),
                                        ),
                                        onError: Image.asset(
                                          'assets/no_image/no_image.png',
                                          height: .12 *
                                              widget.constraints.maxHeight,
                                          width: .12 *
                                              widget.constraints.maxHeight,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: .04 * width,
                                  ),
                                  SizedBox(
                                    height: .24 * height,

                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.max,
                                      children: [
                                        Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            AutoSizeText(
                                              'EAN ',
                                              style: TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black,
                                              ),
                                            ),
                                            AutoSizeText(
                                              'SKU ',
                                              style: TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black,
                                              ),
                                            ),
                                            AutoSizeText(
                                              'Quantity ',
                                              style: TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black,
                                              ),
                                            ),
                                            AutoSizeText(
                                              'Warehouse Location ',
                                              overflow: TextOverflow.visible,
                                              style: TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black,
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(
                                          width: .02 * width,
                                        ),
                                        Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            getCurrentPageItems()[index]
                                                    .ean
                                                    .isEmpty
                                                ? AutoSizeText(
                                                    'Missing EAN',
                                                    style: TextStyle(
                                                      fontSize: 20,
                                                      color: Colors.red,
                                                    ),
                                                  )
                                                : _copyTextWidget(
                                                    ean:
                                                        getCurrentPageItems()[
                                                                index]
                                                            .ean,
                                                    width: width,
                                                  ),
                                            AutoSizeText(
                                              getCurrentPageItems()[index]
                                                  .sku,
                                              style: TextStyle(
                                                fontSize: 20,
                                                color: Colors.black,
                                              ),
                                            ),
                                            AutoSizeText(
                                              _isProductScan(
                                                      itemFromMainList:
                                                          getCurrentPageItems()[
                                                              index])
                                                  ? _returningQuantity(
                                                          orignalQuantity: int.parse(
                                                              getCurrentPageItems()[
                                                                      index]
                                                                  .quantity),
                                                          numberOfTimeProductScan:
                                                              List<int>.from(
                                                            widget
                                                                .scanProducts
                                                                .where((element) =>
                                                                    element
                                                                        .productEAN ==
                                                                    getCurrentPageItems()[
                                                                            index]
                                                                        .ean)
                                                                .map(
                                                                  (e) => e
                                                                      .numberOfTimesProductScanned,
                                                                ),
                                                          )[0])
                                                      .toString()
                                                  : getCurrentPageItems()[
                                                          index]
                                                      .quantity,
                                              style: TextStyle(
                                                fontSize: 20,
                                                color: Colors.black,
                                              ),
                                            ),
                                            AutoSizeText(
                                              getCurrentPageItems()[index]
                                                  .warehouseLocation,
                                              overflow: TextOverflow.visible,
                                              style: TextStyle(
                                                fontSize: 20,
                                                color: Colors.black,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
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
    );
  }

  List<Widget> _forMobileTypeView({
    required double width,
    required double height,
  }) {
    return List.generate(
      getCurrentPageItems().length,
      (index) => GestureDetector(
        child: SizedBox(
          width: width * .5,
          child: Card(
            elevation: 2,
            color:
                // checkBoxValueListForPreOrders[index] == true
                //     ? preOrderColor
                //     :
                Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                children: [
                  SizedBox(
                    height: 80,
                    // width: size.width * .5,
                    child: Center(
                      child: AutoSizeText(
                        getCurrentPageItems()[index].title,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 4,
                        style: TextStyle(
                          fontSize: width * .025,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  getCurrentPageItems()[index].url.isEmpty
                      ? Image.asset(
                          'assets/no_image/no_image.png',
                          height: width * .2,
                          width: width * .2,
                          fit: BoxFit.contain,
                        )
                      : Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: SizedBox(
                              height: .2 * width,
                              width: .2 * width,
                              child: ImageWidgetPlaceholder(
                                image: CachedNetworkImageProvider(
                                  getCurrentPageItems()[index].url,
                                ),
                                placeholder: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ))),
                  SizedBox(
                    height: 160,
                    width: width * .4,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 160,
                          width: width * .2,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AutoSizeText(
                                'EAN ',
                                style: TextStyle(
                                  fontSize: width * .01,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              AutoSizeText(
                                'SKU ',
                                style: TextStyle(
                                  fontSize: width * .01,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              AutoSizeText(
                                'Quantity ',
                                style: TextStyle(
                                  fontSize: width * .01,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              AutoSizeText(
                                'Warehouse Location ',
                                overflow: TextOverflow.visible,
                                style: TextStyle(
                                  fontSize: width * .01,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: 160,
                          width: width * .2,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _copyTextWidget(
                                ean: getCurrentPageItems()[index].ean,
                                width: width,
                              ),
                              AutoSizeText(
                                getCurrentPageItems()[index].sku,
                                style: TextStyle(
                                  fontSize: width * .03,
                                  color: Colors.black,
                                ),
                              ),
                              AutoSizeText(
                                getCurrentPageItems()[index].quantity,
                                overflow: TextOverflow.visible,
                                style: TextStyle(
                                  fontSize: .03 * width,
                                  color: Colors.black,
                                ),
                              ),
                              AutoSizeText(
                                getCurrentPageItems()[index].warehouseLocation,
                                overflow: TextOverflow.visible,
                                style: TextStyle(
                                  fontSize: width * .03,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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

  /*Pagination Work Start Here*/
  int currentPage = 1;
  int itemsPerPage = 10;

  void goToPage(int page) {
    setState(() {
      currentPage = page;
    });
  }

  List<ShopReplenishSku> getCurrentPageItems() {
    int startIndex = (currentPage - 1) * itemsPerPage;
    int endIndex = startIndex + itemsPerPage;
    endIndex = endIndex.clamp(0, widget.data.length);
    return widget.data.sublist(startIndex, endIndex);
  }

  Widget _paginationButtons() => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed:
                  currentPage > 1 ? () => goToPage(currentPage - 1) : null,
              child: const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('Previous'),
              ),
            ),
            const SizedBox(width: 20),
            ElevatedButton(
              onPressed:
                  currentPage < (widget.data.length / itemsPerPage).ceil()
                      ? () => goToPage(currentPage + 1)
                      : null,
              child: const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('Next'),
              ),
            ),
          ],
        ),
      );

/*Pagination Work Ends Here*/
}

class _copyTextWidget extends StatefulWidget {
  final String ean;

  final double width;

  const _copyTextWidget({required this.ean, required this.width});

  @override
  State<_copyTextWidget> createState() => _copyTextWidgetState();
}

class _copyTextWidgetState extends State<_copyTextWidget> {
  TextDecoration inputDecoration = TextDecoration.none;

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return GestureDetector(
      onTap: () {
        setState(() {
          inputDecoration = TextDecoration.underline;
        });

        Clipboard.setData(ClipboardData(
          text: widget.ean,
        ));

        Fluttertoast.showToast(msg: 'EAN Copied');

        Future.delayed(const Duration(seconds: 1)).whenComplete(
          () => setState(
            () => inputDecoration = TextDecoration.none,
          ),
        );
      },
      child: AutoSizeText(
        widget.ean,
        maxLines: 1,
        style: TextStyle(
          fontSize: 20,
          color: Colors.black,
          decoration: inputDecoration,
        ),
      ),
    );
  }
}
