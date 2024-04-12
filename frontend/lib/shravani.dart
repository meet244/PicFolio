import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:photoz/globals.dart';

import 'package:photoz/screens/home_left.dart';
import 'package:photoz/screens/horizon_face.dart';
import 'package:photoz/screens/library.dart';
import 'package:photoz/screens/shared.dart';
import "color.dart";

class MyHomePage extends StatefulWidget {

  const MyHomePage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  File? image;
  final _picker = ImagePicker();

  var _currentIndex = 0;
  final _pageController = PageController();

  var allselected = [];
  var sharing = 0;

  Future<bool> getimage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      if (kDebugMode) print("picked");
      if (await uploadimage(pickedFile)) {
        return true;
      }
    } else {
      if (kDebugMode) print("not selected");
      return false;
    }
    return false;
  }

  Future<bool> uploadimage(XFile xFile) async {
    var url = Uri.parse('${Globals.ip}/api/upload');
    var formData = http.MultipartRequest('POST', url);
    formData.fields['username'] = Globals.username;

    final imageBytes = await xFile.readAsBytes();
    formData.files.add(http.MultipartFile.fromBytes('asset', imageBytes,
        filename: 'image.jpg'));

    try {
      final response = await formData.send();
      if (response.statusCode == 200) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image uploaded successfully'),
            duration: Duration(seconds: 2),
          ),
        );
        return true;
      } else {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: ${response.reasonPhrase}'),
            duration: const Duration(seconds: 2),
          ),
        );
        return false;
      }
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error during upload: $e'),
          duration: const Duration(seconds: 2),
        ),
      );
      return false;
    }
  }

  void _onDestinationSelected(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.ease,
    );
  }

  @override
  Widget build(BuildContext context) {
    DateTime currentBackPressTime = DateTime.now();
    return MaterialApp(
      theme: ThemeData(useMaterial3: true, colorScheme: lightColorScheme),
      darkTheme: ThemeData(useMaterial3: true, colorScheme: darkColorScheme),
      title: 'PicFolio',
      debugShowCheckedModeBanner: false,
      // ignore: deprecated_member_use
      home: WillPopScope(
        onWillPop: () async {
          // check page no 
          if (_currentIndex == 0) {
            // check if back button is pressed twice
            if (DateTime.now().difference(currentBackPressTime) >
                const Duration(seconds: 2)) {
              // if not pressed twice
              // update current time
              currentBackPressTime = DateTime.now();
              // show snackbar
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Press back again to exit'),
                  duration: Duration(seconds: 2),
                ),
              );
              // return false
              return false;
            } else {
              // if pressed twice
              // exit app
              return true;
            }
          } else {
            // if not on first page
            // go to first page
            _onDestinationSelected(0);
            // return false
            return false;
          }
        },
        child: Scaffold(
          body: PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            children: const [
              /// Photos page
              HomeLeft(),
        
              /// Shared page
              Shared(),
        
              /// Notifications page
              Library(),
        
              /// Messages page
              FaceListWidget(),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: _onDestinationSelected,
            destinations: const <Widget>[
              NavigationDestination(
                selectedIcon: Icon(Icons.image),
                icon: Icon(Icons.image_outlined),
                label: 'Images',
              ),
              NavigationDestination(
                selectedIcon: Icon(Icons.group),
                icon: Icon(Icons.group_outlined),
                label: 'Shared',
              ),
              NavigationDestination(
                selectedIcon: Icon(Icons.photo_album),
                icon: Icon(Icons.photo_album_outlined),
                label: 'Albums',
              ),
              NavigationDestination(
                selectedIcon: Icon(Icons.search),
                icon: Icon(Icons.search_outlined),
                label: 'Search',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
