import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:convert';

import 'package:photoz/screens/home_left.dart';
import 'package:photoz/screens/horizon_face.dart';
import 'package:photoz/screens/library.dart';
import 'package:photoz/screens/settings.dart';
import 'package:photoz/screens/shared.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';

class MyHomePage extends StatefulWidget {
  String ip;

  MyHomePage(this.ip, {Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  File? image;
  final _picker = ImagePicker();

  var _currentIndex = 0;
  final _pageController = PageController();

  Future<bool> getimage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      print("picked");
      if (await uploadimage(pickedFile)) {
        return true;
      }
    } else {
      print("not selected");
      return false;
    }
    return false;
  }

  Future<bool> uploadimage(XFile xFile) async {
    var url = Uri.parse('http://${widget.ip}:7251/api/upload');
    var formData = http.MultipartRequest('POST', url);
    formData.fields['username'] = 'meet244';

    final imageBytes = await xFile.readAsBytes();
    formData.files.add(http.MultipartFile.fromBytes('asset', imageBytes,
        filename: 'image.jpg'));

    try {
      final response = await formData.send();
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Image uploaded successfully'),
            duration: Duration(seconds: 2),
          ),
        );
        return true;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: ${response.reasonPhrase}'),
            duration: Duration(seconds: 2),
          ),
        );
        return false;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error during upload: $e'),
          duration: Duration(seconds: 2),
        ),
      );
      return false;
    }
  }

  Future<void> startup() async {
    var url = Uri.parse('http://${widget.ip}:7251/api/list/general');
    var body = {'username': 'meet244'};
    var req = http.MultipartRequest('POST', url);
    req.fields.addAll(body);
    var res = await req.send();
    final resBody = await res.stream.bytesToString();
    if (res.statusCode == 200) {
      final jsonResponse = json.decode(resBody);
    } else {
      print(res.reasonPhrase);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Text("Picfolio"),
            ],
          ),
          actions: <Widget>[
            GestureDetector(
              onTap: getimage,
              child: Padding(
                padding: EdgeInsets.all(10.0),
                child: Icon(
                  Icons.add,
                  size: 32.0,
                ),
              ),
            ),
            Builder(
              builder: (context) => GestureDetector(
                onTap: () {
                  // Open settings page
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SettingsPage(widget.ip),
                    ),
                  );
                },
                child: Padding(
                  padding: EdgeInsets.all(10.0),
                  child: Icon(
                    Icons.account_circle_outlined,
                    size: 32.0,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: PageView(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          children: [
            /// Photos page
            HomeLeft(widget.ip),

            /// Shared page
            Shared(widget.ip),

            /// Notifications page
            Library(widget.ip),

            /// Messages page
            FaceListWidget(widget.ip),
          ],
        ),
        bottomNavigationBar: SalomonBottomBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
              _pageController.animateToPage(
                index,
                duration: Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            });
          },
          items: [
            /// Home
            SalomonBottomBarItem(
              icon: Icon(Icons.photo_outlined),
              title: Text("Photos"),
              selectedColor: const Color.fromARGB(255, 0, 86, 156),
            ),

            /// Likes
            SalomonBottomBarItem(
              icon: Icon(Icons.groups_outlined),
              title: Text("Shared"),
              selectedColor: Colors.blue,
            ),

            /// Search
            SalomonBottomBarItem(
              icon: Icon(Icons.photo_album_outlined),
              title: Text("Albums"),
              selectedColor: Colors.blue,
            ),

            /// Profile
            SalomonBottomBarItem(
              icon: Icon(Icons.search_outlined),
              title: Text("Search"),
              selectedColor: Colors.blue,
            ),
          ],
        ),
      ),
    );
  }
}
