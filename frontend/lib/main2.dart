import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
// import 'package:js/js.dart' as js;
import 'package:qr_code_scanner/qr_code_scanner.dart';

class QRApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QR Code Scanner',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: QRScannerPage(),
    );
  }
}

class QRScannerPage extends StatefulWidget {
  @override
  _QRScannerPageState createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;

  final List<String> services = [];

  @override
  void initState() {
    super.initState();
    _scanServices();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('QR Code Scanner')),
      body: Column(
        children: [
          Expanded(
            flex: 4,
            child: _buildQRView(),
          ),
          Expanded(
            flex: 1,
            child: ElevatedButton(
              onPressed: () {
                _showServicesBottomSheet(context);
              },
              child: Text('Show Services'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQRView() {
    return QRView(
      key: qrKey,
      onQRViewCreated: _onQRViewCreated,
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      // Verify the QR code and connect to the service
      // For demonstration, we'll print the scanned data
      print('Scanned data: ${scanData.code}');
    });
  }

  void _showServicesBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 200,
          child: ListView.builder(
            itemCount: services.length,
            itemBuilder: (BuildContext context, int index) {
              return ListTile(
                title: Text('Service ${index + 1}'),
                subtitle: Text(services[index]), // Display service IP and port
                onTap: () {
                  // Connect to the selected service
                  // For demonstration, we'll print the service info
                  print('Connecting to Service ${services[index]}');
                  Navigator.pop(context); // Close the bottom sheet
                },
              );
            },
          ),
        );
      },
    );
  }

  void _scanServices() {
    final String baseIp = '192.168.';
    final int port = 7251;

    for (int i = 0; i <= 255; i++) {
      for (int j = 0; j <= 255; j++) {
        String ip = baseIp + i.toString() + '.' + j.toString();
        checkPort(ip, port);
      }
    }
  }

  void checkPort(String ip, int port) async {
    try {
      final response = await http.get(Uri.parse('http://$ip:$port'));
      if (response.statusCode == 200) {
        setState(() {
          services.add('$ip:$port');
        });
      }
    } catch (e) {
      // Error occurred, port is closed or unreachable
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}
