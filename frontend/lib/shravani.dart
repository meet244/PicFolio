// ignore_for_file: prefer_const_constructors

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';

import 'package:photoz/screens/home_left.dart';
import 'package:photoz/screens/horizon_face.dart';
import 'package:photoz/screens/library.dart';
import 'package:photoz/screens/settings.dart';
import 'package:photoz/screens/shared.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';
import 'package:share_plus/share_plus.dart';

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

  var allselected = [];
  var sharing = 0;

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

  Future<void> _onSend() async {
    // Implement your send logic here
    print(allselected);

    try {
      final tempDir = await getTemporaryDirectory();

      // Create temporary files for each image
      final tempFiles = <File>[];
      for (int i = 0; i < allselected.length; i++) {
        final imageId = allselected[i];
        final mainImageBytes = await fetchMainImage(imageId);
        allselected[imageId] = mainImageBytes;
        // Save the main image to a temporary file
        final tempFile = File('${tempDir.path}/temp_image_$i.png');
        await tempFile.writeAsBytes(mainImageBytes);
        tempFiles.add(tempFile);
      }

      // Share the multiple images using the share_plus package
      await Share.shareFiles(
        tempFiles.map((file) => file.path).toList(),
        text: 'I shared these images from my PicFolio app. Try them out!',
        subject: 'Image Sharing',
      );
    } catch (e) {
      print('Error sharing images: $e');
      // Handle the error, e.g., show a snackbar or log the error
    }

    setState(() {
      allselected.clear(); // Clear selected images after sending
    });
  }

  Future<void> _onDelete() async {
    // Implement your delete logic here
    print(allselected);

    // Call delete image API here
    var imgs = allselected.join(',');
    final response = await http
        .delete(Uri.parse('http://${widget.ip}:7251/api/delete/meet244/$imgs'));
    if (response.statusCode == 200) {
      print('Image deleted');
      // remove the deleted images from the grid
      setState(() {
        allselected.clear();
      });
    } else {
      throw Exception('Failed to delete image');
    }
  }

  void _onAdd() {
    // Implement your add logic here
    print(allselected);
    setState(() {
      allselected.clear(); // Clear selected images after sending
    });
  }

  Future<void> _editDate() async {
    // Implement your edit date logic here
    // get a date from calendar
    final DateTime? picked = await showDatePicker(
      context: context,
      // initialDate: selectedDate,
      firstDate: DateTime(2015, 8),
      lastDate: DateTime(2101),
    );
    if (picked == null) {
      return;
    }
    var date = (picked.toString().split(" ")[0]);
    var imgs = allselected.join(',');
    final response = await http.post(
      Uri.parse('http://${widget.ip}:7251/api/redate'),
      body: {
        'username': 'meet244',
        'date': date,
        'id': imgs,
      },
    );
    if (response.statusCode == 200) {
      print('Dates Updated');
      setState(() {
        allselected.clear();
      });
      // remove the deleted images from the grid
    } else {
      throw Exception('Failed to update date');
    }

    setState(() {
      allselected.clear(); // Clear selected images after sending
    });
  }

  Future<void> _moveToFamily() async {
    // Implement your move to family logic here
    print(allselected);
    final response = await http.post(
      Uri.parse('http://${widget.ip}:7251/api/shared/move'),
      body: {
        'username': 'meet244',
        'asset_id': allselected.join(','),
      },
    );
    if (response.statusCode == 200) {
      print('Image Shared');
    } else {
      throw Exception('Failed to move to share');
    }
    setState(() {
      allselected.clear(); // Clear selected images after sending
    });
  }

  Future<List<int>> fetchMainImage(int imageId) async {
    var url = 'http://${widget.ip}:7251/api/asset/meet244/$imageId';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      throw Exception('Failed to load preview image ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Stack(children: [
            // a top layer to show download progress
            PageView(
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
            if (sharing != 0)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 20),
                      Text('Fetching $sharing of ${allselected.length} images'),
                    ],
                  ),
                ),
              ),
          ]),
          bottomNavigationBar: allselected.length == 0
              ? SalomonBottomBar(
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
                )
              : NavigationBar(
                  indicatorColor: Colors.transparent,
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.share_outlined),
                      label: 'Share',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.delete_outlined),
                      label: 'Delete',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.add_outlined),
                      label: 'Add to',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.edit_calendar_outlined),
                      label: 'Edit date',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.groups_outlined),
                      label: 'Move to shared',
                    ),
                  ],
                  onDestinationSelected: (int index) {
                    // Handle the click event based on the index of the selected destination
                    switch (index) {
                      case 0:
                        // Handle share action
                        _onSend();
                        setState(() {
                          sharing = 1;
                        });
                        break;
                      case 1:
                        // Handle delete action
                        _onDelete();
                        break;
                      case 2:
                        // Handle add to action
                        _onAdd();
                        break;
                      case 3:
                        // Handle edit date action
                        _editDate();
                        break;
                      case 4:
                        // Handle move action
                        _moveToFamily();
                        break;
                    }
                  },
                ),
        ));
  }
}
