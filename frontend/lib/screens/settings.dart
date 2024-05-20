import 'package:flutter/material.dart';
import 'package:photoz/globals.dart';
import 'package:photoz/screens/splash.dart';
import 'package:photoz/screens/stats.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  final String ipAddress;

  const SettingsPage(this.ipAddress, {super.key});

  @override
  // ignore: library_private_types_in_public_api
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isBackupEnabled = false;

  bool _isCreateMemoriesEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: (Globals.username == "")
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : // Add a loading spinner while fetching the username
          ListView(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const StatisticsPage(),
                          ),
                        );
                      },
                      child: const ListTile(
                        leading: Icon(Icons.donut_small_outlined, size: 30),
                        title: Text(
                          "See Statistics",
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text("View your photo and video statistics"),
                      ),
                    ),
                    const Divider(),
                  ],
                ),
                _buildSettingItem(
                  'Auto Backup',
                  'Automatically backup your photos and videos to PicFolio',
                  Icons.backup_outlined,
                  _isBackupEnabled,
                  (value) {
                    setState(() {
                      _isBackupEnabled = value;
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const SplashScreen(noip: true),
                          ),
                        );
                      },
                      child: ListTile(
                        leading: const Icon(Icons.language_outlined, size: 30),
                        title: const Text(
                          "Connected to",
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        subtitle:
                            Text("Server: ${Globals.ip.replaceAll("http://", "").replaceAll(":7251", '')}"),
                        trailing: TextButton(
                          onPressed: () {
                            // go to Scanner Page
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SplashScreen(noip: true),
                              ),
                            );
                          },
                          child: const Text("Change"),
                        ),
                      ),
                    ),
                    const Divider(),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: () {
                        // remove value from shared preferences
                        SharedPreferences.getInstance().then((prefs) {
                          prefs.remove('username');
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SplashScreen(),
                            ),
                          );
                        });
                      },
                      child: ListTile(
                        leading: const Icon(Icons.logout_outlined, size: 30),
                        title: const Text(
                          "Logout",
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        subtitle:
                            Text(Globals.username),
                      ),
                    ),
                    const Divider(),
                  ],
                ),
                Container(
                  alignment: Alignment.bottomCenter,
                  padding: const EdgeInsets.only(bottom: 16),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Text(
                      'Version: 1.0.1',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
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
        InkWell(
          onTap: () {
            onChanged(!value);
          },
          child: ListTile(
            leading: Icon(icon, size: 30),
            title: Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(subtitle),
            trailing: Switch(
              value: value,
              onChanged: onChanged,
            ),
          ),
        ),
        const Divider(),
      ],
    );
  }
}
