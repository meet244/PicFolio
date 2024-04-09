// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:photoz/color.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:photoz/screens/favourite.dart';

class SearchScreen extends StatefulWidget {
  final String searched;
  SearchScreen(this.searched, {Key? key}) : super(key: key);

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  TextEditingController _controller = TextEditingController();
  FocusNode _focusNode = FocusNode();
  bool _isMicButton = true;
  List<String> recentSearches = [];

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
  }

  void _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      recentSearches = prefs.getStringList('recentSearches') ?? [];
    });
  }

  void _saveRecentSearch(String query) async {
    final prefs = await SharedPreferences.getInstance();
    recentSearches.insert(0, query);
    if (recentSearches.length > 5) {
      recentSearches.removeLast();
    }
    prefs.setStringList('recentSearches', recentSearches);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(useMaterial3: true, colorScheme: lightColorScheme),
      darkTheme: ThemeData(useMaterial3: true, colorScheme: darkColorScheme),
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
            backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              // Handle back button press
              Navigator.of(context).pop();
            },
          ),
          title: TextField(
            autofocus: true,
            focusNode: _focusNode,
            controller: _controller,
            decoration: const InputDecoration(
              hintText: 'Search...',
              border: InputBorder.none,
            ),
            onChanged: (text) {
              setState(() {
                _isMicButton = text.isEmpty;
              });
            },
            onSubmitted: (text) {
              if (text.isEmpty) {
                return;
              }
              // Save the search to local storage
              _saveRecentSearch(text);
              // Navigate to the result screen
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => FavouritesScreen(query: text, qtype: 'search'),
                ),
              );
            },
          ),
          actions: [
            IconButton(
              icon: _isMicButton ? Icon(Icons.mic) : Icon(Icons.clear),
              onPressed: () {
                setState(() {
                  if (_isMicButton) {
                    // Handle voice typing
                  } else {
                    _controller.clear();
                    _isMicButton = true;
                  }
                });
              },
            ),
          ],
        ),
        body: ListView(
          children: recentSearches.map((query) {
            return ListTile(
              leading: Icon(Icons.history),
              title: Padding(
                padding: const EdgeInsets.only(left: 20),
                child: Text(query),
              ),
              onTap: () {
                // Navigate to the result screen
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => FavouritesScreen(query: query, qtype: 'search'),
                  ),
                );
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}
