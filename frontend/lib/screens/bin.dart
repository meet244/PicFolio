import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:photoz/widgets/gridImages.dart';

class BinScreen extends StatefulWidget {
  final String ip;

  BinScreen(this.ip);

  @override
  _BinScreenState createState() => _BinScreenState();
}

class _BinScreenState extends State<BinScreen> {
  Map<String, List<int>> images = {};

  @override
  void initState() {
    super.initState();
    fetchImages();
  }

  Future<void> fetchImages() async {
    final response = await http.post(
      Uri.parse('http://${widget.ip}:7251/api/list/deleted'),
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
      return MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            title: Text('Bin'),
            leading: IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
          body: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Bin'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        body: ImageGridView(
          ip: widget.ip,
          images: images,
          gridCount: 3,
          noImageIcon: Icons.delete_outline,
          mainEmptyMessage: "No Deleted Images",
          secondaryEmptyMessage: "Deleted images will appear here",
        ),
      ),
    );
  }
}

void main() {
  runApp(
    BinScreen("192.168.0.107"),
  );
}