import 'dart:convert';
import 'package:csdl_mobile/advisor/advisor_drawer.dart';
import 'package:csdl_mobile/session_storage.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AdvisorDayAssignments extends StatefulWidget {
  final String advisor_id;
  final String supervisor_id;
  const AdvisorDayAssignments({
    super.key,
    required this.advisor_id,
    required this.supervisor_id,
  });

  @override
  _AdvisorDayAssignmentsState createState() => _AdvisorDayAssignmentsState();
}

class _AdvisorDayAssignmentsState extends State<AdvisorDayAssignments> {
  List<dynamic> _scholars = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchAssignedScholars();
  }

  Future<void> _fetchAssignedScholars() async {
    try {
      var url = Uri.parse("${SessionStorage.url}transaction.php");
      Map<String, dynamic> jsonData = {
        "supM_email": widget.advisor_id,
      };

      Map<String, String> requestBody = {
        "operation": "getAssignedScholars",
        "json": jsonEncode(jsonData),
      };

      var response = await http.post(url, body: requestBody);

      if (response.statusCode == 200) {
        var res = jsonDecode(response.body);
        print("Day Assignments API Response: $res");
        if (res != 0) {
          setState(() {
            _scholars = res;
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
            _errorMessage = "No scholars assigned.";
          });
        }
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = "Failed to load scholars.";
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = "An error occurred: $e";
      });
    }
  }

  Map<String, List<dynamic>> _organizeScholarsByDay() {
    Map<String, List<dynamic>> organizedScholars = {};
    
    // Initialize days in order
    List<String> days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    for (String day in days) {
      organizedScholars[day] = [];
    }

    print("Total scholars to organize: ${_scholars.length}");
    
    // Organize scholars by day
    for (var scholar in _scholars) {
      String dayName = scholar['day_name']?.toString() ?? 'Monday';
      print("Scholar: ${scholar['Fullname']?.toString() ?? 'Unknown'}, Day: $dayName, Assignment: ${scholar['assignment_name']?.toString() ?? 'Unknown'}");
      
      // Ensure the day name is properly capitalized and matches our list
      String normalizedDayName = _normalizeDayName(dayName);
      
      if (organizedScholars.containsKey(normalizedDayName)) {
        organizedScholars[normalizedDayName]!.add(scholar);
      } else {
        // If day doesn't match, add to Monday as default
        organizedScholars['Monday']!.add(scholar);
        print("Added ${scholar['Fullname']?.toString() ?? 'Unknown'} to Monday (default)");
      }
    }

    // Print organization results
    organizedScholars.forEach((day, scholars) {
      print("$day: ${scholars.length} scholars");
    });

    return organizedScholars;
  }

  String _normalizeDayName(String dayName) {
    // Normalize day names to match our expected format
    String normalized = dayName.toLowerCase().trim();
    switch (normalized) {
      case 'monday':
      case 'mon':
        return 'Monday';
      case 'tuesday':
      case 'tue':
        return 'Tuesday';
      case 'wednesday':
      case 'wed':
        return 'Wednesday';
      case 'thursday':
      case 'thu':
        return 'Thursday';
      case 'friday':
      case 'fri':
        return 'Friday';
      case 'saturday':
      case 'sat':
        return 'Saturday';
      default:
        return 'Monday'; // Default fallback
    }
  }

  Widget _buildDayCard(String dayName, List<dynamic> dayScholars) {
    // Check if there are any SF assignments for this day
    bool hasSFAssignments = dayScholars.any((scholar) => scholar['assignment_name'] == 'Student Facilitator');
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ExpansionTile(
        title: Row(
          children: [
            Icon(
              Icons.calendar_today,
              color: Colors.green[700],
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              "$dayName Assigned Duty",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green[700],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${dayScholars.length} Scholar${dayScholars.length != 1 ? 's' : ''}',
                style: TextStyle(
                  color: Colors.green[800],
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        subtitle: dayScholars.isNotEmpty 
            ? Text(
                "Click to view assigned scholars",
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              )
            : null,
        children: dayScholars.isEmpty
            ? [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    "No scholars assigned for this day",
                    style: TextStyle(
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ]
            : dayScholars.map((scholar) => _buildScholarCard(scholar, hasSFAssignments)).toList(),
      ),
    );
  }

  Widget _buildScholarCard(Map<String, dynamic> scholar, bool hasSFAssignments) {
    String assignmentType = scholar['assignment_name']?.toString() ?? 'Unknown';
    String dutyHours = scholar['dutyH_name']?.toString() ?? 'N/A';
    String section = scholar['sub_section']?.toString() ?? 'N/A';
    String room = scholar['sub_room']?.toString() ?? 'N/A';
    String time = scholar['sub_time']?.toString() ?? 'N/A';
    String subject = scholar['sub_code']?.toString() ?? 'N/A';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  assignmentType == 'Office' ? Icons.business : Icons.school,
                  color: assignmentType == 'Office' ? Colors.blue : Colors.green,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    scholar['Fullname']?.toString() ?? 'Unknown',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: assignmentType == 'Office' ? Colors.blue[100] : Colors.green[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    assignmentType,
                    style: TextStyle(
                      color: assignmentType == 'Office' ? Colors.blue[800] : Colors.green[800],
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (assignmentType == 'Student Facilitator') ...[
              _buildInfoRow('Section', section),
              _buildInfoRow('Subject', subject),
              _buildInfoRow('Duty Hours', dutyHours),
              _buildInfoRow('Time', time),
            ] else ...[
              _buildInfoRow('Department', scholar['dept_name']),
              _buildInfoRow('Building', scholar['build_name']),
              _buildInfoRow('Duty Hours', dutyHours),
            ],
            _buildInfoRow('Room', room),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value?.toString() ?? 'N/A',
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(50),
        child: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          flexibleSpace: Image.asset(
            'assets/images/coc_logo.png',
            height: 50,
            width: 50,
          ),
        ),
      ),
      drawer: AdvisorDrawer(
        advisorId: widget.advisor_id,
        supervisor_id: widget.supervisor_id,
        currentIndex: 0, // This is a separate module, so it goes back to dashboard
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
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              const Text(
                "DAY-ORGANIZED SCHOLAR ASSIGNMENTS",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2F332D),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage.isNotEmpty
                        ? Center(
                            child: Text(
                              _errorMessage,
                              style: const TextStyle(color: Colors.red),
                            ),
                          )
                        : _buildScholarsByDay(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScholarsByDay() {
    Map<String, List<dynamic>> organizedScholars = _organizeScholarsByDay();
    
    return ListView.builder(
      itemCount: organizedScholars.length,
      itemBuilder: (context, index) {
        String dayName = organizedScholars.keys.elementAt(index);
        List<dynamic> dayScholars = organizedScholars[dayName]!;
        
        return _buildDayCard(dayName, dayScholars);
      },
    );
  }
}
