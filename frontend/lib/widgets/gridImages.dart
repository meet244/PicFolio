import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:photo_view/photo_view.dart';

class ImageGridView extends StatefulWidget {
  final Map<String, List<int>> images;
  final int gridCount;
  final String ip;
  final IconData noImageIcon;
  final String mainEmptyMessage;
  final String secondaryEmptyMessage;

  const ImageGridView({super.key, 
    required this.ip,
    required this.images,
    required this.gridCount,
    required this.noImageIcon,
    required this.mainEmptyMessage,
    required this.secondaryEmptyMessage,
  });

  @override
  _ImageGridViewState createState() => _ImageGridViewState();
}

class _ImageGridViewState extends State<ImageGridView> {
  Future<List<int>> fetchPreviewImage(int imageId, String date) async {
    date = date.replaceAll('-', '/');
    final response = await http.get(Uri.parse(
        'http://${widget.ip}:7251/api/preview/meet244/$imageId/$date'));
    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      throw Exception('Failed to load preview image');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: widget.images.length,
      itemBuilder: (context, index) {
        var entry = widget.images.entries.toList()[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                intl.DateFormat('d MMM yyyy').format(DateTime.parse(entry.key)),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            GridView.count(
              crossAxisCount: widget.gridCount,
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              children: entry.value.map((imageId) {
                return FutureBuilder(
                  future: fetchPreviewImage(imageId, entry.key),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    } else if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ImageDetailScreen(
                                widget.ip,
                                imageId,
                                entry.key.replaceAll('-', '/'),
                              ),
                            ),
                          );
                          // widget.onImageTap(imageId, entry.key);
                        },
                        child: Image.memory(
                          Uint8List.fromList(snapshot.data as List<int>),
                          fit: BoxFit.cover,
                        ),
                      );
                    } else {
                      return NothingMessage(
                        icon: widget.noImageIcon,
                        mainMessage: widget.mainEmptyMessage,
                        secondaryMessage: widget.secondaryEmptyMessage,
                      );
                    }
                  },
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }
}

class NothingMessage extends StatelessWidget {
  final IconData icon;
  final String mainMessage;
  final String secondaryMessage;

  const NothingMessage({super.key, required this.icon, required this.mainMessage, required this.secondaryMessage});

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
  final String date;

  ImageDetailScreen(this.ip, this.imageId, this.date);

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
    _previewImageFuture =
        fetchPreviewImage(widget.ip, widget.imageId, widget.date);
    _mainImageFuture = fetchMainImage(widget.ip, widget.imageId, widget.date);
    _mainImageFuture.then((_) {
      setState(() {
        isMainImageLoaded = true;
      });
    });
    isImageLiked(widget.imageId);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.leanBack,
        overlays: [SystemUiOverlay.top]);
  }

  @override
  void dispose() {
    super.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: [SystemUiOverlay.top]);
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
                      return Center(
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
                      IconButton(
                        onPressed: () {
                          // Add share logic here
                        },
                        icon: Icon(Icons.share_outlined, color: Colors.white),
                      ),
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
                          icon:
                              Icon(Icons.favorite_outline, color: Colors.white),
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
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 20),
                                            child: Text("Faces",
                                                style: TextStyle(
                                                    fontSize: 24,
                                                    fontWeight: FontWeight.bold)),
                                          ),
                                          // Faces will show uo here
                                          
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 20),
                                            child: Text("Details",
                                                style: TextStyle(
                                                    fontSize: 24,
                                                    fontWeight: FontWeight.bold)),
                                          ),
                                          DetailComponent(
                                            iconData: Icons.event_outlined,
                                            title: DateFormat('d MMM yyyy')
                                                .format(DateTime.parse(widget
                                                    .date
                                                    .replaceAll('/', '-'))),
                                            subtitle:
                                                "${DateFormat('E').format(DateTime.parse(widget.date.replaceAll('/', '-')))}, ${snapshot.data['time']}",
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
                                          if (snapshot.data['faces']
                                              .toList()
                                              .isNotEmpty)
                                            DetailComponent(
                                                iconData: Icons.face_outlined,
                                                title: 'Faces',
                                                subtitle: snapshot.data['faces']
                                                    .map((face) =>
                                                        face.toString())
                                                    .join(', ')),
                                          if (snapshot.data['location'] != null)
                                            DetailComponent(
                                                iconData:
                                                    Icons.location_on_outlined,
                                                title: 'Location',
                                                subtitle: snapshot
                                                        .data['location']
                                                        ?.toString() ??
                                                    'Unknown'),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
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
                                                    children: List<Widget>.from(
                                                      snapshot.data['tags'].map(
                                                        (tag) => Chip(
                                                          label: Text(
                                                              tag.toString()),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Text(
                                            'Image ID: ${widget.imageId}',
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            "Faces: ${snapshot.data['faces'].map((face) => face.toString()).join(', ')}",
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
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
      Uri.parse('http://${widget.ip}:7251/api/like/meet244/$photoId'),
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

  Future<List<int>> fetchPreviewImage(
      String ip, int imageId, String date) async {
    final response = await http.get(Uri.parse(
        'http://${widget.ip}:7251/api/preview/meet244/$imageId/$date'));
    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      print(response.statusCode);
      print(response.reasonPhrase);
      throw Exception('Failed to load preview image');
    }
  }

  Future<List<int>> fetchMainImage(String ip, int imageId, String date) async {
    final response = await http.get(
        Uri.parse('http://${widget.ip}:7251/api/asset/meet244/$imageId/$date'));
    if (response.statusCode == 200) {
      mainImageBytes = response.bodyBytes;
      return response.bodyBytes;
    } else {
      print(response.statusCode);
      print(response.reasonPhrase);
      throw Exception('Failed to load main image');
    }
  }
}

class DetailComponent extends StatelessWidget {
  final IconData iconData;
  final String title;
  final String subtitle;

  DetailComponent({
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  // fontWeight: FontWeight.bold,
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
        ],
      ),
    );
  }
}
