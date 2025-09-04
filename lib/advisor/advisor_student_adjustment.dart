import 'dart:convert';
import 'package:csdl_mobile/session_storage.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'advisor_qr_scanner.dart'; // import scanner
import 'package:intl/intl.dart';

class AdvisorStudentAdjustment extends StatefulWidget {
  final String advisor_id;
  const AdvisorStudentAdjustment({
    super.key,
    required this.advisor_id,
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

    final totalDeduction = hours + (minutes / 60);
    final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate!);

    try {
      var url = Uri.parse("${SessionStorage.url}transaction.php");

      Map<String, dynamic> jsonData = {
        "adj_student_id": _studentIdController.text.trim(),
        "adj_supervisor_id": widget.advisor_id,
        "adj_reason": _reasonController.text.trim(),
        "adj_hours": totalDeduction.toStringAsFixed(2),
        "adj_date": formattedDate,
      };

      Map<String, String> requestBody = {
        "operation": "addScholarHourDeduction",
        "json": jsonEncode(jsonData),
      };

      setState(() {
        _isLoading = true;
        _message = "";
      });

      var response = await http.post(url, body: requestBody);
      var res = jsonDecode(response.body);

      setState(() {
        _isLoading = false;
        _message = res["status"] == "success"
            ? "Hours deducted successfully."
            : "Failed to deduct. Please try again.";
      });

      if (res["status"] == "success") {
        _studentIdController.clear();
        _reasonController.clear();
        _hoursInputController.clear();
        _minutesInputController.clear();
        _selectedDate = null;
      }

      print("Response: $res");
    } catch (e) {
      print("Error submitting adjustment: $e");
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green.shade50, Colors.green.shade200],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              const Text("Student ID"),
              TextField(
                controller: _studentIdController,
                decoration: const InputDecoration(
                  hintText: "Enter Scholar's Assign ID",
                ),
              ),
              ElevatedButton.icon(
                onPressed: openScanner,
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text("Scan QR for ID"),
              ),
              const SizedBox(height: 16),
              const Text("Reason for Adjustment"),
              TextField(
                controller: _reasonController,
                decoration: const InputDecoration(
                  hintText: "e.g. Late sign-in, Special Duty, Etc.",
                ),
              ),
              const SizedBox(height: 16),
              const Text("Add Hours"),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _hoursInputController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Hours",
                        hintText: "0 or 1 only",
                      ),
                      onChanged: (value) {
                        if (value.isNotEmpty && value != '0' && value != '1') {
                          _hoursInputController.text = '';
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _minutesInputController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Minutes",
                        hintText: "0 to 59 only",
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
              const SizedBox(height: 16),
              const Text("Exact Day to Adjust"),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _selectedDate != null
                          ? DateFormat("yyyy-MM-dd").format(_selectedDate!)
                          : "No date selected",
                      style: TextStyle(
                        fontSize: 16,
                        color:
                            _selectedDate != null ? Colors.black : Colors.grey,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _pickDate,
                    child: const Text("Pick Date"),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                      onPressed: submitAdjustment,
                      icon: const Icon(Icons.remove_circle_outline),
                      label: const Text("Add Time"),
                    ),
              const SizedBox(height: 16),
              Text(
                _message,
                style: TextStyle(
                  color:
                      _message.contains("success") ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
