import 'dart:convert';
import 'package:csdl_mobile/session_storage.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';

class AdvisorQrScanner extends StatefulWidget {
  final String advisor_id;
  final void Function(String)? onScanned;

  const AdvisorQrScanner({
    super.key,
    required this.advisor_id,
    this.onScanned,
  });

  @override
  State<AdvisorQrScanner> createState() => _AdvisorQrScannerState();
}

class _AdvisorQrScannerState extends State<AdvisorQrScanner> {
  Barcode? _barcode;
  String? _lastScannedId;
  DateTime? _lastScanTime;
  Duration _cooldownDuration = const Duration(seconds: 5);
  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    _checkCameraPermission();
  }

  Future<void> _checkCameraPermission() async {
    var status = await Permission.camera.status;
    if (!status.isGranted) {
      status = await Permission.camera.request();
    }

    setState(() {
      _hasPermission = status.isGranted;
    });

    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Camera permission denied")),
      );
      Navigator.pop(context);
    }
  }

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

      if (widget.onScanned != null) {
        widget.onScanned!(scannedId);
      } else {
        studentsAttendance(scannedId);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Simple scanner')),
      backgroundColor: Colors.black,
      body: !_hasPermission
          ? const Center(child: CircularProgressIndicator())
          : Stack(
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

  void studentsAttendance(String scannedId) async {
    try {
      var url = Uri.parse("${SessionStorage.url}transaction.php");
      Map<String, dynamic> jsonData = {
        "stud_active_id": scannedId,
        "advisor_id": widget.advisor_id,
      };
      Map<String, String> requestBody = {
        "operation": "studentsAttendance",
        "json": jsonEncode(jsonData),
      };

      var response = await http.post(url, body: requestBody);

      if (response.statusCode == 200) {
        var res = jsonDecode(response.body);

        if (res is Map && res["error"] != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res["error"])),
          );
        } else if (res == 1 || (res is List && res.contains(1))) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Attendance marked successfully!")),
          );

          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) Navigator.pop(context);
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Failed to mark attendance.")),
          );
        }
      } else {
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
