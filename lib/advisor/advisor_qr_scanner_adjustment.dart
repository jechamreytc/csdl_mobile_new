//AdvisorQrScannerAdjustment

import 'dart:convert';
import 'package:csdl_mobile/session_storage.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;

class AdvisorQrScannerAdjustment extends StatefulWidget {
  const AdvisorQrScannerAdjustment({super.key});

  @override
  State<AdvisorQrScannerAdjustment> createState() =>
      _AdvisorQrScannerAdjustmentState();
}

class _AdvisorQrScannerAdjustmentState
    extends State<AdvisorQrScannerAdjustment> {
  Barcode? _barcode;

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
    if (mounted) {
      setState(() {
        _barcode = barcodes.barcodes.firstOrNull;
      });

      // Call the attendance function after a successful scan
      if (_barcode != null) {
        studentsAttendence();
      }
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
        "advisor_id": "temp_advisor", // This will be validated by the API
      };
      Map<String, String> requestBody = {
        "operation": "studentsAttendance",
        "json": jsonEncode(jsonData),
      };

      var response = await http.post(url, body: requestBody);

      if (response.statusCode == 200) {
        // Check if response contains HTML (PHP errors)
        String responseBody = response.body.trim();
        
        // Detect HTML responses (PHP errors)
        if (responseBody.startsWith('<') || 
            responseBody.contains('<br') || 
            responseBody.contains('<b>') ||
            responseBody.contains('Fatal error') ||
            responseBody.contains('Warning') ||
            responseBody.contains('Notice') ||
            responseBody.contains('Parse error') ||
            responseBody.contains('Call to undefined')) {
          print("Server returned HTML instead of JSON: $responseBody");
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Server error: Please try again later"),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
          return;
        }

        // Try to parse JSON safely
        dynamic res;
        try {
          res = jsonDecode(responseBody);
        } catch (jsonError) {
          print("JSON Parse Error: $jsonError");
          print("Response body: $responseBody");
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Server error: Invalid response format"),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
          return;
        }

        // Handle the parsed response
        if (res is Map && res["error"] != null) {
          String errorMessage = res["error"];
          
          // Check for specific error messages and show user-friendly alerts
          if (errorMessage.contains("No valid assignment found") || 
              errorMessage.contains("not assigned to this supervisor") ||
              errorMessage.contains("Student is not assigned")) {
            _showStudentNotFoundDialog();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMessage),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        } else if (res is Map && res["success"] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Student found successfully!"),
              backgroundColor: Colors.green,
            ),
          );

          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) Navigator.pop(context, _barcode!.displayValue);
          });
        } else if (res != 0) {
          print("Student found successfully");
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Student found successfully!"),
              backgroundColor: Colors.green,
            ),
          );

          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) Navigator.pop(context, _barcode!.displayValue);
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Student not found in assigned scholars."),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${response.statusCode}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print("ERROR: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("An error occurred while scanning student.")),
      );
    }
  }

  void _showStudentNotFoundDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.person_off,
                color: Colors.orange[700],
                size: 28,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  "Student Not Found",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.orange[700],
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        "This student is not found in your assigned scholars list.",
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Please verify that:",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              const Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("• The student is assigned to your supervision"),
                    Text("• The QR code is valid and not damaged"),
                    Text("• The student is scheduled for today's duty"),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                backgroundColor: Colors.orange[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                "OK",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
