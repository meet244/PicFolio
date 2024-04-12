import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:http/http.dart' as http;
import 'package:photoz/globals.dart';

// import 'linechart.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _StatisticsPageState createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  int total = 0;

  // ignore: prefer_typing_uninitialized_variables
  var apiResponse;

  @override
  void initState() {
    super.initState();
    fetchdata();
  }

  void fetchdata() async {
    final response = await http.post(
      Uri.parse('${Globals.ip}/api/stats'),
      body: {
        'username': Globals.username,
      },
    );
    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      if (kDebugMode) print(data);
      // count total assets
      total = data['image_counts'].values.fold(0, (sum, count) => sum + count) +
          data['video_counts'].values.fold(0, (sum, count) => sum + count);
      setState(() {
        apiResponse = data;
      });
    } else {
      throw Exception('Failed to load images');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Stats'),
        ),
        body: (apiResponse == null)
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Center(
                          child: Container(
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width *
                                  0.6, // 80% of screen width
                              maxHeight: MediaQuery.of(context).size.height *
                                  0.3, // 50% of screen height
                            ),
                            child: Stack(
                              children: [
                                PieChart(
                                  PieChartData(
                                    borderData: FlBorderData(
                                      show: false,
                                    ),
                                    sectionsSpace: 0,
                                    centerSpaceRadius: 70,
                                    sections: showingSectionsimg(),
                                  ),
                                ),
                                Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.photo_outlined,
                                        size: 30,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '${apiResponse!['image_counts'].values.fold(0, (sum, count) => sum + count)}',
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              for (var entry
                                  in apiResponse?['image_counts'].entries)
                                Row(
                                  children: [
                                    Icon(
                                      Icons.circle,
                                      color: _getColorForLabel(entry.key),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(entry.key.toUpperCase()),
                                    const SizedBox(width: 5),
                                    Text(entry.value.toString()),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Center(
                          child: Container(
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width *
                                  0.6, // 80% of screen width
                              maxHeight: MediaQuery.of(context).size.height *
                                  0.3, // 50% of screen height
                            ),
                            child: Stack(
                              children: [
                                PieChart(
                                  PieChartData(
                                    borderData: FlBorderData(
                                      show: false,
                                    ),
                                    sectionsSpace: 0,
                                    centerSpaceRadius: 70,
                                    sections: showingSectionsvid(),
                                  ),
                                ),
                                Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.video_collection_outlined,
                                        size: 30,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '${apiResponse!['video_counts'].values.fold(0, (sum, count) => sum + count)}',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              for (var entry
                                  in apiResponse?['video_counts'].entries)
                                Row(
                                  children: [
                                    Icon(
                                      Icons.circle,
                                      color: _getColorForLabel(entry.key),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(entry.key.toUpperCase()),
                                    const SizedBox(width: 5),
                                    Text(entry.value.toString()),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Center(
                      child: SimpleLineChart(apiResponse: apiResponse!),
                    ),
                    // Modify the code to use the extracted data

                    Row(
                      children: [
                        const SizedBox(width: 20),
                        const Icon(Icons.storage_outlined),
                        const SizedBox(width: 10),
                        LinearPercentIndicator(
                          trailing: Padding(
                            padding: const EdgeInsets.only(left: 10),
                            child: Text(
                                "${apiResponse['used_storage']} / ${apiResponse['total_storage']} GB"),
                          ),
                          width: 200,
                          lineHeight: 17.0,
                          percent: apiResponse['used_storage'] /
                              apiResponse['total_storage'],
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.2),
                          progressColor: Theme.of(context).colorScheme.primary,
                          animation: true,
                          animationDuration: 1000,
                          barRadius: const Radius.circular(10),
                          center: Text(
                            "${(apiResponse['used_storage'] / apiResponse['total_storage'] * 100).toStringAsFixed(0)}%",
                            style: TextStyle(
                                fontSize: 15,
                                color: Theme.of(context).colorScheme.onPrimary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    if (apiResponse['top_locations'].length > 0)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(left: 20),
                            child: Text(
                              "TOP PLACES",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Montserrat',
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Row(
                              children: [
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    for (var location
                                        in apiResponse['top_locations'])
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Container(
                                          padding: const EdgeInsets.all(5),
                                          decoration: BoxDecoration(
                                            color: Colors.transparent,
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            border: Border.all(
                                              color: Colors.pink,
                                              width: 2,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(
                                                  Icons.location_on_outlined),
                                              const SizedBox(width: 5),
                                              Text(location),
                                            ],
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(width: 10),
                                const Spacer(),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(20.0),
                                      child: LinearPercentIndicator(
                                        trailing: Padding(
                                          padding: const EdgeInsets.only(left: 10),
                                          child: Text(
                                              apiResponse['used_storage']
                                                  .toString()),
                                        ),
                                        width: 100.0,
                                        lineHeight: 17.0,
                                        percent: apiResponse['used_storage'] /
                                            apiResponse['total_storage'],
                                        backgroundColor: const Color(0xffefefef),
                                        progressColor: const Color(0xffb8e0ff),
                                        animation: true,
                                        animationDuration: 1000,
                                        barRadius: const Radius.circular(10),
                                        center: Text(
                                          "${(apiResponse['used_storage'] / apiResponse['total_storage'] * 100).toStringAsFixed(0)}%",
                                          style: const TextStyle(
                                            fontSize: 15,
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    if (apiResponse['top_albums'].length > 0)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(left: 20),
                            child: Text(
                              "TOP ALBUMS",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Montserrat',
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Row(
                              children: [
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    for (var album
                                        in apiResponse['top_albums'])
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Container(
                                          padding: const EdgeInsets.all(5),
                                          decoration: BoxDecoration(
                                            color: Colors.transparent,
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            border: Border.all(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .tertiary,
                                              width: 2,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(
                                                  Icons.photo_album_outlined),
                                              const SizedBox(width: 5),
                                              Text(album[0]),
                                            ],
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(width: 10),
                                const Spacer(),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(20.0),
                                      child: LinearPercentIndicator(
                                        trailing: Padding(
                                          padding: const EdgeInsets.only(left: 10),
                                          child: Text(
                                              apiResponse['top_albums'][0][1]
                                                  .toString()),
                                        ),
                                        width: 100.0,
                                        lineHeight: 17.0,
                                        percent: apiResponse['top_albums'][0]
                                                [1] /
                                            total,
                                        backgroundColor: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withOpacity(0.2),
                                        progressColor: Theme.of(context)
                                            .colorScheme
                                            .tertiary,
                                        animation: true,
                                        animationDuration: 1000,
                                        barRadius: const Radius.circular(10),
                                        center: Text(
                                          "${(apiResponse['top_albums'][0][1] / total * 100).toStringAsFixed(0)}%",
                                          style: const TextStyle(fontSize: 15),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ));
  }

  List<PieChartSectionData> showingSectionsvid() {
    final assetCounts = apiResponse!['video_counts'] as Map<String, dynamic>;

    return assetCounts.entries.map((entry) {
      final label = entry.key;
      final value = (entry.value as num).toDouble();
      const radius = 20.0;

      return PieChartSectionData(
        color: _getColorForLabel(label),
        value: value,
        showTitle: false,
        radius: radius,
      );
    }).toList();
  }

  List<PieChartSectionData> showingSectionsimg() {
    final assetCounts = apiResponse!['image_counts'] as Map<String, dynamic>;

    return assetCounts.entries.map((entry) {
      final label = entry.key;
      final value = (entry.value as num).toDouble();
      const radius = 20.0;

      return PieChartSectionData(
        color: _getColorForLabel(label),
        value: value,
        showTitle: false,
        radius: radius,
      );
    }).toList();
  }
}

Color _getColorForLabel(String label) {
  switch (label) {
    case 'heic':
      return const Color(0xffffa4e1);
    case 'jpeg':
      return const Color(0xff3bffc8);
    case 'jpg':
      return const Color(0xffadd6f7);
    case 'mp4':
      return const Color(0xfffebefb);
    case 'png':
      return const Color(0xffffff9f);
    case 'avif':
      return const Color(0xffffc0cb); // Light Pink
    case 'ttif':
      return const Color(0xff7fffd4); // Aquamarine
    case 'webp':
      return const Color(0xff00ffff); // Cyan
    case 'jfif':
      return const Color(0xffff6347); // Tomato
    case 'mov':
      return const Color(0xff20b2aa); // Light Sea Green
    case 'avi':
      return const Color(0xff9370db); // Medium Purple
    case 'webm':
      return const Color(0xff2e8b57); // Sea Green
    case 'flv':
      return const Color(0xff8a2be2); // Blue Violet
    case 'wmv':
      return const Color(0xff48d1cc); // Medium Turquoise
    case 'mkv':
      return const Color(0xffd8bfd8); // Thistle
    default:
      throw Error();
  }
}

class SimpleLineChart extends StatelessWidget {
  final Map<String, dynamic> apiResponse;

  const SimpleLineChart({super.key, required this.apiResponse});

  @override
  Widget build(BuildContext context) {
    final yearlyCounts = apiResponse['yearly_counts'] as List<dynamic>;

    final bottomBarValues =
        yearlyCounts.map((entry) => entry[0] as String).toList();

    return Container(
      padding: const EdgeInsets.all(30.0),
      child: SizedBox(
        width: MediaQuery.of(context).size.width,
        height: 200, // Set a fixed height for the chart
        child: LineChart(
          LineChartData(
            lineBarsData: [
              LineChartBarData(
                spots: yearlyCounts.map((entry) {
                  final label = entry[0] as String;
                  final value = (entry[1] as num).toDouble();
                  final index = bottomBarValues.indexOf(label);
                  return FlSpot(
                    index.toDouble(),
                    value,
                  );
                }).toList(),
                isCurved: true,
                colors: [Colors.purple],
                barWidth: 2,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: true,
                  // Show spots
                  getDotPainter: (spot, percent, barData, index) =>
                      FlDotCirclePainter(
                    radius: 2,
                    color: Colors.white,
                    strokeWidth: 2,
                    strokeColor: Colors.black,
                  ),
                ),
                belowBarData: BarAreaData(
                  show: true,
                  colors: [
                    Color.fromARGB(255, 149, 120, 255).withOpacity(0.7),
                    const Color.fromARGB(255, 149, 120, 255).withOpacity(0.4),
                    // Colors.white.withOpacity(0.5),
                  ],
                  gradientColorStops: [0.8, 0.9],
                  gradientFrom: const Offset(0, 3),
                  gradientTo: const Offset(1, 0),
                ),
              ),
            ],
            titlesData: FlTitlesData(
              leftTitles: SideTitles(
                showTitles: true,
                getTitles: (value) {
                  if (value % 200 == 0) {
                    return value.toInt().toString();
                  }
                  return '';
                },
                getTextStyles: (value) =>
                    const TextStyle(color: Colors.white), // Set text color to white
              ),
              bottomTitles: SideTitles(
                showTitles: true,
                getTitles: (value) {
                  if (value.toInt() >= 0 &&
                      value.toInt() < bottomBarValues.length) {
                    return bottomBarValues[value.toInt()];
                  }
                  return '';
                },
                getTextStyles: (value) =>
                    const TextStyle(color: Colors.white), // Set text color to white
              ),
            ),
            gridData: FlGridData(
              show: true,
              getDrawingHorizontalLine: (value) {
                if (value % 200 == 0) {
                  return FlLine(
                    color: Colors.grey,
                    strokeWidth: 0.5,
                  );
                } else {
                  return FlLine(
                    color: Colors.transparent,
                  );
                }
              },
            ),
            borderData: FlBorderData(show: false),
          ),
        ),
      ),
    );
  }
}
