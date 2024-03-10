import 'package:flutter/material.dart';
import 'package:photoz/screens/favourite.dart';

class SearchScreen extends StatefulWidget {
  String ip;
  String searched = '';
  SearchScreen(this.ip,this.searched, {super.key});
  
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  TextEditingController _controller = TextEditingController();
  FocusNode _focusNode = FocusNode();
  bool _isMicButton = true;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: Color.fromARGB(255, 245, 245, 245),
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
            // controller: TextEditingController()..text = widget.searched,
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
              // todo: save it to local storage
      
              // todo: Handle search query - go to result screen
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => FavouritesScreen(widget.ip, query: text),
                ),
              );
              print("Search query: $text");
              print("IP: ${widget.ip}");
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
          children: [
            ListTile(
              leading: Icon(Icons.history),
              title: Padding(
                padding: const EdgeInsets.only(left: 20),
                child: Text('Recently typed item'),
              ),
            ),
            ListTile(
              leading: Icon(Icons.history),
              title: Padding(
                padding: const EdgeInsets.only(left: 20),
                child: Text('Recently typed item'),
              ),
            ),
            ListTile(
              leading: Icon(Icons.history),
              title: Padding(
                padding: const EdgeInsets.only(left: 20),
                child: Text('Recently typed item'),
              ),
            ),
      
            // Add more list items for additional history items
          ],
        ),
      ),
    );
  }
}
