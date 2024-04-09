// ignore_for_file: prefer_const_constructors


import 'dart:convert';


import 'package:flutter/material.dart';


import 'package:photoz/globals.dart';


import 'package:photoz/screens/splash.dart';


import 'package:photoz/screens/stats.dart';


import 'package:shared_preferences/shared_preferences.dart';


import 'package:http/http.dart' as http;


class SettingsPage extends StatefulWidget {

  final String ipAddress;


  const SettingsPage(this.ipAddress, {super.key});


  @override

  _SettingsPageState createState() => _SettingsPageState();

}


class _SettingsPageState extends State<SettingsPage> {

  bool _isBackupEnabled = false;


  bool _isCreateMemoriesEnabled = true;


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

      body: (Globals.username == "")

          ? Center(

              child: CircularProgressIndicator(),

            )

          : // Add a loading spinner while fetching the username


          ListView(

              padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),

              children: [

                Column(

                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [

                    InkWell(

                      onTap: () {

                        Navigator.push(

                            context,

                            MaterialPageRoute(

                                builder: (context) => StatisticsPage()));

                      },

                      child: ListTile(

                        leading: Icon(Icons.donut_small_outlined, size: 30),


                        title: Text(

                          "See Statistics",

                          style: TextStyle(

                              fontSize: 20, fontWeight: FontWeight.bold),

                        ),


                        subtitle: Text("View your photo and video statistics"),


                        // trailing: TextButton(


                        //   onPressed: () {


                        //     // go to Scanner Page


                        //   },


                        //   child: Text("Change"),


                        // ),

                      ),

                    ),

                    Divider(),

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

                                    SplashScreen(noip: true)));

                      },

                      child: ListTile(

                        leading: Icon(Icons.language_outlined, size: 30),

                        title: Text(

                          "Connected to ${Globals.ip}",

                          style: TextStyle(

                              fontSize: 20, fontWeight: FontWeight.bold),

                        ),

                        subtitle: Text("You are connected to this device."),

                        trailing: TextButton(

                          onPressed: () {

                            // go to Scanner Page

                          },

                          child: Text("Change"),

                        ),

                      ),

                    ),

                    Divider(),

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

                                  builder: (context) => SplashScreen()));

                        });

                      },

                      child: ListTile(

                        leading: Icon(Icons.logout_outlined, size: 30),


                        title: Text(

                          "Logout",

                          style: TextStyle(

                              fontSize: 20, fontWeight: FontWeight.bold),

                        ),


                        subtitle:

                            Text("Currently logged in as ${Globals.username}"),


                        // trailing: TextButton(


                        //   onPressed: () {


                        //     // go to Scanner Page


                        //   },


                        //   child: Text("Change"),


                        // ),

                      ),

                    ),

                    Divider(),

                  ],

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

        InkWell(

          onTap: () {

            onChanged(!value);

          },

          child: ListTile(

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

        ),

        Divider(),

      ],

    );

  }

}

