
import 'dart:async';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:photoz/functions/selectedImages.dart';
import 'package:photoz/globals.dart';
import 'package:photoz/screens/all_people.dart';
import 'package:photoz/screens/favourite.dart';
import 'package:photoz/screens/search.dart';
import 'package:photoz/screens/settings.dart';
import 'package:photoz/widgets/gridImages.dart';
import '../widgets/face.dart';

class FaceListWidget extends StatefulWidget {
  const FaceListWidget({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _FaceListWidgetState createState() => _FaceListWidgetState();
}

class _FaceListWidgetState extends State<FaceListWidget> {
  // List<String> faces  = [];
  List<dynamic> faceNames = [];
  bool isfaceLoading = true;
  bool isalbumLoading = true;

  List<dynamic> autoAlbumsPlace = [];
  List<dynamic> autoAlbumsDocs = [];
  List<dynamic> autoAlbumsThings = [];

  @override
  void initState() {
    super.initState();
    fetchFaces();
  }

  Future<void> fetchFaces() async {
    try {
      final response = await http.post(
        Uri.parse('${Globals.ip}/api/list/faces'),
        body: {'username': Globals.username},
      );
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        // faceNames = Map<String, String>.from(data);
        data.removeWhere((face) => face[1].toString() == 'Unknown');
        setState(() {
          isfaceLoading = false;
          faceNames = data;
        });
        // faces = faceNames.keys.toList();
      } else {
        throw Exception('Failed to load faces');
      }
    } catch (e) {
      if (kDebugMode) print('Error: $e');
    } finally {
      setState(() {
        isfaceLoading = false;
      });

      fetchAutoAlbums();
    }
  }

  Future<void> fetchAutoAlbums() async {
    try {
      final response = await http.post(
        Uri.parse('${Globals.ip}/api/list/autoalbums'),
        body: {'username': Globals.username},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // print(data);
        // print(data["Places"].runtimeType);
        setState(() {
          autoAlbumsPlace = data["Places"];
          autoAlbumsDocs = data['Documents'];
          autoAlbumsThings = data["Things"];
          isalbumLoading = false;
        });
      } else {
        throw Exception('Failed to load auto albums');
      }
    } catch (e) {
      if (kDebugMode) print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PicFolio'),
        actions: <Widget>[
          IconButton(
            onPressed: () {
              // Select image from gallery
              var ret = getimage(Globals.ip, context);
              ret.then((value) {
                if (value) {
                  if (kDebugMode) print('Image Uploaded');
                }
              });
            },
            icon: const Icon(Icons.add_a_photo_outlined, size: 32.0),
          ),
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
        ],
      ),
      body: Stack(children: [
        SingleChildScrollView(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start, // Align text to the left
            children: [
              Container(
                margin:
                    const EdgeInsets.symmetric(horizontal: 15.0, vertical: 7),
                height: 50.0,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(15.0),
                ),
              ),
              if (faceNames.isNotEmpty)
                Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 15.0, vertical: 7),
                    child: Row(
                      children: [
                        const Text('People', style: TextStyle(fontSize: 20)),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: (context) => AllPeople(
                                      ip: Globals.ip,
                                    )));
                          },
                          style: ButtonStyle(
                            backgroundColor: MaterialStateProperty.all<Color>(
                                Colors.transparent),
                          ),
                          child: const Text(
                            "View All",
                            style: TextStyle(
                              fontSize: 16.0,
                            ),
                          ),
                        ),
                      ],
                    )),
              if (faceNames.isNotEmpty)
                FaceList(
                  faceNames: faceNames,
                  ip: Globals.ip,
                  enabled: isfaceLoading,
                  // isSquared: true,
                ),
              if (autoAlbumsPlace.isNotEmpty) makename('Auto Albums'),
              if (autoAlbumsPlace.isNotEmpty)
                makehorizonScroll(autoAlbumsPlace),
              if (autoAlbumsDocs.isNotEmpty) makename('Documents'),
              if (autoAlbumsDocs.isNotEmpty) makehorizonScroll(autoAlbumsDocs),
              if (autoAlbumsThings.isNotEmpty) makename('Things'),
              if (autoAlbumsThings.isNotEmpty)
                makehorizonScroll(autoAlbumsThings),
              const SizedBox(height: 40.0),
              // if all are empty
              if (faceNames.isEmpty &&
                  autoAlbumsPlace.isEmpty &&
                  autoAlbumsDocs.isEmpty &&
                  autoAlbumsThings.isEmpty)
                const NothingMessage(
                    icon: Icons.search,
                    mainMessage: "Nothing to see 👀",
                    secondaryMessage:
                        "No faces or auto albums found. Try adding some images.")
            ],
          ),
        ),
        GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const SearchScreen('')));
              },
              child: Container(
                margin:
                    const EdgeInsets.symmetric(horizontal: 15.0, vertical: 7),
                height: 50.0,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(15.0),
                ),
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 10, right: 7),
                      child: Icon(Icons.search,
                          size: 25.0,
                          color: Theme.of(context).colorScheme.onSurface),
                    ),
                    const Expanded(
                      child: Text('Search \'Hiking\'',
                          style: TextStyle(fontSize: 20.0)),
                    ),
                  ],
                ),
              ),
            )
      ]),
    );
  }

  Widget makename(String name) {
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 12.0),
        child: Text(name, style: const TextStyle(fontSize: 20.0)));
  }

  Widget makehorizonScroll(List<dynamic> listr) {
    // print(listr);
    return SizedBox(
      height: 150.0,
      width: double.infinity,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: listr.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FavouritesScreen(
                      query: listr[index][0], qtype: 'auto albums'),
                ),
              );
            },
            child: Container(
              width: 150.0,
              height: 150.0,
              margin: EdgeInsets.only(
                left: index == 0 ? 15 : 7,
                right: index == listr.length - 1 ? 15 : 7,
              ),
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10.0),
                    child: ShaderMask(
                      shaderCallback: (Rect bounds) {
                        return const LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Colors.black54, Colors.transparent],
                        ).createShader(bounds);
                      },
                      blendMode: BlendMode.srcATop,
                      child: CachedNetworkImage(
                        imageUrl:
                            '${Globals.ip}/api/preview/${Globals.username}/${listr[index][1]}/${listr[index][2].replaceAll("-", '/')}', // Replace with your image URL
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 7,
                    left: 0,
                    right: 0,
                    child: Text(
                      listr[index][0],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
