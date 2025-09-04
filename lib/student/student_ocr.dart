import 'package:csdl_mobile/student/student_drawer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import 'package:csdl_mobile/student/student_job_type.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

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

  @override
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
      drawer: StudentDrawer(student_id: widget.student_id),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green.shade50, Colors.green.shade200],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black87,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                ),
                icon: const Icon(Icons.assignment),
                label: const Text("SBO/WORKING Student Portal"),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          StudentJobType(student_id: widget.student_id),
                    ),
                  );
                },
              ),

              const SizedBox(height: 32),

              // File upload container
              Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.teal.shade800, width: 2),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey.shade100,
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.picture_as_pdf,
                          size: 48, color: Colors.teal),
                      const SizedBox(height: 16),
                      const Text(
                        "Upload your Official Registration Form (ORF) here to get a HK duty",
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _pickPDFText,
                        child: const Text("Choose a PDF File"),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Display extracted info
              if (studentNumber != null && schoolYear != null) ...[
                Text('Student Number: $studentNumber',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text('School Year: $schoolYear'),
                const SizedBox(height: 16),
              ],

              // Schedule table
              if (scheduleData.isNotEmpty)
                Expanded(
                  child: SingleChildScrollView(
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Day')),
                        DataColumn(label: Text('From')),
                        DataColumn(label: Text('To')),
                      ],
                      rows: _generateDataTableRows(),
                    ),
                  ),
                ),

              // Raw text fallback
              if (extractedText != null && scheduleData.isEmpty)
                Expanded(
                  child: SingleChildScrollView(
                    child: Text(extractedText!),
                  ),
                ),

              // Save button
              if (scheduleData.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.save),
                    label: const Text('Save Data'),
                    onPressed: _saveScheduleData,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 14),
                    ),
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
              DataCell(Text(day)),
              DataCell(Text(timeRange['from'] ?? '')),
              DataCell(Text(timeRange['to'] ?? '')),
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

      setState(() {
        studentNumber = extractedStudentNumber;
        schoolYear =
            'SY ${schoolYearMatch.group(1)} SEM ${schoolYearMatch.group(2)}';
      });

      print('Student Number: $studentNumber');
      print('School Year: $schoolYear');

      _extractVacantSchedule(text);
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
        var response = await http.post(
          Uri.parse('http://localhost/finalhk/api/transaction.php'),
          body: {
            'json': json.encode(jsonData),
            'operation': 'addScholarSchedule',
          },
        );

        String responseBody = response.body;
        String message =
            responseBody != "0" ? responseBody : 'Error saving data.';

        _showResultDialog(message);
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
}
