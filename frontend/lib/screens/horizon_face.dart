import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:photoz/screens/all_people.dart';
import 'package:photoz/screens/favourite.dart';
import 'package:photoz/screens/search.dart';
import '../widgets/face.dart';

class FaceListWidget extends StatefulWidget {
  final String ip;

  const FaceListWidget(this.ip, {super.key});

  @override
  _FaceListWidgetState createState() => _FaceListWidgetState();
}

class _FaceListWidgetState extends State<FaceListWidget> {
  List<String> faces  = [];
  Map<String, String> faceNames = {};
  bool isfaceLoading = true;
  bool isalbumLoading = true;

  List<String> autoAlbumsPlace = [];
  List<String> autoAlbumsDocs = [];
  List<String> autoAlbumsThings = [];

  @override
  void initState() {
    super.initState();
    fetchFaces();
    fetchAutoAlbums();
  }

  Future<void> fetchFaces() async {
    try {
      final response = await http.post(
        Uri.parse('http://${widget.ip}:7251/api/list/faces'),
        body: {'username': 'meet244'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        faceNames = Map<String, String>.from(data);
        // remove all keys that have value 'Unknown'
        faceNames.removeWhere((key, value) => value == 'Unknown');
        faces = faceNames.keys.toList();
      } else {
        throw Exception('Failed to load faces');
      }
    } catch (e) {
      print('Error: $e');
    } finally {
      setState(() {
        isfaceLoading = false;
      });
    }
  }

  Future<void> fetchAutoAlbums() async {
    try {
      final response = await http.post(
        Uri.parse('http://${widget.ip}:7251/api/list/autoalbums'),
        body: {'username': 'meet244'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          isalbumLoading = false;
          autoAlbumsPlace = List<String>.from(data["Places"]);
          autoAlbumsDocs = List<String>.from(data['Documents']);
          autoAlbumsThings = List<String>.from(data["Things"]);
        });
      } else {
        throw Exception('Failed to load auto albums');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isalbumLoading || isfaceLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start, // Align text to the left
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => SearchScreen(widget.ip, '')));
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 15.0, vertical: 10.0),
                      height: 50.0,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                      child: Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 10, right: 7),
                            child: Icon(Icons.search,
                                size: 25.0, color: Colors.grey[800]),
                          ),
                          const Expanded(
                            child: Text('Search \'Hiking\'',
                                style: TextStyle(fontSize: 20.0)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15.0),
                      child: Row(
                        children: [
                          const Text('People', style: TextStyle(fontSize: 20)),
                          const Spacer(),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).push(MaterialPageRoute(
                                  builder: (context) => AllPeople(
                                        widget.ip,
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
                                color: Colors.blueAccent,
                              ),
                            ),
                          ),
                        ],
                      )),
                  FaceList(
                    faceNames: faceNames,
                    ip: widget.ip,
                    isSquared: true,
                  ),
                  makename('Auto Albums'),
                  makehorizonScroll(autoAlbumsPlace),
                  makename('Documents'),
                  makehorizonScroll(autoAlbumsDocs),
                  makename('Things'),
                  makehorizonScroll(autoAlbumsThings),
                  const SizedBox(height: 40.0),
                ],
              ),
            ),
    );
  }

  Widget makename(String name) {
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 12.0),
        child: Text(name, style: const TextStyle(fontSize: 20.0)));
  }

  Widget makehorizonScroll(List<String> listr) {
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
                  builder: (context) => FavouritesScreen(widget.ip, query:listr[index], qtype: 'auto albums'),
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
                      child: Image.network(
                        'http://${widget.ip}:7251/api/autoalbum/meet244/${listr[index]}', // Replace with your image URL
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
                      listr[index],
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
