import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:photoz/screens/all_people.dart';
import 'package:photoz/screens/search.dart';
import '../widgets/face.dart';

class FaceListWidget extends StatefulWidget {
  final String ip;

  const FaceListWidget(this.ip, {super.key});

  @override
  _FaceListWidgetState createState() => _FaceListWidgetState();
}

class _FaceListWidgetState extends State<FaceListWidget> {
  late List<String> faces;
  late Map<String, String> faceNames;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchFaces();
  }

  Future<void> fetchFaces() async {
    setState(() {
      isLoading = true;
    });
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
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
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
                const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 15.0),
                    child: Row(
                      children: [
                        Text('Places', style: TextStyle(fontSize: 20.0)),
                        Spacer(),
                        Text("View All",
                            style: TextStyle(
                                fontSize: 16.0, color: Colors.blueAccent)),
                      ],
                    )),
                const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 15.0),
                    child: Row(
                      children: [
                        Text('Things', style: TextStyle(fontSize: 20.0)),
                        Spacer(),
                        Text("View All",
                            style: TextStyle(
                                fontSize: 16.0, color: Colors.blueAccent)),
                      ],
                    )),
              ],
            ),
    );
  }
}

class FaceItemWidget extends StatelessWidget {
  final String faceId;
  final String faceName;
  final String ip;

  const FaceItemWidget({
    super.key,
    required this.faceId,
    required this.faceName,
    required this.ip,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          CircleAvatar(
            backgroundImage:
                NetworkImage('http://$ip:7251/api/face/image/meet244/$faceId'),
            radius: 50.0,
          ),
          const SizedBox(height: 5.0),
          Text(
            faceName,
            style: const TextStyle(fontSize: 18.0),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
