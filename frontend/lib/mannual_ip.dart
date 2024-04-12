import 'package:ai_barcode_scanner/ai_barcode_scanner.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:photoz/globals.dart';
import 'package:photoz/screens/login.dart';
import 'package:photoz/screens/qrScanner.dart';
import 'package:photoz/shravani.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'color.dart';

class IpAddressInputPage extends StatefulWidget {
  const IpAddressInputPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
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
    return MaterialApp(
      theme: ThemeData(useMaterial3: true, colorScheme: lightColorScheme),
      darkTheme: ThemeData(useMaterial3: true, colorScheme: darkColorScheme),
      title: 'PicFolio',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Enter IP Address'),
          actions: [
            IconButton(
              icon: const Icon(Icons.qr_code),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => QRScanner(
                      validator: (value) {
                        return value
                            .startsWith('https://picfolio.vercel.app/scan/');
                      },
                      canPop: true,
                      onScan: (String value) {
                        value = value.replaceAll(
                            'https://picfolio.vercel.app/scan/', '');
                        debugPrint(value);
                        SharedPreferences.getInstance().then((prefs) {
                          String? ipLast = prefs.getString('ips');
                          ipLast ??= '';
                          prefs.setString('ips', value);
                          if (kDebugMode) print("stored");
                        });
                        Globals.ip = value;

                        SharedPreferences.getInstance().then((prefs) {
                          final username = prefs.getString('username');
                          Navigator.pushReplacement(context,
                              MaterialPageRoute(builder: (context) {
                            if (username != null && username.isNotEmpty) {
                              return const MyHomePage();
                            }
                            return const LoginPage();
                          }));
                        });
                      },
                      onDetect: (p0) {},
                      onDispose: () {
                        debugPrint("Barcode scanner disposed!");
                      },
                      controller: MobileScannerController(
                        detectionSpeed: DetectionSpeed.noDuplicates,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: TextField(
              controller: ipController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
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
                    MaterialPageRoute(builder: (context) => const MyHomePage()),
                  );
                } else {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                  );
                }
              },
            ),
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
