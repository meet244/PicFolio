import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:photoz/color.dart';
import 'package:photoz/functions/selectedImages.dart';
import 'package:photoz/globals.dart';
import 'package:photoz/screens/selectScreen.dart';
import 'package:photoz/widgets/gridImages.dart';
import 'package:http/http.dart' as http;

class UserProfileScreen extends StatefulWidget {
  final String userId;

  const UserProfileScreen(this.userId, {super.key});

  @override
  // ignore: library_private_types_in_public_api
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  List<dynamic> images = [];
  String name = '';
  int cnt = 0;
  List<int> selectedImages = [];
  bool imageLoad = false;
  bool nameLoad = false;

  @override
  void initState() {
    super.initState();
    fetchname();
    fetchImages();
  }

  Future<void> fetchImages() async {
    final response = await http.get(Uri.parse(
        '${Globals.ip}/api/list/face/${Globals.username}/${widget.userId}'));
    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);

      setState(() {
        images = data;
      });
      imageLoad = true;
      if (imageLoad && nameLoad) {
        setState(() {});
      }
    } else {
      throw Exception('Failed to load images');
    }
  }

  Future<void> fetchname() async {
    // wait for 0.1 seconds
    // await Future.delayed(const Duration(milliseconds: 100));
    final response = await http.get(Uri.parse(
        '${Globals.ip}/api/face/name/${Globals.username}/${widget.userId}'));
    if (response.statusCode == 200) {
      var d = json.decode(response.body);
      var n = d[0];
      nameLoad = true;
      name = (n != null && n != 'Unknown') ? n : "Add a name";
      cnt = d[1];
      if (imageLoad && nameLoad) {
        setState(() {});
      }
    } else {
      throw Exception('Failed to load name');
    }
  }

  Future<void> rename(String name) async {
    final response = await http.get(Uri.parse(
        '${Globals.ip}/api/face/rename/${Globals.username}/${widget.userId}/$name'));
    if (response.statusCode == 200) {
      setState(() {
        this.name = name;
      });
    } else {
      throw Exception('Failed to load name');
    }
  }

  Future<void> removeName() async {
    final response = await http.post(Uri.parse('${Globals.ip}/api/face/noname'),
        body: {'username': Globals.username, 'name': widget.userId});
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
    final response =
        await http.post(Uri.parse('${Globals.ip}/api/face/remove'), body: {
      'username': Globals.username,
      'asset_id': images.join(','),
      'face_id': widget.userId,
    });
    if (response.statusCode == 200) {
      if (kDebugMode) print('Face removed');
    } else {
      throw Exception('Failed to remove face');
    }
  }

  @override
  Widget build(BuildContext context) {
    bool finalLoad = imageLoad && nameLoad;
    return MaterialApp(
      theme: ThemeData(useMaterial3: true, colorScheme: lightColorScheme),
      darkTheme: ThemeData(useMaterial3: true, colorScheme: darkColorScheme),
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: Text((selectedImages.isEmpty)
              ? name
              : (selectedImages.length == 1)
                  ? '${selectedImages.length} item'
                  : '${selectedImages.length} items'),
          leading: (selectedImages.isNotEmpty)
              ? GestureDetector(
                  onTap: () {
                    // Clear selection
                    setState(() {
                      selectedImages.length = 0;
                    });
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(10.0),
                    child: Icon(
                      Icons.close,
                      size: 32.0,
                    ),
                  ),
                )
              : (selectedImages.isEmpty)
                  ? GestureDetector(
                      onTap: () {
                        // Handle back button tap
                        Navigator.pop(context);
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(10.0),
                        child: Icon(
                          Icons.arrow_back,
                          size: 32.0,
                        ),
                      ),
                    )
                  : null,
          actions: <Widget>[
            if (selectedImages.isNotEmpty)
              GestureDetector(
                onTap: () {
                  // Handle delete icon tap
                  onDelete(context, selectedImages);
                },
                child: const Padding(
                  padding: EdgeInsets.all(10.0),
                  child: Icon(
                    Icons.delete_outline,
                    size: 32.0,
                  ),
                ),
              ),
            if (selectedImages.isNotEmpty)
              GestureDetector(
                onTap: () {
                  // Handle share icon tap
                  onSend(context, selectedImages);
                },
                child: const Padding(
                  padding: EdgeInsets.all(10.0),
                  child: Icon(
                    Icons.share_outlined,
                    size: 32.0,
                  ),
                ),
              ),
            if (selectedImages.isNotEmpty)
              PopupMenuButton(
                itemBuilder: (BuildContext context) {
                  return [
                    PopupMenuItem(
                      child: const Row(
                        children: [
                          Icon(Icons.add_outlined),
                          SizedBox(width: 8.0),
                          Text('Add to Album'),
                        ],
                      ),
                      onTap: () {
                        // Handle edit option tap
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SelectAlbumsScreen(),
                          ),
                        ).then((selectedAlbum) {
                          // Use the selectedAlbum value here
                          if (selectedAlbum != null) {
                            // Handle the selected album
                            onAddToAlbum(selectedAlbum, selectedImages)
                                .then((value) {
                              if (value) {
                                setState(() {
                                  selectedImages.clear();
                                });
                              }
                            });
                          }
                        });
                      },
                    ),
                    PopupMenuItem(
                      child: const Row(
                        children: [
                          Icon(Icons.edit_calendar_outlined),
                          SizedBox(width: 8.0),
                          Text('Edit Date'),
                        ],
                      ),
                      onTap: () {
                        // Handle copy option tap
                        editDate(context, selectedImages);
                      },
                    ),
                    PopupMenuItem(
                      child: const Row(
                        children: [
                          Icon(Icons.groups_outlined),
                          SizedBox(width: 8.0),
                          Text('add to shared'),
                        ],
                      ),
                      onTap: () {
                        // Handle move option tap
                        moveToShared(selectedImages);
                      },
                    ),
                    PopupMenuItem(
                      child: const Row(
                        children: [
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
                child: const Padding(
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
                    const PopupMenuItem<String>(
                      value: 'rename',
                      child: Text('Edit Name'),
                    ),
                    const PopupMenuItem<String>(
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
                          title: const Text('Enter Name'),
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
                              child: const Text('Cancel'),
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
                              child: const Text('Save'),
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
        body: (!finalLoad)
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: ClipOval(
                            child: CachedNetworkImage(
                              imageUrl:
                                  '${Globals.ip}/api/face/image/${Globals.username}/${widget.userId}',
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
                                        title: const Text('Enter Name'),
                                        content: TextField(
                                          autofocus: true,
                                          maxLength:
                                              30, // Add maximum length limit
                                          onChanged: (value) {
                                            newName = value;
                                          },
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            },
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              if (newName.length >= 30) {
                                                showDialog(
                                                  context: context,
                                                  builder:
                                                      (BuildContext context) {
                                                    return AlertDialog(
                                                      title:
                                                          const Text('Error'),
                                                      content: const Text(
                                                          'Name should be less than 30 characters.'),
                                                      actions: [
                                                        TextButton(
                                                          onPressed: () {
                                                            Navigator.of(
                                                                    context)
                                                                .pop();
                                                          },
                                                          child:
                                                              const Text('OK'),
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
                                            child: const Text('Save'),
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
                                    fontSize: 25.0,
                                    fontWeight: FontWeight.bold),
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
