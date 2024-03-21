// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:photoz/screens/user.dart';

class AllPeople extends StatefulWidget {
  String ip;

  AllPeople(this.ip, {super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<AllPeople> {
  late Map<String, String> faceNames;
  final List<String> _selectedImages = [];
  bool _isSearching = true;

  @override
  void initState() {
    super.initState();
    fetchFaces();
  }

  Future<void> fetchFaces() async {
    try {
      final response = await http.post(
        Uri.parse('http://${widget.ip}:7251/api/list/faces'),
        body: {'username': 'meet244'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // print(data);
        faceNames = Map<String, String>.from(data);

        // remove hidden faces - get from shared pref
      } else {
        throw Exception('Failed to load faces');
      }
      setState(() {
        _isSearching = false;
      });
    } catch (e) {
      print('Error: $e');
    }
  }

  // api to rename face
  Future<void> renameFace(String name, int userId) async {
    final response = await http.get(Uri.parse(
        'http://${widget.ip}:7251/api/face/rename/meet244/${userId}/${name}'));
    if (response.statusCode == 200) {
      setState(() {
        // rename from var
        faceNames[userId.toString()] = name;
      });
    } else {
      throw Exception('Failed to load name');
    }
  }

  // api to remove name
  Future<void> removeName(List<String> names) async {
    String namesString = names.join(',');
    final response = await http.post(
        Uri.parse('http://${widget.ip}:7251/api/face/noname'),
        body: {'username': 'meet244', 'name': namesString});
    if (response.statusCode == 200) {
      setState(() {
        // remove name from var
        faceNames.forEach((key, value) {
          if (names.contains(key)) {
            faceNames[key] = "Unknown";
          }
        });
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
    final response = await http
        .post(Uri.parse('http://${widget.ip}:7251/api/face/join'), body: {
      'username': 'meet244',
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
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'People',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('People'),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          actions: [
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
                      String newName =
                          ''; // Declare a variable to store the new name
                      return AlertDialog(
                        title: const Text('Rename Face'),
                        content: TextField(
                          decoration: InputDecoration(
                            hintText: 'Enter new name',
                          ),
                          onChanged: (value) {
                            newName =
                                value; // Update the new name variable when the input changes and limit it to 30 characters
                          },
                          maxLength:
                              30, // Set the maximum length of the input to 30 characters
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
                                  newName,
                                  int.parse(_selectedImages[
                                      0])); // Pass the new name and userId to the renameFace function
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
                } else if (value == 'hide') {
                  // hide faces -- add them to shared pref to hide them
                } else if (value == 'show') {
                  // show hidden faces -- shaw them from shared pref
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
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
                    child: Text('Reomve name'),
                  ),
                if (_selectedImages.isNotEmpty)
                  const PopupMenuItem<String>(
                    value: 'hide',
                    child: Text('Hide faces'),
                  ),
                const PopupMenuItem<String>(
                  value: 'show ',
                  child: Text('Show Hidden faces'),
                ),
              ],
            ),
          ],
        ),
        body: _buildBody(),
      ),
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
                // Add your action here
                _toggleSelection(faceNames.keys.toList()[index]);
              },
              onTap: () {
                if (_selectedImages.isNotEmpty) {
                  _toggleSelection(faceNames.keys.toList()[index]);
                } else {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => UserProfileScreen(
                        widget.ip,
                        faceNames.keys.toList()[index],
                      ),
                    ),
                  );
                }
              },
              child: Stack(
                children: [
                  Image.network(
                    "http://${widget.ip}:7251/api/face/image/meet244/${faceNames.keys.toList()[index]}",
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                  if (faceNames.values.toList()[index] != "Unknown")
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
                          faceNames.values.toList()[index].toString(),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16.0,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                  if (_selectedImages.contains(faceNames.keys.toList()[index]))
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withOpacity(0.5),
                        child: Icon(
                          Icons.check_circle,
                          color: Colors.blue,
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
