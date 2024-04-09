// ignore_for_file: prefer_const_constructors

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photoz/globals.dart';
import 'package:photoz/screens/all_people.dart';
import 'package:photoz/widgets/face.dart';
import 'package:share_plus/share_plus.dart';
import 'package:appinio_video_player/appinio_video_player.dart';
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
    String url = '${Globals.ip}:7251/api/preview/${Globals.username}/$imageId/$date';
    if (widget.isBin || date == '') {
      url = '${Globals.ip}:7251/api/preview/${Globals.username}/$imageId';
    } else {
      url = '${Globals.ip}:7251/api/preview/${Globals.username}/$imageId/$date';
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

  Future<void> restoreImage() async {
    var imgs = _selectedImages.join(',');
    final response = await http
        .post(Uri.parse('${Globals.ip}:7251/api/restore/${Globals.username}/$imgs'));
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
        .post(Uri.parse('${Globals.ip}:7251/api/album/remove'), body: {
      'username': '${Globals.username}',
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
                                widget.onSelectionChanged(_selectedImages);
                              });
                            } else {
                              setState(() {
                                for (var item in entry[1]) {
                                  if (!_selectedImages
                                      .contains(item[0] as int)) {
                                    _selectedImages.add(item[0] as int);
                                  }
                                }
                                widget.onSelectionChanged(_selectedImages);
                              });
                            }
                          },
                          child: Icon(
                            allChecked
                                ? Icons.check_circle
                                : Icons.check_circle_outline,
                            size: 30,
                            color: Colors.grey,
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
                                        Globals.ip,
                                        imageId,
                                        date: null,
                                      ),
                                    )
                                  : MaterialPageRoute(
                                      builder: (context) => ImageDetailScreen(
                                        Globals.ip,
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
                          Hero(
                            tag: imageId.toString(),
                            child: CachedNetworkImage(
                              imageUrl:
                                  '${Globals.ip}:7251/api/preview/${Globals.username}/$imageId',
                              placeholder: (context, url) => Center(
                                child: const CircularProgressIndicator(),
                              ),
                              errorWidget: (context, url, error) => Center(
                                child: const Icon(
                                  Icons.error,
                                  color: Colors.red,
                                ),
                              ),
                              imageBuilder: (context, imageProvider) =>
                                  Container(
                                decoration: BoxDecoration(
                                  image: DecorationImage(
                                    image: imageProvider,
                                    fit: BoxFit.cover,
                                  ),
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
                          if (item.length > 2 && item[2] != null)
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomLeft,
                                    end: Alignment.center,
                                    colors: [
                                      Colors.black.withOpacity(1),
                                      Colors.transparent
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          if (item.length > 2 && item[2] != null)
                            Positioned(
                              bottom: 7,
                              left: 7,
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.play_circle_fill,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    item[2].toString(),
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
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
  bool isImage = true;

  var imageDetails;

  late VideoPlayerController videoPlayerController;
  late CustomVideoPlayerController _customVideoPlayerController;

  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _previewImageFuture = fetchPreviewImage();
    isImageLiked(widget.imageId);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.leanBack,
        overlays: [SystemUiOverlay.top]);
    videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(
        "http://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4"))
      ..initialize().then((value) => setState(() {}));
    _customVideoPlayerController = CustomVideoPlayerController(
      context: context,
      videoPlayerController: videoPlayerController,
    );
    _controller = VideoPlayerController.networkUrl(
      Uri.parse(
          'http://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4'),
    );

    _controller.setLooping(false);
    // _controller.play();
    super.initState();
  }

  @override
  void dispose() {
    if (!isImage) {
      _controller.dispose();
      _customVideoPlayerController.dispose();
    }
    super.dispose();
    // SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
    //     overlays: [SystemUiOverlay.top]);
  }

  void initPhoto() {
    _mainImageFuture = fetchMainImage();
    _mainImageFuture.then((_) {
      setState(() {
        isMainImageLoaded = true;
      });
    });
  }

  Future<void> initVideo() async {
    videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(
        "${Globals.ip}:7251/api/asset/${Globals.username}/${widget.imageId}/${widget.date}"))
      ..initialize().then((value) => setState(() {}));
    _customVideoPlayerController = CustomVideoPlayerController(
      context: context,
      videoPlayerController: videoPlayerController,
    );
    // print("asseting");

    // _controller = VideoPlayerController.networkUrl(
    //   // Uri.parse('http://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4'),
    //   Uri.parse('${Globals.ip}:7251/api/asset/${Globals.username}/${widget.imageId}/${widget.date}'),
    // );
    // _initializeVideoPlayerFuture = _controller.initialize();

    // _controller.setLooping(false);
    // _controller.play();
    setState(() {
      isImage = false;
    });
  }

  Future<void> addFace(String faceId) async {
    final response = await http
        .post(Uri.parse('${Globals.ip}:7251/api/face/add'), body: {
      'username': '${Globals.username}',
      'asset_id': widget.imageId.toString(),
      'face_id': faceId,
    });
    if (response.statusCode == 200) {
      print('Face added');
    } else {
      throw Exception('Failed to add face');
    }
  }

  Future<void> removeFace(String faceId) async {
    final response = await http
        .post(Uri.parse('${Globals.ip}:7251/api/face/remove'), body: {
      'username': '${Globals.username}',
      'asset_id': widget.imageId.toString(),
      'face_id': faceId,
    });
    if (response.statusCode == 200) {
      print('Face removed');
    } else {
      throw Exception('Failed to remove face');
    }
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
              child: Hero(
                tag: widget.imageId.toString(),
                child: (isImage)
                    ? FutureBuilder(
                        future: isMainImageLoaded
                            ? _mainImageFuture
                            : _previewImageFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          } else if (snapshot.hasError) {
                            return Center(
                                child: Text('Error: ${snapshot.error}'));
                          } else if (snapshot.hasData) {
                            return (isImage)
                                ? PhotoView(
                                    imageProvider: MemoryImage(
                                        Uint8List.fromList(snapshot.data!)),
                                    minScale: PhotoViewComputedScale.contained,
                                    maxScale:
                                        PhotoViewComputedScale.covered * 5.0,
                                  )
                                : Center(
                                    child: Text('Image not supported'),
                                  );
                          } else {
                            return SizedBox(); // Return an empty widget if there's no data
                          }
                        },
                      )
                    : SafeArea(
                        child: Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 65),
                            child: AspectRatio(
                              aspectRatio:
                                  videoPlayerController.value.aspectRatio,
                              child: CustomVideoPlayer(
                                customVideoPlayerController:
                                    _customVideoPlayerController,
                              ),
                            ),
                          ),
                        ),
                      ),
                // : FutureBuilder(
                //     future: _initializeVideoPlayerFuture,
                //     builder: (context, snapshot) {
                //       if (snapshot.connectionState == ConnectionState.done) {
                //         return GestureDetector(
                //           onTap: () {
                //             setState(() {
                //               if (_controller.value.isPlaying) {
                //                 _controller.pause();
                //               } else {
                //                 _controller.play();
                //               }
                //             });
                //           },
                //           child: Padding(
                //             padding: const EdgeInsets.symmetric(vertical: 60),
                //             child: Center(
                //               child: AspectRatio(
                //                 aspectRatio: _controller.value.aspectRatio,
                //                 child: VideoPlayer(_controller),
                //               ),
                //             ),
                //           ),
                //         );
                //       } else {
                //         return Center(child: CircularProgressIndicator());
                //       }
                //     },
                //   ),
              ),
            ),
            AnimatedOpacity(
              opacity: showBottomBar ? 1.0 : 0.0,
              duration: Duration(milliseconds: 200),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  padding: EdgeInsets.all(16),
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
            AnimatedOpacity(
              opacity: showBottomBar ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: SafeArea(
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
                            showDetails();
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ));
  }

  void showDetails() {
    showModalBottomSheet(
      enableDrag: true,
      isScrollControlled: true,
      context: context,
      builder: (BuildContext context) {
        // Use a FutureBuilder to show loading indicator and handle API response
        return FutureBuilder(
          future: fetchDetails(widget.imageId),
          builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
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
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Faces",
                                  style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold)),
                              Row(
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.add_circle_outline),
                                    onPressed: () {
                                      // Handle plus icon press
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => AllPeople(
                                            ip: Globals.ip,
                                            removeFaceIds:
                                                snapshot.data['faces'],
                                            title: 'Add Someone...',
                                            isAdd: true,
                                          ),
                                        ),
                                      ).then((value) => {
                                            if (value != null)
                                              {
                                                addFace(value[0].toString()),
                                                Navigator.pop(context),
                                                setState(() {
                                                  snapshot.data['faces']
                                                      .add(value);
                                                  // close the bottom sheet
                                                }),
                                              }
                                          });
                                    },
                                  ),
                                  if (snapshot.data['faces'].isNotEmpty)
                                    IconButton(
                                      icon: Icon(Icons.remove_circle_outline),
                                      onPressed: () {
                                        // Handle minus icon press
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => AllPeople(
                                              ip: Globals.ip,
                                              removeFaceIds:
                                                  snapshot.data['faces'],
                                              title: 'Remove Someone...',
                                              isAdd: false,
                                            ),
                                          ),
                                        ).then((value) => {
                                              if (value != null)
                                                {
                                                  removeFace(
                                                      value[0].toString()),
                                                  Navigator.pop(context),
                                                  setState(() {
                                                    snapshot.data['faces']
                                                        .remove(value);
                                                  })
                                                }
                                            });
                                      },
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (snapshot.data['faces'].isEmpty)
                          SizedBox(
                            height: 10,
                          ),
                        if (snapshot.data['faces'].isNotEmpty)
                          FaceList(
                            faceNames: snapshot.data['faces'],
                            ip: Globals.ip,
                            isSquared: true,
                          ),

                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: Text("Details",
                              style: TextStyle(
                                  fontSize: 24, fontWeight: FontWeight.bold)),
                        ),
                        if (snapshot.data['date'] != null &&
                            snapshot.data['time'] != null)
                          DetailComponent(
                            iconData: Icons.event_outlined,
                            title: DateFormat('d MMM yyyy').format(
                                DateFormat('dd-MM-yyyy')
                                    .parse(snapshot.data['date'].toString())),
                            subtitle:
                                "${DateFormat('E').format(DateFormat('dd-MM-yyyy').parse(snapshot.data['date'].toString()))}, ${snapshot.data['time']}",
                          ),
                        if (snapshot.data['name'] != null &&
                            snapshot.data['mp'] != null &&
                            snapshot.data['width'] != null &&
                            snapshot.data['height'] != null)
                          DetailComponent(
                              iconData: Icons.image_outlined,
                              title: snapshot.data['name'],
                              subtitle:
                                  "${snapshot.data['mp']} • ${snapshot.data['width']} x ${snapshot.data['height']}"),
                        if (snapshot.data['size'] != null &&
                            snapshot.data['format'] != null &&
                            snapshot.data['compress'] != null)
                          DetailComponent(
                              iconData: Icons.cloud_done_outlined,
                              title: 'Backed Up (${snapshot.data['size']})',
                              subtitle:
                                  "${snapshot.data['format'].toString().toUpperCase()} • ${(snapshot.data['compress'] == "false") ? "Original" : "Compressed"}"),
                        if (snapshot.data['location'] != null)
                          DetailComponent(
                              iconData: Icons.location_on_outlined,
                              title: 'Location',
                              subtitle: snapshot.data['location']?.toString() ??
                                  'Unknown'),
                        if (snapshot.data['tags'].isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 8.0, horizontal: 20.0),
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
                                    alignment: WrapAlignment.start,
                                    children: List<Widget>.from(
                                      snapshot.data['tags'].map(
                                        (tag) => Chip(
                                          label: Text(tag.toString()),
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
    if (imageDetails != null) {
      return imageDetails;
    }
    final response = await http.get(
        Uri.parse('${Globals.ip}:7251/api/details/${Globals.username}/$photoId'));
    if (response.statusCode == 200) {
      imageDetails = json.decode(response.body);
      return imageDetails;
    } else {
      throw Exception('Failed to fetch details');
    }
  }

  Future<void> likeImage(int photoId) async {
    final response = await http.post(
      Uri.parse('${Globals.ip}:7251/api/like/${Globals.username}/$photoId'),
      body: {'username': '${Globals.username}'},
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
      Uri.parse('${Globals.ip}:7251/api/liked/${Globals.username}/$photoId'),
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
        .delete(Uri.parse('${Globals.ip}:7251/api/delete/${Globals.username}/$imgs'));
    if (response.statusCode == 200) {
      print('Image deleted');
    } else {
      throw Exception('Failed to delete image');
    }
  }

  Future<void> restoreImage(List<String> imageIds) async {
    var imgs = imageIds.join(',');
    final response = await http
        .post(Uri.parse('${Globals.ip}:7251/api/restore/${Globals.username}/$imgs'));
    if (response.statusCode == 200) {
      print('Image restored');
    } else {
      throw Exception('Failed to restore image');
    }
  }

  Future<List<int>> fetchPreviewImage() async {
    String url;
    if (widget.date != null) {
      url =
          '${Globals.ip}:7251/api/preview/${Globals.username}/${widget.imageId}/${widget.date}';
    } else {
      url = '${Globals.ip}:7251/api/preview/${Globals.username}/${widget.imageId}';
    }
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      if (response.headers['content-type'] != 'image/webp') {
        initVideo();
      } else {
        initPhoto();
      }
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
          '${Globals.ip}:7251/api/asset/${Globals.username}/${widget.imageId}/${widget.date}';
    } else {
      url = '${Globals.ip}:7251/api/asset/${Globals.username}/${widget.imageId}';
    }
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      mainImageBytes = response.bodyBytes;
      return response.bodyBytes;
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
          Icon(iconData, size: 30),
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
