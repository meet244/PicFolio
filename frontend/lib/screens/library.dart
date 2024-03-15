import 'package:flutter/material.dart';
import 'package:photoz/screens/bin.dart';
import 'package:photoz/screens/duplicate.dart';
import 'package:photoz/screens/favourite.dart';

class Library extends StatelessWidget {
  final String ip;

  const Library(this.ip, {super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
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
                              builder: (context) =>
                                  FavouritesScreen(ip, query: "favourite")),
                        )
                      }),
              TransparentIconButton(
                  icon: Icons.cleaning_services_outlined,
                  text: 'Blurry Images',
                  onPressed: () => {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  FavouritesScreen(ip, query: "blurry")),
                        )
                      }),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              TransparentIconButton(
                  icon: Icons.screenshot_outlined,
                  text: 'Screenshots',
                  onPressed: () => {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  FavouritesScreen(ip, query: "screenshot")),
                        )
                      }),
              TransparentIconButton(
                  icon: Icons.delete_outline,
                  text: 'Bin',
                  onPressed: () => {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => BinScreen(ip)),
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
                                  Duplicates(ip:ip)),
                        )
                      }),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Text(
              'Albums',
              style: TextStyle(fontSize: 20),
            ),
          ),
        ],
      ),
    );
  }
}

class TransparentIconButton extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onPressed; // Add onPressed callback

  const TransparentIconButton(
      {super.key,
      required this.icon,
      required this.text,
      required this.onPressed});

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
              horizontal: 15, vertical: 22), // Remove padding
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
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onBackground),
              textAlign: TextAlign.left, // Align text to the left
            ),
          ],
        ),
      ),
    );
  }
}
