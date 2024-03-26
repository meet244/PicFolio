import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:photoz/functions/selectedImages.dart';
import 'dart:convert';
import 'package:photoz/widgets/gridImages.dart';

class BinScreen extends StatefulWidget {
  final String ip;

  BinScreen(this.ip);

  @override
  _BinScreenState createState() => _BinScreenState();
}

class _BinScreenState extends State<BinScreen> {
  List<dynamic> images = [];
  List<int> allimags = [];

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
      var data = jsonDecode(response.body);
      print(data);
      setState(() {
        images = data;
      });
    } else {
      throw Exception('Failed to load images');
    }
  }

  void _restore(List<int> allselected) async {
    var imgs = allselected.join(',');
    final response = await http.post(
      Uri.parse('http://${widget.ip}:7251/api/restore'),
      body: {'username': 'meet244', 'ids': imgs},
    );
    if (response.statusCode == 200) {
      setState(() {
        allimags.clear();
        // remove the deleted images from the grid
        fetchImages();
      });
    } else {
      throw Exception('Failed to restore image');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              (allimags.isEmpty)
                  ? const Text('Bin')
                  : (allimags.length == 1)
                      ? Text("${allimags.length} item")
                      : Text(
                          "${allimags.length} items"), // Show count if images are selected
            ],
          ),
          leading: (allimags.isNotEmpty)
              ? GestureDetector(
                  onTap: () {
                    // Clear selection
                    setState(() {
                      allimags.length = 0;
                    });
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(10.0),
                    child: Icon(
                      Icons.close,
                      size: 32.0,
                    ),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
          actions: <Widget>[
            if (allimags.isNotEmpty)
              IconButton(
                onPressed: () {
                  print(allimags);
                  print(images);
                  // return;
                  var ret = onDelete(widget.ip, context, allimags);
                  ret.then((value) {
                    if (value) {
                      setState(() {
                        allimags.clear();
                        // remove the deleted images from the grid
                        fetchImages();
                      });
                    }
                  });
                },
                icon: const Icon(Icons.delete_outlined, size: 32.0),
              ),
            if (allimags.isNotEmpty)
              IconButton(
                onPressed: () {
                  // Handle share icon tap
                  _restore(allimags);
                },
                icon: const Icon(
                  Icons.restore_outlined,
                  size: 32.0,
                ),
              ),
          ],
        ),
        body: (images.isEmpty)
            ? const Center(
                child: Text("No Deleted Images"),
              )
            : SingleChildScrollView(
              child: ImageGridView(
                  ip: widget.ip,
                  images: images,
                  gridCount: 3,
                  noImageIcon: Icons.delete_outline,
                  mainEmptyMessage: "No Deleted Images",
                  secondaryEmptyMessage: "It's Clean and Clear!",
                  isBin: true,
                  onSelectionChanged: (select) {
                    setState(() {
                      allimags = select;
                    });
                  },
                ),
            ),
      ),
    );
  }
}
