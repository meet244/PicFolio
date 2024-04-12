import 'package:flutter/material.dart';
import 'package:photoz/color.dart';
import 'package:photoz/screens/splash.dart';

void main() {
  // runApp(MyHomePage('127.0.0.1'));
  // runApp(MyHomePage('192.168.0.107'));

  // runApp(MyApp());
  // runApp(LoginPage());
  runApp(MaterialApp(
    theme: ThemeData(useMaterial3: true, colorScheme: lightColorScheme),
    darkTheme: ThemeData(useMaterial3: true, colorScheme: darkColorScheme),
    debugShowCheckedModeBanner: false,
    home: const SplashScreen(),
    ));
}
