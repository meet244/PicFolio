import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:photoz/screens/search.dart';
import 'package:photoz/widgets/gridImages.dart';
import 'package:http/http.dart' as http;


class UserProfileScreen extends StatefulWidget {
  final String userId;
  final String ip;

  const UserProfileScreen(this.ip, this.userId, {super.key});

  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  Map<String, List<int>> images = {};
  String name = '';
  int cnt = 0;

  @override
  void initState() {
    super.initState();
    fetchname();
    fetchImages();
  }

  Future<void> fetchImages() async {
    final response = await http.get(
      Uri.parse('http://${widget.ip}:7251/api/list/face/meet244/${widget.userId}')
    );
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

      setState(() {
        images = data2;
      });
    } else {
      throw Exception('Failed to load images');
    }
  }

  Future<void> fetchname() async {
    // wait for 0.1 seconds
    // await Future.delayed(const Duration(milliseconds: 100));
    final response = await http.get(
      Uri.parse('http://${widget.ip}:7251/api/face/name/meet244/${widget.userId}')
    );
    if (response.statusCode == 200) {
      var d = json.decode(response.body);
      var n = d[0];
      if (n != null && n != 'Unknown') {
        setState(() {
          name = n;
          cnt = d[1];
        });
      }
      else{
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
    final response = await http.get(
      Uri.parse('http://${widget.ip}:7251/api/face/rename/meet244/${widget.userId}/${name}')
    );
    if (response.statusCode == 200) {
      setState(() {
        this.name = name;
      });
    } else {
      throw Exception('Failed to load name');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: GestureDetector(
            onTap: () {
              if (name != 'Add a name') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SearchScreen(widget.ip, name),
                  ),
                );
              }
            },
            child: Text(name == 'Add a name' ? '' : name),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ClipOval(
                    child: Image.network(
                      'http://${widget.ip}:7251/api/face/image/meet244/${widget.userId}',
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
                                      if (newName.length > 30) {
                                        showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return AlertDialog(
                                              title: Text('Error'),
                                              content: Text('Name should be less than 30 characters.'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.of(context).pop();
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
                        style: const TextStyle(fontSize: 25.0, fontWeight: FontWeight.bold),
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
            Expanded( // Add an Expanded widget here
              child: ImageGridView(
                ip: widget.ip,
                images: images,
                gridCount: 3,
                noImageIcon: Icons.image_outlined,
                mainEmptyMessage: "No Images Found",
                secondaryEmptyMessage: "Images will appear here",
              ),
            ),
          ],
        ),
      ),
    );
  }
}
