import 'dart:ui';

import 'package:flutter/material.dart';

class LevelTheme {
//  static const mainDarkMode = Color(0xff292b2e);
  static const mainDarkMode = Color(0xff292bff);
//  static const mainLightMode = Color(0xffF2F2F2);
  static const mainLightMode = Color(0xff058986);
//  static const darkModeBlack = Color(0xff47586f);
  static const darkModeBlack = Color(0xff4758ff);
//  static const darkModeYellow = Color(0xffefed70); // Bubble color
//  static const darkModeYellow = Color(0xfff6890f); // PobbleBonk
  static const darkModeYellow = Color(0xff0e0901); // Crickets
//  static const darkModeYellow = Color(0xffa431c4); // Tuning
//  static const darkModeGreen = Color(0xff5bdc97);
//  static const darkModeGreen = Color(0xff91c618); //small bubble
//  static const darkModeGreen = Color(0xfff6890f); // PobbleBonk
  static const darkModeGreen = Color(0xff69b610); // Crickets
//  static const darkModeGreen = Color(0xff180e02); // Tuning
//  static const bgColor = Color(0xff2e2b2e);
//  static const bgColor = Color(0xff206503); // background PobbleBonk
  static const bgColor = Color(0xfff3ee01); // background Crickets
//  static const bgColor = Color(0xff3c038b); // background Tuning
//  static const textColor = Color(0xff47576E);
  static const textColor = Color(0xff4f88fa);
//  static const splashTextColor = Color.fromRGBO(50, 58, 69, 0.5);
  static const splashTextColor = Color.fromRGBO(11, 234, 234, 1.0);
//  static const splashHeading2Color = Color(0xff066449);
  static const splashHeading2Color = Color(0xff0664ff);
//  static const splashHeading3Color = Color(0xffF1DB6B);
  static const splashHeading3Color = Color(0xffF1DBff);
//  static const splashCard3Color = Color(0xff292A2E);
  static const splashCard3Color = Color(0xff295fff);

  static TextStyle htmlText = TextStyle(
      fontWeight: FontWeight.normal,
      color: LevelTheme.mainDarkMode,
      fontSize: 18,
      fontFamily: 'Sintony',
      decoration: TextDecoration.none);
  static TextStyle linkText = TextStyle(
      fontWeight: FontWeight.bold,
      color: LevelTheme.mainDarkMode,
      fontSize: 18,
      fontFamily: 'Sintony',
      decoration: TextDecoration.underline,
      decorationColor: LevelTheme.textColor);

  static TextStyle defaultText = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 32,
      decoration: TextDecoration.none,
      color: LevelTheme.textColor);
  static TextStyle currentText = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 32,
      decoration: TextDecoration.none,
      color: LevelTheme.darkModeYellow);
  static TextStyle dialogueText = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 32,
      decoration: TextDecoration.none,
      color: LevelTheme.darkModeGreen);
  static TextStyle errorText = TextStyle(
      fontWeight: FontWeight.bold,
      decoration: TextDecoration.none,
      color: LevelTheme.darkModeYellow
  );
  static TextStyle splashSubTitle = TextStyle(
    fontSize:24,
    decoration: TextDecoration.none,
    fontFamily: 'Sintony',
    fontStyle: FontStyle.normal,
    fontWeight: FontWeight.bold,
  );
  static TextStyle splashTitle = TextStyle(
    fontSize:40,
    wordSpacing: 2,
    decoration: TextDecoration.none,
    fontFamily: 'Sintony',
    fontStyle: FontStyle.normal,
    fontWeight: FontWeight.bold,
  );
  static TextStyle splashText = TextStyle(
    fontSize:16,
    decoration: TextDecoration.none,
    fontFamily: 'Sintony',
    fontStyle: FontStyle.normal,
    fontWeight: FontWeight.bold,
  );
  static ThemeData levelThemeData = ThemeData(
    textTheme: TextTheme(
      bodyText1: TextStyle(fontWeight: FontWeight.normal, fontSize: 20),
      bodyText2: TextStyle(fontWeight: FontWeight.normal, fontSize: 56),
    ).apply(
      bodyColor: darkModeYellow,
      displayColor: Colors.blue,
      decoration: TextDecoration.none,
    ),
    primaryColor: darkModeGreen,
    accentColor: bgColor,
  );
}
