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

  @override
  void dispose() {
    // Clean up any resources if needed
    super.dispose();
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
        'Ready to scan',
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: Colors.white70,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      );
    }

    return Text(
      value.displayValue ?? 'No display value.',
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  void _handleBarcode(BarcodeCapture barcodes) {
    // Check if widget is still mounted before processing
    if (!mounted) return;
    
    final scannedBarcode = barcodes.barcodes.firstOrNull;
    final scannedId = scannedBarcode?.displayValue;

    if (scannedId == null) return;

    // Check if QR code is within the scanning frame (250x250px centered)
    if (!_isWithinScanningArea(scannedBarcode)) {
      // QR code is outside the scanning area - ignore it completely
      return;
    }

    // QR code is inside the scanning area - process it
    
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

  bool _isWithinScanningArea(Barcode? barcode) {
    if (barcode == null || barcode.corners == null || barcode.corners!.isEmpty) {
      return false;
    }

    // Check if widget is still mounted before accessing MediaQuery
    if (!mounted) return false;

    // Get the center point of the QR code
    double centerX = 0;
    double centerY = 0;
    for (var corner in barcode.corners!) {
      centerX += corner.dx;
      centerY += corner.dy;
    }
    centerX /= barcode.corners!.length;
    centerY /= barcode.corners!.length;

    // Get screen dimensions
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // Calculate the scanning area bounds to match the visual frame exactly
    final scanAreaSize = 250.0;
    final scanAreaLeft = (screenWidth - scanAreaSize) / 2;
    // Position the scanning area higher to match the visual frame in the image
    final scanAreaTop = (screenHeight - scanAreaSize) / 2 - 200; // Move up more to match visual frame
    final scanAreaRight = scanAreaLeft + scanAreaSize;
    final scanAreaBottom = scanAreaTop + scanAreaSize;

    // Check if QR code center is within the exact frame boundaries
    // No tolerance - must be exactly inside the green frame
    bool isWithin = centerX >= scanAreaLeft && 
                    centerX <= scanAreaRight && 
                    centerY >= scanAreaTop && 
                    centerY <= scanAreaBottom;

    // Debug information
    
    
    
    
    // Additional debug info
    
    

    return isWithin;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'QR Code Scanner',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: !_hasPermission
          ? Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF1A1A1A), Color(0xFF000000)],
                ),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Requesting camera permission...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF1A1A1A), Color(0xFF000000)],
                ),
              ),
              child: Stack(
                children: [
                  // Scanner
                  MobileScanner(
                    onDetect: _handleBarcode,
                  ),
                  
                  // Top overlay with instructions
                  Positioned(
                    top: 20,
                    left: 20,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.qr_code_scanner,
                            color: Colors.green,
                            size: 24,
                          ),
                          SizedBox(width: 12),
                          // Expanded(
                          //   child: Text(
                          //     'Position the QR code within the frame to scan',
                          //     style: TextStyle(
                          //       color: Colors.white,
                          //       fontSize: 14,
                          //       fontWeight: FontWeight.w500,
                          //     ),
                          //   ),
                          // ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Center scanning frame (positioned to match scanning area exactly)
                  Positioned(
                    top: (MediaQuery.of(context).size.height - 250) / 2 - 200, // Match scanning area position
                    left: (MediaQuery.of(context).size.width - 250) / 2,
                    child: Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.green,
                          width: 3,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Stack(
                        children: [
                          // Corner decorations
                          Positioned(
                            top: 0,
                            left: 0,
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: const BoxDecoration(
                                border: Border(
                                  top: BorderSide(color: Colors.green, width: 4),
                                  left: BorderSide(color: Colors.green, width: 4),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: const BoxDecoration(
                                border: Border(
                                  top: BorderSide(color: Colors.green, width: 4),
                                  right: BorderSide(color: Colors.green, width: 4),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: const BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(color: Colors.green, width: 4),
                                  left: BorderSide(color: Colors.green, width: 4),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: const BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(color: Colors.green, width: 4),
                                  right: BorderSide(color: Colors.green, width: 4),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Bottom overlay with scan result
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.8),
                          ],
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Scan result
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _barcode != null ? Icons.check_circle : Icons.qr_code,
                                  color: _barcode != null ? Colors.green : Colors.white70,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildBarcode(_barcode),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Scanning area indicator
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: Colors.green.withOpacity(0.3),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.crop_free,
                                  color: Colors.green,
                                  size: 16,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  "Position QR code within the green frame",
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Instructions
                          const Text(
                            'Point your camera at a QR code',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
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
          String errorType = res["type"] ?? "";
          
          // Check for specific error messages and show user-friendly alerts
          if (errorMessage.contains("No valid assignment found") || 
              errorMessage.contains("not assigned to this supervisor") ||
              errorMessage.contains("Student is not assigned")) {
            _showStudentNotFoundDialog();
          } else if (errorType.startsWith("sf_duty_")) {
            // Handle SF duty validation errors with custom dialog
            String dutyStartTime = res["duty_start_time"] ?? "";
            String dutyEndTime = res["duty_end_time"] ?? "";
            _showSFDutyValidationDialog(errorMessage, dutyStartTime, dutyEndTime, errorType);
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
          _showSuccessDialog();
        } else if (res == 1 || (res is List && res.contains(1))) {
          _showSuccessDialog();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Failed to mark attendance."),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("An error occurred while marking attendance.")),
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
                        "This student is not assigned to your duty supervision.",
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
                    Text("â€¢ The student is assigned to your supervision"),
                    Text("â€¢ The QR code is valid and not damaged"),
                    Text("â€¢ The student is scheduled for today's duty"),
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

  void _showSFDutyValidationDialog(String errorMessage, String dutyStartTime, String dutyEndTime, String errorType) {
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
                Icons.schedule,
                color: Colors.red[700],
                size: 28,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  "SF Duty Validation",
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
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning,
                      color: Colors.red[700],
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        errorMessage,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.4,
                          color: Colors.red[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Duty Schedule Information
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          color: Colors.blue[700],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          "Your Duty Schedule",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF104038),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Duty Start:",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF104038),
                              ),
                            ),
                            Text(
                              dutyStartTime,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[700],
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Duty End:",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF104038),
                              ),
                            ),
                            Text(
                              dutyEndTime,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[700],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Instructions based on error type
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.orange[700],
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          "Please Note:",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF104038),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getInstructionText(errorType),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.orange[700],
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                backgroundColor: Colors.red[700],
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

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Success"),
          content: const Text("Attendance marked successfully!"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.pop(context); // Go back to previous page
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  String _getInstructionText(String errorType) {
    switch (errorType) {
      case "sf_duty_too_early":
        return "â€¢ You can only scan attendance during your assigned duty time\nâ€¢ Please wait until your duty starts to scan time-in";
      case "sf_duty_late_timein":
        return "â€¢ You missed the 15-minute grace period for time-in\nâ€¢ Please contact your supervisor for assistance";
      case "sf_duty_too_early_timeout":
        return "â€¢ You can only scan time-out after your duty ends\nâ€¢ Please wait until your duty time is complete";
      case "sf_duty_late_timeout":
        return "â€¢ You missed the 15-minute grace period for time-out\nâ€¢ Please contact your supervisor for assistance";
      case "sf_duty_expired":
        return "â€¢ Your duty time has ended and the grace period has expired\nâ€¢ Please contact your supervisor for assistance";
      default:
        return "â€¢ Please follow your assigned duty schedule\nâ€¢ Contact your supervisor if you have questions";
    }
  }

}
