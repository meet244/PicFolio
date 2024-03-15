import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:photoz/screens/settings.dart';
import 'dart:convert';
import 'screens/home_left.dart';
import 'package:photoz/screens/horizon_face.dart';
import 'package:photoz/screens/library.dart';

class MyHomePage extends StatefulWidget {
  String ip;

  MyHomePage(this.ip, {super.key});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  File? image;
  final _picker = ImagePicker();
  List imageList = [];

  Future<bool> getimage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      print("picked");
      if (await uploadimage(pickedFile)) {
        return true;
      }
      // print(pickedFile);
    } else {
      print("not selected");
      return false;
    }
    return false;
  }

  Future<bool> uploadimage(XFile xFile) async {
    var url = Uri.parse('http://${widget.ip}:7251/api/upload');

    // Create FormData
    var formData = http.MultipartRequest('POST', url);
    formData.fields['username'] = 'meet244';

    // Convert XFile to bytes (or base64, depending on your server's requirements)
    final imageBytes = await xFile.readAsBytes();
    formData.files.add(http.MultipartFile.fromBytes('asset', imageBytes,
        filename: 'image.jpg')); // Adjust the filename as needed

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
    var url = Uri.parse('http://127.0.0.1:7251/api/list/general');

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

  int currentPageIndex = 0;
  @override
  Widget build(BuildContext context) {
    // final ThemeData theme = Theme.of(context);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Navigator(
        // Wrap with Navigator widget
        onGenerateRoute: (settings) {
          return MaterialPageRoute(
            builder: (context) => Scaffold(
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
                        )),
                  ),
                  GestureDetector(
                    onTap: () {
                      // open settings page
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => SettingsPage(widget.ip)),
                      );
                    },
                    child: Padding(
                        padding: EdgeInsets.all(10.0),
                        child: Icon(
                          Icons.account_circle_outlined,
                          size: 32.0,
                        )),
                  ),
                ],
              ),
              bottomNavigationBar: BottomNavigationBar(
                onTap: (int index) {
                  setState(() {
                    currentPageIndex = index;
                  });
                },
                currentIndex: currentPageIndex,
                items: const <BottomNavigationBarItem>[
                  BottomNavigationBarItem(
                    icon: Icon(Icons.photo_outlined),
                    label: 'Photos',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.photo_album_sharp),
                    label: 'Library',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.search),
                    label: 'Search',
                  ),
                ],
              ),
              body: <Widget>[
                /// Photos page
                HomeLeft(widget.ip),

                /// Notifications page
                Library(widget.ip),

                /// Messages page
                FaceListWidget(widget.ip),
              ][currentPageIndex],
            ),
          );
        },
      ),
    );
  }
}
