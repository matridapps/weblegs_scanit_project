import 'dart:async';
import 'dart:ui';
import 'package:absolute_app/core/state_management/logic_class.dart';
import 'package:absolute_app/core/utils/constants.dart';
import 'package:absolute_app/core/utils/navigation_methods.dart';
import 'package:absolute_app/screens/mobile_device_screens/new_order_screen_one.dart';
import 'package:absolute_app/screens/mobile_device_screens/pack_and_scan.dart';
import 'package:absolute_app/screens/mobile_device_screens/product_details.dart';
import 'package:absolute_app/screens/mobile_device_screens/scan_for_transfer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeCameraScreen extends StatefulWidget {
  const BarcodeCameraScreen(
      {Key? key,
      required this.accType,
      required this.authorization,
      required this.refreshToken,
      required this.crossVisible,
      required this.profileId,
      required this.distCenterId,
      required this.distCenterName,
      required this.screenType,
      required this.barcodeToCheck})
      : super(key: key);

  final String accType;
  final String authorization;
  final String refreshToken;
  final bool crossVisible;
  final String screenType;
  final int profileId;
  final int distCenterId;
  final String distCenterName;
  final int barcodeToCheck;

  @override
  State<BarcodeCameraScreen> createState() => _BarcodeCameraScreenState();
}

class _BarcodeCameraScreenState extends State<BarcodeCameraScreen>
    with SingleTickerProviderStateMixin {
  BarcodeCapture? barcode;

  bool isLoaderVisible = false;

  final MobileScannerController controller =
      MobileScannerController(torchEnabled: false);

  bool isStarted = true;
  BusinessLogic logicProvider = BusinessLogic();

  @override
  void initState() {
    Timer.periodic(const Duration(milliseconds: 10), (Timer t) async {
      if (barcode?.barcodes != null) {
        HapticFeedback.heavyImpact();
        t.cancel();
        checkForBarcodeValue();
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void checkForBarcodeValue() async {
    if (barcode?.barcodes != null) {
      if (widget.screenType == 'transfer') {
        await Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                ScanForTransfer(
              accType: widget.accType,
              authorization: widget.authorization,
              refreshToken: widget.refreshToken,
              controllerText: barcode?.barcodes.first.rawValue ?? '',
              crossVisible: widget.crossVisible,
              profileId: widget.profileId,
            ),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              const begin = Offset(1.0, 0.0);
              const end = Offset.zero;
              const curve = Curves.ease;

              var tween =
                  Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

              return SlideTransition(
                position: animation.drive(tween),
                child: child,
              );
            },
          ),
        );
      } else if (widget.screenType == 'pack and scan') {
        NavigationMethods.pushReplacement(
            context,
            PackAndScan(
              ean: barcode?.barcodes.first.rawValue ?? '',
              accType: widget.accType,
              authorization: widget.authorization,
              refreshToken: widget.refreshToken,
              crossVisible: false,
              screenType: widget.screenType,
              profileId: widget.profileId,
              distCenterId: widget.distCenterId,
              distCenterName: widget.distCenterName,
              barcodeToCheck: widget.barcodeToCheck,
            ));
      } else if (widget.screenType == 'jit order') {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                NewOrderScreenOne(
              ean: barcode?.barcodes.first.rawValue ?? '',
              isFiltered: true,
            ),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              const begin = Offset(1.0, 0.0);
              const end = Offset.zero;
              const curve = Curves.ease;

              var tween =
                  Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

              return SlideTransition(
                position: animation.drive(tween),
                child: child,
              );
            },
          ),
        );
      } else if (widget.screenType == 'picklist details') {
        if (int.parse(barcode?.barcodes.first.rawValue ?? '0') ==
            widget.barcodeToCheck) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              duration: Duration(milliseconds: 600),
              content: Text('Barcode Matched!'),
              backgroundColor: Colors.green,
            ),
          );
          await Future.delayed(const Duration(seconds: 1), () {
            Navigator.pop(context, true);
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              duration: Duration(milliseconds: 600),
              content: Text('Barcode Not Matched!'),
              backgroundColor: Colors.red,
            ),
          );
          await Future.delayed(const Duration(seconds: 1), () {
            Navigator.pop(context, false);
          });
        }
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetails(
              ean: barcode?.barcodes.first.rawValue ?? '',
              location: '',
              accType: widget.accType,
              authorization: widget.authorization,
              refreshToken: widget.refreshToken,
              profileId: widget.profileId,
              distCenterId: widget.distCenterId,
              distCenterName: widget.distCenterName,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: widget.screenType == 'picklist details'
          ? () async {
              Navigator.pop(context, false);
              return false;
            }
          : () async {
              return true;
            },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Builder(
          builder: (context) {
            return Stack(
              children: [
                MobileScanner(
                  controller: controller,
                  fit: BoxFit.fill,
                  onDetect: (barcode) {
                    setState(() {
                      this.barcode = barcode;
                    });
                  },
                ),
                Align(
                  alignment: Alignment.center,
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height,
                    width: MediaQuery.of(context).size.width,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ClipRect(
                          child: BackdropFilter(
                            filter:
                                ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                            child: SizedBox(
                              height: MediaQuery.of(context).size.height * .2,
                              width: MediaQuery.of(context).size.width,
                            ),
                          ),
                        ),
                        SizedBox(
                          height: MediaQuery.of(context).size.height * .4,
                          width: MediaQuery.of(context).size.width,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              ClipRect(
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(
                                      sigmaX: 10.0, sigmaY: 10.0),
                                  child: SizedBox(
                                    height:
                                        MediaQuery.of(context).size.height * .4,
                                    width:
                                        MediaQuery.of(context).size.width * .1,
                                  ),
                                ),
                              ),
                              Container(
                                height: MediaQuery.of(context).size.height * .4,
                                width: MediaQuery.of(context).size.width * .8,
                                decoration: BoxDecoration(
                                    border:
                                        Border.all(color: appColor, width: 5),
                                    borderRadius: BorderRadius.circular(20)),
                              ),
                              ClipRect(
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(
                                      sigmaX: 10.0, sigmaY: 10.0),
                                  child: SizedBox(
                                    height:
                                        MediaQuery.of(context).size.height * .4,
                                    width:
                                        MediaQuery.of(context).size.width * .1,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        ClipRect(
                          child: BackdropFilter(
                            filter:
                                ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                            child: SizedBox(
                              height: MediaQuery.of(context).size.height * .4,
                              width: MediaQuery.of(context).size.width,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(top: 15),
                                    child: GestureDetector(
                                      onTap: () async {
                                        final ImagePicker picker =
                                            ImagePicker();
                                        final XFile? image =
                                            await picker.pickImage(
                                          source: ImageSource.gallery,
                                        );
                                        if (image != null) {
                                          if (await controller
                                              .analyzeImage(image.path)) {
                                            if (!mounted) return;
                                            if (widget.screenType !=
                                                'picklist details') {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                  duration:
                                                      Duration(seconds: 1),
                                                  content:
                                                      Text('Barcode found!'),
                                                  backgroundColor: Colors.green,
                                                ),
                                              );
                                            }
                                          } else {
                                            if (!mounted) return;
                                            if (widget.screenType !=
                                                'picklist details') {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                  duration:
                                                      Duration(seconds: 1),
                                                  content:
                                                      Text('No barcode found!'),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                            }
                                          }
                                        }
                                      },
                                      child: Card(
                                        color: Colors.white,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(20)),
                                        child: SizedBox(
                                          height: MediaQuery.of(context)
                                                  .size
                                                  .height *
                                              .07,
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              .6,
                                          child: const Center(
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceEvenly,
                                              children: [
                                                Icon(Icons.image),
                                                Text(
                                                  'Scan from Gallery',
                                                  style:
                                                      TextStyle(fontSize: 16),
                                                )
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Visibility(
                                    visible: isLoaderVisible,
                                    child: SizedBox(
                                      height:
                                          MediaQuery.of(context).size.height *
                                              .2,
                                      width: MediaQuery.of(context).size.width,
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                          color: appColor,
                                        ),
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    alignment: Alignment.center,
                    height: 150,
                    color: Colors.transparent,
                    child: const Center(
                      child: Text(
                        'Scan any Barcode\n  (for EAN Value)',
                        style: TextStyle(color: Colors.white, fontSize: 22),
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    alignment: Alignment.bottomCenter,
                    height: 100,
                    color: Colors.black.withOpacity(0.4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ValueListenableBuilder(
                          valueListenable: controller.torchState,
                          builder: (context, state, child) {
                            return IconButton(
                              color: Colors.white,
                              icon: ValueListenableBuilder(
                                valueListenable: controller.torchState,
                                builder: (context, state, child) {
                                  if (state == null) {
                                    return const Icon(
                                      Icons.flash_off,
                                      color: Colors.white,
                                    );
                                  }
                                  switch (state as TorchState) {
                                    case TorchState.off:
                                      return const Icon(
                                        Icons.flash_off,
                                        color: Colors.white,
                                      );
                                    case TorchState.on:
                                      return const Icon(
                                        Icons.flash_on,
                                        color: Colors.yellow,
                                      );
                                  }
                                },
                              ),
                              iconSize: 32.0,
                              onPressed: () => controller.toggleTorch(),
                            );
                          },
                        ),
                        IconButton(
                          color: Colors.white,
                          icon: ValueListenableBuilder(
                            valueListenable: controller.cameraFacingState,
                            builder: (context, state, child) {
                              if (state == null) {
                                return const Icon(Icons.camera_front);
                              }
                              switch (state as CameraFacing) {
                                case CameraFacing.front:
                                  return const Icon(Icons.camera_front);
                                case CameraFacing.back:
                                  return const Icon(Icons.camera_rear);
                              }
                            },
                          ),
                          iconSize: 32.0,
                          onPressed: () => controller.switchCamera(),
                        ),
                      ],
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: IconButton(
                      onPressed: () {
                        widget.screenType == 'picklist details'
                            ? Navigator.pop(context, false)
                            : Navigator.pop(context);
                      },
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                      ),
                      iconSize: 30,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
