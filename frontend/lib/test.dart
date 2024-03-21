import 'package:flutter/material.dart';
import 'package:photoz/screens/home_left.dart';
import 'package:photoz/screens/horizon_face.dart';
import 'package:photoz/screens/library.dart';
import 'package:photoz/screens/shared.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';

class MyApp extends StatefulWidget {
  String ip;
  MyApp(this.ip, {super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  var _currentIndex = 0;
  final _pageController = PageController();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Photoz",
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Text("Photoz"),
        ),
        body: PageView(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          children: [
            /// Photos page
            HomeLeft(widget.ip),

            /// Shared page
            Shared(widget.ip),

            /// Notifications page
            Library(widget.ip),

            /// Messages page
            FaceListWidget(widget.ip),
          ],
        ),
        bottomNavigationBar: SalomonBottomBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
              _pageController.animateToPage(
                index,
                duration: Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            });
          },
          items: [
            /// Home
            SalomonBottomBarItem(
              icon: Icon(Icons.photo_outlined),
              title: Text("Photos"),
              selectedColor: const Color.fromARGB(255, 0, 86, 156),
            ),

            /// Likes
            SalomonBottomBarItem(
              icon: Icon(Icons.groups_outlined),
              title: Text("Shared"),
              selectedColor: Colors.blue,
            ),

            /// Search
            SalomonBottomBarItem(
              icon: Icon(Icons.photo_album_outlined),
              title: Text("Albums"),
              selectedColor: Colors.blue,
            ),

            /// Profile
            SalomonBottomBarItem(
              icon: Icon(Icons.search_outlined),
              title: Text("Search"),
              selectedColor: Colors.blue,
            ),
          ],
        ),
      ),
    );
  }
}
