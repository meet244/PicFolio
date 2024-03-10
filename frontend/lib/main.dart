import 'package:flutter/material.dart';
// import 'package:photoz/screens/bin.dart';
import 'shravani.dart';

// import 'try.dart';

void main() {
  // runApp(MyApp());

  // runApp(BinScreen("127.0.0.1"));
  runApp(MyHomePage('192.168.0.106'));
}

// --------------------------------------------------------------------------------------------------------


// import 'package:flutter/material.dart';

// void main() {
//   runApp(MyApp());
// }

// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       home: ImageSelectionScreen(),
//     );
//   }
// }

// class ImageSelectionScreen extends StatefulWidget {
//   @override
//   _ImageSelectionScreenState createState() => _ImageSelectionScreenState();
// }

// class _ImageSelectionScreenState extends State<ImageSelectionScreen> {
//   List<String> _images = [
//     'https://static.vecteezy.com/system/resources/previews/004/244/268/original/cute-dog-cartoon-character-illustration-free-vector.jpg',
//     'https://www.shutterstock.com/shutterstock/photos/2321276795/display_1500/stock-vector-doraemon-character-from-apanese-manga-series-cartoon-illustration-2321276795.jpg',
//     'https://m.media-amazon.com/images/I/61AbHD-RGtL._AC_UF1000,1000_QL80_.jpg',
//     'https://artprojectsforkids.org/wp-content/uploads/2020/04/Minion.jpg.webp',
//     'https://cdn.pixabay.com/photo/2022/04/04/16/54/cute-cartoon-7111833_640.png',
//     'https://classroomclipart.com/image/static7/preview2/cute-big-eared-mouse-cartoon-style-clip-art-58687.jpg',
//   ];

//   List<bool> _selected = List<bool>.generate(6, (index) => false);
//   bool _selectionMode = false;

//   void _toggleSelection(int index) {
//     setState(() {
//       if (_selected[index]) {
//         _selected[index] = false;
//         if (_selected.every((isSelected) => !isSelected)) {
//           _selectionMode = false;
//         }
//       } else {
//         _selected[index] = true;
//         _selectionMode = true;
//       }
//     });
//   }

//   void _sendOrDeleteSelectedImages() {
//     List<String> selectedImages = [];
//     for (int i = 0; i < _selected.length; i++) {
//       if (_selected[i]) {
//         selectedImages.add(_images[i]);
//       }
//     }
//     // Perform action with selected images (e.g., send or delete them)
//     print('Selected images: $selectedImages');
//     // Reset selection mode and selected images
//     setState(() {
//       _selectionMode = false;
//       _selected = List<bool>.generate(6, (index) => false);
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Image Selection Demo'),
//       ),
//       body: GridView.builder(
//         itemCount: _images.length,
//         gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//           crossAxisCount: 3,
//         ),
//         itemBuilder: (BuildContext context, int index) {
//           return GestureDetector(
//             onTap: () => _toggleSelection(index),
//             child: Stack(
//               children: [
//                 Image.network(_images[index]),
//                 if (_selected[index])
//                   Container(
//                     color: Colors.black.withOpacity(0.5),
//                   ),
//                 if (_selected[index])
//                   Positioned.fill(
//                     child: Align(
//                       alignment: Alignment.center,
//                       child: Icon(
//                         Icons.check_circle,
//                         color: Colors.blue,
//                         size: 40,
//                       ),
//                     ),
//                   ),
//               ],
//             ),
//           );
//         },
//       ),
//       bottomSheet: _selectionMode
//           ? ClipRRect(
//               borderRadius: BorderRadius.only(
//                 topLeft: Radius.circular(25),
//                 topRight: Radius.circular(25),
//               ),
//               child: Container(
//                 padding: EdgeInsets.all(16.0),
//                 color: Colors.grey[200],
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     IconButton(
//                       icon: Icon(Icons.send),
//                       onPressed: _sendOrDeleteSelectedImages,
//                     ),
//                     IconButton(
//                       icon: Icon(Icons.cancel),
//                       onPressed: () {
//                         setState(() {
//                           _selectionMode = false;
//                           _selected = List<bool>.generate(6, (index) => false);
//                         });
//                       },
//                     ),
//                   ],
//                 ),
//               ),
//             )
//           : null,
//     );
//   }
// }
