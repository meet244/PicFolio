import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'widgets/face.dart';

class FaceListWidget extends StatefulWidget {
  final String ip;

  const FaceListWidget({Key? key, required this.ip}) : super(key: key);

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
                    print('Search');
                  },
                  child: Container(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10.0),
                    height: 50.0,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(20.0),
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
                const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 15.0),
                    child: Row(
                      children: [
                        Text('People', style: TextStyle(fontSize: 20)),
                        Spacer(),
                        Text("View All",
                            style: TextStyle(
                                fontSize: 16.0, color: Colors.blueAccent)),
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
    Key? key,
    required this.faceId,
    required this.faceName,
    required this.ip,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(8.0),
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
            style: TextStyle(fontSize: 18.0),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

void main() {
  runApp(MyApp("192.168.0.107"));
}

class MyApp extends StatelessWidget {
  final String ip;
  MyApp(this.ip);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Face List App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: FaceListWidget(ip: ip),
    );
  }
}
