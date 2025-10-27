import 'dart:convert';
import 'package:csdl_mobile/session_storage.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';

class StudentQrDutyRegistration extends StatefulWidget {
  final String student_id;
  const StudentQrDutyRegistration({Key? key, required this.student_id})
      : super(key: key);

  @override
  _StudentQrDutyRegistrationState createState() =>
      _StudentQrDutyRegistrationState();
}

class _StudentQrDutyRegistrationState extends State<StudentQrDutyRegistration> {
  Barcode? _barcode;
  String? _lastScanned;
  DateTime? _lastScanTime;
  Duration _cooldown = const Duration(seconds: 5);
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

  void _handleBarcode(BarcodeCapture barcodes) {
    final scanned = barcodes.barcodes.firstOrNull;
    final scannedData = scanned?.displayValue;

    if (scannedData == null) return;

    final now = DateTime.now();

    if (_lastScanned == scannedData &&
        _lastScanTime != null &&
        now.difference(_lastScanTime!) < _cooldown) {
      return;
    }

    setState(() {
      _barcode = scanned;
      _lastScanned = scannedData;
      _lastScanTime = now;
    });

    _verifyAndAssignSupervisor(scannedData);
  }

  void _verifyAndAssignSupervisor(String qrData) async {
    try {
      final decoded = jsonDecode(
          qrData); // Expected keys: supM_id, sub_code, sub_section, session_name

      final url = Uri.parse("${SessionStorage.url}transaction.php");
      final studentId = widget.student_id;

      final scholarSubjectReq = {
        "operation": "getScholarsAssignedDutyForQrScanning",
        "json": jsonEncode({"assign_stud_id": studentId}),
      };

      final res = await http.post(url, body: scholarSubjectReq);

      if (res.statusCode == 200) {
        final assignedSubjects = jsonDecode(res.body);
        bool matchFound = false;

        for (var sub in assignedSubjects) {
          if (sub["sub_code"] == decoded["sub_code"] &&
              sub["sub_section"] == decoded["sub_section"] &&
              sub["session_name"] == decoded["session_name"]) {
            matchFound = true;
            break;
          }
        }

        if (!matchFound) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text("QR does not match your assigned subjects.")),
          );
          return;
        }

        // âœ… Proceed to assign supM_id
        final assignRes = await http.post(
          url,
          body: {
            "operation": "updateSubjectSupervisor",
            "json": jsonEncode({
              "supM_id": decoded["supM_id"],
              "sub_code": decoded["sub_code"],
              "sub_section": decoded["sub_section"],
              "session_name": decoded["session_name"],
            }),
          },
        );

        if (assignRes.statusCode == 200) {
          final response = jsonDecode(assignRes.body);
          if (response["success"] == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text("Supervisor assigned successfully.")),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(
                      "Assignment failed: ${response["error"] ?? "Unknown error"}")),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Server error: ${assignRes.statusCode}")),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Server error: ${res.statusCode}")),
        );
      }
    } catch (e) {
      print("Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("An error occurred during QR processing.")),
      );
    }
  }

  Widget _buildBarcodeInfo() {
    if (_barcode == null) {
      return const Text(
        'Scan the QR code from your advisor/supervisor.',
        style: TextStyle(color: Colors.white),
      );
    }
    return Text(
      _barcode!.displayValue ?? "No data",
      style: const TextStyle(color: Colors.white),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Student Duty Registration")),
      backgroundColor: Colors.black,
      body: !_hasPermission
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                MobileScanner(onDetect: _handleBarcode),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    height: 100,
                    color: Colors.black.withOpacity(0.4),
                    child: Center(child: _buildBarcodeInfo()),
                  ),
                ),
              ],
            ),
    );
  }
}
