import 'package:absolute_app/models/shop_replinsh_model.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

// ignore: must_be_immutable
class ScannerWebForShop extends StatefulWidget {
  ScannerWebForShop(
      {super.key, required this.scanProducts, required this.orignalProducts});

  List<ScanProductModel> scanProducts;
  final List<ShopReplenishSku> orignalProducts;

  @override
  State<ScannerWebForShop> createState() => _ScannerWebForShopState();
}

class _ScannerWebForShopState extends State<ScannerWebForShop> {
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: ,

      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: TextFormField(
                controller: _controller,
                decoration: const InputDecoration(
                  labelText: 'Scanned EA',
                  border: OutlineInputBorder(),
                ),
                onChanged: (String value) async {
                  if (value.length > 4) {
                    if (widget.scanProducts
                        .where((element) => element.productEAN == value)
                        .isNotEmpty) {
                      List<ScanProductModel> list = List<ScanProductModel>.from(
                          widget.scanProducts
                              .where((element) => element.productEAN == value)
                              .map((e) => e));

                      ScanProductModel model = list[0];

                      setState(() {


                        if(_isQuantityReachZero(
                            ean: value,
                            numberOfTimesScanned:
                            model.numberOfTimesProductScanned) ==
                            true) {
                          Fluttertoast.showToast(
                              msg: '0 quantity left.\nCannot Update the Quantity for this Product',
                              gravity: ToastGravity.CENTER,
                              toastLength: Toast
                                  .LENGTH_LONG);
                        }else
                        {
                          model.numberOfTimesProductScanned =
                              model.numberOfTimesProductScanned + 1;

                          widget.scanProducts.remove(model);
                          widget.scanProducts.insert(0, model);
                        }
                      });
                    } else {
                      saveScannedProducts(ean: value, numberOfTimes: 1);
                    }

                    await Future.delayed(const Duration(seconds: 1))
                        .whenComplete(() => _controller.clear());
                  }
                },
              ),
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          const Padding(
            padding: EdgeInsets.all(15.0),
            child: Text(
              'Recently Scanned Products',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          Flexible(
            child: Column(
              children: List.generate(
                widget.scanProducts.length,
                    (index) =>
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(15),
                        child: Center(
                          child: Text(
                            'EAN:  ${widget.scanProducts[index]
                                .productEAN}   Number of times scanned:  ${widget
                                .scanProducts[index]
                                .numberOfTimesProductScanned}',
                            style: const TextStyle(
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ),
              ),
            ),
          )
        ],
      ),
    );
  }

  void saveScannedProducts({required String ean, required int numberOfTimes}) {
    setState(() {
      widget.scanProducts.insert(
          0,
          ScanProductModel(
              productEAN: ean, numberOfTimesProductScanned: numberOfTimes));
    });
  }

  bool _isQuantityReachZero(
      {required String ean, required int numberOfTimesScanned}) {
    List<ShopReplenishSku> temp = List<ShopReplenishSku>.from(
      widget.orignalProducts
          .where((element) => element.ean == ean)
          .map((e) => e),
    );

    int tempQuantity = int.parse(temp[0].quantity) - numberOfTimesScanned;

    return tempQuantity <= 0;
  }
}

class ScanProductModel {
  final String productEAN;
  int numberOfTimesProductScanned;

  ScanProductModel({
    required this.productEAN,
    required this.numberOfTimesProductScanned,
  });
}
