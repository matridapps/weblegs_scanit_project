import 'package:absolute_app/core/utils/constants.dart';
import 'package:absolute_app/core/utils/navigation_methods.dart';
import 'package:absolute_app/screens/mobile_device_screens/pre_order_screen.dart';
import 'package:absolute_app/screens/web_screens/pre_order_screen_web.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class PreOrderOptions extends StatefulWidget {
  const PreOrderOptions({super.key});

  @override
  State<PreOrderOptions> createState() => _PreOrderOptionsState();
}

class _PreOrderOptionsState extends State<PreOrderOptions> {
  List<bool> isTapped = [false, false];

  LinearGradient linearGradient1 = const LinearGradient(
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
    stops: [0.1, 0.4, 0.6, 0.9],
    colors: [
      Color.fromARGB(255, 178, 62, 3),
      Color.fromARGB(255, 181, 63, 3),
      Color.fromARGB(255, 194, 82, 3),
      Color.fromARGB(255, 221, 118, 3),
    ],
  );

  LinearGradient linearGradient2 = const LinearGradient(
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
    stops: [0.5],
    colors: [Colors.white],
  );

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.grey[100],
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.white,
        automaticallyImplyLeading: true,
        iconTheme: const IconThemeData(color: Colors.black),
        centerTitle: true,
        toolbarHeight: AppBar().preferredSize.height,
        elevation: 5,
        title: const Text(
          'Pre-Orders',
          style: TextStyle(
            fontSize: 25,
            color: Colors.black,
          ),
        ),
      ),
      body: kIsWeb == true
          ? _webScreenBuilder(context, size)
          : _mobileScreenBuilder(context, size),
    );
  }

  Widget _webScreenBuilder(BuildContext context, Size size) {
    return SizedBox(
        height: size.height,
        width: size.width,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                GestureDetector(
                  onTap: () async {
                    setState(() {
                      isTapped = [true, false];
                    });
                    await Future.delayed(const Duration(milliseconds: 400),
                        () async {
                      await NavigationMethods.push(
                        context,
                        const PreOrderScreenWeb(),
                      );
                    });
                  },
                  child: Card(
                    elevation: isTapped[0] ? 20 : 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Container(
                      height: size.width * .15,
                      width: size.width * .15,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: isTapped[0] == true
                            ? linearGradient1
                            : linearGradient2,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(
                            height: size.width * .1,
                            width: size.width * .1,
                            child: Image.asset(
                              'assets/home_screen_assets/single_color/order_pre-order_01.png',
                              color: isTapped[0] == true
                                  ? Colors.white
                                  : appColor,
                            ),
                          ),
                          Text(
                            'Orders',
                            style: TextStyle(
                              color: isTapped[0] == true
                                  ? Colors.white
                                  : Colors.black,
                              fontSize: 16,
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () async {
                    setState(() {
                      isTapped = [false, true];
                    });
                    await Future.delayed(const Duration(milliseconds: 400),
                        () async {
                      // await NavigationMethods.push(
                      //   context,
                      //   PickLists(
                      //     accType: widget.accType,
                      //     authorization: widget.authorization,
                      //     refreshToken: widget.refreshToken,
                      //     profileId: widget.profileId,
                      //     distCenterId: widget.distCenterId,
                      //     distCenterName: widget.distCenterName,
                      //     userName: widget.userId,
                      //   ),
                      // );
                    });
                  },
                  child: Card(
                    elevation: isTapped[1] ? 20 : 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Container(
                      height: size.width * .15,
                      width: size.width * .15,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: isTapped[1] == true
                            ? linearGradient1
                            : linearGradient2,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(
                            height: size.width * .1,
                            width: size.width * .1,
                            child: Image.asset(
                              'assets/home_screen_assets/single_color/picklist_01.png',
                              color: isTapped[1] == true
                                  ? Colors.white
                                  : appColor,
                            ),
                          ),
                          Text(
                            'Picklist',
                            style: TextStyle(
                              color: isTapped[1] == true
                                  ? Colors.white
                                  : Colors.black,
                              fontSize: 16,
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ));
  }

  Widget _mobileScreenBuilder(BuildContext context, Size size) {
    return SizedBox(
      height: size.height,
      width: size.width,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              GestureDetector(
                onTap: () async {
                  setState(() {
                    isTapped = [true, false];
                  });
                  await Future.delayed(const Duration(milliseconds: 400), () {
                    NavigationMethods.push(
                      context,
                      const PreOrderScreen(),
                    );
                  });
                },
                child: Card(
                  elevation: isTapped[0] ? 20 : 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Container(
                    height: size.width * .4,
                    width: size.width * .4,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: isTapped[0] == true
                          ? linearGradient1
                          : linearGradient2,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: size.width * .25,
                          width: size.width * .25,
                          child: Image.asset(
                            'assets/home_screen_assets/single_color/order_pre-order_01.png',
                            color:
                                isTapped[0] == true ? Colors.white : appColor,
                          ),
                        ),
                        Text(
                          'Orders',
                          style: TextStyle(
                            color: isTapped[0] == true
                                ? Colors.white
                                : Colors.black,
                            fontSize: 16,
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () async {
                  setState(() {
                    isTapped = [false, true];
                  });
                  await Future.delayed(const Duration(milliseconds: 400), () {
                    // NavigationMethods.push(
                    //   context,
                    //   BarcodeCameraScreen(
                    //     accType: widget.accType,
                    //     authorization: widget.authorization,
                    //     refreshToken: widget.refreshToken,
                    //     crossVisible: crossVisible,
                    //     screenType: 'jit order',
                    //     profileId: widget.profileId,
                    //     distCenterName: widget.distCenterName,
                    //     distCenterId: widget.distCenterId,
                    //     barcodeToCheck: 0,
                    //   ),
                    // );
                  });
                },
                child: Card(
                  elevation: isTapped[1] ? 20 : 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Container(
                    height: size.width * .4,
                    width: size.width * .4,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: isTapped[1] == true
                          ? linearGradient1
                          : linearGradient2,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: size.width * .25,
                          width: size.width * .25,
                          child: Image.asset(
                            'assets/home_screen_assets/single_color/picklist_01.png',
                            color:
                                isTapped[1] == true ? Colors.white : appColor,
                          ),
                        ),
                        Text(
                          'Picklist',
                          style: TextStyle(
                            color: isTapped[1] == true
                                ? Colors.white
                                : Colors.black,
                            fontSize: 16,
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
