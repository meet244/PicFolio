import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:photoz/widgets/gridImages.dart';

// ignore: must_be_immutable
class FavouritesScreen extends StatefulWidget {
  final String ip;
  String query;
  String qtype;

  FavouritesScreen(this.ip,
      {super.key, this.query = '', this.qtype = 'search'});

  @override
  _FavouritesScreenState createState() => _FavouritesScreenState();
}

class _FavouritesScreenState extends State<FavouritesScreen> {
  Map<String, List<int>> images = {};
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchImages();
  }

  Future<void> fetchImages() async {
    final response = await http.post(
      Uri.parse('http://${widget.ip}:7251/api/search'),
      body: {
        'username': 'meet244',
        'query': widget.query,
        'type': widget.qtype,
      },
    );
    if (response.statusCode == 200) {
      print(jsonDecode(response.body));
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
        loading = false;
        images = data2;
      });
    } else {
      throw Exception('Failed to load images');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.query),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : widget.query.toLowerCase() == 'favourite'
              ? ImageGridView(
                  ip: widget.ip,
                  images: images,
                  gridCount: 3,
                  noImageIcon: Icons.heart_broken_outlined,
                  mainEmptyMessage: "No Favourites",
                  secondaryEmptyMessage:
                      "❤ images/videos to add them to Favourites",
                )
              : widget.query.toLowerCase() == 'screenshot'
                  ? ImageGridView(
                      ip: widget.ip,
                      images: images,
                      gridCount: 3,
                      noImageIcon: Icons.screenshot_outlined,
                      mainEmptyMessage: "No Screenshot",
                      secondaryEmptyMessage:
                          "Screenshots will automatically appear here",
                    )
                  : widget.query.toLowerCase() == 'blurry'
                      ? ImageGridView(
                          ip: widget.ip,
                          images: images,
                          gridCount: 3,
                          noImageIcon: Icons.photo_library,
                          mainEmptyMessage: "No Blurry Images",
                          secondaryEmptyMessage:
                              "Blurry images will automatically appear here",
                        )
                      : ImageGridView(
                          ip: widget.ip,
                          images: images,
                          gridCount: 3,
                          noImageIcon: Icons.search_off_outlined,
                          mainEmptyMessage: "Nothing Found",
                          secondaryEmptyMessage:
                              "We didn't got it anywhere! Try searching something else",
                        ),
    );
  }

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
}
