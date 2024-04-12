// ignore: file_names
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:http/http.dart' as http;
import 'package:photoz/globals.dart';

class CreateAlbum extends StatefulWidget {
  final String ip;

  const CreateAlbum({super.key, required this.ip}); // Required parameter

  @override
  // ignore: library_private_types_in_public_api
  _CreateAlbumPageState createState() => _CreateAlbumPageState();
}

class _CreateAlbumPageState extends State<CreateAlbum> {
  final TextEditingController _titleController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Album'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(vertical: 20.0),
                  labelText: 'Album Title',
                  labelStyle: TextStyle(fontSize: 20)),
              style: const TextStyle(fontSize: 20.0),
              maxLength: 30, // Set maximum length to 30 characters
            ),
            const SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: () {
                if (_titleController.text.isEmpty) {
                  return;
                }
                createAlbumApi(_titleController.text);
              },
              child: const Text('Create Album'),
            ),
          ],
        ),
      ),
    );
  }

  void createAlbumApi(String title) async {
    final response = await http.post(
      Uri.parse('${Globals.ip}/api/album/create'),
      body: {
        'username':Globals.username,
        'name': _titleController.text,
      },
    );

    if (response.statusCode == 200) {
      if (kDebugMode) print('API call successful');
      if (kDebugMode) print('Response body: ${response.body}');
      // ignore: use_build_context_synchronously
      Navigator.pop(context, true);
    } else {
      if (kDebugMode) print('API call failed with status code: ${response.statusCode}');
    }
  }
}
