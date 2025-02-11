import 'dart:convert';
import 'package:csdl_mobile/session_storage.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class StudentDtr extends StatefulWidget {
  final String student_id;
  const StudentDtr({
    super.key,
    required this.student_id,
  });

  @override
  _StudentDtrState createState() => _StudentDtrState();
}

class _StudentDtrState extends State<StudentDtr> {
  String formatDutyTime(String dutyHTime) {
    if (dutyHTime == 'N/A') return 'N/A';

    List<String> timeParts = dutyHTime.split(':');
    if (timeParts.length != 3) return 'Invalid time';

    int hours = int.parse(timeParts[0]);
    int minutes = int.parse(timeParts[1]);

    String hoursText = hours > 0 ? '$hours hour${hours > 1 ? 's' : ''}' : '';
    String minutesText =
        minutes > 0 ? '$minutes Minute${minutes > 1 ? 's' : ''}' : '';

    return [hoursText, minutesText]
        .where((part) => part.isNotEmpty)
        .join(' : ');
  }

  List<dynamic> studentDtr = [];
  int duty_hours = 0;

  @override
  void initState() {
    super.initState();
    getStudentDtr();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade800, // Green background
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0), // Padding around the screen
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start, // Aligns children to the start (left)
          children: [
            // Card for School Year
            _buildCard(
              'School Year: ${studentDtr.isNotEmpty ? studentDtr[0]['dtr_school_year'] : 'N/A'}',
            ),
            // Card for Semester
            _buildCard(
              'Semester: ${studentDtr.isNotEmpty ? studentDtr[0]['dtr_semester'] : 'N/A'}',
            ),
            // Create Data Table
            createDatatable(),
          ],
        ),
      ),
    );
  }

  // Create a reusable card widget with content
  Widget _buildCard(String content) {
    return Card(
      margin:
          const EdgeInsets.symmetric(vertical: 10.0), // Margin around the card
      color: Colors.white, // Card background color
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12), // Rounded corners for the card
      ),
      elevation: 5, // Elevation for shadow effect
      child: Padding(
        padding: const EdgeInsets.all(16.0), // Padding inside the card
        child: Text(
          content,
          style: const TextStyle(
            fontSize: 18, // Font size for the text
            color: Colors.green, // Text color is green
            fontWeight: FontWeight.bold, // Bold text
          ),
        ),
      ),
    );
  }

  // Create a DataTable inside a Card
  Widget createDatatable() {
    return Card(
      margin: const EdgeInsets.all(10.0), // Margin around the card
      color: Colors.white, // Card color
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12), // Rounded corners
      ),
      elevation: 5, // Elevation for shadow effect
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal, // Enable horizontal scrolling
        child: DataTable(
          columns: _columns(),
          rows: _rows(),
          headingTextStyle: const TextStyle(
            color: Colors.green, // Green header text
            fontWeight: FontWeight.bold, // Bold header text
          ),
          dataTextStyle: const TextStyle(
            color: Colors.black, // Black text for data cells
          ),
        ),
      ),
    );
  }

  // Define the columns of the DataTable
  List<DataColumn> _columns() {
    return const [
      DataColumn(label: Text("Date")),
      DataColumn(label: Text("Time In")),
      DataColumn(label: Text("Time Out")),
      DataColumn(label: Text("Time Rendered (Hours)")),
    ];
  }

  // Define the rows of the DataTable
  List<DataRow> _rows() {
    return studentDtr.map((data) {
      String formattedTime = formatDutyTime(data['TotalRendered'] ?? 'N/A');

      return DataRow(
        cells: [
          DataCell(Text(data['dtr_date'] ?? 'N/A')),
          DataCell(Text(data['dtr_time_in'] ?? 'N/A')),
          DataCell(Text(data['dtr_time_out'] ?? 'N/A')),
          DataCell(Text(formattedTime)), // Displays formatted time
        ],
      );
    }).toList();
  }

  // Fetch student DTR data from API
  void getStudentDtr() async {
    try {
      var url = Uri.parse("${SessionStorage.url}transaction.php");
      Map<String, dynamic> jsonData = {
        "stud_active_id": widget.student_id,
      };

      Map<String, String> requestBody = {
        "operation": "getStudentDtr",
        "json": jsonEncode(jsonData),
      };

      var response = await http.post(url, body: requestBody);
      var res = jsonDecode(response.body);
      print(res);
      if (res != 0) {
        setState(() {
          studentDtr = res;
          duty_hours = res[0]['assign_hours'] ?? 0;
        });
      }
    } catch (e) {
      print(e);
    }
  }
}
