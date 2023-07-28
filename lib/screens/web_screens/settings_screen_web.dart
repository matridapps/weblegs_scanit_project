import 'dart:developer';

import 'package:absolute_app/core/apis/api_calls.dart';
import 'package:absolute_app/core/utils/constants.dart';
import 'package:absolute_app/core/utils/toast_utils.dart';
import 'package:absolute_app/screens/switch_for_settings_screen.dart';
import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:parse_server_sdk/parse_server_sdk.dart';
import 'package:rounded_loading_button/rounded_loading_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreenWeb extends StatefulWidget {
  const SettingsScreenWeb({super.key, required this.userId});

  final String userId;

  @override
  State<SettingsScreenWeb> createState() => _SettingsScreenWebState();
}

class _SettingsScreenWebState extends State<SettingsScreenWeb> {
  final RoundedLoadingButtonController saveValuesController =
      RoundedLoadingButtonController();

  final TextEditingController lengthController = TextEditingController();
  final TextEditingController widthController = TextEditingController();
  final TextEditingController heightController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController eanOrOrderController = TextEditingController();
  final TextEditingController selectedPicklistController =
      TextEditingController();

  List<String> pickListTypes = ['SIW', 'SSMQW', 'MSMQW'];
  List<String> eanOrOrder = ['Barcode', 'Order Number'];
  List<ParseObject> defaultValuesDB = [];
  List<ParseObject> siteNameList = [];
  List<bool> checkBoxValueListForSiteName = [];
  List<String> objectIdListForSiteName = [];
  List<String> userIdListForSiteName = [];

  bool isLoading = false;
  bool isError = false;

  String error = '';
  String eanOrOrderSelected = 'Barcode';
  String selectedPicklist = 'SIW';

  @override
  void initState() {
    super.initState();
    settingScreenApis();
  }

  @override
  void dispose() {
    lengthController.dispose();
    widthController.dispose();
    heightController.dispose();
    weightController.dispose();
    super.dispose();
  }

  void settingScreenApis() async {
    setState(() {
      isLoading = true;
      isError = false;
    });
    await getDefaultValuesForSKU()
        .whenComplete(() async => await getPackAndScanValues())
        .whenComplete(() async => await getSiteNameList())
        .whenComplete(() {
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
          'Settings',
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
                          _bundleSettingBuilder(context, size),
                          _defaultValuesBuilder(context, size),
                          _defaultValueForPackAndScanBuilder(context, size),
                          _settingForSiteName(context, size),
                          _bottomBuilder(context, size)
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }

  /// BUILDER METHODS FOR WEB

  Widget _bundleSettingBuilder(BuildContext context, Size size) {
    return const ListTile(
      title: Text(
        'Scan One Order at once for Bundled SKUs',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        'If enabled, validating SKUs in SIW and SSMQW picklist will validate one order at a time for that SKU Bundle and If disabled, all orders in the SKU bundle will be validated.',
        style: TextStyle(fontSize: 16),
      ),
      trailing: SwitchForSettingsScreen(),
    );
  }

  Widget _defaultValuesBuilder(BuildContext context, Size size) {
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
                'Default Values for SKU',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              )
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Length (in cm)  :',
                  style: TextStyle(fontSize: 16),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: SizedBox(
                    height: 35,
                    width: size.width,
                    child: TextFormField(
                      controller: lengthController,
                      style: const TextStyle(
                        fontSize: 16,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Length',
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
                const Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Width (in cm)  :',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: SizedBox(
                    height: 35,
                    width: size.width,
                    child: TextFormField(
                      controller: widthController,
                      style: const TextStyle(
                        fontSize: 16,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Width',
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
                const Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Height (in cm)  :',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: SizedBox(
                    height: 35,
                    width: size.width,
                    child: TextFormField(
                      controller: heightController,
                      style: const TextStyle(
                        fontSize: 16,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Height',
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
                const Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Weight (in gm)  :',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: SizedBox(
                    height: 35,
                    width: size.width,
                    child: TextFormField(
                      controller: weightController,
                      style: const TextStyle(
                        fontSize: 16,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Weight',
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

  Widget _defaultValueForPackAndScanBuilder(BuildContext context, Size size) {
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
                'Default Values for Pack and Scan',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              )
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Scan Orders using  :',
                  style: TextStyle(fontSize: 16),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 5.0),
                  child: SizedBox(
                    height: 35,
                    width: size.width,
                    child: CustomDropdown(
                      items: eanOrOrder,
                      controller: eanOrOrderController,
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
                          eanOrOrderSelected = eanOrOrderController.text;
                        });
                        log('V eanOrOrderController.text >>---> ${eanOrOrderController.text}');
                        log('V eanOrOrderSelected >>---> $eanOrOrderSelected');
                      },
                    ),
                  ),
                ),
                Visibility(
                  visible: eanOrOrderSelected == 'Barcode',
                  child: const Padding(
                    padding: EdgeInsets.only(top: 8.0),
                    child: Text(
                      'For Picklist type  :',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                Visibility(
                  visible: eanOrOrderSelected == 'Barcode',
                  child: Padding(
                    padding: const EdgeInsets.only(top: 5.0),
                    child: SizedBox(
                      height: 35,
                      width: size.width,
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
                            selectedPicklist = selectedPicklistController.text;
                          });
                          log('V selectedPicklistController.text >>---> ${selectedPicklistController.text}');
                          log('V selectedPicklist >>---> $selectedPicklist');
                        },
                      ),
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

  Widget _settingForSiteName(BuildContext context, Size size) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Flexible(
                child: Text(
                  'Select SiteName to be Removed from Order Scan System',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    overflow: TextOverflow.visible,
                  ),
                ),
              )
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ..._siteNameListMaker(),
              ],
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
                await saveValues(
                  length: lengthController.text.toString(),
                  width: widthController.text.toString(),
                  height: heightController.text.toString(),
                  weight: weightController.text.toString(),
                ).whenComplete(
                  () async {
                    await savePackAndScanValues(
                      eanOrOrder: eanOrOrderSelected,
                      picklistType: selectedPicklist,
                    );
                  },
                ).whenComplete(
                  () async {
                    await saveSiteNameList(
                      isSelected: checkBoxValueListForSiteName
                          .map((e) => e == true ? 'Yes' : 'No')
                          .toList(),
                      userId: userIdListForSiteName,
                    );
                  },
                ).whenComplete(() async {
                  await getDefaultValuesForSKU();
                }).whenComplete(() async {
                  await getPackAndScanValues();
                }).whenComplete(() async {
                  await getSiteNameList();
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

  /// OTHER WIDGETS

  List<Widget> _siteNameListMaker() {
    return List.generate(
      siteNameList.length,
      (index) => Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Checkbox(
            activeColor: appColor,
            value: checkBoxValueListForSiteName[index],
            onChanged: (bool? newValue) {
              setState(() {
                checkBoxValueListForSiteName[index] =
                    !(checkBoxValueListForSiteName[index]);
                userIdListForSiteName[index] = widget.userId;
              });
              log('V checkBoxValueListForSiteName At $index >>---> ${checkBoxValueListForSiteName[index]}');
              log('V userIdListForSiteName At $index >>---> ${userIdListForSiteName[index]}');
            },
          ),
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Text(
              siteNameList[index].get<String>('site_name') ?? 'NA',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// API METHODS

  Future<void> getDefaultValuesForSKU() async {
    await ApiCalls.getDefaultValuesForSKU().then((data) {
      if (data.isEmpty) {
        setState(() {
          isError = true;
          error = 'Error in fetching Default Values. Please try again!';
        });
      } else {
        defaultValuesDB = [];
        defaultValuesDB.addAll(data.map((e) => e));
        log('defaultValuesDB >> $defaultValuesDB');

        setState(() {
          lengthController.text = defaultValuesDB[defaultValuesDB
                  .indexWhere((e) => e.get<String>('item_name') == 'Length')]
              .get<String>('item_value')!;
          widthController.text = defaultValuesDB[defaultValuesDB
                  .indexWhere((e) => e.get<String>('item_name') == 'Width')]
              .get<String>('item_value')!;
          heightController.text = defaultValuesDB[defaultValuesDB
                  .indexWhere((e) => e.get<String>('item_name') == 'Height')]
              .get<String>('item_value')!;
          weightController.text = defaultValuesDB[defaultValuesDB
                  .indexWhere((e) => e.get<String>('item_name') == 'Weight')]
              .get<String>('item_value')!;
        });
      }
    });
  }

  Future<void> saveValues({
    required String length,
    required String width,
    required String height,
    required String weight,
  }) async {
    var lengthData = ParseObject('default_values_for_sku')
      ..objectId = 'OkRHmPq8qU'
      ..set('item_value', length);

    var widthData = ParseObject('default_values_for_sku')
      ..objectId = 'E24ym7tMhy'
      ..set('item_value', width);

    var heightData = ParseObject('default_values_for_sku')
      ..objectId = '7QCp7f09YV'
      ..set('item_value', height);

    var weightData = ParseObject('default_values_for_sku')
      ..objectId = 'pakp6zzNHE'
      ..set('item_value', weight);

    await lengthData.save().whenComplete(() async {
      await widthData.save();
    }).whenComplete(() async {
      await heightData.save();
    }).whenComplete(() async {
      await weightData.save();
    });
  }

  Future<void> getPackAndScanValues() async {
    await SharedPreferences.getInstance().then((prefs) {
      setState(() {
        eanOrOrderController.text =
            prefs.getString('eanOrOrderNumber') ?? 'Barcode';
        eanOrOrderSelected = prefs.getString('eanOrOrderNumber') ?? 'Barcode';
        selectedPicklistController.text =
            prefs.getString('picklistType') ?? 'SIW';
        selectedPicklist = prefs.getString('picklistType') ?? 'SIW';
      });
    });
  }

  Future<void> savePackAndScanValues({
    required String eanOrOrder,
    required String picklistType,
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('eanOrOrderNumber', eanOrOrder);
    prefs.setString('picklistType', picklistType);
  }

  Future<void> getSiteNameList() async {
    await ApiCalls.getSiteNameList().then((data) {
      if (data.isEmpty) {
        setState(() {
          isError = true;
          error = 'Error in fetching SiteNames. Please try again!';
        });
      } else {
        siteNameList = [];
        siteNameList.addAll(data.map((e) => e));
        log('V siteNameList >>---> $defaultValuesDB');

        checkBoxValueListForSiteName = [];
        checkBoxValueListForSiteName.addAll(siteNameList.map((e) =>
            (e.get<String>('is_selected') ?? 'No') == 'Yes' ? true : false));
        log('V checkBoxValueListForSiteName >>---> $checkBoxValueListForSiteName');

        objectIdListForSiteName = [];
        objectIdListForSiteName.addAll(
            siteNameList.map((e) => (e.get<String>('objectId') ?? 'NA')));
        log('V objectIdListForSiteName >>---> $objectIdListForSiteName');

        userIdListForSiteName = [];
        userIdListForSiteName.addAll(siteNameList
            .map((e) => (e.get<String>('updated_by_user') ?? 'NA')));
        log('V userIdListForSiteName >>---> $userIdListForSiteName');
      }
    });
  }

  Future<void> saveSiteNameList({
    required List<String> isSelected,
    required List<String> userId,
  }) async {
    for (int i = 0; i < siteNameList.length; i++) {
      var siteNameData = ParseObject('site_name_list')
        ..objectId = objectIdListForSiteName[i]
        ..set('is_selected', isSelected[i])
        ..set('updated_by_user', userId[i]);

      await siteNameData.save();
    }
  }
}
