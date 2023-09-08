import 'dart:convert';
import 'dart:developer';

import 'package:absolute_app/core/apis/api_calls.dart';
import 'package:absolute_app/core/utils/constants.dart';
import 'package:absolute_app/core/utils/responsive_check.dart';
import 'package:absolute_app/core/utils/common_screen_widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:parse_server_sdk/parse_server_sdk.dart';
import 'package:rounded_loading_button/rounded_loading_button.dart';

class EditRule extends StatefulWidget {
  const EditRule({
    Key? key,
    required this.objectId,
    required this.ruleName,
    required this.isActive,
    required this.conditionItem,
    required this.conditionType,
    required this.conditionValue,
    required this.shipFrom,
    required this.carrier,
    required this.service,
    required this.packageType,
    required this.addressVTN,
    required this.addresseeIRN,
    required this.classX,
    required this.guarantee,
    required this.lc,
    required this.lcLocationNameValue,
    required this.lcLocationTypeValue,
    required this.notification,
    required this.safePlace,
    required this.serviceLevelValue,
    required this.parcelShape,
    required this.postalChargesValue,
    required this.satDelivery,
    required this.signedConsignment,
    required this.dgMedicine,
    required this.dgPerfume,
    required this.dgNail,
    required this.dgToiletry,
    required this.customInvoice,
    required this.destinationTax,
    required this.ecd,
    required this.liability,
    required this.preCleared,
    required this.recipientNotification,
    required this.iossNumber,
    required this.copiedFrom,
  }) : super(key: key);

  final String objectId;
  final String ruleName;
  final String isActive;
  final List<dynamic> conditionItem;
  final List<dynamic> conditionType;
  final List<dynamic> conditionValue;
  final String shipFrom;
  final String carrier;
  final String service;
  final String packageType;
  final String addressVTN;
  final String addresseeIRN;
  final String classX;
  final String guarantee;
  final String lc;
  final String lcLocationNameValue;
  final String lcLocationTypeValue;
  final String notification;
  final String safePlace;
  final String serviceLevelValue;
  final String parcelShape;
  final String postalChargesValue;
  final String satDelivery;
  final String signedConsignment;
  final String dgMedicine;
  final String dgPerfume;
  final String dgNail;
  final String dgToiletry;
  final String customInvoice;
  final String destinationTax;
  final String ecd;
  final String liability;
  final String preCleared;
  final String recipientNotification;
  final String iossNumber;
  final String copiedFrom;

  @override
  State<EditRule> createState() => _EditRuleState();
}

class _EditRuleState extends State<EditRule> {
  final RoundedLoadingButtonController saveRuleController =
      RoundedLoadingButtonController();
  final RoundedLoadingButtonController removeRuleController =
      RoundedLoadingButtonController();
  final RoundedLoadingButtonController cancelController =
      RoundedLoadingButtonController();
  final RoundedLoadingButtonController yesController =
      RoundedLoadingButtonController();
  final RoundedLoadingButtonController noController =
      RoundedLoadingButtonController();

  late TextEditingController ruleNameController;
  late List<TextEditingController> valueForCondController;
  late TextEditingController addresseeIdentificationController;
  late TextEditingController lcLocationNameController;
  late TextEditingController lcLocationTypeController;
  late TextEditingController postalChargesController;
  late TextEditingController serviceLevelCodeController;
  late TextEditingController destinationTaxController;
  late TextEditingController iossController;

  int noOfConditionsToShow = 0;

  Color color1 = const Color.fromARGB(255, 238, 238, 238);
  Color color2 = const Color.fromARGB(255, 245, 245, 245);
  Color color3 = const Color.fromARGB(255, 255, 255, 255);
  Color color4 = const Color.fromARGB(255, 229, 229, 229);

  bool errorVisible = false;
  bool isLoading = true;
  bool isActiveChecked = true;
  bool isHideService = false;
  bool isBorderForEnhancementButton = false;

  List<ParseObject> shippingRulesFromDB = [];
  List<String> itemsToBeConditionedDDValue = [];
  List<String> conditionsTypeDDValue = [];
  List<String> itemsToBeConditionedNames = [];
  List<List<String>> listOfItemsToBeConditionedNames = [];
  List<List<dynamic>> conditionsList = <List<dynamic>>[];
  List<String> shipFrom = [];
  List<String> carrier = [];
  List<String> services = [];
  List<String> servicesForIndexing = [];
  List<String> serviceType = [];
  List<String> packageTypeVisible = [];
  List<List<dynamic>> packageType = <List<dynamic>>[];
  List<String> virtualTrackingVisible = [];
  List<List<dynamic>> virtualTracking = <List<dynamic>>[];
  List<String> addressIdentificationVisible = [];
  List<String> classVisible = [];
  List<List<dynamic>> classX = <List<dynamic>>[];
  List<String> guaranteeVisible = [];
  List<List<dynamic>> guarantee = <List<dynamic>>[];
  List<String> localCollectVisible = [];
  List<List<dynamic>> localCollect = <List<dynamic>>[];
  List<String> lcLocationNameVisible = [];
  List<String> lcLocationTypeVisible = [];
  List<String> notificationTypeVisible = [];
  List<List<dynamic>> notificationType = <List<dynamic>>[];
  List<String> safePlaceVisible = [];
  List<List<dynamic>> safePlace = <List<dynamic>>[];
  List<String> parcelShapeVisible = [];
  List<List<dynamic>> parcelShape = <List<dynamic>>[];
  List<String> postalChargesVisible = [];
  List<String> satDeliveryVisible = [];
  List<List<dynamic>> satDelivery = <List<dynamic>>[];
  List<String> serviceLevelCodeVisible = [];
  List<String> signedConsignmentVisible = [];
  List<List<dynamic>> signedConsignment = <List<dynamic>>[];
  List<String> dgMedicinesVisible = [];
  List<List<dynamic>> dgMedicines = <List<dynamic>>[];
  List<String> dgPerfumeVisible = [];
  List<List<dynamic>> dgPerfume = <List<dynamic>>[];
  List<String> dgNailVisible = [];
  List<List<dynamic>> dgNail = <List<dynamic>>[];
  List<String> dgToiletryVisible = [];
  List<List<dynamic>> dgToiletry = <List<dynamic>>[];

  /// 4 JUNE, 2023 CHANGES FOR DPD CARRIER
  List<String> customInvoiceVisible = [];
  List<List<dynamic>> customInvoice = <List<dynamic>>[];
  List<String> destinationTaxVisible = [];
  List<String> ecdVisible = [];
  List<List<dynamic>> ecd = <List<dynamic>>[];
  List<String> liabilityVisible = [];
  List<List<dynamic>> liability = <List<dynamic>>[];
  List<String> preClearedVisible = [];
  List<List<dynamic>> preCleared = <List<dynamic>>[];
  List<String> recipientNotificationVisible = [];
  List<List<dynamic>> recipientNotification = <List<dynamic>>[];

  /// CONDITIONS LIST TO SAVE TO DB IF ANY EDITS ARE DONE - WHILE SAVE RULE BUTTON IS TAPPED.
  List<String> conditionValueSave = [];

  String carrierValue = '';
  String shipFromDDValue = '';
  String servicesDDValue = '';
  String packageTypeDDValue = '';
  String virtualTrackingDDValue = '';
  String classDDValue = '';
  String guaranteeValue = '';
  String localCollectValue = '';
  String notificationTypeValue = '';
  String safePlaceValue = '';
  String parcelShapeValue = '';
  String satDeliveryValue = '';
  String signedConsignmentValue = '';
  String dgMedicinesValue = '';
  String dgPerfumeValue = '';
  String dgNailValue = '';
  String dgToiletryValue = '';

  /// CHANGES FOR DPD CARRIER - 04 JUNE, 2023
  String customInvoiceValue = '';
  String ecdValue = '';
  String liabilityValue = '';
  String preClearedValue = '';
  String recipientNotificationValue = '';

  @override
  void initState() {
    super.initState();
    ruleNameController = TextEditingController();
    valueForCondController = widget.conditionValue.map((value) {
      return TextEditingController(text: value);
    }).toList();
    addresseeIdentificationController = TextEditingController();
    lcLocationNameController = TextEditingController();
    lcLocationTypeController = TextEditingController();
    postalChargesController = TextEditingController();
    serviceLevelCodeController = TextEditingController();
    destinationTaxController = TextEditingController();
    iossController = TextEditingController();

    conditionValueSave = List.generate(widget.conditionValue.length,
        (index) => widget.conditionValue[index].toString());

    loadingShippingRulesData();
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    FocusScopeNode currentFocus = FocusScope.of(context);
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, false);
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          backgroundColor: Colors.white,
          automaticallyImplyLeading: true,
          iconTheme: const IconThemeData(color: Colors.black),
          centerTitle: true,
          toolbarHeight: AppBar().preferredSize.height,
          title: Text(
            'Edit Rule',
            style: TextStyle(fontSize: size.height * .03, color: Colors.black),
          ),
        ),
        body: isLoading == true
            ? const Center(child: CircularProgressIndicator(color: appColor))
            : errorVisible == true
                ? const Center(
                    child: Text(
                      'Internet may not be available, Please check your connection and Restart the app',
                    ),
                  )
                : GestureDetector(
                    onTap: () {
                      FocusScope.of(context).requestFocus(FocusNode());
                      if (!currentFocus.hasPrimaryFocus) {
                        currentFocus.unfocus();
                      }
                      setState(() {
                        isBorderForEnhancementButton = false;
                      });
                    },
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: size.height * .015,
                          horizontal: size.width * .035,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            _ruleNameBuilder(context, size),
                            verticalSpacer(context, size.height * .035),
                            _conditionsOuterBuilder(context, size),
                            verticalSpacer(context, size.height * .035),
                            _shippingBuilder(context, size),
                          ],
                        ),
                      ),
                    ),
                  ),
      ),
    );
  }

  Widget _ruleNameBuilder(BuildContext context, Size size) {
    return LayoutBuilder(builder: (_, c) {
      final width = c.maxWidth;
      double tFontSize = 16.0;
      double stFontSize = 10.0;
      if (width <= 480) {
        tFontSize = 16.0;
        stFontSize = 10.0;
      } else if (width > 480 && width <= 960) {
        tFontSize = 20.0;
        stFontSize = 13.0;
      } else {
        tFontSize = 24.0;
        stFontSize = 16.0;
      }
      return Container(
        height: size.height * .22,
        width: size.width,
        color: color1,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(
                left: size.width * .025,
                right: size.width * .05,
                top: size.height * .02,
                bottom: size.height * .02,
              ),
              child: Row(
                children: [
                  Text(
                    'Rule Name',
                    style: TextStyle(fontSize: tFontSize, color: Colors.black),
                  )
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.only(left: size.width * .025),
              child: SizedBox(
                height: size.height * .03,
                width: size.width,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text('Name', style: TextStyle(fontSize: stFontSize)),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(
                left: size.width * .025,
                right: size.width * .05,
                top: size.width * .005,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(
                    height: size.height * .04,
                    width: size.width * .5,
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: ThemeData().colorScheme.copyWith(
                              primary: appColor,
                            ),
                      ),
                      child: TextFormField(
                        controller: ruleNameController,
                        textAlignVertical: TextAlignVertical.top,
                        cursorColor: appColor,
                        style: TextStyle(
                          fontSize: stFontSize,
                          color: Colors.black,
                        ),
                        decoration: InputDecoration(
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 10),
                          enabledBorder: const OutlineInputBorder(
                            borderSide: BorderSide(
                              width: 0.25,
                              color: Colors.grey,
                            ),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderSide: BorderSide(color: appColor, width: 0.5),
                          ),
                          filled: true,
                          fillColor: color3,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.only(
                left: size.width * .02,
                top: size.height * .005,
              ),
              child: SizedBox(
                height: size.height * .05,
                width: size.width,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Checkbox(
                      activeColor: appColor,
                      value: isActiveChecked,
                      onChanged: (bool? newValue) {
                        setState(() {
                          isActiveChecked = newValue!;
                        });
                        log('isActiveChecked - $isActiveChecked');
                      },
                    ),
                    Text('Active', style: TextStyle(fontSize: stFontSize))
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _conditionsOuterBuilder(BuildContext context, Size size) {
    return LayoutBuilder(builder: (_, c) {
      final width = c.maxWidth;
      double tFontSize = 16.0;
      double stFontSize = 10.0;
      double buttonWidth = 100.0;
      if (width <= 480) {
        tFontSize = 16.0;
        stFontSize = 10.0;
        buttonWidth = 100.0;
      } else if (width > 480 && width <= 960) {
        tFontSize = 20.0;
        stFontSize = 13.0;
        buttonWidth = 130.0;
      } else {
        tFontSize = 24.0;
        stFontSize = 16.0;
        buttonWidth = 160.0;
      }
      return Container(
        color: color1,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(
                left: size.width * .025,
                right: size.width * .05,
                top: size.height * .02,
              ),
              child: SizedBox(
                height: size.height * .03,
                width: size.width,
                child: Text(
                  'Conditions',
                  style: TextStyle(
                    fontSize: tFontSize,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(
                left: size.width * .025,
                top: size.height * .02,
                right: size.width * .025,
              ),
              child: Column(
                children: _conditionsInnerBuilder(context, size),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(
                right: size.width * .005,
                bottom: size.height * .02,
              ),
              child: SizedBox(
                height: size.height * .04,
                width: size.width,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Visibility(
                      visible: noOfConditionsToShow <
                          itemsToBeConditionedNames.length,
                      child: Padding(
                        padding: EdgeInsets.only(right: size.width * .02),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.lightGreen,
                            minimumSize: Size.zero,
                            padding: const EdgeInsets.all(5),
                          ),
                          onPressed: () {
                            setState(() {
                              noOfConditionsToShow = noOfConditionsToShow + 1;
                            });

                            itemsToBeConditionedDDValue.add('None');

                            /// FOR 'LIST OF ITEMS TO BE CONDITIONED NAMES' ----------- START
                            for (int i = 0;
                                i < itemsToBeConditionedDDValue.length;
                                i++) {
                              itemsToBeConditionedNames.removeWhere(
                                  (e) => e == itemsToBeConditionedDDValue[i]);
                            }

                            listOfItemsToBeConditionedNames = [];

                            for (int i = 0;
                                i < itemsToBeConditionedDDValue.length;
                                i++) {
                              List<String> tempList = [];
                              tempList.addAll(
                                  itemsToBeConditionedNames.map((e) => e));
                              tempList.add(itemsToBeConditionedDDValue[i]);
                              listOfItemsToBeConditionedNames.add(tempList);
                              tempList = [];
                              setState(() {});
                            }

                            itemsToBeConditionedNames = [];
                            itemsToBeConditionedNames.addAll(
                                shippingRulesFromDB.map((e) =>
                                    e.get<String>(
                                        'items_to_be_conditioned_names') ??
                                    ''));
                            itemsToBeConditionedNames
                                .removeWhere((e) => e == 'empty');
                            log('itemsToBeConditionedNames - $itemsToBeConditionedNames');

                            /// FOR 'LIST OF ITEMS TO BE CONDITIONED NAMES' ----------- END

                            setState(() {
                              conditionsTypeDDValue
                                  .add('--- choose a condition ---');
                              valueForCondController
                                  .add(TextEditingController(text: ''));
                              conditionValueSave.add('');
                            });
                          },
                          child: SizedBox(
                            height: size.height * .045,
                            width: buttonWidth,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add,
                                  color: Colors.white,
                                  size: stFontSize,
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(left: 5),
                                  child: Text(
                                    'Add a Condition',
                                    style: TextStyle(
                                      fontSize: stFontSize,
                                    ),
                                  ),
                                ),
                              ],
                            ),
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
      );
    });
  }

  Widget _singleInnerBuilder(int index, BuildContext context, Size size) {
    return LayoutBuilder(builder: (_, c) {
      final width = c.maxWidth;
      double ddWidth = size.width * .3;
      double stFontSize = 10.0;
      double fieldFontSize = 8.0;
      double buttonWidth = 50.0;
      if (width <= 480) {
        ddWidth = size.width * .24;
        stFontSize = 10.0;
        fieldFontSize = 8.0;
        buttonWidth = 55.0;
      } else if (width > 480 && width <= 960) {
        ddWidth = size.width * .24;
        stFontSize = 13.0;
        fieldFontSize = 10.0;
        buttonWidth = 70.0;
      } else {
        ddWidth = size.width * .2;
        stFontSize = 16.0;
        fieldFontSize = 16.0;
        buttonWidth = 85.0;
      }
      return Column(
        children: [
          Container(
            height: size.height * .08,
            width: size.width,
            decoration: BoxDecoration(
              color: color2,
              border: Border.all(
                width: 0.25,
                color: Colors.grey,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(
                  height: size.height * .08,
                  width: size.width * .78 - buttonWidth,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(left: size.width * .01),
                        child: Container(
                          height: size.height * .04,
                          width: ddWidth,
                          decoration: BoxDecoration(
                            color: color3,
                            border: Border.all(
                              width: 0.25,
                              color: Colors.grey,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.only(left: 10),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton(
                                elevation: 0,
                                value: itemsToBeConditionedDDValue[index],
                                icon: SizedBox(
                                  height: 25,
                                  width: 25,
                                  child: FittedBox(
                                    child: Image.asset(
                                        'assets/add_new_rule_assets/dd_icon.png'),
                                  ),
                                ),
                                items: listOfItemsToBeConditionedNames[index]
                                    .map(
                                      (value) => DropdownMenuItem(
                                        value: value,
                                        child: Text(
                                          value,
                                          style: TextStyle(
                                            fontSize: fieldFontSize,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (Object? newValue) {
                                  setState(() {
                                    itemsToBeConditionedDDValue[index] =
                                        newValue as String;
                                  });

                                  /// Start Re-setup of conditions to show in various dropdowns >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
                                  for (int i = 0;
                                      i < itemsToBeConditionedDDValue.length;
                                      i++) {
                                    itemsToBeConditionedNames.removeWhere((e) =>
                                        e == itemsToBeConditionedDDValue[i]);
                                  }

                                  listOfItemsToBeConditionedNames = [];

                                  for (int i = 0;
                                      i < itemsToBeConditionedDDValue.length;
                                      i++) {
                                    List<String> tempList = [];
                                    tempList.addAll(itemsToBeConditionedNames
                                        .map((e) => e));
                                    tempList
                                        .add(itemsToBeConditionedDDValue[i]);
                                    listOfItemsToBeConditionedNames
                                        .add(tempList);
                                    tempList = [];
                                    setState(() {});
                                  }

                                  itemsToBeConditionedNames = [];
                                  itemsToBeConditionedNames.addAll(
                                      shippingRulesFromDB.map((e) =>
                                          e.get<String>(
                                              'items_to_be_conditioned_names') ??
                                          ''));
                                  itemsToBeConditionedNames
                                      .removeWhere((e) => e == 'empty');
                                  log('itemsToBeConditionedNames - $itemsToBeConditionedNames');

                                  /// End Re-setup of conditions to show in various dropdowns >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

                                  setState(() {
                                    conditionsTypeDDValue[index] =
                                        conditionsList[
                                            itemsToBeConditionedNames.indexOf(
                                                itemsToBeConditionedDDValue[
                                                    index])][0];
                                  });

                                  valueForCondController[index].clear();

                                  log('itemsToBeConditionedDDValue at $index >>>>> ${itemsToBeConditionedDDValue[index]}');
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                      Visibility(
                        visible: itemsToBeConditionedDDValue[index] != 'None',
                        child: Padding(
                          padding: EdgeInsets.only(left: size.width * .01),
                          child: Container(
                            height: size.height * .04,
                            width: ddWidth,
                            decoration: BoxDecoration(
                              color: color3,
                              border: Border.all(
                                width: 0.25,
                                color: Colors.grey,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.only(left: 10),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton(
                                  elevation: 0,
                                  value: conditionsTypeDDValue[index],
                                  icon: SizedBox(
                                    height: 25,
                                    width: 25,
                                    child: FittedBox(
                                      child: Image.asset(
                                          'assets/add_new_rule_assets/dd_icon.png'),
                                    ),
                                  ),
                                  items: conditionsList[
                                          itemsToBeConditionedNames.indexOf(
                                              itemsToBeConditionedDDValue[
                                                  index])]
                                      .map(
                                        (value) => DropdownMenuItem(
                                          value: value,
                                          child: Text(
                                            value,
                                            style: TextStyle(
                                              fontSize: fieldFontSize,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (Object? newValue) {
                                    setState(() {
                                      conditionsTypeDDValue[index] =
                                          newValue as String;
                                    });
                                    log('conditionsTypeDDValue at $index >>>>> ${conditionsTypeDDValue[index]}');
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Visibility(
                        visible: itemsToBeConditionedDDValue[index] != 'None',
                        child: Visibility(
                          visible: conditionsTypeDDValue[index] !=
                              '--- choose a condition ---',
                          child: Padding(
                            padding: EdgeInsets.only(left: size.width * .01),
                            child: SizedBox(
                              height: size.height * .04,
                              width: ddWidth,
                              child: Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: ThemeData().colorScheme.copyWith(
                                        primary: appColor,
                                      ),
                                ),
                                child: TextFormField(
                                  controller: valueForCondController[index],
                                  textAlignVertical: TextAlignVertical.top,
                                  cursorColor: appColor,
                                  style: TextStyle(
                                    fontSize: stFontSize,
                                    color: Colors.black,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Value to match',
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 10),
                                    enabledBorder: const OutlineInputBorder(
                                      borderSide: BorderSide(
                                        width: 0.25,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    focusedBorder: const OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: appColor,
                                        width: 0.5,
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: color3,
                                  ),
                                  onChanged: (value) {
                                    setState(() {
                                      conditionValueSave[index] = value;
                                    });
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(right: size.width * .01),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            minimumSize: Size.zero,
                            padding: const EdgeInsets.all(5),
                          ),
                          onPressed: () {
                            setState(() {
                              noOfConditionsToShow = noOfConditionsToShow - 1;
                              itemsToBeConditionedDDValue.removeAt(index);
                              conditionsTypeDDValue.removeAt(index);
                              conditionValueSave.removeAt(index);
                            });

                            /// making removed conditions value available to others ---------- START
                            for (int i = 0;
                                i < itemsToBeConditionedDDValue.length;
                                i++) {
                              itemsToBeConditionedNames.removeWhere(
                                  (e) => e == itemsToBeConditionedDDValue[i]);
                            }

                            listOfItemsToBeConditionedNames = [];

                            for (int i = 0;
                                i < itemsToBeConditionedDDValue.length;
                                i++) {
                              List<String> tempList = [];
                              tempList.addAll(
                                  itemsToBeConditionedNames.map((e) => e));
                              tempList.add(itemsToBeConditionedDDValue[i]);
                              listOfItemsToBeConditionedNames.add(tempList);
                              tempList = [];
                              setState(() {});
                            }

                            itemsToBeConditionedNames = [];
                            itemsToBeConditionedNames.addAll(
                                shippingRulesFromDB.map((e) =>
                                    e.get<String>(
                                        'items_to_be_conditioned_names') ??
                                    ''));
                            itemsToBeConditionedNames
                                .removeWhere((e) => e == 'empty');
                            log('itemsToBeConditionedNames - $itemsToBeConditionedNames');

                            /// making removed conditions value available to others ---------- END

                            log('no remove >>> $noOfConditionsToShow < ${itemsToBeConditionedNames.length}');
                          },
                          child: SizedBox(
                            height: size.height * .04,
                            width: buttonWidth,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.delete,
                                  color: Colors.white,
                                  size: stFontSize,
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(left: 5),
                                  child: Text(
                                    'Remove',
                                    style: TextStyle(
                                      fontSize: stFontSize,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: size.height * .02,
            width: size.width,
            color: color1,
          ),
        ],
      );
    });
  }

  List<Widget> _conditionsInnerBuilder(BuildContext context, Size size) {
    return List.generate(noOfConditionsToShow,
        (index) => _singleInnerBuilder(index, context, size));
  }

  Widget _shippingBuilder(BuildContext context, Size size) {
    return LayoutBuilder(builder: (_, c) {
      final width = c.maxWidth;
      double tFontSize = 16.0;
      double stFontSize = 10.0;
      if (width <= 480) {
        tFontSize = 16.0;
        stFontSize = 10.0;
      } else if (width > 480 && width <= 960) {
        tFontSize = 20.0;
        stFontSize = 13.0;
      } else {
        tFontSize = 24.0;
        stFontSize = 16.0;
      }
      return Container(
        color: Colors.grey.shade200,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: size.height * .025),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              _actionsTextBuilder(context, size, tFontSize),
              _shipFromBuilder(context, size, stFontSize),
              _shippingInnerBuilder(context, size, stFontSize),
              _iossBuilder(context, size, stFontSize),
              _saveRuleBuilder(context, size),
            ],
          ),
        ),
      );
    });
  }

  /// SHIPPING BUILDER HELPER WIDGET STARTS

  Widget _actionsTextBuilder(BuildContext context, Size size, double fontSize) {
    return Padding(
      padding: EdgeInsets.only(
        left: size.width * .025,
        right: size.width * .05,
        bottom: size.height * .02,
      ),
      child: Row(
        children: [
          Text(
            'Then take the following actions',
            style: TextStyle(
              fontSize: fontSize,
              color: Colors.black,
            ),
          )
        ],
      ),
    );
  }

  Widget _shipFromBuilder(BuildContext context, Size size, double fontSize) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(
            left: size.width * .025,
            top: size.height * .01,
          ),
          child: SizedBox(
            height: size.height * .03,
            width: size.width,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  'Ship from',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                )
              ],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(left: size.width * .025),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                height: size.height * .04,
                width: size.width * .88,
                decoration: BoxDecoration(
                  color: color3,
                  border: Border.all(
                    width: 0.25,
                    color: Colors.grey,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton(
                      elevation: 0,
                      value: shipFromDDValue,
                      icon: SizedBox(
                        height: 25,
                        width: 25,
                        child: FittedBox(
                          child: Image.asset(
                            'assets/add_new_rule_assets/dd_icon.png',
                          ),
                        ),
                      ),
                      items: shipFrom
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text(
                                value,
                                style: TextStyle(
                                  fontSize: fontSize,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (Object? newValue) {
                        setState(() {
                          shipFromDDValue = newValue as String;
                        });
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        )
      ],
    );
  }

  Widget _shippingInnerBuilder(
      BuildContext context, Size size, double fontSize) {
    return Padding(
      padding: EdgeInsets.only(top: size.height * .02),
      child: Container(
        width: size.width * .88,
        decoration: BoxDecoration(
          color: color2,
          border: Border.all(
            width: 0.25,
            color: Colors.grey,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            _carrierBuilder(context, size, fontSize),
            _serviceBuilder(context, size, fontSize),
            Visibility(
              visible: !isHideService,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  _packageTypeBuilder(context, size, fontSize),
                  _virtualTrackingBuilder(context, size, fontSize),
                  _addressIdentificationBuilder(context, size, fontSize),
                  _classXBuilder(context, size, fontSize),
                  _guaranteeBuilder(context, size, fontSize),
                  _localCollectBuilder(context, size, fontSize),
                  _lcLocationNameBuilder(context, size, fontSize),
                  _lcLocationTypeBuilder(context, size, fontSize),
                  _notificationTypeBuilder(context, size, fontSize),
                  _parcelShapeBuilder(context, size, fontSize),
                  _safePlaceBuilder(context, size, fontSize),
                  _postalChargesBuilder(context, size, fontSize),
                  _satDeliveryBuilder(context, size, fontSize),
                  _serviceLevelCodeBuilder(context, size, fontSize),
                  _signedConsignmentBuilder(context, size, fontSize),
                  _dgMedicinesBuilder(context, size, fontSize),
                  _dgPerfumeBuilder(context, size, fontSize),
                  _dgNailBuilder(context, size, fontSize),
                  _dgToiletryBuilder(context, size, fontSize),
                  _customInvoiceBuilder(context, size, fontSize),
                  _destinationTaxBuilder(context, size, fontSize),
                  _ecdBuilder(context, size, fontSize),
                  _liabilityBuilder(context, size, fontSize),
                  _preClearedBuilder(context, size, fontSize),
                  _recipientNotificationBuilder(context, size, fontSize),
                ],
              ),
            ),
            _showHideServiceEnhancements(context, size),
          ],
        ),
      ),
    );
  }

  Widget _carrierBuilder(BuildContext context, Size size, double fontSize) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(
            top: size.height * .015,
            left: size.width * .025,
          ),
          child: SizedBox(
            height: size.height * .03,
            width: size.width,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  'Assign to carrier',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                )
              ],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(left: size.width * .025),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                height: size.height * .04,
                width: size.width * .83,
                decoration: BoxDecoration(
                  color: color3,
                  border: Border.all(
                    width: 0.25,
                    color: Colors.grey,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton(
                      elevation: 0,
                      value: carrierValue,
                      icon: SizedBox(
                        height: 25,
                        width: 25,
                        child: FittedBox(
                          child: Image.asset(
                              'assets/add_new_rule_assets/dd_icon.png'),
                        ),
                      ),
                      items: carrier
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text(
                                value,
                                style: TextStyle(
                                  fontSize: fontSize,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (Object? newValue) {
                        setState(() {
                          carrierValue = newValue as String;
                          isHideService = true;
                        });
                        services = [];
                        services.addAll(shippingRulesFromDB
                            .where((el) =>
                                el.get<String>('service_type') == carrierValue)
                            .map((e) => e.get<String>('services') ?? ''));
                        setState(() {
                          servicesDDValue = 'None';
                          packageTypeDDValue =
                              packageType[servicesForIndexing.indexOf('None')]
                                  [0];
                          virtualTrackingDDValue = virtualTracking[
                              servicesForIndexing.indexOf('None')][0];
                          classDDValue =
                              classX[servicesForIndexing.indexOf('None')][0];
                          guaranteeValue =
                              guarantee[servicesForIndexing.indexOf('None')][0];
                          localCollectValue =
                              localCollect[servicesForIndexing.indexOf('None')]
                                  [0];
                          notificationTypeValue = notificationType[
                              servicesForIndexing.indexOf('None')][0];
                          safePlaceValue =
                              safePlace[servicesForIndexing.indexOf('None')][0];
                          parcelShapeValue =
                              parcelShape[servicesForIndexing.indexOf('None')]
                                  [0];
                          satDeliveryValue =
                              satDelivery[servicesForIndexing.indexOf('None')]
                                  [0];
                          signedConsignmentValue = signedConsignment[
                              servicesForIndexing.indexOf('None')][0];
                          dgMedicinesValue =
                              dgMedicines[servicesForIndexing.indexOf('None')]
                                  [0];
                          dgPerfumeValue =
                              dgPerfume[servicesForIndexing.indexOf('None')][0];
                          dgNailValue =
                              dgNail[servicesForIndexing.indexOf('None')][0];
                          dgToiletryValue =
                              dgToiletry[servicesForIndexing.indexOf('None')]
                                  [0];

                          /// CHANGES 04 JUNE, 2023 - FOR DPD CARRIER
                          customInvoiceValue =
                              customInvoice[servicesForIndexing.indexOf('None')]
                                  [0];
                          ecdValue =
                              ecd[servicesForIndexing.indexOf('None')][0];
                          liabilityValue =
                              liability[servicesForIndexing.indexOf('None')][0];
                          preClearedValue =
                              preCleared[servicesForIndexing.indexOf('None')]
                                  [0];
                          recipientNotificationValue = recipientNotification[
                              servicesForIndexing.indexOf('None')][0];
                          addresseeIdentificationController.text = '';
                          lcLocationNameController.text = '';
                          lcLocationTypeController.text = '';
                          postalChargesController.text = '';
                          serviceLevelCodeController.text = '';
                          destinationTaxController.text = '';
                        });
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        )
      ],
    );
  }

  Widget _serviceBuilder(BuildContext context, Size size, double fontSize) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(
            top: size.height * .015,
            left: size.width * .025,
          ),
          child: SizedBox(
            height: size.height * .03,
            width: size.width,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  'Assign to service',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                )
              ],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(left: size.width * .025),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                height: size.height * .04,
                width: size.width * .83,
                decoration: BoxDecoration(
                  color: color3,
                  border: Border.all(width: 0.25, color: Colors.grey),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton(
                      elevation: 0,
                      value: servicesDDValue,
                      icon: SizedBox(
                        height: 25,
                        width: 25,
                        child: FittedBox(
                          child: Image.asset(
                            'assets/add_new_rule_assets/dd_icon.png',
                          ),
                        ),
                      ),
                      items: services
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text(
                                value,
                                style: TextStyle(
                                  fontSize: fontSize,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (Object? newValue) {
                        setState(() {
                          servicesDDValue = newValue as String;
                          isHideService = false;
                          packageTypeDDValue =
                              packageType[servicesForIndexing.indexOf(newValue)]
                                  [0];
                          virtualTrackingDDValue = virtualTracking[
                              servicesForIndexing.indexOf(newValue)][0];
                          classDDValue =
                              classX[servicesForIndexing.indexOf(newValue)][0];
                          guaranteeValue =
                              guarantee[servicesForIndexing.indexOf(newValue)]
                                  [0];
                          localCollectValue = localCollect[
                              servicesForIndexing.indexOf(newValue)][0];
                          notificationTypeValue = notificationType[
                              servicesForIndexing.indexOf(newValue)][0];
                          safePlaceValue =
                              safePlace[servicesForIndexing.indexOf(newValue)]
                                  [0];
                          parcelShapeValue =
                              parcelShape[servicesForIndexing.indexOf(newValue)]
                                  [0];
                          satDeliveryValue =
                              satDelivery[servicesForIndexing.indexOf(newValue)]
                                  [0];
                          signedConsignmentValue = signedConsignment[
                              servicesForIndexing.indexOf(newValue)][0];
                          dgMedicinesValue =
                              dgMedicines[servicesForIndexing.indexOf(newValue)]
                                  [0];
                          dgPerfumeValue =
                              dgPerfume[servicesForIndexing.indexOf(newValue)]
                                  [0];
                          dgNailValue =
                              dgNail[servicesForIndexing.indexOf(newValue)][0];
                          dgToiletryValue =
                              dgToiletry[servicesForIndexing.indexOf(newValue)]
                                  [0];

                          /// CHANGES 04 JUNE, 2023 - FOR DPD CARRIER
                          customInvoiceValue = customInvoice[
                              servicesForIndexing.indexOf(newValue)][0];
                          ecdValue =
                              ecd[servicesForIndexing.indexOf(newValue)][0];
                          liabilityValue =
                              liability[servicesForIndexing.indexOf(newValue)]
                                  [0];
                          preClearedValue =
                              preCleared[servicesForIndexing.indexOf(newValue)]
                                  [0];
                          recipientNotificationValue = recipientNotification[
                              servicesForIndexing.indexOf(newValue)][0];

                          addresseeIdentificationController.text = '';
                          lcLocationNameController.text = '';
                          lcLocationTypeController.text = '';
                          postalChargesController.text = '';
                          serviceLevelCodeController.text = '';
                          destinationTaxController.text = '';
                        });
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        )
      ],
    );
  }

  Widget _packageTypeBuilder(BuildContext context, Size size, double fontSize) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Visibility(
          visible: packageTypeVisible[
                      servicesForIndexing.indexOf(servicesDDValue)] ==
                  'Yes'
              ? true
              : false,
          child: Padding(
            padding: EdgeInsets.only(
              top: size.height * .015,
              left: size.width * .025,
            ),
            child: SizedBox(
              height: size.height * .03,
              width: size.width,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    'Package type',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  )
                ],
              ),
            ),
          ),
        ),
        Visibility(
          visible: packageTypeVisible[
                      servicesForIndexing.indexOf(servicesDDValue)] ==
                  'Yes'
              ? true
              : false,
          child: Padding(
            padding: EdgeInsets.only(left: size.width * .025),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  height: size.height * .04,
                  width: size.width * .83,
                  decoration: BoxDecoration(
                    color: color3,
                    border: Border.all(width: 0.25, color: Colors.grey),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton(
                        elevation: 0,
                        value: packageTypeDDValue,
                        icon: SizedBox(
                          height: 25,
                          width: 25,
                          child: FittedBox(
                            child: Image.asset(
                              'assets/add_new_rule_assets/dd_icon.png',
                            ),
                          ),
                        ),
                        items: packageType[
                                servicesForIndexing.indexOf(servicesDDValue)]
                            .map(
                              (value) => DropdownMenuItem(
                                value: value.toString(),
                                child: Text(
                                  value,
                                  style: TextStyle(
                                    fontSize: fontSize,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (Object? newValue) {
                          setState(() {
                            packageTypeDDValue = newValue as String;
                          });
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _virtualTrackingBuilder(
      BuildContext context, Size size, double fontSize) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Visibility(
          visible: virtualTrackingVisible[
                      servicesForIndexing.indexOf(servicesDDValue)] ==
                  'Yes'
              ? true
              : false,
          child: Padding(
            padding: EdgeInsets.only(
              top: size.height * .015,
              left: size.width * .025,
            ),
            child: SizedBox(
              height: size.height * .03,
              width: size.width,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    'Address contains Virtual Tracking Number',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  )
                ],
              ),
            ),
          ),
        ),
        Visibility(
          visible: virtualTrackingVisible[
                      servicesForIndexing.indexOf(servicesDDValue)] ==
                  'Yes'
              ? true
              : false,
          child: Padding(
            padding: EdgeInsets.only(left: size.width * .025),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  height: size.height * .04,
                  width: size.width * .83,
                  decoration: BoxDecoration(
                    color: color3,
                    border: Border.all(width: 0.25, color: Colors.grey),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton(
                        elevation: 0,
                        value: virtualTrackingDDValue,
                        icon: SizedBox(
                          height: 25,
                          width: 25,
                          child: FittedBox(
                            child: Image.asset(
                              'assets/add_new_rule_assets/dd_icon.png',
                            ),
                          ),
                        ),
                        items: virtualTracking[
                                servicesForIndexing.indexOf(servicesDDValue)]
                            .map(
                              (value) => DropdownMenuItem(
                                value: value.toString(),
                                child: Text(
                                  value,
                                  style: TextStyle(
                                    fontSize: fontSize,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (Object? newValue) {
                          setState(() {
                            virtualTrackingDDValue = newValue as String;
                          });
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _addressIdentificationBuilder(
      BuildContext context, Size size, double fontSize) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Visibility(
          visible: addressIdentificationVisible[
                      servicesForIndexing.indexOf(servicesDDValue)] ==
                  'Yes'
              ? true
              : false,
          child: Padding(
            padding: EdgeInsets.only(
              top: size.height * .015,
              left: size.width * .025,
            ),
            child: SizedBox(
              height: size.height * .03,
              width: size.width,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    'Addressee Identification Reference Number (for Brazil, Russia and Portugal)',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  )
                ],
              ),
            ),
          ),
        ),
        Visibility(
          visible: addressIdentificationVisible[
                      servicesForIndexing.indexOf(servicesDDValue)] ==
                  'Yes'
              ? true
              : false,
          child: Padding(
            padding: EdgeInsets.only(left: size.width * .025),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(
                  height: size.height * .04,
                  width: size.width * .83,
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: ThemeData().colorScheme.copyWith(
                            primary: appColor,
                          ),
                    ),
                    child: TextFormField(
                      controller: addresseeIdentificationController,
                      textAlignVertical: TextAlignVertical.top,
                      cursorColor: appColor,
                      style: TextStyle(fontSize: fontSize, color: Colors.black),
                      decoration: InputDecoration(
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 10),
                        enabledBorder: const OutlineInputBorder(
                          borderSide: BorderSide(
                            width: 0.25,
                            color: Colors.grey,
                          ),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: appColor, width: 0.5),
                        ),
                        filled: true,
                        fillColor: color3,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _classXBuilder(BuildContext context, Size size, double fontSize) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Visibility(
          visible: classVisible[servicesForIndexing.indexOf(servicesDDValue)] ==
                  'Yes'
              ? true
              : false,
          child: Padding(
            padding: EdgeInsets.only(
              top: size.height * .015,
              left: size.width * .025,
            ),
            child: SizedBox(
              height: size.height * .03,
              width: size.width,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    'First/Second class',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  )
                ],
              ),
            ),
          ),
        ),
        Visibility(
          visible: classVisible[servicesForIndexing.indexOf(servicesDDValue)] ==
                  'Yes'
              ? true
              : false,
          child: Padding(
            padding: EdgeInsets.only(left: size.width * .025),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  height: size.height * .04,
                  width: size.width * .83,
                  decoration: BoxDecoration(
                    color: color3,
                    border: Border.all(width: 0.25, color: Colors.grey),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton(
                        elevation: 0,
                        value: classDDValue,
                        icon: SizedBox(
                          height: 25,
                          width: 25,
                          child: FittedBox(
                            child: Image.asset(
                              'assets/add_new_rule_assets/dd_icon.png',
                            ),
                          ),
                        ),
                        items:
                            classX[servicesForIndexing.indexOf(servicesDDValue)]
                                .map(
                                  (value) => DropdownMenuItem(
                                    value: value.toString(),
                                    child: Text(
                                      value,
                                      style: TextStyle(
                                        fontSize: fontSize,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                        onChanged: (Object? newValue) {
                          setState(() {
                            classDDValue = newValue as String;
                          });
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _guaranteeBuilder(BuildContext context, Size size, double fontSize) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Visibility(
          visible:
              guaranteeVisible[servicesForIndexing.indexOf(servicesDDValue)] ==
                      'Yes'
                  ? true
                  : false,
          child: Padding(
            padding: EdgeInsets.only(
              top: size.height * .015,
              left: size.width * .025,
            ),
            child: SizedBox(
              height: size.height * .03,
              width: size.width,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    'Guarantee By',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  )
                ],
              ),
            ),
          ),
        ),
        Visibility(
          visible:
              guaranteeVisible[servicesForIndexing.indexOf(servicesDDValue)] ==
                      'Yes'
                  ? true
                  : false,
          child: Padding(
            padding: EdgeInsets.only(left: size.width * .025),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  height: size.height * .04,
                  width: size.width * .83,
                  decoration: BoxDecoration(
                    color: color3,
                    border: Border.all(width: 0.25, color: Colors.grey),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton(
                        elevation: 0,
                        value: guaranteeValue,
                        icon: SizedBox(
                          height: 25,
                          width: 25,
                          child: FittedBox(
                            child: Image.asset(
                              'assets/add_new_rule_assets/dd_icon.png',
                            ),
                          ),
                        ),
                        items: guarantee[
                                servicesForIndexing.indexOf(servicesDDValue)]
                            .map(
                              (value) => DropdownMenuItem(
                                value: value.toString(),
                                child: Text(
                                  value,
                                  style: TextStyle(
                                    fontSize: fontSize,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (Object? newValue) {
                          setState(() {
                            guaranteeValue = newValue as String;
                          });
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _localCollectBuilder(
      BuildContext context, Size size, double fontSize) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Visibility(
          visible: localCollectVisible[
                      servicesForIndexing.indexOf(servicesDDValue)] ==
                  'Yes'
              ? true
              : false,
          child: Padding(
            padding: EdgeInsets.only(
              top: size.height * .015,
              left: size.width * .025,
            ),
            child: SizedBox(
              height: size.height * .03,
              width: size.width,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    'Local Collect',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
        Visibility(
          visible: localCollectVisible[
                      servicesForIndexing.indexOf(servicesDDValue)] ==
                  'Yes'
              ? true
              : false,
          child: Padding(
            padding: EdgeInsets.only(left: size.width * .025),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  height: size.height * .04,
                  width: size.width * .83,
                  decoration: BoxDecoration(
                    color: color3,
                    border: Border.all(width: 0.25, color: Colors.grey),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton(
                        elevation: 0,
                        value: localCollectValue,
                        icon: SizedBox(
                          height: 25,
                          width: 25,
                          child: FittedBox(
                            child: Image.asset(
                              'assets/add_new_rule_assets/dd_icon.png',
                            ),
                          ),
                        ),
                        items: localCollect[
                                servicesForIndexing.indexOf(servicesDDValue)]
                            .map(
                              (value) => DropdownMenuItem(
                                value: value.toString(),
                                child: Text(
                                  value,
                                  style: TextStyle(
                                    fontSize: fontSize,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (Object? newValue) {
                          setState(() {
                            localCollectValue = newValue as String;
                          });
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _lcLocationNameBuilder(
      BuildContext context, Size size, double fontSize) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Visibility(
          visible: lcLocationNameVisible[
                      servicesForIndexing.indexOf(servicesDDValue)] ==
                  'Yes'
              ? true
              : false,
          child: Padding(
            padding: EdgeInsets.only(
              top: size.height * .015,
              left: size.width * .025,
            ),
            child: SizedBox(
              height: size.height * .03,
              width: size.width,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    'Local Collect Location Name',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  )
                ],
              ),
            ),
          ),
        ),
        Visibility(
          visible: lcLocationNameVisible[
                      servicesForIndexing.indexOf(servicesDDValue)] ==
                  'Yes'
              ? true
              : false,
          child: Padding(
            padding: EdgeInsets.only(left: size.width * .025),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(
                  height: size.height * .04,
                  width: size.width * .83,
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: ThemeData().colorScheme.copyWith(
                            primary: appColor,
                          ),
                    ),
                    child: TextFormField(
                      controller: lcLocationNameController,
                      textAlignVertical: TextAlignVertical.top,
                      cursorColor: appColor,
                      style: TextStyle(
                        fontSize: fontSize,
                        color: Colors.black,
                      ),
                      decoration: InputDecoration(
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 10),
                        enabledBorder: const OutlineInputBorder(
                          borderSide: BorderSide(
                            width: 0.25,
                            color: Colors.grey,
                          ),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: appColor, width: 0.51),
                        ),
                        filled: true,
                        fillColor: color3,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _lcLocationTypeBuilder(
      BuildContext context, Size size, double fontSize) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Visibility(
          visible: lcLocationTypeVisible[
                      servicesForIndexing.indexOf(servicesDDValue)] ==
                  'Yes'
              ? true
              : false,
          child: Padding(
            padding: EdgeInsets.only(
              top: size.height * .015,
              left: size.width * .025,
            ),
            child: SizedBox(
              height: size.height * .03,
              width: size.width,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    'Local Collect Location Type',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  )
                ],
              ),
            ),
          ),
        ),
        Visibility(
          visible: lcLocationTypeVisible[
                      servicesForIndexing.indexOf(servicesDDValue)] ==
                  'Yes'
              ? true
              : false,
          child: Padding(
            padding: EdgeInsets.only(left: size.width * .025),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(
                  height: size.height * .04,
                  width: size.width * .83,
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: ThemeData().colorScheme.copyWith(
                            primary: appColor,
                          ),
                    ),
                    child: TextFormField(
                      controller: lcLocationTypeController,
                      textAlignVertical: TextAlignVertical.top,
                      cursorColor: appColor,
                      style: TextStyle(fontSize: fontSize, color: Colors.black),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                        ),
                        enabledBorder: const OutlineInputBorder(
                          borderSide: BorderSide(
                            width: 0.25,
                            color: Colors.grey,
                          ),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: appColor, width: 0.5),
                        ),
                        filled: true,
                        fillColor: color3,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _notificationTypeBuilder(
      BuildContext context, Size size, double fontSize) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Visibility(
          visible: notificationTypeVisible[
                      servicesForIndexing.indexOf(servicesDDValue)] ==
                  'Yes'
              ? true
              : false,
          child: Padding(
            padding: EdgeInsets.only(
              top: size.height * .015,
              left: size.width * .025,
            ),
            child: SizedBox(
              height: size.height * .03,
              width: size.width,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    'Notification Type',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  )
                ],
              ),
            ),
          ),
        ),
        Visibility(
          visible: notificationTypeVisible[
                      servicesForIndexing.indexOf(servicesDDValue)] ==
                  'Yes'
              ? true
              : false,
          child: Padding(
            padding: EdgeInsets.only(left: size.width * .025),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  height: size.height * .04,
                  width: size.width * .83,
                  decoration: BoxDecoration(
                    color: color3,
                    border: Border.all(width: 0.25, color: Colors.grey),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton(
                        elevation: 0,
                        value: notificationTypeValue,
                        icon: SizedBox(
                          height: 25,
                          width: 25,
                          child: FittedBox(
                            child: Image.asset(
                                'assets/add_new_rule_assets/dd_icon.png'),
                          ),
                        ),
                        items: notificationType[
                                servicesForIndexing.indexOf(servicesDDValue)]
                            .map(
                              (value) => DropdownMenuItem(
                                value: value.toString(),
                                child: Text(
                                  value,
                                  style: TextStyle(
                                    fontSize: fontSize,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (Object? newValue) {
                          setState(() {
                            notificationTypeValue = newValue as String;
                          });
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _parcelShapeBuilder(BuildContext context, Size size, double fontSize) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Visibility(
          visible: parcelShapeVisible[
                      servicesForIndexing.indexOf(servicesDDValue)] ==
                  'Yes'
              ? true
              : false,
          child: Padding(
            padding: EdgeInsets.only(
              top: size.height * .015,
              left: size.width * .025,
            ),
            child: SizedBox(
              height: size.height * .03,
              width: size.width,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    'Parcel Shape',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  )
                ],
              ),
            ),
          ),
        ),
        Visibility(
          visible: parcelShapeVisible[
                      servicesForIndexing.indexOf(servicesDDValue)] ==
                  'Yes'
              ? true
              : false,
          child: Padding(
            padding: EdgeInsets.only(left: size.width * .025),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  height: size.height * .04,
                  width: size.width * .83,
                  decoration: BoxDecoration(
                    color: color3,
                    border: Border.all(width: 0.25, color: Colors.grey),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton(
                        elevation: 0,
                        value: parcelShapeValue,
                        icon: SizedBox(
                          height: 25,
                          width: 25,
                          child: FittedBox(
                            child: Image.asset(
                              'assets/add_new_rule_assets/dd_icon.png',
                            ),
                          ),
                        ),
                        items: parcelShape[
                                servicesForIndexing.indexOf(servicesDDValue)]
                            .map(
                              (value) => DropdownMenuItem(
                                value: value.toString(),
                                child: Text(
                                  value,
                                  style: TextStyle(
                                    fontSize: fontSize,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (Object? newValue) {
                          setState(() {
                            parcelShapeValue = newValue as String;
                          });
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _safePlaceBuilder(BuildContext context, Size size, double fontSize) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Visibility(
          visible:
              safePlaceVisible[servicesForIndexing.indexOf(servicesDDValue)] ==
                      'Yes'
                  ? true
                  : false,
          child: Padding(
            padding: EdgeInsets.only(
              top: size.height * .015,
              left: size.width * .025,
            ),
            child: SizedBox(
              height: size.height * .03,
              width: size.width,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    'Safeplace (Use the Shipping Notes in Order Info tab for Safeplace instructions)',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  )
                ],
              ),
            ),
          ),
        ),
        Visibility(
          visible:
              safePlaceVisible[servicesForIndexing.indexOf(servicesDDValue)] ==
                      'Yes'
                  ? true
                  : false,
          child: Padding(
            padding: EdgeInsets.only(left: size.width * .025),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  height: size.height * .04,
                  width: size.width * .83,
                  decoration: BoxDecoration(
                    color: color3,
                    border: Border.all(width: 0.25, color: Colors.grey),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton(
                        elevation: 0,
                        value: safePlaceValue,
                        icon: SizedBox(
                          height: 25,
                          width: 25,
                          child: FittedBox(
                            child: Image.asset(
                                'assets/add_new_rule_assets/dd_icon.png'),
                          ),
                        ),
                        items: safePlace[
                                servicesForIndexing.indexOf(servicesDDValue)]
                            .map(
                              (value) => DropdownMenuItem(
                                value: value.toString(),
                                child: Text(
                                  value,
                                  style: TextStyle(
                                    fontSize: fontSize,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (Object? newValue) {
                          setState(() {
                            safePlaceValue = newValue as String;
                          });
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _postalChargesBuilder(
      BuildContext context, Size size, double fontSize) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Visibility(
          visible: postalChargesVisible[
                      servicesForIndexing.indexOf(servicesDDValue)] ==
                  'Yes'
              ? true
              : false,
          child: Padding(
            padding: EdgeInsets.only(
              top: size.height * .015,
              left: size.width * .025,
            ),
            child: SizedBox(
              height: size.height * .03,
              width: size.width,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    'Postal Charges',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  )
                ],
              ),
            ),
          ),
        ),
        Visibility(
          visible: postalChargesVisible[
                      servicesForIndexing.indexOf(servicesDDValue)] ==
                  'Yes'
              ? true
              : false,
          child: Padding(
            padding: EdgeInsets.only(left: size.width * .025),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(
                  height: size.height * .04,
                  width: size.width * .83,
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: ThemeData().colorScheme.copyWith(
                            primary: appColor,
                          ),
                    ),
                    child: TextFormField(
                      controller: postalChargesController,
                      textAlignVertical: TextAlignVertical.top,
                      cursorColor: appColor,
                      style: TextStyle(fontSize: fontSize, color: Colors.black),
                      decoration: InputDecoration(
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 10),
                        enabledBorder: const OutlineInputBorder(
                          borderSide: BorderSide(
                            width: 0.25,
                            color: Colors.grey,
                          ),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: appColor, width: 0.5),
                        ),
                        filled: true,
                        fillColor: color3,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _satDeliveryBuilder(BuildContext context, Size size, double fontSize) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Visibility(
          visible: satDeliveryVisible[
                      servicesForIndexing.indexOf(servicesDDValue)] ==
                  'Yes'
              ? true
              : false,
          child: Padding(
            padding: EdgeInsets.only(
              top: size.height * .015,
              left: size.width * .025,
            ),
            child: SizedBox(
              height: size.height * .03,
              width: size.width,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    'Saturday delivery',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  )
                ],
              ),
            ),
          ),
        ),
        Visibility(
          visible: satDeliveryVisible[
                      servicesForIndexing.indexOf(servicesDDValue)] ==
                  'Yes'
              ? true
              : false,
          child: Padding(
            padding: EdgeInsets.only(left: size.width * .025),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  height: size.height * .04,
                  width: size.width * .83,
                  decoration: BoxDecoration(
                    color: color3,
                    border: Border.all(width: 0.25, color: Colors.grey),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton(
                        elevation: 0,
                        value: satDeliveryValue,
                        icon: SizedBox(
                          height: 25,
                          width: 25,
                          child: FittedBox(
                            child: Image.asset(
                              'assets/add_new_rule_assets/dd_icon.png',
                            ),
                          ),
                        ),
                        items: satDelivery[
                                servicesForIndexing.indexOf(servicesDDValue)]
                            .map(
                              (value) => DropdownMenuItem(
                                value: value.toString(),
                                child: Text(
                                  value,
                                  style: TextStyle(
                                    fontSize: fontSize,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (Object? newValue) {
                          setState(() {
                            satDeliveryValue = newValue as String;
                          });
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _serviceLevelCodeBuilder(
      BuildContext context, Size size, double fontSize) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Visibility(
          visible: serviceLevelCodeVisible[
                      servicesForIndexing.indexOf(servicesDDValue)] ==
                  'Yes'
              ? true
              : false,
          child: Padding(
            padding: EdgeInsets.only(
              top: size.height * .015,
              left: size.width * .025,
            ),
            child: SizedBox(
              height: size.height * .03,
              width: size.width,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    'Service Level code',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  )
                ],
              ),
            ),
          ),
        ),
        Visibility(
          visible: serviceLevelCodeVisible[
                      servicesForIndexing.indexOf(servicesDDValue)] ==
                  'Yes'
              ? true
              : false,
          child: Padding(
            padding: EdgeInsets.only(left: size.width * .025),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(
                  height: size.height * .04,
                  width: size.width * .83,
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: ThemeData().colorScheme.copyWith(
                            primary: appColor,
                          ),
                    ),
                    child: TextFormField(
                      controller: serviceLevelCodeController,
                      textAlignVertical: TextAlignVertical.top,
                      cursorColor: appColor,
                      style: TextStyle(fontSize: fontSize, color: Colors.black),
                      decoration: InputDecoration(
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 10),
                        enabledBorder: const OutlineInputBorder(
                          borderSide: BorderSide(
                            width: 0.25,
                            color: Colors.grey,
                          ),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: appColor, width: 0.5),
                        ),
                        filled: true,
                        fillColor: color3,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _signedConsignmentBuilder(
      BuildContext context, Size size, double fontSize) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Visibility(
          visible: signedConsignmentVisible[
                      servicesForIndexing.indexOf(servicesDDValue)] ==
                  'Yes'
              ? true
              : false,
          child: Padding(
            padding: EdgeInsets.only(
              top: size.height * .015,
              left: size.width * .025,
            ),
            child: SizedBox(
              height: size.height * .03,
              width: size.width,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    'Signed consignment',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  )
                ],
              ),
            ),
          ),
        ),
        Visibility(
          visible: signedConsignmentVisible[
                      servicesForIndexing.indexOf(servicesDDValue)] ==
                  'Yes'
              ? true
              : false,
          child: Padding(
            padding: EdgeInsets.only(left: size.width * .025),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  height: size.height * .04,
                  width: size.width * .83,
                  decoration: BoxDecoration(
                    color: color3,
                    border: Border.all(width: 0.25, color: Colors.grey),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton(
                        elevation: 0,
                        value: signedConsignmentValue,
                        icon: SizedBox(
                          height: 25,
                          width: 25,
                          child: FittedBox(
                            child: Image.asset(
                                'assets/add_new_rule_assets/dd_icon.png'),
                          ),
                        ),
                        items: signedConsignment[
                                servicesForIndexing.indexOf(servicesDDValue)]
                            .map(
                              (value) => DropdownMenuItem(
                                value: value.toString(),
                                child: Text(
                                  value,
                                  style: TextStyle(
                                    fontSize: fontSize,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (Object? newValue) {
                          setState(() {
                            signedConsignmentValue = newValue as String;
                          });
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _dgMedicinesBuilder(BuildContext context, Size size, double fontSize) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Visibility(
          visible: dgMedicinesVisible[
                      servicesForIndexing.indexOf(servicesDDValue)] ==
                  'Yes'
              ? true
              : false,
          child: Padding(
            padding: EdgeInsets.only(
              top: size.height * .015,
              left: size.width * .025,
            ),
            child: SizedBox(
              height: size.height * .03,
              width: size.width,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    'Dangerous Goods: Medicines',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  )
                ],
              ),
            ),
          ),
        ),
        Visibility(
          visible: dgMedicinesVisible[
                      servicesForIndexing.indexOf(servicesDDValue)] ==
                  'Yes'
              ? true
              : false,
          child: Padding(
            padding: EdgeInsets.only(left: size.width * .025),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  height: size.height * .04,
                  width: size.width * .83,
                  decoration: BoxDecoration(
                    color: color3,
                    border: Border.all(width: 0.25, color: Colors.grey),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton(
                        elevation: 0,
                        value: dgMedicinesValue,
                        icon: SizedBox(
                          height: 25,
                          width: 25,
                          child: FittedBox(
                            child: Image.asset(
                                'assets/add_new_rule_assets/dd_icon.png'),
                          ),
                        ),
                        items: dgMedicines[
                                servicesForIndexing.indexOf(servicesDDValue)]
                            .map(
                              (value) => DropdownMenuItem(
                                value: value.toString(),
                                child: Text(
                                  value,
                                  style: TextStyle(
                                    fontSize: fontSize,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (Object? newValue) {
                          setState(() {
                            dgMedicinesValue = newValue as String;
                          });
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _dgPerfumeBuilder(BuildContext context, Size size, double fontSize) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Visibility(
          visible:
              dgPerfumeVisible[servicesForIndexing.indexOf(servicesDDValue)] ==
                      'Yes'
                  ? true
                  : false,
          child: Padding(
            padding: EdgeInsets.only(
              top: size.height * .015,
              left: size.width * .025,
            ),
            child: SizedBox(
              height: size.height * .03,
              width: size.width,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    'Dangerous Goods: Perfume/Aftershave',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  )
                ],
              ),
            ),
          ),
        ),
        Visibility(
          visible:
              dgPerfumeVisible[servicesForIndexing.indexOf(servicesDDValue)] ==
                      'Yes'
                  ? true
                  : false,
          child: Padding(
            padding: EdgeInsets.only(left: size.width * .025),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  height: size.height * .04,
                  width: size.width * .83,
                  decoration: BoxDecoration(
                    color: color3,
                    border: Border.all(width: 0.25, color: Colors.grey),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton(
                        elevation: 0,
                        value: dgPerfumeValue,
                        icon: SizedBox(
                          height: 25,
                          width: 25,
                          child: FittedBox(
                            child: Image.asset(
                                'assets/add_new_rule_assets/dd_icon.png'),
                          ),
                        ),
                        items: dgPerfume[
                                servicesForIndexing.indexOf(servicesDDValue)]
                            .map(
                              (value) => DropdownMenuItem(
                                value: value.toString(),
                                child: Text(
                                  value,
                                  style: TextStyle(
                                    fontSize: fontSize,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (Object? newValue) {
                          setState(() {
                            dgPerfumeValue = newValue as String;
                          });
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _dgNailBuilder(BuildContext context, Size size, double fontSize) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Visibility(
          visible:
              dgNailVisible[servicesForIndexing.indexOf(servicesDDValue)] ==
                      'Yes'
                  ? true
                  : false,
          child: Padding(
            padding: EdgeInsets.only(
              top: size.height * .015,
              left: size.width * .025,
            ),
            child: SizedBox(
              height: size.height * .03,
              width: size.width,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    'Dangerous Goods: Nail Varnish',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  )
                ],
              ),
            ),
          ),
        ),
        Visibility(
          visible:
              dgNailVisible[servicesForIndexing.indexOf(servicesDDValue)] ==
                      'Yes'
                  ? true
                  : false,
          child: Padding(
            padding: EdgeInsets.only(left: size.width * .025),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  height: size.height * .04,
                  width: size.width * .83,
                  decoration: BoxDecoration(
                    color: color3,
                    border: Border.all(width: 0.25, color: Colors.grey),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton(
                        elevation: 0,
                        value: dgNailValue,
                        icon: SizedBox(
                          height: 25,
                          width: 25,
                          child: FittedBox(
                            child: Image.asset(
                                'assets/add_new_rule_assets/dd_icon.png'),
                          ),
                        ),
                        items:
                            dgNail[servicesForIndexing.indexOf(servicesDDValue)]
                                .map(
                                  (value) => DropdownMenuItem(
                                    value: value.toString(),
                                    child: Text(
                                      value,
                                      style: TextStyle(
                                        fontSize: fontSize,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                        onChanged: (Object? newValue) {
                          setState(() {
                            dgNailValue = newValue as String;
                          });
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _dgToiletryBuilder(BuildContext context, Size size, double fontSize) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Visibility(
          visible:
              dgToiletryVisible[servicesForIndexing.indexOf(servicesDDValue)] ==
                      'Yes'
                  ? true
                  : false,
          child: Padding(
            padding: EdgeInsets.only(
              top: size.height * .015,
              left: size.width * .025,
            ),
            child: SizedBox(
              height: size.height * .03,
              width: size.width,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    'Dangerous Goods: Toiletry or medicinal aerosols',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  )
                ],
              ),
            ),
          ),
        ),
        Visibility(
          visible:
              dgToiletryVisible[servicesForIndexing.indexOf(servicesDDValue)] ==
                      'Yes'
                  ? true
                  : false,
          child: Padding(
            padding: EdgeInsets.only(left: size.width * .025),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  height: size.height * .04,
                  width: size.width * .83,
                  decoration: BoxDecoration(
                    color: color3,
                    border: Border.all(width: 0.25, color: Colors.grey),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton(
                        elevation: 0,
                        value: dgToiletryValue,
                        icon: SizedBox(
                          height: 25,
                          width: 25,
                          child: FittedBox(
                            child: Image.asset(
                                'assets/add_new_rule_assets/dd_icon.png'),
                          ),
                        ),
                        items: dgToiletry[
                                servicesForIndexing.indexOf(servicesDDValue)]
                            .map(
                              (value) => DropdownMenuItem(
                                value: value.toString(),
                                child: Text(
                                  value,
                                  style: TextStyle(
                                    fontSize: fontSize,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (Object? newValue) {
                          setState(() {
                            dgToiletryValue = newValue as String;
                          });
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _customInvoiceBuilder(
      BuildContext context, Size size, double fontSize) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Visibility(
          visible: customInvoiceVisible[
                      servicesForIndexing.indexOf(servicesDDValue)] ==
                  'Yes'
              ? true
              : false,
          child: Padding(
            padding: EdgeInsets.only(
              top: size.height * .015,
              left: size.width * .025,
            ),
            child: SizedBox(
              height: size.height * .03,
              width: size.width,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    'Customs invoice type',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  )
                ],
              ),
            ),
          ),
        ),
        Visibility(
          visible: customInvoiceVisible[
                      servicesForIndexing.indexOf(servicesDDValue)] ==
                  'Yes'
              ? true
              : false,
          child: Padding(
            padding: EdgeInsets.only(left: size.width * .025),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  height: size.height * .04,
                  width: size.width * .83,
                  decoration: BoxDecoration(
                    color: color3,
                    border: Border.all(width: 0.25, color: Colors.grey),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton(
                        elevation: 0,
                        value: customInvoiceValue,
                        icon: SizedBox(
                          height: 25,
                          width: 25,
                          child: FittedBox(
                            child: Image.asset(
                                'assets/add_new_rule_assets/dd_icon.png'),
                          ),
                        ),
                        items: customInvoice[
                                servicesForIndexing.indexOf(servicesDDValue)]
                            .map(
                              (value) => DropdownMenuItem(
                                value: value.toString(),
                                child: Text(
                                  value,
                                  style: TextStyle(
                                    fontSize: fontSize,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (Object? newValue) {
                          setState(() {
                            customInvoiceValue = newValue as String;
                          });
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _destinationTaxBuilder(
      BuildContext context, Size size, double fontSize) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Visibility(
          visible: destinationTaxVisible[
                      servicesForIndexing.indexOf(servicesDDValue)] ==
                  'Yes'
              ? true
              : false,
          child: Padding(
            padding: EdgeInsets.only(
              top: size.height * .015,
              left: size.width * .025,
            ),
            child: SizedBox(
              height: size.height * .03,
              width: size.width,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    'Destination Tax Number',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  )
                ],
              ),
            ),
          ),
        ),
        Visibility(
          visible: destinationTaxVisible[
                      servicesForIndexing.indexOf(servicesDDValue)] ==
                  'Yes'
              ? true
              : false,
          child: Padding(
            padding: EdgeInsets.only(left: size.width * .025),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(
                  height: size.height * .04,
                  width: size.width * .83,
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: ThemeData().colorScheme.copyWith(
                            primary: appColor,
                          ),
                    ),
                    child: TextFormField(
                      controller: destinationTaxController,
                      textAlignVertical: TextAlignVertical.top,
                      cursorColor: appColor,
                      style: TextStyle(
                        fontSize: fontSize,
                        color: Colors.black,
                      ),
                      decoration: InputDecoration(
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 10),
                        enabledBorder: const OutlineInputBorder(
                          borderSide: BorderSide(
                            width: 0.25,
                            color: Colors.grey,
                          ),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: appColor, width: 0.5),
                        ),
                        filled: true,
                        fillColor: color3,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _ecdBuilder(BuildContext context, Size size, double fontSize) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Visibility(
          visible:
              ecdVisible[servicesForIndexing.indexOf(servicesDDValue)] == 'Yes'
                  ? true
                  : false,
          child: Padding(
            padding: EdgeInsets.only(
              top: size.height * .015,
              left: size.width * .025,
            ),
            child: SizedBox(
              height: size.height * .03,
              width: size.width,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    'ECD',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  )
                ],
              ),
            ),
          ),
        ),
        Visibility(
          visible:
              ecdVisible[servicesForIndexing.indexOf(servicesDDValue)] == 'Yes'
                  ? true
                  : false,
          child: Padding(
            padding: EdgeInsets.only(left: size.width * .025),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  height: size.height * .04,
                  width: size.width * .83,
                  decoration: BoxDecoration(
                    color: color3,
                    border: Border.all(width: 0.25, color: Colors.grey),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton(
                        elevation: 0,
                        value: ecdValue,
                        icon: SizedBox(
                          height: 25,
                          width: 25,
                          child: FittedBox(
                            child: Image.asset(
                                'assets/add_new_rule_assets/dd_icon.png'),
                          ),
                        ),
                        items: ecd[servicesForIndexing.indexOf(servicesDDValue)]
                            .map(
                              (value) => DropdownMenuItem(
                                value: value.toString(),
                                child: Text(
                                  value,
                                  style: TextStyle(
                                    fontSize: fontSize,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (Object? newValue) {
                          setState(() {
                            ecdValue = newValue as String;
                          });
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _liabilityBuilder(BuildContext context, Size size, double fontSize) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Visibility(
          visible:
              liabilityVisible[servicesForIndexing.indexOf(servicesDDValue)] ==
                      'Yes'
                  ? true
                  : false,
          child: Padding(
            padding: EdgeInsets.only(
              top: size.height * .015,
              left: size.width * .025,
            ),
            child: SizedBox(
              height: size.height * .03,
              width: size.width,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    'Liability',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  )
                ],
              ),
            ),
          ),
        ),
        Visibility(
          visible:
              liabilityVisible[servicesForIndexing.indexOf(servicesDDValue)] ==
                      'Yes'
                  ? true
                  : false,
          child: Padding(
            padding: EdgeInsets.only(left: size.width * .025),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  height: size.height * .04,
                  width: size.width * .83,
                  decoration: BoxDecoration(
                    color: color3,
                    border: Border.all(width: 0.25, color: Colors.grey),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton(
                        elevation: 0,
                        value: liabilityValue,
                        icon: SizedBox(
                          height: 25,
                          width: 25,
                          child: FittedBox(
                            child: Image.asset(
                                'assets/add_new_rule_assets/dd_icon.png'),
                          ),
                        ),
                        items: liability[
                                servicesForIndexing.indexOf(servicesDDValue)]
                            .map(
                              (value) => DropdownMenuItem(
                                value: value.toString(),
                                child: Text(
                                  value,
                                  style: TextStyle(
                                    fontSize: fontSize,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (Object? newValue) {
                          setState(() {
                            liabilityValue = newValue as String;
                          });
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _preClearedBuilder(BuildContext context, Size size, double fontSize) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Visibility(
          visible:
              preClearedVisible[servicesForIndexing.indexOf(servicesDDValue)] ==
                      'Yes'
                  ? true
                  : false,
          child: Padding(
            padding: EdgeInsets.only(
              top: size.height * .015,
              left: size.width * .025,
            ),
            child: SizedBox(
              height: size.height * .03,
              width: size.width,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    'Pre-Cleared',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  )
                ],
              ),
            ),
          ),
        ),
        Visibility(
          visible:
              preClearedVisible[servicesForIndexing.indexOf(servicesDDValue)] ==
                      'Yes'
                  ? true
                  : false,
          child: Padding(
            padding: EdgeInsets.only(left: size.width * .025),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  height: size.height * .04,
                  width: size.width * .83,
                  decoration: BoxDecoration(
                    color: color3,
                    border: Border.all(
                      width: 0.25,
                      color: Colors.grey,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton(
                        elevation: 0,
                        value: preClearedValue,
                        icon: SizedBox(
                          height: 25,
                          width: 25,
                          child: FittedBox(
                            child: Image.asset(
                                'assets/add_new_rule_assets/dd_icon.png'),
                          ),
                        ),
                        items: preCleared[
                                servicesForIndexing.indexOf(servicesDDValue)]
                            .map(
                              (value) => DropdownMenuItem(
                                value: value.toString(),
                                child: Text(
                                  value,
                                  style: TextStyle(
                                    fontSize: fontSize,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (Object? newValue) {
                          setState(() {
                            preClearedValue = newValue as String;
                          });
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _recipientNotificationBuilder(
      BuildContext context, Size size, double fontSize) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Visibility(
          visible: recipientNotificationVisible[
                      servicesForIndexing.indexOf(servicesDDValue)] ==
                  'Yes'
              ? true
              : false,
          child: Padding(
            padding: EdgeInsets.only(
              top: size.height * .015,
              left: size.width * .025,
            ),
            child: SizedBox(
              height: size.height * .03,
              width: size.width,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    'Recipient Notification',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  )
                ],
              ),
            ),
          ),
        ),
        Visibility(
          visible: recipientNotificationVisible[
                      servicesForIndexing.indexOf(servicesDDValue)] ==
                  'Yes'
              ? true
              : false,
          child: Padding(
            padding: EdgeInsets.only(left: size.width * .025),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  height: size.height * .04,
                  width: size.width * .83,
                  decoration: BoxDecoration(
                    color: color3,
                    border: Border.all(width: 0.25, color: Colors.grey),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton(
                        elevation: 0,
                        value: recipientNotificationValue,
                        icon: SizedBox(
                          height: 25,
                          width: 25,
                          child: FittedBox(
                            child: Image.asset(
                                'assets/add_new_rule_assets/dd_icon.png'),
                          ),
                        ),
                        items: recipientNotification[
                                servicesForIndexing.indexOf(servicesDDValue)]
                            .map(
                              (value) => DropdownMenuItem(
                                value: value.toString(),
                                child: Text(
                                  value,
                                  style: TextStyle(
                                    fontSize: fontSize,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (Object? newValue) {
                          setState(() {
                            recipientNotificationValue = newValue as String;
                          });
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _showHideServiceEnhancements(BuildContext context, Size size) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: size.height * .025),
      child: Container(
        height: size.height * .04,
        width: size.width * .83,
        decoration: BoxDecoration(
          border: Border.all(
            color: isBorderForEnhancementButton == true
                ? Colors.black
                : Colors.transparent,
            width: isBorderForEnhancementButton == true ? 2 : 0,
          ),
          borderRadius: BorderRadius.circular(
              isBorderForEnhancementButton == true ? 5 : 0),
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: color4,
          ),
          onPressed: () {
            setState(() {
              isHideService = !isHideService;
              isBorderForEnhancementButton = true;
            });
          },
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.remove_red_eye,
                size: 16,
                color: Colors.black,
              ),
              Padding(
                padding: EdgeInsets.only(left: 10),
                child: Text(
                  'Show / hide service enhancements',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// SHIPPING BUILDER HELPER WIDGET ENDS

  Widget _iossBuilder(BuildContext context, Size size, double fontSize) {
    return Padding(
      padding: EdgeInsets.only(top: size.height * .02),
      child: Container(
        height: size.height * .13,
        width: size.width * .88,
        decoration: BoxDecoration(
          color: color2,
          border: Border.all(
            width: 0.25,
            color: Colors.grey,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(
                top: size.height * .015,
                left: size.width * .025,
              ),
              child: SizedBox(
                height: size.height * .03,
                width: size.width,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      'IOSS Number',
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(
                left: size.width * .025,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(
                    height: size.height * .04,
                    width: size.width * .83,
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: ThemeData().colorScheme.copyWith(
                              primary: appColor,
                            ),
                      ),
                      child: TextFormField(
                        controller: iossController,
                        textAlignVertical: TextAlignVertical.top,
                        cursorColor: appColor,
                        style: TextStyle(
                          fontSize: fontSize,
                          color: Colors.black,
                        ),
                        decoration: InputDecoration(
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 10),
                          enabledBorder: const OutlineInputBorder(
                            borderSide: BorderSide(
                              width: 0.25,
                              color: Colors.grey,
                            ),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderSide: BorderSide(
                              color: appColor,
                              width: 0.5,
                            ),
                          ),
                          filled: true,
                          fillColor: color3,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _saveRuleBuilder(BuildContext context, Size size) {
    return Padding(
      padding: EdgeInsets.only(top: size.height * .025),
      child: SizedBox(
        height: size.height * .05,
        width: size.width,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 15),
              child: RoundedLoadingButton(
                color: Colors.red,
                borderRadius: 5,
                elevation: 5,
                height: size.height * .05,
                width: size.width * .07,
                successIcon: Icons.check_rounded,
                failedIcon: Icons.close_rounded,
                successColor: Colors.green,
                errorColor: Colors.red,
                controller: cancelController,
                onPressed: () async {
                  FocusScope.of(context).unfocus();
                  await Future.delayed(const Duration(milliseconds: 500), () {
                    cancelController.reset();
                    Navigator.pop(context, false);
                  });
                },
                child: Row(
                  children: [
                    const Icon(
                      Icons.close,
                      color: Colors.white,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 5),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: ResponsiveCheck.isLargeScreen(context)
                                ? size.width * .012
                                : ResponsiveCheck.isMediumScreen(context)
                                    ? size.width * .015
                                    : size.width * .018),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 15),
              child: RoundedLoadingButton(
                color: Colors.red,
                borderRadius: 5,
                elevation: 5,
                height: size.height * .05,
                width: size.width * .12,
                successIcon: Icons.check_rounded,
                failedIcon: Icons.close_rounded,
                successColor: Colors.green,
                errorColor: Colors.red,
                controller: removeRuleController,
                onPressed: () async {
                  FocusScope.of(context).unfocus();
                  await showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) {
                      return StatefulBuilder(
                        builder: (context, setStateSB) {
                          return AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                            elevation: 5,
                            titleTextStyle: TextStyle(
                              color: Colors.black,
                              fontSize: size.width * .042,
                              fontWeight: FontWeight.bold,
                            ),
                            title: Text(
                              'Delete Rule',
                              style: TextStyle(fontSize: size.width * .015),
                            ),
                            content: Text(
                              'Do you really want to delete the rule?',
                              style: TextStyle(fontSize: size.width * .01),
                            ),
                            actions: <Widget>[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(left: 13),
                                    child: RoundedLoadingButton(
                                      color: appColor,
                                      borderRadius: 10,
                                      height: size.width * .025,
                                      width: size.width * .06,
                                      successIcon: Icons.check_rounded,
                                      failedIcon: Icons.close_rounded,
                                      successColor: Colors.green,
                                      controller: noController,
                                      onPressed: () async {
                                        await Future.delayed(
                                            const Duration(milliseconds: 500),
                                            () async {
                                          noController.reset();
                                          Navigator.pop(context);
                                          await Future.delayed(
                                              const Duration(milliseconds: 500),
                                              () {
                                            removeRuleController.reset();
                                          });
                                        });
                                      },
                                      child: const Text('No'),
                                    ),
                                  ),
                                  Expanded(
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(right: 13),
                                          child: RoundedLoadingButton(
                                            color: appColor,
                                            borderRadius: 10,
                                            height: size.width * .025,
                                            width: size.width * .06,
                                            successIcon: Icons.check_rounded,
                                            failedIcon: Icons.close_rounded,
                                            successColor: Colors.green,
                                            controller: yesController,
                                            onPressed: () async {
                                              await deleteRule(
                                                      objectId: widget.objectId)
                                                  .whenComplete(() async {
                                                await Future.delayed(
                                                    const Duration(seconds: 1),
                                                    () async {
                                                  yesController.reset();
                                                  Fluttertoast.showToast(
                                                      msg:
                                                          'Rule deleted successfully!');
                                                  Navigator.pop(context);
                                                });
                                              }).whenComplete(() =>
                                                      Navigator.pop(
                                                          context, true));
                                            },
                                            child: const Text('Yes'),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      );
                    },
                  );
                },
                child: Row(
                  children: [
                    const Icon(
                      Icons.delete_outline,
                      color: Colors.white,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 5),
                      child: Text(
                        'Remove this Rule',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: ResponsiveCheck.isLargeScreen(context)
                                ? size.width * .012
                                : ResponsiveCheck.isMediumScreen(context)
                                    ? size.width * .015
                                    : size.width * .018),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(right: size.width * .025),
              child: RoundedLoadingButton(
                color: Colors.green,
                borderRadius: 5,
                elevation: 5,
                height: size.height * .05,
                width: size.width * .07,
                successIcon: Icons.check_rounded,
                failedIcon: Icons.close_rounded,
                successColor: Colors.green,
                errorColor: Colors.red,
                controller: saveRuleController,
                onPressed: () async {
                  FocusScope.of(context).unfocus();
                  if (conditionsTypeDDValue
                          .any((e) => e == '--- choose a condition ---') ==
                      true) {
                    Fluttertoast.showToast(
                        msg: 'Please select a condition first');
                    await Future.delayed(const Duration(seconds: 1), () {
                      saveRuleController.reset();
                    });
                  } else {
                    /// Save Rule
                    saveRules(
                      objectId: widget.objectId,
                      ruleName: ruleNameController.text,
                      isActive: isActiveChecked == true ? 'Yes' : 'No',
                      conditionedItem: itemsToBeConditionedDDValue,
                      conditionType: conditionsTypeDDValue,
                      conditionValue: conditionValueSave,
                      shipFrom: shipFromDDValue,
                      carrier: carrierValue,
                      service: servicesDDValue,
                      packageType: packageTypeDDValue,
                      addressVTN: virtualTrackingDDValue,
                      addresseeIRN:
                          addresseeIdentificationController.text.isEmpty
                              ? 'empty'
                              : addresseeIdentificationController.text,
                      classX: classDDValue,
                      guarantee: guaranteeValue,
                      lc: localCollectValue,
                      lcLocationNameValue: lcLocationNameController.text.isEmpty
                          ? 'empty'
                          : lcLocationNameController.text,
                      lcLocationTypeValue: lcLocationTypeController.text.isEmpty
                          ? 'empty'
                          : lcLocationTypeController.text,
                      notification: notificationTypeValue,
                      safePlace: safePlaceValue,
                      serviceLevelValue: serviceLevelCodeController.text.isEmpty
                          ? 'empty'
                          : serviceLevelCodeController.text,
                      parcelShape: parcelShapeValue,
                      postalChargesValue: postalChargesController.text.isEmpty
                          ? 'empty'
                          : postalChargesController.text,
                      satDelivery: satDeliveryValue,
                      signedConsignment: signedConsignmentValue,
                      dgMedicine: dgMedicinesValue,
                      dgPerfume: dgPerfumeValue,
                      dgNail: dgNailValue,
                      dgToiletry: dgToiletryValue,
                      customInvoice: customInvoiceValue,
                      destinationTaxValue: destinationTaxController.text.isEmpty
                          ? 'empty'
                          : destinationTaxController.text,
                      ecd: ecdValue,
                      liability: liabilityValue,
                      preCleared: preClearedValue,
                      recipientNotification: recipientNotificationValue,
                      ioss: iossController.text.isEmpty
                          ? 'empty'
                          : iossController.text,
                      copiedFrom: widget.copiedFrom,
                    ).whenComplete(() {
                      Fluttertoast.showToast(msg: 'Updated Successfully');
                    }).whenComplete(() async {
                      await Future.delayed(const Duration(seconds: 1), () {
                        saveRuleController.reset();
                      });
                    });
                  }
                },
                child: Text(
                  'Save Rule',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: ResponsiveCheck.isLargeScreen(context)
                          ? size.width * .012
                          : ResponsiveCheck.isMediumScreen(context)
                              ? size.width * .015
                              : size.width * .018),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> saveRules({
    required String objectId,
    required String ruleName,
    required String isActive,
    required List<String> conditionedItem,
    required List<String> conditionType,
    required List<String> conditionValue,
    required String shipFrom,
    required String carrier,
    required String service,
    required String packageType,
    required String addressVTN,
    required String addresseeIRN,
    required String classX,
    required String guarantee,
    required String lc,
    required String lcLocationNameValue,
    required String lcLocationTypeValue,
    required String notification,
    required String safePlace,
    required String serviceLevelValue,
    required String parcelShape,
    required String postalChargesValue,
    required String satDelivery,
    required String signedConsignment,
    required String dgMedicine,
    required String dgPerfume,
    required String dgNail,
    required String dgToiletry,
    required String customInvoice,
    required String destinationTaxValue,
    required String ecd,
    required String liability,
    required String preCleared,
    required String recipientNotification,
    required String ioss,
    required String copiedFrom,
  }) async {
    var shippingRulesList = ParseObject('Shipping_Rules_List')
      ..objectId = objectId
      ..set('rule_name', ruleName)
      ..set('is_active_rule', isActive)
      ..set('conditioned_item', conditionedItem)
      ..set('condition_type', conditionType)
      ..set('condition_value', conditionValue)
      ..set('ship_from_value', shipFrom)
      ..set('carrier_name', carrier)
      ..set('service_name', service)
      ..set('package_type_value', packageType)
      ..set('address_vtn_value', addressVTN)
      ..set('addressee_irn_value', addresseeIRN)
      ..set('class_value', classX)
      ..set('guarantee_value', guarantee)
      ..set('local_collect_value', lc)
      ..set('lc_location_name_value', lcLocationNameValue)
      ..set('lc_location_type_value', lcLocationTypeValue)
      ..set('notification_value', notification)
      ..set('safeplace_value', safePlace)
      ..set('parcel_shape_value', parcelShape)
      ..set('postal_charges_value', postalChargesValue)
      ..set('service_level_value', serviceLevelValue)
      ..set('sat_delivery_value', satDelivery)
      ..set('signed_consignment_value', signedConsignment)
      ..set('dg_medicine_value', dgMedicine)
      ..set('dg_perfume_value', dgPerfume)
      ..set('dg_nail_value', dgNail)
      ..set('dg_toiletry_value', dgToiletry)
      ..set('custom_invoice_value', customInvoice)
      ..set('destination_tax_value', destinationTaxValue)
      ..set('ecd_value', ecd)
      ..set('liability_value', liability)
      ..set('precleared_value', preCleared)
      ..set('recipient_notification_value', recipientNotification)
      ..set('ioss_number', ioss)
      ..set('copied_from', copiedFrom);
    await shippingRulesList.save();
  }

  Future<void> saveRuleOrderAfterReorder({
    required String objectId,
    required int newOrderIndex,
  }) async {
    var shippingRulesList = ParseObject('Shipping_Rules_List')
      ..objectId = objectId
      ..set('rule_order_index', newOrderIndex);

    await shippingRulesList.save();
  }

  void loadingShippingRulesData() async {
    isLoading = true;
    await ApiCalls.getWeblegsShippingRules().then((data) {
      log('shipping rules data - ${jsonEncode(data)}');
      if (data.isEmpty) {
        Fluttertoast.showToast(
                msg:
                    'Internet may not be available, Please check your connection and Restart the app.',
                toastLength: Toast.LENGTH_LONG)
            .whenComplete(() {
          setState(() {
            errorVisible = true;
            isLoading = false;
          });
        });
      } else {
        shippingRulesFromDB = [];

        shippingRulesFromDB.addAll(data.map((e) => e));
        log('shippingRulesFromDB - ${jsonEncode(shippingRulesFromDB)}');

        /// /// START CONDITIONS ////

        itemsToBeConditionedNames = [];
        conditionsList = [];

        itemsToBeConditionedNames.addAll(shippingRulesFromDB
            .map((e) => e.get<String>('items_to_be_conditioned_names') ?? ''));

        itemsToBeConditionedNames.removeWhere((e) => e == 'empty');
        log('itemsToBeConditionedNames - $itemsToBeConditionedNames');

        conditionsList.addAll(shippingRulesFromDB
            .map((e) => e.get<List<dynamic>>('conditions_list') ?? []));
        conditionsList.removeWhere((e) => e.toList().isEmpty == true);
        log("availableConditionsList >>>>> $conditionsList");

        /// /// END CONDITIONS /////

        shipFrom = [];
        shipFrom.addAll(
            shippingRulesFromDB.map((e) => e.get<String>('ship_from') ?? ''));
        shipFrom.removeWhere((e) => e == 'empty');

        carrier = [];
        carrier.addAll(
            shippingRulesFromDB.map((e) => e.get<String>('carrier') ?? ''));
        carrier.removeWhere((e) => e == 'empty');

        log('carrier >>>>> $carrier');

        services = [];
        services.addAll(shippingRulesFromDB
            .where((el) => el.get<String>('service_type') == widget.carrier)
            .map((e) => e.get<String>('services') ?? ''));

        servicesForIndexing = [];
        servicesForIndexing.addAll(
            shippingRulesFromDB.map((e) => e.get<String>('services') ?? ''));

        serviceType = [];
        serviceType.addAll(shippingRulesFromDB
            .map((e) => e.get<String>('service_type') ?? ''));

        packageTypeVisible = [];
        packageType = [];
        packageTypeVisible.addAll(shippingRulesFromDB
            .map((e) => e.get<String>('package_type_visible') ?? ''));
        packageType.addAll(shippingRulesFromDB
            .map((e) => e.get<List<dynamic>>('package_type') ?? []));

        virtualTrackingVisible = [];
        virtualTracking = [];
        virtualTrackingVisible.addAll(shippingRulesFromDB.map(
            (e) => e.get<String>('virtual_tracking_number_visible') ?? ''));
        virtualTracking.addAll(shippingRulesFromDB
            .map((e) => e.get<List<dynamic>>('virtual_tracking_number') ?? []));

        addressIdentificationVisible = [];
        addressIdentificationVisible.addAll(shippingRulesFromDB
            .map((e) => e.get<String>('address_identification_visible') ?? ''));

        classVisible = [];
        classVisible.addAll(shippingRulesFromDB
            .map((e) => e.get<String>('class_visible') ?? ''));

        classX = [];
        classX.addAll(shippingRulesFromDB
            .map((e) => e.get<List<dynamic>>('class_x') ?? []));

        guaranteeVisible = [];
        guarantee = [];
        guaranteeVisible.addAll(shippingRulesFromDB
            .map((e) => e.get<String>('guarantee_visible') ?? ""));
        guarantee.addAll(shippingRulesFromDB
            .map((e) => e.get<List<dynamic>>('guarantee') ?? []));

        localCollect = [];
        localCollectVisible = [];
        localCollect.addAll(shippingRulesFromDB
            .map((e) => e.get<List<dynamic>>('local_collect') ?? []));
        localCollectVisible.addAll(shippingRulesFromDB
            .map((e) => e.get<String>('local_collect_visible') ?? ""));

        lcLocationNameVisible = [];
        lcLocationTypeVisible = [];
        lcLocationNameVisible.addAll(shippingRulesFromDB
            .map((e) => e.get<String>('lc_location_name_visible') ?? ""));
        lcLocationTypeVisible.addAll(shippingRulesFromDB
            .map((e) => e.get<String>('lc_location_type_visible') ?? ""));

        notificationTypeVisible = [];
        notificationType = [];
        notificationTypeVisible.addAll(shippingRulesFromDB
            .map((e) => e.get<String>('notification_type_visible') ?? ""));
        notificationType.addAll(shippingRulesFromDB
            .map((e) => e.get<List<dynamic>>('notification_type') ?? []));

        safePlaceVisible = [];
        safePlace = [];
        safePlaceVisible.addAll(shippingRulesFromDB
            .map((e) => e.get<String>('safeplace_visible') ?? ""));
        safePlace.addAll(shippingRulesFromDB
            .map((e) => e.get<List<dynamic>>('safeplace') ?? []));

        parcelShapeVisible = [];
        parcelShape = [];
        parcelShapeVisible.addAll(shippingRulesFromDB
            .map((e) => e.get<String>('parcel_shape_visible') ?? ""));
        parcelShape.addAll(shippingRulesFromDB
            .map((e) => e.get<List<dynamic>>('parcel_shape') ?? []));

        postalChargesVisible = [];
        postalChargesVisible.addAll(shippingRulesFromDB
            .map((e) => e.get<String>('postal_charges_visible') ?? ""));

        satDeliveryVisible = [];
        satDelivery = [];
        satDeliveryVisible.addAll(shippingRulesFromDB
            .map((e) => e.get<String>('sat_delivery_visible') ?? ""));
        satDelivery.addAll(shippingRulesFromDB
            .map((e) => e.get<List<dynamic>>('sat_delivery') ?? []));

        serviceLevelCodeVisible = [];
        serviceLevelCodeVisible.addAll(shippingRulesFromDB
            .map((e) => e.get<String>('service_level_code_visible') ?? ""));

        signedConsignmentVisible = [];
        signedConsignment = [];
        signedConsignmentVisible.addAll(shippingRulesFromDB
            .map((e) => e.get<String>('signed_consignment_visible') ?? ""));
        signedConsignment.addAll(shippingRulesFromDB
            .map((e) => e.get<List<dynamic>>('signed_consignment') ?? []));

        dgMedicinesVisible = [];
        dgMedicines = [];
        dgMedicinesVisible.addAll(shippingRulesFromDB
            .map((e) => e.get<String>('dg_medicines_visible') ?? ""));
        dgMedicines.addAll(shippingRulesFromDB
            .map((e) => e.get<List<dynamic>>('dg_medicines') ?? []));

        dgPerfumeVisible = [];
        dgPerfume = [];
        dgPerfumeVisible.addAll(shippingRulesFromDB
            .map((e) => e.get<String>('dg_perfume_visible') ?? ""));
        dgPerfume.addAll(shippingRulesFromDB
            .map((e) => e.get<List<dynamic>>('dg_perfume') ?? []));

        dgNailVisible = [];
        dgNail = [];
        dgNailVisible.addAll(shippingRulesFromDB
            .map((e) => e.get<String>('dg_nail_varnish_visible') ?? ""));
        dgNail.addAll(shippingRulesFromDB
            .map((e) => e.get<List<dynamic>>('dg_nail_varnish') ?? []));

        dgToiletryVisible = [];
        dgToiletry = [];
        dgToiletryVisible.addAll(shippingRulesFromDB
            .map((e) => e.get<String>('dg_toiletry_visible') ?? ""));
        dgToiletry.addAll(shippingRulesFromDB
            .map((e) => e.get<List<dynamic>>('dg_toiletry') ?? []));

        /// CHANGES FOR DPD CARRIER - 04 JUNE, 2023
        customInvoiceVisible = [];
        customInvoice = [];
        customInvoiceVisible.addAll(shippingRulesFromDB
            .map((e) => e.get<String>('customs_invoice_type_visible') ?? ""));
        customInvoice.addAll(shippingRulesFromDB
            .map((e) => e.get<List<dynamic>>('customs_invoice_type') ?? []));

        destinationTaxVisible = [];
        destinationTaxVisible.addAll(shippingRulesFromDB
            .map((e) => e.get<String>('destination_tax_number_visible') ?? ""));

        ecdVisible = [];
        ecd = [];
        ecdVisible.addAll(
            shippingRulesFromDB.map((e) => e.get<String>('ecd_visible') ?? ""));
        ecd.addAll(
            shippingRulesFromDB.map((e) => e.get<List<dynamic>>('ecd') ?? []));

        liabilityVisible = [];
        liability = [];
        liabilityVisible.addAll(shippingRulesFromDB
            .map((e) => e.get<String>('liability_visible') ?? ""));
        liability.addAll(shippingRulesFromDB
            .map((e) => e.get<List<dynamic>>('liability') ?? []));

        preClearedVisible = [];
        preCleared = [];
        preClearedVisible.addAll(shippingRulesFromDB
            .map((e) => e.get<String>('precleared_visible') ?? ""));
        preCleared.addAll(shippingRulesFromDB
            .map((e) => e.get<List<dynamic>>('precleared') ?? []));

        recipientNotificationVisible = [];
        recipientNotification = [];
        recipientNotificationVisible.addAll(shippingRulesFromDB
            .map((e) => e.get<String>('recipient_notification_visible') ?? ""));
        recipientNotification.addAll(shippingRulesFromDB
            .map((e) => e.get<List<dynamic>>('recipient_notification') ?? []));

        /// adding data as per data from a saved rule

        setState(() {
          carrierValue = widget.carrier;
          shipFromDDValue = widget.shipFrom;
          servicesDDValue = widget.service;
          packageTypeDDValue = widget.packageType;
          virtualTrackingDDValue = widget.addressVTN;
          classDDValue = widget.classX;
          guaranteeValue = widget.guarantee;
          localCollectValue = widget.lc;
          notificationTypeValue = widget.notification;
          safePlaceValue = widget.safePlace;
          parcelShapeValue = widget.parcelShape;
          satDeliveryValue = widget.satDelivery;
          signedConsignmentValue = widget.signedConsignment;
          dgMedicinesValue = widget.dgMedicine;
          dgPerfumeValue = widget.dgPerfume;
          dgNailValue = widget.dgNail;
          dgToiletryValue = widget.dgToiletry;
          customInvoiceValue = widget.customInvoice;
          ecdValue = widget.ecd;
          liabilityValue = widget.liability;
          preClearedValue = widget.preCleared;
          recipientNotificationValue = widget.recipientNotification;

          itemsToBeConditionedDDValue
              .addAll(widget.conditionItem.map((e) => e.toString()));
          conditionsTypeDDValue
              .addAll(widget.conditionType.map((e) => e.toString()));

          ///valueForCondController is added in initState

          isActiveChecked = widget.isActive == 'Yes' ? true : false;

          ruleNameController.text =
              widget.ruleName == 'empty' ? '' : widget.ruleName;

          addresseeIdentificationController.text =
              widget.addresseeIRN == 'empty' ? '' : widget.addresseeIRN;
          lcLocationNameController.text = widget.lcLocationNameValue == 'empty'
              ? ''
              : widget.lcLocationNameValue;
          lcLocationTypeController.text = widget.lcLocationTypeValue == 'empty'
              ? ''
              : widget.lcLocationTypeValue;
          postalChargesController.text = widget.postalChargesValue == 'empty'
              ? ''
              : widget.postalChargesValue;
          serviceLevelCodeController.text = widget.serviceLevelValue == 'empty'
              ? ''
              : widget.serviceLevelValue;
          destinationTaxController.text =
              widget.destinationTax == 'empty' ? '' : widget.destinationTax;
          iossController.text =
              widget.iossNumber == 'empty' ? '' : widget.iossNumber;
        });

        setState(() {
          noOfConditionsToShow = widget.conditionItem.length;
        });

        for (int i = 0; i < widget.conditionItem.length; i++) {
          itemsToBeConditionedNames
              .removeWhere((e) => e == widget.conditionItem[i]);
        }

        for (int i = 0; i < widget.conditionItem.length; i++) {
          List<String> tempList = [];
          tempList.addAll(itemsToBeConditionedNames.map((e) => e));
          tempList.add(widget.conditionItem[i]);
          listOfItemsToBeConditionedNames.add(tempList);
          tempList = [];
          setState(() {});
        }

        itemsToBeConditionedNames = [];
        itemsToBeConditionedNames.addAll(shippingRulesFromDB
            .map((e) => e.get<String>('items_to_be_conditioned_names') ?? ''));
        itemsToBeConditionedNames.removeWhere((e) => e == 'empty');
        log('itemsToBeConditionedNames - $itemsToBeConditionedNames');

        Future.delayed(const Duration(seconds: 1), () {
          setState(() {
            errorVisible = false;
            isLoading = false;
          });
        });
      }
    });
  }

  Future<void> deleteRule({required String objectId}) async {
    var shippingRulesList = ParseObject('Shipping_Rules_List')
      ..objectId = objectId;

    await shippingRulesList.delete();
  }
}
