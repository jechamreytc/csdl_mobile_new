import 'dart:convert';
import 'package:csdl_mobile/advisor/advisor_drawer.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:csdl_mobile/session_storage.dart';

class Advisor extends StatefulWidget {
  final String advisor_id;
  final String supervisor_id;
  const Advisor({
    super.key,
    required this.advisor_id,
    required this.supervisor_id,
  });

  @override
  _AdvisorState createState() => _AdvisorState();
}

class _AdvisorState extends State<Advisor> {
  List<dynamic> _subjects = [];
  List<dynamic> _scholars = [];
  List<dynamic> _assignedScholars = [];
  String _advisorName = "";
  String _advisorEmail = "";

  @override
  void initState() {
    super.initState();
    _fetchSupervisorProfile();
    _fetchSubjects();
    _fetchScholars();
    _fetchAssignedScholars();
  }

  Future<void> _fetchSupervisorProfile() async {
    try {
      var url = Uri.parse("${SessionStorage.url}transaction.php");

      Map<String, dynamic> payload;

      // If it's a number, send as supM_id, otherwise treat it as email
      if (int.tryParse(widget.advisor_id) != null) {
        payload = {"supM_id": widget.advisor_id};
      } else {
        payload = {"supM_email": widget.advisor_id};
      }

      var response = await http.post(url, body: {
        "operation": "getSupervisorProfile",
        "json": jsonEncode(payload),
      });

      var res = jsonDecode(response.body);
      print("Raw response: ${response.body}");
      print("Decoded response: $res");

      if (res["success"] == true && res["data"] != null) {
        var data = res["data"];
        setState(() {
          _advisorName = data["supM_name"] ?? "Unknown";
          _advisorEmail = data["supM_email"] ?? "No email";
        });
      } else {
        setState(() {
          _advisorName = "Unknown";
          _advisorEmail = "No email";
        });
      }
    } catch (e) {
      print("Error fetching supervisor profile: $e");
    }
  }

  Future<void> _fetchSubjects() async {
    try {
      var url = Uri.parse("${SessionStorage.url}transaction.php");
      var response = await http.post(url, body: {
        "operation": "getAdvisorSubjects",
        "json": jsonEncode({"supM_id": widget.advisor_id}),
      });
      var res = jsonDecode(response.body);

      if (res != 0 && res is List) {
        setState(() => _subjects = res);
      }
    } catch (e) {
      print("Error fetching subjects: $e");
    }
  }

  Future<void> _fetchScholars() async {
    try {
      var url = Uri.parse("${SessionStorage.url}transaction.php");
      var response = await http.post(url, body: {
        "operation": "getAdvisorScholars",
        "json": jsonEncode({"supM_id": widget.advisor_id}),
      });
      var res = jsonDecode(response.body);

      if (res != 0 && res is List) {
        setState(() => _scholars = res);
      }
    } catch (e) {
      print("Error fetching scholars: $e");
    }
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
        if (res != 0) {
          setState(() {
            _assignedScholars = res;
          });
        }
      }
    } catch (e) {
      print("Error fetching assigned scholars: $e");
    }
  }

  Map<String, List<dynamic>> _organizeScholarsByDay() {
    Map<String, List<dynamic>> organizedScholars = {};
    List<String> days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    for (String day in days) {
      organizedScholars[day] = [];
    }

    for (var scholar in _assignedScholars) {
      String dayName = scholar['day_name']?.toString() ?? 'Monday';
      String normalizedDayName = _normalizeDayName(dayName);
      
      if (organizedScholars.containsKey(normalizedDayName)) {
        organizedScholars[normalizedDayName]!.add(scholar);
      } else {
        organizedScholars['Monday']!.add(scholar);
      }
    }
    return organizedScholars;
  }

  String _normalizeDayName(String dayName) {
    String normalized = dayName.toLowerCase().trim();
    switch (normalized) {
      case 'monday': case 'mon': return 'Monday';
      case 'tuesday': case 'tue': return 'Tuesday';
      case 'wednesday': case 'wed': return 'Wednesday';
      case 'thursday': case 'thu': return 'Thursday';
      case 'friday': case 'fri': return 'Friday';
      case 'saturday': case 'sat': return 'Saturday';
      default: return 'Monday';
    }
  }

  void _showAssignedScholarsAlert() {
    Map<String, List<dynamic>> organizedScholars = _organizeScholarsByDay();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.95,
            height: MediaQuery.of(context).size.height * 0.8,
            constraints: const BoxConstraints(
              maxWidth: 500,
              maxHeight: 700,
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, color: Colors.green[700], size: 24),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Assigned Scholars by Day",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(Icons.close, color: Colors.green[700]),
                        iconSize: 20,
                      ),
                    ],
                  ),
                ),
                // Content
                Expanded(
                  child: _assignedScholars.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.people_outline,
                                  size: 48,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  "No scholars assigned to you yet.",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                    fontStyle: FontStyle.italic,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: organizedScholars.length,
                          itemBuilder: (context, index) {
                            String dayName = organizedScholars.keys.elementAt(index);
                            List<dynamic> dayScholars = organizedScholars[dayName]!;
                            return _buildDayCard(dayName, dayScholars);
                          },
                        ),
                ),
                // Footer
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.green[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          "Close",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDayCard(String dayName, List<dynamic> dayScholars) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        title: Row(
          children: [
            Icon(Icons.calendar_today, color: Colors.green[700], size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                "$dayName Assigned Duty",
                style: TextStyle(
                  fontSize: 16, 
                  fontWeight: FontWeight.bold, 
                  color: Colors.green[700]
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green[100], 
                borderRadius: BorderRadius.circular(12)
              ),
              child: Text(
                '${dayScholars.length} Scholar${dayScholars.length != 1 ? 's' : ''}',
                style: TextStyle(
                  color: Colors.green[800], 
                  fontSize: 12, 
                  fontWeight: FontWeight.bold
                ),
              ),
            ),
          ],
        ),
        children: dayScholars.isEmpty
            ? [
                const Padding(
                  padding: EdgeInsets.all(16), 
                  child: Text(
                    "No scholars assigned for this day", 
                    style: TextStyle(
                      color: Colors.grey, 
                      fontStyle: FontStyle.italic, 
                      fontSize: 14
                    ),
                    textAlign: TextAlign.center,
                  )
                )
              ]
            : dayScholars.map((scholar) => _buildScholarCard(scholar)).toList(),
      ),
    );
  }

  Widget _buildScholarCard(Map<String, dynamic> scholar) {
    String assignmentType = scholar['assignment_name']?.toString() ?? 'Unknown';
    String dutyHours = scholar['dutyH_name']?.toString() ?? 'N/A';
    String section = scholar['sub_section']?.toString() ?? 'N/A';
    String room = scholar['sub_room']?.toString() ?? 'N/A';
    String time = scholar['sub_time']?.toString() ?? 'N/A';
    String subject = scholar['sub_code']?.toString() ?? 'N/A';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
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
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    scholar['Fullname']?.toString() ?? 'Unknown',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold, 
                      fontSize: 14
                    ),
                    overflow: TextOverflow.ellipsis,
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
                      fontSize: 11,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value?.toString() ?? 'N/A',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black87,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Scaffold(
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(50),
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
          currentIndex: 0,
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green.shade50, Colors.green.shade200],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // const Text(
              //   "Welcome",
              //   style: TextStyle(
              //     fontSize: 20,
              //     fontWeight: FontWeight.bold,
              //     color: Colors.green,
              //   ),
              // ),
              const SizedBox(height: 8),

              // ✅ Supervisor Info Card
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Color(0xFF104038),
                        child:
                            Icon(Icons.person, size: 30, color: Colors.white),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "$_advisorName",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "$_advisorEmail",
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Subjects Section
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Subjects",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const Divider(),
                      _subjects.isEmpty
                          ? const Text("No subjects found.")
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _subjects.length,
                              itemBuilder: (context, index) {
                                var subj = _subjects[index];
                                return ListTile(
                                  leading: const Icon(Icons.book,
                                      color: Colors.blue),
                                  title: Text(subj["subject_name"] ??
                                      "Unknown Subject"),
                                  subtitle: Text(
                                      "Code: ${subj["subject_code"] ?? 'N/A'}"),
                                );
                              },
                            ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Assigned Scholars Section
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
                child: InkWell(
                  onTap: () {
                    _showAssignedScholarsAlert();
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.people,
                              color: Colors.green[700],
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                "Assigned Scholars",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green[100],
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${_assignedScholars.length}',
                                style: TextStyle(
                                  color: Colors.green[800],
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.green[600],
                              size: 18,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (_assignedScholars.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.people_outline,
                                  color: Colors.grey[600],
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text(
                                    "No scholars assigned yet",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green[200]!),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.people,
                                  color: Colors.green[700],
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    "Tap to view assigned scholars",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.green[700],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward,
                                  color: Colors.green[700],
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
