import 'dart:convert';
import 'dart:developer';

import 'package:absolute_app/core/apis/api_calls.dart';
import 'package:absolute_app/core/utils/constants.dart';
import 'package:absolute_app/core/utils/toast_utils.dart';
import 'package:absolute_app/models/get_printers_list_response.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:parse_server_sdk/parse_server_sdk.dart';
import 'package:rounded_loading_button/rounded_loading_button.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class PrintNodeSettingsWeb extends StatefulWidget {
  const PrintNodeSettingsWeb({super.key, required this.userId});

  final String userId;

  @override
  State<PrintNodeSettingsWeb> createState() => _PrintNodeSettingsWebState();
}

class _PrintNodeSettingsWebState extends State<PrintNodeSettingsWeb> {
  final RoundedLoadingButtonController saveValuesController =
      RoundedLoadingButtonController();
  final RoundedLoadingButtonController getPrintersController =
      RoundedLoadingButtonController();
  final TextEditingController apiKeyController = TextEditingController();
  final FocusNode apiKeyFocus = FocusNode();

  List<ParseObject> printNodeData = [];
  List<GetPrintersListResponse> printersList = [];

  bool isLoading = false;
  bool isError = false;
  bool isAPIKeyChanged = false;
  bool isPrintersFound = false;

  String error = '';
  String? selectedPrinter;
  String apiKeyBeforeChange = '';

  @override
  void initState() {
    super.initState();
    printNodeAPICalls();
  }

  void printNodeAPICalls() async {
    setState(() {
      isLoading = true;
      isError = false;
    });
    await getPrintNodeData().whenComplete(() async {
      await getPrintersList(apiKey: apiKeyController.text);
    }).whenComplete(() async {
      await getSelectedPrinter();
    }).whenComplete(() {
      setState(() {
        isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.white,
        automaticallyImplyLeading: true,
        iconTheme: const IconThemeData(color: Colors.black),
        centerTitle: true,
        toolbarHeight: AppBar().preferredSize.height,
        elevation: 5,
        title: const Text(
          'PrintNode Settings',
          style: TextStyle(fontSize: 25, color: Colors.black),
        ),
      ),
      body: isLoading == true
          ? SizedBox(
              height: size.height,
              width: size.width,
              child: const Center(
                child: CircularProgressIndicator(color: appColor),
              ),
            )
          : isError == true
              ? SizedBox(
                  height: size.height,
                  width: size.width,
                  child: Center(
                    child: Text(error, style: const TextStyle(fontSize: 16)),
                  ),
                )
              : SizedBox(
                  height: size.height,
                  width: size.width,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 35,
                      vertical: 10,
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          _apiKeyBuilder(context, size),
                          _printersListBuilder(context, size),
                          _getPrintersBuilder(context, size),
                          _bottomBuilder(context, size)
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }

  /// BUILDER WIDGETS
  Widget _apiKeyBuilder(BuildContext context, Size size) {
    return Padding(
      padding: const EdgeInsets.only(top: 10.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PrintNode API Key',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: SizedBox(
              height: 40,
              width: size.width,
              child: TextFormField(
                  controller: apiKeyController,
                  focusNode: apiKeyFocus,
                  style: const TextStyle(fontSize: 18),
                  decoration: InputDecoration(
                    hintText: 'Enter API Key here',
                    hintStyle: const TextStyle(fontSize: 18),
                    contentPadding: const EdgeInsets.only(left: 14),
                    border: OutlineInputBorder(
                      borderSide: const BorderSide(width: 0.5),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: appColor, width: 1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (value) {
                    setState(() {
                      isAPIKeyChanged =
                          value != apiKeyBeforeChange ? true : false;
                    });
                  }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _printersListBuilder(BuildContext context, Size size) {
    return Visibility(
      visible: !isAPIKeyChanged,
      child: Padding(
        padding: const EdgeInsets.only(top: 20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Printer To Be Used for Label Printing',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: SizedBox(
                height: 40,
                width: size.width,
                child: DropdownButtonHideUnderline(
                  child: DropdownButton2<String>(
                    isExpanded: true,
                    hint: const Text(
                      'Select a Printer',
                      style: TextStyle(fontSize: 18),
                    ),
                    items: printersList.map((e) => e.name).toList().map(
                      (String item) {
                        return DropdownMenuItem<String>(
                          value: item,
                          child: Text(
                            item,
                            style: const TextStyle(fontSize: 18),
                          ),
                        );
                      },
                    ).toList(),
                    value: selectedPrinter,
                    onChanged: (value) async {
                      setState(() {
                        selectedPrinter = value ?? printersList[0].name;
                      });
                      log('V selectedPrinter >>---> $selectedPrinter');
                    },
                    buttonStyleData: ButtonStyleData(
                      height: 40,
                      width: size.width - 70,
                      padding: const EdgeInsets.only(left: 14, right: 14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.black26),
                        color: Colors.white,
                      ),
                    ),
                    dropdownStyleData: DropdownStyleData(
                      maxHeight: 200,
                      width: size.width - 70,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      scrollbarTheme: ScrollbarThemeData(
                        radius: const Radius.circular(40),
                        thickness: MaterialStateProperty.all<double>(6),
                        thumbVisibility: MaterialStateProperty.all<bool>(true),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _getPrintersBuilder(BuildContext context, Size size) {
    return Visibility(
      visible: isAPIKeyChanged,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Padding(padding: EdgeInsets.only(top: 30), child: Divider()),
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: RoundedLoadingButton(
              color: Colors.lightBlue,
              borderRadius: 14,
              height: 45,
              width: 180,
              successIcon: Icons.check_rounded,
              failedIcon: Icons.close_rounded,
              successColor: Colors.green,
              controller: getPrintersController,
              onPressed: () async {
                apiKeyFocus.unfocus();
                if (apiKeyController.text.isNotEmpty) {
                  await getPrintersList(apiKey: apiKeyController.text)
                      .whenComplete(() async {
                    if (isPrintersFound) {
                      setState(() {
                        isLoading = true;
                        isError = false;
                      });
                      await saveSelectedPrinter(
                        selectedPrinter: null,
                        selectedPrinterId: 0,
                      ).whenComplete(() async {
                        await getSelectedPrinter();
                      }).whenComplete(() async {
                        await savePrintNodeData(
                          apiKey: apiKeyController.text.toString(),
                          userId: widget.userId,
                        );
                      }).whenComplete(() async {
                        await getPrintNodeData();
                      }).whenComplete(() {
                        setState(() {
                          isAPIKeyChanged = false;
                        });
                      });
                    } else {
                      apiKeyFocus.requestFocus();
                    }
                  }).whenComplete(() {
                    setState(() {
                      isLoading = false;
                    });
                    getPrintersController.reset();
                  });
                } else {
                  ToastUtils.motionToastCentered1500MS(
                    message: 'Please enter a valid PrintNode API Key',
                    context: context,
                  );
                  apiKeyFocus.requestFocus();
                  getPrintersController.reset();
                }
              },
              child: const Text(
                'Get Printers List',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomBuilder(BuildContext context, Size size) {
    return Visibility(
      visible: !isAPIKeyChanged,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Padding(padding: EdgeInsets.only(top: 40), child: Divider()),
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: RoundedLoadingButton(
              color: Colors.green,
              borderRadius: 14,
              height: 45,
              width: 160,
              successIcon: Icons.check_rounded,
              failedIcon: Icons.close_rounded,
              successColor: Colors.green,
              controller: saveValuesController,
              onPressed: () async {
                if (selectedPrinter != null) {
                  if (apiKeyController.text.isNotEmpty) {
                    await savePrintNodeData(
                      apiKey: apiKeyController.text.toString(),
                      userId: widget.userId,
                    ).whenComplete(() async {
                      await saveSelectedPrinter(
                        selectedPrinter: selectedPrinter,
                        selectedPrinterId: printersList[printersList
                                .indexWhere((e) => e.name == selectedPrinter)]
                            .id,
                      );
                    }).whenComplete(() async {
                      await getPrintNodeData();
                    }).whenComplete(() async {
                      await getSelectedPrinter();
                    }).whenComplete(() {
                      ToastUtils.motionToastCentered1500MS(
                        message: 'Changes Saved Successfully',
                        context: context,
                      );
                      saveValuesController.reset();
                    });
                  } else {
                    ToastUtils.motionToastCentered1500MS(
                      message: 'Please enter a valid PrintNode API Key',
                      context: context,
                    );
                    saveValuesController.reset();
                  }
                } else {
                  ToastUtils.motionToastCentered1500MS(
                    message: 'Please Select a Printer first',
                    context: context,
                  );
                  saveValuesController.reset();
                }
              },
              child: const Text(
                'Save Changes',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// API METHODS

  Future<void> getPrintersList({required String apiKey}) async {
    setState(() {
      isPrintersFound = false;
    });
    String uri = 'https://api.printnode.com/printers';

    log('GET PRINTERS LIST API URI >>---> $uri');
    log('ENCODED API KEY >>---> ${base64.encode(utf8.encode(apiKey))}');

    var header = {
      "Authorization": "Basic ${base64.encode(utf8.encode(apiKey))}"
    };

    try {
      var response = await http.get(Uri.parse(uri), headers: header).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          ToastUtils.motionToastCentered1500MS(
              message: kTimeOut, context: context);
          setState(() {
            isPrintersFound = false;
          });
          return http.Response('Error', 408);
        },
      );
      log('GET PRINTERS LIST API STATUS CODE >>---> ${response.statusCode}');
      if (response.statusCode == 200) {
        log('GET PRINTERS LIST API RESPONSE >>---> ${response.body}');

        printersList = [];
        printersList.addAll(
            getPrintersListResponseFromJson(response.body).map((e) => e));
        log('V printersList >>---> ${jsonEncode(printersList)}');
        setState(() {
          isPrintersFound = true;
        });
      } else {
        if (!mounted) return;
        ToastUtils.motionToastCentered1500MS(
          message: jsonDecode(response.body)['message'].toString(),
          context: context,
        );
        setState(() {
          isPrintersFound = false;
        });
      }
    } catch (e) {
      log("GET PRINTERS LIST API EXCEPTION >>---> ${e.toString()}");
      ToastUtils.motionToastCentered1500MS(
          message: e.toString(), context: context);
      setState(() {
        isPrintersFound = false;
      });
    }
  }

  Future<void> getPrintNodeData() async {
    await ApiCalls.getPrintNodeData().then((data) {
      if (data.isEmpty) {
        setState(() {
          isError = true;
          error = 'Error in fetching PrintNode Data. Please try again!';
        });
      } else {
        printNodeData = [];
        printNodeData.addAll(data.map((e) => e));
        log('V printNodeData >>---> $printNodeData');

        setState(() {
          apiKeyController.text = printNodeData[0].get<String>('api_key') ?? '';
          apiKeyBeforeChange = printNodeData[0].get<String>('api_key') ?? '';
        });
        log('V apiKeyController.text >>---> ${apiKeyController.text}');
        log('V apiKeyBeforeChange >>---> $apiKeyBeforeChange');
      }
    });
  }

  Future<void> savePrintNodeData({
    required String apiKey,
    required String userId,
  }) async {
    var printNodeDataToSave = ParseObject('PrintNodeData')
      ..objectId = 'XOmhiwvKGg'
      ..set('api_key', apiKey)
      ..set('user_id', userId);

    await printNodeDataToSave.save();
  }

  Future<void> getSelectedPrinter() async {
    await SharedPreferences.getInstance().then((prefs) {
      if (prefs.getString('selectedPrinter') == null ||
          prefs.getString('selectedPrinter') == 'null') {
        /// MEANS
        /// 1. EITHER API KEY IS CHANGED AFTER COMING TO PRINT NODE SCREEN. OR
        /// 2. NO PRINTER IS SAVED YET AFTER SELECTING IT FROM THE LIST.
        ///
        /// SAVING [selectedPrinter] TO NULL >>> WILL SHOW HINT TEXT.
        setState(() {
          selectedPrinter = null;
        });
      } else {
        /// SOME PRINTER IS SAVED PREVIOUSLY.
        /// CHECK WHETHER API KEY IS CHANGED AFTER COMING TO THE SCREEN.
        if (isAPIKeyChanged) {
          /// SAVING [selectedPrinter] TO NULL >>> WILL SHOW HINT TEXT.
          setState(() {
            selectedPrinter = null;
          });
        } else {
          setState(() {
            selectedPrinter = prefs.getString('selectedPrinter');
          });
        }
      }
    });
  }

  Future<void> saveSelectedPrinter({
    required String? selectedPrinter,
    required int selectedPrinterId,
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('selectedPrinter', selectedPrinter ?? 'null');
    prefs.setInt('selectedPrinterId', selectedPrinterId);
  }
}
