import 'dart:convert';
import 'dart:developer';

import 'package:absolute_app/core/blocs/shop_repienish_bloc/shop_repienish_bloc.dart';
import 'package:absolute_app/core/utils/constants.dart';
import 'package:absolute_app/core/utils/size_vishal.dart';
import 'package:absolute_app/models/shop_replinsh_model.dart';
import 'package:absolute_app/screens/web_screens/new_screens_by_vishal/shop_screen/widgets/scanner_web_shop.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart';
import 'package:image_network/image_network.dart';
import 'package:modal_side_sheet/modal_side_sheet.dart';

import 'widgets/for_24_inches_and_below.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  final _controller = ScrollController();

  bool show = false;

  bool _buttonLoading = false;

  @override
  void initState() {
    // WidgetsBinding.instance.addObserver(this);
    context.read<ShopRepienishBloc>().add(ShopRepienishLoadingEvent());
    super.initState();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _controller.dispose();
    super.dispose();
  }

  Widget _scanButton({required List<ShopReplenishSku> orignalProducts,}) =>
      GestureDetector(
        onTap: () => kIsWeb
            ? Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ScannerWebForShop(
                    scanProducts: scanProducts,
                    orignalProducts: orignalProducts,
                    focusNode: FocusNode(),
                  ),
                ),
              ).whenComplete(() => scanProducts.isNotEmpty
                ? context
                    .read<ShopRepienishBloc>()
                    .add(ShopRepienishLoadingEvent())
                : null)
            : Fluttertoast.showToast(
                msg: 'Work in Progress for Mobile.',
              ),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 30.0),
          child: Center(
            child: Text(
              'Scan',
              style: TextStyle(color: Colors.black),
            ),
          ),
        ),
      );

  List<ScanProductModel> scanProducts = [];

  @override
  Widget build(BuildContext context) {

    return SizedBox(
      width: w,
      height: h,
      child: BlocBuilder<ShopRepienishBloc, ShopRepienishState>(
        builder: (context, state) {
          return state is ShopRepienishInitialState ||
                  state is ShopRepienishLoadingState
              ? const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              : state is ShopRepienishLoadedState
                  ? Scaffold(
                      appBar: AppBar(
                        backgroundColor: Colors.white,
                        title: const Center(
                          child: Text(
                            'Shops Replenish',
                            style: TextStyle(
                              fontSize: 25,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        // actions: [
                        //   _scanButton(orignalProducts: state.list),
                        // ],
                        leading: Padding(
                          padding: const EdgeInsets.all(10),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(50),
                            radius: 40,
                            onTap: () async {
                              Navigator.pop(context);
                            },
                            splashColor: Colors.grey.withOpacity(.3),
                            highlightColor: Colors.grey.withOpacity(.3),
                            hoverColor: Colors.grey.withOpacity(.3),
                            child: const Icon(
                              Icons.arrow_back,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        centerTitle: true,
                      ),
                      body: BodyWithSideSheet(
                        sheetWidth: MediaQuery.of(context).size.width / 4,
                        show: scanProducts.isNotEmpty,
                        body: LayoutBuilder(
                          builder: (context, constraints) {
                            return !kIsWeb && constraints.maxWidth <= 385
                                ? Scrollbar(
                                    controller: _controller,
                                    child: SingleChildScrollView(
                                      child: ShopReplenishForMobile(
                                        data: state.list,
                                        controller: _controller,
                                        constraints: constraints,
                                      ),
                                    ),
                                  )
                                : ShopScreenForWeb(
                                    data: state.list,
                                    constraints: constraints,
                                    scanProducts: scanProducts,
                                  );
                          },
                        ),
                        sheetBody: SingleChildScrollView(
                          physics: const NeverScrollableScrollPhysics(),
                          child: Column(
                            children: [
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * .85,
                                child: ListView.builder(
                                  itemCount: scanProducts.length,
                                  itemBuilder: (context, index) {
                                    return Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Card(
                                        child: ListTile(
                                          trailing: Text(
                                              'Quantity: ${scanProducts[index].numberOfTimesProductScanned}'),
                                          title: Text(
                                              "EAN: ${scanProducts[index].productEAN}"),
                                          // trailing:
                                          // const Icon(Icons.safety_divider),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              SizedBox(
                                  height: MediaQuery.of(context).size.width / 4,
                                  child: Wrap(
                                    alignment: WrapAlignment.spaceEvenly,
                                    children: [
                                      GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            scanProducts.clear();
                                            context
                                                .read<ShopRepienishBloc>()
                                                .add(
                                                    ShopRepienishLoadingEvent());
                                          });
                                        },
                                        child: Container(
                                          color: appColor,
                                          child: const Padding(
                                            padding: EdgeInsets.all(15),
                                            child: AutoSizeText(
                                              'Clear Scan List',
                                              style: TextStyle(
                                                fontSize: 20,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(
                                        width: 60,
                                        height: 50,
                                      ),
                          GestureDetector(
                            onTap: () async{
                              setState(()=> _buttonLoading = true);
                              await createShopReplenishPicklist().whenComplete(() => setState(()=> _buttonLoading = false));
                            },
                            child: Container(
                              color: appColor,
                              child:  Padding(
                                padding:const EdgeInsets.all(15),
                                child:_buttonLoading == true?const CircularProgressIndicator(color: Colors.white,): const AutoSizeText(
                                  'Create Picklist',
                                  style: TextStyle(
                                    fontSize: 20,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          )

                                    ],
                                  ))
                            ],
                          ),
                        ),
                      ),
                    )
                  : state is ShopRepienishErrorState
                      ? Scaffold(
                          body: Center(
                            child: Text(state.errorMessage),
                          ),
                        )
                      : const SizedBox();
        },
      ),
    );
  }

  Future<void> createShopReplenishPicklist() async {
 
    List<String> _tempList = [];

    for (var element in scanProducts) {
      _tempList.add(
          '${element.productEAN}:' '${element.numberOfTimesProductScanned}');
    }

    log(_tempList.length.toString());
    log(_tempList.join(',').toString());
    
    
    try{

      final response = await get(Uri.parse('https://weblegs.info/JadlamApp/api/CreateShopReplenishpicklist?SkuandQuantity=${_tempList.join(',')}'));
      if(jsonDecode(response.body)['message'].toString().toLowerCase().contains('successfully created')){
        Fluttertoast.showToast(msg: jsonDecode(response.body)['message'].toString());

        setState(() {
          scanProducts.clear();
        });
        context.read<ShopRepienishBloc>().add(ShopRepienishLoadingEvent());
      }else{

        Fluttertoast.showToast(msg: jsonDecode(response.body)['message'].toString());
      }
      
      
    }catch(e){
      Fluttertoast.showToast(msg: 'Something went wrong.\nPlease try again');
    }
    
  }


}

class ShopReplenishForMobile extends StatelessWidget {
  const ShopReplenishForMobile(
      {super.key,
      required this.data,
      required this.constraints,
      required this.controller});

  final List<ShopReplenishSku> data;
  final BoxConstraints constraints;
  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: _preOrdersListMaker(
          Size(
            constraints.maxWidth,
            constraints.maxHeight,
          ),
        ),
      ),
    );
  }

  /// LIST GENERATOR FOR PRE-ORDERS
  List<Widget> _preOrdersListMaker(Size size) {
    return List.generate(
      data.length,
      (index) => GestureDetector(
        // onTap: () {
        //   setState(() {
        //     checkBoxValueListForPreOrders[index] =
        //     !(checkBoxValueListForPreOrders[index]);
        //   });
        //   log('V checkBoxValueListForPreOrders At $index >>---> ${checkBoxValueListForPreOrders[index]}');
        //   if (checkBoxValueListForPreOrders.every((e) => e == true)) {
        //     setState(() {
        //       isAllSelected = true;
        //     });
        //   } else {
        //     setState(() {
        //       isAllSelected = false;
        //     });
        //   }
        // },
        child: Card(
          elevation: 2,
          color:
              // checkBoxValueListForPreOrders[index] == true
              //     ? preOrderColor
              //     :
              Colors.white,
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
                          data[index].title,
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
                    child: data[index].url.isEmpty
                        ? Image.asset(
                            'assets/no_image/no_image.png',
                            height: size.width * .8,
                            width: size.width * .8,
                            fit: BoxFit.contain,
                          )
                        : ImageNetwork(
                            image: data[index].url,
                            imageCache: CachedNetworkImageProvider(
                              data[index].url,
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
                                  'EAN ',
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
                                  'Quantity ',
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
                                  data[index].ean,
                                  style: TextStyle(
                                    fontSize: size.width * .04,
                                    color: Colors.black,
                                  ),
                                ),
                                Text(
                                  data[index].sku,
                                  style: TextStyle(
                                    fontSize: size.width * .04,
                                    color: Colors.black,
                                  ),
                                ),
                                Flexible(
                                  child: Text(
                                    data[index].quantity,
                                    overflow: TextOverflow.visible,
                                    style: TextStyle(
                                      fontSize: size.width * .04,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                                Flexible(
                                  child: Text(
                                    data[index].warehouseLocation,
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
                          value: true,
                          // onChanged: (bool? newValue) {
                          //   setState(() {
                          //     checkBoxValueListForPreOrders[index] =
                          //     !(checkBoxValueListForPreOrders[index]);
                          //   });
                          //   log('V checkBoxValueListForPreOrders At $index >>---> ${checkBoxValueListForPreOrders[index]}');
                          //   if (checkBoxValueListForPreOrders
                          //       .every((e) => e == true)) {
                          //     setState(() {
                          //       isAllSelected = true;
                          //     });
                          //   } else {
                          //     setState(() {
                          //       isAllSelected = false;
                          //     });
                          //   }
                          onChanged: (bool? value) {},
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
}
