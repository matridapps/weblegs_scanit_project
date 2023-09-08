import 'dart:convert';
import 'dart:developer';

import 'package:absolute_app/core/utils/constants.dart';
import 'package:absolute_app/core/utils/toast_utils.dart';
import 'package:flutter/material.dart';
import 'package:rounded_loading_button/rounded_loading_button.dart';
import 'package:http/http.dart' as http;

class ShopReplenishScreenWeb extends StatefulWidget {
  const ShopReplenishScreenWeb({super.key});

  @override
  State<ShopReplenishScreenWeb> createState() => _ShopReplenishScreenWebState();
}

class _ShopReplenishScreenWebState extends State<ShopReplenishScreenWeb> {
  final RoundedLoadingButtonController createPicklistController =
      RoundedLoadingButtonController();
  final TextEditingController eanController = TextEditingController();
  final FocusNode eanFocus = FocusNode();

  Map<String, int> eanQuantityMap = {};
  List<dynamic> eanListToSent = [];
  List<String> eanList = [];

  bool isLoading = false;
  bool isError = false;

  String error = '';
  String currentEan = '';

  @override
  void initState() {
    super.initState();
  }

  PreferredSizeWidget? _shopReplenishAppBar(Size size) {
    return AppBar(
      backgroundColor: Colors.white,
      automaticallyImplyLeading: true,
      iconTheme: const IconThemeData(color: Colors.black),
      centerTitle: true,
      toolbarHeight: AppBar().preferredSize.height,
      elevation: 5,
      title: const Text(
        'Shop Replenish',
        style: TextStyle(
          fontSize: 25,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _loader(Size size) {
    return SizedBox(
      height: size.height,
      width: size.width,
      child: const Center(
        child: CircularProgressIndicator(
          color: appColor,
        ),
      ),
    );
  }

  Widget _screenBuilder(BuildContext context, Size size, FocusScopeNode node) {
    return GestureDetector(
      onTap: () {
        log('height >> ${MediaQuery.of(context).size.height}');
        log('width >> ${MediaQuery.of(context).size.width}');
        FocusScope.of(context).requestFocus(FocusNode());
        if (!node.hasPrimaryFocus) {
          node.unfocus();
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          children: [
            _eanTextFormFieldBuilder(size),
            _createPicklistBuilder(context, size),
            _eanListTitleMaker(size),
            Expanded(
              child: SingleChildScrollView(
                child: Column(children: _eanListMaker(size)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _eanTextFormFieldBuilder(Size size) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 40,
              width: _sizeChecker(size),
              child: TextFormField(
                focusNode: eanFocus,
                autofocus: true,
                controller: eanController,
                style: const TextStyle(fontSize: 16),
                decoration: const InputDecoration(
                  hintText: 'Product Barcode',
                  hintStyle: TextStyle(fontSize: 16),
                  contentPadding: EdgeInsets.all(5),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(width: 0.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: appColor, width: 1),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onChanged: (_) {
                  if (eanController.text.length > 4) {
                    _onEanFieldChange();
                  }
                },
              ),
            ),
          ],
        ),
        Visibility(
          visible: error.isNotEmpty || eanQuantityMap.isNotEmpty,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  error.isEmpty ? currentEan : error,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (error.isEmpty)
                  const Text(
                    ' added to the list below',
                    style: TextStyle(fontSize: 18),
                  ),
              ],
            ),
          ),
        )
      ],
    );
  }

  Widget _createPicklistBuilder(BuildContext context, Size size) {
    return Visibility(
      visible: eanQuantityMap.isNotEmpty,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: SizedBox(
              height: 40,
              width: 300,
              child: RoundedLoadingButton(
                color: Colors.green,
                borderRadius: 5,
                height: 40,
                width: 250,
                successIcon: Icons.check_rounded,
                failedIcon: Icons.close_rounded,
                successColor: Colors.green,
                controller: createPicklistController,
                onPressed: () async {
                  await makeShopPicklist(
                    eanList: eanListToSent,
                    context: context,
                  ).whenComplete(() async {
                    await Future.delayed(const Duration(milliseconds: 1500),
                        () {
                      if (!isError) {
                        Navigator.pop(context);
                      }
                      createPicklistController.reset();
                    });
                  });
                },
                child: const Text(
                  'Make Shop Picklist',
                  style: TextStyle(fontSize: 20, color: Colors.white),
                ),
              ),
            ),
          ),
          const Padding(padding: EdgeInsets.only(top: 5), child: Divider()),
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${eanQuantityMap.length} ',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  eanQuantityMap.length > 1 ? 'EANs Scanned' : 'EAN Scanned',
                  style: const TextStyle(fontSize: 18),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _eanListTitleMaker(Size size) {
    return Visibility(
      visible: eanQuantityMap.isNotEmpty,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: _sizeChecker(size) * (2 / 3),
            height: 40,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey, width: 1),
              color: Colors.grey.shade300,
            ),
            child: const Center(
              child: Text(
                'EAN',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Container(
            width: _sizeChecker(size) * (1 / 3),
            height: 40,
            decoration: BoxDecoration(
              border: const Border(
                right: BorderSide(color: Colors.grey, width: 1),
                top: BorderSide(color: Colors.grey, width: 1),
                bottom: BorderSide(color: Colors.grey, width: 1),
              ),
              color: Colors.grey.shade300,
            ),
            child: const Center(
              child: Text(
                'Quantity',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _eanListMaker(Size size) {
    return List.generate(
      eanQuantityMap.length,
      (index) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: _sizeChecker(size) * (2 / 3),
            height: 40,
            decoration: BoxDecoration(
              border: const Border(
                right: BorderSide(color: Colors.grey, width: 1),
                left: BorderSide(color: Colors.grey, width: 1),
                bottom: BorderSide(color: Colors.grey, width: 1),
              ),
              color: Colors.grey.shade200,
            ),
            child: Center(
              child: Text(
                eanList.toSet().toList()[index],
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ),
          Container(
            width: _sizeChecker(size) * (1 / 3),
            height: 40,
            decoration: BoxDecoration(
              border: const Border(
                right: BorderSide(color: Colors.grey, width: 1),
                bottom: BorderSide(color: Colors.grey, width: 1),
              ),
              color: Colors.grey.shade200,
            ),
            child: Center(
              child: Text(
                '${eanQuantityMap[eanList.toSet().toList()[index]]}',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    FocusScopeNode currentFocus = FocusScope.of(context);
    return SelectionArea(
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        resizeToAvoidBottomInset: true,
        appBar: _shopReplenishAppBar(size),
        body: isLoading == true
            ? _loader(size)
            : _screenBuilder(context, size, currentFocus),
      ),
    );
  }

  double _sizeChecker(Size size) {
    if (size.width > 1000) {
      return size.width * .6;
    } else {
      return size.width * .9;
    }
  }

  void _onEanFieldChange() async {
    setState(() {
      isLoading = true;
    });
    if (int.tryParse(eanController.text) != null) {
      setState(() {
        currentEan = eanController.text;
        error = '';
      });
      log('currentEan >>---> $currentEan');
      eanList.add(eanController.text);
      log('eanList >>---> $eanList');
      List<String> tempList = [];
      tempList.addAll(eanList.map((e) => e));
      log('tempList >>---> $tempList');
      eanQuantityMap = {};
      for (var x in tempList) {
        eanQuantityMap[x] =
            !eanQuantityMap.containsKey(x) ? (1) : (eanQuantityMap[x]! + 1);
      }
      log('V eanQuantityMap >>---> $eanQuantityMap');

      eanListToSent = [];
      eanListToSent.addAll(List.generate(
              eanQuantityMap.length,
              (index) =>
                  '{%22ean%22:%22${eanList.toSet().toList()[index]}%22,%22quantity%22:%22${eanQuantityMap[eanList.toSet().toList()[index]]}%22}')
          .map((e) => e));
      log('eanListToSent >>---> $eanListToSent');
    } else {
      setState(() {
        error = 'Not an EAN!';
      });
      log('error >>---> $error');
    }
    await Future.delayed(const Duration(milliseconds: 500), () {
      eanController.clear();
      eanFocus.requestFocus();
      setState(() {
        isLoading = false;
      });
    });
  }

  Future<void> makeShopPicklist({
    required List<dynamic> eanList,
    required BuildContext context,
  }) async {
    setState(() {
      isLoading = true;
      isError = false;
    });
    String uri =
        'https://weblegs.info/JadlamApp/api/CreateShopReplenishVersion2?data={%22eanQuanities%22:[${eanList.join(',')}]}';
    log('MAKE SHOP PICKLIST API URI >>--->');
    log(uri);

    try {
      var response = await http.get(Uri.parse(uri)).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          ToastUtils.motionToastCentered1500MS(
            message: kTimeOut,
            context: context,
          );
          setState(() {
            isLoading = false;
            isError = true;
          });
          return http.Response('Error', 408);
        },
      );
      log('MAKE SHOP PICKLIST API STATUS CODE >>---> ${response.statusCode}');

      if (response.statusCode == 200) {
        log('MAKE SHOP PICKLIST API RESPONSE >>---> ${jsonDecode(response.body)}');
        if (!mounted) return;
        ToastUtils.motionToastCentered1500MS(
          message: jsonDecode(response.body)['message'].toString(),
          context: context,
        );
        setState(() {
          isLoading = false;
          isError = false;
        });
      } else {
        if (!mounted) return;
        ToastUtils.motionToastCentered1500MS(
          message: kerrorString,
          context: context,
        );
        setState(() {
          isLoading = false;
          isError = true;
        });
      }
    } on Exception catch (e) {
      log('MAKE SHOP PICKLIST API EXCEPTION >>---> ${e.toString()}');
      ToastUtils.motionToastCentered1500MS(
        message: e.toString(),
        context: context,
      );
      setState(() {
        isLoading = false;
        isError = true;
      });
    }
  }
}
