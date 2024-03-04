import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:photoz/widgets/gridImages.dart';

class FavouritesScreen extends StatefulWidget {
  final String ip;

  FavouritesScreen(this.ip);

  @override
  _FavouritesScreenState createState() => _FavouritesScreenState();
}

class _FavouritesScreenState extends State<FavouritesScreen> {
  Map<String, List<int>> images = {};

  @override
  void initState() {
    super.initState();
    fetchImages();
  }

  Future<void> fetchImages() async {
    final response = await http.post(
      Uri.parse('http://${widget.ip}:7251/api/list/favourites'),
      body: {'username': 'meet244'},
    );
    if (response.statusCode == 200) {
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
        images = data2;
      });
    } else {
      throw Exception('Failed to load images');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) {
      return Scaffold(
          appBar: AppBar(
            title: Text('Favourites'),
            leading: IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
          body: Center(
            child: CircularProgressIndicator(),
          ));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Favourites'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: ImageGridView(
        ip: widget.ip,
        images: images,
        gridCount: 3,
        noImageIcon: Icons.favorite_outline,
        mainEmptyMessage: "No Favourites",
        secondaryEmptyMessage: "Tap ❤ for images/videos to add them to Favourites",
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
