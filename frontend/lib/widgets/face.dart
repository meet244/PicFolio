import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:photoz/screens/user.dart';

class FaceList extends StatelessWidget {
  final List<dynamic> faceNames;
  final String ip;
  final bool isSquared;

  const FaceList({
    super.key,
    required this.faceNames,
    required this.ip,
    this.isSquared = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 150,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: faceNames.length,
        itemBuilder: (context, index) {
          final faceId = faceNames[index][0].toString();
          final faceName = faceNames[index][1].toString();
          return Padding(
            padding: EdgeInsets.only(
              left: index == 0 ? 8.0 : 0.0,
              right: index == faceNames.length - 1 ? 8.0 : 0.0,
            ),
            child: FaceItem(
              ip: ip,
              faceId: faceId,
              faceName: faceName,
              isSquared: isSquared,
            ),
          );
        },
      ),
    );
  }
}

class FaceItem extends StatelessWidget {
  final String faceId;
  final String faceName;
  final String ip;
  final bool isSquared;

  const FaceItem({
    super.key,
    required this.ip,
    required this.faceId,
    required this.faceName,
    this.isSquared = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8.0),
      child: GestureDetector(
        onTap: () => {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UserProfileScreen(ip, faceId),
            ),
          ),
        },
        child: Column(
          children: [
            isSquared
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10.0),
                    child: CachedNetworkImage(
                      imageUrl: 'http://$ip:7251/api/face/image/meet244/$faceId',
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(45.0),
                    child: CachedNetworkImage(
                      imageUrl: 'http://$ip:7251/api/face/image/meet244/$faceId',
                      width: 90,
                      height: 90,
                      fit: BoxFit.cover,
                    ),
                  ),
            const SizedBox(height: 5.0),
            Text(
              faceName,
              style: const TextStyle(fontSize: 18.0),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
