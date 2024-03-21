import 'package:flutter/material.dart';

class Shared extends StatefulWidget {
  String ip;

  Shared(this.ip, {Key? key}) : super(key: key);

  @override
  _SharedState createState() => _SharedState();
}

class _SharedState extends State<Shared> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Centered Button Screen'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            // Navigate to the next screen
            // Navigator.push(
            //   context,
            //   MaterialPageRoute(builder: (context) => NextScreen()),
            // );
          },
          child: Text('Next Screen'),
        ),
      ),
    );
  }
}
