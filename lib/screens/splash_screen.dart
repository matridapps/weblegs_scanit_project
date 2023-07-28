import 'dart:convert';
import 'dart:developer';

import 'package:absolute_app/core/apis/api_calls.dart';
import 'package:absolute_app/core/utils/constants.dart';
import 'package:absolute_app/screens/home_screen.dart';
import 'package:absolute_app/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() {
    return _SplashScreenState();
  }
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  bool errorVisible = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6000),
      reverseDuration: const Duration(milliseconds: 444),
    );
    _controller.forward();

    loadingData();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        top: true,
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    color: appColor,
                    strokeWidth: 5,
                  ),
                  Visibility(
                    visible: errorVisible,
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                          'Internet may not be available, Please Restart the app'),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void loadingData() async {
    await ApiCalls.getWeblegsData().then((data) async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      log('data - ${jsonEncode(data)}');
      if (data.isEmpty) {
        Fluttertoast.showToast(
                msg:
                    'Internet may not be available, Please check your connection and Restart the app.',
                toastLength: Toast.LENGTH_LONG)
            .whenComplete(() {
          setState(() {
            errorVisible = true;
          });
        });
      } else {
        /// IF LOG OUT IS DONE PREVIOUSLY : FURTHER CHECKS
        if (prefs.getBool('isLoggedOut') != null) {
          /// IF NOT LOGGED OUT : FURTHER CHECKS
          if (prefs.getBool('isLoggedOut') == false) {
            /// IF LOGIN IS DONE PREVIOUSLY : FURTHER CHECKS
            if (prefs.getString('loggedInTime') != null) {
              ///   CHECKING WHETHER TIME AFTER LOGIN IS LESS THAN OR GREATER THAN 1 DAY.
              if ((DateTime.now()
                      .difference(DateFormat()
                          .parse(prefs.getString('loggedInTime') ?? ''))
                      .compareTo(const Duration(days: 1))) ==
                  -1) {
                /// LESS THAN 1 DAY, SESSION NOT ENDED : MOVE TO HOME SCREEN.
                setState(() {
                  errorVisible = false;
                });
                if (!mounted) return;
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => HomeScreen(
                      accType: data[data.indexWhere((e) =>
                              e.get<String>('user_id') ==
                              (prefs.getString("userName") ?? ""))]
                          .get<String>('account_type')!,
                      authorization: data[data.indexWhere((e) =>
                              e.get<String>('user_id') ==
                              (prefs.getString("userName") ?? ""))]
                          .get<String>('authorization')!,
                      refreshToken: data[data.indexWhere((e) =>
                              e.get<String>('user_id') ==
                              (prefs.getString("userName") ?? ""))]
                          .get<String>('refresh_token')!,
                      userId: data[data.indexWhere((e) =>
                              e.get<String>('user_id') ==
                              (prefs.getString("userName") ?? ""))]
                          .get<String>('user_id')!,
                      profileId: data[data.indexWhere((e) =>
                              e.get<String>('user_id') ==
                              (prefs.getString("userName") ?? ""))]
                          .get<int>('profile_id')!,
                      distCenterId: data[data.indexWhere((e) =>
                              e.get<String>('user_id') ==
                              (prefs.getString("userName") ?? ""))]
                          .get<int>('distribution_center_id')!,
                      distCenterName: data[data.indexWhere((e) =>
                              e.get<String>('user_id') ==
                              (prefs.getString("userName") ?? ""))]
                          .get<String>('distribution_center_name')!,
                    ),
                  ),
                );
              } else {
                /// GREATER THAN 1 DAY, SESSION TIME ENDS : MOVE TO LOGIN SCREEN.
                setState(() {
                  errorVisible = false;
                });
                Future.delayed(const Duration(seconds: 1)).then(
                  (value) => Navigator.pushReplacement(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          LoginScreen(dataFromDB: data),
                    ),
                  ),
                );
              }
            } else {
              /// IF LOGIN IS NOT DONE, APPLICABLE FOR A NEW APP INSTALLATION : MOVE TO LOGIN SCREEN.
              setState(() {
                errorVisible = false;
              });
              Future.delayed(const Duration(seconds: 1)).then(
                (value) => Navigator.pushReplacement(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        LoginScreen(dataFromDB: data),
                  ),
                ),
              );
            }
          } else {
            /// IF LOGGED OUT : MOVE TO LOGIN SCREEN
            setState(() {
              errorVisible = false;
            });
            Future.delayed(const Duration(seconds: 1)).then(
              (value) => Navigator.pushReplacement(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      LoginScreen(dataFromDB: data),
                ),
              ),
            );
          }
        } else {
          /// IF LOG OUT IS NOT DONE, APPLICABLE FOR A NEW APP INSTALLATION : MOVE TO LOGIN SCREEN.
          setState(() {
            errorVisible = false;
          });
          Future.delayed(const Duration(seconds: 1)).then(
            (value) => Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    LoginScreen(dataFromDB: data),
              ),
            ),
          );
        }
      }
    });
  }
}
