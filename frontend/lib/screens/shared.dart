import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:photoz/globals.dart';
import 'package:photoz/screens/selectScreen.dart';
import 'package:photoz/screens/settings.dart';
import 'package:photoz/widgets/gridImages.dart';

import '../functions/selectedImages.dart';

class Shared extends StatefulWidget {
  // final Function(List<int>) onSelect;

  const Shared({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _SharedState createState() => _SharedState();
}

class _SharedState extends State<Shared> {
  List<String> names = [
    "All users",
  ];
  int selectedIndex = 1;
  bool isLoading = true;

  List<int> allselected = [];
  List<dynamic> allimgs = [];

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    final response = await http.post(
        Uri.parse('${Globals.ip}/api/list/shared/users'),
        body: {'username': Globals.username});
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // print(data);
      setState(() {
        names.addAll(List<String>.from(data));
        selectedIndex = names.indexOf(Globals.username);
        isLoading = false;
        fetchImages();
      });
    } else {
      throw Exception('Failed to fetch data');
    }
  }

  Future<void> fetchImages() async {
    var url = '';
    if (selectedIndex == 0) {
      url = '${Globals.ip}/api/list/shared/all';
    } else {
      url = '${Globals.ip}/api/list/shared';
    }
    final response = await http.post(
      Uri.parse(url),
      body: {'username': Globals.username, 'of_user': names[selectedIndex]},
    );
    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      var imgs = jsonData;
      allimgs = imgs;
      setState(() {
        allselected.clear();
      });
    } else {
      throw Exception('Failed to fetch images');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            (allselected.isEmpty)
                ? const Text("PicFolio")
                : (allselected.length == 1)
                    ? Text("${allselected.length} item")
                    : Text(
                        "${allselected.length} items"), // Show count if images are selected
          ],
        ),
        leading: (allselected.isNotEmpty)
            ? IconButton(
                onPressed: () {
                  // Clear selection
                  setState(() {
                    allselected.clear();
                  });
                },
                icon: const Icon(
                  Icons.close,
                  size: 32.0,
                ),
              )
            : null,
        actions: <Widget>[
          if (allselected.isEmpty)
            IconButton(
              onPressed: () {
                // Open settings page
                var ret = getimage(Globals.ip, context);
                ret.then((value) {
                  if (value) {
                    if (kDebugMode) print('Image Uploaded');
                  }
                });
              },
              icon: const Icon(Icons.add_a_photo_outlined, size: 32.0),
            ),
          if (allselected.isEmpty)
            IconButton(
              onPressed: () {
                // Open settings page
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SettingsPage(Globals.ip),
                  ),
                );
              },
              icon: const Icon(Icons.settings_outlined, size: 32.0),
            ),
          if (allselected.isNotEmpty)
            IconButton(
              onPressed: () {
                var ret = onDelete(context, allselected);
                ret.then((value) {
                  if (value) {
                    setState(() {
                      allselected.clear();
                    });
                  }
                });
              },
              icon: const Icon(Icons.delete_outlined, size: 32.0),
            ),
          if (allselected.isNotEmpty)
            IconButton(
              onPressed: () {
                var ret = onSend(context, allselected);
                ret.then((value) {
                  if (value) {
                    setState(() {
                      allselected.clear();
                    });
                  }
                });
              },
              icon: const Icon(Icons.share_outlined, size: 32.0),
            ),
          if (allselected.isNotEmpty)
            PopupMenuButton(
              itemBuilder: (BuildContext context) {
                return [
                  PopupMenuItem(
                    child: const Row(
                      children: [
                        Icon(Icons.add_outlined, size: 32.0),
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
                          onAddToAlbum(selectedAlbum, allselected)
                              .then((value) {
                            if (value) {
                              setState(() {
                                allimgs.clear();
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
                        Icon(Icons.edit_calendar_outlined, size: 32.0),
                        SizedBox(width: 8.0),
                        Text('Edit Date'),
                      ],
                    ),
                    onTap: () {
                      // Handle copy option tap
                      editDate(context, allselected);
                    },
                  ),
                  PopupMenuItem(
                    child: const Row(
                      children: [
                        Icon(Icons.group_off_outlined, size: 32.0),
                        SizedBox(width: 8.0),
                        Text('Remove from shared'),
                      ],
                    ),
                    onTap: () {
                      // Handle move option tap
                      unMoveToShared(allselected);
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
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 127,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount:
                          names.length + 2, // Add 2 extra items for the gaps
                      itemBuilder: (context, index) {
                        if (index == 0 || index == names.length + 1) {
                          // Render empty SizedBox for the gaps
                          return const SizedBox(width: 10);
                        } else {
                          // Render the actual list items
                          final actualIndex = index - 1;
                          return GestureDetector(
                            onTap: () {
                              if (selectedIndex == actualIndex) {
                                return;
                              }
                              selectedIndex = actualIndex;
                              fetchImages();
                            },
                            child: SizedBox(
                              // width: 80,
                              width: 85,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  children: [
                                    CircleAvatar(
                                      radius: 30,
                                      backgroundColor:
                                          selectedIndex == actualIndex
                                              ? Colors.primaries[actualIndex %
                                                  Colors.primaries.length]
                                              : Colors.primaries[actualIndex %
                                                      Colors.primaries.length]
                                                  .withOpacity(0.15),
                                      child: Text(
                                        names[actualIndex].isEmpty
                                            ? ''
                                            : names[actualIndex][0]
                                                .toUpperCase(),
                                        style: TextStyle(
                                          color: selectedIndex == actualIndex
                                              ? Colors.white
                                              : Colors.primaries[actualIndex %
                                                  Colors.primaries.length],
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(top: 5),
                                      child: Text(
                                        names[actualIndex],
                                        style: const TextStyle(fontSize: 16),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                  ImageGridView(
                    ip: Globals.ip,
                    images: allimgs,
                    gridCount: 3,
                    noImageIcon: Icons.person_outline,
                    mainEmptyMessage: 'No shared photos found',
                    secondaryEmptyMessage:
                        'Ask ${names[selectedIndex]} to share some photos',
                    onSelectionChanged: (selectedImages) {
                      setState(() {
                        allselected = selectedImages;
                      });
                    },
                  ),
                ],
              ),
            ),
    );
  }
}
