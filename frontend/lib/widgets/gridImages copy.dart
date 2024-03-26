// ignore_for_file: prefer_const_constructors

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photoz/widgets/face.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';

// ignore: must_be_immutable
class ImageGridView extends StatefulWidget {
  List<dynamic> images;
  final int gridCount;
  final String ip;
  final IconData noImageIcon;
  final String mainEmptyMessage;
  final String secondaryEmptyMessage;
  bool isBin;
  bool isNormal;
  bool isAlbum;
  String albumOrFaceId;
  final Function(List<int>) onSelectionChanged;

  ImageGridView({
    super.key,
    required this.ip,
    required this.images,
    required this.gridCount,
    required this.noImageIcon,
    required this.mainEmptyMessage,
    required this.secondaryEmptyMessage,
    this.isBin = false,
    this.isNormal = false,
    this.isAlbum = false,
    this.albumOrFaceId = '0',
    required this.onSelectionChanged,
  });

  @override
  _ImageGridViewState createState() => _ImageGridViewState();
}

class _ImageGridViewState extends State<ImageGridView> {
  Map<int, List<int>> loadedImages = {};
  final List<int> _selectedImages = [];

  Future<List<int>> fetchPreviewImage(int imageId, {String date = ''}) async {
    // print(date);
    // print(imageId);
    date = date.replaceAll('-', '/');
    String url = 'http://${widget.ip}:7251/api/preview/meet244/$imageId/$date';
    if (widget.isBin || date == '') {
      url = 'http://${widget.ip}:7251/api/preview/meet244/$imageId';
    } else {
      url = 'http://${widget.ip}:7251/api/preview/meet244/$imageId/$date';
    }
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      throw Exception('Failed to load preview image ${response.statusCode}');
    }
  }

  void _toggleSelection(int imageId) {
    print(imageId);
    setState(() {
      if (_selectedImages.contains(imageId)) {
        _selectedImages.remove(imageId);
      } else {
        _selectedImages.add(imageId);
      }
      widget.onSelectionChanged(_selectedImages);
    });
  }

  Future<void> _onSend() async {
    // Implement your send logic here
    print(_selectedImages);

    try {
      final tempDir = await getTemporaryDirectory();

      // Create temporary files for each image
      final tempFiles = <File>[];
      for (int i = 0; i < _selectedImages.length; i++) {
        final imageId = _selectedImages[i];
        final mainImageBytes = await fetchPreviewImage(imageId);
        loadedImages[imageId] = mainImageBytes;
        // Save the main image to a temporary file
        final tempFile = File('${tempDir.path}/temp_image_$i.png');
        await tempFile.writeAsBytes(mainImageBytes);
        tempFiles.add(tempFile);
      }

      // Share the multiple images using the share_plus package
      await Share.shareFiles(
        tempFiles.map((file) => file.path).toList(),
        text: 'I shared these images from my PicFolio app. Try them out!',
        subject: 'Image Sharing',
      );
    } catch (e) {
      print('Error sharing images: $e');
      // Handle the error, e.g., show a snackbar or log the error
    }

    setState(() {
      _selectedImages.clear(); // Clear selected images after sending
    });
  }

  Future<void> _onDelete() async {
    // Implement your delete logic here
    print(_selectedImages);

    // Call delete image API here
    var imgs = _selectedImages.join(',');
    final response = await http
        .delete(Uri.parse('http://${widget.ip}:7251/api/delete/meet244/$imgs'));
    if (response.statusCode == 200) {
      print('Image deleted');
      // remove the deleted images from the grid
      setState(() {
        _selectedImages.clear();
      });
    } else {
      throw Exception('Failed to delete image');
    }
  }

  void _onAdd() {
    // Implement your add logic here
    print(_selectedImages);
    setState(() {
      _selectedImages.clear(); // Clear selected images after sending
    });
  }

  Future<void> _editDate() async {
    // Implement your edit date logic here
    // get a date from calendar
    final DateTime? picked = await showDatePicker(
        context: context,
        // initialDate: selectedDate,
        firstDate: DateTime(2015, 8),
        lastDate: DateTime(2101));
    if (picked == null) {
      return;
    }
    var date = (picked.toString().split(" ")[0]);
    var imgs = _selectedImages.join(',');
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
        _selectedImages.clear();
      });
      // remove the deleted images from the grid
    } else {
      throw Exception('Failed to update date');
    }

    setState(() {
      _selectedImages.clear(); // Clear selected images after sending
    });
  }

  Future<void> _moveToFamily() async {
    // Implement your move to family logic here
    print(_selectedImages);
    final response = await http.post(
      Uri.parse('http://${widget.ip}:7251/api/shared/move'),
      body: {
        'username': 'meet244',
        'asset_id': _selectedImages.join(','),
      },
    );
    if (response.statusCode == 200) {
      print('Image Shared');
    } else {
      throw Exception('Failed to move to share');
    }
    setState(() {
      _selectedImages.clear(); // Clear selected images after sending
    });
  }

  Future<void> restoreImage() async {
    var imgs = _selectedImages.join(',');
    final response = await http
        .post(Uri.parse('http://${widget.ip}:7251/api/restore/meet244/$imgs'));
    if (response.statusCode == 200) {
      print('Image restored');
      setState(() {
        _selectedImages.clear();
      });
    } else {
      throw Exception('Failed to restore image');
    }
  }

  Future<void> removeAlbumImages() async {
    final response = await http
        .post(Uri.parse('http://${widget.ip}:7251/api/album/remove'), body: {
      'username': 'meet244',
      'album_id': widget.albumOrFaceId.toString(),
      'asset_id': _selectedImages.join(','),
    });
    if (response.statusCode == 200) {
      print('Image removed from album');
      setState(() {
        _selectedImages.clear();
      });
    } else {
      throw Exception('Failed to remove image from album');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) {
      return NothingMessage(
        icon: widget.noImageIcon,
        mainMessage: widget.mainEmptyMessage,
        secondaryMessage: widget.secondaryEmptyMessage,
      );
    }
    return Stack(
      children: [
        ListView.builder(
          physics: NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: widget.images.length,
          itemBuilder: (context, index) {
            var entry = widget.images[index];
            var allChecked = true;
            for (var item in entry[1]) {
              if (!_selectedImages.contains(item[0] as int)) {
                allChecked = false;
                break;
              }
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          widget.isBin
                              ? '${entry[0]} days left'
                              : intl.DateFormat('d MMM yyyy')
                                  .format(DateTime.parse(entry[0])),
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        GestureDetector(
                          onTap: () {
                            if (allChecked) {
                              setState(() {
                                for (var item in entry[1]) {
                                  _selectedImages.remove(item[0] as int);
                                }
                              });
                            } else {
                              setState(() {
                                for (var item in entry[1]) {
                                  _selectedImages.add(item[0] as int);
                                }
                              });
                            }
                          },
                          child: Icon(
                            allChecked
                                ? Icons.check_circle
                                : Icons.check_circle_outline,
                            size: 30,
                            color: allChecked ? Colors.blue : Colors.grey,
                          ),
                        ),
                      ],
                    )),
                GridView.count(
                  crossAxisCount: widget.gridCount,
                  crossAxisSpacing: 3,
                  mainAxisSpacing: 3,
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  children: List.generate((entry[1] as List<dynamic>).length,
                      (index) {
                    var item = entry[1][index] as List<dynamic>;
                    var imageId = item[0] as int;

                    return GestureDetector(
                      onTap: () {
                        if (_selectedImages.isNotEmpty) {
                          _toggleSelection(imageId);
                        } else {
                          // Open the image normally
                          Navigator.push(
                              context,
                              widget.isBin
                                  ? MaterialPageRoute(
                                      builder: (context) => ImageDetailScreen(
                                        widget.ip,
                                        imageId,
                                        date: null,
                                      ),
                                    )
                                  : MaterialPageRoute(
                                      builder: (context) => ImageDetailScreen(
                                        widget.ip,
                                        imageId,
                                        date: entry[0].replaceAll('-', '/'),
                                      ),
                                    ));
                        }
                      },
                      onLongPress: () {
                        _toggleSelection(imageId);
                      },
                      child: Stack(
                        children: [
                          CachedNetworkImage(
                            imageUrl:
                                'http://${widget.ip}:7251/api/preview/meet244/$imageId',
                            placeholder: (context, url) => Center(
                                child: const CircularProgressIndicator()),
                            errorWidget: (context, url, error) => Center(
                                child: const Icon(
                              Icons.error,
                              color: Colors.red,
                            )),
                            imageBuilder: (context, imageProvider) => Container(
                              decoration: BoxDecoration(
                                image: DecorationImage(
                                  image: imageProvider,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                          if (_selectedImages.contains(imageId))
                            Positioned.fill(
                              child: Container(
                                color: Colors.black.withOpacity(0.5),
                                child: Icon(
                                  Icons.check_circle,
                                  color: Colors.white,
                                  size: 50,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  }),
                ),
              ],
            );
          },
        ),
        // if (_selectedImages.isNotEmpty)
        //   Positioned(
        //     bottom: 0,
        //     left: 0,
        //     right: 0,
        //     child: Container(
        //       decoration: BoxDecoration(
        //         color: Colors.grey[200],
        //         borderRadius: const BorderRadius.only(
        //           topLeft: Radius.circular(10),
        //           topRight: Radius.circular(10),
        //         ),
        //       ),
        //       padding: const EdgeInsets.all(8.0),
        //       child: Row(
        //         mainAxisAlignment: MainAxisAlignment.spaceAround,
        //         children: [
        //           if (widget.isBin)
        //             Column(
        //               children: [
        //                 IconButton(
        //                   onPressed: _onDelete,
        //                   icon: const Icon(Icons.delete_outline),
        //                 ),
        //                 Text('Delete Premanently'),
        //               ],
        //             ),
        //           if (widget.isBin)
        //             Column(
        //               children: [
        //                 IconButton(
        //                   onPressed: restoreImage,
        //                   icon: const Icon(
        //                       Icons.settings_backup_restore_outlined),
        //                 ),
        //                 Text('Restore'),
        //               ],
        //             ),
        //           if (widget.isNormal)
        //             Column(
        //               children: [
        //                 IconButton(
        //                   onPressed: _onSend,
        //                   icon: const Icon(Icons.share_outlined),
        //                 ),
        //                 Text('Share'),
        //               ],
        //             ),
        //           if (widget.isNormal)
        //             Column(
        //               children: [
        //                 IconButton(
        //                   onPressed: _onDelete,
        //                   icon: const Icon(Icons.delete_outline),
        //                 ),
        //                 Text('Delete'),
        //               ],
        //             ),
        //           if (widget.isNormal)
        //             Column(
        //               children: [
        //                 IconButton(
        //                   onPressed: _onAdd,
        //                   icon: const Icon(Icons.add_outlined),
        //                 ),
        //                 Text('Add to'),
        //               ],
        //             ),
        //           if (widget.isNormal)
        //             Column(
        //               children: [
        //                 IconButton(
        //                   onPressed: _editDate,
        //                   icon: const Icon(Icons.edit_calendar_outlined),
        //                 ),
        //                 Text('Edit Date'),
        //               ],
        //             ),
        //           if (widget.isNormal)
        //             Column(
        //               children: [
        //                 IconButton(
        //                   onPressed: _moveToFamily,
        //                   icon: const Icon(Icons.groups_2_outlined),
        //                 ),
        //                 Text('Move to Family'),
        //               ],
        //             ),
        //           if (widget.isAlbum)
        //             Column(
        //               children: [
        //                 IconButton(
        //                   onPressed: removeAlbumImages,
        //                   icon: const Icon(Icons.close_outlined),
        //                 ),
        //                 Text('Remove from Album'),
        //               ],
        //             ),
        //         ],
        //       ),
        //     ),
        //   ),
      ],
    );
  }
}

class NothingMessage extends StatelessWidget {
  final IconData icon;
  final String mainMessage;
  final String secondaryMessage;

  const NothingMessage(
      {super.key,
      required this.icon,
      required this.mainMessage,
      required this.secondaryMessage});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 100,
            color: Colors.grey,
          ),
          const SizedBox(height: 20),
          Text(
            mainMessage,
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(height: 20),
          Text(
            secondaryMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class ImageDetailScreen extends StatefulWidget {
  final int imageId;
  final String ip;
  final String? date;

  const ImageDetailScreen(this.ip, this.imageId, {this.date, super.key});

  @override
  _ImageDetailScreenState createState() => _ImageDetailScreenState();
}

class _ImageDetailScreenState extends State<ImageDetailScreen> {
  late Future<List<int>> _previewImageFuture;
  late Future<List<int>> _mainImageFuture;
  bool showBottomBar = true;
  bool isMainImageLoaded = false;
  Uint8List? mainImageBytes;
  bool isliked = false;

  @override
  void initState() {
    super.initState();
    _previewImageFuture = fetchPreviewImage();
    _mainImageFuture = fetchMainImage();
    _mainImageFuture.then((_) {
      setState(() {
        isMainImageLoaded = true;
      });
    });
    isImageLiked(widget.imageId);
    // SystemChrome.setEnabledSystemUIMode(SystemUiMode.leanBack,
    //     overlays: [SystemUiOverlay.top]);
  }

  @override
  void dispose() {
    super.dispose();
    // SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
    //     overlays: [SystemUiOverlay.top]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                showBottomBar = !showBottomBar;
              });
            },
            child: Stack(
              children: [
                FutureBuilder(
                  future: isMainImageLoaded
                      ? _mainImageFuture
                      : _previewImageFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else if (snapshot.hasData) {
                      return PhotoView(
                        imageProvider:
                            MemoryImage(Uint8List.fromList(snapshot.data!)),
                        minScale: PhotoViewComputedScale.contained,
                        maxScale: PhotoViewComputedScale.covered * 5.0,
                      );
                    } else {
                      return SizedBox(); // Return an empty widget if there's no data
                    }
                  },
                ),
                Visibility(
                  visible: !isMainImageLoaded,
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                showBottomBar = !showBottomBar;
              });
            },
            child: AnimatedOpacity(
              opacity: showBottomBar ? 1.0 : 0.0,
              duration: Duration(milliseconds: 200),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  padding: EdgeInsets.all(16),
                  // color: Colors.black.withOpacity(0.5),
                  color: Colors.transparent,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      IconButton(
                        onPressed: () {
                          // ask for confirmation
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Text('Confirmation'),
                                content: Text(
                                    'Are you sure you want to delete this image?'),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      // Call delete image API here
                                      deleteImage([widget.imageId.toString()]);
                                      Navigator.of(context).pop();
                                      // go to previous screen with message that imageid is deleted
                                      Navigator.pop(context, widget.imageId);
                                    },
                                    child: Text('Delete'),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        icon: Icon(Icons.delete_outline, color: Colors.white),
                      ),
                      if (widget.date != null)
                        IconButton(
                          onPressed: () {
                            shareImage();
                          },
                          icon: Icon(Icons.share_outlined, color: Colors.white),
                        ),
                      if (widget.date != null)
                        if (isliked)
                          IconButton(
                            onPressed: () {
                              // make API call to unlike image
                              likeImage(widget.imageId);
                            },
                            icon: Icon(Icons.favorite, color: Colors.red),
                          )
                        else
                          IconButton(
                            onPressed: () {
                              // make API call to like image
                              likeImage(widget.imageId);
                            },
                            icon: Icon(Icons.favorite_outline,
                                color: Colors.white),
                          ),
                      if (widget.date == null)
                        IconButton(
                          onPressed: () {
                            // Add restore logic here
                            restoreImage([widget.imageId.toString()]);
                            Navigator.pop(context, widget.imageId);
                          },
                          icon: const Icon(
                              Icons.settings_backup_restore_outlined,
                              color: Colors.white),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          AnimatedOpacity(
            opacity: showBottomBar ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16),
              height: kToolbarHeight,
              color: Colors.transparent,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  if (widget.date != null)
                    IconButton(
                      icon: Icon(Icons.more_vert, color: Colors.white),
                      onPressed: () {
                        // Handle dot-dot-dot options button press
                        showModalBottomSheet(
                          enableDrag: true,
                          isScrollControlled: true,
                          context: context,
                          builder: (BuildContext context) {
                            // Use a FutureBuilder to show loading indicator and handle API response
                            return FutureBuilder(
                              future: fetchDetails(widget.imageId),
                              builder: (BuildContext context,
                                  AsyncSnapshot<dynamic> snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return Container(
                                    height: 200,
                                    alignment: Alignment.center,
                                    child: CircularProgressIndicator(),
                                  );
                                } else {
                                  if (snapshot.hasError) {
                                    return Text('Error: ${snapshot.error}');
                                  } else {
                                    // API call successful, show details in bottom sheet
                                    return DraggableScrollableSheet(
                                      expand: false,
                                      minChildSize: 0.3,
                                      maxChildSize: 1,
                                      initialChildSize: 0.5,
                                      builder: (BuildContext context,
                                          ScrollController scrollController) {
                                        return ListView(
                                          controller: scrollController,
                                          // mainAxisSize: MainAxisSize.min,
                                          children: [
                                            // Faces will show up here
                                            const SizedBox(height: 20),
                                            if (snapshot
                                                .data['faces'].isNotEmpty)
                                              const Padding(
                                                padding: EdgeInsets.symmetric(
                                                    horizontal: 20),
                                                child: Text("Faces",
                                                    style: TextStyle(
                                                        fontSize: 24,
                                                        fontWeight:
                                                            FontWeight.bold)),
                                              ),
                                            if (snapshot
                                                .data['faces'].isNotEmpty)
                                              FaceList(
                                                faceNames:
                                                    snapshot.data['faces'],
                                                ip: widget.ip,
                                                isSquared: true,
                                              ),

                                            const Padding(
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 20),
                                              child: Text("Details",
                                                  style: TextStyle(
                                                      fontSize: 24,
                                                      fontWeight:
                                                          FontWeight.bold)),
                                            ),
                                            DetailComponent(
                                              iconData: Icons.event_outlined,
                                              title: DateFormat('d MMM yyyy')
                                                  .format(
                                                      DateFormat('dd-MM-yyyy')
                                                          .parse(snapshot
                                                              .data['date']
                                                              .toString())),
                                              subtitle:
                                                  "${DateFormat('E').format(DateFormat('dd-MM-yyyy').parse(snapshot.data['date'].toString().replaceAll('/', '-')))}, ${snapshot.data['time']}",
                                            ),
                                            DetailComponent(
                                                iconData: Icons.image_outlined,
                                                title: snapshot.data['name'],
                                                subtitle:
                                                    "${snapshot.data['mp']} • ${snapshot.data['width']} x ${snapshot.data['height']}"),
                                            DetailComponent(
                                                iconData:
                                                    Icons.cloud_done_outlined,
                                                title:
                                                    'Backed Up (${snapshot.data['size']})',
                                                subtitle:
                                                    "${snapshot.data['format'].toString().toUpperCase()} • ${(snapshot.data['compress'] == "false") ? "Original" : "Compressed"}"),
                                            if (snapshot.data['location'] !=
                                                null)
                                              DetailComponent(
                                                  iconData: Icons
                                                      .location_on_outlined,
                                                  title: 'Location',
                                                  subtitle: snapshot
                                                          .data['location']
                                                          ?.toString() ??
                                                      'Unknown'),
                                            if (snapshot
                                                .data['tags'].isNotEmpty)
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 8.0,
                                                        horizontal: 20.0),
                                                child: Row(
                                                  children: [
                                                    const Icon(
                                                      Icons.sell_outlined,
                                                      size: 40,
                                                    ),
                                                    const SizedBox(width: 20),
                                                    Expanded(
                                                      child: Wrap(
                                                        spacing: 5.0,
                                                        runSpacing: 5.0,
                                                        alignment:
                                                            WrapAlignment.start,
                                                        children:
                                                            List<Widget>.from(
                                                          snapshot.data['tags']
                                                              .map(
                                                            (tag) => Chip(
                                                              label: Text(tag
                                                                  .toString()),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            const SizedBox(height: 20),
                                          ],
                                        );
                                      },
                                    );
                                  }
                                }
                              },
                            );
                          },
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> shareImage() async {
    try {
      final mainImageBytes = await fetchMainImage();

      // Save the main image to a temporary file

      final tempDir = await getTemporaryDirectory();

      final tempFile = File('${tempDir.path}/temp_image.png');

      await tempFile.writeAsBytes(mainImageBytes);

      // Share the image using the share_plus package

      await Share.shareFiles(
        ['${tempFile.path}'],
        text: 'I shared this image from PicFolio. Try it out!',
        subject: 'Image Sharing',
      );
    } catch (e) {
      print('Error sharing image: $e');

      // Handle the error, e.g., show a snackbar or log the error
    }
  }

  Future<Map<String, dynamic>> fetchDetails(int photoId) async {
    final response = await http.get(
        Uri.parse('http://${widget.ip}:7251/api/details/meet244/$photoId'));
    if (response.statusCode == 200) {
      // var d = json.decode(response.body);
      // print(d['faces'].keys);
      // Map<String, String> facesMap = d['faces'].keys.fold({}, (map, i) {
      //   map[i] = d['faces'][i].toString();
      //   return map;
      // });
      // print(facesMap);
      return json.decode(response.body);
    } else {
      throw Exception('Failed to fetch details');
    }
  }

  Future<void> likeImage(int photoId) async {
    final response = await http.post(
      Uri.parse('http://${widget.ip}:7251/api/like/meet244/$photoId'),
      body: {'username': 'meet244'},
    );
    if (response.statusCode == 200) {
      print('Image Liked/Unliked');
      setState(() {
        isliked = !isliked;
      });
    } else {
      throw Exception('Failed to like image');
    }
  }

  Future<void> isImageLiked(int photoId) async {
    final response = await http.get(
      Uri.parse('http://${widget.ip}:7251/api/liked/meet244/$photoId'),
    );
    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      setState(() {
        isliked = data;
      });
    } else {
      throw Exception('Failed to get liked data');
    }
  }

  Future<void> deleteImage(List<String> imageIds) async {
    var imgs = imageIds.join(',');
    final response = await http
        .delete(Uri.parse('http://${widget.ip}:7251/api/delete/meet244/$imgs'));
    if (response.statusCode == 200) {
      print('Image deleted');
    } else {
      throw Exception('Failed to delete image');
    }
  }

  Future<void> restoreImage(List<String> imageIds) async {
    var imgs = imageIds.join(',');
    final response = await http
        .post(Uri.parse('http://${widget.ip}:7251/api/restore/meet244/$imgs'));
    if (response.statusCode == 200) {
      print('Image restored');
    } else {
      throw Exception('Failed to restore image');
    }
  }

  Future<List<int>> fetchPreviewImage() async {
    // print(widget.date);
    String url;
    if (widget.date != null) {
      url = 'http://${widget.ip}:7251/api/preview/meet244/${widget.imageId}/${widget.date}';
    } else {
      url = 'http://${widget.ip}:7251/api/preview/meet244/${widget.imageId}';
    }
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      throw Exception('Failed to load preview image');
    }
  }

  Future<List<int>> fetchMainImage() async {
    String url;
    if (widget.date != null) {
      url =
          'http://${widget.ip}:7251/api/asset/meet244/${widget.imageId}/${widget.date}';
    } else {
      url = 'http://${widget.ip}:7251/api/asset/meet244/${widget.imageId}';
    }
    print(url);
    print(widget.date != null);
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      mainImageBytes = response.bodyBytes;
      return response.bodyBytes;
    } else if (response.statusCode == 304) {
      return mainImageBytes!;
    } else {
      throw Exception('Failed to load main image');
    }
  }
}

class DetailComponent extends StatelessWidget {
  final IconData iconData;
  final String title;
  final String subtitle;

  const DetailComponent({
    super.key,
    required this.iconData,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 20.0),
      child: Row(
        children: [
          Icon(iconData, size: 40),
          SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    overflow: TextOverflow.ellipsis,
                    fontSize: 20,
                    color: Colors.black,
                  ),
                  textAlign:
                      subtitle.isEmpty ? TextAlign.center : TextAlign.start,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black.withOpacity(0.5),
                    ),
                    textAlign: TextAlign.start,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
