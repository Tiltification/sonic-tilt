import 'package:flutter/material.dart';
import 'OneDScreen.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

void intializeHive () async {
  await Hive.initFlutter();
  await Hive.openBox("app_settings");
  await Hive.openBox("app_presets");
}

void main() async {
  await intializeHive ();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(      localizationsDelegates: [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
      supportedLocales: [
        const Locale('en', ''), // English, no country code
      ],
      title: '[App Name]',
      theme: ThemeData(
        primarySwatch: Colors.green,
          fontFamily: 'Sintony',
      ),
      home: OneDScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
