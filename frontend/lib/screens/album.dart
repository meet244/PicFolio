// ignore_for_file: prefer_const_constructors

import 'dart:convert';

import 'package:flutter/material.dart';
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
  Map<String, List<int>> images = {};
  int cnt = 0;

  @override
  void initState() {
    super.initState();
    fetchImages();
  }

  Future<void> fetchImages() async {
    final response = await http.get(Uri.parse(
        'http://${widget.ip}:7251/api/album/meet244/${widget.albumId}'));
    if (response.statusCode == 200) {
      Map<String, dynamic> data = jsonDecode(response.body);
      List<String> keys = data.keys.toList();
      keys = keys.reversed.toList();

      Map<String, dynamic> reversedMap = {};

      for (var key in keys) {
        reversedMap[key] = data[key];
      }

      Map<String, List<int>> data2 = reversedMap.map((key, value) {
        return MapEntry(
            key, (value as List<dynamic>).map((e) => e as int).toList());
      });

      // update count
      for (var key in data.keys) {
        cnt += data[key].length as int;
      }

      setState(() {
        images = data2;
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

  Future<void> deleteAlbum() async {
    final response = await http.post(
      Uri.parse('http://${widget.ip}:7251/api/album/delete'),
      body: {
        'album_id': widget.albumId,
        'username': 'meet244',
      },
    );
    if (response.statusCode == 200) {
      Navigator.pop(context, true);
    } else {
      throw Exception('Failed to delete album');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: Text("Album"),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          actions: [
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'delete') {
                  deleteAlbum();
                } else if (value == 'rename') {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      String newName = '';
                      return AlertDialog(
                        title: Text('Enter Album Name'),
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
                              if (newName.length > 30 || newName.isEmpty) {
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
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'rename',
                  child: Text('Rename Album'),
                ),
                const PopupMenuItem<String>(
                  value: 'delete',
                  child: Text('Delete Album'),
                ),
              ],
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
                            fontSize: 50, fontWeight: FontWeight.w100),
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
