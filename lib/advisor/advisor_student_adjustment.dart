import 'dart:convert';
import 'package:csdl_mobile/session_storage.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'advisor_qr_scanner.dart'; // import scanner
import 'package:intl/intl.dart';
import 'advisor_drawer.dart';

class AdvisorStudentAdjustment extends StatefulWidget {
  final String advisor_id;
  final String supervisor_id;
  const AdvisorStudentAdjustment({
    super.key,
    required this.advisor_id,
    required this.supervisor_id,
  });

  @override
  State<AdvisorStudentAdjustment> createState() =>
      _AdvisorStudentAdjustmentState();
}

class _AdvisorStudentAdjustmentState extends State<AdvisorStudentAdjustment> {
  final TextEditingController _studentIdController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _hoursInputController = TextEditingController();
  final TextEditingController _minutesInputController = TextEditingController();

  DateTime? _selectedDate;
  bool _isLoading = false;
  String _message = "";

  void _pickDate() async {
    DateTime now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 1),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void submitAdjustment() async {
    final hours = int.tryParse(_hoursInputController.text.trim()) ?? 0;
    final minutes = int.tryParse(_minutesInputController.text.trim()) ?? 0;

    if (_studentIdController.text.trim().isEmpty ||
        _reasonController.text.trim().isEmpty ||
        _selectedDate == null ||
        (hours == 0 && minutes == 0)) {
      setState(() {
        _message =
            "Please fill all fields, select a date, and enter hours or minutes.";
      });
      return;
    }

    // Check if supervisor_id is available
    if (widget.supervisor_id.isEmpty) {
      setState(() {
        _message = "Supervisor ID is missing. Please contact administrator.";
      });
      return;
    }

    final totalDeduction = hours + (minutes / 60);
    final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate!);

    try {
      var url = Uri.parse("${SessionStorage.url}transaction.php");

      Map<String, dynamic> jsonData = {
        "adj_student_id": _studentIdController.text.trim(),
        "adj_supervisor_id": widget.supervisor_id,
        "adj_reason": _reasonController.text.trim(),
        "adj_hours": totalDeduction.toStringAsFixed(2),
        "adj_date": formattedDate,
      };

      // Debug logging removed

      Map<String, String> requestBody = {
        "operation": "addScholarHourDeduction",
        "json": jsonEncode(jsonData),
      };

      setState(() {
        _isLoading = true;
        _message = "";
      });

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
          setState(() {
            _isLoading = false;
            _message = "Server error: Please try again later";
          });
          return;
        }

        // Try to parse JSON safely
        dynamic res;
        try {
          res = jsonDecode(responseBody);
        } catch (jsonError) {
          setState(() {
            _isLoading = false;
            _message = "Server error: Invalid response format";
          });
          return;
        }

        // Handle the parsed response
        if (res is Map && res["error"] != null) {
          String errorMessage = res["error"];
          
          // Check for specific error messages and show user-friendly alerts
          if (errorMessage.contains("No valid assignment found") || 
              errorMessage.contains("not assigned to this supervisor") ||
              errorMessage.contains("Student is not assigned") ||
              errorMessage.contains("Student not found") ||
              errorMessage.contains("is not assigned to this supervisor")) {
            setState(() {
              _isLoading = false;
              _message = "";
            });
            _showStudentNotFoundDialog();
          } else {
            setState(() {
              _isLoading = false;
              _message = errorMessage;
            });
          }
        } else if (res is Map && res["status"] == "success") {
          setState(() {
            _isLoading = false;
          });

          // Clear form fields
          _studentIdController.clear();
          _reasonController.clear();
          _hoursInputController.clear();
          _minutesInputController.clear();
          _selectedDate = null;
          
          // Show success dialog
          _showSuccessDialog();
        } else {
          setState(() {
            _isLoading = false;
            _message = "Failed to deduct. Please try again.";
          });
        }
        
      } else {
        setState(() {
          _isLoading = false;
          _message = "Error: ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _message = "An error occurred. Please try again.";
      });
    }
  }

  void openScanner() async {
    final scannedId = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdvisorQrScanner(
          advisor_id: widget.advisor_id,
          onScanned: (id) {
            Navigator.pop(context, id);
          },
        ),
      ),
    );

    if (scannedId != null && scannedId is String) {
      setState(() {
        _studentIdController.text = scannedId;
      });
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
                    Expanded(
                      child: Text(
                        "Student ID '${_studentIdController.text.trim()}' is not found in your assigned scholars.",
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
              Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("â€¢ Student ID '${_studentIdController.text.trim()}' is assigned to your supervision"),
                    Text("â€¢ The student ID is correct and valid"),
                    Text("â€¢ The student is scheduled for the selected date"),
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

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.1),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  icon,
                  color: Colors.green,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  @override
  void dispose() {
    _studentIdController.dispose();
    _reasonController.dispose();
    _hoursInputController.dispose();
    _minutesInputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(50), // Set the height of the AppBar
        child: AppBar(
          backgroundColor:
              Colors.transparent, // Make the AppBar background transparent
          elevation: 0, // Remove the shadow of the AppBar
          flexibleSpace: Image.asset(
            'assets/images/coc_logo.png', // Path to your background image
            height: 50,
            width: 50, // Ensure the image covers the entire area
          ),
        ),
      ),
            drawer: AdvisorDrawer(
        advisorId: widget.advisor_id,
        supervisor_id: widget.supervisor_id,
        currentIndex: 3,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green.shade50, Colors.green.shade200],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.1),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.schedule,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Student Time Adjustment",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            "Add hours to student's time record",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Student ID Section
              _buildSectionCard(
                title: "Student Identification",
                icon: Icons.person,
                children: [
                  const Text(
                    "Student ID",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _studentIdController,
                    decoration: InputDecoration(
                      hintText: "Enter Scholar's Assign ID",
                      prefixIcon: const Icon(Icons.badge, color: Colors.green),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Colors.green, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: openScanner,
                      icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
                      label: const Text(
                        "Scan QR Code",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Reason Section
              _buildSectionCard(
                title: "Adjustment Reason",
                icon: Icons.note_alt,
                children: [
                  const Text(
                    "Reason for Adjustment",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _reasonController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: "e.g. Late sign-in, Special Duty, etc.",
                      prefixIcon: const Icon(Icons.edit_note, color: Colors.green),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Colors.green, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Time Adjustment Section
              _buildSectionCard(
                title: "Time Adjustment",
                icon: Icons.access_time,
                children: [
                  const Text(
                    "Add Hours",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _hoursInputController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: "Hours",
                            hintText: "0 or 1 only",
                            prefixIcon: const Icon(Icons.hourglass_empty, color: Colors.green),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Colors.green, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          onChanged: (value) {
                            if (value.isNotEmpty && value != '0' && value != '1') {
                              _hoursInputController.text = '';
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _minutesInputController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: "Minutes",
                            hintText: "0 to 59 only",
                            prefixIcon: const Icon(Icons.timer, color: Colors.green),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Colors.green, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          onChanged: (value) {
                            if (value.isNotEmpty) {
                              final numValue = int.tryParse(value);
                              if (numValue == null ||
                                  numValue < 0 ||
                                  numValue > 59) {
                                _minutesInputController.text = '';
                              }
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Date Selection Section
              _buildSectionCard(
                title: "Date Selection",
                icon: Icons.calendar_today,
                children: [
                  const Text(
                    "Exact Day to Adjust",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_month,
                          color: _selectedDate != null ? Colors.green : Colors.grey,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _selectedDate != null
                                ? DateFormat("MMMM dd, yyyy").format(_selectedDate!)
                                : "No date selected",
                            style: TextStyle(
                              fontSize: 16,
                              color: _selectedDate != null ? Colors.black87 : Colors.grey,
                              fontWeight: _selectedDate != null ? FontWeight.w500 : FontWeight.normal,
                            ),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _pickDate,
                          icon: const Icon(Icons.date_range, size: 18),
                          label: const Text("Select Date"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Submit Button
              _isLoading
                  ? Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.1),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Column(
                        children: [
                          CircularProgressIndicator(color: Colors.green),
                          SizedBox(height: 16),
                          Text(
                            "Processing adjustment...",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Container(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: submitAdjustment,
                        icon: const Icon(Icons.add_circle_outline, size: 24),
                        label: const Text(
                          "Add Time Adjustment",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 3,
                        ),
                      ),
                    ),
              
              const SizedBox(height: 16),
              
              // Message Display
              if (_message.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _message.contains("success") 
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _message.contains("success") 
                          ? Colors.green.withOpacity(0.3)
                          : Colors.red.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _message.contains("success") 
                            ? Icons.check_circle 
                            : Icons.error,
                        color: _message.contains("success") 
                            ? Colors.green 
                            : Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _message,
                          style: TextStyle(
                            color: _message.contains("success") 
                                ? Colors.green.shade700
                                : Colors.red.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Success"),
          content: const Text("Hours adjustment has been successfully submitted."),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }
}
