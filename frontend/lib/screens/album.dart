// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:photoz/functions/selectedImages.dart';
import 'package:photoz/screens/settings.dart';
import 'package:photoz/widgets/gridImages.dart';
import 'package:http/http.dart' as http;

class Album extends StatefulWidget {
  final String albumId;
  String albumName;
  final String ip;

  Album(this.ip, this.albumId, this.albumName, {super.key});

  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<Album> {
  List<dynamic> images = [];
  int cnt = 0;
  List<int> selectedImages = [];

  @override
  void initState() {
    super.initState();
    fetchImages();
  }

  Future<void> fetchImages() async {
    final response = await http.get(Uri.parse(
        'http://${widget.ip}:7251/api/album/meet244/${widget.albumId}'));
    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);

      // update count
      for (var i in data) {
        cnt += int.parse(i[1].length.toString());
      }

      setState(() {
        images = data;
      });
    } else {
      throw Exception('Failed to load images');
    }
  }

  Future<void> rename(String name) async {
    final response = await http.post(
      Uri.parse('http://${widget.ip}:7251/api/album/rename'),
      body: {
        'username': 'meet244',
        'album_id': widget.albumId,
        'name': name,
      },
    );
    if (response.statusCode == 200) {
      setState(() {
        widget.albumName = name;
      });
    } else {
      throw Exception('Failed to load name');
    }
  }

  Future<bool> deleteAlbum() async {
    final response = await http.post(
      Uri.parse('http://${widget.ip}:7251/api/album/delete'),
      body: {
        'album_id': widget.albumId,
        'username': 'meet244',
      },
    );
    if (response.statusCode == 200) {
      Navigator.pop(context);
      return true;
    } else {
      print('Failed to delete album');
      return false;
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
              Text(
                (selectedImages.isEmpty)
                    ? "Album"
                    : (selectedImages.length == 1)
                        ? "${selectedImages.length} item"
                        : "${selectedImages.length} items", // Show count if images are selected
              ),
            ],
          ),
          leading: (selectedImages.isNotEmpty)
              ? IconButton(
                  onPressed: () {
                    // Clear selection
                    setState(() {
                      selectedImages.clear();
                    });
                  },
                  icon: Icon(
                    Icons.close,
                    size: 32.0,
                  ),
                )
              : IconButton(
                  onPressed: () {
                    // Navigate back
                    Navigator.pop(context);
                  },
                  icon: Icon(
                    Icons.arrow_back,
                    size: 32.0,
                  ),
                ),
          actions: <Widget>[
            if (selectedImages.isNotEmpty)
              IconButton(
                onPressed: () {
                  var ret = onDelete(widget.ip, context, selectedImages);
                  ret.then((value) {
                    if (value) {
                      setState(() {
                        selectedImages.clear();
                      });
                    }
                  });
                },
                icon: Icon(Icons.delete_outlined, size: 32.0),
              ),
            if (selectedImages.isNotEmpty)
              IconButton(
                onPressed: () {
                  var ret = onSend(widget.ip, selectedImages);
                  ret.then((value) {
                    if (value) {
                      setState(() {
                        selectedImages.clear();
                      });
                    }
                  });
                },
                icon: Icon(Icons.share_outlined, size: 32.0),
              ),
            if (selectedImages.isNotEmpty)
              PopupMenuButton(
                itemBuilder: (BuildContext context) {
                  return [
                    if (selectedImages.isNotEmpty)
                      PopupMenuItem(
                        child: Row(
                          children: [
                            Icon(Icons.cancel_outlined, size: 32.0),
                            SizedBox(width: 8.0),
                            Text('Remove from Album'),
                          ],
                        ),
                        onTap: () {
                          // Handle edit option tap
                          var ret = onRemoveFromAlbum(
                              widget.ip, widget.albumId, selectedImages);
                          ret.then((value) {
                            if (value) {
                              setState(() {
                                selectedImages.clear();
                              });
                            }
                          });
                        },
                      ),
                    if (selectedImages.isNotEmpty)
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
                          editDate(widget.ip, context, selectedImages);
                        },
                      ),
                    if (selectedImages.isNotEmpty)
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
                          moveToShared(widget.ip, selectedImages);
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
              PopupMenuButton(
                itemBuilder: (BuildContext context) {
                  return [
                    PopupMenuItem(
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 32.0),
                          SizedBox(width: 8.0),
                          Text('Rename Album'),
                        ],
                      ),
                      onTap: () {
                        // Handle edit option tap
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text('Rename Album'),
                              content: TextField(
                                autofocus: true,
                                onSubmitted: (value) {
                                  rename(value);
                                  Navigator.pop(context);
                                },
                              ),
                            );
                          },
                        );
                      },
                    ),
                    PopupMenuItem(
                      child: Row(
                        children: [
                          Icon(Icons.delete_outlined, size: 32.0),
                          SizedBox(width: 8.0),
                          Text('Delete Album'),
                        ],
                      ),
                      onTap: () {
                        // Handle delete option tap
                        deleteAlbum();
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
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const SizedBox(width: 16.0),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.albumName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 50, fontWeight: FontWeight.w300),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(
                            Icons.image_outlined,
                            size: 20,
                          ),
                          SizedBox(width: 5.0),
                          Text(
                            '$cnt photos',
                            style: const TextStyle(fontSize: 16.0),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20.0),
              ImageGridView(
                ip: widget.ip,
                images: images,
                gridCount: 3,
                noImageIcon: Icons.image_outlined,
                mainEmptyMessage: "No Images Found",
                secondaryEmptyMessage: "Images will appear here",
                isAlbum: true,
                albumOrFaceId: widget.albumId,
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
