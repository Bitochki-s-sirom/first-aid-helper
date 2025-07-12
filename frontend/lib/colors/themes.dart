import 'package:flutter/material.dart';
import 'colors.dart';

final ThemeData lightTheme = ThemeData(
  scaffoldBackgroundColor: kBackgroundColor,
  fontFamily: 'Montserrat',
  brightness: Brightness.light,
  textTheme: Typography.blackCupertino.copyWith(
    bodyLarge: TextStyle(color: kBackgroundColor, fontSize: 30),
    bodyMedium: TextStyle(color: kBackgroundColor, fontSize: 20),
    headlineSmall: TextStyle(color: kBackgroundColor, fontSize: 14),
  ),
);

final ThemeData darkTheme = ThemeData(
  scaffoldBackgroundColor: kDarkBackgroundColor,
  fontFamily: 'Montserrat',
  brightness: Brightness.dark,
  textTheme: Typography.whiteCupertino.copyWith(
    bodyLarge: TextStyle(color: kDarkBackgroundColor, fontSize: 30),
    bodyMedium: TextStyle(color: kDarkBackgroundColor, fontSize: 20),
    headlineSmall: TextStyle(color: kDarkBackgroundColor, fontSize: 14),
  ),
);
