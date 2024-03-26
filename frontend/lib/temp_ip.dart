// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:photoz/shravani.dart';


class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      darkTheme: ThemeData.dark(),
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

  @override
  void initState() {
    super.initState();
    // Focus the text field when the screen starts
    Future.delayed(Duration.zero, () => FocusScope.of(context).requestFocus());
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
              if (ipAddress.isNotEmpty && ipAddress != '127.0.0.1') {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MyHomePage(ipAddress),
                  ),
                );
              }
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final ipAddress = ipController.text;
          if (ipAddress.isNotEmpty && ipAddress != '127.0.0.1') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => MyHomePage(ipAddress),
              ),
            );
          }
        },
        child: Icon(Icons.arrow_forward),
      ),
    );
  }

  @override
  void dispose() {
    ipController.dispose();
    super.dispose();
  }
}