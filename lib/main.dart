import 'package:absolute_app/core/blocs/shop_repienish_bloc/shop_repienish_bloc.dart';
import 'package:absolute_app/core/utils/app_export.dart';
import 'package:absolute_app/core/utils/constants.dart';
import 'package:absolute_app/core/utils/platform_view_directory/platform_view_registry.dart';
import 'package:absolute_app/screens/web_screens/new_screens_by_vishal/shop_screen/widgets/no_transition_builder_for_web.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:universal_html/html.dart' as html;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Parse().initialize(
    keyApplicationId,
    keyParseServerUrl,
    clientKey: keyClientKey,
    autoSendSessionId: true,
  );
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
      .then((_) async {
    if (kIsWeb) {
      platformViewRegistry.registerViewFactory(
        'iframeElement',
        (int viewId) => html.IFrameElement()
          ..width = '640'
          ..height = '360'
          ..style.width = '100%'
          ..style.height = '100%'
          ..src = 'https://weblegs-scanit.changelogfy.com/'
          ..style.border = 'none',
      );
    }
    runApp(const MyApp());
  });
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [BlocProvider(create: (context) => ShopRepienishBloc())],
      child: MultiProvider(
        providers: [ChangeNotifierProvider(create: (_) => BusinessLogic())],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(pageTransitionsTheme: NoTransitionsOnWeb()),
          home: const SplashScreen(),
        ),
      ),
    );
  }
}
