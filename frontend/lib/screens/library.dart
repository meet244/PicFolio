// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:photoz/functions/selectedImages.dart';
import 'package:photoz/globals.dart';
import 'package:photoz/screens/album.dart';
import 'package:photoz/screens/bin.dart';
import 'package:photoz/screens/duplicate.dart';
import 'package:photoz/screens/favourite.dart';
import 'package:photoz/screens/newalbum.dart';
import 'package:photoz/screens/settings.dart';


class Library extends StatefulWidget {

  const Library({Key? key}) : super(key: key);

  @override
  _LibraryState createState() => _LibraryState();
}

class _LibraryState extends State<Library> {
  List<dynamic>? albums;

  @override
  void initState() {
    super.initState();
    fetchAlbums();
  }

  Future<void> fetchAlbums() async {
    final response = await http.post(
      Uri.parse('${Globals.ip}:7251/api/list/albums'),
      body: {'username': Globals.username},
    );
    if (response.statusCode == 200) {
      // print(jsonDecode(response.body));
      setState(() {
        albums = jsonDecode(response.body);
      });
    } else {
      throw Exception('Failed to load albums');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('PicFolio'),
        actions: <Widget>[
          IconButton(
            onPressed: () {
              // Select image from gallery
              var ret = getimage(Globals.ip, context);
              ret.then((value) {
                if (value) {
                  print('Image Uploaded');
                }
              });
            },
            icon: Icon(Icons.add_a_photo_outlined, size: 32.0),
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
            icon: Icon(Icons.settings_outlined, size: 32.0),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  TransparentIconButton(
                      icon: Icons.favorite_outline,
                      text: 'Favourites',
                      onPressed: () => {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => FavouritesScreen(
                                        query: "favourite",
                                        qtype: "buttons",
                                      )),
                            )
                          }),
                  TransparentIconButton(
                      icon: Icons.cleaning_services_outlined,
                      text: 'Blurry Images',
                      onPressed: () => {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => FavouritesScreen(
                                        query: "blurry",
                                        qtype: "buttons",
                                      )),
                            )
                          }),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  TransparentIconButton(
                      icon: Icons.file_copy_outlined,
                      text: 'Duplicates',
                      onPressed: () => {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      Duplicates(ip: Globals.ip)),
                            )
                          }),
                  TransparentIconButton(
                      icon: Icons.delete_outline,
                      text: 'Bin',
                      onPressed: () => {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => BinScreen(Globals.ip)),
                            )
                          }),
                ],
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text(
                  'My Albums',
                  style: TextStyle(
                      fontSize: 18,
                      color: Theme.of(context).colorScheme.onBackground),
                ),
              ),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio:
                    0.85, // Adjust the value to increase or decrease vertical space
                children: [
                  GestureDetector(
                    onTap: () async {
                      bool result = await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => CreateAlbum(ip: Globals.ip),
                        ),
                      );
                      if (result == true) {
                        // Handle if the return value is true
                        fetchAlbums();
                      }
                    },
                    child: LayoutBuilder(builder:
                        (BuildContext context, BoxConstraints constraints) {
                      return LayoutBuilder(
                        builder:
                            (BuildContext context, BoxConstraints constraints) {
                          double containerWidth = constraints.maxWidth;
                          return Column(
                            children: [
                              SizedBox(
                                width: containerWidth,
                                height: containerWidth,
                                child: Container(
                                  margin: const EdgeInsets.all(8),
                                  width: double
                                      .infinity, // Set the width to occupy the available space
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .surfaceVariant,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.add_rounded,
                                    size: 60,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 5),
                                    child: Text(
                                      'New Album',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onBackground,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    }),
                  ),
                  for (int i = 0; i < (albums?.length ?? 0); i++)
                    Column(
                      children: [
                        Container(
                          margin: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: LayoutBuilder(
                            builder: (BuildContext context,
                                BoxConstraints constraints) {
                              double containerWidth = constraints.maxWidth;
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => Album(
                                          albums![i][0],
                                          albums![i][1],
                                          albums![i][3]),
                                    ),
                                  ).then((response) {
                                    if (response == true) {
                                      fetchAlbums();
                                    }
                                  });
                                },
                                child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: CachedNetworkImage(
                                      width: containerWidth,
                                      height: containerWidth,
                                      fit: BoxFit.cover,
                                      imageUrl: albums![i][2].toString().isEmpty
                                          ? 'https://cdn3d.iconscout.com/3d/premium/thumb/picture-3446957-2888175.png'
                                          : '${Globals.ip}:7251/api/preview/${Globals.username}/${albums![i][2].toString()}',
                                    )),
                              );
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 5),
                              child: Text(
                                albums![i][1].toString(),
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onBackground,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                        if (albums![i][3] != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 5),
                                child: Text(
                                  albums![i][3].toString().isEmpty
                                      ? ''
                                      : DateFormat('dd MMM yyyy').format(
                                          DateFormat('yyyy-MM-dd')
                                              .parse(albums![i][3].toString())),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onBackground
                                        .withOpacity(0.6),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TransparentIconButton extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onPressed; // Add onPressed callback

  const TransparentIconButton({
    Key? key,
    required this.icon,
    required this.text,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width *
          0.45, // Set width to 50% of the screen
      margin: const EdgeInsets.all(7.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context)
              .colorScheme
              .surface, // Set background color to surface color
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(12), // Adjust the corner radius here
          ),
          // shadowColor: Colors.transparent, // Remove shadow
          padding: const EdgeInsets.symmetric(
              horizontal: 12, vertical: 12), // Remove padding
          alignment: Alignment.centerLeft, // Align content to the left
        ),
        onPressed: onPressed, // Set the onPressed callback
        child: Row(
          mainAxisAlignment:
              MainAxisAlignment.start, // Align icon and text to the left
          children: [
            Icon(icon),
            const SizedBox(
                width: 15), // Add some spacing between the icon and text
            Text(
              text,
              style: TextStyle(
                  fontSize: 15,
                  color: Theme.of(context).colorScheme.onBackground),
              textAlign: TextAlign.left, // Align text to the left
            ),
          ],
        ),
      ),
    );
  }
}
