import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:photoz/color.dart';
import 'package:photoz/functions/selectedImages.dart';
import 'package:photoz/globals.dart';
import 'dart:convert';
import 'package:photoz/widgets/gridImages.dart';

class BinScreen extends StatefulWidget {
  final String ip;

  const BinScreen(this.ip, {super.key});

  @override
  // ignore: library_private_types_in_public_api
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
      Uri.parse('${Globals.ip}/api/list/deleted'),
      body: {'username': Globals.username},
    );
    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      if (kDebugMode) print(data);
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
      Uri.parse('${Globals.ip}/api/restore'),
      body: {'username': Globals.username, 'ids': imgs},
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
      title: 'PicFolio',
      theme: ThemeData(useMaterial3: true, colorScheme: lightColorScheme),
      darkTheme: ThemeData(useMaterial3: true, colorScheme: darkColorScheme),
      debugShowCheckedModeBanner: false,
      home: (Globals.username == '')
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Scaffold(
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
                        if (kDebugMode) print(allimags);
                        if (kDebugMode) print(images);
                        // return;
                        var ret = onDelete(context, allimags);
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
                        ip: Globals.ip,
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
