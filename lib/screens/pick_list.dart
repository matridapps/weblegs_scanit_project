import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:absolute_app/core/apis/api_calls.dart';
import 'package:absolute_app/core/utils/constants.dart';
import 'package:absolute_app/core/utils/navigation_methods.dart';
import 'package:absolute_app/core/utils/responsive_check.dart';
import 'package:absolute_app/core/utils/toast_utils.dart';
import 'package:absolute_app/core/utils/widgets.dart';
import 'package:absolute_app/models/get_all_picklist_response.dart';
import 'package:absolute_app/models/get_locked_picklist_response.dart';
import 'package:absolute_app/models/get_picklist_details_response.dart';
import 'package:absolute_app/screens/picklist_details.dart';
import 'package:absolute_app/screens/web_screens/picklist_allocating_screen_web.dart';
import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:parse_server_sdk/parse_server_sdk.dart';
import 'package:rounded_loading_button/rounded_loading_button.dart';

class PickLists extends StatefulWidget {
  const PickLists({
    Key? key,
    required this.accType,
    required this.authorization,
    required this.refreshToken,
    required this.profileId,
    required this.distCenterName,
    required this.distCenterId,
    required this.userName,
  }) : super(key: key);

  final String accType;
  final String authorization;
  final String refreshToken;
  final int profileId;
  final String distCenterName;
  final int distCenterId;
  final String userName;

  @override
  State<PickLists> createState() => _PickListsState();
}

class _PickListsState extends State<PickLists> {
  List<Batch> pickLists = <Batch>[];
  List<Batch> paginatedPickList = <Batch>[];
  List<String> pickListTypes = ['SIW', 'SSMQW', 'MSMQW'];
  List<int> noToShow = [5];
  List<ParseObject> picklistsDataDB = [];
  List<String> statusTypes = [
    'All Picklists',
    'Not Started',
    'In Progress',
    'Complete'
  ];
  List<ParseObject> savedLockedPicklistData = [];
  List<MessageXX> lockedPicklistList = [];
  List<String> locationsList = [];
  List<SkuXX> details = [];

  int selectedNoToShow = 5;
  int startIndex = 0;
  int endIndex = 4;
  int pickListCount = 0;
  int picklistLengthDB = 0;
  int pendingPickListNo = 0;
  int pickListLengthToSave = 0;

  Color previousColor = Colors.grey;
  Color nextColor = Colors.blue;

  bool isCreatingPicklist = false;
  bool isPicklistSuccessful = true;
  bool errorVisible = false;
  bool shiftLoading = false;
  bool isPicklistVisible = false;

  String pickDB = '';
  String isErrorShown = 'No';
  String pendingPicklistRequestType = '';
  String lastCreatedPicklistToSave = '';
  String selectedStatusToFilter = 'All Picklists';
  String selectedPicklist = 'SIW';

  DateTime savedTime = DateTime.now();
  DateFormat dateFormat = DateFormat("M/d/yyyy h:mm:ss a");

  final RoundedLoadingButtonController createController =
      RoundedLoadingButtonController();
  final RoundedLoadingButtonController cancelController =
      RoundedLoadingButtonController();
  final TextEditingController selectedStatusToFilterController =
      TextEditingController();
  final TextEditingController selectedPicklistController =
      TextEditingController();
  final TextEditingController selectedNoToShowController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    setState(() {
      selectedStatusToFilterController.text = 'All Picklists';
      selectedPicklistController.text = 'SIW';
      selectedNoToShowController.text = '5';
    });
    pickListApis();
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
        title: Text(
          'Pick Lists',
          style: TextStyle(
            fontSize: (size.width <= 1000) ? 25 : 30,
            color: Colors.black,
          ),
        ),
        actions: [
          Visibility(
            visible: kIsWeb == true,
            child: Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 10),
              child: SizedBox(
                height: AppBar().preferredSize.height,
                width: 180,
                child: CustomDropdown(
                  items: statusTypes,
                  controller: selectedStatusToFilterController,
                  hintText: '',
                  selectedStyle: const TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                  ),
                  listItemStyle: const TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                  ),
                  excludeSelected: true,
                  onChanged: (_) async {
                    setState(() {
                      selectedStatusToFilter =
                          selectedStatusToFilterController.text;
                    });
                    log('V selectedStatusToFilterController.text >>---> ${selectedStatusToFilterController.text}');
                    log('V selectedStatusToFilter >>---> $selectedStatusToFilter');
                    await Future.delayed(const Duration(milliseconds: 100), () {
                      setState(() {
                        selectedNoToShow = 5;
                        selectedNoToShowController.text = '5';
                        startIndex = 0;
                        endIndex = 4;
                        previousColor = Colors.grey;
                        nextColor = Colors.blue;
                      });
                      pickListApis();
                    });
                  },
                ),
              ),
            ),
          ),
          const Visibility(
            visible: kIsWeb == true,
            child: SizedBox(width: 20.0),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 10.0),
            child: IconButton(
              onPressed: () {
                pickListApis();
              },
              icon: const Icon(
                Icons.refresh_rounded,
                size: kIsWeb ? 25 : 30,
              ),
            ),
          )
        ],
      ),
      body: kIsWeb == true
          ? webBuilder(context, size)
          : mobileBuilder(context, size),
    );
  }

  Widget webBuilder(BuildContext context, Size size) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: size.width * .035,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Visibility(
            visible: isPicklistVisible == true,
            child: SizedBox(
              height: size.height * .075,
              width: size.width,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      if (ResponsiveCheck.screenBiggerThan24inch(context)) {
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
                                  titleTextStyle: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  title: const Text(
                                    'Select a Picklist Type',
                                    style: TextStyle(fontSize: 25),
                                  ),
                                  content: SizedBox(
                                    height: 40,
                                    width: 400,
                                    child: CustomDropdown(
                                      items: pickListTypes,
                                      controller: selectedPicklistController,
                                      hintText: '',
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
                                          selectedPicklist =
                                              selectedPicklistController.text;
                                        });
                                        log('V selectedPicklistController.text >>---> ${selectedPicklistController.text}');
                                        log('V selectedPicklist >>---> $selectedPicklist');
                                      },
                                    ),
                                  ),
                                  actions: <Widget>[
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(left: 13),
                                          child: RoundedLoadingButton(
                                            color: Colors.red,
                                            borderRadius: 10,
                                            height: 50,
                                            width: 120,
                                            successIcon: Icons.check_rounded,
                                            failedIcon: Icons.close_rounded,
                                            successColor: Colors.green,
                                            controller: cancelController,
                                            onPressed: () async {
                                              await Future.delayed(
                                                  const Duration(
                                                      milliseconds: 500), () {
                                                cancelController.reset();
                                                Navigator.pop(context);
                                              });
                                            },
                                            child: const Text('Cancel'),
                                          ),
                                        ),
                                        Expanded(
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            children: [
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    right: 13),
                                                child: RoundedLoadingButton(
                                                  color: Colors.green,
                                                  borderRadius: 10,
                                                  height: 50,
                                                  width: 120,
                                                  successIcon:
                                                      Icons.check_rounded,
                                                  failedIcon:
                                                      Icons.close_rounded,
                                                  successColor: Colors.green,
                                                  controller: createController,
                                                  onPressed: () async {
                                                    createNewPicklistMethod(
                                                      context,
                                                    );
                                                  },
                                                  child: const Text(
                                                    'Create',
                                                  ),
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
                      } else {
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
                                    'Select a Picklist Type',
                                    style:
                                        TextStyle(fontSize: size.width * .015),
                                  ),
                                  content: SizedBox(
                                    height: size.height * .05,
                                    width: size.width * .2,
                                    child: CustomDropdown(
                                      items: pickListTypes,
                                      controller: selectedPicklistController,
                                      hintText: '',
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
                                          selectedPicklist =
                                              selectedPicklistController.text;
                                        });
                                        log('V selectedPicklistController.text >>---> ${selectedPicklistController.text}');
                                        log('V selectedPicklistT >>---> $selectedPicklist');
                                      },
                                    ),
                                  ),
                                  actions: <Widget>[
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(left: 13),
                                          child: RoundedLoadingButton(
                                            color: Colors.red,
                                            borderRadius: 10,
                                            height: size.width * .03,
                                            width: size.width * .07,
                                            successIcon: Icons.check_rounded,
                                            failedIcon: Icons.close_rounded,
                                            successColor: Colors.green,
                                            controller: cancelController,
                                            onPressed: () async {
                                              await Future.delayed(
                                                  const Duration(
                                                      milliseconds: 500), () {
                                                cancelController.reset();
                                                Navigator.pop(context);
                                              });
                                            },
                                            child: const Text('Cancel'),
                                          ),
                                        ),
                                        Expanded(
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            children: [
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    right: 13),
                                                child: RoundedLoadingButton(
                                                  color: Colors.green,
                                                  borderRadius: 10,
                                                  height: size.width * .03,
                                                  width: size.width * .07,
                                                  successIcon:
                                                      Icons.check_rounded,
                                                  failedIcon:
                                                      Icons.close_rounded,
                                                  successColor: Colors.green,
                                                  controller: createController,
                                                  onPressed: () async {
                                                    createNewPicklistMethod(
                                                      context,
                                                    );
                                                  },
                                                  child: const Text(
                                                    'Create',
                                                  ),
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
                      }
                    },
                    child: const Text(
                      'Create New PickList',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Visibility(
            visible: isPicklistVisible == true,
            child: Visibility(
              visible: pickLists.length > 10,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () async {
                      setState(() {
                        shiftLoading = (startIndex == 0) ? false : true;
                      });
                      await Future.delayed(const Duration(milliseconds: 300),
                          () {
                        if (startIndex >= selectedNoToShow) {
                          if (endIndex < pickLists.length - 1) {
                            setState(() {
                              startIndex -= selectedNoToShow;
                              endIndex -= selectedNoToShow;
                            });
                            paginatedPickList = [];
                            paginatedPickList.addAll(pickLists.where((e) =>
                                pickLists.indexOf(e) <= endIndex &&
                                pickLists.indexOf(e) >= startIndex));
                          } else {
                            setState(() {
                              startIndex -= selectedNoToShow;
                            });
                            if (pickLists.length % selectedNoToShow == 0) {
                              setState(() {
                                endIndex -= selectedNoToShow;
                              });
                            } else {
                              setState(() {
                                endIndex -=
                                    (pickLists.length % selectedNoToShow);
                              });
                            }
                            paginatedPickList = [];
                            paginatedPickList.addAll(pickLists.where((e) =>
                                pickLists.indexOf(e) <= endIndex &&
                                pickLists.indexOf(e) >= startIndex));
                          }
                        }
                        if (startIndex == 0) {
                          setState(() {
                            previousColor = Colors.grey;
                          });
                        }
                        if (endIndex < pickLists.length - 1) {
                          setState(() {
                            nextColor = Colors.blue;
                          });
                        }
                        setState(() {
                          shiftLoading = false;
                        });

                        log("prev tap startIndex >> $startIndex");
                        log("prev tap endIndex >> $endIndex");
                      });
                    },
                    child: Text(
                      'Previous',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: previousColor,
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'Showing ',
                        style: TextStyle(
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(
                        height: 30,
                        width: 90,
                        child: CustomDropdown(
                          items: noToShow.map((e) => '$e').toList(),
                          controller: selectedNoToShowController,
                          hintText: '',
                          selectedStyle: const TextStyle(
                            color: Colors.black,
                            fontSize: 14,
                          ),
                          listItemStyle: const TextStyle(
                            color: Colors.black,
                            fontSize: 14,
                          ),
                          excludeSelected: true,
                          onChanged: (_) async {
                            setState(() {
                              shiftLoading = true;
                              selectedNoToShow =
                                  parseToInt(selectedNoToShowController.text);
                            });
                            log('V selectedNoToShowController.text >>---> ${selectedNoToShowController.text}');
                            log('V selectedNoToShow >>---> $selectedNoToShow');
                            await Future.delayed(
                                const Duration(milliseconds: 100), () {
                              setState(() {
                                startIndex = 0;
                                endIndex = selectedNoToShow - 1;
                                previousColor = Colors.grey;
                                nextColor = Colors.blue;
                              });
                              paginatedPickList = [];
                              paginatedPickList.addAll(pickLists.where((e) =>
                                  pickLists.indexOf(e) <= endIndex &&
                                  pickLists.indexOf(e) >= startIndex));
                              setState(() {
                                shiftLoading = false;
                              });
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () async {
                      setState(() {
                        shiftLoading =
                            (endIndex == pickLists.length - 1) ? false : true;
                      });
                      await Future.delayed(const Duration(milliseconds: 300),
                          () {
                        setState(() {
                          previousColor = Colors.blue;
                        });
                        if (pickLists.length - endIndex >
                            selectedNoToShow + 1) {
                          setState(() {
                            startIndex += selectedNoToShow;
                            endIndex += selectedNoToShow;
                          });
                          paginatedPickList = [];
                          paginatedPickList.addAll(pickLists.where((e) =>
                              pickLists.indexOf(e) <= endIndex &&
                              pickLists.indexOf(e) >= startIndex));
                        } else {
                          if (pickLists.length - startIndex >
                              selectedNoToShow) {
                            setState(() {
                              endIndex = pickLists.length - 1;
                              startIndex += selectedNoToShow;
                              nextColor = Colors.grey;
                            });
                            paginatedPickList = [];
                            paginatedPickList.addAll(pickLists.where((e) =>
                                pickLists.indexOf(e) <= endIndex &&
                                pickLists.indexOf(e) >= startIndex));
                          }
                        }
                        setState(() {
                          shiftLoading = false;
                        });

                        log("next tap startIndex >> $startIndex");
                        log("next tap endIndex >> $endIndex");
                      });
                    },
                    child: Text(
                      'Next',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: nextColor,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Visibility(
            visible: isPicklistVisible == true,
            child: Row(
              children: [
                Container(
                  width: size.width * .7,
                  height: 50,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.grey,
                      width: 1,
                    ),
                    color: Colors.grey.shade300,
                  ),
                  child: const Center(
                    child: Text(
                      'Picklist Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Container(
                  width: size.width * .1,
                  height: 50,
                  decoration: BoxDecoration(
                    border: const Border(
                      right: BorderSide(
                        color: Colors.grey,
                        width: 1,
                      ),
                      top: BorderSide(
                        color: Colors.grey,
                        width: 1,
                      ),
                      bottom: BorderSide(
                        color: Colors.grey,
                        width: 1,
                      ),
                    ),
                    color: Colors.grey.shade300,
                  ),
                  child: const Center(
                    child: Text(
                      'Type',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Container(
                  width: size.width * .13,
                  height: 50,
                  decoration: BoxDecoration(
                    border: const Border(
                      right: BorderSide(
                        color: Colors.grey,
                        width: 1,
                      ),
                      top: BorderSide(
                        color: Colors.grey,
                        width: 1,
                      ),
                      bottom: BorderSide(
                        color: Colors.grey,
                        width: 1,
                      ),
                    ),
                    color: Colors.grey.shade300,
                  ),
                  child: const Center(
                    child: Text(
                      'Validate Picklist',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
          SizedBox(
            height:
                pickLists.length > 10 ? size.height * .73 : size.height * .78,
            width: size.width,
            child: isPicklistVisible == false
                ? const Center(
                    child: CircularProgressIndicator(
                      color: appColor,
                    ),
                  )
                : pickLists.isEmpty
                    ? const Center(
                        child: Text(
                          'No PickList to show',
                          style: TextStyle(
                            fontSize: 20,
                          ),
                        ),
                      )
                    : shiftLoading == true
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: appColor,
                            ),
                          )
                        : ListView.builder(
                            itemCount: picklistChooser().length,
                            itemBuilder: (BuildContext ctx, index) {
                              return Container(
                                alignment: Alignment.center,
                                foregroundDecoration: lockedPicklistList
                                        .isNotEmpty
                                    ? lockedPicklistList
                                            .map((e) => e.batchId)
                                            .toList()
                                            .contains(picklistChooser()[index]
                                                .batchId)
                                        ? lockedPicklistList[lockedPicklistList
                                                        .indexWhere((e) =>
                                                            e.batchId ==
                                                            picklistChooser()[
                                                                    index]
                                                                .batchId)]
                                                    .userName ==
                                                widget.userName
                                            ? null
                                            : const BoxDecoration(
                                                color: Colors.grey,
                                                backgroundBlendMode:
                                                    BlendMode.saturation,
                                              )
                                        : null
                                    : null,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: size.width * .7,
                                      height: heightCheckerForWeb(index: index),
                                      decoration: BoxDecoration(
                                        border: const Border(
                                          right: BorderSide(
                                            color: Colors.grey,
                                            width: 1,
                                          ),
                                          left: BorderSide(
                                            color: Colors.grey,
                                            width: 1,
                                          ),
                                          bottom: BorderSide(
                                            color: Colors.grey,
                                            width: 1,
                                          ),
                                        ),
                                        color: Colors.grey.shade200,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          SizedBox(
                                            height: heightCheckerForWeb(
                                                index: index),
                                            width: lockedPicklistList.isNotEmpty
                                                ? lockedPicklistList
                                                        .map((e) => e.batchId)
                                                        .toList()
                                                        .contains(
                                                            picklistChooser()[
                                                                    index]
                                                                .batchId)
                                                    ? lockedPicklistList[lockedPicklistList.indexWhere((e) =>
                                                                    e.batchId ==
                                                                    picklistChooser()[
                                                                            index]
                                                                        .batchId)]
                                                                .userName ==
                                                            widget.userName
                                                        ? size.width * .69
                                                        : size.width * .59
                                                    : size.width * .69
                                                : size.width * .69,
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                MouseRegion(
                                                  cursor: mouseCursorForWeb(
                                                    index: index,
                                                  ),
                                                  child: GestureDetector(
                                                    onTap: () {
                                                      moveToPicklistDetailsOrAllocationScreenWeb(
                                                        index: index,
                                                        showPickedOrders: false,
                                                      );
                                                    },
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              top: 5, left: 10),
                                                      child: Text(
                                                        picklistChooser()[index]
                                                            .picklist,
                                                        style: const TextStyle(
                                                          fontSize: 18,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color:
                                                              Colors.lightBlue,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          top: 5, left: 10),
                                                  child: Row(
                                                    children: [
                                                      const Text(
                                                        'Created on : ',
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      Text(
                                                        picklistChooser()[index]
                                                            .createdOn,
                                                        style: const TextStyle(
                                                          fontSize: 16,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          top: 5, left: 10),
                                                  child: Row(
                                                    children: [
                                                      const Text(
                                                        'Status : ',
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      Text(
                                                        picklistChooser()[index]
                                                            .status,
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color:
                                                              colorChooserForStatus(
                                                                  index: index),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Visibility(
                                                  visible: picklistChooser()[
                                                              index]
                                                          .status
                                                          .contains(
                                                              'In Progress') ||
                                                      picklistChooser()[index]
                                                          .status
                                                          .contains(
                                                              'Not Started'),
                                                  child: GestureDetector(
                                                    onTap: () {
                                                      moveToPicklistDetailsOrAllocationScreenWeb(
                                                        index: index,
                                                        showPickedOrders: false,
                                                      );
                                                    },
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              top: 5, left: 10),
                                                      child: Row(
                                                        children: [
                                                          Visibility(
                                                            visible:
                                                                leftOrderOrSkuVisible(
                                                                    index),
                                                            child: MouseRegion(
                                                              cursor:
                                                                  mouseCursorForWeb(
                                                                index: index,
                                                              ),
                                                              child: Text(
                                                                picklistChooser()[index]
                                                                            .requestType ==
                                                                        'MSMQW'
                                                                    ? '${parseToInt(picklistChooser()[index].totalorder) - parseToInt(picklistChooser()[index].pickedorder)} ${(parseToInt(picklistChooser()[index].totalorder) - parseToInt(picklistChooser()[index].pickedorder) > 1 ? 'Orders' : 'Order')} '
                                                                    : '${parseToInt(picklistChooser()[index].totalsku) - parseToInt(picklistChooser()[index].pickedsku)} ${(parseToInt(picklistChooser()[index].totalsku) - parseToInt(picklistChooser()[index].pickedsku) > 1 ? 'SKUs' : 'SKU')} ',
                                                                style:
                                                                    const TextStyle(
                                                                  fontSize: 16,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                          Visibility(
                                                            visible:
                                                                leftOrderOrSkuVisible(
                                                                    index),
                                                            child: MouseRegion(
                                                              cursor:
                                                                  mouseCursorForWeb(
                                                                index: index,
                                                              ),
                                                              child: const Text(
                                                                'Left to be Picked',
                                                                style:
                                                                    TextStyle(
                                                                  fontSize: 16,
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                          Visibility(
                                                            visible: leftOrderOrSkuVisible(
                                                                    index) &&
                                                                leftPartialOrderOrSkuVisible(
                                                                    index),
                                                            child: MouseRegion(
                                                              cursor:
                                                                  mouseCursorForWeb(
                                                                index: index,
                                                              ),
                                                              child: const Text(
                                                                ' & ',
                                                                style:
                                                                    TextStyle(
                                                                  fontSize: 16,
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                          Visibility(
                                                            visible:
                                                                leftPartialOrderOrSkuVisible(
                                                                    index),
                                                            child: MouseRegion(
                                                              cursor:
                                                                  mouseCursorForWeb(
                                                                index: index,
                                                              ),
                                                              child: Text(
                                                                picklistChooser()[index]
                                                                            .requestType ==
                                                                        'MSMQW'
                                                                    ? '${picklistChooser()[index].partialOrders} ${parseToInt(picklistChooser()[index].partialOrders) > 1 ? 'Orders' : 'Order'} '
                                                                    : '${picklistChooser()[index].partialSkus} ${parseToInt(picklistChooser()[index].partialSkus) > 1 ? 'SKUs' : 'SKU'} ',
                                                                style:
                                                                    const TextStyle(
                                                                  fontSize: 16,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                          Visibility(
                                                            visible:
                                                                leftPartialOrderOrSkuVisible(
                                                                    index),
                                                            child: MouseRegion(
                                                              cursor:
                                                                  mouseCursorForWeb(
                                                                index: index,
                                                              ),
                                                              child: const Text(
                                                                'Partially Left to be Picked',
                                                                style:
                                                                    TextStyle(
                                                                  fontSize: 16,
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                          Visibility(
                                                            visible: leftOrderOrSkuVisible(
                                                                    index) ||
                                                                leftPartialOrderOrSkuVisible(
                                                                    index),
                                                            child: const Icon(
                                                              Icons
                                                                  .navigate_next,
                                                              size: 20,
                                                            ),
                                                          )
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                Visibility(
                                                  visible: (picklistChooser()[
                                                                          index]
                                                                      .requestType ==
                                                                  'MSMQW'
                                                              ? picklistChooser()[
                                                                      index]
                                                                  .pickedorder
                                                              : picklistChooser()[
                                                                      index]
                                                                  .pickedsku) !=
                                                          '0' &&
                                                      (picklistChooser()[index]
                                                                      .requestType ==
                                                                  'MSMQW'
                                                              ? picklistChooser()[
                                                                      index]
                                                                  .pickedorder
                                                              : picklistChooser()[
                                                                      index]
                                                                  .pickedsku) !=
                                                          '',
                                                  child: Visibility(
                                                    visible: picklistChooser()[
                                                                index]
                                                            .status
                                                            .contains(
                                                                'Complete') ||
                                                        picklistChooser()[index]
                                                            .status
                                                            .contains(
                                                                'In Progress') ||
                                                        picklistChooser()[index]
                                                            .status
                                                            .contains(
                                                                'Not Started'),
                                                    child: GestureDetector(
                                                      onTap: () async {
                                                        moveToPicklistDetailsOrAllocationScreenWeb(
                                                          index: index,
                                                          showPickedOrders:
                                                              true,
                                                        );
                                                      },
                                                      child: Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                    .only(
                                                                top: 5,
                                                                left: 10),
                                                        child: Row(
                                                          children: [
                                                            Visibility(
                                                              visible:
                                                                  validatedOrderOrSkuVisible(
                                                                      index),
                                                              child:
                                                                  MouseRegion(
                                                                cursor:
                                                                    mouseCursorForWeb(
                                                                  index: index,
                                                                ),
                                                                child: Text(
                                                                  picklistChooser()[index]
                                                                              .requestType ==
                                                                          'MSMQW'
                                                                      ? '${parseToInt(picklistChooser()[index].pickedorder) - parseToInt(picklistChooser()[index].partialOrders)} ${parseToInt(picklistChooser()[index].pickedorder) - parseToInt(picklistChooser()[index].partialOrders) > 1 ? 'Orders' : 'Order'} '
                                                                      : '${parseToInt(picklistChooser()[index].pickedsku) - parseToInt(picklistChooser()[index].partialSkus)} ${parseToInt(picklistChooser()[index].pickedsku) - parseToInt(picklistChooser()[index].partialSkus) > 1 ? 'SKUs' : 'SKU'} ',
                                                                  style:
                                                                      const TextStyle(
                                                                    fontSize:
                                                                        16,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                            Visibility(
                                                              visible:
                                                                  validatedOrderOrSkuVisible(
                                                                      index),
                                                              child:
                                                                  MouseRegion(
                                                                cursor:
                                                                    mouseCursorForWeb(
                                                                  index: index,
                                                                ),
                                                                child:
                                                                    const Text(
                                                                  'Picked',
                                                                  style:
                                                                      TextStyle(
                                                                    fontSize:
                                                                        16,
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                            Visibility(
                                                              visible: validatedOrderOrSkuVisible(
                                                                      index) &&
                                                                  validatedPartialOrderOrSkuVisible(
                                                                      index),
                                                              child:
                                                                  MouseRegion(
                                                                cursor:
                                                                    mouseCursorForWeb(
                                                                  index: index,
                                                                ),
                                                                child:
                                                                    const Text(
                                                                  ' & ',
                                                                  style:
                                                                      TextStyle(
                                                                    fontSize:
                                                                        16,
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                            Visibility(
                                                              visible:
                                                                  validatedPartialOrderOrSkuVisible(
                                                                      index),
                                                              child:
                                                                  MouseRegion(
                                                                cursor:
                                                                    mouseCursorForWeb(
                                                                  index: index,
                                                                ),
                                                                child: Text(
                                                                  picklistChooser()[index]
                                                                              .requestType ==
                                                                          'MSMQW'
                                                                      ? '${picklistChooser()[index].partialOrders} ${parseToInt(picklistChooser()[index].partialOrders) > 1 ? 'Orders' : 'Order'} '
                                                                      : '${picklistChooser()[index].partialSkus} ${parseToInt(picklistChooser()[index].partialSkus) > 1 ? 'SKUs' : 'SKU'} ',
                                                                  style:
                                                                      const TextStyle(
                                                                    fontSize:
                                                                        16,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                            Visibility(
                                                              visible:
                                                                  validatedPartialOrderOrSkuVisible(
                                                                      index),
                                                              child:
                                                                  MouseRegion(
                                                                cursor:
                                                                    mouseCursorForWeb(
                                                                  index: index,
                                                                ),
                                                                child:
                                                                    const Text(
                                                                  'Partially Picked',
                                                                  style:
                                                                      TextStyle(
                                                                    fontSize:
                                                                        16,
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                            const Icon(
                                                              Icons
                                                                  .navigate_next,
                                                              size: 20,
                                                            )
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Visibility(
                                            visible: lockedPicklistList
                                                    .isNotEmpty
                                                ? lockedPicklistList
                                                        .map((e) => e.batchId)
                                                        .toList()
                                                        .contains(
                                                            picklistChooser()[
                                                                    index]
                                                                .batchId)
                                                    ? lockedPicklistList[lockedPicklistList.indexWhere((e) =>
                                                                    e.batchId ==
                                                                    picklistChooser()[
                                                                            index]
                                                                        .batchId)]
                                                                .userName ==
                                                            widget.userName
                                                        ? false
                                                        : true
                                                    : false
                                                : false,
                                            child: SizedBox(
                                              height: heightCheckerForWeb(
                                                  index: index),
                                              width: size.width * .1,
                                              child: Center(
                                                child: IconButton(
                                                  onPressed: () {},
                                                  icon: const Icon(Icons.lock),
                                                  iconSize: 30,
                                                  tooltip:
                                                      '${picklistChooser()[index].picklist} Locked as another user is working on this picklist.',
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      width: size.width * .1,
                                      height: heightCheckerForWeb(index: index),
                                      decoration: BoxDecoration(
                                        border: const Border(
                                          right: BorderSide(
                                            color: Colors.grey,
                                            width: 1,
                                          ),
                                          bottom: BorderSide(
                                            color: Colors.grey,
                                            width: 1,
                                          ),
                                        ),
                                        color: Colors.grey.shade200,
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Text(
                                            picklistChooser()[index]
                                                .requestType,
                                            style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                                    Container(
                                      width: size.width * .13,
                                      height: heightCheckerForWeb(index: index),
                                      decoration: BoxDecoration(
                                        border: const Border(
                                          right: BorderSide(
                                            color: Colors.grey,
                                            width: 1,
                                          ),
                                          bottom: BorderSide(
                                            color: Colors.grey,
                                            width: 1,
                                          ),
                                        ),
                                        color: Colors.grey.shade200,
                                      ),
                                      child: Visibility(
                                        visible: picklistChooser()[index]
                                            .status
                                            .isNotEmpty,
                                        child: Center(
                                          child: picklistChooser()[index]
                                                          .status ==
                                                      'Complete' ||
                                                  picklistChooser()[index]
                                                          .status ==
                                                      'Processing.......' ||
                                                  picklistChooser()[index]
                                                      .status
                                                      .contains(
                                                          'No Ean to be picked')
                                              ? Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      picklistChooser()[index]
                                                                  .status ==
                                                              'Complete'
                                                          ? 'Validated'
                                                          : picklistChooser()[
                                                                          index]
                                                                      .status ==
                                                                  'Processing.......'
                                                              ? 'Processing.......'
                                                              : 'No Ean to be Picked',
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                )
                                              : SizedBox(
                                                  height: 50,
                                                  width: size.width * .12,
                                                  child: ElevatedButton(
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      backgroundColor:
                                                          Colors.green,
                                                    ),
                                                    onPressed: () async {
                                                      lockedPicklistList
                                                              .isNotEmpty
                                                          ? lockedPicklistList
                                                                  .map((e) =>
                                                                      e.batchId)
                                                                  .toList()
                                                                  .contains(picklistChooser()[
                                                                          index]
                                                                      .batchId)
                                                              ? lockedPicklistList[lockedPicklistList.indexWhere((e) =>
                                                                              e.batchId ==
                                                                              picklistChooser()[index]
                                                                                  .batchId)]
                                                                          .userName ==
                                                                      widget
                                                                          .userName
                                                                  ? validateAllPicklist(
                                                                      index)
                                                                  : ToastUtils.motionToastCentered1500MS(message: '${picklistChooser()[index].picklist} Locked as another user is working on this picklist.', context: context,)
                                                              : validateAllPicklist(
                                                                  index)
                                                          : validateAllPicklist(
                                                              index);
                                                    },
                                                    child: Center(
                                                      child: Text(
                                                        'Validate ${picklistChooser()[index].picklist}',
                                                        style: const TextStyle(
                                                          fontSize: 14,
                                                          color: Colors.white,
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
                            }),
          ),
        ],
      ),
    );
  }

  Widget mobileBuilder(BuildContext context, Size size) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: size.height * .005,
        horizontal: size.width * .025,
      ),
      child: Column(
        children: [
          Visibility(
            visible: isPicklistVisible == true,
            child: SizedBox(
              height: size.height * .08,
              width: size.width,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () async {
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
                                  'Select a Picklist Type',
                                  style: TextStyle(fontSize: size.width * .05),
                                ),
                                content: SizedBox(
                                    height: size.height * .07,
                                    width: size.width * .7,
                                    child: CustomDropdown(
                                      items: pickListTypes,
                                      controller: selectedPicklistController,
                                      hintText: '',
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
                                          selectedPicklist =
                                              selectedPicklistController.text;
                                        });
                                        log('V selectedPicklistController.text >>---> ${selectedPicklistController.text}');
                                        log('V selectedPicklistT >>---> $selectedPicklist');
                                      },
                                    )),
                                actions: <Widget>[
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(left: 10),
                                        child: RoundedLoadingButton(
                                          color: Colors.red,
                                          borderRadius: 10,
                                          height: size.width * .1,
                                          width: size.width * .25,
                                          successIcon: Icons.check_rounded,
                                          failedIcon: Icons.close_rounded,
                                          successColor: Colors.green,
                                          controller: cancelController,
                                          onPressed: () async {
                                            cancelController.error();
                                            await Future.delayed(
                                                const Duration(
                                                    milliseconds: 500), () {
                                              cancelController.reset();
                                              Navigator.pop(context);
                                            });
                                          },
                                          child: const Text('Cancel'),
                                        ),
                                      ),
                                      Expanded(
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  right: 10),
                                              child: RoundedLoadingButton(
                                                color: Colors.green,
                                                borderRadius: 10,
                                                height: size.width * .1,
                                                width: size.width * .25,
                                                successIcon:
                                                    Icons.check_rounded,
                                                failedIcon: Icons.close_rounded,
                                                successColor: Colors.green,
                                                controller: createController,
                                                onPressed: () async {
                                                  createNewPicklistMethod(
                                                    context,
                                                  );
                                                },
                                                child: const Text('Create'),
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
                    child: Text(
                      'Create New PickList',
                      style: TextStyle(
                        fontSize: size.height * .025,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Visibility(
            visible: isPicklistVisible == true && kIsWeb != true,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: size.width * .25,
                    child: const Text(
                      'Showing',
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),
                  ),
                  SizedBox(
                      height: 40,
                      width: size.width * .7,
                      child: CustomDropdown(
                        items: statusTypes,
                        controller: selectedStatusToFilterController,
                        hintText: '',
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
                        onChanged: (_) async {
                          setState(() {
                            selectedStatusToFilter =
                                selectedStatusToFilterController.text;
                          });
                          log('V selectedStatusToFilterController.text >>---> ${selectedStatusToFilterController.text}');
                          log('V selectedStatusToFilter >>---> $selectedStatusToFilter');
                          await Future.delayed(
                              const Duration(milliseconds: 100), () {
                            setState(() {
                              selectedNoToShow = 5;
                              selectedNoToShowController.text = '5';
                              startIndex = 0;
                              endIndex = 4;
                              previousColor = Colors.grey;
                              nextColor = Colors.blue;
                            });
                            pickListApis();
                          });
                        },
                      )),
                ],
              ),
            ),
          ),
          Visibility(
            visible: isPicklistVisible == true,
            child: Visibility(
              visible: pickLists.length > 10,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () async {
                      setState(() {
                        shiftLoading = (startIndex == 0) ? false : true;
                      });
                      await Future.delayed(const Duration(milliseconds: 300),
                          () {
                        if (startIndex >= selectedNoToShow) {
                          if (endIndex < pickLists.length - 1) {
                            setState(() {
                              startIndex -= selectedNoToShow;
                              endIndex -= selectedNoToShow;
                            });
                            paginatedPickList = [];
                            paginatedPickList.addAll(pickLists.where((e) =>
                                pickLists.indexOf(e) <= endIndex &&
                                pickLists.indexOf(e) >= startIndex));
                          } else {
                            setState(() {
                              startIndex -= selectedNoToShow;
                            });
                            if (pickLists.length % selectedNoToShow == 0) {
                              setState(() {
                                endIndex -= selectedNoToShow;
                              });
                            } else {
                              setState(() {
                                endIndex -=
                                    (pickLists.length % selectedNoToShow);
                              });
                            }
                            paginatedPickList = [];
                            paginatedPickList.addAll(pickLists.where((e) =>
                                pickLists.indexOf(e) <= endIndex &&
                                pickLists.indexOf(e) >= startIndex));
                          }
                        }
                        if (startIndex == 0) {
                          setState(() {
                            previousColor = Colors.grey;
                          });
                        }
                        if (endIndex < pickLists.length - 1) {
                          setState(() {
                            nextColor = Colors.blue;
                          });
                        }
                        setState(() {
                          shiftLoading = false;
                        });

                        log("prev tap startIndex >> $startIndex");
                        log("prev tap endIndex >> $endIndex");
                      });
                    },
                    child: Text(
                      'Previous',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: previousColor,
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'Showing ',
                        style: TextStyle(
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(
                        height: 25,
                        width: 90,
                        child: CustomDropdown(
                          items: noToShow.map((e) => '$e').toList(),
                          controller: selectedNoToShowController,
                          hintText: '',
                          selectedStyle: const TextStyle(
                            color: Colors.black,
                            fontSize: 14,
                          ),
                          listItemStyle: const TextStyle(
                            color: Colors.black,
                            fontSize: 14,
                          ),
                          excludeSelected: true,
                          onChanged: (_) async {
                            setState(() {
                              shiftLoading = true;
                              selectedNoToShow =
                                  parseToInt(selectedNoToShowController.text);
                            });
                            log('V selectedNoToShowController.text >>---> ${selectedNoToShowController.text}');
                            log('V selectedNoToShow >>---> $selectedNoToShow');
                            await Future.delayed(
                                const Duration(milliseconds: 100), () {
                              setState(() {
                                startIndex = 0;
                                endIndex = selectedNoToShow - 1;
                                previousColor = Colors.grey;
                                nextColor = Colors.blue;
                              });
                              paginatedPickList = [];
                              paginatedPickList.addAll(pickLists.where((e) =>
                                  pickLists.indexOf(e) <= endIndex &&
                                  pickLists.indexOf(e) >= startIndex));
                              setState(() {
                                shiftLoading = false;
                              });
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () async {
                      setState(() {
                        shiftLoading =
                            (endIndex == pickLists.length - 1) ? false : true;
                      });
                      await Future.delayed(const Duration(milliseconds: 300),
                          () {
                        setState(() {
                          previousColor = Colors.blue;
                        });
                        if (pickLists.length - endIndex >
                            selectedNoToShow + 1) {
                          setState(() {
                            startIndex += selectedNoToShow;
                            endIndex += selectedNoToShow;
                          });
                          paginatedPickList = [];
                          paginatedPickList.addAll(pickLists.where((e) =>
                              pickLists.indexOf(e) <= endIndex &&
                              pickLists.indexOf(e) >= startIndex));
                        } else {
                          if (pickLists.length - startIndex >
                              selectedNoToShow) {
                            setState(() {
                              endIndex = pickLists.length - 1;
                              startIndex += selectedNoToShow;
                              nextColor = Colors.grey;
                            });
                            paginatedPickList = [];
                            paginatedPickList.addAll(pickLists.where((e) =>
                                pickLists.indexOf(e) <= endIndex &&
                                pickLists.indexOf(e) >= startIndex));
                          }
                        }
                        setState(() {
                          shiftLoading = false;
                        });

                        log("next tap startIndex >> $startIndex");
                        log("next tap endIndex >> $endIndex");
                      });
                    },
                    child: Text(
                      'Next',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: nextColor,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Visibility(
            visible: isPicklistVisible == true,
            child: Row(
              children: [
                Container(
                  width: size.width * .7,
                  height: 40,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.grey,
                      width: 1,
                    ),
                    color: Colors.grey.shade300,
                  ),
                  child: const Center(
                    child: Text(
                      'Picklist Details',
                      style: TextStyle(
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                Container(
                  width: size.width * .25,
                  height: 40,
                  decoration: BoxDecoration(
                    border: const Border(
                      right: BorderSide(
                        color: Colors.grey,
                        width: 1,
                      ),
                      top: BorderSide(
                        color: Colors.grey,
                        width: 1,
                      ),
                      bottom: BorderSide(
                        color: Colors.grey,
                        width: 1,
                      ),
                    ),
                    color: Colors.grey.shade300,
                  ),
                  child: const Center(
                    child: Text(
                      'Type',
                      style: TextStyle(
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height:
                pickLists.length > 10 ? size.height * .62 : size.height * .65,
            width: size.width,
            child: isPicklistVisible == false
                ? const Center(
                    child: CircularProgressIndicator(
                      color: appColor,
                    ),
                  )
                : pickLists.isEmpty
                    ? Center(
                        child: Text(
                          'No PickList to show',
                          style: TextStyle(
                            fontSize: size.width * .045,
                          ),
                        ),
                      )
                    : shiftLoading == true
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: appColor,
                            ),
                          )
                        : ListView.builder(
                            itemCount: picklistChooser().length,
                            itemBuilder: (BuildContext context, index) {
                              return Container(
                                alignment: Alignment.center,
                                foregroundDecoration: lockedPicklistList
                                        .isNotEmpty
                                    ? lockedPicklistList
                                            .map((e) => e.batchId)
                                            .toList()
                                            .contains(picklistChooser()[index]
                                                .batchId)
                                        ? lockedPicklistList[lockedPicklistList
                                                        .indexWhere((e) =>
                                                            e.batchId ==
                                                            picklistChooser()[
                                                                    index]
                                                                .batchId)]
                                                    .userName ==
                                                widget.userName
                                            ? null
                                            : const BoxDecoration(
                                                color: Colors.grey,
                                                backgroundBlendMode:
                                                    BlendMode.saturation,
                                              )
                                        : null
                                    : null,
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          height: heightCheckerForMobile(
                                              index: index),
                                          width: size.width * .7,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            border: const Border(
                                              right: BorderSide(
                                                color: Colors.grey,
                                                width: 1,
                                              ),
                                              left: BorderSide(
                                                color: Colors.grey,
                                                width: 1,
                                              ),
                                              bottom: BorderSide(
                                                color: Colors.grey,
                                                width: 1,
                                              ),
                                            ),
                                            color: Colors.grey.shade200,
                                          ),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              GestureDetector(
                                                onTap: () {
                                                  moveToPicklistDetailsOrAllocationScreenWeb(
                                                    index: index,
                                                    showPickedOrders: false,
                                                  );
                                                },
                                                child: Padding(
                                                  padding:
                                                  const EdgeInsets.only(
                                                      top: 5, left: 10),
                                                  child: Text(
                                                    picklistChooser()[index]
                                                        .picklist,
                                                    style: const TextStyle(
                                                      fontSize: 17,
                                                      fontWeight:
                                                      FontWeight.bold,
                                                      color:
                                                      Colors.lightBlue,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Padding(
                                                padding:
                                                const EdgeInsets.only(
                                                    top: 5, left: 10),
                                                child: Text(
                                                  picklistChooser()[index]
                                                      .createdOn,
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ),
                                              Padding(
                                                padding:
                                                const EdgeInsets.only(
                                                    top: 5, left: 10),
                                                child: Row(
                                                  children: [
                                                    const Text(
                                                      'Status : ',
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        fontWeight:
                                                        FontWeight.bold,
                                                      ),
                                                    ),
                                                    Text(
                                                      picklistChooser()[index]
                                                          .status,
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        fontWeight:
                                                        FontWeight.bold,
                                                        color:
                                                        colorChooserForStatus(
                                                            index: index),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Visibility(
                                                visible: picklistChooser()[
                                                index]
                                                    .status
                                                    .contains(
                                                    'In Progress') ||
                                                    picklistChooser()[index]
                                                        .status
                                                        .contains(
                                                        'Not Started'),
                                                child: GestureDetector(
                                                  onTap: () {
                                                    moveToPicklistDetailsOrAllocationScreenWeb(
                                                      index: index,
                                                      showPickedOrders: false,
                                                    );
                                                  },
                                                  child: Padding(
                                                    padding:
                                                    const EdgeInsets.only(
                                                        top: 5, left: 10),
                                                    child: Row(
                                                      children: [
                                                        Visibility(
                                                          visible:
                                                          leftOrderOrSkuVisible(
                                                              index),
                                                          child: Text(
                                                            picklistChooser()[index]
                                                                .requestType ==
                                                                'MSMQW'
                                                                ? '${parseToInt(picklistChooser()[index].totalorder) - parseToInt(picklistChooser()[index].pickedorder)} ${(parseToInt(picklistChooser()[index].totalorder) - parseToInt(picklistChooser()[index].pickedorder) > 1 ? 'Orders' : 'Order')} '
                                                                : '${parseToInt(picklistChooser()[index].totalsku) - parseToInt(picklistChooser()[index].pickedsku)} ${(parseToInt(picklistChooser()[index].totalsku) - parseToInt(picklistChooser()[index].pickedsku) > 1 ? 'SKUs' : 'SKU')} ',
                                                            style:
                                                            const TextStyle(
                                                              fontSize: 14,
                                                              fontWeight:
                                                              FontWeight
                                                                  .bold,
                                                            ),
                                                          ),
                                                        ),
                                                        Visibility(
                                                          visible:
                                                          leftOrderOrSkuVisible(
                                                              index),
                                                          child: const Text(
                                                            'Left to be Picked',
                                                            style:
                                                            TextStyle(
                                                              fontSize: 14,
                                                            ),
                                                          ),
                                                        ),
                                                        Visibility(
                                                          visible: leftOrderOrSkuVisible(
                                                              index) &&
                                                              leftPartialOrderOrSkuVisible(
                                                                  index),
                                                          child: const Text(
                                                            ' & ',
                                                            style:
                                                            TextStyle(
                                                              fontSize: 14,
                                                            ),
                                                          ),
                                                        ),
                                                        Visibility(
                                                          visible:
                                                          leftPartialOrderOrSkuVisible(
                                                              index),
                                                          child: Text(
                                                            picklistChooser()[index]
                                                                .requestType ==
                                                                'MSMQW'
                                                                ? '${picklistChooser()[index].partialOrders} ${parseToInt(picklistChooser()[index].partialOrders) > 1 ? 'Orders' : 'Order'} '
                                                                : '${picklistChooser()[index].partialSkus} ${parseToInt(picklistChooser()[index].partialSkus) > 1 ? 'SKUs' : 'SKU'} ',
                                                            style:
                                                            const TextStyle(
                                                              fontSize: 14,
                                                              fontWeight:
                                                              FontWeight
                                                                  .bold,
                                                            ),
                                                          ),
                                                        ),
                                                        Visibility(
                                                          visible:
                                                          leftPartialOrderOrSkuVisible(
                                                              index),
                                                          child: const Text(
                                                            'Partially Left to be Picked',
                                                            style:
                                                            TextStyle(
                                                              fontSize: 14,
                                                            ),
                                                          ),
                                                        ),
                                                        Visibility(
                                                          visible: leftOrderOrSkuVisible(
                                                              index) ||
                                                              leftPartialOrderOrSkuVisible(
                                                                  index),
                                                          child: const Icon(
                                                            Icons
                                                                .navigate_next,
                                                            size: 20,
                                                          ),
                                                        )
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Visibility(
                                                visible: (picklistChooser()[
                                                index]
                                                    .requestType ==
                                                    'MSMQW'
                                                    ? picklistChooser()[
                                                index]
                                                    .pickedorder
                                                    : picklistChooser()[
                                                index]
                                                    .pickedsku) !=
                                                    '0' &&
                                                    (picklistChooser()[index]
                                                        .requestType ==
                                                        'MSMQW'
                                                        ? picklistChooser()[
                                                    index]
                                                        .pickedorder
                                                        : picklistChooser()[
                                                    index]
                                                        .pickedsku) !=
                                                        '',
                                                child: Visibility(
                                                  visible: picklistChooser()[
                                                  index]
                                                      .status
                                                      .contains(
                                                      'Complete') ||
                                                      picklistChooser()[index]
                                                          .status
                                                          .contains(
                                                          'In Progress') ||
                                                      picklistChooser()[index]
                                                          .status
                                                          .contains(
                                                          'Not Started'),
                                                  child: GestureDetector(
                                                    onTap: () async {
                                                      moveToPicklistDetailsOrAllocationScreenWeb(
                                                        index: index,
                                                        showPickedOrders:
                                                        true,
                                                      );
                                                    },
                                                    child: Padding(
                                                      padding:
                                                      const EdgeInsets
                                                          .only(
                                                          top: 5,
                                                          left: 10),
                                                      child: Row(
                                                        children: [
                                                          Visibility(
                                                            visible:
                                                            validatedOrderOrSkuVisible(
                                                                index),
                                                            child:
                                                            Text(
                                                              picklistChooser()[index]
                                                                  .requestType ==
                                                                  'MSMQW'
                                                                  ? '${parseToInt(picklistChooser()[index].pickedorder) - parseToInt(picklistChooser()[index].partialOrders)} ${parseToInt(picklistChooser()[index].pickedorder) - parseToInt(picklistChooser()[index].partialOrders) > 1 ? 'Orders' : 'Order'} '
                                                                  : '${parseToInt(picklistChooser()[index].pickedsku) - parseToInt(picklistChooser()[index].partialSkus)} ${parseToInt(picklistChooser()[index].pickedsku) - parseToInt(picklistChooser()[index].partialSkus) > 1 ? 'SKUs' : 'SKU'} ',
                                                              style:
                                                              const TextStyle(
                                                                fontSize:
                                                                14,
                                                                fontWeight:
                                                                FontWeight
                                                                    .bold,
                                                              ),
                                                            ),
                                                          ),
                                                          Visibility(
                                                            visible:
                                                            validatedOrderOrSkuVisible(
                                                                index),
                                                            child:
                                                            const Text(
                                                              'Picked',
                                                              style:
                                                              TextStyle(
                                                                fontSize:
                                                                14,
                                                              ),
                                                            ),
                                                          ),
                                                          Visibility(
                                                            visible: validatedOrderOrSkuVisible(
                                                                index) &&
                                                                validatedPartialOrderOrSkuVisible(
                                                                    index),
                                                            child:
                                                            const Text(
                                                              ' & ',
                                                              style:
                                                              TextStyle(
                                                                fontSize:
                                                                14,
                                                              ),
                                                            ),
                                                          ),
                                                          Visibility(
                                                            visible:
                                                            validatedPartialOrderOrSkuVisible(
                                                                index),
                                                            child:
                                                            Text(
                                                              picklistChooser()[index]
                                                                  .requestType ==
                                                                  'MSMQW'
                                                                  ? '${picklistChooser()[index].partialOrders} ${parseToInt(picklistChooser()[index].partialOrders) > 1 ? 'Orders' : 'Order'} '
                                                                  : '${picklistChooser()[index].partialSkus} ${parseToInt(picklistChooser()[index].partialSkus) > 1 ? 'SKUs' : 'SKU'} ',
                                                              style:
                                                              const TextStyle(
                                                                fontSize:
                                                                14,
                                                                fontWeight:
                                                                FontWeight
                                                                    .bold,
                                                              ),
                                                            ),
                                                          ),
                                                          Visibility(
                                                            visible:
                                                            validatedPartialOrderOrSkuVisible(
                                                                index),
                                                            child:
                                                            const Text(
                                                              'Partially Picked',
                                                              style:
                                                              TextStyle(
                                                                fontSize:
                                                                14,
                                                              ),
                                                            ),
                                                          ),
                                                          const Icon(
                                                            Icons
                                                                .navigate_next,
                                                            size: 20,
                                                          )
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          height: heightCheckerForMobile(
                                              index: index),
                                          width: size.width * .25,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            border: const Border(
                                              right: BorderSide(
                                                color: Colors.grey,
                                                width: 1,
                                              ),
                                              bottom: BorderSide(
                                                color: Colors.grey,
                                                width: 1,
                                              ),
                                            ),
                                            color: Colors.grey.shade200,
                                          ),
                                          child: Center(
                                            child: Text(
                                              picklistChooser()[index]
                                                  .requestType,
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Container(
                                          width: size.width * .95,
                                          height: size.height * .08,
                                          decoration: BoxDecoration(
                                            border: const Border(
                                              left: BorderSide(
                                                color: Colors.grey,
                                                width: 1,
                                              ),
                                              right: BorderSide(
                                                color: Colors.grey,
                                                width: 1,
                                              ),
                                              bottom: BorderSide(
                                                color: Colors.grey,
                                                width: 1,
                                              ),
                                            ),
                                            color: Colors.grey.shade200,
                                          ),
                                          child: Visibility(
                                            visible: picklistChooser()[index]
                                                .status
                                                .isNotEmpty,
                                            child: Center(
                                              child: picklistChooser()[index]
                                                              .status ==
                                                          'Complete' ||
                                                      picklistChooser()[index]
                                                              .status ==
                                                          'Processing.......' ||
                                                      picklistChooser()[index]
                                                          .status
                                                          .contains(
                                                              'No Ean to be picked')
                                                  ? Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .center,
                                                      children: [
                                                        Text(
                                                          picklistChooser()[
                                                                          index]
                                                                      .status ==
                                                                  'Complete'
                                                              ? '${picklistChooser()[index].picklist} Validated'
                                                              : picklistChooser()[
                                                                              index]
                                                                          .status ==
                                                                      'Processing.......'
                                                                  ? 'Processing.......'
                                                                  : 'No Ean to be Picked',
                                                          style:
                                                              const TextStyle(
                                                            fontSize: 14,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                      ],
                                                    )
                                                  : SizedBox(
                                                      height: size.height * .05,
                                                      width: size.width * .8,
                                                      child: ElevatedButton(
                                                        style: ElevatedButton
                                                            .styleFrom(
                                                                backgroundColor:
                                                                    Colors
                                                                        .green),
                                                        onPressed: () async {
                                                          lockedPicklistList
                                                                  .isNotEmpty
                                                              ? lockedPicklistList
                                                                      .map((e) => e
                                                                          .batchId)
                                                                      .toList()
                                                                      .contains(
                                                                          picklistChooser()[index]
                                                                              .batchId)
                                                                  ? lockedPicklistList[lockedPicklistList.indexWhere((e) => e.batchId == picklistChooser()[index].batchId)]
                                                                              .userName ==
                                                                          widget
                                                                              .userName
                                                                      ? validateAllPicklist(
                                                                          index)
                                                                      : ToastUtils.showCenteredLongToast(message: '${picklistChooser()[index].picklist} Locked as another user is working on this picklist.')
                                                                  : validateAllPicklist(
                                                                      index)
                                                              : validateAllPicklist(
                                                                  index);
                                                        },
                                                        child: Center(
                                                          child: Text(
                                                            'Validate ${picklistChooser()[index].picklist}',
                                                            style:
                                                                const TextStyle(
                                                              fontSize: 14,
                                                              color:
                                                                  Colors.white,
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
                                  ],
                                ),
                              );
                            }),
          ),
        ],
      ),
    );
  }

  void validateAllPicklist(int index) async {
    await getPickListDetails(
      batchId: picklistChooser()[index].batchId,
      showPickedOrders: false,
    ).whenComplete(() async {
      await updateQtyToPick(
        batchId: picklistChooser()[index].batchId,
        isWeb: true,
        context: context,
        picklist: picklistChooser()[index].picklist,
      );
    }).whenComplete(() => pickListApis());
  }

  void createNewPicklistMethod(BuildContext context) async {
    if (pickLists[0].status != 'Processing.......') {
      if (pickLists[0].status.contains('No Ean to be picked') == false) {
        await createNewPicklist(
          picklistType: selectedPicklist,
        ).whenComplete(() async {
          if (isPicklistSuccessful == true) {
            await Future.delayed(const Duration(milliseconds: 300), () async {
              createController.reset();
              Navigator.pop(context);
              setState(() {
                isCreatingPicklist = true;
                pendingPickListNo = 1 +
                    parseToInt(
                      pickDB.substring(
                        pickDB.indexOf('-') + 1,
                        pickDB.length,
                      ),
                    );
                pendingPicklistRequestType = selectedPicklist;
              });
              await savePicklistData(
                picklist:
                    'Picklist-${parseToInt(pickDB.substring(pickDB.indexOf('-') + 1, pickDB.length)) + 1}',
                length: pickListCount + 1,
                pendingPicklistNo: parseToInt(pickDB.substring(
                        pickDB.indexOf('-') + 1, pickDB.length)) +
                    1,
                pendingPicklistRequestType: selectedPicklist,
              ).whenComplete(() => pickListApis());
            });
          } else {
            await Future.delayed(const Duration(milliseconds: 500), () {
              createController.reset();
            });
          }
        });
      } else {
        Navigator.pop(context);
        if (kIsWeb == true) {
          ToastUtils.motionToastCentered1500MS(
            message: 'Processing..',
            context: context,
          );
        } else {
          ToastUtils.showCenteredShortToast(message: 'Processing..');
        }
        await Future.delayed(const Duration(milliseconds: 100), () {
          pickListApis();
        }).whenComplete(() async {
          await createNewPicklist(
            picklistType: selectedPicklist,
          ).whenComplete(() async {
            if (isPicklistSuccessful == true) {
              await Future.delayed(const Duration(milliseconds: 300), () async {
                createController.reset();
                setState(() {
                  isCreatingPicklist = true;
                  pendingPickListNo = 1 +
                      parseToInt(
                        pickDB.substring(
                          pickDB.indexOf('-') + 1,
                          pickDB.length,
                        ),
                      );
                  pendingPicklistRequestType = selectedPicklist;
                });
                await savePicklistData(
                  picklist:
                      'Picklist-${parseToInt(pickDB.substring(pickDB.indexOf('-') + 1, pickDB.length)) + 1}',
                  length: pickListCount + 1,
                  pendingPicklistNo: parseToInt(pickDB.substring(
                          pickDB.indexOf('-') + 1, pickDB.length)) +
                      1,
                  pendingPicklistRequestType: selectedPicklist,
                ).whenComplete(() => pickListApis());
              });
            } else {
              await Future.delayed(const Duration(milliseconds: 500), () {
                createController.reset();
              });
            }
          });
        });
      }
    } else {
      await Future.delayed(const Duration(seconds: 1), () async {
        if (kIsWeb == true) {
          ToastUtils.motionToastCentered(
            message:
                'Picklist already running! Please wait and try again later',
            context: context,
          );
        } else {
          ToastUtils.showCenteredShortToast(
            message:
                'Picklist already running! Please wait and try again later',
          );
        }
        await Future.delayed(const Duration(seconds: 1), () {
          createController.reset();
        });
      });
    }
  }

  MouseCursor mouseCursorForWeb({required int index}) {
    return lockedPicklistList.isNotEmpty
        ? lockedPicklistList
                .map((e) => e.batchId)
                .toList()
                .contains(picklistChooser()[index].batchId)
            ? lockedPicklistList[lockedPicklistList.indexWhere((e) =>
                            e.batchId == picklistChooser()[index].batchId)]
                        .userName ==
                    widget.userName
                ? SystemMouseCursors.click
                : SystemMouseCursors.basic
            : SystemMouseCursors.click
        : SystemMouseCursors.click;
  }

  void moveToPicklistDetailsOrAllocationScreenWeb({
    required bool showPickedOrders,
    required int index,
  }) async {
    if (picklistChooser()[index].requestType == 'SIW' ||
        picklistChooser()[index].requestType == 'SSMQW') {
      /// PICKLIST OPENING FIRST TIME
      if (picklistChooser()[index].isAlreadyOpened == '') {
        bool result = await NavigationMethods.pushWithResult(
          context,
          PicklistAllocatingScreenWeb(
            batchId: picklistChooser()[index].batchId,
            appBarName:
                '${picklistChooser()[index].picklist} (${picklistChooser()[index].requestType})',
            picklist: picklistChooser()[index].picklist,
            status: picklistChooser()[index].status,
            showPickedOrders: false,
            totalQty:
                '${parseToInt(picklistChooser()[index].totalsku) - parseToInt(picklistChooser()[index].pickedsku)}',
            picklistLength: pickListCount,
          ),
        );
        if (result == true) {
          if (!mounted) return;
          ToastUtils.motionToastCentered20S(
              message: 'Processing New Picklists.........', context: context);
          await Future.delayed(const Duration(seconds: 20), () {
            pickListApis();
          });
        }
      }

      /// PICKLIST OPENING SECOND TIME ONWARDS
      if (picklistChooser()[index].isAlreadyOpened == 'true') {
        await getSavedLockedPicklistData()
            .whenComplete(() => deleteOlderLockedPicklists())
            .whenComplete(() {
          if (lockedPicklistList.isNotEmpty) {
            if (lockedPicklistList
                .map((e) => e.batchId)
                .toList()
                .contains(picklistChooser()[index].batchId)) {
              if (lockedPicklistList[lockedPicklistList.indexWhere(
                          (e) => e.batchId == picklistChooser()[index].batchId)]
                      .userName !=
                  widget.userName) {
                ToastUtils.motionToastCentered1500MS(
                    message:
                        '${picklistChooser()[index].picklist} is Locked as another user is working on this picklist.',
                    context: context);
                pickListApis();
              } else {
                moveToPicklistDetailsWeb(
                  showPickedOrders: showPickedOrders,
                  index: index,
                );
              }
            } else {
              moveToPicklistDetailsWeb(
                showPickedOrders: showPickedOrders,
                index: index,
              );
            }
          } else {
            moveToPicklistDetailsWeb(
              showPickedOrders: showPickedOrders,
              index: index,
            );
          }
        });
      }
    } else {
      await getSavedLockedPicklistData()
          .whenComplete(() => deleteOlderLockedPicklists())
          .whenComplete(() {
        if (lockedPicklistList.isNotEmpty) {
          if (lockedPicklistList
              .map((e) => e.batchId)
              .toList()
              .contains(picklistChooser()[index].batchId)) {
            if (lockedPicklistList[lockedPicklistList.indexWhere(
                        (e) => e.batchId == picklistChooser()[index].batchId)]
                    .userName !=
                widget.userName) {
              ToastUtils.motionToastCentered1500MS(
                  message:
                      '${picklistChooser()[index].picklist} is Locked as another user is working on this picklist.',
                  context: context);
              pickListApis();
            } else {
              moveToPicklistDetailsWeb(
                showPickedOrders: showPickedOrders,
                index: index,
              );
            }
          } else {
            moveToPicklistDetailsWeb(
              showPickedOrders: showPickedOrders,
              index: index,
            );
          }
        } else {
          moveToPicklistDetailsWeb(
            showPickedOrders: showPickedOrders,
            index: index,
          );
        }
      });
    }
  }

  void moveToPicklistDetailsWeb({
    required bool showPickedOrders,
    required int index,
  }) async {
    await saveDataForLockingPicklist(
      userName: widget.userName,
      batchId: picklistChooser()[index].batchId,
    ).whenComplete(() async => await NavigationMethods.push(
          context,
          PickListDetails(
            batchId: picklistChooser()[index].batchId,
            requestType: picklistChooser()[index].requestType,
            appBarName:
                '${picklistChooser()[index].picklist} (${picklistChooser()[index].requestType})',
            isSKUAvailable: parseToInt(picklistChooser()[index].totalsku) > 0
                ? true
                : false,
            status: picklistChooser()[index].status,
            isStatusComplete:
                picklistChooser()[index].status == 'Complete' ? true : false,
            orderPicked: picklistChooser()[index].pickedorder,
            partialOrders: picklistChooser()[index].partialOrders,
            totalOrders: picklistChooser()[index].totalorder,
            accType: widget.accType,
            authorization: widget.authorization,
            refreshToken: widget.refreshToken,
            profileId: widget.profileId,
            distCenterName: widget.distCenterName,
            distCenterId: widget.distCenterId,
            showPickedOrders: showPickedOrders,
          ),
        ).whenComplete(() => pickListApis()));
  }

  void pickListApis() async {
    await loadingPicklistsData().whenComplete(() async {
      await getSavedLockedPicklistData()
          .whenComplete(() => deleteOlderLockedPicklists());
    }).whenComplete(() async {
      await getAllPickList();
    }).whenComplete(() {
      setPendingPicklistOrSaveCurrentApiDataToDb(
        picklistNo: pendingPickListNo,
        requestType: pendingPicklistRequestType,
      );
    });
  }

  Future<void> createNewPicklist({
    required String picklistType,
  }) async {
    String uri =
        'https://weblegs.info/JadlamApp/api/PickList?type=$picklistType';
    log('createNewPicklist uri >>>>>>>> $uri');

    try {
      var response = await http.get(Uri.parse(uri)).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          Fluttertoast.showToast(msg: "Connection Timeout.\nPlease try again.");
          return http.Response('Error', 408);
        },
      );

      if (response.statusCode == 200) {
        log('getAllPickList response >>>>> ${jsonDecode(response.body)}');

        ToastUtils.showCenteredShortToast(
            message: jsonDecode(response.body)['data'].toString());
        setState(() {
          isPicklistSuccessful = true;
        });
      } else {
        ToastUtils.showCenteredLongToast(
            message: jsonDecode(response.body)['message'].toString());
        setState(() {
          isPicklistSuccessful = false;
        });
      }
    } on Exception catch (e) {
      log(e.toString());
      ToastUtils.showCenteredLongToast(message: e.toString());
    }
  }

  Future<void> getAllPickList() async {
    String uri = 'https://weblegs.info/JadlamApp/api/GetPickListVersion2';
    log('getAllPickList - $uri');
    //Todo: fix this issue >>---> Error: setState() called after dispose(): _PickListsState#822af(lifecycle state: defunct, not mounted)
    if (!mounted) return;
    setState(() {
      isPicklistVisible = false;
    });
    try {
      var response = await http.get(Uri.parse(uri)).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          Fluttertoast.showToast(msg: "Connection Timeout.\nPlease try again.");
          //Todo: fix this issue >>---> Error: setState() called after dispose(): _PickListsState#822af(lifecycle state: defunct, not mounted)
          if (!mounted) return http.Response('Error', 408);
          setState(() {
            isPicklistVisible = true;
          });
          return http.Response('Error', 408);
        },
      );

      if (response.statusCode == 200) {
        log('gP resp > ${jsonDecode(response.body)}');

        GetAllPicklistResponse getAllPicklistResponse =
            GetAllPicklistResponse.fromJson(jsonDecode(response.body));
        log('getAllPicklistResponse >>>>> ${jsonEncode(getAllPicklistResponse)}');

        pickLists = <Batch>[];
        pickLists.addAll(getAllPicklistResponse.batch.map((e) => e));
        log('pickLists >>>>> ${jsonEncode(pickLists)}');

        pickListCount = 0;
        pickListCount = pickLists.length;
        log("pickListCount >>>>> $pickListCount");

        if ('-'.allMatches(pickDB).length > 1) {
          /// MEANS WRONG PICKLIST TITLE WAS SAVED TO DB

          int i = 0;
          while (i < pickLists.length) {
            if ('-'.allMatches(pickLists[i].picklist).length == 1) {
              setState(() {
                pickDB = pickLists[i].picklist;
              });
              break;
            }
            i++;
          }
        }
        log('VALUE OF PICK DB >>---> $pickDB');

        if (picklistLengthDB == pickListCount) {
          /// picklist is not running, check whether error in new picklist or not.
          //Todo: fix this issue >>---> Error: setState() called after dispose(): _PickListsState#822af(lifecycle state: defunct, not mounted)
          if (!mounted) return;
          setState(() {
            isCreatingPicklist = false;
          });
          log('isCreatingPicklist when app not running >> $isCreatingPicklist');
          if (pickLists[0].picklist == 'null') {
            /// dialog showing new picklist is having error.
            if (isErrorShown == 'No') {
              //Todo: fix this issue >>---> Error: setState() called after dispose(): _PickListsState#822af(lifecycle state: defunct, not mounted)
              if (!mounted) return;
              setState(() {
                errorVisible = true;
              });
              log('errorVisible app not running >> $errorVisible');
              pickLists.insert(
                  0,
                  Batch(
                    picklist: pickDB,
                    batchId: pickLists[0].batchId,
                    createdOn: pickLists[0].createdOn,
                    requestType: pickLists[0].requestType,
                    status: kIsWeb == true
                        ? 'No Ean to be picked for ${pickLists[0].requestType} Picklist'
                        : 'No Ean to be picked',
                    pickedsku: pickLists[0].pickedsku,
                    totalsku: pickLists[0].totalsku,
                    pickedorder: pickLists[0].pickedorder,
                    totalorder: pickLists[0].totalorder,
                    partialOrders: pickLists[0].partialOrders,
                    partialSkus: pickLists[0].partialSkus,
                    isAlreadyOpened: 'true',
                  ));

              setState(() {
                pickListLengthToSave = pickLists.length;
              });

              pickLists.removeWhere(
                  (e) => pickLists.indexOf(e) > 0 && e.picklist == 'null');

              if (selectedStatusToFilter != 'All Picklists') {
                pickLists.removeWhere((e) =>
                    (e.status != selectedStatusToFilter &&
                        e.status.contains('Processing') == false &&
                        e.status.contains('No Ean to be picked') == false));
              }

              if (pickLists.length > 10) {
                paginatedPickList = [];
                paginatedPickList.addAll(pickLists.where((e) =>
                    pickLists.indexOf(e) <= endIndex &&
                    pickLists.indexOf(e) >= startIndex));
              }

              setState(() {
                lastCreatedPicklistToSave = pickLists[0].picklist;
              });

              /// giving value to number to show dropdown
              noToShow = [];
              for (int i = 1; i < (pickLists.length / 1.5); i++) {
                if (i % 5 == 0) {
                  noToShow.add(i);
                }
              }
              log('noToShow (error not shown picklist null) >> $noToShow');
              savePickListInError(picklist: pickLists[1].picklist);
            } else {
              setState(() {
                pickListLengthToSave = pickLists.length;
              });

              pickLists.removeWhere((e) => e.picklist == 'null');

              if (selectedStatusToFilter != 'All Picklists') {
                pickLists.removeWhere((e) =>
                    (e.status != selectedStatusToFilter &&
                        e.status.contains('Processing') == false &&
                        e.status.contains('No Ean to be picked') == false));
              }

              if (pickLists.length > 10) {
                paginatedPickList = [];
                paginatedPickList.addAll(pickLists.where((e) =>
                    pickLists.indexOf(e) <= endIndex &&
                    pickLists.indexOf(e) >= startIndex));
              }

              setState(() {
                lastCreatedPicklistToSave = pickLists[0].picklist;
              });

              /// giving value to number to show dropdown
              noToShow = [];
              for (int i = 1; i < (pickLists.length / 1.5); i++) {
                if (i % 5 == 0) {
                  noToShow.add(i);
                }
              }
              log('noToShow (error shown picklist null) >> $noToShow');
            }
          } else {
            /// new picklist not having error - do nothing.

            setState(() {
              pickListLengthToSave = pickLists.length;
            });

            pickLists.removeWhere((e) => e.picklist == 'null');

            if (selectedStatusToFilter != 'All Picklists') {
              pickLists.removeWhere((e) =>
                  (e.status != selectedStatusToFilter &&
                      e.status.contains('Processing') == false &&
                      e.status.contains('No Ean to be picked') == false));
            }

            if (pickLists.length > 10) {
              paginatedPickList = [];
              paginatedPickList.addAll(pickLists.where((e) =>
                  pickLists.indexOf(e) <= endIndex &&
                  pickLists.indexOf(e) >= startIndex));
            }

            setState(() {
              lastCreatedPicklistToSave = pickLists[0].picklist;
            });

            /// giving value to number to show dropdown
            noToShow = [];
            for (int i = 1; i < (pickLists.length / 1.5); i++) {
              if (i % 5 == 0) {
                noToShow.add(i);
              }
            }
            log('noToShow (picklist not null)>> $noToShow');
          }
        } else {
          /// app is running currently show progress picklist.
          setState(() {
            isCreatingPicklist = true;
          });
          log('isCreatingPicklist when app running >> $isCreatingPicklist');

          setState(() {
            pickListLengthToSave = pickLists.length;
          });

          pickLists.removeWhere((e) => e.picklist == 'null');

          if (selectedStatusToFilter != 'All Picklists') {
            pickLists.removeWhere((e) => (e.status != selectedStatusToFilter &&
                e.status.contains('Processing') == false &&
                e.status.contains('No Ean to be picked') == false));
          }

          if (pickLists.length > 10) {
            paginatedPickList = [];
            paginatedPickList.addAll(pickLists.where((e) =>
                pickLists.indexOf(e) <= endIndex &&
                pickLists.indexOf(e) >= startIndex));
          }

          setState(() {
            lastCreatedPicklistToSave = pickLists[0].picklist;
          });

          /// giving value to number to show dropdown
          noToShow = [];
          for (int i = 1; i < (pickLists.length / 1.5); i++) {
            if (i % 5 == 0) {
              noToShow.add(i);
            }
          }
          log('noToShow (app running) >> $noToShow');
        }
        log('picklist length to show >> ${picklistChooser().length}');

        setState(() {
          isPicklistVisible = true;
        });
      } else {
        ToastUtils.showCenteredShortToast(message: kerrorString);
        setState(() {
          isPicklistVisible = true;
        });
      }
    } on Exception catch (e) {
      log(e.toString());
      ToastUtils.showCenteredLongToast(message: e.toString());
      setState(() {
        isPicklistVisible = true;
      });
    }
  }

  void savePickListInError({
    required String picklist,
  }) async {
    var picklistData = ParseObject('picklists_data')
      ..objectId = 'tNeOL7aEYx'
      ..set('last_created_picklist', picklist)
      ..set('isErrorShown', 'Yes');
    await picklistData.save();
  }

  Future<void> savePicklistData({
    required String picklist,
    required int length,
    required int pendingPicklistNo,
    required pendingPicklistRequestType,
  }) async {
    var picklistData = ParseObject('picklists_data')
      ..objectId = 'tNeOL7aEYx'
      ..set('last_created_picklist', picklist)
      ..set('date_created', DateTime.now())
      ..set('picklist_length', length)
      ..set('isErrorShown', 'No')
      ..set('pending_picklist_number', pendingPicklistNo)
      ..set('pending_picklist_request_type', pendingPicklistRequestType);
    await picklistData.save();
    log('saving picklist >> $picklist');
  }

  Future<void> loadingPicklistsData() async {
    isPicklistVisible = false;
    await ApiCalls.getPicklistsData().then((data) {
      log('picklists data>>>>>${jsonEncode(data)}');

      picklistsDataDB = [];
      picklistsDataDB.addAll(data.map((e) => e));
      log('picklistsDataDB>>>>>${jsonEncode(picklistsDataDB)}');

      //Todo: fix this issue >>---> Error: setState() called after dispose(): _PickListsState#822af(lifecycle state: defunct, not mounted)
      if (!mounted) return;
      setState(() {
        pickDB = picklistsDataDB[0].get<String>('last_created_picklist') ?? '';
        picklistLengthDB = picklistsDataDB[0].get<int>('picklist_length') ?? 0;
        isErrorShown = picklistsDataDB[0].get<String>('isErrorShown') ?? '';
        pendingPickListNo =
            picklistsDataDB[0].get<int>('pending_picklist_number') ?? 0;
        pendingPicklistRequestType =
            picklistsDataDB[0].get<String>('pending_picklist_request_type') ??
                '';
        savedTime = (picklistsDataDB[0].get('date_created'))
            .add(const Duration(hours: 1));
      });

      log('>>>>>>>>>>>>>>>>>>>>>>>>> Loading Picklist >>>>>>>>>>>>>>>>>>>>>>>>>');
      log('pickDB >> $pickDB');
      log('picklistLengthDB >> $picklistLengthDB');
      log('isErrorShown >> $isErrorShown');
      log('pendingPickListNo >> $pendingPickListNo');
      log('pendingPicklistRequestType >> $pendingPicklistRequestType');
      log('savedTime >> $savedTime');
      log('formatted time >> ${dateFormat.format(savedTime)}');
      log('>>>>>>>>>>>>>>>>>>>>>>>>> Loading Picklist >>>>>>>>>>>>>>>>>>>>>>>>>');
    });
  }

  void setPendingPicklistOrSaveCurrentApiDataToDb({
    required int picklistNo,
    required String requestType,
  }) async {
    /// IF PICKLIST CREATED TIME IS LESS THAN 10 MINUTES OLD : SHOW PENDING PICKLIST
    if (DateTime.now()
            .toUtc()
            .difference(savedTime.subtract(const Duration(hours: 1)))
            .compareTo(const Duration(minutes: 10)) ==
        -1) {
      if (isCreatingPicklist == true) {
        pickLists.insert(
          0,
          Batch(
            picklist: 'Picklist-$picklistNo',
            batchId: '',
            createdOn: dateFormat.format(savedTime),
            requestType: requestType,
            status: 'Processing.......',
            pickedsku: '0',
            totalsku: '0',
            pickedorder: '0',
            totalorder: '0',
            partialOrders: '0',
            partialSkus: '0',
            isAlreadyOpened: 'true',
          ),
        );

        log('pickLists >>>>> ${jsonEncode(pickLists)}');

        paginatedPickList = [];
        paginatedPickList.addAll(pickLists.where((e) =>
            pickLists.indexOf(e) <= endIndex &&
            pickLists.indexOf(e) >= startIndex));

        log('pending case - picklist length to show >> ${picklistChooser().length}');
      }
    } else {
      /// IF PICKLIST CREATED TIME IS MORE THAN 10 MINUTES OLD : SAVE CURRENT API DATA TO DB
      var picklistData = ParseObject('picklists_data')
        ..objectId = 'tNeOL7aEYx'
        ..set('last_created_picklist', lastCreatedPicklistToSave)
        ..set('picklist_length', pickListLengthToSave);
      await picklistData.save();
    }
    await Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      setState(() {
        isPicklistVisible = true;
      });
    });
  }

  Future<void> getSavedLockedPicklistData() async {
    setState(() {
      isPicklistVisible = false;
    });
    String uri = 'https://weblegs.info/JadlamApp/api/GetLoackingEntries';
    log('GET SAVED LOCKED PICKLIST DATA URI >>---> $uri');

    try {
      var response = await http.get(Uri.parse(uri)).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          ToastUtils.motionToastCentered1500MS(
            message: kTimeOut,
            context: context,
          );
          return http.Response('Error', 408);
        },
      );

      if (response.statusCode == 200) {
        log('GET SAVED LOCKED PICKLIST DATA RESPONSE >>---> ${jsonDecode(response.body)}');

        GetLockedPicklistResponse getLockedPicklistResponse =
            GetLockedPicklistResponse.fromJson(jsonDecode(response.body));
        log('V getLockedPicklistResponse >>---> ${jsonEncode(getLockedPicklistResponse)}');

        lockedPicklistList = [];
        if (getLockedPicklistResponse.message.isNotEmpty) {
          lockedPicklistList
              .addAll(getLockedPicklistResponse.message.map((e) => e));
        }
        log('V lockedPicklistList >>---> ${jsonEncode(lockedPicklistList)}');

        setState(() {
          isPicklistSuccessful = true;
        });
      } else {
        if (!mounted) return;
        ToastUtils.motionToastCentered1500MS(
          message: kerrorString,
          context: context,
        );
        setState(() {
          isPicklistSuccessful = false;
        });
      }
    } on Exception catch (e) {
      log('EXCEPTION IN GET SAVED LOCKED PICKLIST DATA API >>---> ${e.toString()}');
      ToastUtils.motionToastCentered1500MS(
        message: e.toString(),
        context: context,
      );
    }
  }

  ///THIS API IS USED FOR DELETING ALL THE LOCKED PICKLISTS OLDER THAN 30 MINUTES IN
  ///THE LIST OF LOCKED PICKLISTS.
  void deleteOlderLockedPicklists() async {
    DateTime britishTimeNow =
        DateTime.now().toUtc().add(const Duration(hours: 1));
    log('V britishTimeNow >>---> $britishTimeNow');

    List<MessageXX> picklistsToDelete = [];
    if (lockedPicklistList
        .where((e) =>
            (britishTimeNow
                .difference(dateFormat.parse(e.createdDate))
                .compareTo(const Duration(minutes: 30))) ==
            1)
        .toList()
        .isNotEmpty) {
      picklistsToDelete.addAll(lockedPicklistList
          .where((e) =>
              (britishTimeNow
                  .difference(dateFormat.parse(e.createdDate))
                  .compareTo(const Duration(minutes: 30))) ==
              1)
          .map((e) => e));
      for (int i = 0; i < picklistsToDelete.length; i++) {
        deleteLockedPicklistData(id: picklistsToDelete[i].id);
        log('DELETED OLDER LOCKED PICKLIST >>---> $i');
      }
    }
  }

  Future<void> deleteLockedPicklistData({required String id}) async {
    String uri = 'https://weblegs.info/JadlamApp/api/DeleteLock?id=$id';
    log('ID TO DELETE >>---> $id');
    log('DELETE LOCKED PICKLIST DATA URI >>---> $uri');

    try {
      var response = await http.get(Uri.parse(uri)).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          ToastUtils.motionToastCentered1500MS(
            message: kTimeOut,
            context: context,
          );
          return http.Response('Error', 408);
        },
      );

      if (response.statusCode == 200) {
        log('DELETE LOCKED PICKLIST DATA RESPONSE >>---> ${jsonDecode(response.body)}');
      } else {
        if (!mounted) return;
        ToastUtils.motionToastCentered1500MS(
          message: kerrorString,
          context: context,
        );
      }
    } on Exception catch (e) {
      log('EXCEPTION IN DELETE LOCKED PICKLIST DATA API >>---> ${e.toString()}');
      ToastUtils.motionToastCentered1500MS(
        message: e.toString(),
        context: context,
      );
    }
  }

  Future<void> saveDataForLockingPicklist({
    required String userName,
    required String batchId,
  }) async {
    String uri =
        'https://weblegs.info/JadlamApp/api/InsertNewLock?user=$userName&BatchId=$batchId';
    log('SAVE LOCKED PICKLIST DATA URI >>---> $uri');

    try {
      var response = await http.get(Uri.parse(uri)).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          ToastUtils.motionToastCentered1500MS(
            message: kTimeOut,
            context: context,
          );
          return http.Response('Error', 408);
        },
      );

      if (response.statusCode == 200) {
        log('SAVE LOCKED PICKLIST DATA RESPONSE >>---> ${jsonDecode(response.body)}');
      } else {
        if (!mounted) return;
        ToastUtils.motionToastCentered1500MS(
          message: kerrorString,
          context: context,
        );
      }
    } on Exception catch (e) {
      log('EXCEPTION IN SAVE LOCKED PICKLIST DATA API >>---> ${e.toString()}');
      ToastUtils.motionToastCentered1500MS(
        message: e.toString(),
        context: context,
      );
    }
  }

  List<Batch> picklistChooser() {
    if (pickLists.length > 10) {
      return paginatedPickList;
    } else {
      return pickLists;
    }
  }

  Color colorChooserForStatus({required int index}) {
    if (picklistChooser()[index].status.contains('Complete')) {
      return Colors.green[700]!;
    } else if (picklistChooser()[index].status.contains('In Progress')) {
      return Colors.orange.shade700;
    } else if (picklistChooser()[index].status.contains('Not Started')) {
      return Colors.amber;
    } else {
      return Colors.red[700]!;
    }
  }

  double? heightCheckerForWeb({required int index}) {
    if (picklistChooser()[index].status.contains('In Progress') ||
        picklistChooser()[index].status.contains('Not Started')) {
      if ((picklistChooser()[index].requestType == 'MSMQW'
                  ? picklistChooser()[index].pickedorder
                  : picklistChooser()[index].pickedsku) !=
              '0' &&
          (picklistChooser()[index].requestType == 'MSMQW'
                  ? picklistChooser()[index].pickedorder
                  : picklistChooser()[index].pickedsku) !=
              '') {
        return 130;
      } else {
        return 105;
      }
    } else if (picklistChooser()[index].status.contains('Complete')) {
      return 105;
    } else {
      return 80;
    }
  }

  double? heightCheckerForMobile({required int index}) {
    if (picklistChooser()[index].status.contains('In Progress') ||
        picklistChooser()[index].status.contains('Not Started')) {
      if ((picklistChooser()[index].requestType == 'MSMQW'
              ? picklistChooser()[index].pickedorder
              : picklistChooser()[index].pickedsku) !=
          '0') {
        return 150;
      } else {
        return 120;
      }
    } else if (picklistChooser()[index].status.contains('Complete')) {
      return 120;
    } else {
      return 90;
    }
  }

  bool leftOrderOrSkuVisible(int index) {
    return picklistChooser()[index].requestType == 'MSMQW'
        ? (parseToInt(picklistChooser()[index].totalorder) -
                    parseToInt(picklistChooser()[index].pickedorder)) >
                0
            ? true
            : false
        : (parseToInt(picklistChooser()[index].totalsku) -
                    parseToInt(picklistChooser()[index].pickedsku)) >
                0
            ? true
            : false;
  }

  bool leftPartialOrderOrSkuVisible(int index) {
    return picklistChooser()[index].requestType == 'MSMQW'
        ? parseToInt(picklistChooser()[index].partialOrders) > 0
            ? true
            : false
        : parseToInt(picklistChooser()[index].partialSkus) > 0
            ? true
            : false;
  }

  bool validatedOrderOrSkuVisible(int index) {
    return picklistChooser()[index].requestType == 'MSMQW'
        ? parseToInt(picklistChooser()[index].pickedorder) -
                    parseToInt(picklistChooser()[index].partialOrders) >
                0
            ? true
            : false
        : parseToInt(picklistChooser()[index].pickedsku) -
                    parseToInt(picklistChooser()[index].partialSkus) >
                0
            ? true
            : false;
  }

  bool validatedPartialOrderOrSkuVisible(int index) {
    return picklistChooser()[index].requestType == 'MSMQW'
        ? parseToInt(picklistChooser()[index].partialOrders) > 0
            ? true
            : false
        : parseToInt(picklistChooser()[index].partialSkus) > 0
            ? true
            : false;
  }

  Future<void> updateQtyToPick({
    required String batchId,
    required bool isWeb,
    required BuildContext context,
    required String picklist,
  }) async {
    setState(() {
      isPicklistVisible = false;
    });
    String uri =
        'https://weblegs.info/JadlamApp/api/UpdatePicksVersion2?BatchId=$batchId&SKU=&OrderNumber=&type=&updateall=true';
    log('updateQtyToPick uri - $uri');

    try {
      var response = await http.get(Uri.parse(uri)).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          if (isWeb == true) {
            ToastUtils.motionToastCentered(
                message: 'Connection Timeout! Please try again',
                context: context);
          } else {
            ToastUtils.showCenteredShortToast(
                message: 'Connection Timeout! Please try again');
          }
          return http.Response('Error', 408);
        },
      );

      if (response.statusCode == 200) {
        log('updateQtyToPick response >>>>> ${jsonDecode(response.body)}');

        if (isWeb == true) {
          if (!mounted) return;
          ToastUtils.motionToastCentered1500MS(
              message: 'All Orders in $picklist is Validated',
              context: context);
        } else {
          ToastUtils.showCenteredShortToast(
            message: 'All Orders in $picklist is Validated',
          );
        }
      } else {
        if (isWeb == true) {
          if (!mounted) return;
          ToastUtils.motionToastCentered(
              message: jsonDecode(response.body)['message'].toString(),
              context: context);
        } else {
          ToastUtils.showCenteredShortToast(
              message: jsonDecode(response.body)['message'].toString());
        }
      }
    } on Exception catch (e) {
      log('Exception in updateQtyToPick api >>> ${e.toString()}');
      if (isWeb == true) {
        if (!mounted) return;
        ToastUtils.motionToastCentered(message: e.toString(), context: context);
      } else {
        ToastUtils.showCenteredShortToast(message: e.toString());
      }
    }
  }

  Future<void> getPickListDetails({
    required String batchId,
    required bool showPickedOrders,
  }) async {
    String uri =
        'https://weblegs.info/JadlamApp/api/GetPicklistByBatchId?BatchId=$batchId&ShowPickedOrders=$showPickedOrders';
    log('getPickListDetails uri - $uri');
    setState(() {
      isPicklistVisible = false;
    });
    try {
      var response = await http.get(Uri.parse(uri)).timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          Fluttertoast.showToast(msg: "Connection Timeout.\nPlease try again.");
          return http.Response('Error', 408);
        },
      );

      if (response.statusCode == 200) {
        log('getPickListDetails response >>>>> ${jsonDecode(response.body)}');

        GetPicklistDetailsResponse getPicklistDetailsResponse =
            GetPicklistDetailsResponse.fromJson(jsonDecode(response.body));
        log('getPicklistDetailsResponse >>>>>>>> ${jsonEncode(getPicklistDetailsResponse)}');

        details = [];
        details.addAll(getPicklistDetailsResponse.sku.map((e) => e));
      } else {
        ToastUtils.showCenteredShortToast(
            message: jsonDecode(response.body)['message'].toString());
      }
    } on Exception catch (e) {
      log(e.toString());
      ToastUtils.showCenteredLongToast(message: e.toString());
    }
  }
}
