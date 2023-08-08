import 'dart:developer';

import 'package:absolute_app/core/utils/toast_utils.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SwitchForBundleSkuSetting extends StatefulWidget {
  const SwitchForBundleSkuSetting({super.key});

  @override
  State<SwitchForBundleSkuSetting> createState() =>
      _SwitchForBundleSkuSettingState();
}

class _SwitchForBundleSkuSettingState extends State<SwitchForBundleSkuSetting> {
  bool light = false;

  @override
  void initState() {
    super.initState();
    setLight();
  }

  void setLight() async {
    await SharedPreferences.getInstance().then((prefs) {
      if ((prefs.getBool('SingleSkuAtOnce') ?? false) == true) {
        setState(() {
          light = true;
        });
      } else {
        setState(() {
          light = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Switch(
          value: light,
          onChanged: (bool value) async {
            setState(() {
              light = value;
            });
            await SharedPreferences.getInstance().then((prefs) {
              prefs.setBool('SingleSkuAtOnce', value);
              log('is SingleSkuAtOnce >>> ${prefs.getBool('SingleSkuAtOnce')}');
            }).whenComplete(() => ToastUtils.motionToastCentered1500MS(
                message:
                'Scanning One Order at once for Bundled SKUs is ${value == true ? 'Enabled' : 'Disabled'}',
                context: context));
          },
        ),
      ],
    );
  }
}
