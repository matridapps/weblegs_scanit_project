import 'package:absolute_app/core/utils/app_export.dart';
import 'package:fluttertoast/fluttertoast.dart';

const keyApplicationId = 'uc9gqlNy0ykz3ws8X1Kcf69k8kgIDLYYkZOv0RMa';
const keyClientKey = 'kOE90HhFp0VKOKspT8eRlZaPzobHnK7xkp8rJYSh';
const keyParseServerUrl = 'https://parseapi.back4app.com';

Future<bool> checkCameraPermission() async {
  bool requestPermission = false;
  if (await Permission.camera.request().isDenied) {
    // We didn't ask for permission yet or the permission has been denied before but not permanently.
    await Permission.camera.request();
    checkCameraPermission();
    requestPermission = false;
  }
  if (await Permission.camera.isPermanentlyDenied) {
    Fluttertoast.showToast(
        msg:
            'Cam permission is permanently denied\n Go to App Settings and allow us to use the camera permission');
    requestPermission = false;
  }
// You can can also directly ask the permission about its status.
  if (await Permission.location.isRestricted) {
    Fluttertoast.showToast(msg: 'Cam permission is restricted');
    // The OS restricts access, for example because of parental controls.
    requestPermission = false;
  }
  if (await Permission.camera.request().isGranted) {
    requestPermission = true;
  }
  return requestPermission;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Parse().initialize(keyApplicationId, keyParseServerUrl,
      clientKey: keyClientKey, autoSendSessionId: true);
  // checkCameraPermission();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
      .then((_) async {
    runApp(const MyApp());
  });
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => BusinessLogic(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          fontFamily: 'RobotoSerif',
        ),
        home: const SplashScreen(),
      ),
    );
  }
}
