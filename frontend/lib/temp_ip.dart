// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:photoz/globals.dart';
import 'package:photoz/screens/login.dart';
import 'package:photoz/shravani.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'color.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(useMaterial3: true, colorScheme: lightColorScheme),
      darkTheme: ThemeData(useMaterial3: true, colorScheme: darkColorScheme),
      title: 'PicFolio',
      debugShowCheckedModeBanner: false,
      home: IpAddressInputPage(),
    );
  }
}

class IpAddressInputPage extends StatefulWidget {
  @override
  _IpAddressInputPageState createState() => _IpAddressInputPageState();
}

class _IpAddressInputPageState extends State<IpAddressInputPage> {
  final ipController = TextEditingController();

  bool signed = false;

  @override
  void initState() {
    super.initState();
    // Focus the text field when the screen starts
    Future.delayed(Duration.zero, () => FocusScope.of(context).requestFocus());

    // check for username value in shared preferences
    SharedPreferences.getInstance().then((prefs) {
      final username = prefs.getString('username');
      if (username != null && username.isNotEmpty) {
        signed = true;
        Globals.username = username;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Enter IP Address'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: TextField(
            controller: ipController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Enter IP Address',
              labelText: 'IP Address',
            ),
            textAlign: TextAlign.center,
            autofocus: true, // Automatically opens the keyboard
            onSubmitted: (value) {
              final ipAddress = ipController.text;
              Globals.ip = ipAddress;
              if (signed) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => MyHomePage()),
                );
              } else {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => LoginPage(
                          )),
                );
              }
            },
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    ipController.dispose();
    super.dispose();
  }
}
