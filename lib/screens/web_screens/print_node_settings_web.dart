import 'dart:convert';
import 'dart:developer';

import 'package:absolute_app/core/apis/api_calls.dart';
import 'package:absolute_app/core/utils/constants.dart';
import 'package:absolute_app/core/utils/toast_utils.dart';
import 'package:absolute_app/models/get_printers_list_response.dart';
import 'package:animated_custom_dropdown/custom_dropdown.dart';
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
  final TextEditingController apiKeyController = TextEditingController();
  final TextEditingController selectedPrinterController =
      TextEditingController();

  List<ParseObject> printNodeData = [];
  List<GetPrintersListResponse> printersList = [];

  bool isLoading = false;
  bool isError = false;

  String error = '';
  String selectedPrinter = '';

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
      await getPrintersList(
        apiKey: apiKeyController.text,
      );
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
          style: TextStyle(
            fontSize: 25,
            color: Colors.black,
          ),
        ),
      ),
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
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                )
              : SizedBox(
                  height: size.height,
                  width: size.width,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          _apiKeyBuilder(context, size),
                          _printersListBuilder(context, size),
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
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 10.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                'PrintNode API Key',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              )
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: SizedBox(
                    height: 35,
                    width: size.width,
                    child: TextFormField(
                      controller: apiKeyController,
                      style: const TextStyle(
                        fontSize: 16,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Enter API Key here',
                        hintStyle: TextStyle(
                          fontSize: 16,
                        ),
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
                      onChanged: (_) {},
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _printersListBuilder(BuildContext context, Size size) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                'Select Printer To Be Used for Label Printing',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              )
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 5.0),
            child: SizedBox(
              height: 35,
              width: size.width,
              child: CustomDropdown(
                items: printersList.map((e) => e.name).toList(),
                controller: selectedPrinterController,
                hintText: 'Select a Printer',
                selectedStyle: const TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                ),
                borderRadius: BorderRadius.circular(5),
                borderSide: BorderSide(
                  color: Colors.grey[700]!,
                  width: 1,
                ),
                excludeSelected: true,
                onChanged: (_) {
                  setState(() {
                    selectedPrinter = selectedPrinterController.text;
                  });
                  log('V selectedPrinterController.text >>---> ${selectedPrinterController.text}');
                  log('V selectedPrinter >>---> $selectedPrinter');
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomBuilder(BuildContext context, Size size) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 40),
          child: Divider(),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: SizedBox(
            height: 35,
            width: 300,
            child: RoundedLoadingButton(
              color: Colors.green,
              borderRadius: 10,
              height: 50,
              width: 160,
              successIcon: Icons.check_rounded,
              failedIcon: Icons.close_rounded,
              successColor: Colors.green,
              controller: saveValuesController,
              onPressed: () async {
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
              },
              child: const Text(
                'Save Changes',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// API METHODS

  Future<void> getPrintersList({required String apiKey}) async {
    setState(() {
      isError = false;
      error = '';
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
            message: kTimeOut,
            context: context,
          );
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
          isError = false;
          error = '';
        });
      } else {
        if(!mounted) return;
        ToastUtils.motionToastCentered1500MS(
          message: kerrorString,
          context: context,
        );
        setState(() {
          isError = true;
          error = kerrorString;
        });
      }
    } catch (e) {
      log("GET PRINTERS LIST API EXCEPTION >>---> ${e.toString()}");
      setState(() {
        isError = true;
        error = e.toString();
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
        });
        log('V apiKeyController.text >>---> ${apiKeyController.text}');
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
      setState(() {
        selectedPrinterController.text =
            prefs.getString('selectedPrinter') ?? '';
        selectedPrinter = prefs.getString('selectedPrinter') ?? '';
      });
    });
  }

  Future<void> saveSelectedPrinter({
    required String selectedPrinter,
    required int selectedPrinterId,
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('selectedPrinter', selectedPrinter);
    prefs.setInt('selectedPrinterId', selectedPrinterId);
  }
}
