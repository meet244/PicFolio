// ignore_for_file: prefer_const_constructors

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:photoz/globals.dart';
import 'dart:convert';
import 'package:photoz/widgets/gridImages.dart';


class Duplicates extends StatefulWidget {

  const Duplicates({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _DuplicatesScreenState createState() => _DuplicatesScreenState();
}

class _DuplicatesScreenState extends State<Duplicates> {
  List<List<dynamic>> images = [];
  bool gotResponse = false;
  List<int> selectedImages = [];

  @override
  void initState() {
    super.initState();
      fetchImages();
  }

  void toggleSelection(int imageId) {
    if (selectedImages.contains(imageId)) {
      setState(() {
        selectedImages.remove(imageId);
      });
    } else {
      setState(() {
        selectedImages.add(imageId);
      });
    }
  }

  Future<void> fetchImages() async {
    final response = await http.post(
      Uri.parse('${Globals.ip}/api/list/duplicate'),
      body: {
        'username': Globals.username,
      },
    );
    if (response.statusCode == 200) {
      final List<dynamic> responseData = jsonDecode(response.body);

      List<List<dynamic>> data2 = [];
      for (dynamic data in responseData) {
        data2.add(data);
      }
      // Iterate over the responseData list using a for loop
      setState(() {
        gotResponse = true;
        images = data2;
        selectedImages = [];
      });
    } else {
      throw Exception('Failed to load images');
    }
  }

  Future<bool> deleteImage(List<String> imageIds) async {
    var imgs = imageIds.join(',');
    final response = await http
        .delete(Uri.parse('${Globals.ip}/api/delete/${Globals.username}/$imgs'));
    if (response.statusCode == 200) {
      if (kDebugMode) print('Image deleted');
      return true;
    } else {
      if (kDebugMode) print("Failed to delete image");
      return false;
      // throw Exception('Failed to delete image');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Duplicates"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          if (selectedImages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.done_all_outlined),
              onPressed: () {
                List<int> s = [];
                for (int i = 0; i < images.length; i++) {
                  s.add(images[i][2] as int);
                }
                if (selectedImages == s) {
                  s = [];
                }
                setState(() {
                  selectedImages = s;
                });
              },
            ),
        ],
      ),
      body: (Globals.username == '')
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : 
      images.isNotEmpty
          ? Stack(children: [
              ListView.builder(
                itemCount: images.length,
                itemBuilder: (BuildContext context, int index) {
                  String title =
                      images[index][0].toString().replaceAll("-", "/");
                  String imageUrl1 =
                      '${Globals.ip}/api/preview/${Globals.username}/${images[index][1] as int}/$title';
                  String imageUrl2 =
                      '${Globals.ip}/api/preview/${Globals.username}/${images[index][2] as int}/$title';
                  return SizedBox(
                    // height: 250, // Adjust the height as needed
                    child: Column(
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.all(7),
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(3),
                                child: SizedBox(
                                  width: double.infinity,
                                  height: 200, // Adjust the height as needed
                                  child: GestureDetector(
                                    onTap: () {
                                      if (selectedImages.isEmpty) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                ImageDetailScreen(
                                              images[index][1] as int,
                                              date: images[index][0]
                                                  .toString()
                                                  .replaceAll("-", "/"),
                                            ),
                                          ),
                                        );
                                      } else {
                                        toggleSelection(
                                            images[index][1] as int);
                                      }
                                    },
                                    onLongPress: () {
                                      toggleSelection(images[index][1] as int);
                                    },
                                    child: Stack(
                                      children: [
                                        ShaderMask(
                                          shaderCallback: (Rect bounds) {
                                            return LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.center,
                                              colors: const [
                                                Colors.black54,
                                                Colors.transparent
                                              ],
                                              stops: const [0.0, 0.4],
                                            ).createShader(bounds);
                                          },
                                          blendMode: BlendMode.srcATop,
                                          child: Image.network(
                                            imageUrl1,
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                            height: double.infinity,
                                            alignment: Alignment.center,
                                          ),
                                        ),
                                        if (selectedImages
                                            .contains(images[index][1] as int))
                                          Positioned.fill(
                                            child: Container(
                                              color:
                                                  Colors.black.withOpacity(0.5),
                                              child: Icon(
                                                Icons.check_circle,
                                                color: Colors.blue,
                                                size: 40,
                                              ),
                                            ),
                                          ),
                                        Positioned(
                                          top: 7,
                                          left: 7,
                                          child: Icon(
                                            Icons.star,
                                            color: Colors.yellow,
                                            size: 20,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(3),
                                child: GestureDetector(
                                  onTap: () {
                                    if (selectedImages.isEmpty) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              ImageDetailScreen(
                                            images[index][2] as int,
                                            date: images[index][0]
                                                .toString()
                                                .replaceAll("-", "/"),
                                          ),
                                        ),
                                      );
                                    } else {
                                      toggleSelection(images[index][2] as int);
                                    }
                                  },
                                  onLongPress: () {
                                    toggleSelection(images[index][2] as int);
                                  },
                                  child: SizedBox(
                                    width: double.infinity,
                                    height: 200, // Adjust the height as needed
                                    child: Stack(children: [
                                      Image.network(
                                        imageUrl2,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: double.infinity,
                                      ),
                                      if (selectedImages
                                          .contains(images[index][2] as int))
                                        Positioned.fill(
                                          child: Container(
                                            color:
                                                Colors.black.withOpacity(0.5),
                                            child: Icon(
                                              Icons.check_circle,
                                              color: Colors.blue,
                                              size: 40,
                                            ),
                                          ),
                                        ),
                                    ]),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
              SizedBox(height: 16),
              Align(
                alignment: Alignment.bottomRight,
                child: AnimatedOpacity(
                  opacity: selectedImages.isEmpty ? 0.0 : 1.0,
                  duration: Duration(milliseconds: 200),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: FloatingActionButton(
                      elevation: 10,
                      onPressed: selectedImages.isEmpty
                          ? null
                          : () {
                              // remove all duplicates from the list
                              selectedImages = selectedImages.toSet().toList();
                              deleteImage(selectedImages
                                      .map((e) => e.toString())
                                      .toList())
                                  .then((bool success) {
                                // Handle the result here
                                if (success) {
                                  // Delete operation was successful
                                  if (kDebugMode) print('Image deleted successfully');
                                  fetchImages();
                                } else {
                                  // Delete operation failed
                                  if (kDebugMode) print('Failed to delete image');
                                }
                              });
                              // Navigator.pop(context);
                            },
                      backgroundColor: Colors.red,
                      child:
                          const Icon(Icons.delete_outline, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ])
          : gotResponse
              ? NothingMessage(
                  icon: Icons.file_copy_outlined,
                  mainMessage: "No Duplicates Found",
                  secondaryMessage: "That's a good thing!")
              : const Center(
                  child: CircularProgressIndicator(),
                ),
    );
  }

  Future<List<int>> fetchPreviewImage(int imageId, String date) async {
    final response = await http.get(Uri.parse(
        '${Globals.ip}/api/preview/${Globals.username}/$imageId/$date'));
    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      throw Exception('Failed to load preview image');
    }
  }
}
