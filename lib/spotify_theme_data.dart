import 'package:flutter/material.dart';

const spotifyWidgetColor = Color(0xFF121212);
final spotifyThemeData = ThemeData(
  primarySwatch: Colors.green,
  brightness: Brightness.dark,
  scaffoldBackgroundColor: spotifyWidgetColor,
  appBarTheme: const AppBarTheme(
    backgroundColor: spotifyWidgetColor,
    elevation: 0,
    iconTheme: IconThemeData(color: Colors.white),
    titleTextStyle: TextStyle(
        color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
  ),
  buttonTheme: ButtonThemeData(
    buttonColor: Colors.green,
    textTheme: ButtonTextTheme.primary,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
    ),
  ),
  expansionTileTheme: ExpansionTileThemeData(
    backgroundColor: spotifyWidgetColor,
    collapsedBackgroundColor: spotifyWidgetColor,
    collapsedShape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(25),
    ),
  ),
  textTheme: TextTheme(
    titleLarge: const TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.bold,
      fontSize: 28,
    ),
    titleMedium: const TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.bold,
      fontSize: 20,
    ),
    titleSmall: const TextStyle(
      color: Colors.white,
      // fontWeight: FontWeight.bold,
      fontSize: 18,
    ),
    bodyMedium: const TextStyle(color: Colors.white70),
    labelMedium: TextStyle(color: Colors.grey[400]),
  ),
  inputDecorationTheme: InputDecorationTheme(
    fillColor: spotifyWidgetColor,
    filled: true,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide: const BorderSide(color: Colors.white24),
    ),
    labelStyle: const TextStyle(color: Colors.white54),
  ),
  iconTheme: const IconThemeData(color: Colors.white),
  dividerTheme: const DividerThemeData(
    color: Colors.white10,
    thickness: 1,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ButtonStyle(
      backgroundColor: MaterialStateProperty.all(Colors.green),
      foregroundColor: MaterialStateProperty.all(Colors.white),
      shape: MaterialStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    ),
  ),
  listTileTheme: const ListTileThemeData(
    tileColor: Color(0xFF121212),
    textColor: Colors.white,
    iconColor: Colors.white54,
  ),
  switchTheme: SwitchThemeData(
    thumbColor: MaterialStateProperty.all(Colors.white),
    trackColor: MaterialStateProperty.all(Colors.green),
  ),
);
