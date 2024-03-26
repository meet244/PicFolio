import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;

Future<bool> onSend(String ip, List<int> allselected) async {
  // Implement your send logic here
  try {
    final tempDir = await getTemporaryDirectory();

    // Create temporary files for each image
    final tempFiles = <File>[];
    for (int i = 0; i < allselected.length; i++) {
      final imageId = allselected[i];
      final mainImageBytes = await fetchMainImage(ip, imageId);
      // allselected[imageId] = mainImageBytes;
      // Save the main image to a temporary file
      final tempFile = File('${tempDir.path}/temp_image_$i.png');
      await tempFile.writeAsBytes(mainImageBytes);
      tempFiles.add(tempFile);
    }

    // Share the multiple images using the share_plus package
    // ignore: deprecated_member_use
    await Share.shareFiles(
      tempFiles.map((file) => file.path).toList(),
      text: 'I shared these images from my PicFolio app. Try them out!',
      subject: 'Image Sharing',
    );
    return true;
  } catch (e) {
    print('Error sharing images: $e');
    // Handle the error, e.g., show a snackbar or log the error
    return false;
  }
}

Future<List<int>> fetchMainImage(String ip, int imageId) async {
  var url = 'http://$ip:7251/api/asset/meet244/$imageId';
  final response = await http.get(Uri.parse(url));
  if (response.statusCode == 200) {
    return response.bodyBytes;
  } else {
    throw Exception('Failed to load preview image ${response.statusCode}');
  }
}

Future<bool> onDelete(
    String ip, BuildContext context, List<int> allselected) async {
  // ask for confirmation before deleting
  final bool delete = await showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Delete Images'),
        content: const Text('Are you sure you want to delete the selected images?'),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(true);
            },
            child: Text('Yes'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false);
            },
            child: const Text('No'),
          ),
        ],
      );
    },
  );
  if (!delete) {
    return false;
  }
  // Call delete image API here
  var imgs = allselected.join(',');
  final response = await http
      .delete(Uri.parse('http://$ip:7251/api/delete/meet244/$imgs'));
  if (response.statusCode == 200) {
    // print('Image deleted');
    // remove the deleted images from the grid
    return true;
  } else {
    // print('Failed to delete image');
    return false;
  }
}

Future<bool> onAddToAlbum(
    String ip, String albumId, List<int> allselected) async {
  // Call add image API here
  var imgs = allselected.join(',');
  final response = await http.post(
    Uri.parse('http://$ip:7251/api/album/add'),
    body: {'username': 'meet244', 'album_id': albumId, 'asset_id': imgs},
  );

  if (response.statusCode == 200) {
    print('Image added to album');
    return true;
  } else {
    print('Failed to add image to album');
    return false;
  }
}

Future<bool> onRemoveFromAlbum(
    String ip, String albumId, List<int> allselected) async {
  // Call remove image API here
  var imgs = allselected.join(',');
  final response = await http.post(
    Uri.parse('http://${ip}:7251/api/album/remove'),
    body: {'username': 'meet244', 'album_id': albumId, 'asset_ids': imgs},
  );

  if (response.statusCode == 200) {
    print('Image removed from album');
    return true;
  } else {
    print('Failed to remove image from album');
    return false;
  }
}

Future<bool> editDate(
  String ip,
  BuildContext context,
  List<int> allselected,
) async {
  // Implement your edit date logic here
  // get a date from calendar
  final DateTime? picked = await showDatePicker(
    context: context,
    // initialDate: selectedDate,
    firstDate: DateTime(2015, 8),
    lastDate: DateTime(2101),
  );
  if (picked == null) {
    return false;
  }
  var date = (picked.toString().split(" ")[0]);
  var imgs = allselected.join(',');
  final response = await http.post(
    Uri.parse('http://${ip}:7251/api/redate'),
    body: {
      'username': 'meet244',
      'date': date,
      'id': imgs,
    },
  );
  if (response.statusCode == 200) {
    print('Dates Updated');
    return true;
    // remove the deleted images from the grid
  } else {
    print('Failed to update date');
    return false;
  }
}

Future<bool> moveToShared(String ip, List<int> allselected) async {
  // Implement your move to family logic here
  print(allselected);
  final response = await http.post(
    Uri.parse('http://${ip}:7251/api/shared/move'),
    body: {
      'username': 'meet244',
      'asset_id': allselected.join(','),
    },
  );
  if (response.statusCode == 200) {
    print('Image Shared');
    return true;
  } else {
    print('Failed to move to share');
  }
  return false;
}

Future<bool> unMoveToShared(String ip, List<int> allselected) async {
  // Implement your move to family logic here
  print(allselected);
  final response = await http.post(
    Uri.parse('http://${ip}:7251/api/shared/moveback'),
    body: {
      'username': 'meet244',
      'asset_id': allselected.join(','),
    },
  );
  if (response.statusCode == 200) {
    print('Image Unshared');
    return true;
  } else {
    print('Failed to unmove to share');
  }
  return false;
}

final _picker = ImagePicker();

Future<bool> getimage(
  String ip,
  BuildContext context,
) async {
  final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
  if (pickedFile != null) {
    // print("picked");
    if (await _uploadimage(ip, context, pickedFile)) {
      return true;
    }
  }
  return false;
}

Future<bool> _uploadimage(String ip, BuildContext context, XFile xFile) async {
  var url = Uri.parse('http://${ip}:7251/api/upload');
  var formData = http.MultipartRequest('POST', url);
  formData.fields['username'] = 'meet244';

  final imageBytes = await xFile.readAsBytes();
  formData.files.add(
      http.MultipartFile.fromBytes('asset', imageBytes, filename: 'image.jpg'));

  try {
    final response = await formData.send();
    if (response.statusCode == 200) {
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(
      //     content: Text('Image uploaded successfully'),
      //     duration: Duration(seconds: 2),
      //   ),
      // );
      return true;
    } else {
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(
      //     content: Text('Upload failed: ${response.reasonPhrase}'),
      //     duration: Duration(seconds: 2),
      //   ),
      // );
      return false;
    }
  } catch (e) {
    // ScaffoldMessenger.of(context).showSnackBar(
    //   SnackBar(
    //     content: Text('Error during upload: $e'),
    //     duration: Duration(seconds: 2),
    //   ),
    // );
    return false;
  }
}
