import 'dart:convert';
import 'package:csdl_mobile/session_storage.dart';
import 'package:csdl_mobile/student/student_drawer.dart';
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
    // Getting the screen size using MediaQuery
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    // Dynamically adjusting the font size based on screen size
    double fontSize =
        screenWidth > 600 ? 18 : 14; // Larger screens use larger font

    return Scaffold(
      // backgroundColor: Colors.green.shade800,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      drawer: StudentDrawer(student_id: widget.student_id), // Green background
      body: Stack(
        children: [
          Image.asset(
            'assets/images/csdl_background.jpg',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            alignment: Alignment.topLeft,
          ),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color.fromRGBO(
                      255, 255, 255, 0.95), // White with 50% transparency
                  Color.fromRGBO(
                      255, 255, 255, 0.95), // White with 50% transparency
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(
              top: kToolbarHeight + 8,
            ),
            child: Container(
              color: const Color(0xFF006400),
              child: SingleChildScrollView(
                padding: EdgeInsets.all(
                    screenWidth * 0.05), // Padding around the screen
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment
                      .start, // Aligns children to the start (left)
                  children: [
                    // Card for School Year
                    // Card for Semester
                    _buildCard(
                      'Semester: ${studentDtr.isNotEmpty ? studentDtr[0]['session_name'] : 'N/A'}',
                      fontSize,
                    ),
                    // Create Data Table
                    createDatatable(fontSize),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Create a reusable card widget with content
  Widget _buildCard(String content, double fontSize) {
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
          style: TextStyle(
            fontSize: fontSize, // Dynamically set font size
            color: Colors.green, // Text color is green
            fontWeight: FontWeight.bold, // Bold text
          ),
        ),
      ),
    );
  }

  // Create a DataTable inside a Card
  Widget createDatatable(double fontSize) {
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
          columns: _columns(fontSize),
          rows: _rows(fontSize),
          headingTextStyle: TextStyle(
            color: Colors.green, // Green header text
            fontWeight: FontWeight.bold, // Bold header text
            fontSize: fontSize, // Dynamically set font size for header
          ),
          dataTextStyle: TextStyle(
            color: Colors.black, // Black text for data cells
            fontSize: fontSize, // Dynamically set font size for data
          ),
        ),
      ),
    );
  }

  // Define the columns of the DataTable (Date, Type, Details, Actions)
  List<DataColumn> _columns(double fontSize) {
    return [
      DataColumn(label: Text("Date", style: TextStyle(fontSize: fontSize))),
      DataColumn(label: Text("Type", style: TextStyle(fontSize: fontSize))),
      DataColumn(label: Text("Details", style: TextStyle(fontSize: fontSize))),
      DataColumn(label: Text("Actions", style: TextStyle(fontSize: fontSize))),
    ];
  }

  // Define the rows of the DataTable
  List<DataRow> _rows(double fontSize) {
    return studentDtr.map((data) {
      bool isAdjustment = data['source'] == 'ADJUSTMENT';
      
      return DataRow(
        cells: [
          DataCell(Text(data['record_date'] ?? 'N/A',
              style: TextStyle(fontSize: fontSize))),
          DataCell(
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isAdjustment ? Colors.orange.shade100 : Colors.green.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isAdjustment ? Colors.orange : Colors.green,
                  width: 1,
                ),
              ),
              child: Text(
                isAdjustment ? 'Adjustment' : 'DTR',
                style: TextStyle(
                  fontSize: fontSize - 2,
                  fontWeight: FontWeight.w600,
                  color: isAdjustment ? Colors.orange.shade800 : Colors.green.shade800,
                ),
              ),
            ),
          ),
          DataCell(
            Text(
              isAdjustment 
                ? '${data['adjustment_deducted'] ?? 'N/A'} hours deducted'
                : '${data['dtr_time_in'] ?? 'N/A'} - ${data['dtr_time_out'] ?? 'N/A'}',
              style: TextStyle(fontSize: fontSize),
            ),
          ),
          DataCell(
            ElevatedButton(
              onPressed: () => _showDetailsDialog(data),
              child: const Text("View Details"),
            ),
          ),
        ],
      );
    }).toList();
  }

  // Function to show the dialog with the detailed data
  void _showDetailsDialog(Map<String, dynamic> data) {
    bool isAdjustment = data['source'] == 'ADJUSTMENT';
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Details for ${data['record_date']}'),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isAdjustment) ...[
                _buildDetailCard('Type', 'Adjustment', Icons.settings, Colors.orange),
                _buildDetailCard('Date', data['record_date'] ?? 'N/A', Icons.calendar_today, Colors.blue),
                _buildDetailCard('Hours Deducted', '${data['adjustment_deducted'] ?? 'N/A'} hours', Icons.remove_circle, Colors.red),
                _buildDetailCard('Reason', data['adjustment_reason'] ?? 'N/A', Icons.info, Colors.grey),
              ] else ...[
                _buildDetailCard('Type', 'DTR Record', Icons.access_time, Colors.green),
                _buildDetailCard('Date', data['record_date'] ?? 'N/A', Icons.calendar_today, Colors.blue),
                _buildDetailCard('Time In', data['dtr_time_in'] ?? 'N/A', Icons.login, Colors.green),
                _buildDetailCard('Time Out', data['dtr_time_out'] ?? 'N/A', Icons.logout, Colors.red),
                _buildDetailCard('Rendered Hours', data['TotalRendered'] ?? 'N/A', Icons.timer, Colors.blue),
              ],
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailCard(String title, String value, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
      // print("print ni" + res);
      if (res != 0) {
        setState(() {
          studentDtr = res;
          duty_hours = res[0]['assign_hours'] ?? 0;
        });
      }
    } catch (e) {
      // print(e);
    }
  }
}
