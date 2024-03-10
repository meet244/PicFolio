import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photoz/widgets/face.dart';


// ignore: must_be_immutable
class ImageGridView extends StatefulWidget {
  final Map<String, List<int>> images;
  final int gridCount;
  final String ip;
  final IconData noImageIcon;
  final String mainEmptyMessage;
  final String secondaryEmptyMessage;
  bool isBin = false;

  ImageGridView({
    super.key,
    required this.ip,
    required this.images,
    required this.gridCount,
    required this.noImageIcon,
    required this.mainEmptyMessage,
    required this.secondaryEmptyMessage,
    this.isBin = false,
  });

  @override
  _ImageGridViewState createState() => _ImageGridViewState();
}

class _ImageGridViewState extends State<ImageGridView> {
  Map<int, List<int>> loadedImages = {};
  final List<int> _selectedImages = [];

  Future<List<int>> fetchPreviewImage(int imageId, String date) async {
    date = date.replaceAll('-', '/');
    String url = 'http://${widget.ip}:7251/api/preview/meet244/$imageId/$date';
    if (widget.isBin) {
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
    setState(() {
      if (_selectedImages.contains(imageId)) {
        _selectedImages.remove(imageId);
      } else {
        _selectedImages.add(imageId);
      }
    });
  }

  void _onSend() {
    // Implement your send logic here
    print(_selectedImages);
    setState(() {
      _selectedImages.clear(); // Clear selected images after sending
    });
  }

  void _onDelete() {
    // Implement your delete logic here
    print(_selectedImages);
    setState(() {
      _selectedImages.clear(); // Clear selected images after sending
    });
  }

  void _onAdd() {
    // Implement your add logic here
    print(_selectedImages);
    setState(() {
      _selectedImages.clear(); // Clear selected images after sending
    });
  }

  void _editDate() {
    // Implement your edit date logic here
    print(_selectedImages);
    setState(() {
      _selectedImages.clear(); // Clear selected images after sending
    });
  }

  void _moveToFamily() {
    // Implement your move to family logic here
    print(_selectedImages);
    setState(() {
      _selectedImages.clear(); // Clear selected images after sending
    });
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
          itemCount: widget.images.length,
          itemBuilder: (context, index) {
            var entry = widget.images.entries.toList()[index];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    widget.isBin
                        ? '${entry.key} days left'
                        : intl.DateFormat('d MMM yyyy')
                            .format(DateTime.parse(entry.key)),
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                GridView.count(
                  crossAxisCount: widget.gridCount,
                  crossAxisSpacing: 3,
                  mainAxisSpacing: 3,
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  children: entry.value.map((imageId) {
                    if (loadedImages.containsKey(imageId)) {
                      // Image is already loaded, use the cached image
                      return GestureDetector(
                        onTap: () {
                          if (_selectedImages.isNotEmpty) {
                            _toggleSelection(imageId);
                          } else {
                            // Open the image normally
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ImageDetailScreen(
                                  widget.ip,
                                  imageId,
                                  date: entry.key.replaceAll('-', '/'),
                                ),
                              ),
                            );
                          }
                        },
                        onLongPress: () {
                          _toggleSelection(imageId);
                        },
                        child: Stack(
                          children: [
                            Image.memory(
                              Uint8List.fromList(loadedImages[imageId]!),
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                            if (_selectedImages.contains(imageId))
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
                      );
                    } else {
                      // Image is not loaded, fetch and cache the image
                      return FutureBuilder(
                        future: fetchPreviewImage(imageId, entry.key),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const CircularProgressIndicator();
                          } else if (snapshot.hasError) {
                            return Text('Error: ${snapshot.error}');
                          } else if (snapshot.hasData &&
                              snapshot.data!.isNotEmpty) {
                            // Cache the loaded image
                            loadedImages[imageId] =
                                snapshot.data as List<int>;
                            return GestureDetector(
                              onTap: () {
                                if (_selectedImages.isNotEmpty) {
                                  _toggleSelection(imageId);
                                } else {
                                  // Open the image normally
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ImageDetailScreen(
                                        widget.ip,
                                        imageId,
                                        date: entry.key.replaceAll('-', '/'),
                                      ),
                                    ),
                                  );
                                }
                              },
                              onLongPress: () {
                                _toggleSelection(imageId);
                              },
                              child: Stack(
                                children: [
                                  Image.memory(
                                    Uint8List.fromList(
                                        snapshot.data as List<int>),
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                  ),
                                  if (_selectedImages.contains(imageId))
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
                            );
                          } else {
                            return NothingMessage(
                              icon: widget.noImageIcon,
                              mainMessage: widget.mainEmptyMessage,
                              secondaryMessage:
                                  widget.secondaryEmptyMessage,
                            );
                          }
                        },
                      );
                    }
                  }).toList(),
                ),
              ],
            );
          },
        ),
        if (_selectedImages.isNotEmpty)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                ),
              ),
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      IconButton(
                        onPressed: _onSend,
                        icon: const Icon(Icons.share_outlined),
                      ),
                      Text('Share'),
                    ],
                  ),
                  Column(
                    children: [
                      IconButton(
                        onPressed: _onDelete,
                        icon: const Icon(Icons.delete_outline),
                      ),
                      Text('Delete'),
                    ],
                  ),
                  Column(
                    children: [
                      IconButton(
                        onPressed: _onAdd,
                        icon: const Icon(Icons.add_outlined),
                      ),
                      Text('Add to'),
                    ],
                  ),
                  Column(
                    children: [
                      IconButton(
                        onPressed: _editDate,
                        icon: const Icon(Icons.edit_calendar_outlined),
                      ),
                      Text('Edit Date'),
                    ],
                  ),
                  Column(
                    children: [
                      IconButton(
                        onPressed: _moveToFamily,
                        icon: const Icon(Icons.groups_2_outlined),
                      ),
                      Text('Move to Family'),
                    ],
                  ),
                
                ],
              ),
            ),
          ),
      ],
    );
  }
}



// class ImageGridView extends StatefulWidget {
//   final Map<String, List<int>> images;
//   final int gridCount;
//   final String ip;
//   final IconData noImageIcon;
//   final String mainEmptyMessage;
//   final String secondaryEmptyMessage;
//   bool isBin = false;

//   ImageGridView({
//     Key? key,
//     required this.ip,
//     required this.images,
//     required this.gridCount,
//     required this.noImageIcon,
//     required this.mainEmptyMessage,
//     required this.secondaryEmptyMessage,
//     this.isBin = false,
//   }) : super(key: key);

//   @override
//   _ImageGridViewState createState() => _ImageGridViewState();
// }

// class _ImageGridViewState extends State<ImageGridView> {
//   Map<int, List<int>> loadedImages = {};
//   List<int> _selectedImages = [];
//   bool _isBottomFragmentVisible = false; // Track visibility of the bottom fragment

//   Future<List<int>> fetchPreviewImage(int imageId, String date) async {
//     date = date.replaceAll('-', '/');
//     String url = 'http://${widget.ip}:7251/api/preview/meet244/$imageId/$date';
//     if (widget.isBin) {
//       url = 'http://${widget.ip}:7251/api/preview/meet244/$imageId';
//     } else {
//       url = 'http://${widget.ip}:7251/api/preview/meet244/$imageId/$date';
//     }
//     final response = await http.get(Uri.parse(url));
//     if (response.statusCode == 200) {
//       return response.bodyBytes;
//     } else {
//       throw Exception('Failed to load preview image ${response.statusCode}');
//     }
//   }

//   void _toggleSelection(int imageId) {
//     setState(() {
//       if (_selectedImages.contains(imageId)) {
//         _selectedImages.remove(imageId);
//       } else {
//         _selectedImages.add(imageId);
//       }

//       // Check if any images are selected to show/hide the bottom fragment
//       _isBottomFragmentVisible = _selectedImages.isNotEmpty;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (widget.images.isEmpty) {
//       return NothingMessage(
//         icon: widget.noImageIcon,
//         mainMessage: widget.mainEmptyMessage,
//         secondaryMessage: widget.secondaryEmptyMessage,
//       );
//     }
//     return ListView.builder(
//       itemCount: widget.images.length,
//       itemBuilder: (context, index) {
//         var entry = widget.images.entries.toList()[index];
//         return Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Padding(
//               padding: const EdgeInsets.all(8.0),
//               child: Text(
//                 widget.isBin
//                     ? '${entry.key} days left'
//                     : intl.DateFormat('d MMM yyyy')
//                         .format(DateTime.parse(entry.key)),
//                 style:
//                     const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//               ),
//             ),
//             GridView.count(
//               crossAxisCount: widget.gridCount,
//               crossAxisSpacing: 3,
//               mainAxisSpacing: 3,
//               physics: const NeverScrollableScrollPhysics(),
//               shrinkWrap: true,
//               children: entry.value.map((imageId) {
//                 if (loadedImages.containsKey(imageId)) {
//                   // Image is already loaded, use the cached image
//                   return GestureDetector(
//                     onTap: () {
//                       if (_selectedImages.isNotEmpty) {
//                         _toggleSelection(imageId);
//                       } else {
//                         // Open the image normally
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (context) => ImageDetailScreen(
//                               widget.ip,
//                               imageId,
//                               date: entry.key.replaceAll('-', '/'),
//                             ),
//                           ),
//                         );
//                       }
//                     },
//                     onLongPress: () {
//                       _toggleSelection(imageId);
//                     },
//                     child: Stack(
//                       children: [
//                         Image.memory(
//                           Uint8List.fromList(loadedImages[imageId]!),
//                           fit: BoxFit.cover,
//                           width: double.infinity,
//                           height: double.infinity,
//                         ),
//                         if (_selectedImages.contains(imageId))
//                           Positioned.fill(
//                             child: Container(
//                               color: Colors.black.withOpacity(0.5),
//                               child: Icon(
//                                 Icons.check_circle,
//                                 color: Colors.blue,
//                                 size: 40,
//                               ),
//                             ),
//                           ),
//                       ],
//                     ),
//                   );
//                 } else {
//                   // Image is not loaded, fetch and cache the image
//                   return FutureBuilder(
//                     future: fetchPreviewImage(imageId, entry.key),
//                     builder: (context, snapshot) {
//                       if (snapshot.connectionState == ConnectionState.waiting) {
//                         return const CircularProgressIndicator();
//                       } else if (snapshot.hasError) {
//                         return Text('Error: ${snapshot.error}');
//                       } else if (snapshot.hasData &&
//                           snapshot.data!.isNotEmpty) {
//                         // Cache the loaded image
//                         loadedImages[imageId] = snapshot.data as List<int>;
//                         return GestureDetector(
//                           onTap: () {
//                             if (_selectedImages.isNotEmpty) {
//                               _toggleSelection(imageId);
//                             } else {
//                               // Open the image normally
//                               Navigator.push(
//                                 context,
//                                 MaterialPageRoute(
//                                   builder: (context) => ImageDetailScreen(
//                                     widget.ip,
//                                     imageId,
//                                     date: entry.key.replaceAll('-', '/'),
//                                   ),
//                                 ),
//                               );
//                             }
//                           },
//                           onLongPress: () {
//                             _toggleSelection(imageId);
//                           },
//                           child: Stack(
//                             children: [
//                               Image.memory(
//                                 Uint8List.fromList(snapshot.data as List<int>),
//                                 fit: BoxFit.cover,
//                                 width: double.infinity,
//                                 height: double.infinity,
//                               ),
//                               if (_selectedImages.contains(imageId))
//                                 Positioned.fill(
//                                   child: Container(
//                                     color: Colors.black.withOpacity(0.5),
//                                     child: Icon(
//                                       Icons.check_circle,
//                                       color: Colors.blue,
//                                       size: 40,
//                                     ),
//                                   ),
//                                 ),
//                             ],
//                           ),
//                         );
//                       } else {
//                         return NothingMessage(
//                           icon: widget.noImageIcon,
//                           mainMessage: widget.mainEmptyMessage,
//                           secondaryMessage: widget.secondaryEmptyMessage,
//                         );
//                       }
//                     },
//                   );
//                 }
//               }).toList(),
//             ),
//           ],
//         );
//       },
//     );
//   }
// }

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

  ImageDetailScreen(this.ip, this.imageId, {this.date, Key? key})
      : super(key: key);

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
                            // Add share logic here
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
                                                faceNames: snapshot
                                                    .data['faces']
                                                    .cast<String, String>(),
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
                                                  .format(DateFormat('dd-MM-yyyy').parse(
                                                      snapshot.data['date']
                                                          .toString())),
                                              subtitle:"${DateFormat('E').format(DateFormat('dd-MM-yyyy').parse(snapshot.data['date'].toString().replaceAll('/', '-')))}, ${snapshot.data['time']}",
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
    print(widget.date);
    String url;
    if (widget.date != null) {
      url =
          'http://${widget.ip}:7251/api/preview/meet244/${widget.imageId}/${widget.date}';
    } else {
      url = 'http://${widget.ip}:7251/api/preview/meet244/${widget.imageId}';
    }
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      print(response.statusCode);
      print(response.reasonPhrase);
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
