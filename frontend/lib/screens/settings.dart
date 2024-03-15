import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  final String ipAddress;

  const SettingsPage(this.ipAddress, {super.key});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isBackupEnabled = false;
  bool _isFaceGroupingEnabled = true;
  bool _isImageTaggingEnabled = true;
  bool _isCreateMemoriesEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        children: [
          _buildSettingItem(
            'Backup',
            'Back up photos and videos from this device to your Picfolio account',
            Icons.backup_outlined,
            _isBackupEnabled,
            (value) {
              setState(() {
                _isBackupEnabled = value;
              });
            },
          ),
          _buildSettingItem(
            'Face Grouping',
            'See photos of your favourite people grouped by similar faces',
            Icons.face_outlined,
            _isFaceGroupingEnabled,
            (value) {
              setState(() {
                _isFaceGroupingEnabled = value;
              });
            },
          ),
          _buildSettingItem(
            'Image Tagging',
            'Helps to recognize objects and scenes in your photos and make them search faster',
            Icons.image_outlined,
            _isImageTaggingEnabled,
            (value) {
              setState(() {
                _isImageTaggingEnabled = value;
              });
            },
          ),
          _buildSettingItem(
            'Create Memories',
            'Create memories from your photos and videos to see them in a new way',
            Icons.bookmarks_outlined,
            _isCreateMemoriesEnabled,
            (value) {
              setState(() {
                _isCreateMemoriesEnabled = value;
              });
            },
          ),
        ],
      ),
      bottomNavigationBar: const BottomAppBar(
        surfaceTintColor: Colors.white,
        child: Text(
          'App Version 1.0.1',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildSettingItem(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          leading: Icon(icon, size: 30),
          title: Text(
            title,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          subtitle: Text(subtitle),
          trailing: Switch(
            value: value,
            onChanged: onChanged,
          ),
        ),
        Divider(),
      ],
    );
  }
}
