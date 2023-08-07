import 'dart:developer';

import 'package:absolute_app/core/apis/api_calls.dart';
import 'package:absolute_app/core/utils/toast_utils.dart';
import 'package:flutter/material.dart';
import 'package:parse_server_sdk/parse_server_sdk.dart';

class SwitchForDCSplitSetting extends StatefulWidget {
  const SwitchForDCSplitSetting({super.key, required this.userId});

  final String userId;

  @override
  State<SwitchForDCSplitSetting> createState() =>
      _SwitchForDCSplitSettingState();
}

class _SwitchForDCSplitSettingState extends State<SwitchForDCSplitSetting> {
  List<ParseObject> dcSplitData = [];

  bool light = false;
  bool isError = false;

  String error = '';

  @override
  void initState() {
    super.initState();
    setLight();
  }

  void setLight() async {
    await getDCSplitData();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        if(error.isNotEmpty)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(error)
          ],
        ),
        if(error.isEmpty)
        Switch(
          value: light,
          onChanged: (bool value) async {
            setState(() {
              light = value;
            });
            await saveDcSplitData(
              isDCSplitAutomatic: value == true ? 'Yes' : 'No',
              userId: widget.userId,
            ).whenComplete(
              () {
                ToastUtils.motionToastCentered1500MS(
                  message:
                      'Automatic Split by Distribution Center in Picklist is ${value == true ? 'Enabled' : 'Disabled'}',
                  context: context,
                );
              },
            );
          },
        ),
      ],
    );
  }

  Future<void> getDCSplitData() async {
    await ApiCalls.getPrintNodeData().then((data) {
      if (data.isEmpty) {
        setState(() {
          isError = true;
          error = 'Error in fetching PrintNode Data. Please try again!';
        });
      } else {
        dcSplitData = [];
        dcSplitData.addAll(data.map((e) => e));
        log('V dcSplitData >>---> $dcSplitData');

        setState(() {
          light = (dcSplitData[0].get<String>('is_dc_split_automatic') ?? '') ==
                  'Yes'
              ? true
              : false;
        });
        log('V light >>---> $light');
      }
    });
  }

  Future<void> saveDcSplitData({
    required String isDCSplitAutomatic,
    required String userId,
  }) async {
    var dcSplitDataToSave = ParseObject('PrintNodeData')
      ..objectId = 'XOmhiwvKGg'
      ..set('is_dc_split_automatic', isDCSplitAutomatic)
      ..set('user_id', userId);

    await dcSplitDataToSave.save();
  }
}
