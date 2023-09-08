import 'dart:convert';
import 'dart:developer';

import 'package:absolute_app/core/utils/constants.dart';
import 'package:absolute_app/core/utils/toast_utils.dart';
import 'package:flutter/material.dart';
import 'package:rounded_loading_button/rounded_loading_button.dart';
import 'package:http/http.dart' as http;

class ShopReplenishScreen extends StatefulWidget {
  const ShopReplenishScreen({super.key, required this.eanList});

  final List<String> eanList;

  @override
  State<ShopReplenishScreen> createState() => _ShopReplenishScreenState();
}

class _ShopReplenishScreenState extends State<ShopReplenishScreen> {
  final RoundedLoadingButtonController createPicklistController =
      RoundedLoadingButtonController();

  Map<String, int> eanQuantityMap = {};
  List<dynamic> eanListToSent = [];

  bool isLoading = false;
  bool isError = false;

  String error = '';

  @override
  void initState() {
    super.initState();
    eanListToMap();
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
        FocusScope.of(context).requestFocus(FocusNode());
        if (!node.hasPrimaryFocus) {
          node.unfocus();
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
        child: Column(
          children: [
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

  Widget _createPicklistBuilder(BuildContext context, Size size) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 5),
          child: SizedBox(
            height: 40,
            width: 300,
            child: RoundedLoadingButton(
              color: Colors.green,
              borderRadius: 10,
              height: 40,
              width: 200,
              successIcon: Icons.check_rounded,
              failedIcon: Icons.close_rounded,
              successColor: Colors.green,
              controller: createPicklistController,
              onPressed: () async {
                await makeShopPicklist(eanList: eanListToSent)
                    .whenComplete(() async {
                  await Future.delayed(const Duration(milliseconds: 1500), () {
                    if (!isError) {
                      Navigator.popUntil(context, (route) => route.isFirst);
                    }
                    createPicklistController.reset();
                  });
                });
              },
              child: Text(
                'Make Shop Picklist',
                style: TextStyle(
                  fontSize: size.width * .048,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
        const Padding(padding: EdgeInsets.only(top: 5), child: Divider()),
        Padding(
          padding: const EdgeInsets.only(top: 5, bottom: 5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${eanQuantityMap.length} ',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                eanQuantityMap.length > 1 ? 'EANs Scanned' : 'EAN Scanned',
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _eanListTitleMaker(Size size) {
    return Row(
      children: [
        Container(
          width: size.width * .7 - 5,
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
          width: size.width * .3 - 5,
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
    );
  }

  List<Widget> _eanListMaker(Size size) {
    return List.generate(
      eanQuantityMap.length,
      (index) => Row(
        children: [
          Container(
            width: size.width * .7 - 5,
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
                widget.eanList.toSet().toList()[index],
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ),
          Container(
            width: size.width * .3 - 5,
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
                '${eanQuantityMap[widget.eanList.toSet().toList()[index]]}',
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

  void eanListToMap() async {
    setState(() {
      isLoading = true;
    });
    eanQuantityMap = {};
    for (var x in widget.eanList) {
      eanQuantityMap[x] =
          !eanQuantityMap.containsKey(x) ? (1) : (eanQuantityMap[x]! + 1);
    }
    log('V eanQuantityMap >>---> $eanQuantityMap');

    eanListToSent = [];
    eanListToSent.addAll(List.generate(
            eanQuantityMap.length,
            (index) =>
                '{%22ean%22:%22${widget.eanList.toSet().toList()[index]}%22,%22quantity%22:%22${eanQuantityMap[widget.eanList.toSet().toList()[index]]}%22}')
        .map((e) => e));
    log('eanListToSent >>---> $eanListToSent');

    await Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        isLoading = false;
      });
    });
  }

  Future<void> makeShopPicklist({required List<dynamic> eanList}) async {
    setState(() {
      isLoading = true;
      isError = false;
    });
    String uri =
        'https://weblegs.info/JadlamApp/api/CreateShopReplenishVersion2?data={%22eanQuanities%22:[${eanList.join(',')}]}';
    log('MAKE SHOP PICKLIST API URI >>---> $uri');

    try {
      var response = await http.get(Uri.parse(uri)).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          ToastUtils.showCenteredLongToast(message: kTimeOut);
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
        ToastUtils.showCenteredLongToast(
          message: jsonDecode(response.body)['message'].toString(),
        );
        setState(() {
          isLoading = false;
          isError = false;
        });
      } else {
        ToastUtils.showCenteredLongToast(message: kerrorString);
        setState(() {
          isLoading = false;
          isError = true;
        });
      }
    } on Exception catch (e) {
      log('MAKE SHOP PICKLIST API EXCEPTION >>---> ${e.toString()}');
      ToastUtils.showCenteredLongToast(message: e.toString());
      setState(() {
        isLoading = false;
        isError = true;
      });
    }
  }
}
