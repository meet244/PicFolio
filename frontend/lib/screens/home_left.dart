// ignore_for_file: prefer_const_constructors, prefer_is_empty, prefer_const_literals_to_create_immutables

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photoz/functions/selectedImages.dart';
import 'package:photoz/screens/selectScreen.dart';
import 'package:photoz/screens/settings.dart';

import 'package:photoz/widgets/gridImages.dart';
import 'package:share_plus/share_plus.dart';

class HomeLeft extends StatefulWidget {
  final String ip;
  // final Function(List<int>) onSelect;

  HomeLeft(
    this.ip,
    // this.onSelect,
  );

  @override
  _HomeLeftState createState() => _HomeLeftState();
}

class _HomeLeftState extends State<HomeLeft> {
  List<dynamic> images = [];
  // Map<int, List<int>> loadedImages = {};
  List<int> allImages = [];
  List<int> allselected = [];

  Future<List<int>> fetchMainImage(int imageId) async {
    var url = 'http://${widget.ip}:7251/api/asset/meet244/$imageId';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      throw Exception('Failed to load preview image ${response.statusCode}');
    }
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

  @override
  void initState() {
    super.initState();
    fetchImages();
    // SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,overlays: [SystemUiOverlay.top]);
  }

  Future<void> fetchImages() async {
    final response = await http.post(
      Uri.parse('http://${widget.ip}:7251/api/list/general'),
      body: {'username': 'meet244'},
    );
    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);

      setState(() {
        images = data;
      });
    } else {
      throw Exception('Failed to load images');
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
                var ret = getimage(widget.ip, context);
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
                    builder: (context) => SettingsPage(widget.ip),
                  ),
                );
              },
              icon: Icon(Icons.settings_outlined, size: 32.0),
            ),
          if (allselected.length > 0)
            IconButton(
              onPressed: () {
                var ret = onDelete(widget.ip, context, allselected);
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
                var ret = onSend(widget.ip, allselected);
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
                          builder: (context) => SelectAlbumsScreen(widget.ip),
                        ),
                      ).then((selectedAlbum) {
                        // Use the selectedAlbum value here
                        if (selectedAlbum != null) {
                          // Handle the selected album
                          onAddToAlbum(widget.ip, selectedAlbum, allselected).then((value) {
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
                      editDate(widget.ip, context, allselected);
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
                      moveToShared(widget.ip, allselected);
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
      body: (images.isEmpty)
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              child: ImageGridView(
                ip: widget.ip,
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
                  // widget.onSelect(selectedImages);
                },
              ),
            ),
    );
  }
}
