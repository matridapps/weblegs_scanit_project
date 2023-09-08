import 'dart:developer';

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:rounded_loading_button/rounded_loading_button.dart';

// ignore: must_be_immutable
class CreateNewPicklistButtonWeb extends StatelessWidget {
  CreateNewPicklistButtonWeb({
    super.key,
    required this.isVisible,
    required this.size,
    required this.items,
    required this.buttonStyleData,
    required this.dropdownStyleData,
    required this.cancelController,
    required this.createController,
    required this.onPressedCancel,
    required this.onPressedCreate,
    required this.selectedValue,
  });

  final bool isVisible;
  final Size size;
  final List<DropdownMenuItem<String>>? items;
  final ButtonStyleData? buttonStyleData;
  final DropdownStyleData dropdownStyleData;
  final RoundedLoadingButtonController cancelController;
  final RoundedLoadingButtonController createController;
  void Function()? onPressedCancel;
  void Function()? onPressedCreate;
  String selectedValue;

  @override
  Widget build(BuildContext context) {
    const TextStyle s = TextStyle(fontSize: 16, color: Colors.white);
    const TextStyle s2 = TextStyle(fontSize: 18, color: Colors.white);
    return Visibility(
      visible: isVisible,
      child: SizedBox(
        height: 50,
        width: size.width,
        child: Center(
          child: SizedBox(
            height: 35,
            width: 250,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
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
                          titleTextStyle: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                          title: const Text(
                            'Select a Picklist Type',
                            style: TextStyle(fontSize: 22),
                            textAlign: TextAlign.center,
                          ),
                          content: SizedBox(
                            height: 40,
                            width: 300,
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton2<String>(
                                isExpanded: true,
                                items: items,
                                value: selectedValue,
                                onChanged: (String? value) {
                                  setStateSB(() {
                                    selectedValue = value!;
                                  });
                                  log('V selectedPicklist >>---> $selectedValue');
                                },
                                buttonStyleData: buttonStyleData,
                                dropdownStyleData: dropdownStyleData,
                              ),
                            ),
                          ),
                          actions: <Widget>[
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 15),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  RoundedLoadingButton(
                                    color: Colors.red,
                                    borderRadius: 14,
                                    height: 40,
                                    width: 100,
                                    controller: cancelController,
                                    onPressed: onPressedCancel,
                                    child: const Text('Cancel', style: s),
                                  ),
                                  Expanded(
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        RoundedLoadingButton(
                                          color: Colors.green,
                                          borderRadius: 14,
                                          height: 40,
                                          width: 100,
                                          controller: createController,
                                          onPressed: onPressedCreate,
                                          child: const Text('Create', style: s),
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
              child: const Text('Create New PickList', style: s2),
            ),
          ),
        ),
      ),
    );
  }
}
