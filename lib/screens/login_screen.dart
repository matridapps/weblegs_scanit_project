import 'dart:developer';

import 'package:absolute_app/core/utils/app_export.dart';
import 'package:absolute_app/core/utils/constants.dart';
import 'package:absolute_app/core/utils/responsive_check.dart';
import 'package:absolute_app/screens/home_screen.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:rounded_loading_button/rounded_loading_button.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key, required this.dataFromDB}) : super(key: key);

  final List<ParseObject> dataFromDB;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late TextEditingController _userNameController;
  late TextEditingController _passwordController;
  late FocusNode _userNameFocus;
  late FocusNode _passwordFocus;

  bool _passwordVisible = true;
  bool _isRememberChecked = false;
  bool _isUFocused = false;
  bool _isPFocused = false;

  final RoundedLoadingButtonController loginController =
      RoundedLoadingButtonController();

  @override
  void initState() {
    super.initState();
    _loadUserNamePassword();
    _userNameController = TextEditingController();
    _passwordController = TextEditingController();
    _userNameFocus = FocusNode();
    _passwordFocus = FocusNode();

    loginController.stateStream.listen((value) {
      log('$value');
    });
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    FocusScopeNode currentFocus = FocusScope.of(context);
    return WillPopScope(
      onWillPop: kIsWeb == true
          ? () async {
              return true;
            }
          : showExitPopup,
      child: Scaffold(
        backgroundColor: Colors.white,
        resizeToAvoidBottomInset: true,
        extendBodyBehindAppBar: true,
        body: kIsWeb == true

            /// >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> WEB APP LOGIN SCREEN  >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

            ? ResponsiveCheck.screenBiggerThan24inch(context) == true
                ? GestureDetector(
                    onTap: () {
                      FocusScope.of(context).requestFocus(FocusNode());
                      if (!currentFocus.hasPrimaryFocus) {
                        currentFocus.unfocus();
                      }
                    },
                    child: Container(
                      height: size.height,
                      width: size.width,
                      color: Colors.white,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(80, 50, 80, 80),
                            child: SizedBox(
                              height: 300,
                              width: 200,
                              child: Image.asset('assets/logo/new_logo.png'),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(80, 0, 80, 0),
                            child: Card(
                              elevation: 10,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: SizedBox(
                                height: 60,
                                width: 560,
                                child: Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: ThemeData()
                                        .colorScheme
                                        .copyWith(primary: appColor),
                                  ),
                                  child: RawKeyboardListener(
                                    focusNode: _userNameFocus,
                                    child: Focus(
                                      onFocusChange: (isFocused) {
                                        setState(() {
                                          _isUFocused = isFocused;
                                          log('uFocused - $_isUFocused');
                                        });
                                      },
                                      child: TextFormField(
                                        textAlignVertical:
                                            TextAlignVertical.center,
                                        controller: _userNameController,
                                        style: const TextStyle(fontSize: 20),
                                        decoration: InputDecoration(
                                          contentPadding: EdgeInsets.zero,
                                          filled: true,
                                          fillColor: _isUFocused
                                              ? Colors.white
                                              : Colors.grey.shade100,
                                          prefixIcon: Image.asset(
                                            'assets/login_icons/username.png',
                                            height: 100,
                                            width: 100,
                                            color:
                                                _isUFocused ? appColor : null,
                                          ),
                                          hintText: "User name",
                                          border: InputBorder.none,
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: const BorderSide(
                                              color: appColor,
                                              width: 1,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          focusColor: appColor,
                                        ),
                                        validator: (value) {
                                          if (value!.isEmpty) {
                                            return "user name cannot be empty";
                                          }
                                          return null;
                                        },
                                        onFieldSubmitted: (_) {
                                          FocusScope.of(context)
                                              .requestFocus(_passwordFocus);
                                        },
                                      ),
                                    ),
                                    onKey: (RawKeyEvent event) {
                                      if (event.isKeyPressed(
                                          LogicalKeyboardKey.tab)) {
                                        var currentText =
                                            _userNameController.text;
                                        var textWithoutTab =
                                            currentText.replaceAll("\t", "");
                                        _userNameController.text =
                                            textWithoutTab;
                                        FocusScope.of(context)
                                            .requestFocus(_passwordFocus);
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(80, 35, 80, 0),
                            child: Card(
                              elevation: 10,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              child: SizedBox(
                                height: 60,
                                width: 560,
                                child: Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme:
                                        ThemeData().colorScheme.copyWith(
                                              primary: appColor,
                                            ),
                                  ),
                                  child: RawKeyboardListener(
                                    focusNode: _passwordFocus,
                                    child: Focus(
                                      onFocusChange: (isFocused) {
                                        setState(() {
                                          _isPFocused = isFocused;
                                          log('pFocused - $_isPFocused');
                                        });
                                      },
                                      child: TextFormField(
                                        textAlignVertical:
                                            TextAlignVertical.center,
                                        obscureText: _passwordVisible,
                                        controller: _passwordController,
                                        style: const TextStyle(fontSize: 20),
                                        decoration: InputDecoration(
                                          contentPadding: EdgeInsets.zero,
                                          suffixIcon: IconButton(
                                            icon: Icon(_passwordVisible
                                                ? Icons.visibility_rounded
                                                : Icons.visibility_off_rounded),
                                            onPressed: () {
                                              setState(() {
                                                _passwordVisible =
                                                    !_passwordVisible;
                                              });
                                            },
                                          ),
                                          filled: true,
                                          fillColor: _isPFocused
                                              ? Colors.white
                                              : Colors.grey.shade100,
                                          prefixIcon: Image.asset(
                                            'assets/login_icons/password.png',
                                            height: 100,
                                            width: 100,
                                            color:
                                                _isPFocused ? appColor : null,
                                          ),
                                          hintText: "Password",
                                          border: InputBorder.none,
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: const BorderSide(
                                              color: appColor,
                                              width: 1,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          focusColor: appColor,
                                        ),
                                        onFieldSubmitted: (value) async {
                                          FocusScope.of(context).unfocus();
                                          if (widget.dataFromDB.isEmpty) {
                                            Future.delayed(
                                                const Duration(seconds: 1), () {
                                              Fluttertoast.showToast(
                                                  msg:
                                                      'Internet may not be available, Please check your connection and Restart the app.',
                                                  toastLength:
                                                      Toast.LENGTH_SHORT);
                                              loginController.reset();
                                            });
                                          } else {
                                            if (_userNameController.text
                                                    .toString()
                                                    .isNotEmpty &&
                                                _passwordController.text
                                                    .toString()
                                                    .isNotEmpty) {
                                              if (widget.dataFromDB.any((e) =>
                                                      e.get<String>(
                                                          'user_id') ==
                                                      _userNameController.text
                                                          .toString()) ==
                                                  false) {
                                                log(_userNameController.text
                                                    .toString());
                                                Future.delayed(
                                                    const Duration(seconds: 1),
                                                    () {
                                                  Fluttertoast.showToast(
                                                      msg:
                                                          'You have entered an invalid username',
                                                      toastLength:
                                                          Toast.LENGTH_LONG);
                                                  loginController.reset();
                                                });
                                              } else {
                                                if (_passwordController.text
                                                        .toString() !=
                                                    widget.dataFromDB[widget
                                                            .dataFromDB
                                                            .indexWhere((e) =>
                                                                e.get<String>(
                                                                    'user_id') ==
                                                                _userNameController
                                                                    .text
                                                                    .toString())]
                                                        .get<String>(
                                                            'password')) {
                                                  Future.delayed(
                                                      const Duration(
                                                          seconds: 1), () {
                                                    Fluttertoast.showToast(
                                                        msg:
                                                            'The password you entered is incorrect',
                                                        toastLength:
                                                            Toast.LENGTH_LONG);
                                                    loginController.reset();
                                                  });
                                                } else {
                                                  /// set Remember Me Values
                                                  await SharedPreferences
                                                          .getInstance()
                                                      .then(
                                                    (prefs) {
                                                      prefs.setBool(
                                                          "rememberMe",
                                                          _isRememberChecked);
                                                      prefs.setString(
                                                          'userName',
                                                          _userNameController
                                                              .text);
                                                      prefs.setString(
                                                          'password',
                                                          _passwordController
                                                              .text);
                                                      prefs.setString(
                                                          'loggedInTime',
                                                          DateFormat().format(
                                                              DateTime.now()));
                                                      prefs.setBool(
                                                          'isLoggedOut', false);
                                                    },
                                                  );
                                                  Future.delayed(
                                                      const Duration(
                                                          seconds: 1), () {
                                                    Fluttertoast.showToast(
                                                        msg:
                                                            'You have successfully logged in.',
                                                        toastLength:
                                                            Toast.LENGTH_LONG);
                                                    Future.delayed(
                                                        const Duration(
                                                            seconds: 1), () {
                                                      Navigator.pushReplacement(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (_) =>
                                                              HomeScreen(
                                                            accType: widget
                                                                .dataFromDB[widget
                                                                    .dataFromDB
                                                                    .indexWhere((e) =>
                                                                        e.get<String>(
                                                                            'user_id') ==
                                                                        _userNameController
                                                                            .text
                                                                            .toString())]
                                                                .get<String>(
                                                                    'account_type')!,
                                                            authorization: widget
                                                                .dataFromDB[widget
                                                                    .dataFromDB
                                                                    .indexWhere((e) =>
                                                                        e.get<String>(
                                                                            'user_id') ==
                                                                        _userNameController
                                                                            .text
                                                                            .toString())]
                                                                .get<String>(
                                                                    'authorization')!,
                                                            refreshToken: widget
                                                                .dataFromDB[widget
                                                                    .dataFromDB
                                                                    .indexWhere((e) =>
                                                                        e.get<String>(
                                                                            'user_id') ==
                                                                        _userNameController
                                                                            .text
                                                                            .toString())]
                                                                .get<String>(
                                                                    'refresh_token')!,
                                                            userId: widget
                                                                .dataFromDB[widget
                                                                    .dataFromDB
                                                                    .indexWhere((e) =>
                                                                        e.get<String>(
                                                                            'user_id') ==
                                                                        _userNameController
                                                                            .text
                                                                            .toString())]
                                                                .get<String>(
                                                                    'user_id')!,
                                                            profileId: widget
                                                                .dataFromDB[widget
                                                                    .dataFromDB
                                                                    .indexWhere((e) =>
                                                                        e.get<String>(
                                                                            'user_id') ==
                                                                        _userNameController
                                                                            .text
                                                                            .toString())]
                                                                .get<int>(
                                                                    'profile_id')!,
                                                            distCenterId: widget
                                                                .dataFromDB[widget
                                                                    .dataFromDB
                                                                    .indexWhere((e) =>
                                                                        e.get<String>(
                                                                            'user_id') ==
                                                                        _userNameController
                                                                            .text
                                                                            .toString())]
                                                                .get<int>(
                                                                    'distribution_center_id')!,
                                                            distCenterName: widget
                                                                .dataFromDB[widget
                                                                    .dataFromDB
                                                                    .indexWhere((e) =>
                                                                        e.get<String>(
                                                                            'user_id') ==
                                                                        _userNameController
                                                                            .text
                                                                            .toString())]
                                                                .get<String>(
                                                                    'distribution_center_name')!,
                                                          ),
                                                        ),
                                                      ).whenComplete(() =>
                                                          loginController
                                                              .reset());
                                                    });
                                                  });
                                                }
                                              }
                                            } else {
                                              Future.delayed(
                                                  const Duration(seconds: 1),
                                                  () {
                                                Fluttertoast.showToast(
                                                    msg:
                                                        'Please enter required details');
                                                loginController.reset();
                                              });
                                            }
                                          }
                                        },
                                        validator: (value) {
                                          if (value!.isEmpty) {
                                            return "password cannot be empty";
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                    onKey: (RawKeyEvent event) {
                                      if (event.isKeyPressed(
                                          LogicalKeyboardKey.tab)) {
                                        var currentText =
                                            _passwordController.text;
                                        var textWithoutTab =
                                            currentText.replaceAll("\t", "");
                                        _passwordController.text =
                                            textWithoutTab;
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(50, 35, 80, 0),
                            child: SizedBox(
                              height: 40,
                              width: size.width,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Checkbox(
                                    activeColor: appColor,
                                    value: _isRememberChecked,
                                    onChanged: (bool? newValue) {
                                      setState(() {
                                        _isRememberChecked = newValue!;
                                      });
                                      log('_isRememberChecked - $_isRememberChecked');
                                    },
                                  ),
                                  const Text(
                                    'Remember me',
                                    style: TextStyle(
                                      fontSize: 18,
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(80, 16, 80, 0),
                            child: RoundedLoadingButton(
                              color: appColor,
                              borderRadius: 0,
                              elevation: 10,
                              height: 60,
                              width: 300,
                              successIcon: Icons.check_rounded,
                              failedIcon: Icons.close_rounded,
                              successColor: Colors.green,
                              errorColor: appColor,
                              controller: loginController,
                              onPressed: () {
                                FocusScope.of(context).unfocus();
                                if (widget.dataFromDB.isEmpty) {
                                  Future.delayed(const Duration(seconds: 1),
                                      () {
                                    Fluttertoast.showToast(
                                        msg:
                                            'Internet may not be available, Please check your connection and Restart the app.',
                                        toastLength: Toast.LENGTH_SHORT);
                                    loginController.reset();
                                  });
                                } else {
                                  if (_userNameController.text
                                          .toString()
                                          .isNotEmpty &&
                                      _passwordController.text
                                          .toString()
                                          .isNotEmpty) {
                                    if (widget.dataFromDB.any((e) =>
                                            e.get<String>('user_id') ==
                                            _userNameController.text
                                                .toString()) ==
                                        false) {
                                      log(_userNameController.text.toString());
                                      Future.delayed(const Duration(seconds: 1),
                                          () {
                                        Fluttertoast.showToast(
                                            msg:
                                                'You have entered an invalid username',
                                            toastLength: Toast.LENGTH_LONG);
                                        loginController.reset();
                                      });
                                    } else {
                                      if (_passwordController.text.toString() !=
                                          widget.dataFromDB[widget.dataFromDB
                                                  .indexWhere((e) =>
                                                      e.get<String>(
                                                          'user_id') ==
                                                      _userNameController.text
                                                          .toString())]
                                              .get<String>('password')) {
                                        Future.delayed(
                                            const Duration(seconds: 1), () {
                                          Fluttertoast.showToast(
                                              msg:
                                                  'The password you entered is incorrect',
                                              toastLength: Toast.LENGTH_LONG);
                                          loginController.reset();
                                        });
                                      } else {
                                        /// set Remember Me Values
                                        SharedPreferences.getInstance().then(
                                          (prefs) {
                                            prefs.setBool("rememberMe",
                                                _isRememberChecked);
                                            prefs.setString('userName',
                                                _userNameController.text);
                                            prefs.setString('password',
                                                _passwordController.text);
                                            prefs.setString(
                                                'loggedInTime',
                                                DateFormat()
                                                    .format(DateTime.now()));
                                            prefs.setBool('isLoggedOut', false);
                                          },
                                        );
                                        Future.delayed(
                                            const Duration(seconds: 1), () {
                                          Fluttertoast.showToast(
                                              msg:
                                                  'You have successfully logged in.',
                                              toastLength: Toast.LENGTH_LONG);
                                          Future.delayed(
                                              const Duration(seconds: 1), () {
                                            Navigator.pushReplacement(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => HomeScreen(
                                                  accType: widget
                                                      .dataFromDB[widget
                                                          .dataFromDB
                                                          .indexWhere((e) =>
                                                              e.get<String>(
                                                                  'user_id') ==
                                                              _userNameController
                                                                  .text
                                                                  .toString())]
                                                      .get<String>(
                                                          'account_type')!,
                                                  authorization: widget
                                                      .dataFromDB[widget
                                                          .dataFromDB
                                                          .indexWhere((e) =>
                                                              e.get<String>(
                                                                  'user_id') ==
                                                              _userNameController
                                                                  .text
                                                                  .toString())]
                                                      .get<String>(
                                                          'authorization')!,
                                                  refreshToken: widget
                                                      .dataFromDB[widget
                                                          .dataFromDB
                                                          .indexWhere((e) =>
                                                              e.get<String>(
                                                                  'user_id') ==
                                                              _userNameController
                                                                  .text
                                                                  .toString())]
                                                      .get<String>(
                                                          'refresh_token')!,
                                                  userId: widget
                                                      .dataFromDB[widget
                                                          .dataFromDB
                                                          .indexWhere((e) =>
                                                              e.get<String>(
                                                                  'user_id') ==
                                                              _userNameController
                                                                  .text
                                                                  .toString())]
                                                      .get<String>('user_id')!,
                                                  profileId: widget
                                                      .dataFromDB[widget
                                                          .dataFromDB
                                                          .indexWhere((e) =>
                                                              e.get<String>(
                                                                  'user_id') ==
                                                              _userNameController
                                                                  .text
                                                                  .toString())]
                                                      .get<int>('profile_id')!,
                                                  distCenterId: widget
                                                      .dataFromDB[widget
                                                          .dataFromDB
                                                          .indexWhere((e) =>
                                                              e.get<String>(
                                                                  'user_id') ==
                                                              _userNameController
                                                                  .text
                                                                  .toString())]
                                                      .get<int>(
                                                          'distribution_center_id')!,
                                                  distCenterName: widget
                                                      .dataFromDB[widget
                                                          .dataFromDB
                                                          .indexWhere((e) =>
                                                              e.get<String>(
                                                                  'user_id') ==
                                                              _userNameController
                                                                  .text
                                                                  .toString())]
                                                      .get<String>(
                                                          'distribution_center_name')!,
                                                ),
                                              ),
                                            ).whenComplete(
                                                () => loginController.reset());
                                          });
                                        });
                                      }
                                    }
                                  } else {
                                    Future.delayed(const Duration(seconds: 1),
                                        () {
                                      Fluttertoast.showToast(
                                          msg: 'Please enter required details');
                                      loginController.reset();
                                    });
                                  }
                                }
                              },
                              child: const Text(
                                'Login',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 26),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )

                ///>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>..>>>>>

                : GestureDetector(
                    onTap: () {
                      FocusScope.of(context).requestFocus(FocusNode());
                      if (!currentFocus.hasPrimaryFocus) {
                        currentFocus.unfocus();
                      }
                    },
                    child: Container(
                      height: size.height,
                      width: size.width,
                      color: Colors.white,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          Padding(
                            padding: EdgeInsets.fromLTRB(
                              size.width * .05,
                              size.width * .03,
                              size.width * .05,
                              size.width * .05,
                            ),
                            child: SizedBox(
                              height: size.height * .25,
                              width: size.height * .25,
                              child: Image.asset('assets/logo/new_logo.png'),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.fromLTRB(
                                size.width * .05, 0, size.width * .05, 0),
                            child: Card(
                              elevation: 10,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: SizedBox(
                                height: ResponsiveCheck.isLargeScreen(context)
                                    ? size.height * .075
                                    : ResponsiveCheck.isMediumScreen(context)
                                        ? size.height * .065
                                        : size.height * .055,
                                width: ResponsiveCheck.isSmallScreen(context)
                                    ? size.width * .35
                                    : size.width * .25,
                                child: Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: ThemeData()
                                        .colorScheme
                                        .copyWith(primary: appColor),
                                  ),
                                  child: RawKeyboardListener(
                                    focusNode: _userNameFocus,
                                    child: Focus(
                                      onFocusChange: (isFocused) {
                                        setState(() {
                                          _isUFocused = isFocused;
                                          log('uFocused - $_isUFocused');
                                        });
                                      },
                                      child: TextFormField(
                                        textAlignVertical:
                                            TextAlignVertical.center,
                                        controller: _userNameController,
                                        style: TextStyle(
                                            fontSize:
                                                ResponsiveCheck.isSmallScreen(
                                                        context)
                                                    ? 15
                                                    : 20),
                                        decoration: InputDecoration(
                                          contentPadding: EdgeInsets.zero,
                                          filled: true,
                                          fillColor: _isUFocused
                                              ? Colors.white
                                              : Colors.grey.shade100,
                                          prefixIcon: Image.asset(
                                            'assets/login_icons/username.png',
                                            height: size.width * .06,
                                            width: size.width * .06,
                                            color:
                                                _isUFocused ? appColor : null,
                                          ),
                                          hintText: "User name",
                                          border: InputBorder.none,
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: const BorderSide(
                                              color: appColor,
                                              width: 1,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          focusColor: appColor,
                                        ),
                                        validator: (value) {
                                          if (value!.isEmpty) {
                                            return "user name cannot be empty";
                                          }
                                          return null;
                                        },
                                        onFieldSubmitted: (_) {
                                          FocusScope.of(context)
                                              .requestFocus(_passwordFocus);
                                        },
                                      ),
                                    ),
                                    onKey: (RawKeyEvent event) {
                                      if (event.isKeyPressed(
                                          LogicalKeyboardKey.tab)) {
                                        var currentText =
                                            _userNameController.text;
                                        var textWithoutTab =
                                            currentText.replaceAll("\t", "");
                                        _userNameController.text =
                                            textWithoutTab;
                                        FocusScope.of(context)
                                            .requestFocus(_passwordFocus);
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.fromLTRB(size.width * .05,
                                size.width * .02, size.width * .05, 0),
                            child: Card(
                              elevation: 10,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              child: SizedBox(
                                height: ResponsiveCheck.isLargeScreen(context)
                                    ? size.height * .075
                                    : ResponsiveCheck.isMediumScreen(context)
                                        ? size.height * .065
                                        : size.height * .055,
                                width: ResponsiveCheck.isSmallScreen(context)
                                    ? size.width * .35
                                    : size.width * .25,
                                child: Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme:
                                        ThemeData().colorScheme.copyWith(
                                              primary: appColor,
                                            ),
                                  ),
                                  child: RawKeyboardListener(
                                    focusNode: _passwordFocus,
                                    child: Focus(
                                      onFocusChange: (isFocused) {
                                        setState(() {
                                          _isPFocused = isFocused;
                                          log('pFocused - $_isPFocused');
                                        });
                                      },
                                      child: TextFormField(
                                        textAlignVertical:
                                            TextAlignVertical.center,
                                        obscureText: _passwordVisible,
                                        controller: _passwordController,
                                        style: TextStyle(
                                            fontSize:
                                                ResponsiveCheck.isSmallScreen(
                                                        context)
                                                    ? 15
                                                    : 20),
                                        decoration: InputDecoration(
                                          contentPadding: EdgeInsets.zero,
                                          suffixIcon: IconButton(
                                            icon: Icon(_passwordVisible
                                                ? Icons.visibility_rounded
                                                : Icons.visibility_off_rounded),
                                            onPressed: () {
                                              setState(() {
                                                _passwordVisible =
                                                    !_passwordVisible;
                                              });
                                            },
                                          ),
                                          filled: true,
                                          fillColor: _isPFocused
                                              ? Colors.white
                                              : Colors.grey.shade100,
                                          prefixIcon: Image.asset(
                                            'assets/login_icons/password.png',
                                            height: size.width * .06,
                                            width: size.width * .06,
                                            color:
                                                _isPFocused ? appColor : null,
                                          ),
                                          hintText: "Password",
                                          border: InputBorder.none,
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: const BorderSide(
                                              color: appColor,
                                              width: 1,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          focusColor: appColor,
                                        ),
                                        onFieldSubmitted: (value) {
                                          FocusScope.of(context).unfocus();
                                          if (widget.dataFromDB.isEmpty) {
                                            Future.delayed(
                                                const Duration(seconds: 1), () {
                                              Fluttertoast.showToast(
                                                  msg:
                                                      'Internet may not be available, Please check your connection and Restart the app.',
                                                  toastLength:
                                                      Toast.LENGTH_SHORT);
                                              loginController.reset();
                                            });
                                          } else {
                                            if (_userNameController.text
                                                    .toString()
                                                    .isNotEmpty &&
                                                _passwordController.text
                                                    .toString()
                                                    .isNotEmpty) {
                                              if (widget.dataFromDB.any((e) =>
                                                      e.get<String>(
                                                          'user_id') ==
                                                      _userNameController.text
                                                          .toString()) ==
                                                  false) {
                                                log(_userNameController.text
                                                    .toString());
                                                Future.delayed(
                                                    const Duration(seconds: 1),
                                                    () {
                                                  Fluttertoast.showToast(
                                                      msg:
                                                          'You have entered an invalid username',
                                                      toastLength:
                                                          Toast.LENGTH_LONG);
                                                  loginController.reset();
                                                });
                                              } else {
                                                if (_passwordController.text
                                                        .toString() !=
                                                    widget.dataFromDB[widget
                                                            .dataFromDB
                                                            .indexWhere((e) =>
                                                                e.get<String>(
                                                                    'user_id') ==
                                                                _userNameController
                                                                    .text
                                                                    .toString())]
                                                        .get<String>(
                                                            'password')) {
                                                  Future.delayed(
                                                      const Duration(
                                                          seconds: 1), () {
                                                    Fluttertoast.showToast(
                                                        msg:
                                                            'The password you entered is incorrect',
                                                        toastLength:
                                                            Toast.LENGTH_LONG);
                                                    loginController.reset();
                                                  });
                                                } else {
                                                  /// set Remember Me Values
                                                  SharedPreferences
                                                          .getInstance()
                                                      .then(
                                                    (prefs) {
                                                      prefs.setBool(
                                                          "rememberMe",
                                                          _isRememberChecked);
                                                      prefs.setString(
                                                          'userName',
                                                          _userNameController
                                                              .text);
                                                      prefs.setString(
                                                          'password',
                                                          _passwordController
                                                              .text);
                                                      prefs.setString(
                                                          'loggedInTime',
                                                          DateFormat().format(
                                                              DateTime.now()));
                                                      prefs.setBool(
                                                          'isLoggedOut', false);
                                                    },
                                                  );
                                                  Future.delayed(
                                                      const Duration(
                                                          seconds: 1), () {
                                                    Fluttertoast.showToast(
                                                        msg:
                                                            'You have successfully logged in.',
                                                        toastLength:
                                                            Toast.LENGTH_LONG);
                                                    Future.delayed(
                                                        const Duration(
                                                            seconds: 1), () {
                                                      Navigator.pushReplacement(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (_) =>
                                                              HomeScreen(
                                                            accType: widget
                                                                .dataFromDB[widget
                                                                    .dataFromDB
                                                                    .indexWhere((e) =>
                                                                        e.get<String>(
                                                                            'user_id') ==
                                                                        _userNameController
                                                                            .text
                                                                            .toString())]
                                                                .get<String>(
                                                                    'account_type')!,
                                                            authorization: widget
                                                                .dataFromDB[widget
                                                                    .dataFromDB
                                                                    .indexWhere((e) =>
                                                                        e.get<String>(
                                                                            'user_id') ==
                                                                        _userNameController
                                                                            .text
                                                                            .toString())]
                                                                .get<String>(
                                                                    'authorization')!,
                                                            refreshToken: widget
                                                                .dataFromDB[widget
                                                                    .dataFromDB
                                                                    .indexWhere((e) =>
                                                                        e.get<String>(
                                                                            'user_id') ==
                                                                        _userNameController
                                                                            .text
                                                                            .toString())]
                                                                .get<String>(
                                                                    'refresh_token')!,
                                                            userId: widget
                                                                .dataFromDB[widget
                                                                    .dataFromDB
                                                                    .indexWhere((e) =>
                                                                        e.get<String>(
                                                                            'user_id') ==
                                                                        _userNameController
                                                                            .text
                                                                            .toString())]
                                                                .get<String>(
                                                                    'user_id')!,
                                                            profileId: widget
                                                                .dataFromDB[widget
                                                                    .dataFromDB
                                                                    .indexWhere((e) =>
                                                                        e.get<String>(
                                                                            'user_id') ==
                                                                        _userNameController
                                                                            .text
                                                                            .toString())]
                                                                .get<int>(
                                                                    'profile_id')!,
                                                            distCenterId: widget
                                                                .dataFromDB[widget
                                                                    .dataFromDB
                                                                    .indexWhere((e) =>
                                                                        e.get<String>(
                                                                            'user_id') ==
                                                                        _userNameController
                                                                            .text
                                                                            .toString())]
                                                                .get<int>(
                                                                    'distribution_center_id')!,
                                                            distCenterName: widget
                                                                .dataFromDB[widget
                                                                    .dataFromDB
                                                                    .indexWhere((e) =>
                                                                        e.get<String>(
                                                                            'user_id') ==
                                                                        _userNameController
                                                                            .text
                                                                            .toString())]
                                                                .get<String>(
                                                                    'distribution_center_name')!,
                                                          ),
                                                        ),
                                                      ).whenComplete(() =>
                                                          loginController
                                                              .reset());
                                                    });
                                                  });
                                                }
                                              }
                                            } else {
                                              Future.delayed(
                                                  const Duration(seconds: 1),
                                                  () {
                                                Fluttertoast.showToast(
                                                    msg:
                                                        'Please enter required details');
                                                loginController.reset();
                                              });
                                            }
                                          }
                                        },
                                        validator: (value) {
                                          if (value!.isEmpty) {
                                            return "password cannot be empty";
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                    onKey: (RawKeyEvent event) {
                                      if (event.isKeyPressed(
                                          LogicalKeyboardKey.tab)) {
                                        var currentText =
                                            _passwordController.text;
                                        var textWithoutTab =
                                            currentText.replaceAll("\t", "");
                                        _passwordController.text =
                                            textWithoutTab;
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.fromLTRB(
                              size.width * .03,
                              size.width * .02,
                              size.width * .05,
                              0,
                            ),
                            child: SizedBox(
                              height: size.height * .05,
                              width: size.width,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Checkbox(
                                    activeColor: appColor,
                                    value: _isRememberChecked,
                                    onChanged: (bool? newValue) {
                                      setState(() {
                                        _isRememberChecked = newValue!;
                                      });
                                      log('_isRememberChecked - $_isRememberChecked');
                                    },
                                  ),
                                  Text(
                                    'Remember me',
                                    style: TextStyle(
                                      fontSize:
                                          ResponsiveCheck.isSmallScreen(context)
                                              ? size.width * .02
                                              : ResponsiveCheck.isMediumScreen(
                                                      context)
                                                  ? size.width * .015
                                                  : size.width * .01,
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.fromLTRB(size.width * .05,
                                size.width * .01, size.width * .05, 0),
                            child: RoundedLoadingButton(
                              color: appColor,
                              borderRadius: 0,
                              elevation: 10,
                              height: ResponsiveCheck.isLargeScreen(context)
                                  ? size.height * .07
                                  : ResponsiveCheck.isMediumScreen(context)
                                      ? size.height * .06
                                      : size.height * .045,
                              width: ResponsiveCheck.isLargeScreen(context)
                                  ? size.width * .1
                                  : ResponsiveCheck.isMediumScreen(context)
                                      ? size.width * .14
                                      : size.width * .18,
                              successIcon: Icons.check_rounded,
                              failedIcon: Icons.close_rounded,
                              successColor: Colors.green,
                              errorColor: appColor,
                              controller: loginController,
                              onPressed: () {
                                FocusScope.of(context).unfocus();
                                if (widget.dataFromDB.isEmpty) {
                                  Future.delayed(const Duration(seconds: 1),
                                      () {
                                    Fluttertoast.showToast(
                                        msg:
                                            'Internet may not be available, Please check your connection and Restart the app.',
                                        toastLength: Toast.LENGTH_SHORT);
                                    loginController.reset();
                                  });
                                } else {
                                  if (_userNameController.text
                                          .toString()
                                          .isNotEmpty &&
                                      _passwordController.text
                                          .toString()
                                          .isNotEmpty) {
                                    if (widget.dataFromDB.any((e) =>
                                            e.get<String>('user_id') ==
                                            _userNameController.text
                                                .toString()) ==
                                        false) {
                                      log(_userNameController.text.toString());
                                      Future.delayed(const Duration(seconds: 1),
                                          () {
                                        Fluttertoast.showToast(
                                            msg:
                                                'You have entered an invalid username',
                                            toastLength: Toast.LENGTH_LONG);
                                        loginController.reset();
                                      });
                                    } else {
                                      if (_passwordController.text.toString() !=
                                          widget.dataFromDB[widget.dataFromDB
                                                  .indexWhere((e) =>
                                                      e.get<String>(
                                                          'user_id') ==
                                                      _userNameController.text
                                                          .toString())]
                                              .get<String>('password')) {
                                        Future.delayed(
                                            const Duration(seconds: 1), () {
                                          Fluttertoast.showToast(
                                              msg:
                                                  'The password you entered is incorrect',
                                              toastLength: Toast.LENGTH_LONG);
                                          loginController.reset();
                                        });
                                      } else {
                                        /// set Remember Me Values
                                        SharedPreferences.getInstance().then(
                                          (prefs) {
                                            prefs.setBool("rememberMe",
                                                _isRememberChecked);
                                            prefs.setString('userName',
                                                _userNameController.text);
                                            prefs.setString('password',
                                                _passwordController.text);
                                            prefs.setString(
                                                'loggedInTime',
                                                DateFormat()
                                                    .format(DateTime.now()));
                                            prefs.setBool('isLoggedOut', false);
                                          },
                                        );
                                        Future.delayed(
                                            const Duration(seconds: 1), () {
                                          Fluttertoast.showToast(
                                              msg:
                                                  'You have successfully logged in.',
                                              toastLength: Toast.LENGTH_LONG);
                                          Future.delayed(
                                              const Duration(seconds: 1), () {
                                            Navigator.pushReplacement(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => HomeScreen(
                                                  accType: widget
                                                      .dataFromDB[widget
                                                          .dataFromDB
                                                          .indexWhere((e) =>
                                                              e.get<String>(
                                                                  'user_id') ==
                                                              _userNameController
                                                                  .text
                                                                  .toString())]
                                                      .get<String>(
                                                          'account_type')!,
                                                  authorization: widget
                                                      .dataFromDB[widget
                                                          .dataFromDB
                                                          .indexWhere((e) =>
                                                              e.get<String>(
                                                                  'user_id') ==
                                                              _userNameController
                                                                  .text
                                                                  .toString())]
                                                      .get<String>(
                                                          'authorization')!,
                                                  refreshToken: widget
                                                      .dataFromDB[widget
                                                          .dataFromDB
                                                          .indexWhere((e) =>
                                                              e.get<String>(
                                                                  'user_id') ==
                                                              _userNameController
                                                                  .text
                                                                  .toString())]
                                                      .get<String>(
                                                          'refresh_token')!,
                                                  userId: widget
                                                      .dataFromDB[widget
                                                          .dataFromDB
                                                          .indexWhere((e) =>
                                                              e.get<String>(
                                                                  'user_id') ==
                                                              _userNameController
                                                                  .text
                                                                  .toString())]
                                                      .get<String>('user_id')!,
                                                  profileId: widget
                                                      .dataFromDB[widget
                                                          .dataFromDB
                                                          .indexWhere((e) =>
                                                              e.get<String>(
                                                                  'user_id') ==
                                                              _userNameController
                                                                  .text
                                                                  .toString())]
                                                      .get<int>('profile_id')!,
                                                  distCenterId: widget
                                                      .dataFromDB[widget
                                                          .dataFromDB
                                                          .indexWhere((e) =>
                                                              e.get<String>(
                                                                  'user_id') ==
                                                              _userNameController
                                                                  .text
                                                                  .toString())]
                                                      .get<int>(
                                                          'distribution_center_id')!,
                                                  distCenterName: widget
                                                      .dataFromDB[widget
                                                          .dataFromDB
                                                          .indexWhere((e) =>
                                                              e.get<String>(
                                                                  'user_id') ==
                                                              _userNameController
                                                                  .text
                                                                  .toString())]
                                                      .get<String>(
                                                          'distribution_center_name')!,
                                                ),
                                              ),
                                            ).whenComplete(
                                                () => loginController.reset());
                                          });
                                        });
                                      }
                                    }
                                  } else {
                                    Future.delayed(const Duration(seconds: 1),
                                        () {
                                      Fluttertoast.showToast(
                                          msg: 'Please enter required details');
                                      loginController.reset();
                                    });
                                  }
                                }
                              },
                              child: Text(
                                'Login',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize:
                                        ResponsiveCheck.isLargeScreen(context)
                                            ? size.width * .015
                                            : ResponsiveCheck.isMediumScreen(
                                                    context)
                                                ? size.width * .02
                                                : size.width * .024),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )

            /// >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> MOBILE DEVICE LOGIN SCREEN >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

            : GestureDetector(
                onTap: () {
                  FocusScope.of(context).requestFocus(FocusNode());
                  if (!currentFocus.hasPrimaryFocus) {
                    currentFocus.unfocus();
                  }
                },
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Container(
                    height: size.height,
                    width: size.width,
                    color: Colors.white,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            Padding(
                              padding: EdgeInsets.fromLTRB(
                                size.width * .05,
                                size.width * .03,
                                size.width * .05,
                                size.width * .05,
                              ),
                              child: SizedBox(
                                height: size.width * .5,
                                width: size.width * .5,
                                child: Image.asset('assets/logo/new_logo.png'),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.fromLTRB(size.width * .05,
                                  size.width * .03, size.width * .05, 0),
                              child: Card(
                                elevation: 10,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: ThemeData()
                                        .colorScheme
                                        .copyWith(primary: appColor),
                                  ),
                                  child: FocusScope(
                                    child: Focus(
                                      onFocusChange: (isFocused) {
                                        setState(() {
                                          _isUFocused = isFocused;
                                          log('uFocused - $_isUFocused');
                                        });
                                      },
                                      child: TextFormField(
                                        controller: _userNameController,
                                        decoration: InputDecoration(
                                          filled: true,
                                          fillColor: _isUFocused
                                              ? Colors.white
                                              : Colors.grey.shade100,
                                          prefixIcon: Image.asset(
                                            'assets/login_icons/username.png',
                                            height: size.width * .15,
                                            width: size.width * .15,
                                            color:
                                                _isUFocused ? appColor : null,
                                          ),
                                          labelText: "User name",
                                          border: InputBorder.none,
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: const BorderSide(
                                              color: appColor,
                                              width: 1,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          focusColor: appColor,
                                        ),
                                        validator: (value) {
                                          if (value!.isEmpty) {
                                            return "user name cannot be empty";
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.fromLTRB(size.width * .05,
                                  size.width * .03, size.width * .05, 0),
                              child: Card(
                                elevation: 10,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                child: Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme:
                                        ThemeData().colorScheme.copyWith(
                                              primary: appColor,
                                            ),
                                  ),
                                  child: FocusScope(
                                    child: Focus(
                                      onFocusChange: (isFocused) {
                                        setState(() {
                                          _isPFocused = isFocused;
                                          log('pFocused - $_isPFocused');
                                        });
                                      },
                                      child: TextFormField(
                                        obscureText: _passwordVisible,
                                        controller: _passwordController,
                                        decoration: InputDecoration(
                                          suffixIcon: IconButton(
                                            icon: Icon(_passwordVisible
                                                ? Icons.visibility_rounded
                                                : Icons.visibility_off_rounded),
                                            onPressed: () {
                                              setState(() {
                                                _passwordVisible =
                                                    !_passwordVisible;
                                              });
                                            },
                                          ),
                                          filled: true,
                                          fillColor: _isPFocused
                                              ? Colors.white
                                              : Colors.grey.shade100,
                                          prefixIcon: Image.asset(
                                            'assets/login_icons/password.png',
                                            height: size.width * .15,
                                            width: size.width * .15,
                                            color:
                                                _isPFocused ? appColor : null,
                                          ),
                                          labelText: "Password",
                                          border: InputBorder.none,
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: const BorderSide(
                                              color: appColor,
                                              width: 1,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          focusColor: appColor,
                                        ),
                                        validator: (value) {
                                          if (value!.isEmpty) {
                                            return "password cannot be empty";
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.fromLTRB(
                                size.width * .03,
                                size.width * .02,
                                size.width * .05,
                                0,
                              ),
                              child: SizedBox(
                                height: size.height * .05,
                                width: size.width,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Checkbox(
                                      activeColor: appColor,
                                      value: _isRememberChecked,
                                      onChanged: (bool? newValue) {
                                        setState(() {
                                          _isRememberChecked = newValue!;
                                        });
                                        log('_isRememberChecked - $_isRememberChecked');
                                      },
                                    ),
                                    Text(
                                      'Remember me',
                                      style: TextStyle(
                                        fontSize: size.width * .04,
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.fromLTRB(size.width * .05,
                                  size.width * .1, size.width * .05, 0),
                              child: SizedBox(
                                height: size.width * .12,
                                width: size.width * .4,
                                child: RoundedLoadingButton(
                                  color: appColor,
                                  borderRadius: 0,
                                  elevation: 10,
                                  height: size.width * .12,
                                  width: size.width * .35,
                                  successIcon: Icons.check_rounded,
                                  failedIcon: Icons.close_rounded,
                                  successColor: Colors.green,
                                  errorColor: appColor,
                                  controller: loginController,
                                  onPressed: () {
                                    FocusScope.of(context).unfocus();
                                    if (widget.dataFromDB.isEmpty) {
                                      loginController.error();
                                      Future.delayed(const Duration(seconds: 1),
                                          () {
                                        Fluttertoast.showToast(
                                            msg:
                                                'Internet may not be available, Please check your connection and Restart the app.',
                                            toastLength: Toast.LENGTH_SHORT);
                                        loginController.reset();
                                      });
                                    } else {
                                      if (_userNameController.text
                                              .toString()
                                              .isNotEmpty &&
                                          _passwordController.text
                                              .toString()
                                              .isNotEmpty) {
                                        if (widget.dataFromDB.any((e) =>
                                                e.get<String>('user_id') ==
                                                _userNameController.text
                                                    .toString()) ==
                                            false) {
                                          log(_userNameController.text
                                              .toString());
                                          loginController.error();
                                          Future.delayed(
                                              const Duration(seconds: 1), () {
                                            Fluttertoast.showToast(
                                                msg:
                                                    'You have entered an invalid username',
                                                toastLength: Toast.LENGTH_LONG);
                                            loginController.reset();
                                          });
                                        } else {
                                          if (_passwordController.text
                                                  .toString() !=
                                              widget.dataFromDB[widget
                                                      .dataFromDB
                                                      .indexWhere((e) =>
                                                          e.get<String>(
                                                              'user_id') ==
                                                          _userNameController
                                                              .text
                                                              .toString())]
                                                  .get<String>('password')) {
                                            loginController.error();
                                            Future.delayed(
                                                const Duration(seconds: 1), () {
                                              Fluttertoast.showToast(
                                                  msg:
                                                      'The password you entered is incorrect',
                                                  toastLength:
                                                      Toast.LENGTH_LONG);
                                              loginController.reset();
                                            });
                                          } else {
                                            /// set Remember Me Values
                                            SharedPreferences.getInstance()
                                                .then(
                                              (prefs) {
                                                prefs.setBool("rememberMe",
                                                    _isRememberChecked);
                                                prefs.setString('userName',
                                                    _userNameController.text);
                                                prefs.setString('password',
                                                    _passwordController.text);
                                                prefs.setString(
                                                    'loggedInTime',
                                                    DateFormat().format(
                                                        DateTime.now()));
                                                prefs.setBool(
                                                    'isLoggedOut', false);
                                              },
                                            );

                                            loginController.success();
                                            Future.delayed(
                                                const Duration(seconds: 1), () {
                                              Fluttertoast.showToast(
                                                  msg:
                                                      'You have successfully logged in.',
                                                  toastLength:
                                                      Toast.LENGTH_LONG);
                                              Future.delayed(
                                                  const Duration(seconds: 1),
                                                  () {
                                                Navigator.pushReplacement(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) => HomeScreen(
                                                      accType: widget
                                                          .dataFromDB[widget
                                                              .dataFromDB
                                                              .indexWhere((e) =>
                                                                  e.get<String>(
                                                                      'user_id') ==
                                                                  _userNameController
                                                                      .text
                                                                      .toString())]
                                                          .get<String>(
                                                              'account_type')!,
                                                      authorization: widget
                                                          .dataFromDB[widget
                                                              .dataFromDB
                                                              .indexWhere((e) =>
                                                                  e.get<String>(
                                                                      'user_id') ==
                                                                  _userNameController
                                                                      .text
                                                                      .toString())]
                                                          .get<String>(
                                                              'authorization')!,
                                                      refreshToken: widget
                                                          .dataFromDB[widget
                                                              .dataFromDB
                                                              .indexWhere((e) =>
                                                                  e.get<String>(
                                                                      'user_id') ==
                                                                  _userNameController
                                                                      .text
                                                                      .toString())]
                                                          .get<String>(
                                                              'refresh_token')!,
                                                      userId: widget
                                                          .dataFromDB[widget
                                                              .dataFromDB
                                                              .indexWhere((e) =>
                                                                  e.get<String>(
                                                                      'user_id') ==
                                                                  _userNameController
                                                                      .text
                                                                      .toString())]
                                                          .get<String>(
                                                              'user_id')!,
                                                      profileId: widget
                                                          .dataFromDB[widget
                                                              .dataFromDB
                                                              .indexWhere((e) =>
                                                                  e.get<String>(
                                                                      'user_id') ==
                                                                  _userNameController
                                                                      .text
                                                                      .toString())]
                                                          .get<int>(
                                                              'profile_id')!,
                                                      distCenterId: widget
                                                          .dataFromDB[widget
                                                              .dataFromDB
                                                              .indexWhere((e) =>
                                                                  e.get<String>(
                                                                      'user_id') ==
                                                                  _userNameController
                                                                      .text
                                                                      .toString())]
                                                          .get<int>(
                                                              'distribution_center_id')!,
                                                      distCenterName: widget
                                                          .dataFromDB[widget
                                                              .dataFromDB
                                                              .indexWhere((e) =>
                                                                  e.get<String>(
                                                                      'user_id') ==
                                                                  _userNameController
                                                                      .text
                                                                      .toString())]
                                                          .get<String>(
                                                              'distribution_center_name')!,
                                                    ),
                                                  ),
                                                ).whenComplete(() =>
                                                    loginController.reset());
                                              });
                                            });
                                          }
                                        }
                                      } else {
                                        loginController.error();
                                        Future.delayed(
                                            const Duration(seconds: 1), () {
                                          Fluttertoast.showToast(
                                              msg:
                                                  'Please enter required details');
                                          loginController.reset();
                                        });
                                      }
                                    }
                                  },
                                  child: Text(
                                    'Login',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: size.width * .05),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  void _loadUserNamePassword() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      var userName = prefs.getString("userName") ?? "";
      var password = prefs.getString("password") ?? "";
      var rememberMe = prefs.getBool("rememberMe") ?? false;
      log('rememberMe - $rememberMe');
      log('userName - $userName');
      log('password - $password');
      if (rememberMe) {
        _userNameController.text = userName;
        _passwordController.text = password;
        if (_userNameController.text.toString().isNotEmpty &&
            _passwordController.text.toString().isNotEmpty) {
          setState(() {
            _isRememberChecked = true;
          });
        } else {
          setState(() {
            _isRememberChecked = false;
          });
        }
      }
    } catch (e) {
      log(e.toString());
    }
  }

  Future<bool> showExitPopup() async {
    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Center(child: Text('Exit App')),
            content: const Text('Do you want to exit the App?'),
            actions: [
              SizedBox(
                height: MediaQuery.of(context).size.height * .075,
                width: MediaQuery.of(context).size.width,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(
                          left: MediaQuery.of(context).size.width * .05),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: appColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        onPressed: () => Navigator.of(context).pop(false),
                        //return false when click on "NO"
                        child: const Text('No'),
                      ),
                    ),
                    Expanded(
                        child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(
                              right: MediaQuery.of(context).size.width * .05),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: appColor,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20))),
                            onPressed: () => Navigator.of(context).pop(true),
                            //return true when click on "Yes"
                            child: const Text('Yes'),
                          ),
                        ),
                      ],
                    ))
                  ],
                ),
              )
            ],
          ),
        ) ??
        false;
  }
}
