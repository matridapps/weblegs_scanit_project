import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:absolute_app/core/apis/api_calls.dart';
import 'package:absolute_app/core/utils/constants.dart';
import 'package:absolute_app/core/utils/navigation_methods.dart';
import 'package:absolute_app/core/utils/toast_utils.dart';
import 'package:absolute_app/core/utils/common_screen_widgets/widgets.dart';
import 'package:absolute_app/models/get_all_picklist_response.dart';
import 'package:absolute_app/models/get_locked_picklist_response.dart';
import 'package:absolute_app/models/get_picklist_details_response.dart';
import 'package:absolute_app/screens/mobile_device_screens/picklist_dc_splitting_screen.dart';
import 'package:absolute_app/screens/mobile_device_screens/picklist_wl_splitting_screen.dart';
import 'package:absolute_app/screens/pick_list/picklist_widgets/picklist_web_builder_widgets/create_new_picklist_button_web.dart';
import 'package:absolute_app/screens/picklist_details.dart';
import 'package:absolute_app/screens/picklist_distribution_center_splitting/picklist_dc_splitting_screen_web.dart';
import 'package:absolute_app/screens/picklist_shipping_class_splitting/picklist_sc_splitting_screen.dart';
import 'package:absolute_app/screens/picklist_warehouse_location_splitting/picklist_wl_splitting_screen_web.dart';
import 'package:animations/animations.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
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
    required this.isDCSplitAutomatic,
  }) : super(key: key);

  final String accType;
  final String authorization;
  final String refreshToken;
  final int profileId;
  final String distCenterName;
  final int distCenterId;
  final String userName;
  final bool isDCSplitAutomatic;

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
  List<MsgX> listOfLockedPicklists = [];
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

  /// A BOOL VARIABLE WHICH IS USED FOR HANDLING THE SCREEN WHEN SCREEN IS
  /// RELOADING WITH FOLLOWING APIS -
  /// 1. getAllPickList
  /// 2. loadingPicklistsDataFromDatabase
  /// 3. setPendingPicklistOrSaveCurrentApiDataToDb
  /// 4. getSavedLockedPicklistData
  /// 5. updateQtyToPick
  /// 6. getPickListDetails
  bool isPicklistVisible = false;
  bool isOpenedLoading = false;

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

  ContainerTransitionType _transitionType = ContainerTransitionType.fade;
  BorderSide _side = BorderSide(color: Colors.grey, width: 1);

  Timer? timer;
  int timerCounter = 0;

  @override
  void initState() {
    super.initState();
    pickListApis();
    timer = Timer.periodic(Duration(seconds: 10), (Timer t) {
      pickListApisNew();
      timerCounter++;
      if(timerCounter > 4) {
        timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  ///<----------------------------------------- START ----------------------------------------------- BUILD METHOD HELPER METHODS -------------------------------------------------->///

  // COMMON APPBAR
  /// APPBAR WIDGET WITH FILTER PICKLIST BASED ON STATUS FUNCTIONALITY FOR WEB
  /// APP AND REFRESH PICKLIST FUNCTIONALITY FOR BOTH WEB APP AND MOBILE APP
  PreferredSizeWidget? _picklistMainScreenAppBar(Size size) {
    return AppBar(
      backgroundColor: Colors.white,
      automaticallyImplyLeading: true,
      iconTheme: const IconThemeData(color: Colors.black),
      centerTitle: true,
      toolbarHeight: AppBar().preferredSize.height,
      title: const Text(
        'Pick Lists',
        style: TextStyle(fontSize: 25, color: Colors.black),
      ),
      actions: [
        Visibility(
          visible: kIsWeb == true,
          child: Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 10, right: 20),
            child: SizedBox(
              height: AppBar().preferredSize.height,
              width: 180,
              child: DropdownButtonHideUnderline(
                child: DropdownButton2<String>(
                  isExpanded: true,
                  items: stringDropdownItems(statusTypes),
                  value: selectedStatusToFilter,
                  onChanged: (String? value) => onPicklistStatusChanged(value!),
                  buttonStyleData: buttonStyleDropdowns(50, 180),
                  dropdownStyleData: dropdownStyle(180),
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 10.0),
          child: IconButton(
            onPressed: () => pickListApis(),
            icon: const Icon(Icons.refresh_rounded, size: kIsWeb ? 25 : 30),
          ),
        )
      ],
    );
  }

  ///<------------- WEB BUILDER HELPER METHODS [WBHM] ---------------------->///

  // [WBHM] 2 :
  /// THE BUILDER FOR ROW CONSISTING THE PREVIOUS BUTTON, NEXT BUTTON, AND THE
  /// CUSTOM DROPDOWN BAR FOR SELECTING COUNT OF PICKLIST TO SHOW IN THE`
  /// PAGINATED PICKLIST FOR WEB APP
  Widget _prevCountNextBuilderWebApp(Size size) {
    return Visibility(
      visible: isPicklistVisible == true,
      child: Visibility(
        visible: pickLists.length > 10,
        child: SizedBox(
          height: 30,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => onTapPrevButton(),
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
                children: [
                  const Text('Showing   ', style: TextStyle(fontSize: 14)),
                  Visibility(
                    visible: noToShow.isNotEmpty,
                    child: SizedBox(
                      height: 25,
                      width: 80,
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton2(
                          isExpanded: true,
                          items: integerDropdownItems(
                              noToShow.isNotEmpty ? noToShow : [5], 14),
                          value: selectedNoToShow,
                          onChanged: (int? value) =>
                              onCountOfPicklistChanged(value!),
                          buttonStyleData: buttonStyleDropdowns(25, 80),
                          dropdownStyleData: dropdownStyle(80),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => onTapNextButton(),
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
    );
  }

  // [WBHM] 3 :
  /// TABLE TITLE ROW BUILDER WITH SAME SIZE AS OTHER PICKLIST TABLE ROWS
  Widget _tableTitleRowBuilderWebApp(Size size) {
    return Visibility(
      visible: isPicklistVisible == true,
      child: SizedBox(
        height: 50,
        child: Row(
          children: [
            Container(
              width: size.width * .7,
              height: 50,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey, width: 1),
                color: Colors.grey.shade300,
              ),
              child: const Center(
                child: Text(
                  'Picklist Details',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            Container(
              width: size.width * .1,
              height: 50,
              decoration: BoxDecoration(
                border: Border(right: _side, top: _side, bottom: _side),
                color: Colors.grey.shade300,
              ),
              child: const Center(
                child: Text(
                  'Type',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            Container(
              width: size.width * .13,
              height: 50,
              decoration: BoxDecoration(
                border: Border(right: _side, top: _side, bottom: _side),
                color: Colors.grey.shade300,
              ),
              child: const Center(
                child: Text(
                  'Validate Picklist',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  // [WBHM] 4 :
  /// PICKLIST TABLE DATA BUILDER FOR WEB APP, WHICH WILL SHOW ALL THE PICKLIST
  /// DATA, PICKLIST TYPE AND VALIDATE PICKLIST BUTTON IN EACH ROW RESPECTIVELY
  Widget _tableDataBuilderWebApp(Size size) {
    return Expanded(
      child: isPicklistVisible == false || shiftLoading == true
          ? loader()
          : pickLists.isEmpty
              ? _noPicklistToShowBuilder(20)
              : ListView.builder(
                  itemCount: picklistChooser().length,
                  itemBuilder: (BuildContext ctx, int index) {
                    return Container(
                      alignment: Alignment.center,
                      foregroundDecoration: outerContainerDecoration(index),
                      child: IntrinsicHeight(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              width: size.width * .7,
                              decoration: innerContainer1(index),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: listOfLockedPicklists.isNotEmpty
                                        ? listOfLockedPicklists
                                                .map((e) => e.batchId)
                                                .toList()
                                                .contains(picklistChooser()[
                                                        index]
                                                    .batchId)
                                            ? listOfLockedPicklists[listOfLockedPicklists
                                                            .indexWhere((e) =>
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
                                              padding: const EdgeInsets.only(
                                                  top: 5, left: 10),
                                              child: Text(
                                                picklistChooser()[index]
                                                    .picklist,
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.lightBlue,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              top: 5, left: 10),
                                          child: Row(
                                            children: [
                                              const Text(
                                                'Created on : ',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
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
                                          padding: const EdgeInsets.only(
                                              top: 5, left: 10),
                                          child: Row(
                                            children: [
                                              const Text(
                                                'Status : ',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Text(
                                                picklistChooser()[index]
                                                            .status
                                                            .isEmpty &&
                                                        picklistChooser()[index]
                                                                .picklist
                                                                .substring(
                                                                    0, 4) ==
                                                            'Shop'
                                                    ? 'Processing...'
                                                    : picklistChooser()[index]
                                                        .status,
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: colorChooserForStatus(
                                                      index: index),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Visibility(
                                          visible: picklistChooser()[index]
                                                  .status
                                                  .contains('In Progress') ||
                                              picklistChooser()[index]
                                                  .status
                                                  .contains('Not Started'),
                                          child: GestureDetector(
                                            onTap: () {
                                              moveToPicklistDetailsOrAllocationScreenWeb(
                                                index: index,
                                                showPickedOrders: false,
                                              );
                                            },
                                            child: Padding(
                                              padding: const EdgeInsets.only(
                                                  top: 5, left: 10),
                                              child: Row(
                                                children: [
                                                  Visibility(
                                                    visible:
                                                        leftOrderOrSkuVisible(
                                                            index),
                                                    child: MouseRegion(
                                                      cursor: mouseCursorForWeb(
                                                        index: index,
                                                      ),
                                                      child: Text(
                                                        picklistChooser()[index]
                                                                    .requestType ==
                                                                'MSMQW'
                                                            ? '${orderLeftToBePicked(index)} ${(orderLeftToBePicked(index) > 1 ? 'Orders' : 'Order')} '
                                                            : '${skuLeftToBePicked(index)} ${(skuLeftToBePicked(index) > 1 ? 'SKUs' : 'SKU')} ',
                                                        style: const TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  Visibility(
                                                    visible:
                                                        leftOrderOrSkuVisible(
                                                            index),
                                                    child: MouseRegion(
                                                      cursor: mouseCursorForWeb(
                                                        index: index,
                                                      ),
                                                      child: const Text(
                                                        'Left to be Picked',
                                                        style: TextStyle(
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
                                                      cursor: mouseCursorForWeb(
                                                        index: index,
                                                      ),
                                                      child: const Text(
                                                        ' & ',
                                                        style: TextStyle(
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
                                                      cursor: mouseCursorForWeb(
                                                        index: index,
                                                      ),
                                                      child: Text(
                                                        picklistChooser()[index]
                                                                    .requestType ==
                                                                'MSMQW'
                                                            ? '${picklistChooser()[index].partialOrders} ${parseToInt(picklistChooser()[index].partialOrders) > 1 ? 'Orders' : 'Order'} '
                                                            : '${picklistChooser()[index].partialSkus} ${parseToInt(picklistChooser()[index].partialSkus) > 1 ? 'SKUs' : 'SKU'} ',
                                                        style: const TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  Visibility(
                                                    visible:
                                                        leftPartialOrderOrSkuVisible(
                                                            index),
                                                    child: MouseRegion(
                                                      cursor: mouseCursorForWeb(
                                                        index: index,
                                                      ),
                                                      child: const Text(
                                                        'Partially Left to be Picked',
                                                        style: TextStyle(
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
                                                      Icons.navigate_next,
                                                      size: 20,
                                                    ),
                                                  ),
                                                  Visibility(
                                                    visible: leftOrderOrSkuVisible(
                                                                index) ==
                                                            false &&
                                                        leftPartialOrderOrSkuVisible(
                                                                index) ==
                                                            false,
                                                    child: const Text(
                                                      'Processing....',
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                  )
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        Visibility(
                                          visible: (picklistChooser()[index]
                                                              .requestType ==
                                                          'MSMQW'
                                                      ? picklistChooser()[index]
                                                          .pickedorder
                                                      : picklistChooser()[index]
                                                          .pickedsku) !=
                                                  '0' &&
                                              (picklistChooser()[index]
                                                              .requestType ==
                                                          'MSMQW'
                                                      ? picklistChooser()[index]
                                                          .pickedorder
                                                      : picklistChooser()[index]
                                                          .pickedsku) !=
                                                  '',
                                          child: Visibility(
                                            visible: picklistChooser()[index]
                                                    .status
                                                    .contains('Complete') ||
                                                picklistChooser()[index]
                                                    .status
                                                    .contains('In Progress') ||
                                                picklistChooser()[index]
                                                    .status
                                                    .contains('Not Started'),
                                            child: GestureDetector(
                                              onTap: () async {
                                                moveToPicklistDetailsOrAllocationScreenWeb(
                                                  index: index,
                                                  showPickedOrders: true,
                                                );
                                              },
                                              child: Padding(
                                                padding: const EdgeInsets.only(
                                                    top: 5, left: 10),
                                                child: Row(
                                                  children: [
                                                    Visibility(
                                                      visible:
                                                          validatedOrderOrSkuVisible(
                                                              index),
                                                      child: MouseRegion(
                                                        cursor:
                                                            mouseCursorForWeb(
                                                          index: index,
                                                        ),
                                                        child: Text(
                                                          picklistChooser()[
                                                                          index]
                                                                      .requestType ==
                                                                  'MSMQW'
                                                              ? '${parseToInt(picklistChooser()[index].pickedorder) - parseToInt(picklistChooser()[index].partialOrders)} ${parseToInt(picklistChooser()[index].pickedorder) - parseToInt(picklistChooser()[index].partialOrders) > 1 ? 'Orders' : 'Order'} '
                                                              : '${parseToInt(picklistChooser()[index].pickedsku) - parseToInt(picklistChooser()[index].partialSkus)} ${parseToInt(picklistChooser()[index].pickedsku) - parseToInt(picklistChooser()[index].partialSkus) > 1 ? 'SKUs' : 'SKU'} ',
                                                          style:
                                                              const TextStyle(
                                                            fontSize: 16,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    Visibility(
                                                      visible:
                                                          validatedOrderOrSkuVisible(
                                                              index),
                                                      child: MouseRegion(
                                                        cursor:
                                                            mouseCursorForWeb(
                                                          index: index,
                                                        ),
                                                        child: const Text(
                                                          'Picked',
                                                          style: TextStyle(
                                                            fontSize: 16,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    Visibility(
                                                      visible:
                                                          validatedOrderOrSkuVisible(
                                                                  index) &&
                                                              validatedPartialOrderOrSkuVisible(
                                                                  index),
                                                      child: MouseRegion(
                                                        cursor:
                                                            mouseCursorForWeb(
                                                          index: index,
                                                        ),
                                                        child: const Text(
                                                          ' & ',
                                                          style: TextStyle(
                                                            fontSize: 16,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    Visibility(
                                                      visible:
                                                          validatedPartialOrderOrSkuVisible(
                                                              index),
                                                      child: MouseRegion(
                                                        cursor:
                                                            mouseCursorForWeb(
                                                          index: index,
                                                        ),
                                                        child: Text(
                                                          picklistChooser()[
                                                                          index]
                                                                      .requestType ==
                                                                  'MSMQW'
                                                              ? '${picklistChooser()[index].partialOrders} ${parseToInt(picklistChooser()[index].partialOrders) > 1 ? 'Orders' : 'Order'} '
                                                              : '${picklistChooser()[index].partialSkus} ${parseToInt(picklistChooser()[index].partialSkus) > 1 ? 'SKUs' : 'SKU'} ',
                                                          style:
                                                              const TextStyle(
                                                            fontSize: 16,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    Visibility(
                                                      visible:
                                                          validatedPartialOrderOrSkuVisible(
                                                              index),
                                                      child: MouseRegion(
                                                        cursor:
                                                            mouseCursorForWeb(
                                                          index: index,
                                                        ),
                                                        child: const Text(
                                                          'Partially Picked',
                                                          style: TextStyle(
                                                            fontSize: 16,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    const Icon(
                                                      Icons.navigate_next,
                                                      size: 20,
                                                    )
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        Visibility(
                                          visible:
                                              splitOnWarehouseLocationVisible(
                                                  index),
                                          child: MouseRegion(
                                            cursor: mouseCursorForWeb(
                                              index: index,
                                            ),
                                            child: GestureDetector(
                                              onTap: () async {
                                                bool result =
                                                    await NavigationMethods
                                                        .pushWithResult(
                                                  context,
                                                  PicklistWlSplittingScreenWeb(
                                                    batchId:
                                                        picklistChooser()[index]
                                                            .batchId,
                                                    appBarName:
                                                        '${picklistChooser()[index].picklist} (${picklistChooser()[index].requestType}) Split on WL',
                                                    picklist:
                                                        picklistChooser()[index]
                                                            .picklist,
                                                    status:
                                                        picklistChooser()[index]
                                                            .status,
                                                    showPickedOrders: false,
                                                    totalQty:
                                                        '${skuLeftToBePicked(index)}',
                                                    picklistLength:
                                                        pickListCount,
                                                  ),
                                                );
                                                if (result == true) {
                                                  if (!mounted) return;
                                                  ToastUtils
                                                      .motionToastCentered1500MS(
                                                          message:
                                                              'Processing New Picklists....',
                                                          context: context);
                                                  await Future.delayed(
                                                      const Duration(
                                                          seconds: 2), () {
                                                    pickListApis();
                                                  });
                                                }
                                              },
                                              child: const Padding(
                                                padding: EdgeInsets.only(
                                                    top: 5, left: 10),
                                                child: Row(
                                                  children: [
                                                    Text(
                                                      'Split on Warehouse Location and Allocate Picklist',
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    Icon(
                                                      Icons.navigate_next,
                                                      size: 20,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        Visibility(
                                          visible:
                                              splitOnDistributionCenterVisible(
                                                  index),
                                          child: MouseRegion(
                                            cursor: mouseCursorForWeb(
                                              index: index,
                                            ),
                                            child: GestureDetector(
                                              onTap: () async {
                                                bool result =
                                                    await NavigationMethods
                                                        .pushWithResult(
                                                  context,
                                                  PicklistDCSplittingScreenWeb(
                                                    batchId:
                                                        picklistChooser()[index]
                                                            .batchId,
                                                    appBarName:
                                                        '${picklistChooser()[index].picklist} (${picklistChooser()[index].requestType}) Split on DC',
                                                    picklist:
                                                        picklistChooser()[index]
                                                            .picklist,
                                                    status:
                                                        picklistChooser()[index]
                                                            .status,
                                                    picklistLength:
                                                        pickListCount,
                                                    totalOrders:
                                                        picklistChooser()[index]
                                                            .totalorder,
                                                  ),
                                                );
                                                if (result == true) {
                                                  if (!mounted) return;
                                                  ToastUtils
                                                      .motionToastCentered1500MS(
                                                          message:
                                                              'Processing New Picklists....',
                                                          context: context);
                                                  await Future.delayed(
                                                      const Duration(
                                                          seconds: 2), () {
                                                    pickListApis();
                                                  });
                                                }
                                              },
                                              child: const Padding(
                                                padding: EdgeInsets.only(
                                                    top: 5, left: 10),
                                                child: Row(
                                                  children: [
                                                    Text(
                                                      'Split on Distribution Center and Allocate Picklist',
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    Icon(
                                                      Icons.navigate_next,
                                                      size: 20,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        Visibility(
                                          visible: splitOnShippingClassVisible(
                                              index),
                                          child: MouseRegion(
                                            cursor: mouseCursorForWeb(
                                              index: index,
                                            ),
                                            child: GestureDetector(
                                              onTap: () async {
                                                bool result =
                                                    await NavigationMethods
                                                        .pushWithResult(
                                                  context,
                                                  PicklistSCSplittingScreen(
                                                    batchId:
                                                        picklistChooser()[index]
                                                            .batchId,
                                                    appBarName:
                                                        '${picklistChooser()[index].picklist} (${picklistChooser()[index].requestType}) Split on SC',
                                                    picklist:
                                                        picklistChooser()[index]
                                                            .picklist,
                                                    status:
                                                        picklistChooser()[index]
                                                            .status,
                                                    picklistLength:
                                                        pickListCount,
                                                    totalOrders:
                                                        picklistChooser()[index]
                                                            .totalorder,
                                                  ),
                                                );
                                                if (result == true) {
                                                  if (!mounted) return;
                                                  ToastUtils
                                                      .motionToastCentered1500MS(
                                                          message:
                                                              'Processing New Picklists....',
                                                          context: context);
                                                  await Future.delayed(
                                                      const Duration(
                                                          seconds: 2), () {
                                                    pickListApis();
                                                  });
                                                }
                                              },
                                              child: const Padding(
                                                padding: EdgeInsets.only(
                                                    top: 5,
                                                    left: 10,
                                                    bottom: 05),
                                                child: Row(
                                                  children: [
                                                    Text(
                                                      'Split on Shipping Class and Allocate Picklist',
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    Icon(
                                                      Icons.navigate_next,
                                                      size: 20,
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
                                  Visibility(
                                    visible: listOfLockedPicklists.isNotEmpty
                                        ? listOfLockedPicklists
                                                .map((e) => e.batchId)
                                                .toList()
                                                .contains(picklistChooser()[
                                                        index]
                                                    .batchId)
                                            ? listOfLockedPicklists[listOfLockedPicklists
                                                            .indexWhere((e) =>
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
                              decoration: innerContainer2(index),
                              child: Center(
                                child: Text(
                                  picklistChooser()[index].requestType,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              width: size.width * .13,
                              decoration: innerContainer2(index),
                              child: picklistChooser()[index].status.isEmpty
                                  ? Center(
                                      child: Text(
                                      '',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ))
                                  : picklistChooser()[index]
                                              .picklist
                                              .substring(0, 4) ==
                                          'Shop'
                                      ? Center(
                                          child: Text(
                                          'Shop Picklist',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ))
                                      : Center(
                                          child: picklistChooser()[index]
                                                          .status ==
                                                      'Complete' ||
                                                  picklistChooser()[index]
                                                          .status ==
                                                      'Processing...' ||
                                                  picklistChooser()[index]
                                                      .status
                                                      .contains('No EAN found!')
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
                                                                  'Processing...'
                                                              ? 'Processing...'
                                                              : 'No EAN found!',
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
                                                      shape:
                                                          RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(14),
                                                      ),
                                                    ),
                                                    onPressed: () async {
                                                      listOfLockedPicklists
                                                              .isNotEmpty
                                                          ? listOfLockedPicklists
                                                                  .map((e) =>
                                                                      e.batchId)
                                                                  .toList()
                                                                  .contains(
                                                                      picklistChooser()[
                                                                              index]
                                                                          .batchId)
                                                              ? listOfLockedPicklists[listOfLockedPicklists.indexWhere((e) =>
                                                                              e.batchId ==
                                                                              picklistChooser()[index]
                                                                                  .batchId)]
                                                                          .userName ==
                                                                      widget
                                                                          .userName
                                                                  ? validateAllPicklist(
                                                                      index)
                                                                  : ToastUtils
                                                                      .motionToastCentered1500MS(
                                                                      message:
                                                                          '${picklistChooser()[index].picklist} Locked as another user is working on this picklist.',
                                                                      context:
                                                                          context,
                                                                    )
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
                            )
                          ],
                        ),
                      ),
                    );
                  }),
    );
  }

  // [WBHM] 4.1 :
  /// WIDGET FOR WEB APP : MOUSE CURSOR CHOOSER
  MouseCursor mouseCursorForWeb({required int index}) {
    return listOfLockedPicklists.isNotEmpty
        ? listOfLockedPicklists
                .map((e) => e.batchId)
                .toList()
                .contains(picklistChooser()[index].batchId)
            ? listOfLockedPicklists[listOfLockedPicklists.indexWhere((e) =>
                            e.batchId == picklistChooser()[index].batchId)]
                        .userName ==
                    widget.userName
                ? SystemMouseCursors.click
                : SystemMouseCursors.basic
            : SystemMouseCursors.click
        : SystemMouseCursors.click;
  }

  // [WBHM] 4.2 :
  /// WIDGET FOR WEB APP : HEIGHT CHECKER CHOOSER
  double? heightCheckerForWeb(int index) {
    bool check1 = picklistChooser()[index].status.contains('In Progress') ||
        picklistChooser()[index].status.contains('Not Started');
    bool check2 = picklistChooser()[index].status.contains('Complete');
    bool check3 = picklistChooser()[index].requestType == 'MSMQW';
    bool check4 = picklistChooser()[index].pickedorder.isNotEmpty &&
        picklistChooser()[index].pickedorder != '0';
    bool check5 = picklistChooser()[index].totalsku.isEmpty;
    bool check6 = picklistChooser()[index].pickedsku.isNotEmpty &&
        picklistChooser()[index].pickedsku != '0';
    bool check7 = splitOnWarehouseLocationVisible(index) &&
        splitOnDistributionCenterVisible(index);
    bool check8 = splitOnWarehouseLocationVisible(index) ||
        splitOnDistributionCenterVisible(index);
    return check1
        ? check3
            ? check4
                ? 130
                : 105
            : check5
                ? 105
                : check6
                    ? check7
                        ? 180
                        : check8
                            ? 155
                            : 130
                    : check7
                        ? 155
                        : check8
                            ? 130
                            : 105
        : check2
            ? 105
            : 80;
  }

  ///<---------- END ----------------------------- [WBHM] ------------------>///

  // WEB BUILDER WIDGET FOR WEB APP SCREEN BODY BUILDER
  Widget _webBuilder(BuildContext context, Size size) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: size.width * .035),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          CreateNewPicklistButtonWeb(
            isVisible: isPicklistVisible,
            size: size,
            items: stringDropdownItems(pickListTypes),
            selectedValue: selectedPicklist,
            buttonStyleData: buttonStyleDropdowns(40, 300),
            dropdownStyleData: dropdownStyle(300),
            cancelController: cancelController,
            onPressedCancel: () => onCancelButtonTapped(context),
            createController: createController,
            onPressedCreate: () => createNewPicklistMethod(context),
          ),
          _prevCountNextBuilderWebApp(size),
          _tableTitleRowBuilderWebApp(size),
          _tableDataBuilderWebApp(size),
        ],
      ),
    );
  }

  ///<------------- MOBILE BUILDER HELPER METHODS [MBHM] ------------------->///

  // [MBHM] 1 :
  /// CREATE NEW PICKLIST BUTTON BUILDER FOR MOBILE APP
  Widget _createNewPicklistButtonMobileBuilder(Size size) {
    return Visibility(
      visible: isPicklistVisible == true,
      child: SizedBox(
        height: 55,
        width: size.width,
        child: Center(
          child: SizedBox(
            height: 40,
            width: size.width * .65,
            child: ElevatedButton(
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
                            style: TextStyle(fontSize: size.width * .055),
                            textAlign: TextAlign.center,
                          ),
                          content: SizedBox(
                              height: size.height * .07,
                              width: size.width * .7,
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton2<String>(
                                  isExpanded: true,
                                  items: stringDropdownItems(pickListTypes),
                                  value: selectedPicklist,
                                  onChanged: (String? value) =>
                                      onPicklistTypeChange(setStateSB, value!),
                                  buttonStyleData: buttonStyleDropdowns(
                                      size.height * .07, size.width * .7),
                                  dropdownStyleData:
                                      dropdownStyle(size.width * .7),
                                ),
                              )),
                          actions: <Widget>[
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(left: 10),
                                    child: RoundedLoadingButton(
                                      color: Colors.red,
                                      borderRadius: 14,
                                      height: size.width * .1,
                                      width: size.width * .25,
                                      successIcon: Icons.check_rounded,
                                      failedIcon: Icons.close_rounded,
                                      successColor: Colors.green,
                                      controller: cancelController,
                                      onPressed: () =>
                                          onCancelButtonTapped(context),
                                      child: const Text(
                                        'Cancel',
                                        style: TextStyle(
                                          fontSize: 15,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(right: 10),
                                          child: RoundedLoadingButton(
                                            color: Colors.green,
                                            borderRadius: 14,
                                            height: size.width * .1,
                                            width: size.width * .25,
                                            successIcon: Icons.check_rounded,
                                            failedIcon: Icons.close_rounded,
                                            successColor: Colors.green,
                                            controller: createController,
                                            onPressed: () {
                                              createNewPicklistMethod(context);
                                            },
                                            child: const Text(
                                              'Create',
                                              style: TextStyle(
                                                fontSize: 15,
                                                color: Colors.white,
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
                          ],
                        );
                      },
                    );
                  },
                );
              },
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                'Create New PickList',
                style: TextStyle(
                  fontSize: size.height * .025,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  ///<----- HELPER FOR _statusAndCountFilterMobileBuilder [HFSACFMB] ------->///

  // [HFSACFMB] 1 :
  /// PADDING ADDED TO STATUS AND COUNT FILTER MOBILE BUILDER WIDGET FOR
  /// DIFFERENT CONDITIONS
  EdgeInsetsGeometry _paddingForStatusAndCountFilterMobile() {
    return pickLists.length > 10 ? EdgeInsets.zero : EdgeInsets.only(bottom: 5);
  }

  // [HFSACFMB] 2 :
  /// CALCULATING WIDTH FOR THE [Showing] TEXT FOR THE MOBILE APP.
  double _showingTextWidth() {
    // 3 PLACES ADDED FOR CALCULATING TEXT SIZE
    return calcTextSize('Showing' + '   ', context).width;
  }

  // [HFSACFMB] 3 :
  /// CALCULATING WIDTH FOR THE STATUS SELECTOR DROPDOWN FOR THE MOBILE APP.
  double _statusSelectorWidth(Size size) {
    return pickLists.length > 10
        ? (size.width * .95 - _showingTextWidth()) * .64
        : size.width * .95 - _showingTextWidth();
  }

  // [HFSACFMB] 4 :
  /// CALCULATING WIDTH FOR THE COUNT OF PICKLIST TO SHOW AT ONCE SELECTOR
  /// DROPDOWN FOR THE MOBILE APP
  double _picklistCountSelectorWidth(Size size) {
    return (size.width * .95 - _showingTextWidth()) * .34;
  }

  ///<------ END ------------------------- [HFSACFMB] ---------------------->///

  // [MBHM] 2 :
  /// THE BUILDER FOR ROW CONSISTING THE STATUS FILTER DROPDOWN, AND THE
  /// DROPDOWN FOR SELECTING COUNT OF PICKLIST TO SHOW IN THE`PAGINATED PICKLIST
  /// FOR MOBILE APP
  Widget _statusAndCountFilterMobileBuilder(BuildContext context, Size size) {
    return Visibility(
      visible: isPicklistVisible == true && kIsWeb != true,
      child: Padding(
        padding: _paddingForStatusAndCountFilterMobile(),
        child: SizedBox(
          height: 40,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: _showingTextWidth(),
                child: const Text('Showing', style: TextStyle(fontSize: 16)),
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: _statusSelectorWidth(size),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton2<String>(
                          isExpanded: true,
                          items: stringDropdownItems(statusTypes),
                          value: selectedStatusToFilter,
                          onChanged: (String? value) =>
                              onPicklistStatusChanged(value!),
                          buttonStyleData: buttonStyleDropdowns(
                              40, _statusSelectorWidth(size)),
                          dropdownStyleData:
                              dropdownStyle(_statusSelectorWidth(size)),
                        ),
                      ),
                    ),
                    Visibility(
                      visible: pickLists.length > 10,
                      child: SizedBox(
                        width: _picklistCountSelectorWidth(size),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton2<int>(
                            isExpanded: true,
                            items: integerDropdownItems(
                                noToShow.isNotEmpty ? noToShow : [5], 18),
                            value: selectedNoToShow,
                            onChanged: (value) =>
                                onCountOfPicklistChanged(value!),
                            buttonStyleData: buttonStyleDropdowns(
                                40, _picklistCountSelectorWidth(size)),
                            dropdownStyleData: dropdownStyle(
                                _picklistCountSelectorWidth(size)),
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
      ),
    );
  }

  // [MBHM] 3 :
  /// THE BUILDER FOR ROW CONSISTING THE PREVIOUS BUTTON, NEXT BUTTON, AND THE
  /// CUSTOM DROPDOWN BAR FOR SELECTING COUNT OF PICKLIST TO SHOW IN THE
  /// PAGINATED PICKLIST FOR MOBILE APP
  Widget _prevCountNextBuilderMobileApp(Size size) {
    return Visibility(
      visible: isPicklistVisible == true,
      child: Visibility(
        visible: pickLists.length > 10,
        child: SizedBox(
          height: 40,
          width: size.width,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () => onTapPrevButton(),
                child: Text(
                  'Previous',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: previousColor,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => onTapNextButton(),
                child: Text(
                  'Next',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: nextColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // [MBHM] 4 :
  /// TABLE TITLE ROW BUILDER WITH SAME SIZE AS OTHER PICKLIST TABLE ROWS FOR
  /// MOBILE APP
  Widget _tableTitleRowBuilderMobileApp(Size size) {
    String u = widget.userName;
    bool visibilityCheck = listOfLockedPicklists.any((e) => e.userName != u);
    return Visibility(
      visible: isPicklistVisible == true,
      child: Row(
        children: [
          Container(
            width: visibilityCheck ? size.width * .7 - 40 : size.width * .7,
            height: 40,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey, width: 1),
              color: Colors.grey.shade300,
            ),
            child: const Center(
              child: Text('Picklist Details', style: TextStyle(fontSize: 18)),
            ),
          ),
          Container(
            width: size.width * .25,
            height: 40,
            decoration: BoxDecoration(
              border: Border(bottom: _side, right: _side, top: _side),
              color: Colors.grey.shade300,
            ),
            child: const Center(
              child: Text('Type', style: TextStyle(fontSize: 18)),
            ),
          ),
          Visibility(
            visible: visibilityCheck,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                border: Border(right: _side, top: _side, bottom: _side),
                color: Colors.grey.shade300,
              ),
            ),
          ),
        ],
      ),
    );
  }

  ///<----- HELPER FOR _newTableDataBuilderMobileApp [HFNTDBMA] ------------>///

  // [HFNTDBMA] 1 :
  /// THE VIEW OF THE MAIN PICKLIST SCREEN WHEN THE OPEN CONTAINER IS CLOSED.
  Widget _closedBuilderForOpenContainer(Size size, int i) {
    String batch = picklistChooser()[i].batchId;
    String title = picklistChooser()[i].picklist;
    String msg = title.length > 30 ? title.substring(0, 24) + '....' : title;
    String u = widget.userName;
    int idx = listOfLockedPicklists.indexWhere((e) => e.batchId == batch);
    bool chk1 = listOfLockedPicklists.isNotEmpty;
    bool chk2 = listOfLockedPicklists.any((e) => e.batchId == batch);
    bool tempCheck = chk2 ? listOfLockedPicklists[idx].userName != u : false;
    bool chk3 = idx == -1 ? false : tempCheck;
    bool visibilityCheck = listOfLockedPicklists.any((e) => e.userName != u);
    Icon _icon = Icon(Icons.lock, color: Colors.grey.shade700, size: 35);
    return GestureDetector(
      onTap: (chk1 && chk2 && chk3)
          ? () => ToastUtils.showCenteredLongToast(message: msg + kLock)
          : null,
      child: Container(
        alignment: Alignment.center,
        foregroundDecoration: outerContainerDecoration(i),
        child: IntrinsicHeight(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: visibilityCheck ? size.width * .7 - 40 : size.width * .7,
                alignment: Alignment.center,
                decoration: innerContainer1(i),
                child: Padding(
                  padding: const EdgeInsets.all(5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.lightBlue,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Text(
                          picklistChooser()[i].createdOn,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'Status : ',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              picklistChooser()[i].status.isEmpty
                                  ? 'Processing...'
                                  : picklistChooser()[i].status,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: colorChooserForStatus(index: i),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                width: size.width * .25,
                alignment: Alignment.center,
                decoration: innerContainer2(i),
                child: Center(
                  child: Text(
                    picklistChooser()[i].requestType,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Visibility(
                visible: visibilityCheck,
                child: Container(
                  width: 40,
                  alignment: Alignment.center,
                  decoration: innerContainer2(i),
                  child: Center(
                    child: (chk1 && chk2 && chk3) ? _icon : SizedBox(),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  ///<----- HELPER FOR _openBuilderForOpenContainer [HFOBFOC] -------------->///

  // [HFOBFOC] 0a :
  /// FIRST TEXT BUILDER FOR THE OPEN BUILDER SCREEN OF THE OPEN CONTAINER.
  Widget _textBuilder1(String text1, String text2) {
    return RichText(
      overflow: TextOverflow.visible,
      maxLines: 2,
      text: TextSpan(
        style: const TextStyle(fontSize: 20, color: Colors.black),
        children: <TextSpan>[
          TextSpan(
            text: text1,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          TextSpan(text: text2),
        ],
      ),
    );
  }

  // [HFOBFOC] 0b :
  /// SECOND TEXT BUILDER FOR THE OPEN BUILDER SCREEN OF THE OPEN CONTAINER.
  Widget _textBuilder2(String t1, String t2, String t3, String t4) {
    return RichText(
      overflow: TextOverflow.visible,
      maxLines: 3,
      text: TextSpan(
        style: const TextStyle(fontSize: 20, color: Colors.black),
        children: <TextSpan>[
          TextSpan(
            text: t1,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          TextSpan(text: t2),
          TextSpan(
            text: t3,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          TextSpan(text: t4),
        ],
      ),
    );
  }

  // [HFOBFOC] 0c :
  /// FULL CARD VIEW BUILDER FOR THE OPEN BUILDER SCREEN OF THE OPEN CONTAINER.
  Widget _cardBuilder(Widget widget) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Card(
        color: Colors.white,
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: EdgeInsets.fromLTRB(10, 5, 0, 5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Expanded(child: widget),
              const Icon(Icons.navigate_next, size: 40),
            ],
          ),
        ),
      ),
    );
  }

  // [HFOBFOC] 1 :
  /// PICKLIST REQUEST TYPE BUILDER FOR OPEN BUILDER IN OPEN CONTAINER.
  Widget _picklistRequestTypeMobileBuilder(Size size, int index) {
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            picklistChooser()[index].requestType + ' Picklist',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // [HFOBFOC] 2 :
  /// PICKLIST FULL TITLE BUILDER FOR THE OPEN BUILDER IN OPEN CONTAINER.
  Widget _picklistTitleMobileBuilder(Size size, int index) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              picklistChooser()[index].picklist,
              overflow: TextOverflow.visible,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.lightBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _processingBuilder(int i) {
    bool check1 = '-'.allMatches(picklistChooser()[i].picklist).length > 1;
    bool check2 = picklistChooser()[i].totalsku.isEmpty;
    return Visibility(
      visible: check1 && check2,
      child: _cardBuilder(_textBuilder1("Processing...", '')),
    );
  }

  // [HFOBFOC] 3 :
  /// LEFT TO BE PICKED BUILDER FOR OPEN BUILDER.
  Widget _leftToBePickedMobileBuilder(
      BuildContext ctx, Size size, int i, void Function(void Function()) fn) {
    return Visibility(
      visible: leftToBePickedMobileVisible(i),
      child: GestureDetector(
        onTap: () => moveToPicklistDetailsMobileHandling(false, i, ctx, fn),
        child: picklistChooser()[i].requestType == 'MSMQW'
            ? Column(
                children: [
                  Visibility(
                    visible: orderLeftToBePicked(i) > 0 &&
                        !(parseToInt(picklistChooser()[i].partialOrders) > 0),
                    child: _cardBuilder(
                      _textBuilder1(
                        '${orderLeftToBePicked(i)} ${orderLeftToBePicked(i) > 1 ? 'Orders' : 'Order'}',
                        ' Left to be Picked',
                      ),
                    ),
                  ),
                  Visibility(
                    visible:
                        parseToInt(picklistChooser()[i].partialOrders) > 0 &&
                            !(orderLeftToBePicked(i) > 0),
                    child: _cardBuilder(
                      _textBuilder1(
                        picklistChooser()[i].partialOrders +
                            ' ${parseToInt(picklistChooser()[i].partialOrders) > 1 ? 'Orders' : 'Order'}',
                        ' Partially Left to be Picked',
                      ),
                    ),
                  ),
                  Visibility(
                    visible:
                        parseToInt(picklistChooser()[i].partialOrders) > 0 &&
                            orderLeftToBePicked(i) > 0,
                    child: _cardBuilder(
                      _textBuilder2(
                        '${orderLeftToBePicked(i)} ${orderLeftToBePicked(i) > 1 ? 'Orders' : 'Order'}',
                        ' Left to be Picked & ',
                        picklistChooser()[i].partialOrders +
                            ' ${parseToInt(picklistChooser()[i].partialOrders) > 1 ? 'Orders' : 'Order'}',
                        ' Partially Left to be Picked',
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                children: [
                  Visibility(
                    visible: skuLeftToBePicked(i) > 0 &&
                        !(parseToInt(picklistChooser()[i].partialSkus) > 0),
                    child: _cardBuilder(
                      _textBuilder1(
                        '${skuLeftToBePicked(i)} ${skuLeftToBePicked(i) > 1 ? 'SKUs' : 'SKU'}',
                        ' Left to be Picked',
                      ),
                    ),
                  ),
                  Visibility(
                    visible: parseToInt(picklistChooser()[i].partialSkus) > 0 &&
                        !(skuLeftToBePicked(i) > 0),
                    child: _cardBuilder(
                      _textBuilder1(
                        picklistChooser()[i].partialSkus +
                            ' ${parseToInt(picklistChooser()[i].partialSkus) > 1 ? 'SKUs' : 'SKU'}',
                        ' Partially Left to be Picked',
                      ),
                    ),
                  ),
                  Visibility(
                    visible: parseToInt(picklistChooser()[i].partialSkus) > 0 &&
                        skuLeftToBePicked(i) > 0,
                    child: _cardBuilder(
                      _textBuilder2(
                        '${skuLeftToBePicked(i)} ${skuLeftToBePicked(i) > 1 ? 'SKUs' : 'SKU'}',
                        ' Left to be Picked & ',
                        picklistChooser()[i].partialSkus +
                            ' ${parseToInt(picklistChooser()[i].partialSkus) > 1 ? 'SKUs' : 'SKU'}',
                        ' Partially Left to be Picked',
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // [HFOBFOC] 4 :
  /// PICKED BUILDER FOR OPEN BUILDER.
  Widget _pickedMobileBuilder(
      BuildContext ctx, Size size, int i, void Function(void Function()) fn) {
    return Visibility(
      visible: pickedMobileVisible(i),
      child: GestureDetector(
        onTap: () => moveToPicklistDetailsMobileHandling(true, i, ctx, fn),
        child: picklistChooser()[i].requestType == 'MSMQW'
            ? Column(
                children: [
                  Visibility(
                    visible: orderPicked(i) > 0 &&
                        !(parseToInt(picklistChooser()[i].partialOrders) > 0),
                    child: _cardBuilder(
                      _textBuilder1(
                        '${orderPicked(i)} ${orderPicked(i) > 1 ? 'Orders' : 'Order'}',
                        ' Picked',
                      ),
                    ),
                  ),
                  Visibility(
                    visible: parseToInt(picklistChooser()[i].partialOrders) > 0 &&
                        !(orderPicked(i) > 0),
                    child: _cardBuilder(
                      _textBuilder1(
                        picklistChooser()[i].partialOrders +
                            ' ${parseToInt(picklistChooser()[i].partialOrders) > 1 ? 'Orders' : 'Order'}',
                        ' Partially Picked',
                      ),
                    ),
                  ),
                  Visibility(
                    visible: parseToInt(picklistChooser()[i].partialOrders) > 0 &&
                        orderPicked(i) > 0,
                    child: _cardBuilder(
                      _textBuilder2(
                        '${orderPicked(i)} ${orderPicked(i) > 1 ? 'Orders' : 'Order'}',
                        ' Picked & ',
                        picklistChooser()[i].partialOrders +
                            ' ${parseToInt(picklistChooser()[i].partialOrders) > 1 ? 'Orders' : 'Order'}',
                        ' Partially Picked',
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                children: [
                  Visibility(
                    visible: skuPicked(i) > 0 &&
                        !(parseToInt(picklistChooser()[i].partialSkus) > 0),
                    child: _cardBuilder(
                      _textBuilder1(
                        '${skuPicked(i)} ${skuPicked(i) > 1 ? 'SKUs' : 'SKU'}',
                        ' Picked',
                      ),
                    ),
                  ),
                  Visibility(
                    visible: parseToInt(picklistChooser()[i].partialSkus) > 0 &&
                        !(skuPicked(i) > 0),
                    child: _cardBuilder(
                      _textBuilder1(
                        picklistChooser()[i].partialSkus +
                            ' ${parseToInt(picklistChooser()[i].partialSkus) > 1 ? 'SKUs' : 'SKU'}',
                        ' Partially Picked',
                      ),
                    ),
                  ),
                  Visibility(
                    visible: parseToInt(picklistChooser()[i].partialSkus) > 0 &&
                        skuPicked(i) > 0,
                    child: _cardBuilder(
                      _textBuilder2(
                        '${skuPicked(i)} ${skuPicked(i) > 1 ? 'SKUs' : 'SKU'}',
                        ' Picked & ',
                        picklistChooser()[i].partialSkus +
                            ' ${parseToInt(picklistChooser()[i].partialSkus) > 1 ? 'SKUs' : 'SKU'}',
                        ' Partially Picked',
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // [HFOBFOC] 5 :
  /// SPLIT PICKLIST BY WAREHOUSE LOCATION OPTION FOR MOBILE BUILDER
  Widget _splitOnWlMobileBuilder(BuildContext ctx, int i) {
    return GestureDetector(
      onTap: () => moveToWlSplittingScreen(ctx, i),
      child: Visibility(
        visible: splitOnWarehouseLocationVisible(i),
        child: _cardBuilder(
          _textBuilder2(
            '',
            'Split on ',
            'Warehouse Location',
            ' & Allocate Picklist',
          ),
        ),
      ),
    );
  }

  // [HFOBFOC] 6 :
  /// SPLIT PICKLIST BY DISTRIBUTION CENTER OPTION FOR MOBILE BUILDER
  Widget _splitOnDcMobileBuilder(BuildContext ctx, int i) {
    return GestureDetector(
      onTap: () => moveToDcSplittingScreen(ctx, i),
      child: Visibility(
        visible: splitOnDistributionCenterVisible(i),
        child: _cardBuilder(
          _textBuilder2(
            '',
            'Split on ',
            'Distribution Center',
            ' & Allocate Picklist',
          ),
        ),
      ),
    );
  }

  // [HFOBFOC] 7 :
  /// SPLIT PICKLIST BY SHIPPING CLASS OPTION FOR MOBILE BUILDER
  Widget _splitOnScMobileBuilder(BuildContext ctx, int i) {
    return GestureDetector(
      onTap: () => moveToScSplittingScreen(ctx, i),
      child: Visibility(
        visible: splitOnShippingClassVisible(i),
        child: _cardBuilder(
          _textBuilder2(
            '',
            'Split on ',
            'Shipping Class',
            ' & Allocate Picklist',
          ),
        ),
      ),
    );
  }

  // [HFOBFOC] 8 :
  /// VALIDATE ALL SKUS/ORDER IN PICKLIST BUTTON FOR MOBILE BUILDER
  Widget _validatePicklistMobileBuilder(BuildContext ctx, Size size, int i) {
    return Visibility(
      visible: validatePicklistVisible(i),
      child: Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Column(
          children: [
            Divider(),
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: SizedBox(
                height: 45,
                width: size.width * .9,
                child: ElevatedButton(
                  onPressed: picklistValidatedOrNot(i)
                      ? null
                      : () => validatePicklistMobileHandling(ctx, i),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      picklistValidatedOrNot(i)
                          ? picklistValidationText(i)
                          : 'Validate Picklist',
                      style: TextStyle(fontSize: 18, color: Colors.white),
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

  ///<----- END ----------------------------------- [HFOBFOC] -------------->///

  // [HFNTDBMA] 2 :
  /// THE VIEW OF THE MAIN PICKLIST SCREEN WHEN THE OPEN CONTAINER IS OPENED.
  Widget _openBuilderForOpenContainer(Size s, int i, double p, BuildContext c) {
    return StatefulBuilder(builder: (context, setSB) {
      return Container(
        height: s.height,
        width: s.width,
        color: Colors.white,
        child: Padding(
          padding: EdgeInsets.all(s.width * .025),
          child: Padding(
            padding: EdgeInsets.only(top: p),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                border: Border.all(color: Colors.grey, width: 1),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: s.width * .025),
                child: Column(
                  children: [
                    _picklistRequestTypeMobileBuilder(s, i),
                    _picklistTitleMobileBuilder(s, i),
                    isOpenedLoading
                        ? Expanded(child: loader())
                        : SingleChildScrollView(
                            child: Column(
                              children: [
                                _processingBuilder(i),
                                _leftToBePickedMobileBuilder(c, s, i, setSB),
                                _pickedMobileBuilder(c, s, i, setSB),
                                _splitOnWlMobileBuilder(c, i),
                                _splitOnDcMobileBuilder(c, i),
                                _splitOnScMobileBuilder(c, i),
                                _validatePicklistMobileBuilder(c, s, i),
                              ],
                            ),
                          ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    });
  }

  ///<----- END ----------------------------------------- [HFNTDBMA] ------->///

  // [MBHM] 5a :
  /// NEW DESIGN STARTED ON 22 AUGUST, 2023.
  /// NEW TABLE DATA BUILDER FOR MOBILE APP WITH OPEN CONTAINER IMPLEMENTATION
  /// AND SHOWING FOLLOWING DATA ONLY IN THE MAIN SCREEN I.E. CLOSED BUILDER
  /// FROM OPEN CONTAINER
  /// 1. Picklist title
  /// 2. Picklist creation time
  /// 3. Picklist Status
  /// 4. Picklist Type
  /// 5. Lock Icon on the whole picklist if some user is already working.
  Widget _newTableDataBuilderMobileApp(Size s, double padding, BuildContext c) {
    return Expanded(
      child: isPicklistVisible == false || shiftLoading == true
          ? loader()
          : pickLists.isEmpty
              ? _noPicklistToShowBuilder(s.width * .045)
              : ListView.builder(
                  itemCount: picklistChooser().length,
                  itemBuilder: (BuildContext context, int idx) {
                    List<MsgX> l = listOfLockedPicklists.map((e) => e).toList();
                    String batch = picklistChooser()[idx].batchId;
                    int i = l.indexWhere((e) => e.batchId == batch);
                    bool chk1 = l.isNotEmpty;
                    bool chk2 = l.any((e) => e.batchId == batch);
                    bool temp = chk2 ? l[i].userName != widget.userName : false;
                    bool chk3 = i == -1 ? false : temp;
                    return OpenContainer(
                      tappable: !(chk1 && chk2 && chk3),
                      transitionDuration: const Duration(milliseconds: 800),
                      transitionType: _transitionType,
                      middleColor: Colors.grey.shade200,
                      closedElevation: 0,
                      closedShape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero),
                      closedBuilder: (ctx, _) =>
                          _closedBuilderForOpenContainer(s, idx),
                      openBuilder: (ctx, _) =>
                          _openBuilderForOpenContainer(s, idx, padding, c),
                    );
                  }),
    );
  }

  // [MBHM] 5b :
  /// PICKLIST TABLE DATA BUILDER FOR MOBILE APP WITH OLD DESIGN, WHICH WILL
  /// SHOW ALL THE PICKLIST DATA, PICKLIST TYPE AND VALIDATE PICKLIST BUTTON IN
  /// EACH ROW RESPECTIVELY
  // ignore: unused_element
  Widget _oldTableDataBuilderMobileApp(Size size) {
    return SizedBox(
        height: pickLists.length > 10 ? size.height * .61 : size.height * .64,
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
                            foregroundDecoration:
                                outerContainerDecoration(index),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      height: heightCheckerForMobile(index),
                                      width: size.width * .7,
                                      alignment: Alignment.center,
                                      decoration: innerContainer1(index),
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
                                              padding: const EdgeInsets.only(
                                                  top: 5, left: 10),
                                              child: Text(
                                                picklistChooser()[index]
                                                    .picklist,
                                                style: const TextStyle(
                                                  fontSize: 17,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.lightBlue,
                                                ),
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.only(
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
                                            padding: const EdgeInsets.only(
                                                top: 5, left: 10),
                                            child: Row(
                                              children: [
                                                const Text(
                                                  'Status : ',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                Text(
                                                  picklistChooser()[index]
                                                              .status
                                                              .isEmpty &&
                                                          picklistChooser()[
                                                                      index]
                                                                  .picklist
                                                                  .substring(
                                                                      0, 4) ==
                                                              'Shop'
                                                      ? 'Processing...'
                                                      : picklistChooser()[index]
                                                          .status,
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                    color:
                                                        colorChooserForStatus(
                                                            index: index),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Visibility(
                                            visible: picklistChooser()[index]
                                                    .status
                                                    .contains('In Progress') ||
                                                picklistChooser()[index]
                                                    .status
                                                    .contains('Not Started'),
                                            child: GestureDetector(
                                              onTap: () {
                                                moveToPicklistDetailsOrAllocationScreenWeb(
                                                  index: index,
                                                  showPickedOrders: false,
                                                );
                                              },
                                              child: Padding(
                                                padding: const EdgeInsets.only(
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
                                                        style: const TextStyle(
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                    Visibility(
                                                      visible:
                                                          leftOrderOrSkuVisible(
                                                              index),
                                                      child: const Text(
                                                        'Left to be Picked',
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                    ),
                                                    Visibility(
                                                      visible:
                                                          leftOrderOrSkuVisible(
                                                                  index) &&
                                                              leftPartialOrderOrSkuVisible(
                                                                  index),
                                                      child: const Text(
                                                        ' & ',
                                                        style: TextStyle(
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
                                                        style: const TextStyle(
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                    Visibility(
                                                      visible:
                                                          leftPartialOrderOrSkuVisible(
                                                              index),
                                                      child: const Text(
                                                        'Partially Left to be Picked',
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                    ),
                                                    Visibility(
                                                      visible:
                                                          leftOrderOrSkuVisible(
                                                                  index) ||
                                                              leftPartialOrderOrSkuVisible(
                                                                  index),
                                                      child: const Icon(
                                                        Icons.navigate_next,
                                                        size: 20,
                                                      ),
                                                    )
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                          Visibility(
                                            visible: (picklistChooser()[index]
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
                                              visible: picklistChooser()[index]
                                                      .status
                                                      .contains('Complete') ||
                                                  picklistChooser()[index]
                                                      .status
                                                      .contains(
                                                          'In Progress') ||
                                                  picklistChooser()[index]
                                                      .status
                                                      .contains('Not Started'),
                                              child: GestureDetector(
                                                onTap: () async {
                                                  moveToPicklistDetailsOrAllocationScreenWeb(
                                                    index: index,
                                                    showPickedOrders: true,
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
                                                            validatedOrderOrSkuVisible(
                                                                index),
                                                        child: Text(
                                                          picklistChooser()[
                                                                          index]
                                                                      .requestType ==
                                                                  'MSMQW'
                                                              ? '${parseToInt(picklistChooser()[index].pickedorder) - parseToInt(picklistChooser()[index].partialOrders)} ${parseToInt(picklistChooser()[index].pickedorder) - parseToInt(picklistChooser()[index].partialOrders) > 1 ? 'Orders' : 'Order'} '
                                                              : '${parseToInt(picklistChooser()[index].pickedsku) - parseToInt(picklistChooser()[index].partialSkus)} ${parseToInt(picklistChooser()[index].pickedsku) - parseToInt(picklistChooser()[index].partialSkus) > 1 ? 'SKUs' : 'SKU'} ',
                                                          style:
                                                              const TextStyle(
                                                            fontSize: 14,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                      ),
                                                      Visibility(
                                                        visible:
                                                            validatedOrderOrSkuVisible(
                                                                index),
                                                        child: const Text(
                                                          'Picked',
                                                          style: TextStyle(
                                                            fontSize: 14,
                                                          ),
                                                        ),
                                                      ),
                                                      Visibility(
                                                        visible:
                                                            validatedOrderOrSkuVisible(
                                                                    index) &&
                                                                validatedPartialOrderOrSkuVisible(
                                                                    index),
                                                        child: const Text(
                                                          ' & ',
                                                          style: TextStyle(
                                                            fontSize: 14,
                                                          ),
                                                        ),
                                                      ),
                                                      Visibility(
                                                        visible:
                                                            validatedPartialOrderOrSkuVisible(
                                                                index),
                                                        child: Text(
                                                          picklistChooser()[
                                                                          index]
                                                                      .requestType ==
                                                                  'MSMQW'
                                                              ? '${picklistChooser()[index].partialOrders} ${parseToInt(picklistChooser()[index].partialOrders) > 1 ? 'Orders' : 'Order'} '
                                                              : '${picklistChooser()[index].partialSkus} ${parseToInt(picklistChooser()[index].partialSkus) > 1 ? 'SKUs' : 'SKU'} ',
                                                          style:
                                                              const TextStyle(
                                                            fontSize: 14,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                      ),
                                                      Visibility(
                                                        visible:
                                                            validatedPartialOrderOrSkuVisible(
                                                                index),
                                                        child: const Text(
                                                          'Partially Picked',
                                                          style: TextStyle(
                                                            fontSize: 14,
                                                          ),
                                                        ),
                                                      ),
                                                      const Icon(
                                                        Icons.navigate_next,
                                                        size: 20,
                                                      )
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          Visibility(
                                            visible:
                                                splitOnWarehouseLocationVisible(
                                                    index),
                                            child: MouseRegion(
                                              cursor: mouseCursorForWeb(
                                                index: index,
                                              ),
                                              child: GestureDetector(
                                                onTap: () async {
                                                  bool result =
                                                      await NavigationMethods
                                                          .pushWithResult(
                                                    context,
                                                    PicklistWlSplittingScreen(
                                                      batchId:
                                                          picklistChooser()[
                                                                  index]
                                                              .batchId,
                                                      appBarName:
                                                          '${picklistChooser()[index].picklist} (${picklistChooser()[index].requestType}) Split on WL',
                                                      picklist:
                                                          picklistChooser()[
                                                                  index]
                                                              .picklist,
                                                      status: picklistChooser()[
                                                              index]
                                                          .status,
                                                      showPickedOrders: false,
                                                      totalQty:
                                                          '${parseToInt(picklistChooser()[index].totalsku) - parseToInt(picklistChooser()[index].pickedsku)}',
                                                      picklistLength:
                                                          pickListCount,
                                                    ),
                                                  );
                                                  if (result == true) {
                                                    if (!mounted) return;
                                                    ToastUtils
                                                        .motionToastCentered1500MS(
                                                            message:
                                                                'Processing New Picklists....',
                                                            context: context);
                                                    await Future.delayed(
                                                        const Duration(
                                                            seconds: 2), () {
                                                      pickListApis();
                                                    });
                                                  }
                                                },
                                                child: const Padding(
                                                  padding: EdgeInsets.only(
                                                      top: 5, left: 10),
                                                  child: Row(
                                                    children: [
                                                      Text(
                                                        'Split on Warehouse Location and Allocate Picklist',
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      Icon(
                                                        Icons.navigate_next,
                                                        size: 20,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          Visibility(
                                            visible:
                                                splitOnDistributionCenterVisible(
                                                    index),
                                            child: MouseRegion(
                                              cursor: mouseCursorForWeb(
                                                index: index,
                                              ),
                                              child: GestureDetector(
                                                onTap: () async {
                                                  bool result =
                                                      await NavigationMethods
                                                          .pushWithResult(
                                                    context,
                                                    PicklistDCSplittingScreen(
                                                      batchId:
                                                          picklistChooser()[
                                                                  index]
                                                              .batchId,
                                                      appBarName:
                                                          '${picklistChooser()[index].picklist} (${picklistChooser()[index].requestType}) Split on DC',
                                                      picklist:
                                                          picklistChooser()[
                                                                  index]
                                                              .picklist,
                                                      status: picklistChooser()[
                                                              index]
                                                          .status,
                                                      picklistLength:
                                                          pickListCount,
                                                      totalOrders:
                                                          picklistChooser()[
                                                                  index]
                                                              .totalorder,
                                                    ),
                                                  );
                                                  if (result == true) {
                                                    if (!mounted) return;
                                                    ToastUtils
                                                        .motionToastCentered1500MS(
                                                            message:
                                                                'Processing New Picklists....',
                                                            context: context);
                                                    await Future.delayed(
                                                        const Duration(
                                                            seconds: 2), () {
                                                      pickListApis();
                                                    });
                                                  }
                                                },
                                                child: const Padding(
                                                  padding: EdgeInsets.only(
                                                      top: 5, left: 10),
                                                  child: Row(
                                                    children: [
                                                      Text(
                                                        'Split on Distribution Center and Allocate Picklist*/',
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      Icon(
                                                        Icons.navigate_next,
                                                        size: 20,
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
                                    Container(
                                      height: heightCheckerForMobile(index),
                                      width: size.width * .25,
                                      alignment: Alignment.center,
                                      decoration: innerContainer2(index),
                                      child: Center(
                                        child: Text(
                                          picklistChooser()[index].requestType,
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
                                      decoration: innerContainer2(index),
                                      child: Visibility(
                                        visible: picklistChooser()[index]
                                                .status
                                                .isNotEmpty &&
                                            picklistChooser()[index]
                                                    .picklist
                                                    .substring(0, 4) !=
                                                'Shop',
                                        child: Center(
                                          child:
                                              picklistChooser()[index].status ==
                                                          'Complete' ||
                                                      picklistChooser()[index]
                                                              .status ==
                                                          'Processing...' ||
                                                      picklistChooser()[index]
                                                          .status
                                                          .contains(
                                                              'No EAN found!')
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
                                                                      'Processing...'
                                                                  ? 'Processing...'
                                                                  : 'No EAN found!',
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
                                                          listOfLockedPicklists
                                                                  .isNotEmpty
                                                              ? listOfLockedPicklists
                                                                      .map((e) => e
                                                                          .batchId)
                                                                      .toList()
                                                                      .contains(
                                                                          picklistChooser()[index]
                                                                              .batchId)
                                                                  ? listOfLockedPicklists[listOfLockedPicklists.indexWhere((e) => e.batchId == picklistChooser()[index].batchId)]
                                                                              .userName ==
                                                                          widget
                                                                              .userName
                                                                      ? validateAllPicklist(
                                                                          index)
                                                                      : ToastUtils.showCenteredLongToast(
                                                                          message:
                                                                              '${picklistChooser()[index].picklist} Locked as another user is working on this picklist.')
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
                        }));
  }

  ///<------ END -------------------------------- [MBHM] ------------------->///

  // MOBILE BUILDER WIDGET FOR MOBILE APP SCREEN BODY BUILDER
  Widget _mobileBuilder(BuildContext context, Size size, double viewPadding) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: size.width * .025),
      child: Column(
        children: [
          _createNewPicklistButtonMobileBuilder(size),
          _statusAndCountFilterMobileBuilder(context, size),
          _prevCountNextBuilderMobileApp(size),
          _tableTitleRowBuilderMobileApp(size),
          _newTableDataBuilderMobileApp(size, viewPadding, context),
        ],
      ),
    );
  }

  /// <--------------------------------------- END --------------------------------------- BUILD METHOD HELPER METHODS ------------------------------------------------------------> ///

  // BUILD METHOD HELPER METHODS PROPER COMMENTED
  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final double viewPadding = MediaQuery.of(context).viewPadding.top;
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      appBar: _picklistMainScreenAppBar(size),
      body: kIsWeb == true
          ? _webBuilder(context, size)
          : _mobileBuilder(context, size, viewPadding),
    );
  }

  /// <--------------------------------- START ----------------------------------------- COMMON WIDGETS FOR BOTH WEB APP AND MOBILE APP ------------------------------------------> ///

  /// OUTER CONTAINER DECORATION HANDLING
  Decoration? outerContainerDecoration(int index) {
    return listOfLockedPicklists.isNotEmpty
        ? listOfLockedPicklists
                .map((e) => e.batchId)
                .toList()
                .contains(picklistChooser()[index].batchId)
            ? listOfLockedPicklists[listOfLockedPicklists.indexWhere((e) =>
                            e.batchId == picklistChooser()[index].batchId)]
                        .userName ==
                    widget.userName
                ? null
                : const BoxDecoration(
                    color: Colors.grey,
                    backgroundBlendMode: BlendMode.saturation,
                  )
            : null
        : null;
  }

  /// INNER CONTAINER 1 DECORATION HANDLING : CONTAINING PICKLIST DETAILS
  Decoration? innerContainer1(int index) {
    return BoxDecoration(
      border: Border(right: _side, left: _side, bottom: _side),
      color: Colors.grey.shade200,
    );
  }

  /// INNER CONTAINER 2 DECORATION HANDLING : CONTAINING PICKLIST TYPE (FOR BOTH
  /// WEB AND MOBILE APP) AND VALIDATING PICKLIST BUTTON (FOR WEB APP)
  Decoration? innerContainer2(int index) {
    return BoxDecoration(
      border: Border(right: _side, bottom: _side),
      color: Colors.grey.shade200,
    );
  }

  /// HANDLES VISIBILITY OF SPLIT ON WAREHOUSE LOCATION AND ALLOCATE PICKLIST
  /// BUTTON (FOR BOTH WEB AND MOBILE APP)
  bool splitOnWarehouseLocationVisible(int index) {
    return picklistChooser()[index].requestType == 'SIW' ||
            picklistChooser()[index].requestType == 'SSMQW'
        ? picklistChooser()[index].status == 'Not Started' ||
                picklistChooser()[index].status == 'In Progress'
            ? picklistChooser()[index].totalsku != ''
                ? parseToInt(picklistChooser()[index].totalWarehouseLocation) >
                        1
                    ? true
                    : false
                : false
            : false
        : false;
  }

  /// HANDLES VISIBILITY OF SPLIT ON DISTRIBUTION CENTER AND ALLOCATE PICKLIST
  /// BUTTON (FOR BOTH WEB AND MOBILE APP)
  bool splitOnDistributionCenterVisible(int index) {
    return picklistChooser()[index].requestType == 'SIW' ||
            picklistChooser()[index].requestType == 'SSMQW'
        ? picklistChooser()[index].status == 'Not Started' ||
                picklistChooser()[index].status == 'In Progress'
            ? picklistChooser()[index].totalsku != ''
                ? parseToInt(picklistChooser()[index].totalDC) > 1
                    ? widget.isDCSplitAutomatic
                        ? false
                        : true
                    : false
                : false
            : false
        : false;
  }

  /// HANDLES VISIBILITY OF SPLIT ON SHIPPING CLASS AND ALLOCATE PICKLIST
  /// BUTTON (FOR BOTH WEB AND MOBILE APP)
  bool splitOnShippingClassVisible(int index) {
    return picklistChooser()[index].requestType == 'SIW' ||
            picklistChooser()[index].requestType == 'SSMQW'
        ? picklistChooser()[index].status == 'Not Started' ||
                picklistChooser()[index].status == 'In Progress'
            ? picklistChooser()[index].totalsku != ''
                ? parseToInt(picklistChooser()[index].totalSC) > 1
                    ? true
                    : false
                : false
            : false
        : false;
  }

  bool validatePicklistVisible(int i) {
    bool check1 = picklistChooser()[i].status.isNotEmpty;
    bool check2 = picklistChooser()[i].picklist.substring(0, 4) != 'Shop';
    bool check3 = picklistChooser()[i].totalsku.isNotEmpty;
    return check1 && check2 && check3;
  }

  bool picklistValidatedOrNot(int i) {
    bool check1 = picklistChooser()[i].status == 'Complete';
    bool check2 = picklistChooser()[i].status == 'Processing...';
    bool check3 = picklistChooser()[i].status == 'No EAN found!';
    bool check4 = picklistChooser()[i].status.isEmpty;
    return check1 || check2 || check3 || check4;
  }

  String picklistValidationText(int i) {
    return picklistChooser()[i].status == 'Complete'
        ? 'Picklist Validated'
        : picklistChooser()[i].status == 'Processing...'
            ? 'Picklist Processing...'
            : 'No EAN found!';
  }

  /// NO PICKLIST RECEIVED FROM API CASE BUILDER
  Widget _noPicklistToShowBuilder(double font) {
    return Center(
      child: Text('No PickList to show', style: TextStyle(fontSize: font)),
    );
  }

  /// DROPDOWN ITEMS MAKER FOR DROPDOWNS WITH LIST OF STRING DATA.
  List<DropdownMenuItem<String>> stringDropdownItems(List<String> items) {
    return items.map(
      (item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item, style: const TextStyle(fontSize: 18)),
        );
      },
    ).toList();
  }

  /// DROPDOWN ITEMS MAKER FOR DROPDOWNS WITH LIST OF INT DATA.
  List<DropdownMenuItem<int>> integerDropdownItems(List<int> items, double ft) {
    return items.map(
      (item) {
        return DropdownMenuItem<int>(
            value: item, child: Text('$item', style: TextStyle(fontSize: ft)));
      },
    ).toList();
  }

  /// BUTTON STYLE DATA FOR DROPDOWNS MADE USING THE DROPDOWN2 LIBRARY.
  ButtonStyleData buttonStyleDropdowns(double height, double width) {
    return ButtonStyleData(
      height: height,
      width: width,
      padding: const EdgeInsets.only(left: 14, right: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black26),
        color: Colors.white,
      ),
    );
  }

  /// DROPDOWN STYLE DATA FOR DROPDOWNS MADE USING THE DROPDOWN2 LIBRARY.
  DropdownStyleData dropdownStyle(double width) {
    return DropdownStyleData(
      maxHeight: 250,
      width: width,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(14)),
      scrollbarTheme: ScrollbarThemeData(
        radius: const Radius.circular(40),
        thickness: MaterialStateProperty.all<double>(6),
        thumbVisibility: MaterialStateProperty.all<bool>(true),
      ),
    );
  }

  /// SKU LEFT TO BE PICKED CALCULATOR.
  int skuLeftToBePicked(int i) {
    return parseToInt(picklistChooser()[i].totalsku) -
        parseToInt(picklistChooser()[i].pickedsku);
  }

  /// ORDER LEFT TO BE PICKED CALCULATOR
  int orderLeftToBePicked(int i) {
    return parseToInt(picklistChooser()[i].totalorder) -
        parseToInt(picklistChooser()[i].pickedorder);
  }

  int skuPicked(int i) {
    return parseToInt(picklistChooser()[i].pickedsku) -
        parseToInt(picklistChooser()[i].partialSkus);
  }

  int orderPicked(int i) {
    return parseToInt(picklistChooser()[i].pickedorder) -
        parseToInt(picklistChooser()[i].partialOrders);
  }

  /// <----------------------------------- END ----------------------------------------- COMMON WIDGETS FOR BOTH WEB APP AND MOBILE APP ------------------------------------------> ///

  /// <---------------------------------- START --------------------------------------- API HANDLING HELPER METHODS --------------------------------------------------------------> ///

  /*----- ON-TAP METHOD HANDLERS --- (COMMON TO BOTH MOBILE AND WEB APP) -----*/

  /// CREATE NEW PICKLIST METHOD FOR HANDLING ALL CASES FOR PICKLIST CREATION
  void createNewPicklistMethod(BuildContext context) async {
    switch (pickLists[0].status) {
      case 'Processing...':
        {
          await Future.delayed(const Duration(seconds: 1), () async {
            commonToastCentered(
              msg: 'Picklist already running! Please wait and try again later',
              context: context,
            );
            await Future.delayed(const Duration(seconds: 1), () {
              createController.reset();
            });
          });
        }
        break;
      case 'No EAN found!':
        {
          Navigator.pop(context);
          commonToastCentered(msg: 'Processing..', context: context);
          await Future.delayed(const Duration(milliseconds: 100), () {
            pickListApis();
          }).whenComplete(() => defaultCreateNewPicklist());
        }
        break;
      default:
        defaultCreateNewPicklist();
    }
  }

  void defaultCreateNewPicklist() async {
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
    log('VALUE OF PICK DB >>---> $pickDB');
    int tempIndex = pickDB.indexOf('-') + 1;
    int picklistNo = parseToInt(pickDB.substring(tempIndex, pickDB.length)) + 1;
    await createNewPicklist(type: selectedPicklist).whenComplete(() async {
      switch (isPicklistSuccessful) {
        case false:
          {
            await Future.delayed(const Duration(milliseconds: 300), () {
              createController.reset();
            });
          }
          break;
        default:
          {
            await Future.delayed(const Duration(milliseconds: 300), () async {
              createController.reset();
              Navigator.pop(context);
              setState(() {
                isCreatingPicklist = true;
                pendingPickListNo = picklistNo;
                pendingPicklistRequestType = selectedPicklist;
                isPicklistVisible = false;
              });
              await savePicklistData(
                picklist: 'Picklist-$picklistNo',
                length: pickListCount + 1,
                pendingPicklistNo: picklistNo,
                pendingPicklistRequestType: selectedPicklist,
              ).whenComplete(() => pickListApis());
            });
          }
      }
    });
  }

  /// THE ACTION DONE WHEN THE PICKLIST TYPE IS CHANGED BY SELECTING FROM THE
  /// LIST OF TYPES FROM DROPDOWN FOR PICKLIST CREATION.
  void onPicklistTypeChange(void Function(void Function()) fn, String value) {
    fn(() {
      selectedPicklist = value;
    });
    log('V selectedPicklist >>---> $selectedPicklist');
  }

  /// THE ACTION DONE WHEN THE CANCEL BUTTON IS TAPPED IN THE CREATE PICKLIST
  /// POP UP WINDOW.
  void onCancelButtonTapped(BuildContext ctx) async {
    await Future.delayed(const Duration(milliseconds: 300), () {
      cancelController.reset();
      Navigator.pop(ctx);
    });
  }

  /// THE ACTION DONE WHEN THE PICKLIST STATUS FILTER IS USED AND A STATUS VALUE
  /// FROM THE DROPDOWN IS CHOSEN
  void onPicklistStatusChanged(String value) async {
    setState(() {
      selectedStatusToFilter = value;
    });
    log('V selectedStatusToFilter >>---> $selectedStatusToFilter');
    await Future.delayed(const Duration(milliseconds: 100), () {
      setState(() {
        selectedNoToShow = 5;
        startIndex = 0;
        endIndex = 4;
        previousColor = Colors.grey;
        nextColor = Colors.blue;
      });
      pickListApis();
    });
  }

  /// THE ACTION DONE WHEN THE NO. OF PICKLIST TO SHOW IN THE PAGINATED PICKLIST
  /// IS CHANGED
  void onCountOfPicklistChanged(int value) async {
    setState(() {
      shiftLoading = true;
      selectedNoToShow = value;
    });
    log('V selectedNoToShow >>---> $selectedNoToShow');
    await Future.delayed(const Duration(milliseconds: 100), () {
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
  }

  /// THE ACTION DONE WHEN PREVIOUS BUTTON IS TAPPED
  void onTapPrevButton() async {
    setState(() {
      shiftLoading = (startIndex == 0) ? false : true;
    });
    await Future.delayed(const Duration(milliseconds: 300), () {
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
              endIndex -= (pickLists.length % selectedNoToShow);
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
    });
  }

  /// THE ACTION DONE WHEN NEXT BUTTON IS TAPPED
  void onTapNextButton() async {
    setState(() {
      shiftLoading = (endIndex == pickLists.length - 1) ? false : true;
    });
    await Future.delayed(const Duration(milliseconds: 300), () {
      setState(() {
        previousColor = Colors.blue;
      });
      if (pickLists.length - endIndex > selectedNoToShow + 1) {
        setState(() {
          startIndex += selectedNoToShow;
          endIndex += selectedNoToShow;
        });
        paginatedPickList = [];
        paginatedPickList.addAll(pickLists.where((e) =>
            pickLists.indexOf(e) <= endIndex &&
            pickLists.indexOf(e) >= startIndex));
      } else {
        if (pickLists.length - startIndex > selectedNoToShow) {
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
    });
  }

  /*-------- END ------------ ON-TAP METHOD HANDLERS ------------------------ */

  /// <--------------------------------- END ------------------------------------------ API HANDLING HELPER METHODS --------------------------------------------------------------> ///

  /// <-------------------------------- START ----------------------------------------- API METHODS ------------------------------------------------------------------------------> ///

  /// <--------------------------------- END ------------------------------------------ API METHODS ------------------------------------------------------------------------------> ///

  void validateAllPicklist(int index) async {
    await getPickListDetails(
      batchId: picklistChooser()[index].batchId,
      showPickedOrders: false,
    ).whenComplete(() async {
      await validateAllSKUinPicklist(picklistChooser()[index].batchId,
          context, picklistChooser()[index].picklist);
    }).whenComplete(() => pickListApis());
  }

  void moveToPicklistDetailsOrAllocationScreenWeb({
    required bool showPickedOrders,
    required int index,
  }) async {
    await getSavedLockedPicklistData()
        .whenComplete(() => deleteOlderLockedPicklists())
        .whenComplete(() {
      if (listOfLockedPicklists.isNotEmpty) {
        if (listOfLockedPicklists
            .map((e) => e.batchId)
            .toList()
            .contains(picklistChooser()[index].batchId)) {
          if (listOfLockedPicklists[listOfLockedPicklists.indexWhere(
                      (e) => e.batchId == picklistChooser()[index].batchId)]
                  .userName !=
              widget.userName) {
            ToastUtils.motionToastCentered1500MS(
                message: '${picklistChooser()[index].picklist}' + kLock,
                context: context);
            pickListApis();
          } else {
            moveToPicklistDetailsWeb(showPickedOrders, index);
          }
        } else {
          moveToPicklistDetailsWeb(showPickedOrders, index);
        }
      } else {
        moveToPicklistDetailsWeb(showPickedOrders, index);
      }
    });
  }

  void moveToPicklistDetailsWeb(bool showPickedOrders, int i) async {
    String title = picklistChooser()[i].picklist;
    String type = picklistChooser()[i].requestType;
    String batch = picklistChooser()[i].batchId;
    int totalSKU = parseToInt(picklistChooser()[i].totalsku);
    await saveLockingData(widget.userName, batch).whenComplete(() async {
      await NavigationMethods.push(
        context,
        PickListDetails(
          batchId: picklistChooser()[i].batchId,
          requestType: type,
          appBarName: '$title ($type)',
          isSKUAvailable: totalSKU > 0 ? true : false,
          status: picklistChooser()[i].status,
          isStatusComplete: picklistChooser()[i].status == 'Complete',
          orderPicked: picklistChooser()[i].pickedorder,
          partialOrders: picklistChooser()[i].partialOrders,
          totalOrders: picklistChooser()[i].totalorder,
          accType: widget.accType,
          authorization: widget.authorization,
          refreshToken: widget.refreshToken,
          profileId: widget.profileId,
          distCenterName: widget.distCenterName,
          distCenterId: widget.distCenterId,
          showPickedOrders: showPickedOrders,
        ),
      ).whenComplete(() => pickListApis());
    });
  }

  ///******************** Changes for Mobile app ****************************///

  /// saved LockedPicklistDataCheck
  Future<void> checkSavedLockedPicklist() async {
    await getSavedLockedPicklistData()
        .whenComplete(() => deleteOlderLockedPicklists());
  }

  /// new MoveToPicklist Details method for mobile (Optimized) - 29/08/23
  Future<void> moveToPicklistDetails(bool show, int i, BuildContext ctx) async {
    await checkSavedLockedPicklist().whenComplete(() async {
      String batch = picklistChooser()[i].batchId;
      String title = picklistChooser()[i].picklist;
      String type = picklistChooser()[i].requestType;
      String u = widget.userName;
      int totalSKU = parseToInt(picklistChooser()[i].totalsku);
      String msg = title.length > 30 ? title.substring(0, 24) + '....' : title;
      int idx = listOfLockedPicklists.indexWhere((e) => e.batchId == batch);
      bool chk1 = listOfLockedPicklists.isNotEmpty;
      bool chk2 = listOfLockedPicklists.any((e) => e.batchId == batch);
      bool tempCheck = chk2 ? listOfLockedPicklists[idx].userName != u : false;
      bool chk3 = idx == -1 ? false : tempCheck;
      if (chk1 && chk2 && chk3) {
        Navigator.pop(ctx);
        await Future.delayed(const Duration(seconds: 1), () {
          commonToastCentered(msg: msg + kLock, context: ctx);
          pickListApis();
        }).whenComplete(() {
          setState(() {
            isOpenedLoading = false;
          });
        });
      } else {
        await saveLockingData(widget.userName, batch).whenComplete(() async {
          await NavigationMethods.push(
            ctx,
            PickListDetails(
              batchId: picklistChooser()[i].batchId,
              requestType: type,
              appBarName: '$title ($type)',
              isSKUAvailable: totalSKU > 0 ? true : false,
              status: picklistChooser()[i].status,
              isStatusComplete: picklistChooser()[i].status == 'Complete',
              orderPicked: picklistChooser()[i].pickedorder,
              partialOrders: picklistChooser()[i].partialOrders,
              totalOrders: picklistChooser()[i].totalorder,
              accType: widget.accType,
              authorization: widget.authorization,
              refreshToken: widget.refreshToken,
              profileId: widget.profileId,
              distCenterName: widget.distCenterName,
              distCenterId: widget.distCenterId,
              showPickedOrders: show,
            ),
          ).whenComplete(() => pickListApis()).whenComplete(() {
            setState(() {
              isOpenedLoading = false;
            });
          });
        });
      }
    });
  }

  void moveToPicklistDetailsMobileHandling(
      bool chk, int i, BuildContext c, void Function(void Function()) f) async {
    f(() {
      isOpenedLoading = true;
    });
    await moveToPicklistDetails(chk, i, c).whenComplete(() {
      f(() {
        isOpenedLoading = false;
      });
    });
  }

  void moveToWlSplittingScreen(BuildContext c, int i) async {
    String batch = picklistChooser()[i].batchId;
    String title = picklistChooser()[i].picklist;
    String type = picklistChooser()[i].requestType;
    int totalSKU = parseToInt(picklistChooser()[i].totalsku);
    int pickedSKU = parseToInt(picklistChooser()[i].pickedsku);
    String finalSKUCount = '${totalSKU - pickedSKU}';
    String u = widget.userName;
    String msg = title.length > 30 ? title.substring(0, 24) + '....' : title;
    int idx = listOfLockedPicklists.indexWhere((e) => e.batchId == batch);
    bool chk1 = listOfLockedPicklists.isNotEmpty;
    bool chk2 = listOfLockedPicklists.any((e) => e.batchId == batch);
    bool tempCheck = chk2 ? listOfLockedPicklists[idx].userName != u : false;
    bool chk3 = idx == -1 ? false : tempCheck;
    if (chk1 && chk2 && chk3) {
      Navigator.pop(c);
      await Future.delayed(const Duration(seconds: 1), () {
        commonToastCentered(msg: msg + kLock, context: c);
        pickListApis();
      });
    } else {
      await saveLockingData(widget.userName, batch).whenComplete(() async {
        bool result = await NavigationMethods.pushRepWithResult(
          c,
          PicklistWlSplittingScreenWeb(
            batchId: picklistChooser()[i].batchId,
            appBarName: '$title ($type) Split on WL',
            picklist: picklistChooser()[i].picklist,
            status: picklistChooser()[i].status,
            showPickedOrders: false,
            totalQty: finalSKUCount,
            picklistLength: pickListCount,
          ),
        );
        if (result == true) {
          commonToastCentered(msg: 'Processing New Picklists....', context: c);
          await Future.delayed(const Duration(seconds: 2), () {
            pickListApis();
          });
        }
      });
    }
  }

  void moveToDcSplittingScreen(BuildContext c, int i) async {
    String batch = picklistChooser()[i].batchId;
    String title = picklistChooser()[i].picklist;
    String type = picklistChooser()[i].requestType;
    String u = widget.userName;
    String msg = title.length > 30 ? title.substring(0, 24) + '....' : title;
    int idx = listOfLockedPicklists.indexWhere((e) => e.batchId == batch);
    bool chk1 = listOfLockedPicklists.isNotEmpty;
    bool chk2 = listOfLockedPicklists.any((e) => e.batchId == batch);
    bool tempCheck = chk2 ? listOfLockedPicklists[idx].userName != u : false;
    bool chk3 = idx == -1 ? false : tempCheck;
    if (chk1 && chk2 && chk3) {
      Navigator.pop(c);
      await Future.delayed(const Duration(seconds: 1), () {
        commonToastCentered(msg: msg + kLock, context: c);
        pickListApis();
      });
    } else {
      await saveLockingData(widget.userName, batch).whenComplete(() async {
        bool result = await NavigationMethods.pushWithResult(
          c,
          PicklistDCSplittingScreenWeb(
            batchId: picklistChooser()[i].batchId,
            appBarName: '$title ($type) Split on DC',
            picklist: picklistChooser()[i].picklist,
            status: picklistChooser()[i].status,
            totalOrders: picklistChooser()[i].totalorder,
            picklistLength: pickListCount,
          ),
        );
        if (result == true) {
          commonToastCentered(msg: 'Processing New Picklists....', context: c);
          await Future.delayed(const Duration(seconds: 2), () {
            pickListApis();
          });
        }
      });
    }
  }

  void moveToScSplittingScreen(BuildContext c, int i) async {
    String batch = picklistChooser()[i].batchId;
    String title = picklistChooser()[i].picklist;
    String type = picklistChooser()[i].requestType;
    String u = widget.userName;
    String msg = title.length > 30 ? title.substring(0, 24) + '....' : title;
    int idx = listOfLockedPicklists.indexWhere((e) => e.batchId == batch);
    bool chk1 = listOfLockedPicklists.isNotEmpty;
    bool chk2 = listOfLockedPicklists.any((e) => e.batchId == batch);
    bool tempCheck = chk2 ? listOfLockedPicklists[idx].userName != u : false;
    bool chk3 = idx == -1 ? false : tempCheck;
    if (chk1 && chk2 && chk3) {
      Navigator.pop(c);
      await Future.delayed(const Duration(seconds: 1), () {
        commonToastCentered(msg: msg + kLock, context: c);
        pickListApis();
      });
    } else {
      await saveLockingData(widget.userName, batch).whenComplete(() async {
        bool result = await NavigationMethods.pushWithResult(
          c,
          PicklistSCSplittingScreen(
            batchId: picklistChooser()[i].batchId,
            appBarName: '$title ($type) Split on SC',
            picklist: picklistChooser()[i].picklist,
            status: picklistChooser()[i].status,
            totalOrders: picklistChooser()[i].totalorder,
            picklistLength: pickListCount,
          ),
        );
        if (result == true) {
          commonToastCentered(msg: 'Processing New Picklists....', context: c);
          await Future.delayed(const Duration(seconds: 2), () {
            pickListApis();
          });
        }
      });
    }
  }

  void validatePicklistMobileHandling(BuildContext c, int i) async {
    String batch = picklistChooser()[i].batchId;
    String title = picklistChooser()[i].picklist;
    String u = widget.userName;
    String msg = title.length > 30 ? title.substring(0, 24) + '....' : title;
    int idx = listOfLockedPicklists.indexWhere((e) => e.batchId == batch);
    bool chk1 = listOfLockedPicklists.isNotEmpty;
    bool chk2 = listOfLockedPicklists.any((e) => e.batchId == batch);
    bool tempCheck = chk2 ? listOfLockedPicklists[idx].userName != u : false;
    bool chk3 = idx == -1 ? false : tempCheck;
    if (chk1 && chk2 && chk3) {
      Navigator.pop(c);
      await Future.delayed(const Duration(seconds: 1), () {
        commonToastCentered(msg: msg + kLock, context: c);
        pickListApis();
      });
    } else {
      await validateAllSKUinPicklist(batch, c, title).whenComplete(() async {
        Navigator.pop(c);
        await Future.delayed(const Duration(seconds: 1), () {
          pickListApis();
        });
      });
    }
  }

  ///************************************************************************///

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

  double? heightCheckerForMobile(int index) {
    // bool check1 = picklistChooser()[index].status.contains('In Progress') ||
    //     picklistChooser()[index].status.contains('Not Started');
    // bool check2 = picklistChooser()[index].status.contains('Complete');
    // bool check3 = picklistChooser()[index].requestType == 'MSMQW';
    // bool check4 = picklistChooser()[index].pickedorder.isNotEmpty &&
    //     picklistChooser()[index].pickedorder != '0';
    // bool check5 = picklistChooser()[index].totalsku.isEmpty;
    // bool check6 = picklistChooser()[index].pickedsku.isNotEmpty &&
    //     picklistChooser()[index].pickedsku != '0';
    // bool check7 = splitOnWarehouseLocationVisible(index) &&
    //     splitOnDistributionCenterVisible(index);
    // bool check8 = splitOnWarehouseLocationVisible(index) ||
    //     splitOnDistributionCenterVisible(index);
    // return check1
    //     ? check3
    //         ? check4
    //             ? 150
    //             : 120
    //         : check5
    //             ? 120
    //             : check6
    //                 ? check7
    //                     ? 210
    //                     : check8
    //                         ? 180
    //                         : 150
    //                 : check7
    //                     ? 180
    //                     : check8
    //                         ? 150
    //                         : 120
    //     : check2
    //         ? 120
    //         : 90;

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

  /// NEW 23/08/2023----------------------------------------------
  bool leftToBePickedMobileVisible(int i) {
    return picklistChooser()[i].status.contains('In Progress') ||
        picklistChooser()[i].status.contains('Not Started');
  }

  bool pickedMobileVisible(int i) {
    return picklistChooser()[i].requestType == 'MSMQW'
        ? picklistChooser()[i].pickedorder.isNotEmpty &&
            picklistChooser()[i].pickedorder != '0' &&
            (picklistChooser()[i].status.contains('Complete') ||
                leftToBePickedMobileVisible(i))
        : picklistChooser()[i].pickedsku.isNotEmpty &&
            picklistChooser()[i].pickedsku != '0' &&
            (picklistChooser()[i].status.contains('Complete') ||
                leftToBePickedMobileVisible(i));
  }

  ///---------------------------------------------------------------

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

  void pickListApis() async {
    await loadingPicklistsDataFromDatabase().whenComplete(() async {
      await getSavedLockedPicklistData();
    }).whenComplete(() {
      deleteOlderLockedPicklists();
    }).whenComplete(() async {
      await getAllPickList();
    }).whenComplete(() {
      setPendingPicklistOrSaveCurrentApiDataToDb(
        picklistNo: pendingPickListNo,
        requestType: pendingPicklistRequestType,
      );
    });
  }

  void pickListApisNew() async {
    await loadingPicklistsDataFromDatabaseNew().whenComplete(() async {
      await getSavedLockedPicklistDataNew();
    }).whenComplete(() {
      deleteOlderLockedPicklistsNew();
    }).whenComplete(() async {
      await getAllPickListNew();
    }).whenComplete(() {
      setPendingPicklistOrSaveCurrentApiDataToDb(
        picklistNo: pendingPickListNo,
        requestType: pendingPicklistRequestType,
      );
    });
  }

  Future<void> createNewPicklist({required String type}) async {
    String uri = 'https://weblegs.info/JadlamApp/api/PickList?type=$type';
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
    if (!mounted) return;
    setState(() {
      isPicklistVisible = false;
    });
    try {
      var response = await http.get(Uri.parse(uri)).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          Fluttertoast.showToast(msg: "Connection Timeout.\nPlease try again.");
          if (!mounted) return http.Response('Error', 408);
          setState(() {
            isPicklistVisible = true;
          });
          return http.Response('Error', 408);
        },
      );

      if (response.statusCode == 200) {
        GetAllPicklistResponse getAllPicklistResponse =
            GetAllPicklistResponse.fromJson(jsonDecode(response.body));
        pickLists = <Batch>[];
        pickLists.addAll(getAllPicklistResponse.batch.map((e) => e));

        pickListCount = 0;
        pickListCount = pickLists.length;
        log("pickListCount >>>>> $pickListCount");

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
        log('VALUE OF PICK DB >>---> $pickDB');

        if (picklistLengthDB == pickListCount) {
          /// picklist is not running, check whether error in new picklist or not.
          if (!mounted) return;
          setState(() {
            isCreatingPicklist = false;
          });
          log('isCreatingPicklist when app not running >> $isCreatingPicklist');
          if (pickLists[0].picklist == 'null') {
            /// dialog showing new picklist is having error.
            if (isErrorShown == 'No') {
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
                    status: 'No EAN found!',
                    pickedsku: pickLists[0].pickedsku,
                    totalsku: pickLists[0].totalsku,
                    pickedorder: pickLists[0].pickedorder,
                    totalorder: pickLists[0].totalorder,
                    partialOrders: pickLists[0].partialOrders,
                    partialSkus: pickLists[0].partialSkus,
                    isAlreadyOpened: 'true',
                    totalWarehouseLocation: '0',
                    totalDC: '0',
                    totalSC: '0',
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
                        e.status.contains('No EAN found!') == false));
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
                        e.status.contains('No EAN found!') == false));
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
                      e.status.contains('No EAN found!') == false));
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
                e.status.contains('No EAN found!') == false));
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

  Future<void> getAllPickListNew() async {
    String uri = 'https://weblegs.info/JadlamApp/api/GetPickListVersion2';
    log('getAllPickList - $uri');
    if (!mounted) return;
   /* setState(() {
      isPicklistVisible = false;
    });*/
    try {
      var response = await http.get(Uri.parse(uri)).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          Fluttertoast.showToast(msg: "Connection Timeout.\nPlease try again.");
          if (!mounted) return http.Response('Error', 408);
          setState(() {
            isPicklistVisible = true;
          });
          return http.Response('Error', 408);
        },
      );

      if (response.statusCode == 200) {
        GetAllPicklistResponse getAllPicklistResponse = getAllPicklistResponseFromJson(response.body);
        pickLists = <Batch>[];
        pickLists.addAll(getAllPicklistResponse.batch.map((e) => e));

        pickListCount = 0;
        pickListCount = pickLists.length;
        log("pickListCount >>>>> $pickListCount");

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
        log('VALUE OF PICK DB >>---> $pickDB');

        if (picklistLengthDB == pickListCount) {
          /// picklist is not running, check whether error in new picklist or not.
          if (!mounted) return;
          setState(() {
            isCreatingPicklist = false;
          });
          log('isCreatingPicklist when app not running >> $isCreatingPicklist');
          if (pickLists[0].picklist == 'null') {
            /// dialog showing new picklist is having error.
            if (isErrorShown == 'No') {
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
                    status: 'No EAN found!',
                    pickedsku: pickLists[0].pickedsku,
                    totalsku: pickLists[0].totalsku,
                    pickedorder: pickLists[0].pickedorder,
                    totalorder: pickLists[0].totalorder,
                    partialOrders: pickLists[0].partialOrders,
                    partialSkus: pickLists[0].partialSkus,
                    isAlreadyOpened: 'true',
                    totalWarehouseLocation: '0',
                    totalDC: '0',
                    totalSC: '0',
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
                    e.status.contains('No EAN found!') == false));
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
                    e.status.contains('No EAN found!') == false));
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
                  e.status.contains('No EAN found!') == false));
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
                e.status.contains('No EAN found!') == false));
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

  void savePickListInError({required String picklist}) async {
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

  Future<void> loadingPicklistsDataFromDatabase() async {
    isPicklistVisible = false;
    await ApiCalls.getPicklistsData().then((data) {
      log('picklists data>>>>>${jsonEncode(data)}');

      picklistsDataDB = [];
      picklistsDataDB.addAll(data.map((e) => e));
      log('picklistsDataDB>>>>>${jsonEncode(picklistsDataDB)}');

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

  Future<void> loadingPicklistsDataFromDatabaseNew() async {
    /*isPicklistVisible = false;*/
    await ApiCalls.getPicklistsData().then((data) {
      log('picklists data>>>>>${jsonEncode(data)}');

      picklistsDataDB = [];
      picklistsDataDB.addAll(data.map((e) => e));
      log('picklistsDataDB>>>>>${jsonEncode(picklistsDataDB)}');

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
            status: 'Processing...',
            pickedsku: '0',
            totalsku: '0',
            pickedorder: '0',
            totalorder: '0',
            partialOrders: '0',
            partialSkus: '0',
            isAlreadyOpened: 'true',
            totalWarehouseLocation: '0',
            totalDC: '0',
            totalSC: '0',
          ),
        );

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
        GetLockedPicklistResponse getLockedPicklistResponse =
            GetLockedPicklistResponse.fromJson(jsonDecode(response.body));

        listOfLockedPicklists = [];
        if (getLockedPicklistResponse.message.isNotEmpty) {
          listOfLockedPicklists
              .addAll(getLockedPicklistResponse.message.map((e) => e));
        }
        log('V lockedPicklistList >>---> ${jsonEncode(listOfLockedPicklists)}');

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

  Future<void> getSavedLockedPicklistDataNew() async {
    /*setState(() {
      isPicklistVisible = false;
    });*/
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
        GetLockedPicklistResponse getLockedPicklistResponse =
        GetLockedPicklistResponse.fromJson(jsonDecode(response.body));

        listOfLockedPicklists = [];
        if (getLockedPicklistResponse.message.isNotEmpty) {
          listOfLockedPicklists
              .addAll(getLockedPicklistResponse.message.map((e) => e));
        }
        log('V lockedPicklistList >>---> ${jsonEncode(listOfLockedPicklists)}');

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
    List<MsgX> picklistsToDelete = [];
    DateTime now = DateTime.now();
    if (listOfLockedPicklists
        .where((e) => compDuration(now, e.createdDate))
        .toList()
        .isNotEmpty) {
      picklistsToDelete.addAll(listOfLockedPicklists
          .where((e) => compDuration(now, e.createdDate))
          .map((e) => e));
      for (int i = 0; i < picklistsToDelete.length; i++) {
        deleteLockedPicklistData(id: picklistsToDelete[i].id);
      }
    }
  }

  void deleteOlderLockedPicklistsNew() async {
    List<MsgX> picklistsToDelete = [];
    DateTime now = DateTime.now();
    if (listOfLockedPicklists
        .where((e) => compDuration(now, e.createdDate))
        .toList()
        .isNotEmpty) {
      picklistsToDelete.addAll(listOfLockedPicklists
          .where((e) => compDuration(now, e.createdDate))
          .map((e) => e));
      for (int i = 0; i < picklistsToDelete.length; i++) {
        deleteLockedPicklistData(id: picklistsToDelete[i].id);
      }
    }
  }

  bool compDuration(DateTime now, String str) {
    Duration dur = const Duration(hours: 5);
    DateTime date = dateFormat.parse(str);
    return now.difference(date).compareTo(dur) == 1;
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

  Future<void> saveLockingData(String user, String batchId) async {
    String uri =
        'https://weblegs.info/JadlamApp/api/InsertNewLock?user=$user&BatchId=$batchId';
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

  Future<void> validateAllSKUinPicklist
      (String batchId, BuildContext ctx, String picklist) async {
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
          commonToastCentered(msg: kTimeOut, context: ctx);
          return http.Response('Error', 408);
        },
      );

      if (response.statusCode == 200) {
        log('updateQtyToPick response >>>>> ${jsonDecode(response.body)}');
        String msg = 'All Orders in $picklist is Validated';
        commonToastCentered(msg: msg, context: ctx);
      } else {
        String msg = jsonDecode(response.body)['message'].toString();
        commonToastCentered(msg: msg, context: ctx);
      }
    } on Exception catch (e) {
      log('Exception in updateQtyToPick api >>> ${e.toString()}');
      commonToastCentered(msg: e.toString(), context: ctx);
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
        GetPicklistDetailsResponse getPicklistDetailsResponse =
            GetPicklistDetailsResponse.fromJson(jsonDecode(response.body));

        details = [];
        details.addAll(getPicklistDetailsResponse.sku.map((e) => e));

        locationsList = [];
        List<String> tempList = [];
        tempList.addAll(details.map((e) => e.warehouseLocation.isEmpty
            ? 'Warehouse Location Not Available'
            : e.warehouseLocation));
        log('V tempList >>---> $tempList');
        locationsList.addAll(tempList.toSet().toList().map((e) => e));
        log('V locationsList >>---> $locationsList');
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
