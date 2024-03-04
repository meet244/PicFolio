import 'package:flutter/material.dart';
import 'package:photoz/widgets/gridImages.dart';

class UserProfileScreen extends StatelessWidget {
  final String userId;
  final String ip;

  const UserProfileScreen({super.key, required this.ip, required this.userId});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Meet Patel'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ClipOval(
                    child: Image.network(
                      'https://www.simplilearn.com/ice9/free_resources_article_thumb/what_is_image_Processing.jpg',
                      width: 100.0,
                      height: 100.0,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 16.0),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Meet Patel',
                        style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '100 photos',
                        style: TextStyle(fontSize: 16.0),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 25.0),
              ImageGridView(
                ip: ip,
                images: const <String, List<int>>{},
                gridCount: 3,
                noImageIcon: Icons.image_outlined,
                mainEmptyMessage: "No Images Found",
                secondaryEmptyMessage: "Images will appear here",
              )
            ],
          ),
        ),
      ),
    );
  }
}
