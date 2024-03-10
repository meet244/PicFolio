import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:photoz/screens/user.dart';

class AllPeople extends StatefulWidget {
  String ip;

  AllPeople(this.ip, {super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<AllPeople> {
  late Map<String, String> faceNames;

  Future<void> fetchFaces() async {
    try {
      final response = await http.post(
        Uri.parse('http://${widget.ip}:7251/api/list/faces'),
        body: {'username': 'meet244'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print(data);
        faceNames = Map<String, String>.from(data);
      } else {
        throw Exception('Failed to load faces');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'People',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('People'),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () {
                // Add your action here
              },
            ),
          ],
        ),
        body: FutureBuilder(
          future: fetchFaces(),
          builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            } else if (snapshot.hasError) {
              return Center(
                child: Text('Error: ${snapshot.error}'),
              );
            } else {
              return GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 4.0,
                  mainAxisSpacing: 4.0,
                ),
                itemCount: faceNames.length,
                itemBuilder: (BuildContext context, int index) {
                  return GridTile(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => UserProfileScreen(
                              widget.ip,
                              faceNames.keys.toList()[index],
                            ),
                          ),
                        );
                      },
                      child: Stack(
                        children: [
                          Image.network(
                            "http://${widget.ip}:7251/api/face/image/meet244/${faceNames.keys.toList()[index]}",
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                          if (faceNames.values.toList()[index] != "Unknown")
                            Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    Color.fromARGB(255, 36, 36, 36),
                                    Color.fromARGB(128, 39, 39, 39),
                                    Colors.transparent,
                                    Colors.transparent,
                                  ],
                                  stops: [0.0, 0.2, 0.8, 1.0],
                                ),
                              ),
                              alignment: Alignment.bottomCenter,
                              child: Padding(
                                padding: const EdgeInsets.all(5),
                                child: Text(
                                  faceNames.values.toList()[index].toString(),
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16.0,
                                      fontWeight: FontWeight.w500),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }
          },
        ),
      ),
    );
  }
}
