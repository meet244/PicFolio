import 'dart:io';

import 'package:ai_barcode_scanner/ai_barcode_scanner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:photoz/globals.dart';
import 'package:photoz/screens/login.dart';
import 'package:photoz/shravani.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  final bool noip;

  const SplashScreen({super.key, this.noip = false});

  @override
  _MySplashState createState() => _MySplashState();
}

class _MySplashState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  bool isLogedin = false;

  @override
  void initState() {
    super.initState();

    SharedPreferences.getInstance().then((prefs) {
      final username = prefs.getString('username');
      if (username != null && username.isNotEmpty) {
        isLogedin = true;
        Globals.username = username;
      }

      // TODO: Remove this code
      // Globals.ip = '127.0.0.1';

      String? ips = prefs.getString('ips');
      print('IPs: $ips');
      if (ips != null && ips.isNotEmpty) {
        print('IPs: $ips');
        checkPort(ips, 7251).then((value) {
          if (value) {
            Globals.ip = ips;
          }
        });
      }
    });

    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800), // Set the animation duration
    );

    _scaleAnimation = Tween<double>(
      begin: 0.75,
      end: 1.0, // Scale to full size
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.ease, // Use the ease curve for smoother animation
    ));

    // Start the animation when the page loads
    _controller.forward();

    // Delay setting _isLoading to false by 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        if (Globals.ip != '' && !widget.noip) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) {
              if (isLogedin) {
                return MyHomePage();
              } else {
                return const LoginPage();
              }
            }),
          );
        } else {
          print("Globals.ip: ${Globals.ip}");
          print('No IP found, opening barcode scanner');
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => AiBarcodeScanner(
                validator: (value) {
                  return value.startsWith('https://picfolio.vercel.app/scan/');
                },
                canPop: false,
                onScan: (String value) {
                  value =
                      value.replaceAll('https://picfolio.vercel.app/scan/', '');
                  debugPrint(value);
                  SharedPreferences.getInstance().then((prefs) {
                    String? ipLast = prefs.getString('ips');
                    ipLast ??= '';
                    prefs.setString('ips', value);
                    print("stored");
                  });
                  Globals.ip = value;
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) {
                      if (isLogedin) {
                        return MyHomePage();
                      } else {
                        return const LoginPage();
                      }
                    }),
                  );
                },
                onDetect: (p0) {},
                onDispose: () {
                  debugPrint("Barcode scanner disposed!");
                },
                controller: MobileScannerController(
                  detectionSpeed: DetectionSpeed.noDuplicates,
                ),
              ),
            ),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget title = Text(
      'PicFolio',
      style: TextStyle(
        fontWeight: FontWeight.w900,
        fontSize: 50,
        // color: Color.fromARGB(255, 122, 122, 122),
        color: Theme.of(context).colorScheme.primary,
        height: 1,
        letterSpacing: -1,
      ),
    )
            .animate()
            .fadeIn(duration: 500.ms, curve: Curves.easeOutQuad)
            .animate(delay: 500.ms)
            .shimmer(duration: 1000.ms, color: Colors.white)
        // .slide()
        ;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Show the splash logo while loading
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Transform.scale(
                        scale: _scaleAnimation.value,
                        child: SvgPicture.asset(
                          'assets/logo.svg',
                          width: 200, // specify the width
                          height: 200, // specify the height
                          // you can also use other properties like color, alignment, etc.
                        ),
                      ),
                      const SizedBox(height: 50),
                      title,
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

Future<bool> checkPort(String host, int port) 
async {
  host = host.replaceAll('http://', '');
  print('Checking $host:$port');
  try {
    final Socket socket =
        await Socket.connect(host, port, timeout: Duration(seconds: 2));
    print('Service found at $host:$port');
    await socket.close();
    return true;
  } catch (e) {
    // Port is closed or host is unreachable
  }
  return false;
}
