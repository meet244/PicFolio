import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';

import 'package:photoz/widgets/gridImages.dart';

void main() {
  // runApp(MySplash());
  runApp(MyApp('192.168.0.106'));
}

class MySplash extends StatefulWidget {
  @override
  _MySplashState createState() => _MySplashState();
}

class _MySplashState extends State<MySplash> {
  String? ipAddress;
  bool ipFound = false;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    findIPAddress();
  }

  Future<void> findIPAddress() async {
    if (ipFound) return; // Exit if IP address is already found
    for (int i = 0; i < 256; i++) {
      for (int j = 0; j < 256; j++) {
        final String currentTestIP = '192.168.$i.$j';
        try {
          final Socket socket = await Socket.connect(currentTestIP, 7251,
              timeout: Duration(milliseconds: 20));
          print('Found IP: $currentTestIP');
          setState(() {
            ipAddress = currentTestIP;
            ipFound = true;
          });
          socket.destroy();
          return; // Exit after finding IP
        } catch (e) {
          print('IP: $currentTestIP, Error: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (ipFound) {
      _navigatorKey.currentState!.pushReplacement(
        MaterialPageRoute(
          builder: (context) => MyApp(ipAddress!),
        ),
      );
    }

    return SizedBox(
      child: Navigator(
        key: _navigatorKey,
        onGenerateRoute: (settings) => MaterialPageRoute(
          builder: (context) {
            return const Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Image(
                      image: AssetImage('images/logo.png'),
                      width: 200,
                      height: 200,
                    ),
                    SizedBox(height: 20),
                    CircularProgressIndicator(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class MyApp extends StatefulWidget {
  final String ip;

  MyApp(this.ip);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Map<String, List<int>> images = {};
  Map<int, List<int>> loadedImages = {};
  List<int> allImages = [];

  @override
  void initState() {
    super.initState();
    fetchImages();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
    overlays: [SystemUiOverlay.top]);
  }

  Future<void> fetchImages() async {
    final response = await http.post(
      Uri.parse('http://${widget.ip}:7251/api/list/general'),
      body: {'username': 'meet244'},
    );
    if (response.statusCode == 200) {
      Map<String, dynamic> data = jsonDecode(response.body);
      List<String> keys = data.keys.toList();
      keys = keys.reversed.toList();

      Map<String, dynamic> reversedMap = {};

      for (var key in keys) {
        reversedMap[key] = data[key];
      }

      Map<String, List<int>> data2 = reversedMap.map((key, value) {
        return MapEntry(
            key, (value as List<dynamic>).map((e) => e as int).toList());
      });

      // add all images to allImages list
      for (var value in data2.values) {
        allImages.addAll(value);
      }

      setState(() {
        images = data2;
      });
    } else {
      throw Exception('Failed to load images');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('PicFolio'),
        ),
        body: ImageGridView(
          ip: widget.ip,
          images: images,
          gridCount: 3,
          noImageIcon: Icons.image_outlined,
          mainEmptyMessage: 'No images/videos yet!',
          secondaryEmptyMessage: 'Upload Images/Videos to see them here!',
        ),
      ),
    );
  }
}