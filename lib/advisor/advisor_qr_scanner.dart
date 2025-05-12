import 'dart:convert';
import 'package:csdl_mobile/session_storage.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;

class AdvisorQrScanner extends StatefulWidget {
  const AdvisorQrScanner({super.key});

  @override
  State<AdvisorQrScanner> createState() => _AdvisorQrScannerState();
}

class _AdvisorQrScannerState extends State<AdvisorQrScanner> {
  Barcode? _barcode;
  String? _lastScannedId;
  DateTime? _lastScanTime;
  Duration _cooldownDuration =
      const Duration(seconds: 5); // Prevent repeat within 5s

  Widget _buildBarcode(Barcode? value) {
    if (value == null) {
      return const Text(
        'Scan something!',
        overflow: TextOverflow.fade,
        style: TextStyle(color: Colors.white),
      );
    }

    return Text(
      value.displayValue ?? 'No display value.',
      overflow: TextOverflow.fade,
      style: const TextStyle(color: Colors.white),
    );
  }

  void _handleBarcode(BarcodeCapture barcodes) {
    final scannedBarcode = barcodes.barcodes.firstOrNull;
    final scannedId = scannedBarcode?.displayValue;

    if (scannedId == null) return;

    final now = DateTime.now();

    // Block if it's the same ID within the cooldown duration
    if (_lastScannedId == scannedId &&
        _lastScanTime != null &&
        now.difference(_lastScanTime!) < _cooldownDuration) {
      return;
    }

    if (mounted) {
      setState(() {
        _barcode = scannedBarcode;
        _lastScannedId = scannedId;
        _lastScanTime = now;
      });

      studentsAttendence();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Simple scanner')),
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            onDetect: _handleBarcode,
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 100,
              color: Colors.black.withOpacity(0.4),
              child: Center(
                child: _buildBarcode(_barcode),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void studentsAttendence() async {
    if (_barcode == null) return; // Safety check for null barcode

    try {
      var url = Uri.parse("${SessionStorage.url}transaction.php");
      Map<String, dynamic> jsonData = {
        "stud_active_id": _barcode!.displayValue,
      };
      Map<String, String> requestBody = {
        "operation": "studentsAttendance",
        "json": jsonEncode(jsonData),
      };

      var response = await http.post(url, body: requestBody);

      // Check response status code
      if (response.statusCode == 200) {
        var res = jsonDecode(response.body);
        if (res != 0) {
          // Navigator.pop(context);
          print("Time in Success");
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Attendance marked successfully!")),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Failed to mark attendance.")),
          );
        }
      } else {
        // Handle unexpected response
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${response.statusCode}")),
        );
      }
    } catch (e) {
      print("ERROR: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("An error occurred while marking attendance.")),
      );
    }
  }
}
