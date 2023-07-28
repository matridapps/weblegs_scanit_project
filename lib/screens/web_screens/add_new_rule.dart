import 'dart:convert';
import 'dart:developer';

import 'package:absolute_app/core/apis/api_calls.dart';
import 'package:absolute_app/core/utils/constants.dart';
import 'package:absolute_app/core/utils/widgets.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:parse_server_sdk/parse_server_sdk.dart';

class AddNewRule extends StatefulWidget {
  const AddNewRule({Key? key}) : super(key: key);

  @override
  State<AddNewRule> createState() => _AddNewRuleState();
}

class _AddNewRuleState extends State<AddNewRule> {
  List<ParseObject> shippingRulesFromDB = [];

  late TextEditingController ruleNameController;
  late TextEditingController valueForCondController;

  late FocusNode ruleNameNode;
  late FocusNode valueForCondNode;

  bool isActiveChecked = true;
  bool errorVisible = false;
  bool isLoading = true;

  /// DD : DropDown
  List<int> itemsToBeConditionedDDValue = [0];
  List<int> conditionsTypeDDValue = [0];
  int noOfConditionsSlab = 1;

  List<String> itemsToBeConditionedNames = [];

  List<List<dynamic>> availableConditionsList = <List<String>>[];

  List<RuleModel> itemsToBeConditionedList = [];
  List<ConditionsModel> selectedListOfConditions = [];

  @override
  void initState() {
    super.initState();
    ruleNameController = TextEditingController();
    valueForCondController = TextEditingController();
    ruleNameNode = FocusNode();
    valueForCondNode = FocusNode();

    loadingShippingRulesData();
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    FocusScopeNode currentFocus = FocusScope.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.white,
        automaticallyImplyLeading: true,
        iconTheme: const IconThemeData(color: Colors.black),
        centerTitle: true,
        toolbarHeight: AppBar().preferredSize.height,
        title: Text(
          'Add New Rule',
          style: TextStyle(
            fontSize: size.height * .03,
            color: Colors.black,
          ),
        ),
      ),
      body: isLoading == true
          ? const Center(
              child: CircularProgressIndicator(
                color: appColor,
              ),
            )
          : errorVisible == true
              ? const Center(
                  child: Text(
                      'Internet may not be available, Please check your connection and Restart the app.'),
                )
              : SingleChildScrollView(
                  child: GestureDetector(
                    onTap: () {
                      FocusScope.of(context).requestFocus(FocusNode());
                      if (!currentFocus.hasPrimaryFocus) {
                        currentFocus.unfocus();
                      }
                    },
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: size.height * .015,
                        horizontal: size.width * .035,
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            ruleNameBuilder(context, size),
                            verticalSpacer(context, size.height * .035),
                            conditionsOuterBuilder(context, size),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
    );
  }

  Widget ruleNameBuilder(BuildContext context, Size size) {
    return LayoutBuilder(builder: (_, c) {
      final width = c.maxWidth;
      double tFontSize = 16.0;
      double stFontSize = 10.0;
      if (width <= 480) {
        tFontSize = 16.0;
        stFontSize = 10.0;
      } else if (width > 480 && width <= 960) {
        tFontSize = 21.0;
        stFontSize = 13.0;
      } else {
        tFontSize = 26.0;
        stFontSize = 16.0;
      }
      return Container(
        height: size.height * .27,
        width: size.width,
        color: Colors.grey.shade200,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(
                left: size.width * .05,
                right: size.width * .05,
                top: size.height * .02,
                bottom: size.height * .02,
              ),
              child: Row(
                children: [
                  Text(
                    'Rule Name',
                    style: TextStyle(
                      fontSize: tFontSize,
                      color: Colors.black,
                    ),
                  )
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.only(
                left: size.width * .05,
              ),
              child: SizedBox(
                height: size.height * .05,
                width: size.width,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      'Name',
                      style: TextStyle(
                        fontSize: stFontSize,
                      ),
                    )
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(
                left: size.width * .05,
                top: size.height * .005,
                right: size.width * .05,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(
                    height: size.height * .05,
                    width: size.width * .7,
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: ThemeData().colorScheme.copyWith(
                              primary: appColor,
                            ),
                      ),
                      child: TextFormField(
                        focusNode: ruleNameNode,
                        controller: ruleNameController,
                        style: TextStyle(
                          fontSize: stFontSize,
                          color: Colors.black,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Name',
                          border: OutlineInputBorder(
                            borderSide: BorderSide(width: 0.5),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: appColor, width: 1),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.only(
                left: size.width * .05,
                top: size.height * .01,
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
                    Text(
                      'Active',
                      style: TextStyle(
                        fontSize: stFontSize,
                      ),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget conditionsOuterBuilder(BuildContext context, Size size) {
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
        tFontSize = 21.0;
        stFontSize = 13.0;
        buttonWidth = 130.0;
      } else {
        tFontSize = 26.0;
        stFontSize = 16.0;
        buttonWidth = 160.0;
      }
      return Container(
        color: Colors.grey.shade200,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(
                left: size.width * .05,
                right: size.width * .05,
                top: size.height * .015,
              ),
              child: SizedBox(
                height: size.height * .035,
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
                left: size.width * .05,
                top: size.height * .015,
                right: size.width * .05,
              ),
              child: Column(
                children: conditionsInnerBuilder(context, size),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(
                right: size.width * .025,
                top: size.height * .01,
                bottom: size.width * .025,
              ),
              child: SizedBox(
                height: size.height * .05,
                width: size.width,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.lightGreen,
                        minimumSize: Size.zero,
                        padding: const EdgeInsets.all(5),
                      ),
                      onPressed: () {
                        setState(() {
                          noOfConditionsSlab = noOfConditionsSlab + 1;

                        itemsToBeConditionedDDValue.add(0);
                        conditionsTypeDDValue.add(0);
                        log('itemsToBeConditionedDDValue >>>>>>>>> $itemsToBeConditionedDDValue');
                        log('conditionsTypeDDValue >>>>> $conditionsTypeDDValue');
                        conditionsInnerBuilder(context, size)
                            .add(singleInnerBuilder(context, size, noOfConditionsSlab - 1));
                        log('noOfConditionsSlab - $noOfConditionsSlab');
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
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget singleInnerBuilder(BuildContext context, Size size, int indexOfDDValues) {
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
        fieldFontSize = 12.0;
        buttonWidth = 85.0;
      }
      return Container(
        height: size.height * .08,
        width: size.width,
        color: Colors.white70,
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
                    child: Card(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.grey.shade100,
                            width: 1,
                          ),
                        ),
                        child: Container(
                          height: size.height * .06,
                          width: ddWidth,
                          decoration: BoxDecoration(
                              border:
                                  Border.all(width: 0.25, color: Colors.grey)),
                          child: Padding(
                            padding: const EdgeInsets.only(left: 5),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton(
                                elevation: 0,
                                value: itemsToBeConditionedDDValue[
                                    indexOfDDValues],
                                icon: SizedBox(
                                  height: 25,
                                  width: 25,
                                  child: FittedBox(
                                    child: Image.asset(
                                        'assets/add_new_rule_assets/dd_icon.png'),
                                  ),
                                ),
                                items: itemsToBeConditionedList
                                    .map(
                                      (value) => DropdownMenuItem(
                                        value: value.id,
                                        child: Text(
                                          value.value,
                                          style: TextStyle(
                                              fontSize: fieldFontSize),
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (Object? newValue) {
                                  setState(() {
                                    log('indexOfDDValues >>>> $indexOfDDValues');
                                    itemsToBeConditionedDDValue[indexOfDDValues] = newValue as int;
                                    selectedListOfConditions = [];
                                    selectedListOfConditions = List.generate(
                                        itemsToBeConditionedList[newValue]
                                            .availableConditions
                                            .length,
                                        (index) => ConditionsModel(
                                            index,
                                            itemsToBeConditionedList[newValue]
                                                .availableConditions[index]));
                                    conditionsTypeDDValue[
                                        indexOfDDValues] = 0;
                                  });
                                  log('itemsToBeConditionedDDValue >>>>> $itemsToBeConditionedDDValue[indexOfDDValues]');
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Visibility(
                    visible:
                        itemsToBeConditionedDDValue[indexOfDDValues] !=
                            0,
                    child: Padding(
                      padding: EdgeInsets.only(left: size.width * .01),
                      child: Card(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.grey.shade100,
                              width: 1,
                            ),
                          ),
                          child: Container(
                            height: size.height * .06,
                            width: ddWidth,
                            decoration: BoxDecoration(
                                border: Border.all(
                                    width: 0.25, color: Colors.grey)),
                            child: Padding(
                              padding: const EdgeInsets.only(left: 5),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton(
                                  elevation: 0,
                                  value: conditionsTypeDDValue[
                                      indexOfDDValues],
                                  icon: SizedBox(
                                    height: 25,
                                    width: 25,
                                    child: FittedBox(
                                      child: Image.asset(
                                          'assets/add_new_rule_assets/dd_icon.png'),
                                    ),
                                  ),
                                  items: selectedListOfConditions
                                      .map(
                                        (value) => DropdownMenuItem(
                                          value: value.id,
                                          child: Text(
                                            value.conditionsValue,
                                            style: TextStyle(
                                              fontSize: fieldFontSize,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (Object? newValue) {
                                    setState(() {
                                      conditionsTypeDDValue[indexOfDDValues] = newValue as int;
                                    });
                                    log('conditionsTypeDDValue >>>>> $conditionsTypeDDValue[indexOfDDValues]');
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Visibility(
                      visible:
                          itemsToBeConditionedDDValue[indexOfDDValues] !=
                              0,
                      child: SizedBox(
                        height: size.height * .06,
                        width: ddWidth,
                        child: Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: ThemeData().colorScheme.copyWith(
                                  primary: appColor,
                                ),
                          ),
                          child: TextFormField(
                            focusNode: valueForCondNode,
                            controller: valueForCondController,
                            style: TextStyle(
                              fontSize: stFontSize,
                              color: Colors.black,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Value to Match',
                              border: OutlineInputBorder(
                                borderSide: BorderSide(width: 0.5),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: appColor, width: 1),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                          ),
                        ),
                      )),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.only(right: size.width * .02),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.all(5),
                ),
                onPressed: () {
                  // if (noOfConditionsSlab > 0) {
                  //   setState(() {
                  //     noOfConditionsSlab = indexOfDDValues;
                  //     itemsToBeConditionedDDValue;
                  //     conditionsTypeDDValue = [0];
                  //   });
                  // }
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
            ),
          ],
        ),
      );
    });
  }

  List<Widget> conditionsInnerBuilder(BuildContext context, Size size) {
    return List.generate(noOfConditionsSlab, (index) => singleInnerBuilder(context, size, 0));
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
        itemsToBeConditionedNames = [];
        itemsToBeConditionedList = [];
        availableConditionsList = [];

        shippingRulesFromDB.addAll(data.map((e) => e));
        log('shippingRulesFromDB - ${jsonEncode(shippingRulesFromDB)}');
        itemsToBeConditionedNames.addAll(shippingRulesFromDB
            .map((e) => e.get<String>('items_to_be_conditioned_names') ?? ''));
        log('itemsToBeConditionedNames - $itemsToBeConditionedNames');

        availableConditionsList.addAll(shippingRulesFromDB
            .map((e) => e.get<List<dynamic>>('conditions_list') ?? []));
        log("availableConditionsList >>>>> $availableConditionsList");

        itemsToBeConditionedList = List.generate(
            itemsToBeConditionedNames.length,
            (index) => RuleModel(index, itemsToBeConditionedNames[index],
                availableConditionsList[index]));

        selectedListOfConditions = List.generate(
            itemsToBeConditionedList[0].availableConditions.length,
            (index) => ConditionsModel(
                index, itemsToBeConditionedList[0].availableConditions[index]));

        Future.delayed(const Duration(seconds: 1), () {
          setState(() {
            errorVisible = false;
            isLoading = false;
          });
        });
      }
    });
  }
}

class RuleModel {
  int id;
  String value;
  List<dynamic> availableConditions;

  RuleModel(this.id, this.value, this.availableConditions);
}

class ConditionsModel {
  int id;
  String conditionsValue;

  ConditionsModel(this.id, this.conditionsValue);
}
