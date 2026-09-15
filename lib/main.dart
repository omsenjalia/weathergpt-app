import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/theme/app_theme.dart';
import 'core/services/api_client.dart';
import 'router/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await Hive.initFlutter();
  await Hive.openBox('settings');
  final savedLang =
      Hive.box('settings').get('language', defaultValue: 'en') as String;
  ApiClient.instance.setLanguage(savedLang);
  await Hive.openBox('farm_profile');
  await Hive.openBox('saved_locations');
  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('en'),
        Locale('hi'),
        Locale('gu'),
        Locale('mr'),
        Locale('ta'),
        Locale('te'),
        Locale('kn'),
        Locale('ml'),
        Locale('bn'),
      ],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      startLocale: Locale(savedLang),
      child: const ProviderScope(child: WeatherGptApp()),
    ),
  );
}

class WeatherGptApp extends StatelessWidget {
  const WeatherGptApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp.router(
        title: 'WeatherGPT',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        routerConfig: appRouter,
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        locale: context.locale,
      );
}
