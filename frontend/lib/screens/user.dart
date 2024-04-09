// ignore_for_file: prefer_const_constructors

import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photoz/color.dart';
import 'package:photoz/globals.dart';
import 'package:photoz/widgets/gridImages.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;
  final String ip;

  const UserProfileScreen(this.ip, this.userId, {super.key});

  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  List<dynamic> images = [];
  String name = '';
  int cnt = 0;
  List<int> selectedImages = [];

  Future<void> _onSend() async {
    // Implement your send logic here
    print(selectedImages);

    try {
      final tempDir = await getTemporaryDirectory();

      // Create temporary files for each image
      final tempFiles = <File>[];
      for (int i = 0; i < selectedImages.length; i++) {
        final imageId = selectedImages[i];
        final mainImageBytes = await fetchMainImage(imageId);
        // selectedImages[imageId] = mainImageBytes;
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
      selectedImages.clear(); // Clear selected images after sending
    });
  }

  Future<List<int>> fetchMainImage(int imageId) async {
    var url = '${Globals.ip}:7251/api/asset/${Globals.username}/$imageId';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      throw Exception('Failed to load preview image ${response.statusCode}');
    }
  }

  Future<void> _onDelete() async {
    // Implement your delete logic here
    print(selectedImages);

    // Call delete image API here
    var imgs = selectedImages.join(',');
    final response = await http
        .delete(Uri.parse('${Globals.ip}:7251/api/delete/${Globals.username}/$imgs'));
    if (response.statusCode == 200) {
      print('Image deleted');
      // remove the deleted images from the grid
      setState(() {
        selectedImages.clear();
      });
    } else {
      throw Exception('Failed to delete image');
    }
  }

  void _onAdd() {
    // Implement your add logic here
    print(selectedImages);
    setState(() {
      selectedImages.clear(); // Clear selected images after sending
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
    var imgs = selectedImages.join(',');
    final response = await http.post(
      Uri.parse('${Globals.ip}:7251/api/redate'),
      body: {
        'username': '${Globals.username}',
        'date': date,
        'id': imgs,
      },
    );
    if (response.statusCode == 200) {
      print('Dates Updated');
      setState(() {
        selectedImages.clear();
      });
      // remove the deleted images from the grid
    } else {
      throw Exception('Failed to update date');
    }

    setState(() {
      selectedImages.clear(); // Clear selected images after sending
    });
  }

  Future<void> _moveToFamily() async {
    // Implement your move to family logic here
    print(selectedImages);
    final response = await http.post(
      Uri.parse('${Globals.ip}:7251/api/shared/move'),
      body: {
        'username': '${Globals.username}',
        'asset_id': selectedImages.join(','),
      },
    );
    if (response.statusCode == 200) {
      print('Image Shared');
    } else {
      throw Exception('Failed to move to share');
    }
    setState(() {
      selectedImages.clear(); // Clear selected images after sending
    });
  }

  @override
  void initState() {
    super.initState();
    fetchname();
    fetchImages();
  }

  Future<void> fetchImages() async {
    final response = await http.get(Uri.parse(
        '${Globals.ip}:7251/api/list/face/${Globals.username}/${widget.userId}'));
    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);

      setState(() {
        images = data;
      });
    } else {
      throw Exception('Failed to load images');
    }
  }

  Future<void> fetchname() async {
    // wait for 0.1 seconds
    // await Future.delayed(const Duration(milliseconds: 100));
    final response = await http.get(Uri.parse(
        '${Globals.ip}:7251/api/face/name/${Globals.username}/${widget.userId}'));
    if (response.statusCode == 200) {
      var d = json.decode(response.body);
      var n = d[0];
      if (n != null && n != 'Unknown') {
        setState(() {
          name = n;
          cnt = d[1];
        });
      } else {
        setState(() {
          name = "Add a name";
          cnt = d[1];
        });
      }
    } else {
      throw Exception('Failed to load name');
    }
  }

  Future<void> rename(String name) async {
    final response = await http.get(Uri.parse(
        '${Globals.ip}:7251/api/face/rename/${Globals.username}/${widget.userId}/${name}'));
    if (response.statusCode == 200) {
      setState(() {
        this.name = name;
      });
    } else {
      throw Exception('Failed to load name');
    }
  }

  Future<void> removeName() async {
    final response = await http.post(
        Uri.parse('${Globals.ip}:7251/api/face/noname'),
        body: {'username': '${Globals.username}', 'name': widget.userId});
    if (response.statusCode == 200) {
      setState(() {
        // remove name from var
        name = 'Add a name';
      });
    } else {
      throw Exception('Failed to load name');
    }
  }

  Future<void> removeFace(List<int> images) async {
    // Implement your share logic here
    final response = await http
        .post(Uri.parse('${Globals.ip}:7251/api/face/remove'), body: {
      'username': '${Globals.username}',
      'asset_id': images.join(','),
      'face_id': widget.userId,
    });
    if (response.statusCode == 200) {
      print('Face removed');
    } else {
      throw Exception('Failed to remove face');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(useMaterial3: true, colorScheme: lightColorScheme),
      darkTheme: ThemeData(useMaterial3: true, colorScheme: darkColorScheme),
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: Text((selectedImages.isEmpty)
              ? 'Profile'
              : (selectedImages.length == 1)
                  ? '${selectedImages.length} item'
                  : '${selectedImages.length} items'),
          leading: (selectedImages.length > 0)
              ? GestureDetector(
                  onTap: () {
                    // Clear selection
                    setState(() {
                      selectedImages.length = 0;
                    });
                  },
                  child: Padding(
                    padding: EdgeInsets.all(10.0),
                    child: Icon(
                      Icons.close,
                      size: 32.0,
                    ),
                  ),
                )
              : (selectedImages.length == 0)
                  ? GestureDetector(
                      onTap: () {
                        // Handle back button tap
                        Navigator.pop(context);
                      },
                      child: Padding(
                        padding: EdgeInsets.all(10.0),
                        child: Icon(
                          Icons.arrow_back,
                          size: 32.0,
                        ),
                      ),
                    )
                  : null,
          actions: <Widget>[
            if (selectedImages.length > 0)
              GestureDetector(
                onTap: () {
                  // Handle delete icon tap
                  _onDelete();
                },
                child: Padding(
                  padding: EdgeInsets.all(10.0),
                  child: Icon(
                    Icons.delete_outline,
                    size: 32.0,
                  ),
                ),
              ),
            if (selectedImages.length > 0)
              GestureDetector(
                onTap: () {
                  // Handle share icon tap
                  _onSend();
                },
                child: Padding(
                  padding: EdgeInsets.all(10.0),
                  child: Icon(
                    Icons.share_outlined,
                    size: 32.0,
                  ),
                ),
              ),
            if (selectedImages.length > 0)
              PopupMenuButton(
                itemBuilder: (BuildContext context) {
                  return [
                    PopupMenuItem(
                      child: Row(
                        children: [
                          Icon(Icons.add_outlined),
                          SizedBox(width: 8.0),
                          Text('Add to Album'),
                        ],
                      ),
                      onTap: () {
                        // Handle edit option tap
                        _onAdd();
                      },
                    ),
                    PopupMenuItem(
                      child: Row(
                        children: [
                          Icon(Icons.edit_calendar_outlined),
                          SizedBox(width: 8.0),
                          Text('Edit Date'),
                        ],
                      ),
                      onTap: () {
                        // Handle copy option tap
                        _editDate();
                      },
                    ),
                    PopupMenuItem(
                      child: Row(
                        children: [
                          Icon(Icons.groups_outlined),
                          SizedBox(width: 8.0),
                          Text('add to shared'),
                        ],
                      ),
                      onTap: () {
                        // Handle move option tap
                        _moveToFamily();
                      },
                    ),
                    PopupMenuItem(
                      child: Row(
                        children: const [
                          Icon(Icons.person_remove_outlined),
                          SizedBox(width: 8.0),
                          Text('Remove photos'),
                        ],
                      ),
                      onTap: () {
                        // Handle move option tap
                        removeFace(selectedImages);
                      },
                    ),
                  ];
                },
                child: Padding(
                  padding: EdgeInsets.all(10.0),
                  child: Icon(
                    Icons.more_vert_outlined,
                    size: 32.0,
                  ),
                ),
              ),
            if (selectedImages.isEmpty)
              PopupMenuButton<String>(
                itemBuilder: (BuildContext context) {
                  return [
                    PopupMenuItem<String>(
                      value: 'rename',
                      child: Text('Edit Name'),
                    ),
                    PopupMenuItem<String>(
                      value: 'noname',
                      child: Text('Remove Name'),
                    ),
                  ];
                },
                onSelected: (String value) {
                  // Handle menu item selection
                  if (value == 'rename') {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        String newName = '';
                        return AlertDialog(
                          title: Text('Enter Name'),
                          content: TextField(
                            autofocus: true,
                            maxLength: 30, // Add maximum length limit
                            onChanged: (value) {
                              newName = value;
                            },
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                if (newName.length >= 30) {
                                  return;
                                } else {
                                  Navigator.of(context).pop();
                                  rename(newName);
                                }
                              },
                              child: Text('Save'),
                            ),
                          ],
                        );
                      },
                    );
                    // Do something for Item 1
                  } else if (value == 'noname') {
                    removeName();
                  }
                },
              ),
          ],
        ),
        body: SingleChildScrollView(
          physics: ClampingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: '${Globals.ip}:7251/api/face/image/${Globals.username}/${widget.userId}',
                        width: 100.0,
                        height: 100.0,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16.0),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (name == "Add a name") {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                String newName = '';
                                return AlertDialog(
                                  title: Text('Enter Name'),
                                  content: TextField(
                                    autofocus: true,
                                    maxLength: 30, // Add maximum length limit
                                    onChanged: (value) {
                                      newName = value;
                                    },
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                      child: Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        if (newName.length >= 30) {
                                          showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return AlertDialog(
                                                title: Text('Error'),
                                                content: Text(
                                                    'Name should be less than 30 characters.'),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () {
                                                      Navigator.of(context)
                                                          .pop();
                                                    },
                                                    child: Text('OK'),
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                        } else {
                                          Navigator.of(context).pop();
                                          rename(newName);
                                        }
                                      },
                                      child: Text('Save'),
                                    ),
                                  ],
                                );
                              },
                            );
                          }
                        },
                        child: Text(
                          name,
                          style: const TextStyle(
                              fontSize: 25.0, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '$cnt photos',
                        style: const TextStyle(fontSize: 16.0),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20.0),
              ImageGridView(
                ip: Globals.ip,
                images: images,
                gridCount: 3,
                noImageIcon: Icons.image_outlined,
                mainEmptyMessage: "No Images Found",
                secondaryEmptyMessage: "Images will appear here",
                isNormal: true,
                onSelectionChanged: (selected) {
                  setState(() {
                    selectedImages = selected;
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
