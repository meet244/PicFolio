import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:photoz/functions/selectedImages.dart';
import 'package:photoz/globals.dart';
import 'package:photoz/screens/selectScreen.dart';
import 'dart:convert';
import 'package:photoz/widgets/gridImages.dart';


// ignore: must_be_immutable
class FavouritesScreen extends StatefulWidget {
  String query;
  String qtype;

  FavouritesScreen(
      {super.key, this.query = '', this.qtype = 'search'});

  @override
  // ignore: library_private_types_in_public_api
  _FavouritesScreenState createState() => _FavouritesScreenState();
}

class _FavouritesScreenState extends State<FavouritesScreen> {
  List<dynamic> images = [];
  bool loading = true;
  List<int> allimgs = [];

  @override
  void initState() {
    super.initState();

    fetchImages();
  }

  Future<void> fetchImages() async {
    final response = await http.post(
      Uri.parse('${Globals.ip}/api/search'),
      body: {
        'username': Globals.username,
        'query': widget.query,
        'type': widget.qtype,
      },
    );
    if (response.statusCode == 200) {
      if (kDebugMode) print(jsonDecode(response.body));
      var data = jsonDecode(response.body);
      setState(() {
        loading = false;
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
              (allimgs.isEmpty)
                  ? Text(widget.query)
                  : (allimgs.length == 1)
                      ? Text("${allimgs.length} item")
                      : Text(
                          "${allimgs.length} items"), // Show count if images are selected
            ],
          ),
          leading: (allimgs.isNotEmpty)
              ? IconButton(
                  onPressed: () {
                    // Clear selection
                    setState(() {
                      allimgs.clear();
                    });
                  },
                  icon: const Icon(
                    Icons.close,
                    size: 32.0,
                  ),
                )
              : null,
          actions: <Widget>[
            if (allimgs.isNotEmpty)
              IconButton(
                onPressed: () {
                  var ret = onDelete(context, allimgs);
                  ret.then((value) {
                    if (value) {
                      setState(() {
                        allimgs.clear();
                      });
                    }
                  });
                },
                icon: const Icon(Icons.delete_outlined, size: 32.0),
              ),
            if (allimgs.isNotEmpty)
              IconButton(
                onPressed: () {
                  var ret = onSend(context, allimgs);
                  ret.then((value) {
                    if (value) {
                      setState(() {
                        allimgs.clear();
                      });
                    }
                  });
                },
                icon: const Icon(Icons.share_outlined, size: 32.0),
              ),
            if (allimgs.isNotEmpty)
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
                            onAddToAlbum(selectedAlbum, allimgs)
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
                        editDate(context, allimgs);
                      },
                    ),
                    PopupMenuItem(
                      child: const Row(
                        children: [
                          Icon(Icons.groups_outlined, size: 32.0),
                          SizedBox(width: 8.0),
                          Text('Add to shared'),
                        ],
                      ),
                      onTap: () {
                        // Handle move option tap
                        moveToShared(allimgs);
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
        body: loading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : SingleChildScrollView(
                child: widget.query.toLowerCase() == 'favourite'
                    ? ImageGridView(
                        ip: Globals.ip,
                        images: images,
                        gridCount: 3,
                        noImageIcon: Icons.heart_broken_outlined,
                        mainEmptyMessage: "No Favourites",
                        secondaryEmptyMessage:
                            "❤ images/videos to add them to Favourites",
                        onSelectionChanged: (select) {
                          setState(() {
                            allimgs = select;
                          });
                        },
                      )
                    : widget.query.toLowerCase() == 'screenshot'
                        ? ImageGridView(
                            ip: Globals.ip,
                            images: images,
                            gridCount: 3,
                            noImageIcon: Icons.screenshot_outlined,
                            mainEmptyMessage: "No Screenshot",
                            secondaryEmptyMessage:
                                "Screenshots will automatically appear here",
                            onSelectionChanged: (select) {
                              setState(() {
                                allimgs = select;
                              });
                            },
                          )
                        : widget.query.toLowerCase() == 'blurry'
                            ? ImageGridView(
                                ip: Globals.ip,
                                images: images,
                                gridCount: 3,
                                noImageIcon: Icons.photo_library,
                                mainEmptyMessage: "No Blurry Images",
                                secondaryEmptyMessage:
                                    "Blurry images will automatically appear here",
                                onSelectionChanged: (select) {
                                  setState(() {
                                    allimgs = select;
                                  });
                                },
                              )
                            : ImageGridView(
                                ip: Globals.ip,
                                images: images,
                                gridCount: 3,
                                noImageIcon: Icons.search_off_outlined,
                                mainEmptyMessage: "Nothing Found",
                                secondaryEmptyMessage:
                                    "We didn't got it anywhere! Try searching something else",
                                onSelectionChanged: (select) {
                                  setState(() {
                                    allimgs = select;
                                  });
                                },
                              ),
              ));
  }

  Future<List<int>> fetchPreviewImage(int imageId, String date) async {
    date = date.replaceAll('-', '/');
    final response = await http.get(Uri.parse(
        '${Globals.ip}/api/preview/${Globals.username}/$imageId/$date'));
    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      throw Exception('Failed to load preview image');
    }
  }
}
