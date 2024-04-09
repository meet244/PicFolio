// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:photoz/color.dart';
import 'package:photoz/functions/selectedImages.dart';
import 'package:photoz/globals.dart';
import 'package:photoz/screens/settings.dart';
import 'package:photoz/screens/shared.dart';
import 'package:photoz/widgets/gridImages.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Album extends StatefulWidget {
  final String albumId;
  String albumName;
  String albumDate;

  Album(this.albumId, this.albumName, this.albumDate, {super.key});

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
        '${Globals.ip}:7251/api/album/${Globals.username}/${widget.albumId}'));
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
      Uri.parse('${Globals.ip}:7251/api/album/rename'),
      body: {
        'username': Globals.username,
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
      Uri.parse('${Globals.ip}:7251/api/album/delete'),
      body: {
        'album_id': widget.albumId,
        'username': Globals.username,
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

  Future<bool> redate() async {
    final response = await http.post(
      Uri.parse('${Globals.ip}:7251/api/album/redate'),
      body: {
        'username': Globals.username,
        'album_id': widget.albumId,
        'date': widget.albumDate,
      },
    );
    if (response.statusCode == 200) {
      return true;
    } else {
      print('Failed to redate album');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(useMaterial3: true, colorScheme: lightColorScheme),
      darkTheme: ThemeData(useMaterial3: true, colorScheme: darkColorScheme),
      debugShowCheckedModeBanner: false,
      home: (Globals.username == '')
          ? Center(
              child: CircularProgressIndicator(),
            )
          : Scaffold(
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
                        var ret = onDelete(Globals.ip, context, selectedImages);
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
                        var ret = onSend(Globals.ip, context, selectedImages);
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
                                    Globals.ip, widget.albumId, selectedImages);
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
                                  Icon(Icons.edit_calendar_outlined,
                                      size: 32.0),
                                  SizedBox(width: 8.0),
                                  Text('Edit Date'),
                                ],
                              ),
                              onTap: () {
                                // Handle copy option tap
                                editDate(Globals.ip, context, selectedImages);
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
                                moveToShared(Globals.ip, selectedImages);
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
                                  String albumName = widget.albumName;
                                  TextEditingController textEditingController =
                                      TextEditingController(text: albumName);

                                  return AlertDialog(
                                    title: Text('Rename Album'),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        TextField(
                                          autofocus: true,
                                          controller: textEditingController,
                                          onSubmitted: (value) {
                                            rename(value);
                                            Navigator.pop(context);
                                          },
                                        ),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            TextButton(
                                              onPressed: () {
                                                Navigator.pop(context);
                                              },
                                              child: Text('Cancel'),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                rename(
                                                    textEditingController.text);
                                                Navigator.pop(context);
                                              },
                                              child: Text('Save'),
                                            ),
                                          ],
                                        ),
                                      ],
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
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: Text('Delete Album'),
                                    content: Text(
                                        'Are you sure you want to delete this album?\nThis action is irreversible.'),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                        },
                                        child: Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          deleteAlbum();
                                          Navigator.pop(context);
                                        },
                                        child: Text('Delete'),
                                      ),
                                    ],
                                  );
                                },
                              );
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
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 10,
                              ),
                              child: Text(
                                widget.albumName,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 50,
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      left: 12,
                                    ),
                                    child: Icon(
                                      Icons.image_outlined,
                                      size: 20,
                                    ),
                                  ),
                                  SizedBox(width: 10.0),
                                  Text(
                                    '$cnt photos',
                                    style: const TextStyle(fontSize: 16.0),
                                  ),
                                ],
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () {
                                // Open a date picker
                                showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now(),
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2100),
                                ).then((value) {
                                  if (value != null) {
                                    // Update date
                                    widget.albumDate =
                                        DateFormat('yyyy-MM-dd').format(value);
                                    redate().then((value) {
                                      if (value) {
                                        setState(() {});
                                      }
                                    });
                                  }
                                });
                              },
                              icon: Icon(
                                Icons.date_range_outlined,
                                size: 20,
                                color:
                                    Theme.of(context).colorScheme.onBackground,
                              ),
                              label: Text(
                                widget.albumDate == ""
                                    ? "Add Date"
                                    : DateFormat('dd MMM yyyy').format(
                                        DateFormat('yyyy-MM-dd')
                                            .parse(widget.albumDate)),
                                style: TextStyle(
                                  fontSize: 16.0,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onBackground,
                                ),
                              ),
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
