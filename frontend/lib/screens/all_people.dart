import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:photoz/globals.dart';
import 'dart:convert';

import 'package:photoz/screens/user.dart';

// ignore: must_be_immutable
class AllPeople extends StatefulWidget {
  String ip;
  List<dynamic> removeFaceIds = [];
  String title = "";
  bool isAdd = true;

  AllPeople(
      {required this.ip,
      this.removeFaceIds = const [],
      this.isAdd = true,
      this.title = "",
      super.key});

  @override
  // ignore: library_private_types_in_public_api
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<AllPeople> {
  late List<dynamic> faceNames;
  final List<String> _selectedImages = [];
  bool _isSearching = true;

  @override
  void initState() {
    super.initState();
    fetchFaces();
  }

  Future<void> fetchFaces() async {
    if (widget.title != "" && !widget.isAdd) {
      setState(() {
        faceNames = widget.removeFaceIds;
        _isSearching = false;
      });
      return;
    }
    try {
      final response = await http.post(
        Uri.parse('${Globals.ip}/api/list/faces'),
        body: {
          'username': Globals.username,
        },
      );
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        // remove faces
        if (kDebugMode) {
          print(data);
          print(widget.removeFaceIds);
        }
        // print(data); //  == [[15, Harshil], [13, Meet], [168, Heer], [14, Tirth], [156, Meet Shah], [161, Unknown], [101, Mayank], [107, Ananya], [8, Mohit], [96, Karan], [403, Maitri], [225, Vian], [196, Shiva], [88, Nikunj], [400, Ssruvi], [167, Unknown], [392, Ayman], [401, Shravani], [414, Tirth], [419, Unknown], [76, Unknown], [354, Unknown], [357, Unknown], [365, Unknown], [366, Unknown], [383, Unknown], [384, Unknown], [364, Unknown], [394, Unknown], [421, Unknown], [422, Unknown]]
        // print(widget.removeFaceIds); // == [[421, Unknown]]
        if (widget.title != "") {
          if (widget.isAdd) {
            for (var faceId in widget.removeFaceIds) {
              data.removeWhere((face) => face[0] == faceId[0]);
            }
          }
        }
        if (kDebugMode) print(data);
        // for (var faceId in widget.removeFaceIds) {
        //   data.removeWhere((face) => face[0] == faceId);
        // }
        faceNames = data;
      } else {
        throw Exception('Failed to load faces');
      }
      setState(() {
        _isSearching = false;
      });
    } catch (e) {
      if (kDebugMode) print('Error: $e');
    }
  }

  // api to rename face
  Future<void> renameFace(String name, int userId) async {
    final response = await http.get(Uri.parse(
        '${Globals.ip}/api/face/rename/${Globals.username}/$userId/$name'));
    if (response.statusCode == 200) {
      setState(() {
        // rename from var
        for (var face in faceNames) {
          if (face[0].toString() == userId.toString()) {
            face[1] = name;
          }
        }
      });
    } else {
      throw Exception('Failed to load name');
    }
  }

  // api to remove name
  Future<void> removeName(List<String> names) async {
    String namesString = names.join(',');
    final response = await http.post(Uri.parse('${Globals.ip}/api/face/noname'),
        body: {'username': Globals.username, 'name': namesString});
    if (response.statusCode == 200) {
      setState(() {
        // remove name from var
        for (var name in names) {
          for (var face in faceNames) {
            if (face[0].toString() == name) {
              face[1] = "Unknown";
            }
          }
        }
        _selectedImages.clear();
      });
    } else {
      throw Exception('Failed to load name');
    }
  }

  // api to merge faces
  // @app.route('/api/face/join/<string:username>/<int:main_face_id1>/<int:side_face_id2>', methods=['GET'])

  Future<void> mergeFaces(String mainface, String sideface) async {
    // String namesString = names.join(',');
    final response =
        await http.post(Uri.parse('${Globals.ip}/api/face/join'), body: {
      'username': Globals.username,
      'main_face_id1': mainface,
      'side_face_id2': sideface
    });
    if (response.statusCode == 200) {
      setState(() {
        fetchFaces();
        _selectedImages.clear();
      });
    } else {
      throw Exception('Failed to merge faces');
    }
  }

  void _toggleSelection(String image) {
    if (_selectedImages.contains(image)) {
      _selectedImages.remove(image);
    } else {
      _selectedImages.add(image);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _selectedImages.isNotEmpty
            ? Text('${_selectedImages.length} selected')
            : Text(
                widget.title == "" ? "People" : widget.title,
              ),
        leading: _selectedImages.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  setState(() {
                    _selectedImages.clear();
                  });
                },
              )
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
        actions: _selectedImages.isNotEmpty
            ? [
                PopupMenuButton<String>(
                  onSelected: (value) {
                    // Handle the selected item here
                    if (value == 'merge') {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Merge Faces'),
                            content: const Text(
                                'Are you sure you want to merge these faces?\nThis action cannot be undone.'),
                            actions: <Widget>[
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  mergeFaces(
                                      _selectedImages[0], _selectedImages[1]);
                                },
                                child: const Text('Merge'),
                              ),
                            ],
                          );
                        },
                      );
                    } else if (value == 'rename') {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          String newName = '';
                          return AlertDialog(
                            title: const Text('Rename Face'),
                            content: TextField(
                              decoration: const InputDecoration(
                                hintText: 'Enter new name',
                              ),
                              onChanged: (value) {
                                newName = value;
                              },
                              maxLength: 30,
                            ),
                            actions: <Widget>[
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  if (newName.length > 30) {
                                    return;
                                  }
                                  if (newName.isEmpty) {
                                    return;
                                  }
                                  Navigator.of(context).pop();
                                  renameFace(
                                      newName, int.parse(_selectedImages[0]));
                                  setState(() {
                                    _selectedImages.clear();
                                  });
                                },
                                child: const Text('Rename'),
                              ),
                            ],
                          );
                        },
                      );
                    } else if (value == 'noname') {
                      removeName(_selectedImages);
                    }
                  },
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<String>>[
                    if (_selectedImages.length == 2)
                      const PopupMenuItem<String>(
                        value: 'merge',
                        child: Text('Merge Faces'),
                      ),
                    if (_selectedImages.length == 1)
                      const PopupMenuItem<String>(
                        value: 'rename',
                        child: Text('Rename'),
                      ),
                    if (_selectedImages.isNotEmpty)
                      const PopupMenuItem<String>(
                        value: 'noname',
                        child: Text('Remove name'),
                      ),
                  ],
                ),
              ]
            : null,
      ),
      body: (Globals.username == '')
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isSearching) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    } else {
      return GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 4.0,
          mainAxisSpacing: 4.0,
        ),
        itemCount: faceNames.length,
        itemBuilder: (BuildContext context, int index) {
          return GridTile(
            child: GestureDetector(
              onLongPress: () {
                if (widget.title != "") {
                  return;
                }
                // Add your action here
                _toggleSelection(faceNames[index][0].toString());
              },
              onTap: () {
                if (widget.title != "") {
                  Navigator.pop(context, faceNames[index]);
                  return;
                }
                if (_selectedImages.isNotEmpty) {
                  _toggleSelection(faceNames[index][0].toString());
                } else {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => UserProfileScreen(
                        faceNames[index][0].toString(),
                      ),
                    ),
                  );
                }
              },
              child: Stack(
                children: [
                  CachedNetworkImage(
                    imageUrl:
                        "${Globals.ip}/api/face/image/${Globals.username}/${faceNames[index][0]}",
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                  if (faceNames[index][1].toString() != "Unknown")
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Color.fromARGB(255, 36, 36, 36),
                            Color.fromARGB(128, 39, 39, 39),
                            Colors.transparent,
                            Colors.transparent,
                          ],
                          stops: [0.0, 0.2, 0.8, 1.0],
                        ),
                      ),
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.all(5),
                        child: Text(
                          faceNames[index][1].toString(),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16.0,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                  if (_selectedImages.contains(faceNames[index][0].toString()))
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withOpacity(0.5),
                        child: const Icon(
                          Icons.check_circle,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      );
    }
  }
}
