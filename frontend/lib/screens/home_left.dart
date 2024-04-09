// ignore_for_file: prefer_const_constructors, prefer_is_empty, prefer_const_literals_to_create_immutables

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:photoz/functions/selectedImages.dart';
import 'package:photoz/globals.dart';
import 'package:photoz/screens/selectScreen.dart';
import 'package:photoz/screens/settings.dart';

import 'package:photoz/widgets/gridImages.dart';

class HomeLeft extends StatefulWidget {
  // final Function(List<int>) onSelect;

  HomeLeft({Key? key}) : super(key: key);

  @override
  _HomeLeftState createState() => _HomeLeftState();
}

class _HomeLeftState extends State<HomeLeft> {
  List<dynamic> images = []; // insges after fetching
  List<int> allselected = []; // selected images

  bool isLoading = false;
  int page = -1;
  bool bottomreached = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,overlays: [SystemUiOverlay.top]);

    fetchImages();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        fetchImages();
      }
    });
  }

  Future<void> fetchImages() async {
    if (!isLoading && !bottomreached) {
      setState(() {
        page++;
        isLoading = true;
      });
      final response = await http.post(
        Uri.parse('${Globals.ip}:7251/api/list/general'),
        body: {'username': Globals.username, "page": page.toString()},
      );
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);

        if (data.isEmpty) {
          bottomreached = true;
          print('Bottom Reached');
        }

        setState(() {
          images.addAll(data);
          isLoading = false;
        });

        print(images);
      } else {
        throw Exception('Failed to load images');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            (allselected.length == 0)
                ? Text("PicFolio")
                : (allselected.length == 1)
                    ? Text("${allselected.length} item")
                    : Text(
                        "${allselected.length} items"), // Show count if images are selected
          ],
        ),
        leading: (allselected.length > 0)
            ? IconButton(
                onPressed: () {
                  // Clear selection
                  setState(() {
                    allselected.clear();
                  });
                },
                icon: Icon(
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
                    print('Image Uploaded');
                  }
                });
              },
              icon: Icon(Icons.add_a_photo_outlined, size: 32.0),
            ),
          if (allselected.length == 0)
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
              icon: Icon(Icons.settings_outlined, size: 32.0),
            ),
          if (allselected.length > 0)
            IconButton(
              onPressed: () {
                var ret = onDelete(Globals.ip, context, allselected);
                ret.then((value) {
                  if (value) {
                    setState(() {
                      allselected.clear();
                    });
                  }
                });
              },
              icon: Icon(Icons.delete_outlined, size: 32.0),
            ),
          if (allselected.length > 0)
            IconButton(
              onPressed: () {
                var ret = onSend(Globals.ip, context, allselected);
                ret.then((value) {
                  if (value) {
                    setState(() {
                      allselected.clear();
                    });
                  }
                });
              },
              icon: Icon(Icons.share_outlined, size: 32.0),
            ),
          if (allselected.isNotEmpty)
            PopupMenuButton(
              itemBuilder: (BuildContext context) {
                return [
                  PopupMenuItem(
                    child: Row(
                      children: [
                        Icon(Icons.add_outlined, size: 32.0),
                        SizedBox(width: 8.0),
                        Text('Add to Album'),
                      ],
                    ),
                    onTap: () async {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SelectAlbumsScreen(Globals.ip),
                        ),
                      ).then((selectedAlbum) {
                        // Use the selectedAlbum value here
                        if (selectedAlbum != null) {
                          // Handle the selected album
                          onAddToAlbum(Globals.ip, selectedAlbum, allselected)
                              .then((value) {
                            if (value) {
                              setState(() {
                                allselected.clear();
                              });
                            }
                          });
                        }
                      });
                    },
                  ),
                  PopupMenuItem(
                    child: Row(
                      children: [
                        Icon(Icons.edit_calendar_outlined, size: 32.0),
                        SizedBox(width: 8.0),
                        Text('Edit Date'),
                      ],
                    ),
                    onTap: () {
                      // Handle copy option tap
                      editDate(Globals.ip, context, allselected);
                    },
                  ),
                  PopupMenuItem(
                    child: Row(
                      children: [
                        Icon(Icons.groups_outlined, size: 32.0),
                        SizedBox(width: 8.0),
                        Text('Add to shared'),
                      ],
                    ),
                    onTap: () {
                      // Handle move option tap
                      moveToShared(Globals.ip, allselected);
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
        ],
      ),
      body: (Globals.username == '' || isLoading)
          ? Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              controller: _scrollController,
              child: ImageGridView(
                ip: Globals.ip,
                images: images,
                gridCount: 3,
                noImageIcon: Icons.image_outlined,
                mainEmptyMessage: 'No images/videos yet!',
                secondaryEmptyMessage: 'Upload Images/Videos to see them here!',
                isNormal: true,
                onSelectionChanged: (selectedImages) {
                  setState(() {
                    allselected = selectedImages;
                  });
                },
                bottomload: !bottomreached,
              ),
            ),
    );
  }
}
