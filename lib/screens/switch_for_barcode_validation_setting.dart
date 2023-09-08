import 'package:absolute_app/core/utils/common_screen_widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SwitchForBarcodeValidationSetting extends StatefulWidget {
  const SwitchForBarcodeValidationSetting({super.key});

  @override
  State<SwitchForBarcodeValidationSetting> createState() =>
      _SwitchForBarcodeValidationSettingState();
}

class _SwitchForBarcodeValidationSettingState
    extends State<SwitchForBarcodeValidationSetting> {
  bool light = false;

  /// method made to show the switch either in active or inactive state
  /// light variable is made to get the state of the switch
  void setLightBarcodeValidation() async {
    await SharedPreferences.getInstance().then((prefs) {
      setState(() {
        light = prefs.getBool('EnabledBarcodeValidation') ?? false;
      });
    });
  }

  /// the build method for the switch for barcode validation screen
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Switch(
            value: light,
            onChanged: (bool value) async {
              setState(() {
                light = value;
              });
              await SharedPreferences.getInstance().then((prefs) {
                prefs.setBool('EnabledBarcodeValidation', value);
              }).whenComplete(() {
                commonToastCentered(
                    msg:
                        'Barcode Validation in Picklist is ${value == true ? 'Enabled' : 'Disabled'}',
                    context: context);
              });
            }),
      ],
    );
  }
}
