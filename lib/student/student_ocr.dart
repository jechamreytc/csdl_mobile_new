import 'package:csdl_mobile/student/student_drawer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import 'package:csdl_mobile/student/student_job_type.dart';
import 'package:csdl_mobile/student/student_dashboard.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:csdl_mobile/session_storage.dart';

class StudentOcr extends StatefulWidget {
  final String student_id;
  const StudentOcr({Key? key, required this.student_id}) : super(key: key);
  @override
  _StudentOcrState createState() => _StudentOcrState();
}

class _StudentOcrState extends State<StudentOcr> {
  String? extractedText;
  Map<String, List<Map<String, String>>> scheduleData = {};
  String? studentNumber;
  String? schoolYear;
  bool hasExistingOcr = false;
  bool requiresApproval = false;
  Map<String, dynamic>? ocrRequestStatus;
  bool isLoadingEligibility = false;
  
  // Cross-system validation variables
  int? jobTypeStatus;
  bool canUploadOcr = true;

  @override
  void initState() {
    super.initState();
    _checkOcrEligibility();
    _checkJobTypeStatus(); // Check job type status for cross-validation
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
      drawer: StudentDrawer(student_id: widget.student_id, currentIndex: 2),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green.shade50, Colors.green.shade200],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade50, Colors.blue.shade100],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.blue.shade200, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          "Document Upload & Status",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Upload your Official Registration Form (ORF) to get your HK duty schedule. This document helps us assign you the right duty hours.",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue.shade600,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // OCR Status Section
              if (isLoadingEligibility) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.blue.shade200, width: 1),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Colors.blue.shade600),
                      const SizedBox(width: 16),
                      Text(
                        "Checking OCR eligibility...",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (hasExistingOcr) ...[
                // Existing OCR Status
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.orange.shade50, Colors.orange.shade100],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.orange.shade300, width: 2),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.warning, size: 32, color: Colors.orange.shade700),
                          const SizedBox(width: 8),
                          Text(
                            "OCR Schedule Exists",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "You already have an existing OCR schedule. To upload a new one, you need admin approval.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.orange.shade600,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (ocrRequestStatus != null) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.orange.shade200, width: 1),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    ocrRequestStatus!['ocr_request_status'] == 'Approved' 
                                        ? Icons.check_circle 
                                        : ocrRequestStatus!['ocr_request_status'] == 'Declined'
                                            ? Icons.cancel
                                            : ocrRequestStatus!['ocr_request_status'] == 'Completed'
                                                ? Icons.task_alt
                                                : Icons.pending,
                                    color: ocrRequestStatus!['ocr_request_status'] == 'Approved' 
                                        ? Colors.green 
                                        : ocrRequestStatus!['ocr_request_status'] == 'Declined'
                                            ? Colors.red
                                            : ocrRequestStatus!['ocr_request_status'] == 'Completed'
                                                ? Colors.blue
                                                : Colors.orange,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Request Status: ${ocrRequestStatus!['ocr_request_status']}",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: ocrRequestStatus!['ocr_request_status'] == 'Approved' 
                                          ? Colors.green 
                                          : ocrRequestStatus!['ocr_request_status'] == 'Declined'
                                              ? Colors.red
                                              : ocrRequestStatus!['ocr_request_status'] == 'Completed'
                                                  ? Colors.blue
                                                  : Colors.orange,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (ocrRequestStatus != null && ocrRequestStatus!['ocr_request_status'] == 'Pending') ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.orange.shade300),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.hourglass_empty, color: Colors.orange.shade600),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Request Pending",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange.shade800,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Your OCR upload request is pending admin approval. Please wait for the decision.",
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.orange.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else if (ocrRequestStatus != null && ocrRequestStatus!['ocr_request_status'] == 'Approved') ...[
                        ElevatedButton.icon(
                          icon: const Icon(Icons.upload_file),
                          label: const Text('Upload PDF'),
                          onPressed: _pickPDFText,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ] else if (ocrRequestStatus != null && ocrRequestStatus!['ocr_request_status'] == 'Completed') ...[
                        // Show Request button for completed requests
                        ElevatedButton.icon(
                          icon: const Icon(Icons.request_page),
                          label: const Text('Request OCR Upload'),
                          onPressed: _createOcrRequest,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ] else ...[
                        // Show Request button when no request or declined
                        ElevatedButton.icon(
                          icon: const Icon(Icons.request_page),
                          label: const Text('Request OCR Upload'),
                          onPressed: _createOcrRequest,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ] else ...[
                // Normal ORF Upload Section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.teal.shade50, Colors.teal.shade100],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.teal.shade300, width: 2),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.picture_as_pdf, size: 32, color: Colors.teal.shade700),
                          const SizedBox(width: 8),
                          Text(
                            "ORF Upload",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Upload your Official Registration Form (ORF) to get your duty schedule",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.teal.shade600,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 20),
                      GestureDetector(
                        onTap: _pickPDFText,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.teal.shade200, width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.upload_file, color: Colors.teal.shade600),
                              const SizedBox(width: 8),
                              Text(
                                "Choose PDF File",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.teal.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Supported format: PDF only",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.teal.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],



              // Raw text fallback
              if (extractedText != null && scheduleData.isEmpty) ...[
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.red.shade200, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning, color: Colors.red.shade600, size: 24),
                          const SizedBox(width: 8),
                          Text(
                            "Schedule Not Found",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "We couldn't extract your schedule from the document. Please check if your ORF contains the correct schedule information.",
                        style: TextStyle(
                          color: Colors.red.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],


              // SBO/Working Student Portal Section (moved to bottom)
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.grey.shade300, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.work_outline, color: Colors.grey.shade700, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          "Job Type Selection",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Click the button below if you are a SBO or Working Student, please select your job type and you dont have to required on hk duty schedule.",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black87,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.assignment),
                      label: const Text("SBO/Working Student Portal"),
                      onPressed: () {
                        _checkJobTypeAccess();
                      },
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.shade200, width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info, color: Colors.amber.shade700, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                "Important Remarks:",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "â€¢ SBO (Student Body Organization): For students involved in student government and campus leadership activities\nâ€¢ Working Student: For students have woks outside and inside the campus ",
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.amber.shade600,
                              height: 1.3,
                            ),
                          ),
                        ],
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

  List<DataRow> _generateDataTableRows() {
    List<DataRow> rows = [];

    scheduleData.forEach((day, timeRanges) {
      for (var timeRange in timeRanges) {
        rows.add(
          DataRow(
            cells: [
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  child: Text(
                    day,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.blue.shade700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  child: Text(
                    timeRange['from'] ?? '',
                    style: TextStyle(
                      color: Colors.blue.shade600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  child: Text(
                    timeRange['to'] ?? '',
                    style: TextStyle(
                      color: Colors.blue.shade600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }
    });

    return rows;
  }

  Future<void> _pickPDFText() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      Uint8List? fileBytes = result.files.first.bytes;
      if (fileBytes != null) {
        try {
          PdfDocument document = PdfDocument(inputBytes: fileBytes);
          String text = PdfTextExtractor(document).extractText();
          document.dispose();

          setState(() {
            extractedText = text;
          });

          _extractStudentInfo(text);
        } catch (e) {
          print('Error extracting text: $e');
        }
      } else {
        print('No file bytes available');
      }
    } else {
      print('User canceled the picker');
    }
  }

  void _extractStudentInfo(String text) {
    final studentNumberRegex = RegExp(r'(\d{2}-\d{4}-\d{5,10})');
    final schoolYearRegex = RegExp(r'SY (\d{2}-\d{2}) SEM (I{1,2})');

    final studentNumberMatch = studentNumberRegex.firstMatch(text);
    final schoolYearMatch = schoolYearRegex.firstMatch(text);

    if (studentNumberMatch != null && schoolYearMatch != null) {
      String extractedStudentNumber = studentNumberMatch.group(1)!;
      String extractedSchoolYear = 'SY ${schoolYearMatch.group(1)} SEM ${schoolYearMatch.group(2)}';

      if (extractedStudentNumber != widget.student_id) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text("Student Mismatch"),
            content: Text(
                "The student number in the PDF does not match your account."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  setState(() {
                    studentNumber = null;
                    schoolYear = null;
                    extractedText = null;
                    scheduleData.clear();
                  });
                },
                child: Text("OK"),
              ),
            ],
          ),
        );
        return; // stop here
      }

      // Validate academic session
      _validateAcademicSession(extractedSchoolYear, extractedStudentNumber, text);
    } else {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text("Invalid File"),
          content: Text("Student number or academic session not found."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  studentNumber = null;
                  schoolYear = null;
                  extractedText = null;
                  scheduleData.clear();
                });
              },
              child: Text("OK"),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _validateAcademicSession(String extractedSchoolYear, String extractedStudentNumber, String text) async {
    try {
      var url = Uri.parse("${SessionStorage.url}transaction.php");
      var response = await http.post(
        url,
        body: {
          'json': json.encode({}),
          'operation': 'getCurrentAcademicSession',
        },
      );

      print('ðŸ” Academic Session Validation:');
      print('ðŸ“Š PDF Academic Session: $extractedSchoolYear');
      print('ðŸ“¡ Response Code: ${response.statusCode}');
      print('ðŸ“¡ Response Body: ${response.body}');

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        print('ðŸ“Š Current Academic Session Data: $data');
        
        if (data['success'] == true) {
          String currentSessionName = data['session']['session_name'];
          print('ðŸ“‹ Current Active Session: $currentSessionName');
          print('ðŸ“‹ PDF Session: $extractedSchoolYear');
          
          if (extractedSchoolYear == currentSessionName) {
            print('âœ… Academic Session Match - Proceeding with upload');
            setState(() {
              studentNumber = extractedStudentNumber;
              schoolYear = extractedSchoolYear;
            });
            print('Student Number: $studentNumber');
            print('School Year: $schoolYear');
            _extractVacantSchedule(text);
          } else {
            print('âŒ Academic Session Mismatch - Showing alert');
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: Text("Academic Session Mismatch"),
                content: Text(
                    "The academic session in the PDF ($extractedSchoolYear) does not match the current active academic session ($currentSessionName). Please upload an ORF from the current academic session."),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      setState(() {
                        studentNumber = null;
                        schoolYear = null;
                        extractedText = null;
                        scheduleData.clear();
                      });
                    },
                    child: Text("OK"),
                  ),
                ],
              ),
            );
          }
        } else {
          print('âŒ Failed to get current academic session: ${data['error']}');
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: Text("Session Validation Error"),
              content: Text("Unable to validate academic session. Please try again."),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    setState(() {
                      studentNumber = null;
                      schoolYear = null;
                      extractedText = null;
                      scheduleData.clear();
                    });
                  },
                  child: Text("OK"),
                ),
              ],
            ),
          );
        }
      } else {
        print('âŒ Server error: ${response.statusCode}');
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text("Server Error"),
            content: Text("Unable to validate academic session. Please try again."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  setState(() {
                    studentNumber = null;
                    schoolYear = null;
                    extractedText = null;
                    scheduleData.clear();
                  });
                },
                child: Text("OK"),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      print('âŒ Error validating academic session: $e');
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text("Validation Error"),
          content: Text("Network error occurred while validating academic session."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  studentNumber = null;
                  schoolYear = null;
                  extractedText = null;
                  scheduleData.clear();
                });
              },
              child: Text("OK"),
            ),
          ],
        ),
      );
    }
  }

  void _extractVacantSchedule(String text) {
    List<String> daysOfWeek = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    final regex = RegExp(
      r'(\d{1,2}:\d{2} [APM]{2}-\d{1,2}:\d{2} [APM]{2})((Mon|Tue|Wed|Thu|Fri|Sat|Sun)(?:\/(Mon|Tue|Wed|Thu|Fri|Sat|Sun))*)',
      multiLine: true,
    );

    Map<String, List<String>> unavailableTimes = {};

    for (var match in regex.allMatches(text)) {
      String time = match.group(1) ?? '';
      String days = match.group(2) ?? '';

      if (time.isNotEmpty && days.isNotEmpty) {
        List<String> dayList = days.split('/');
        for (String day in dayList) {
          day = day.trim();
          if (daysOfWeek.contains(day)) {
            unavailableTimes.putIfAbsent(day, () => []).add(time);
          }
        }
      }
    }

    Map<String, List<Map<String, String>>> availableTimes = {};

    for (String day in daysOfWeek) {
      List<String> dayUnavailableTimes = unavailableTimes[day] ?? [];
      if (dayUnavailableTimes.isEmpty) {
        availableTimes[day] = [
          {'from': '7:30 AM', 'to': '9:00 PM'}
        ];
      } else {
        List<String> availableDayTimes =
            _getAvailableTimes(dayUnavailableTimes);
        availableTimes[day] = availableDayTimes.map((time) {
          List<String> splitTime = time.split(' - ');
          return {'from': splitTime[0], 'to': splitTime[1]};
        }).toList();
      }
    }

    setState(() {
      scheduleData = availableTimes;
    });
    
    // Automatically show schedule dialog after extraction
    if (availableTimes.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _showScheduleDialog();
        }
      });
    }
  }

  void _showScheduleDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.schedule, color: Colors.blue.shade600),
              const SizedBox(width: 8),
              Text(
                "Your Available Schedule",
                style: TextStyle(
                  color: Colors.blue.shade800,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Container(
            width: double.maxFinite,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.6,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Document Information
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade200, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green.shade600, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              "Document Information",
                              style: TextStyle(
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.shade100, width: 1),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.person, color: Colors.green.shade600, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Student Number: $studentNumber',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: Colors.green.shade700,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.calendar_today, color: Colors.green.shade600, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    'School Year: $schoolYear',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: Colors.green.shade700,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Success message
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200, width: 1),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.schedule, color: Colors.blue.shade600, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Schedule extracted successfully!",
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Schedule table
                  DataTable(
                    columnSpacing: 20,
                    horizontalMargin: 16,
                    columns: [
                      DataColumn(
                        label: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'Day',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'From',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'To',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                    rows: _generateDataTableRows(),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                "Close",
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.save, size: 18),
              label: const Text('Save Schedule'),
              onPressed: () {
                Navigator.of(context).pop();
                _saveScheduleData();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  List<String> _getAvailableTimes(List<String> unavailableTimes) {
    List<Map<String, DateTime>> intervals = [];

    for (String range in unavailableTimes) {
      List<String> parts = range.split('-');
      if (parts.length == 2) {
        DateTime start = _parseTime(parts[0].trim());
        DateTime end = _parseTime(parts[1].trim());
        if (end.isAfter(start)) {
          intervals.add({'start': start, 'end': end});
        }
      }
    }

    intervals.sort((a, b) => a['start']!.compareTo(b['start']!));

    List<Map<String, DateTime>> merged = [];
    for (var current in intervals) {
      if (merged.isEmpty) {
        merged.add(current);
      } else {
        var last = merged.last;
        if (current['start']!.isBefore(last['end']!) ||
            current['start']!.isAtSameMomentAs(last['end']!)) {
          last['end'] = current['end']!.isAfter(last['end']!)
              ? current['end']!
              : last['end']!;
        } else {
          merged.add(current);
        }
      }
    }

    List<String> available = [];
    DateTime dayStart = _parseTime('7:30 AM');
    DateTime dayEnd = _parseTime('9:00 PM');

    DateTime current = dayStart;
    for (var busy in merged) {
      if (current.isBefore(busy['start']!)) {
        available
            .add('${_formatTime(current)} - ${_formatTime(busy['start']!)}');
      }
      current = busy['end']!.isAfter(current) ? busy['end']! : current;
    }

    if (current.isBefore(dayEnd)) {
      available.add('${_formatTime(current)} - ${_formatTime(dayEnd)}');
    }

    final Set<String> seen = {};
    return available.where((slot) => seen.add(slot)).toList();
  }

  String _formatTime(DateTime time) {
    int hour = time.hour;
    String period = hour >= 12 ? 'PM' : 'AM';
    hour = hour > 12
        ? hour - 12
        : hour == 0
            ? 12
            : hour;
    return '${hour}:${time.minute.toString().padLeft(2, '0')} $period';
  }

  DateTime _parseTime(String time) {
    final match = RegExp(r'(\d{1,2}):(\d{2}) (AM|PM)').firstMatch(time);
    if (match != null) {
      int hour = int.parse(match.group(1)!);
      int minute = int.parse(match.group(2)!);
      String period = match.group(3)!;
      if (period == 'PM' && hour != 12) hour += 12;
      if (period == 'AM' && hour == 12) hour = 0;
      return DateTime(2025, 1, 1, hour, minute);
    } else {
      throw FormatException("Invalid time format");
    }
  }

  Future<void> _saveScheduleData() async {
    if (studentNumber != null &&
        schoolYear != null &&
        scheduleData.isNotEmpty) {
      List<Map<String, dynamic>> ocrData = [];

      scheduleData.forEach((day, timeRanges) {
        for (var timeRange in timeRanges) {
          ocrData.add({
            'ocr_studActive_id': studentNumber,
            'ocr_academic_session_id': schoolYear,
            'ocr_day': day,
            'ocr_schedule_time_from': timeRange['from'],
            'ocr_schedule_time_to': timeRange['to'],
          });
        }
      });

      Map<String, dynamic> jsonData = {'ocr': ocrData};
      print("jsonData: $jsonData");

      try {
        var url = Uri.parse("${SessionStorage.url}transaction.php");
        var response = await http.post(
          url,
          body: {
            'json': json.encode(jsonData),
            'operation': 'addScholarSchedule',
          },
        );

        if (response.statusCode == 200) {
          String responseBody = response.body;
          String message =
              responseBody != "0" ? responseBody : 'Error saving data.';

          // If upload was successful and we have an approved request, mark it as completed
          if (responseBody != "0" && ocrRequestStatus != null && ocrRequestStatus!['ocr_request_status'] == 'Approved') {
            _markOcrRequestAsCompleted();
          }

          _showResultDialog(message);
        } else {
          _showResultDialog('Server error: ${response.statusCode}');
        }
      } catch (e) {
        print('Error saving schedule data: $e');
        _showResultDialog('Network error occurred.');
      }
    } else {
      _showResultDialog('Please ensure all fields are filled out.');
    }
  }

  void _showResultDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Result"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                studentNumber = null;
                schoolYear = null;
                extractedText = null;
                scheduleData.clear();
              });
            },
            child: Text("OK"),
          ),
        ],
      ),
    );
  }

  Future<void> _checkOcrEligibility() async {
    print('ðŸ” Checking OCR Eligibility...');
    setState(() {
      isLoadingEligibility = true;
    });

    try {
      var url = Uri.parse("${SessionStorage.url}transaction.php");
      var response = await http.post(
        url,
        body: {
          'json': json.encode({"stud_active_id": widget.student_id}),
          'operation': 'checkOcrEligibility',
        },
      );

      print('ðŸ“¡ OCR Eligibility Response Code: ${response.statusCode}');
      print('ðŸ“¡ OCR Eligibility Response: ${response.body}');

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        print('ðŸ“Š Parsed OCR Eligibility Data: $data');
        
        if (data['success'] == true) {
          print('âœ… OCR Eligibility Check Success');
          print('ðŸ“‹ Has Existing OCR: ${data['has_existing_ocr']}');
          print('ðŸ“‹ Requires Approval: ${data['requires_approval']}');
          
          setState(() {
            hasExistingOcr = data['has_existing_ocr'];
            requiresApproval = data['requires_approval'];
          });
          
          if (hasExistingOcr) {
            print('ðŸ“‹ Existing OCR found - checking request status');
            await _checkOcrRequestStatus();
            // Show appropriate blocking alert based on request status
            WidgetsBinding.instance.addPostFrameCallback((_) {
              print('ðŸš¨ Showing blocking alert based on request status');
              _showOcrAccessAlert();
            });
          } else {
            print('ðŸ“‹ No existing OCR - user can upload directly');
          }
        } else {
          print('âŒ OCR Eligibility Check Failed: ${data['error']}');
        }
      }
    } catch (e) {
      print('âŒ Error checking OCR eligibility: $e');
    } finally {
      setState(() {
        isLoadingEligibility = false;
      });
    }
  }

  /// Check job type status for cross-system validation
  Future<void> _checkJobTypeStatus() async {
    try {
      final url = Uri.parse("${SessionStorage.url}transaction.php");
      final response = await http.post(
        url,
        body: {
          'operation': 'getJobType',
          'json': jsonEncode({"job_stud_id": widget.student_id}),
        },
      );

      print("ðŸ” Job Type Status Check for OCR:");
      print("ðŸ“Š Response: ${response.body}");

      final data = jsonDecode(response.body);
      
      // Handle both List and Map responses
      var existingData;
      if (data != null && data is List && data.isNotEmpty) {
        existingData = data.first;
        print("ðŸ“‹ Found job type data in List format");
      } else if (data != null && data is Map && data.isNotEmpty) {
        existingData = data;
        print("ðŸ“‹ Found job type data in Map format");
      } else {
        existingData = null;
        print("ðŸ“‹ No job type data found");
      }
      
      if (existingData != null) {
        int status = int.tryParse(existingData['job_status']?.toString() ?? '0') ?? 0;
        print("ðŸ“Š Job Type Status: $status");
        
        setState(() {
          jobTypeStatus = status;
          // Block OCR upload if job type is pending (0) or approved (1), but allow if declined (2)
          canUploadOcr = !(status == 0 || status == 1);
        });
        
        // Show job type alerts immediately when OCR page loads
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (status == 0) {
            print('ðŸš¨ JOB TYPE BLOCKING: Pending status - show alert on OCR page load');
            _showJobTypePendingAlert();
          } else if (status == 1) {
            print('ðŸš¨ JOB TYPE BLOCKING: Approved status - show alert on OCR page load');
            _showJobTypeApprovedAlert();
          } else if (status == 2) {
            print('ðŸ“‹ JOB TYPE DECLINED: Show remarks notification but allow access');
            _showJobTypeDeclinedNotification();
          }
        });
      } else {
        setState(() {
          jobTypeStatus = -1; // no job type upload
          canUploadOcr = true;
        });
      }
    } catch (e) {
      print('âŒ Error checking job type status: $e');
      setState(() {
        jobTypeStatus = -1;
        canUploadOcr = true;
      });
    }
  }

  /// Show alert when job type status blocks OCR upload
  void _showJobTypeBlockingAlert(int status) {
    String title = status == 0 ? "Job Type Upload Pending" : status == 1 ? "Job Type Upload Approved" : "Job Type Upload Declined";
    String message = status == 0 
        ? "You have a pending job type upload. Please wait for admin approval before uploading OCR."
        : status == 1
            ? "Your job type upload has been approved. You cannot upload OCR until the next session."
            : "Your job type upload was declined. You cannot upload OCR until the next session.";
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StudentDashboard(student_id: widget.student_id),
                  ),
                );
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }


  /// Show alert dialog with request button when existing data is found
  void _showExistingDataAlert() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Existing Data Found"),
          content: const Text("You have existing OCR or job type data. Please use the request button below to request a new upload."),
          actions: [
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.of(context).pop();
                await _createOcrRequest();
              },
              icon: const Icon(Icons.request_page),
              label: const Text('Request OCR Upload'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade600,
                foregroundColor: Colors.white,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StudentDashboard(student_id: widget.student_id),
                  ),
                );
              },
              child: const Text("Go to Dashboard"),
            ),
          ],
        );
      },
    );
  }

  /// Show OCR access alert based on request status and job type status
  void _showOcrAccessAlert() {
    print('ðŸ” OCR Access Alert Check:');
    print('ðŸ“Š OCR Request Status: $ocrRequestStatus');
    print('ðŸ“Š Job Type Status: $jobTypeStatus');
    
    // Check for job type blocking first
    if (jobTypeStatus != null && jobTypeStatus != -1) {
      if (jobTypeStatus == 0) {
        print('ðŸš¨ JOB TYPE BLOCKING: Pending status');
        _showJobTypePendingAlert();
        return;
      } else if (jobTypeStatus == 1) {
        print('ðŸš¨ JOB TYPE BLOCKING: Approved status');
        _showJobTypeApprovedAlert();
        return;
      } else if (jobTypeStatus == 2) {
        print('ðŸ“‹ JOB TYPE DECLINED: Show remarks notification');
        _showJobTypeDeclinedAlert();
        // Continue to OCR checks after showing declined notification
      }
    }
    
    // Check OCR request status
    if (ocrRequestStatus != null) {
      String status = ocrRequestStatus!['ocr_request_status'] ?? '';
      print('ðŸ“‹ Request Status: $status');
      
      if (status.toLowerCase() == 'pending') {
        print('â³ Pending request - showing blocking alert dialog');
        print('ðŸš¨ BLOCKING: User cannot access OCR module until approved');
        // Show blocking alert dialog for pending requests
        _showPendingRequestAlert();
        return;
      } else if (status.toLowerCase() == 'approved') {
        print('âœ… Approved request - allowing upload access');
        print('ðŸŽ¯ UNBLOCKED: User can now upload ORF');
        // Allow access for approved requests - user can upload
        return;
      } else if (status.toLowerCase() == 'completed') {
        print('ðŸ”„ Completed request - showing request button for new request');
        print('ðŸš¨ BLOCKING: User needs to submit new request');
        // Show request alert for completed requests
        _showExistingOcrAlert();
        return;
      } else if (status.toLowerCase() == 'declined') {
        print('âŒ Declined request - showing request button for new request');
        print('ðŸš¨ BLOCKING: User needs to submit new request');
        // Show request alert for declined requests
        _showExistingOcrAlert();
        return;
      }
    }
    
    print('ðŸ“‹ No request status - showing OCR Schedule Exists alert');
    print('ðŸš¨ BLOCKING: User needs to submit request first');
    // Show "OCR Schedule Exists" alert if there's no request at all
    _showExistingOcrAlert();
  }

  /// Show alert for existing OCR data with request option
  void _showExistingOcrAlert() {
    print('ðŸš¨ Showing OCR Schedule Exists blocking alert');
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("OCR Schedule Exists"),
          content: const Text("You already have an existing OCR schedule. To upload a new one, you need admin approval."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StudentDashboard(student_id: widget.student_id),
                  ),
                );
              },
              child: const Text("Back"),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                _showRequestFormAlert();
              },
              icon: const Icon(Icons.request_page),
              label: const Text('Request'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade600,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  /// Show pending request alert
  void _showPendingRequestAlert() {
    print('ðŸš¨ Showing Request Pending blocking alert');
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Request Pending"),
          content: const Text("Your OCR upload request is pending admin approval. You cannot upload documents until your request is approved."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StudentDashboard(student_id: widget.student_id),
                  ),
                );
              },
              child: const Text("Go to Dashboard"),
            ),
          ],
        );
      },
    );
  }

  /// Show job type pending alert
  void _showJobTypePendingAlert() {
    print('ðŸš¨ Showing Job Type Pending blocking alert');
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Upload Pending"),
          content: const Text("You already have a pending upload. Please wait for admin approval before uploading again."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StudentDashboard(student_id: widget.student_id),
                  ),
                );
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  /// Show job type approved alert
  void _showJobTypeApprovedAlert() {
    print('ðŸš¨ Showing Job Type Approved blocking alert');
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Upload Approved"),
          content: const Text("Your upload has been approved. No further uploads are needed."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StudentDashboard(student_id: widget.student_id),
                  ),
                );
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  /// Show job type declined alert with remarks
  void _showJobTypeDeclinedAlert() {
    print('ðŸ“‹ Showing Job Type Declined notification with remarks');
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Job Type Declined"),
          content: const Text("Your job type upload was declined by admin. You can see the reason below and upload a new job type if needed."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StudentDashboard(student_id: widget.student_id),
                  ),
                );
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  /// Show job type declined notification (non-blocking)
  void _showJobTypeDeclinedNotification() {
    print('ðŸ“‹ Showing Job Type Declined notification (non-blocking)');
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Job Type Declined"),
          content: const Text("Your previous job type upload was declined by admin. You can upload a new job type with the required changes."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Don't navigate to dashboard - allow user to continue
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  /// Check job type access and show appropriate alerts
  void _checkJobTypeAccess() {
    print('ðŸ” Checking Job Type Access...');
    print('ðŸ“Š Job Type Status: $jobTypeStatus');
    
    if (jobTypeStatus != null && jobTypeStatus != -1) {
      if (jobTypeStatus == 0) {
        print('ðŸš¨ JOB TYPE BLOCKING: Pending status - show alert in OCR module');
        _showJobTypePendingAlert();
        return;
      } else if (jobTypeStatus == 1) {
        print('ðŸš¨ JOB TYPE BLOCKING: Approved status - show alert in OCR module');
        _showJobTypeApprovedAlert();
        return;
      } else if (jobTypeStatus == 2) {
        print('ðŸ“‹ JOB TYPE DECLINED: Show remarks notification but allow access');
        _showJobTypeDeclinedNotification();
        // Allow access to job type page after showing notification
        Future.delayed(const Duration(milliseconds: 500), () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StudentJobType(student_id: widget.student_id),
            ),
          );
        });
        return;
      }
    }
    
    print('âœ… No job type restrictions - allowing access to job type');
    // No job type restrictions, allow access
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StudentJobType(student_id: widget.student_id),
      ),
    );
  }

  /// Show request form in alert dialog
  void _showRequestFormAlert() {
    final reasonController = TextEditingController();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("OCR Upload Request"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Please provide a reason for your OCR upload request:"),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  hintText: "Enter reason for request...",
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StudentDashboard(student_id: widget.student_id),
                  ),
                );
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _submitOcrRequest(reasonController.text.isNotEmpty 
                    ? reasonController.text 
                    : "Request to update OCR schedule");
                
                // Navigate to drawer after submission
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StudentDashboard(student_id: widget.student_id),
                  ),
                );
              },
              child: const Text("Submit Request"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _checkOcrRequestStatus() async {
    print('ðŸ” Checking OCR Request Status...');
    try {
      var url = Uri.parse("${SessionStorage.url}transaction.php");
      var response = await http.post(
        url,
        body: {
          'json': json.encode({"stud_active_id": widget.student_id}),
          'operation': 'getOcrRequestStatus',
        },
      );

      print('ðŸ“¡ OCR Request Status Response Code: ${response.statusCode}');
      print('ðŸ“¡ OCR Request Status Response: ${response.body}');

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        print('ðŸ“Š Parsed OCR Request Data: $data');
        
        if (data['success'] == true) {
          print('âœ… OCR Request Status Found: ${data['request']}');
          setState(() {
            ocrRequestStatus = data['request'];
          });
          
          // Don't show blocking alerts - let user see the request button
          // The request status will be displayed in the UI instead
        } else {
          print('âŒ OCR Request Status Failed: ${data['error']}');
        }
      }
    } catch (e) {
      print('âŒ Error checking OCR request status: $e');
    }
  }

  /// Show alert based on OCR request status
  void _showRequestStatusAlert(String status) {
    String title = '';
    String message = '';
    bool canProceed = false;
    
    switch (status.toLowerCase()) {
      case 'pending':
        title = "Request Pending";
        message = "Your OCR upload request is pending admin approval. Please wait for the decision.";
        canProceed = false;
        break;
      case 'approved':
        title = "Request Approved";
        message = "Your OCR upload request has been approved. You can now upload your documents.";
        canProceed = true;
        break;
      case 'declined':
        title = "Request Declined";
        message = "Your OCR upload request was declined. You can submit a new request.";
        canProceed = true;
        break;
      case 'completed':
        title = "Request Completed";
        message = "Your OCR upload request has been completed. You can submit a new request if needed.";
        canProceed = true;
        break;
      default:
        title = "Request Status Unknown";
        message = "Unable to determine your request status. Please contact support.";
        canProceed = false;
    }
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            if (canProceed) ...[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Allow user to proceed with upload or new request
                },
                child: const Text("Continue"),
              ),
            ],
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StudentDashboard(student_id: widget.student_id),
                  ),
                );
              },
              child: const Text("Go to Dashboard"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _createOcrRequest() async {
    final reasonController = TextEditingController();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("OCR Upload Request"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Please provide a reason for your OCR upload request:"),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  hintText: "Enter reason for request...",
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _submitOcrRequest(reasonController.text.isNotEmpty 
                    ? reasonController.text 
                    : "Request to update OCR schedule");
              },
              child: const Text("Submit Request"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitOcrRequest(String reason) async {
    try {
      var url = Uri.parse("${SessionStorage.url}transaction.php");
      var response = await http.post(
        url,
        body: {
          'json': json.encode({
            "stud_active_id": widget.student_id,
            "reason": reason.isNotEmpty ? reason : "Request to update OCR schedule"
          }),
          'operation': 'createOcrRequest',
        },
      );

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        if (data['success'] == true) {
          // Update the request status to pending immediately
          setState(() {
            ocrRequestStatus = {
              'ocr_request_id': data['request_id'] ?? '',
              'ocr_request_status': 'Pending',
              'ocr_request_reason': reason,
              'ocr_request_date': DateTime.now().toIso8601String(),
            };
          });
          
          _showResultDialog(data['message']);
          _checkOcrRequestStatus(); // Refresh request status from server
        } else {
          _showResultDialog(data['error'] ?? 'Failed to submit request');
        }
      }
    } catch (e) {
      print('Error submitting OCR request: $e');
      _showResultDialog('Network error occurred.');
    }
  }

  Future<void> _markOcrRequestAsCompleted() async {
    try {
      var url = Uri.parse("${SessionStorage.url}transaction.php");
      var response = await http.post(
        url,
        body: {
          'json': json.encode({
            "request_id": ocrRequestStatus!['ocr_request_id']
          }),
          'operation': 'completeOcrRequest',
        },
      );

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        if (data['success'] == true) {
          // Refresh the request status
          _checkOcrRequestStatus();
        }
      }
    } catch (e) {
      print('Error marking OCR request as completed: $e');
    }
  }
}
