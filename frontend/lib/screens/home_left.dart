import 'dart:convert';
import 'package:flutter/foundation.dart';
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

  const HomeLeft({super.key});

  @override
  // ignore: library_private_types_in_public_api
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
      page++;
      if (page == 0) {
        setState(() {
          isLoading = true;
        });
      }
      final response = await http.post(
        Uri.parse('${Globals.ip}/api/list/general'),
        body: {'username': Globals.username, "page": page.toString()},
      );
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);

        if (data.isEmpty) {
          bottomreached = true;
          if (kDebugMode) print('Bottom Reached');
        }

        if (images.isEmpty) {
          if (kDebugMode) print('First Fetch');
          setState(() {
            images = data;
            isLoading = false;
          });
          return;
        } else {
          if (kDebugMode) print('Fetching more');
          addImagesToList(data);
        }

        if (kDebugMode) print(images);
      } else {
        throw Exception('Failed to load images');
      }
    }
  }

  final GlobalKey<ImageGridViewState> imageGridViewKey =
      GlobalKey<ImageGridViewState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            (allselected.isEmpty)
                ? const Text("PicFolio")
                : (allselected.length == 1)
                    ? Text("${allselected.length} item")
                    : Text(
                        "${allselected.length} items"), // Show count if images are selected
          ],
        ),
        leading: (allselected.isNotEmpty)
            ? IconButton(
                onPressed: () {
                  // Clear selection
                  setState(() {
                    allselected.clear();
                  });
                },
                icon: const Icon(
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
                    if (kDebugMode) print('Image Uploaded');
                  }
                });
              },
              icon: const Icon(Icons.add_a_photo_outlined, size: 32.0),
            ),
          if (allselected.isEmpty)
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
              icon: const Icon(Icons.settings_outlined, size: 32.0),
            ),
          if (allselected.isNotEmpty)
            IconButton(
              onPressed: () {
                var ret = onDelete(context, allselected);
                ret.then((value) {
                  if (value) {
                    setState(() {
                      allselected.clear();
                    });
                  }
                });
              },
              icon: const Icon(Icons.delete_outlined, size: 32.0),
            ),
          if (allselected.isNotEmpty)
            IconButton(
              onPressed: () {
                var ret = onSend(context, allselected);
                ret.then((value) {
                  if (value) {
                    setState(() {
                      allselected.clear();
                    });
                  }
                });
              },
              icon: const Icon(Icons.share_outlined, size: 32.0),
            ),
          if (allselected.isNotEmpty)
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
                    onTap: () async {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SelectAlbumsScreen(),
                        ),
                      ).then((selectedAlbum) {
                        // Use the selectedAlbum value here
                        if (selectedAlbum != null) {
                          // Handle the selected album
                          onAddToAlbum(selectedAlbum, allselected)
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
                    child: const Row(
                      children: [
                        Icon(Icons.edit_calendar_outlined, size: 32.0),
                        SizedBox(width: 8.0),
                        Text('Edit Date'),
                      ],
                    ),
                    onTap: () {
                      // Handle copy option tap
                      editDate(context, allselected);
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
                      moveToShared(allselected);
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
      body: (Globals.username == '' || isLoading)
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              controller: _scrollController,
              child: ImageGridView(
                key: imageGridViewKey,
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

  void addImagesToList(List<dynamic> newImages) {
    imageGridViewKey.currentState
        ?.addImages(newImages, isLastPage: bottomreached);
  }
}
