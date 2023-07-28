import 'dart:convert';
import 'dart:developer';
import 'dart:math' as math;
import 'dart:ui';

import 'package:absolute_app/core/apis/api_calls.dart';
import 'package:absolute_app/core/utils/constants.dart';
import 'package:absolute_app/core/utils/widgets.dart';
import 'package:absolute_app/screens/web_screens/edit_rule.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:parse_server_sdk/parse_server_sdk.dart';
import 'package:rounded_loading_button/rounded_loading_button.dart';

class ShipmentRulesScreen extends StatefulWidget {
  const ShipmentRulesScreen({Key? key}) : super(key: key);

  @override
  State<ShipmentRulesScreen> createState() => _ShipmentRulesScreenState();
}

class _ShipmentRulesScreenState extends State<ShipmentRulesScreen> {
  List<ParseObject> shippingRulesList = [];

  bool errorVisible = false;
  bool isLoading = true;

  List<String> objectIdList = [];
  List<String> ruleNameList = [];
  List<String> isActiveList = [];
  List<List<dynamic>> conditionItemList = <List<dynamic>>[];
  List<List<dynamic>> conditionTypeList = <List<dynamic>>[];
  List<List<dynamic>> conditionValueList = <List<dynamic>>[];
  List<String> shipFromList = [];
  List<String> carrierList = [];
  List<String> serviceList = [];
  List<String> packageTypeList = [];
  List<String> addressVTNList = [];
  List<String> addresseeIRNList = [];
  List<String> classXList = [];
  List<String> guaranteeList = [];
  List<String> lcList = [];
  List<String> lcLocationNameValueList = [];
  List<String> lcLocationTypeValueList = [];
  List<String> notificationList = [];
  List<String> safePlaceList = [];
  List<String> serviceLevelValueList = [];
  List<String> parcelShapeList = [];
  List<String> postalChargesValueList = [];
  List<String> satDeliveryList = [];
  List<String> signedConsignmentList = [];
  List<String> dgMedicineList = [];
  List<String> dgPerfumeList = [];
  List<String> dgNailList = [];
  List<String> dgToiletryList = [];

  /// 4 PLACES
  /// CHANGES 4 JUNE, 2023 FOR DPD CARRIER --- complete
  List<String> customInvoiceList = [];
  List<String> destinationTaxList = [];
  List<String> ecdList = [];
  List<String> liabilityList = [];
  List<String> preClearedList = [];
  List<String> recipientNotificationList = [];

  List<String> iossNumberList = [];
  List<String> copiedFromList = [];

  List<bool> isActive = [];

  List<int> ruleOrderList = [];

  final RoundedLoadingButtonController yesController =
      RoundedLoadingButtonController();
  final RoundedLoadingButtonController noController =
      RoundedLoadingButtonController();

  Color draggableItemColor = appColor;

  @override
  void initState() {
    super.initState();
    fetchShippingRulesList();

    yesController.stateStream.listen((value) {
      log('yesController >>>>>> $value');
    });
    noController.stateStream.listen((value) {
      log('noController >>>>>> $value');
    });
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return SelectionArea(
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
            'Shipment Rules',
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
                : Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: size.height * .01,
                      horizontal: size.width * .035,
                    ),
                    child: SizedBox(
                      height: size.height * .9,
                      width: size.width,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: size.height * .06,
                            width: size.width,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  'Rules list',
                                  style: TextStyle(
                                    fontSize: size.height * .025,
                                    color: Colors.black,
                                  ),
                                ),
                                Expanded(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Visibility(
                                        visible: false,
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.lightGreen,
                                          ),
                                          onPressed: () async {},
                                          child: Row(
                                            children: const [
                                              Icon(
                                                Icons.add,
                                                color: Colors.white,
                                              ),
                                              Padding(
                                                padding:
                                                    EdgeInsets.only(left: 10),
                                                child: Text('Add a Rule'),
                                              ),
                                            ],
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
                            height: size.height * .01,
                            width: size.width,
                            child: const Center(
                              child: Divider(),
                            ),
                          ),
                          SizedBox(
                            height: size.height * .06,
                            width: size.width,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: const [
                                Flexible(
                                  child: Text(
                                    'Shipment rules help you automate the every day task of deciding which carrier and service to use, and when. The order of the rules is important. The first rule that is correct for a given shipment is the one that is ran.',
                                    style: TextStyle(
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          verticalSpacer(context, size.height * .005),
                          SizedBox(
                            height: size.height * .03,
                            width: size.width,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  'Rule Name',
                                  style: TextStyle(
                                    fontSize: size.height * .017,
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: size.height * .9 -
                                size.height * .03 -
                                size.height * .005 -
                                size.height * .06 -
                                size.height * .01 -
                                size.height * .06,
                            width: size.width,
                            child: ReorderableListView(
                              proxyDecorator: proxyDecorator,
                              children: <Widget>[
                                ...List.generate(
                                  shippingRulesList.length,
                                  (index) => Card(
                                    key: Key('$index'),
                                    elevation: 5,
                                    child: SizedBox(
                                      height: 65,
                                      width: size.width,
                                      child: Column(
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 5, horizontal: 5),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '${ruleNameList[index]} (${carrierList[index]} ${serviceList[index]})',
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                Expanded(
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.end,
                                                    children: [
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                    .only(
                                                                right: 20),
                                                        child: SizedBox(
                                                          height: 50,
                                                          width: 80,
                                                          child: FittedBox(
                                                            child:
                                                                ElevatedButton(
                                                                    onPressed:
                                                                        () async {
                                                                      var isDeleted =
                                                                          await Navigator
                                                                              .push(
                                                                        context,
                                                                        PageRouteBuilder(
                                                                          pageBuilder: (context, animation, secondaryAnimation) => EditRule(
                                                                              objectId: objectIdList[index],
                                                                              ruleName: ruleNameList[index],
                                                                              isActive: isActiveList[index],
                                                                              conditionItem: conditionItemList[index],
                                                                              conditionType: conditionTypeList[index],
                                                                              conditionValue: conditionValueList[index],
                                                                              shipFrom: shipFromList[index],
                                                                              carrier: carrierList[index],
                                                                              service: serviceList[index],
                                                                              packageType: packageTypeList[index],
                                                                              addressVTN: addressVTNList[index],
                                                                              addresseeIRN: addresseeIRNList[index],
                                                                              classX: classXList[index],
                                                                              guarantee: guaranteeList[index],
                                                                              lc: lcList[index],
                                                                              lcLocationNameValue: lcLocationNameValueList[index],
                                                                              lcLocationTypeValue: lcLocationTypeValueList[index],
                                                                              notification: notificationList[index],
                                                                              safePlace: safePlaceList[index],
                                                                              serviceLevelValue: serviceLevelValueList[index],
                                                                              parcelShape: parcelShapeList[index],
                                                                              postalChargesValue: postalChargesValueList[index],
                                                                              satDelivery: satDeliveryList[index],
                                                                              signedConsignment: signedConsignmentList[index],
                                                                              dgMedicine: dgMedicineList[index],
                                                                              dgPerfume: dgPerfumeList[index],
                                                                              dgNail: dgNailList[index],
                                                                              dgToiletry: dgToiletryList[index],
                                                                              customInvoice: customInvoiceList[index],
                                                                              destinationTax: destinationTaxList[index],
                                                                              ecd: ecdList[index],
                                                                              liability: liabilityList[index],
                                                                              preCleared: preClearedList[index],
                                                                              recipientNotification: recipientNotificationList[index],
                                                                              iossNumber: iossNumberList[index],
                                                                              copiedFrom: copiedFromList[index]),
                                                                          transitionsBuilder: (context,
                                                                              animation,
                                                                              secondaryAnimation,
                                                                              child) {
                                                                            const begin =
                                                                                Offset(1.0, 0.0);
                                                                            const end =
                                                                                Offset.zero;
                                                                            const curve =
                                                                                Curves.ease;

                                                                            var tween =
                                                                                Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

                                                                            return SlideTransition(
                                                                              position: animation.drive(tween),
                                                                              child: child,
                                                                            );
                                                                          },
                                                                        ),
                                                                      );

                                                                      if (isDeleted ==
                                                                          true) {
                                                                        await adjustAfterDeletionWhenBack(index: index).whenComplete(() =>
                                                                            fetchShippingRulesList());
                                                                      } else if (isDeleted ==
                                                                          false) {
                                                                        fetchShippingRulesList();
                                                                      }
                                                                    },
                                                                    child: Row(
                                                                      children: const [
                                                                        Icon(
                                                                          Icons
                                                                              .edit,
                                                                          color:
                                                                              Colors.black,
                                                                        ),
                                                                        Padding(
                                                                          padding:
                                                                              EdgeInsets.only(left: 10),
                                                                          child:
                                                                              Text('Edit'),
                                                                        ),
                                                                      ],
                                                                    )),
                                                          ),
                                                        ),
                                                      ),
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                    .only(
                                                                right: 20),
                                                        child: SizedBox(
                                                          height: 50,
                                                          width: 110,
                                                          child: FittedBox(
                                                            child:
                                                                ElevatedButton(
                                                              style: ElevatedButton.styleFrom(
                                                                  backgroundColor: isActive[
                                                                              index] ==
                                                                          true
                                                                      ? Colors
                                                                          .green
                                                                      : Colors
                                                                          .grey),
                                                              onPressed:
                                                                  () async {
                                                                setState(() {
                                                                  isLoading =
                                                                      true;
                                                                  isActive[
                                                                          index] =
                                                                      !(isActive[
                                                                          index]);
                                                                });
                                                                changeActivenessOfRule(
                                                                        objectId:
                                                                            objectIdList[
                                                                                index],
                                                                        isActive: isActive[index] ==
                                                                                true
                                                                            ? 'Yes'
                                                                            : 'No')
                                                                    .whenComplete(
                                                                        () {
                                                                  Fluttertoast.showToast(
                                                                      msg: isActive[index] ==
                                                                              true
                                                                          ? 'Rule activated successfully!'
                                                                          : 'Rule deactivated successfully!');
                                                                  fetchShippingRulesList();
                                                                });
                                                              },
                                                              child: Row(
                                                                children: [
                                                                  Icon(
                                                                    isActive[index] ==
                                                                            true
                                                                        ? Icons
                                                                            .stop
                                                                        : Icons
                                                                            .play_arrow,
                                                                    color: Colors
                                                                        .black,
                                                                  ),
                                                                  Padding(
                                                                      padding: const EdgeInsets
                                                                              .only(
                                                                          left:
                                                                              10),
                                                                      child: Text(isActive[index] ==
                                                                              true
                                                                          ? 'Deactivate'
                                                                          : 'Activate')),
                                                                ],
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                    .only(
                                                                right: 20),
                                                        child: SizedBox(
                                                          height: 50,
                                                          width: 80,
                                                          child: FittedBox(
                                                            child:
                                                                ElevatedButton(
                                                                    onPressed:
                                                                        () async {
                                                                      setState(
                                                                          () {
                                                                        isLoading =
                                                                            true;
                                                                      });
                                                                      List<String>
                                                                          ruleNameCheck =
                                                                          [];
                                                                      int ruleNameCountToSave =
                                                                          0;
                                                                      List<int>
                                                                          extractedNumbers =
                                                                          [];

                                                                      if (shippingRulesList
                                                                          .where((e) =>
                                                                              e.get<String>('copied_from') ==
                                                                              ruleNameList[index])
                                                                          .isEmpty) {
                                                                        /// MEANS THE SELECTED RULE IS NOT COPIED PREVIOUSLY AND GETTING COPIED FOR THE FIRST TIME.

                                                                        setState(
                                                                            () {
                                                                          ruleNameCountToSave =
                                                                              1;
                                                                        });
                                                                      } else {
                                                                        /// MEANS THE SELECTED RULE IS COPIED AT LEAST ONCE PREVIOUSLY.
                                                                        ruleNameCheck.addAll(shippingRulesList
                                                                            .where((e) =>
                                                                                e.get<String>('copied_from') ==
                                                                                ruleNameList[index])
                                                                            .toList()
                                                                            .map((e) => e.get<String>('rule_name') ?? ""));

                                                                        for (int i =
                                                                                0;
                                                                            i < ruleNameCheck.length;
                                                                            i++) {
                                                                          setState(
                                                                              () {
                                                                            ruleNameCheck[i] =
                                                                                ruleNameCheck[i].substring(ruleNameList[index].length + 7, ruleNameCheck[i].length - 1);
                                                                          });
                                                                        }
                                                                        log('extracted Numbers from ruleNameCheck >> $ruleNameCheck');

                                                                        extractedNumbers.addAll(ruleNameCheck.map((e) =>
                                                                            int.parse(e)));
                                                                        log('extracted Numbers List >> $extractedNumbers');

                                                                        setState(
                                                                            () {
                                                                          ruleNameCountToSave =
                                                                              smallestMissingNumber(extractedNumbers);
                                                                        });
                                                                      }

                                                                      await copyRule(
                                                                        ruleOrderIndex:
                                                                            ruleOrderList.reduce(math.max) +
                                                                                1,
                                                                        ruleName:
                                                                            '${ruleNameList[index]} (Copy $ruleNameCountToSave)',
                                                                        isActive:
                                                                            isActiveList[index],
                                                                        conditionedItem:
                                                                            conditionItemList[index],
                                                                        conditionType:
                                                                            conditionTypeList[index],
                                                                        conditionValue:
                                                                            conditionValueList[index],
                                                                        shipFrom:
                                                                            shipFromList[index],
                                                                        carrier:
                                                                            carrierList[index],
                                                                        service:
                                                                            serviceList[index],
                                                                        packageType:
                                                                            packageTypeList[index],
                                                                        addressVTN:
                                                                            addressVTNList[index],
                                                                        addresseeIRN:
                                                                            addresseeIRNList[index],
                                                                        classX:
                                                                            classXList[index],
                                                                        guarantee:
                                                                            guaranteeList[index],
                                                                        lc: lcList[
                                                                            index],
                                                                        lcLocationNameValue:
                                                                            lcLocationNameValueList[index],
                                                                        lcLocationTypeValue:
                                                                            lcLocationTypeValueList[index],
                                                                        notification:
                                                                            notificationList[index],
                                                                        safePlace:
                                                                            safePlaceList[index],
                                                                        serviceLevelValue:
                                                                            serviceLevelValueList[index],
                                                                        parcelShape:
                                                                            parcelShapeList[index],
                                                                        postalChargesValue:
                                                                            postalChargesValueList[index],
                                                                        satDelivery:
                                                                            satDeliveryList[index],
                                                                        signedConsignment:
                                                                            signedConsignmentList[index],
                                                                        dgMedicine:
                                                                            dgMedicineList[index],
                                                                        dgPerfume:
                                                                            dgPerfumeList[index],
                                                                        dgNail:
                                                                            dgNailList[index],
                                                                        dgToiletry:
                                                                            dgToiletryList[index],
                                                                        customInvoice:
                                                                            customInvoiceList[index],
                                                                        destinationTax:
                                                                            destinationTaxList[index],
                                                                        ecd: ecdList[
                                                                            index],
                                                                        liability:
                                                                            liabilityList[index],
                                                                        preCleared:
                                                                            preClearedList[index],
                                                                        recipientNotification:
                                                                            recipientNotificationList[index],
                                                                        ioss: iossNumberList[
                                                                            index],
                                                                        copiedFrom:
                                                                            ruleNameList[index],
                                                                      ).whenComplete(
                                                                          () {
                                                                        Fluttertoast.showToast(
                                                                            msg:
                                                                                'Rule copied successfully!');
                                                                        fetchShippingRulesList();
                                                                      });
                                                                    },
                                                                    child: Row(
                                                                      children: const [
                                                                        Icon(
                                                                          Icons
                                                                              .copy,
                                                                          color:
                                                                              Colors.black,
                                                                        ),
                                                                        Padding(
                                                                          padding:
                                                                              EdgeInsets.only(left: 10),
                                                                          child:
                                                                              Text('Copy'),
                                                                        ),
                                                                      ],
                                                                    )),
                                                          ),
                                                        ),
                                                      ),
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                    .only(
                                                                right: 30),
                                                        child: SizedBox(
                                                          height: 50,
                                                          width: 80,
                                                          child: FittedBox(
                                                            child:
                                                                ElevatedButton(
                                                              style: ElevatedButton
                                                                  .styleFrom(
                                                                      backgroundColor:
                                                                          Colors
                                                                              .red),
                                                              onPressed:
                                                                  () async {
                                                                await showDialog(
                                                                  context:
                                                                      context,
                                                                  barrierDismissible:
                                                                      false,
                                                                  builder:
                                                                      (context) {
                                                                    return StatefulBuilder(
                                                                      builder:
                                                                          (context,
                                                                              setStateSB) {
                                                                        return AlertDialog(
                                                                          shape:
                                                                              RoundedRectangleBorder(
                                                                            borderRadius:
                                                                                BorderRadius.circular(25),
                                                                          ),
                                                                          elevation:
                                                                              5,
                                                                          titleTextStyle:
                                                                              TextStyle(
                                                                            color:
                                                                                Colors.black,
                                                                            fontSize:
                                                                                size.width * .042,
                                                                            fontWeight:
                                                                                FontWeight.bold,
                                                                          ),
                                                                          title:
                                                                              Text(
                                                                            'Delete Rule',
                                                                            style:
                                                                                TextStyle(fontSize: size.width * .015),
                                                                          ),
                                                                          content:
                                                                              Text(
                                                                            'Do you really want to delete the rule?',
                                                                            style:
                                                                                TextStyle(fontSize: size.width * .01),
                                                                          ),
                                                                          actions: <
                                                                              Widget>[
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
                                                                                      await Future.delayed(const Duration(milliseconds: 500), () {
                                                                                        noController.reset();
                                                                                        Navigator.pop(context);
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
                                                                                        padding: const EdgeInsets.only(right: 13),
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
                                                                                            await deleteRule(objectId: objectIdList[index]).whenComplete(() async {
                                                                                              await Future.delayed(const Duration(seconds: 1), () async {
                                                                                                yesController.reset();
                                                                                                Fluttertoast.showToast(msg: 'Rule deleted successfully!');
                                                                                                Navigator.pop(context);
                                                                                                setState(() {
                                                                                                  isLoading = true;
                                                                                                });
                                                                                                if (index == shippingRulesList.length - 1) {
                                                                                                  /// NOTHING TO WORRY. DELETED RULE WAS THE LAST RULE.
                                                                                                } else {
                                                                                                  for (int i = 1; i <= (shippingRulesList.length - 1 - index); i++) {
                                                                                                    await saveRuleOrderAfterReorder(objectId: objectIdList[index + i], newOrderIndex: index + i);
                                                                                                  }
                                                                                                }
                                                                                              });
                                                                                            }).whenComplete(() => fetchShippingRulesList());
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
                                                                children: const [
                                                                  Icon(
                                                                    Icons
                                                                        .delete_outline,
                                                                    color: Colors
                                                                        .black,
                                                                  ),
                                                                  Padding(
                                                                    padding: EdgeInsets
                                                                        .only(
                                                                            left:
                                                                                10),
                                                                    child: Text(
                                                                        'Delete'),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                )
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                              onReorder: (int oldIndex, int newIndex) async {
                                setState(() {
                                  if (oldIndex < newIndex) {
                                    newIndex -= 1;
                                  }
                                  final ParseObject item =
                                      shippingRulesList.removeAt(oldIndex);
                                  shippingRulesList.insert(newIndex, item);
                                });

                                setState(() {
                                  isLoading = true;
                                });

                                /// SAVING THE RULE ORDER INDEX OF THE MOVED RULE.
                                await saveRuleOrderAfterReorder(
                                  objectId: objectIdList[oldIndex],
                                  newOrderIndex: newIndex + 1,
                                ).whenComplete(() async {
                                  if (oldIndex < newIndex) {
                                    /// RULE SHIFTED TO DOWN SIDE IN ORDER >>>>>>> TO SET ABOVE RULES NOW.
                                    for (int i = 0;
                                        i < (newIndex - oldIndex);
                                        i++) {
                                      await saveRuleOrderAfterReorder(
                                          objectId: objectIdList[newIndex - i],
                                          newOrderIndex: (newIndex - i));
                                    }
                                  } else if (oldIndex > newIndex) {
                                    /// RULE SHIFTED TO UP SIDE IN ORDER >>>>>>>> TO SET BELOW RULES NOW.
                                    for (int i = 0;
                                        i < (oldIndex - newIndex);
                                        i++) {
                                      await saveRuleOrderAfterReorder(
                                          objectId: objectIdList[newIndex + i],
                                          newOrderIndex: (newIndex + 2 + i));
                                    }
                                  }
                                }).whenComplete(() => fetchShippingRulesList());
                              },
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }

  Widget proxyDecorator(
    Widget child,
    int index,
    Animation<double> animation,
  ) {
    return AnimatedBuilder(
      animation: animation,
      builder: (BuildContext context, Widget? child) {
        final double animValue = Curves.easeInOut.transform(animation.value);
        final double elevation = lerpDouble(0, 6, animValue)!;
        return Material(
          elevation: elevation,
          color: draggableItemColor,
          shadowColor: draggableItemColor,
          child: child,
        );
      },
      child: child,
    );
  }

  void fetchShippingRulesList() async {
    isLoading = true;
    await ApiCalls.getShippingRulesList().then((data) {
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
        shippingRulesList = [];

        shippingRulesList.addAll(data.map((e) => e));
        log('shippingRulesList >> ${jsonEncode(shippingRulesList)}');

        shippingRulesList.sort((a, b) => (a.get<int>('rule_order_index') ?? 0)
            .compareTo((b.get<int>('rule_order_index') ?? 0)));

        objectIdList = [];
        ruleOrderList = [];
        ruleNameList = [];
        isActiveList = [];
        conditionItemList = <List<dynamic>>[];
        conditionTypeList = <List<dynamic>>[];
        conditionValueList = <List<dynamic>>[];
        shipFromList = [];
        carrierList = [];
        serviceList = [];
        packageTypeList = [];
        addressVTNList = [];
        addresseeIRNList = [];
        classXList = [];
        guaranteeList = [];
        lcList = [];
        lcLocationNameValueList = [];
        lcLocationTypeValueList = [];
        notificationList = [];
        safePlaceList = [];
        serviceLevelValueList = [];
        parcelShapeList = [];
        postalChargesValueList = [];
        satDeliveryList = [];
        signedConsignmentList = [];
        dgMedicineList = [];
        dgPerfumeList = [];
        dgNailList = [];
        dgToiletryList = [];
        customInvoiceList = [];
        destinationTaxList = [];
        ecdList = [];
        liabilityList = [];
        preClearedList = [];
        recipientNotificationList = [];
        iossNumberList = [];
        copiedFromList = [];

        setState(() {
          objectIdList.addAll(
              shippingRulesList.map((e) => e.get<String>('objectId') ?? ""));
          ruleOrderList.addAll(shippingRulesList
              .map((e) => e.get<int>('rule_order_index') ?? 0));
          ruleNameList.addAll(
              shippingRulesList.map((e) => e.get<String>('rule_name') ?? ""));
          isActiveList.addAll(shippingRulesList
              .map((e) => e.get<String>('is_active_rule') ?? ""));
          conditionItemList.addAll(shippingRulesList
              .map((e) => e.get<List<dynamic>>('conditioned_item') ?? []));
          conditionTypeList.addAll(shippingRulesList
              .map((e) => e.get<List<dynamic>>('condition_type') ?? []));
          conditionValueList.addAll(shippingRulesList
              .map((e) => e.get<List<dynamic>>('condition_value') ?? []));
          shipFromList.addAll(shippingRulesList
              .map((e) => e.get<String>('ship_from_value') ?? ""));
          carrierList.addAll(shippingRulesList
              .map((e) => e.get<String>('carrier_name') ?? ""));
          serviceList.addAll(shippingRulesList
              .map((e) => e.get<String>('service_name') ?? ""));
          packageTypeList.addAll(shippingRulesList
              .map((e) => e.get<String>('package_type_value') ?? ""));
          addressVTNList.addAll(shippingRulesList
              .map((e) => e.get<String>('address_vtn_value') ?? ""));
          addresseeIRNList.addAll(shippingRulesList
              .map((e) => e.get<String>('addressee_irn_value') ?? ""));
          classXList.addAll(
              shippingRulesList.map((e) => e.get<String>('class_value') ?? ""));
          guaranteeList.addAll(shippingRulesList
              .map((e) => e.get<String>('guarantee_value') ?? ""));
          lcList.addAll(shippingRulesList
              .map((e) => e.get<String>('local_collect_value') ?? ""));
          lcLocationNameValueList.addAll(shippingRulesList
              .map((e) => e.get<String>('lc_location_name_value') ?? ""));
          lcLocationTypeValueList.addAll(shippingRulesList
              .map((e) => e.get<String>('lc_location_type_value') ?? ""));
          notificationList.addAll(shippingRulesList
              .map((e) => e.get<String>('notification_value') ?? ""));
          safePlaceList.addAll(shippingRulesList
              .map((e) => e.get<String>('safeplace_value') ?? ""));
          serviceLevelValueList.addAll(shippingRulesList
              .map((e) => e.get<String>('service_level_value') ?? ""));
          parcelShapeList.addAll(shippingRulesList
              .map((e) => e.get<String>('parcel_shape_value') ?? ""));
          postalChargesValueList.addAll(shippingRulesList
              .map((e) => e.get<String>('postal_charges_value') ?? ""));
          satDeliveryList.addAll(shippingRulesList
              .map((e) => e.get<String>('sat_delivery_value') ?? ""));
          signedConsignmentList.addAll(shippingRulesList
              .map((e) => e.get<String>('signed_consignment_value') ?? ""));
          dgMedicineList.addAll(shippingRulesList
              .map((e) => e.get<String>('dg_medicine_value') ?? ""));
          dgPerfumeList.addAll(shippingRulesList
              .map((e) => e.get<String>('dg_medicine_value') ?? ""));
          dgNailList.addAll(shippingRulesList
              .map((e) => e.get<String>('dg_nail_value') ?? ""));
          dgToiletryList.addAll(shippingRulesList
              .map((e) => e.get<String>('dg_toiletry_value') ?? ""));
          customInvoiceList.addAll(shippingRulesList
              .map((e) => e.get<String>('custom_invoice_value') ?? ""));
          destinationTaxList.addAll(shippingRulesList
              .map((e) => e.get<String>('destination_tax_value') ?? ""));
          ecdList.addAll(
              shippingRulesList.map((e) => e.get<String>('ecd_value') ?? ""));
          liabilityList.addAll(shippingRulesList
              .map((e) => e.get<String>('liability_value') ?? ""));
          preClearedList.addAll(shippingRulesList
              .map((e) => e.get<String>('precleared_value') ?? ""));
          recipientNotificationList.addAll(shippingRulesList
              .map((e) => e.get<String>('recipient_notification_value') ?? ""));
          iossNumberList.addAll(
              shippingRulesList.map((e) => e.get<String>('ioss_number') ?? ""));
          copiedFromList.addAll(
              shippingRulesList.map((e) => e.get<String>('copied_from') ?? ""));
        });

        isActive = List.generate(shippingRulesList.length,
            (int index) => isActiveList[index] == 'Yes' ? true : false);

        Future.delayed(const Duration(seconds: 1), () {
          setState(() {
            errorVisible = false;
            isLoading = false;
          });
        });
      }
    });
  }

  Future<void> changeActivenessOfRule({
    required String objectId,
    required String isActive,
  }) async {
    var shippingRulesList = ParseObject('Shipping_Rules_List')
      ..objectId = objectId
      ..set('is_active_rule', isActive);

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

  Future<void> copyRule({
    required int ruleOrderIndex,
    required String ruleName,
    required String isActive,
    required List<dynamic> conditionedItem,
    required List<dynamic> conditionType,
    required List<dynamic> conditionValue,
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
    required String destinationTax,
    required String ecd,
    required String liability,
    required String preCleared,
    required String recipientNotification,
    required String ioss,
    required String copiedFrom,
  }) async {
    var copyRule = ParseObject('Shipping_Rules_List');

    copyRule.set('rule_order_index', ruleOrderIndex);
    copyRule.set('rule_name', ruleName);
    copyRule.set('is_active_rule', isActive);
    copyRule.set('conditioned_item', conditionedItem);
    copyRule.set('condition_type', conditionType);
    copyRule.set('condition_value', conditionValue);
    copyRule.set('ship_from_value', shipFrom);
    copyRule.set('carrier_name', carrier);
    copyRule.set('service_name', service);
    copyRule.set('package_type_value', packageType);
    copyRule.set('address_vtn_value', addressVTN);
    copyRule.set('addressee_irn_value', addresseeIRN);
    copyRule.set('class_value', classX);
    copyRule.set('guarantee_value', guarantee);
    copyRule.set('local_collect_value', lc);
    copyRule.set('lc_location_name_value', lcLocationNameValue);
    copyRule.set('lc_location_type_value', lcLocationTypeValue);
    copyRule.set('notification_value', notification);
    copyRule.set('safeplace_value', safePlace);
    copyRule.set('parcel_shape_value', parcelShape);
    copyRule.set('postal_charges_value', postalChargesValue);
    copyRule.set('service_level_value', serviceLevelValue);
    copyRule.set('sat_delivery_value', satDelivery);
    copyRule.set('signed_consignment_value', signedConsignment);
    copyRule.set('dg_medicine_value', dgMedicine);
    copyRule.set('dg_perfume_value', dgPerfume);
    copyRule.set('dg_nail_value', dgNail);
    copyRule.set('dg_toiletry_value', dgToiletry);
    copyRule.set('custom_invoice_value', customInvoice);
    copyRule.set('destination_tax_value', destinationTax);
    copyRule.set('ecd_value', ecd);
    copyRule.set('liability_value', liability);
    copyRule.set('precleared_value', preCleared);
    copyRule.set('recipient_notification_value', recipientNotification);
    copyRule.set('ioss_number', ioss);
    copyRule.set('copied_from', copiedFrom);

    await copyRule.save();
  }

  Future<void> deleteRule({required String objectId}) async {
    var shippingRulesList = ParseObject('Shipping_Rules_List')
      ..objectId = objectId;

    await shippingRulesList.delete();
  }

  Future<void> adjustAfterDeletionWhenBack({required int index}) async {
    setState(() {
      isLoading = true;
    });
    if (index == shippingRulesList.length - 1) {
      /// NOTHING TO WORRY. DELETED RULE WAS THE LAST RULE.
    } else {
      for (int i = 1; i <= (shippingRulesList.length - 1 - index); i++) {
        await saveRuleOrderAfterReorder(
            objectId: objectIdList[index + i], newOrderIndex: index + i);
      }
    }
  }

  int smallestMissingNumber(List<int> list) {
    int i = 1;
    for (; i <= list.length; i++) {
      if (!list.contains(i)) {
        break;
      }
    }
    return i;
  }
}
