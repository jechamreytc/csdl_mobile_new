import 'dart:convert';
import 'package:csdl_mobile/advisor/advisor_drawer.dart';
import 'package:csdl_mobile/advisor/advisor_announcement.dart';
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
  List<dynamic> _scholarProgress = [];
  String _advisorName = "";
  String _advisorEmail = "";

  @override
  void initState() {
    super.initState();
    _fetchSupervisorProfile();
    _fetchSubjects();
    _fetchScholars();
    _fetchAssignedScholars();
    _fetchScholarProgress();
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
      setState(() {
        _advisorName = "Unknown";
        _advisorEmail = "No email";
      });
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
    } catch (e) {}
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
    } catch (e) {}
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
    } catch (e) {}
  }

  Future<void> _fetchScholarProgress() async {
    try {
      var url = Uri.parse("${SessionStorage.url}transaction.php");
      Map<String, dynamic> jsonData = {
        "supM_email": widget.advisor_id,
      };
      Map<String, String> requestBody = {
        "operation": "getScholarProgress",
        "json": jsonEncode(jsonData),
      };
      var response = await http.post(url, body: requestBody);
      if (response.statusCode == 200) {
        var res = jsonDecode(response.body);
        if (res["success"] == true && res["data"] != null) {
          setState(() {
            _scholarProgress = res["data"];
          });
        }
      }
    } catch (e) {}
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

  void _showScholarProgressAlert() {
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
                    color: Colors.orange[50],
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.trending_up, color: Colors.orange[700], size: 24),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Scholar Duty Progress",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[700],
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(Icons.close, color: Colors.orange[700]),
                        iconSize: 20,
                      ),
                    ],
                  ),
                ),
                // Content
                Expanded(
                  child: _scholarProgress.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.analytics_outlined,
                                  size: 48,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  "No progress data available.",
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
                          itemCount: _scholarProgress.length,
                          itemBuilder: (context, index) {
                            var progress = _scholarProgress[index];
                            return _buildProgressCard(progress);
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
                          backgroundColor: Colors.orange[700],
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
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    _showComplaintDialog(scholar);
                  },
                  icon: const Icon(Icons.report_problem, size: 16),
                  label: const Text('Complain'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
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

  void _showComplaintDialog(Map<String, dynamic> scholar) {
    final TextEditingController reasonController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                constraints: const BoxConstraints(maxWidth: 500),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.report_problem,
                          color: Colors.red[600],
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            "Submit Complaint",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                          color: Colors.grey[600],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Scholar: ${scholar['Fullname']?.toString() ?? 'Unknown'}",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: reasonController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: "Reason for Complaint",
                        hintText: "Describe the issue in detail...",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.report_problem),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: isSubmitting ? null : () => Navigator.pop(context),
                          child: const Text("Cancel"),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: isSubmitting ? null : () async {
                            if (reasonController.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Please enter a reason for the complaint"),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            setState(() {
                              isSubmitting = true;
                            });

                            try {
                              await _submitComplaint(
                                scholar['stud_active_id']?.toString() ?? '',
                                reasonController.text.trim(),
                              );

                              if (mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Complaint submitted successfully"),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("Error: $e"),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            } finally {
                              if (mounted) {
                                setState(() {
                                  isSubmitting = false;
                                });
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[600],
                            foregroundColor: Colors.white,
                          ),
                          child: isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text("Submit Complaint"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _submitComplaint(String scholarId, String complaintText) async {
    try {
      var url = Uri.parse("${SessionStorage.url}transaction.php");
      
      // Convert supervisor email to supervisor ID
      String supervisorId = await _getSupervisorId(widget.advisor_id);
      
      Map<String, String> requestBody = {
        "operation": "submitComplaint",
        "json": jsonEncode({
          "scholar_id": scholarId,
          "supervisor_id": supervisorId,
          "complaint_details": complaintText,
        }),
      };

      var response = await http.post(url, body: requestBody);

      if (response.statusCode == 200) {
        try {
          var res = jsonDecode(response.body);
          
          // Check if response has success field
          if (res is Map && res.containsKey('success')) {
            if (res['success'] == true) {
            } else {
              throw Exception(res['error'] ?? "Failed to submit complaint");
            }
          } 
          // Check if response has error field
          else if (res is Map && res.containsKey('error')) {
            throw Exception(res['error']);
          }
          // Legacy support for numeric responses
          else if (res == 1) {
          } else {
            throw Exception("Failed to submit complaint");
          }
        } catch (e) {
          throw Exception("Error submitting complaint: $e");
        }
      } else {
        throw Exception("Server error: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error submitting complaint: $e");
    }
  }

  Future<String> _getSupervisorId(String supervisorEmail) async {
    try {
      var url = Uri.parse("${SessionStorage.url}transaction.php");
      
      Map<String, String> requestBody = {
        "operation": "getSupervisorProfile",
        "json": jsonEncode({
          "supM_email": supervisorEmail,
        }),
      };

      var response = await http.post(url, body: requestBody);

      if (response.statusCode == 200) {
        var res = jsonDecode(response.body);
        print("Supervisor Profile Response: $res");
        
        if (res is List && res.isNotEmpty) {
          return res[0]['supM_id']?.toString() ?? '0';
        } else if (res is Map && res.containsKey('supM_id')) {
          return res['supM_id']?.toString() ?? '0';
        } else {
          print("No supervisor ID found, using default: 1");
          return '1'; // Default supervisor ID
        }
      } else {
        print("Failed to get supervisor ID, using default: 1");
        return '1'; // Default supervisor ID
      }
    } catch (e) {
      print("Error getting supervisor ID: $e, using default: 1");
      return '1'; // Default supervisor ID
    }
  }

  Widget _buildProgressCard(Map<String, dynamic> progress) {
    String fullname = progress['Fullname']?.toString() ?? 'Unknown';
    String assignmentType = progress['assignment_name']?.toString() ?? 'Unknown';
    double progressPercentage = double.tryParse(progress['ProgressPercentage']?.toString() ?? '0') ?? 0;
    double totalDutyHours = double.tryParse(progress['TotalDutyHours']?.toString() ?? '0') ?? 0;
    double totalRenderedHours = double.tryParse(progress['TotalRenderedHours']?.toString() ?? '0') ?? 0;
    double remainingHours = double.tryParse(progress['RemainingHours']?.toString() ?? '0') ?? 0;
    int attendanceDays = int.tryParse(progress['AttendanceDays']?.toString() ?? '0') ?? 0;
    String lastAttendanceDate = progress['LastAttendanceDate']?.toString() ?? 'Never';
    String subject = progress['sub_code']?.toString() ?? 'N/A';
    String section = progress['sub_section']?.toString() ?? 'N/A';
    String room = progress['sub_room']?.toString() ?? 'N/A';
    String time = progress['sub_time']?.toString() ?? 'N/A';
    String deptName = progress['dept_name']?.toString() ?? 'N/A';
    String buildName = progress['build_name']?.toString() ?? 'N/A';

    // Determine progress color
    Color progressColor;
    if (progressPercentage >= 100) {
      progressColor = Colors.green;
    } else if (progressPercentage >= 75) {
      progressColor = Colors.blue;
    } else if (progressPercentage >= 50) {
      progressColor = Colors.orange;
    } else {
      progressColor = Colors.red;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with name and assignment type
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
                    fullname,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
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
            const SizedBox(height: 12),
            
            // Progress Bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progress',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '${progressPercentage.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: progressColor,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: progressPercentage / 100,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                  minHeight: 8,
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Hours Information
            Row(
              children: [
                Expanded(
                  child: _buildProgressInfoRow('Rendered', '${totalRenderedHours.toStringAsFixed(1)}h', Colors.green),
                ),
                Expanded(
                  child: _buildProgressInfoRow('Remaining', '${remainingHours.toStringAsFixed(1)}h', Colors.orange),
                ),
                Expanded(
                  child: _buildProgressInfoRow('Total', '${totalDutyHours.toStringAsFixed(1)}h', Colors.blue),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Additional Info
            Row(
              children: [
                Expanded(
                  child: _buildProgressInfoRow('Days', '$attendanceDays', Colors.purple),
                ),
                Expanded(
                  child: _buildProgressInfoRow('Last', lastAttendanceDate != 'Never' ? 
                    DateTime.tryParse(lastAttendanceDate)?.toString().split(' ')[0] ?? 'Never' : 'Never', Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Assignment Details
            if (assignmentType == 'Student Facilitator') ...[
              _buildInfoRow('Subject', subject),
              _buildInfoRow('Section', section),
              _buildInfoRow('Time', time),
              _buildInfoRow('Room', room),
            ] else ...[
              _buildInfoRow('Department', deptName),
              _buildInfoRow('Building', buildName),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProgressInfoRow(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 12,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
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

              // âœ… Supervisor Info Card
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
              // Card(
              //   shape: RoundedRectangleBorder(
              //     borderRadius: BorderRadius.circular(12),
              //   ),
              //   elevation: 3,
              //   child: Padding(
              //     padding: const EdgeInsets.all(12),
              //     child: Column(
              //       crossAxisAlignment: CrossAxisAlignment.start,
              //       children: [
              //         const Text(
              //           "Subjects",
              //           style: TextStyle(
              //             fontSize: 18,
              //             fontWeight: FontWeight.bold,
              //             color: Colors.blue,
              //           ),
              //         ),
              //         const Divider(),
              //         _subjects.isEmpty
              //             ? const Text("No subjects found.")
              //             : ListView.builder(
              //                 shrinkWrap: true,
              //                 physics: const NeverScrollableScrollPhysics(),
              //                 itemCount: _subjects.length,
              //                 itemBuilder: (context, index) {
              //                   var subj = _subjects[index];
              //                   return ListTile(
              //                     leading: const Icon(Icons.book,
              //                         color: Colors.blue),
              //                     title: Text(subj["subject_name"] ??
              //                         "Unknown Subject"),
              //                     subtitle: Text(
              //                         "Code: ${subj["subject_code"] ?? 'N/A'}"),
              //                   );
              //                 },
              //               ),
              //       ],
              //     ),
              //   ),
              // ),

              // const SizedBox(height: 16),

              // Assigned Scholars Section
              // Card(
              //   shape: RoundedRectangleBorder(
              //     borderRadius: BorderRadius.circular(12),
              //   ),
              //   elevation: 3,
              //   child: InkWell(
              //     onTap: () {
              //       _showAssignedScholarsAlert();
              //     },
              //     borderRadius: BorderRadius.circular(12),
              //     child: Padding(
              //       padding: const EdgeInsets.all(16),
              //       child: Column(
              //         crossAxisAlignment: CrossAxisAlignment.start,
              //         children: [
              //           Row(
              //             children: [
              //               Icon(
              //                 Icons.people,
              //                 color: Colors.green[700],
              //                 size: 24,
              //               ),
              //               const SizedBox(width: 12),
              //               const Expanded(
              //                 child: Text(
              //                   "Scholar Lists",
              //                   style: TextStyle(
              //                     fontSize: 20,
              //                     fontWeight: FontWeight.bold,
              //                     color: Colors.green,
              //                   ),
              //                 ),
              //               ),
              //               Container(
              //                 padding: const EdgeInsets.symmetric(
              //                   horizontal: 12,
              //                   vertical: 6,
              //                 ),
              //                 decoration: BoxDecoration(
              //                   color: Colors.green[100],
              //                   borderRadius: BorderRadius.circular(20),
              //                 ),
              //                 child: Text(
              //                   '${_assignedScholars.length}',
              //                   style: TextStyle(
              //                     color: Colors.green[800],
              //                     fontSize: 16,
              //                     fontWeight: FontWeight.bold,
              //                   ),
              //                 ),
              //               ),
              //               const SizedBox(width: 8),
              //               Icon(
              //                 Icons.arrow_forward_ios,
              //                 color: Colors.green[600],
              //                 size: 18,
              //               ),
              //             ],
              //           ),
              //           const SizedBox(height: 8),
              //           if (_assignedScholars.isEmpty)
              //             Container(
              //               padding: const EdgeInsets.all(16),
              //               decoration: BoxDecoration(
              //                 color: Colors.grey[50],
              //                 borderRadius: BorderRadius.circular(8),
              //                 border: Border.all(color: Colors.grey[300]!),
              //               ),
              //               child: Row(
              //                 children: [
              //                   Icon(
              //                     Icons.people_outline,
              //                     color: Colors.grey[600],
              //                     size: 20,
              //                   ),
              //                   const SizedBox(width: 12),
              //                   const Expanded(
              //                     child: Text(
              //                       "No scholars assigned yet",
              //                       style: TextStyle(
              //                         fontSize: 14,
              //                         color: Colors.grey,
              //                         fontStyle: FontStyle.italic,
              //                       ),
              //                     ),
              //                   ),
              //                 ],
              //               ),
              //             )
              //           else
              //             Container(
              //               padding: const EdgeInsets.all(16),
              //               decoration: BoxDecoration(
              //                 color: Colors.green[50],
              //                 borderRadius: BorderRadius.circular(8),
              //                 border: Border.all(color: Colors.green[200]!),
              //               ),
              //               child: Row(
              //                 children: [
              //                   Icon(
              //                     Icons.people,
              //                     color: Colors.green[700],
              //                     size: 20,
              //                   ),
              //                   const SizedBox(width: 12),
              //                   Expanded(
              //                     child: Text(
              //                       "Tap to view assigned scholars",
              //                       style: TextStyle(
              //                         fontSize: 14,
              //                         color: Colors.green[700],
              //                         fontWeight: FontWeight.w500,
              //                       ),
              //                     ),
              //                   ),
              //                   Icon(
              //                     Icons.arrow_forward,
              //                     color: Colors.green[700],
              //                     size: 16,
              //                   ),
              //                 ],
              //               ),
              //             ),
              //         ],
              //       ),
              //     ),
              //   ),
              // ),

              // const SizedBox(height: 16),

              // Reports Section
              // Card(
              //   shape: RoundedRectangleBorder(
              //     borderRadius: BorderRadius.circular(12),
              //   ),
              //   elevation: 3,
              //   child: InkWell(
              //     onTap: () {
              //       _showReportsDialog();
              //     },
              //     borderRadius: BorderRadius.circular(12),
              //     child: Padding(
              //       padding: const EdgeInsets.all(16),
              //       child: Column(
              //         crossAxisAlignment: CrossAxisAlignment.start,
              //         children: [
              //           Row(
              //             children: [
              //               Icon(
              //                 Icons.assessment,
              //                 color: Colors.blue[700],
              //                 size: 24,
              //               ),
              //               const SizedBox(width: 12),
              //               const Expanded(
              //                 child: Text(
              //                   "Reports",
              //                   style: TextStyle(
              //                     fontSize: 20,
              //                     fontWeight: FontWeight.bold,
              //                     color: Colors.blue,
              //                   ),
              //                 ),
              //               ),
              //               Container(
              //                 padding: const EdgeInsets.symmetric(
              //                   horizontal: 12,
              //                   vertical: 6,
              //                 ),
              //                 decoration: BoxDecoration(
              //                   color: Colors.blue[100],
              //                   borderRadius: BorderRadius.circular(20),
              //                 ),
              //                 child: Text(
              //                   '${_scholarProgress.length}',
              //                   style: TextStyle(
              //                     color: Colors.blue[800],
              //                     fontSize: 16,
              //                     fontWeight: FontWeight.bold,
              //                   ),
              //                 ),
              //               ),
              //               const SizedBox(width: 8),
              //               Icon(
              //                 Icons.arrow_forward_ios,
              //                 color: Colors.blue[600],
              //                 size: 18,
              //               ),
              //             ],
              //           ),
              //           const SizedBox(height: 8),
              //           if (_scholarProgress.isEmpty)
              //             Container(
              //               padding: const EdgeInsets.all(16),
              //               decoration: BoxDecoration(
              //                 color: Colors.grey[50],
              //                 borderRadius: BorderRadius.circular(8),
              //                 border: Border.all(color: Colors.grey[300]!),
              //               ),
              //               child: Row(
              //                 children: [
              //                   Icon(
              //                     Icons.assessment_outlined,
              //                     color: Colors.grey[600],
              //                     size: 20,
              //                   ),
              //                   const SizedBox(width: 12),
              //                   const Expanded(
              //                     child: Text(
              //                       "No progress data available",
              //                       style: TextStyle(
              //                         fontSize: 14,
              //                         color: Colors.grey,
              //                         fontStyle: FontStyle.italic,
              //                       ),
              //                     ),
              //                   ),
              //                 ],
              //               ),
              //             )
              //           else
              //             Container(
              //               padding: const EdgeInsets.all(16),
              //               decoration: BoxDecoration(
              //                 color: Colors.blue[50],
              //                 borderRadius: BorderRadius.circular(8),
              //                 border: Border.all(color: Colors.blue[200]!),
              //               ),
              //               child: Row(
              //                 children: [
              //                   Icon(
              //                     Icons.assessment,
              //                     color: Colors.blue[700],
              //                     size: 20,
              //                   ),
              //                   const SizedBox(width: 12),
              //                   Expanded(
              //                     child: Text(
              //                       "Tap to view duty hours and progress reports",
              //                       style: TextStyle(
              //                         fontSize: 14,
              //                         color: Colors.blue[700],
              //                         fontWeight: FontWeight.w500,
              //                       ),
              //                     ),
              //                   ),
              //                   Icon(
              //                     Icons.arrow_forward,
              //                     color: Colors.blue[700],
              //                     size: 16,
              //                   ),
              //                 ],
              //               ),
              //             ),
              //         ],
              //       ),
              //     ),
              //   ),
              // ),

              const SizedBox(height: 10),

              // Announcements Section
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF104038),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AdvisorAnnouncementsPage(
                        advisor_id: widget.advisor_id,
                      ),
                    ),
                  );
                },
                child: const Text(
                  "View Announcements",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),

              const SizedBox(height: 16),

              // Duty Statistics Section
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.assessment,
                            color: Colors.blue[700],
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              "Duty Statistics",
                        style: TextStyle(
                                fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                          ),
                          IconButton(
                            onPressed: () {
                              _fetchScholarProgress();
                            },
                            icon: Icon(
                              Icons.refresh,
                              color: Colors.blue[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildDashboardStatistics(),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Scholar Progress Section
              // Card(
              //   shape: RoundedRectangleBorder(
              //     borderRadius: BorderRadius.circular(12),
              //   ),
              //   elevation: 3,
              //   child: InkWell(
              //     onTap: () {
              //       _showScholarProgressAlert();
              //     },
              //     borderRadius: BorderRadius.circular(12),
              //     child: Padding(
              //       padding: const EdgeInsets.all(16),
              //       child: Column(
              //         crossAxisAlignment: CrossAxisAlignment.start,
              //         children: [
              //           Row(
              //             children: [
              //               Icon(
              //                 Icons.trending_up,
              //                 color: Colors.orange[700],
              //                 size: 24,
              //               ),
              //               const SizedBox(width: 12),
              //               const Expanded(
              //                 child: Text(
              //                   "Duty Progress",
              //                   style: TextStyle(
              //                     fontSize: 20,
              //                     fontWeight: FontWeight.bold,
              //                     color: Colors.orange,
              //                   ),
              //                 ),
              //               ),
              //               Container(
              //                 padding: const EdgeInsets.symmetric(
              //                   horizontal: 12,
              //                   vertical: 6,
              //                 ),
              //                 decoration: BoxDecoration(
              //                   color: Colors.orange[100],
              //                   borderRadius: BorderRadius.circular(20),
              //                 ),
              //                 child: Text(
              //                   '${_scholarProgress.length}',
              //                   style: TextStyle(
              //                     color: Colors.orange[800],
              //                     fontSize: 16,
              //                     fontWeight: FontWeight.bold,
              //                   ),
              //                 ),
              //               ),
              //               const SizedBox(width: 8),
              //               Icon(
              //                 Icons.arrow_forward_ios,
              //                 color: Colors.orange[600],
              //                 size: 18,
              //               ),
              //             ],
              //           ),
              //           const SizedBox(height: 8),
              //           if (_scholarProgress.isEmpty)
              //             Container(
              //               padding: const EdgeInsets.all(16),
              //               decoration: BoxDecoration(
              //                 color: Colors.grey[50],
              //                 borderRadius: BorderRadius.circular(8),
              //                 border: Border.all(color: Colors.grey[300]!),
              //               ),
              //               child: Row(
              //                 children: [
              //                   Icon(
              //                     Icons.analytics_outlined,
              //                     color: Colors.grey[600],
              //                     size: 20,
              //                   ),
              //                   const SizedBox(width: 12),
              //                   const Expanded(
              //                     child: Text(
              //                       "No progress data available",
              //                       style: TextStyle(
              //                         fontSize: 14,
              //                         color: Colors.grey,
              //                         fontStyle: FontStyle.italic,
              //                       ),
              //                     ),
              //                   ),
              //                 ],
              //               ),
              //             )
              //           else
              //             Container(
              //               padding: const EdgeInsets.all(16),
              //               decoration: BoxDecoration(
              //                 color: Colors.orange[50],
              //                 borderRadius: BorderRadius.circular(8),
              //                 border: Border.all(color: Colors.orange[200]!),
              //               ),
              //               child: Row(
              //                 children: [
              //                   Icon(
              //                     Icons.analytics,
              //                     color: Colors.orange[700],
              //                     size: 20,
              //                   ),
              //                   const SizedBox(width: 12),
              //                   Expanded(
              //                     child: Text(
              //                       "Tap to view duty progress of assigned scholars",
              //                       style: TextStyle(
              //                         fontSize: 14,
              //                         color: Colors.orange[700],
              //                         fontWeight: FontWeight.w500,
              //                       ),
              //                     ),
              //                   ),
              //                   Icon(
              //                     Icons.arrow_forward,
              //                     color: Colors.orange[700],
              //                     size: 16,
              //                   ),
              //                 ],
              //               ),
              //             ),
              //         ],
              //       ),
              //     ),
              //   ),
              // ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showReportsDialog() {
    // Calculate statistics
    int totalScholars = _scholarProgress.length;
    int evaluatedCount = 0;
    int noProgressCount = 0;
    int withProgressCount = 0;
    
    for (var progress in _scholarProgress) {
      String evaluationStatus = progress['assign_evaluation_status']?.toString() ?? '';
      double progressPercentage = double.tryParse(progress['ProgressPercentage']?.toString() ?? '0') ?? 0;
      
      if (evaluationStatus.toLowerCase() == 'evaluated' || evaluationStatus.toLowerCase() == 'completed') {
        evaluatedCount++;
      }
      
      if (progressPercentage == 0) {
        noProgressCount++;
      } else {
        withProgressCount++;
      }
    }

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
              maxWidth: 600,
              maxHeight: 700,
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.assessment,
                        color: Colors.blue[700],
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          "Duty Hours & Progress Reports",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                        color: Colors.grey[600],
                      ),
                    ],
                  ),
                ),
                
                // Statistics Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        "Duty Statistics",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              "Total Scholars",
                              "$totalScholars",
                              Icons.people,
                              Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildStatCard(
                              "Evaluated",
                              "$evaluatedCount",
                              Icons.check_circle,
                              Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              "With Progress",
                              "$withProgressCount",
                              Icons.trending_up,
                              Colors.orange,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildStatCard(
                              "No Progress",
                              "$noProgressCount",
                              Icons.trending_down,
                              Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Content
                Expanded(
                  child: _scholarProgress.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.assessment_outlined,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "No Progress Data Available",
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Progress data will appear here once scholars start their duties",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _scholarProgress.length,
                          itemBuilder: (context, index) {
                            var progress = _scholarProgress[index];
                            return _buildReportCard(progress);
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildReportCard(Map<String, dynamic> progress) {
    String fullname = progress['Fullname'] ?? 'Unknown Scholar';
    String studEmail = progress['stud_email'] ?? '';
    String studContact = progress['stud_contactNumber'] ?? '';
    double totalDutyHours = double.tryParse(progress['TotalDutyHours']?.toString() ?? '0') ?? 0;
    double totalRenderedHours = double.tryParse(progress['TotalRenderedHours']?.toString() ?? '0') ?? 0;
    double remainingHours = double.tryParse(progress['RemainingHours']?.toString() ?? '0') ?? 0;
    double progressPercentage = double.tryParse(progress['ProgressPercentage']?.toString() ?? '0') ?? 0;
    String assignmentName = progress['assignment_name'] ?? 'Unknown Assignment';
    String dutyStatus = progress['assign_render_status'] ?? 'Unknown';
    String lastAttendanceDate = progress['LastAttendanceDate'] ?? 'No attendance yet';
    int attendanceDays = int.tryParse(progress['AttendanceDays']?.toString() ?? '0') ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
            // Header with name and status
                        Row(
                          children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.blue[100],
                  child: Text(
                    fullname.isNotEmpty ? fullname[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                            ),
                            const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fullname,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        assignmentName,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(dutyStatus),
                    borderRadius: BorderRadius.circular(12),
                  ),
                              child: Text(
                    dutyStatus,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Progress Bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Progress",
                                style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                    Text(
                      "${progressPercentage.toStringAsFixed(1)}%",
                      style: TextStyle(
                        fontSize: 14,
                                  fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progressPercentage / 100,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getProgressColor(progressPercentage),
                  ),
                  minHeight: 8,
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Hours Information
            Row(
              children: [
                Expanded(
                  child: _buildInfoCard(
                    "Total Hours",
                    "${totalDutyHours.toStringAsFixed(1)}h",
                    Icons.schedule,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildInfoCard(
                    "Rendered",
                    "${totalRenderedHours.toStringAsFixed(1)}h",
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildInfoCard(
                    "Remaining",
                    "${remainingHours.toStringAsFixed(1)}h",
                    Icons.timer,
                    Colors.orange,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Additional Info
            Row(
              children: [
                Expanded(
                  child: _buildInfoCard(
                    "Attendance Days",
                    "$attendanceDays days",
                    Icons.calendar_today,
                    Colors.purple,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildInfoCard(
                    "Last Attendance",
                    lastAttendanceDate.isNotEmpty ? lastAttendanceDate : "None",
                    Icons.access_time,
                    Colors.teal,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 4),
          Text(
            value,
                                style: TextStyle(
              fontSize: 12,
                                  fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Color _getProgressColor(double percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 60) return Colors.blue;
    if (percentage >= 40) return Colors.orange;
    return Colors.red;
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardStatistics() {
    // Calculate statistics based on assigned scholars for this supervisor
    int totalScholars = _assignedScholars.length;
    int evaluatedCount = 0;
    int noProgressCount = 0;
    int withProgressCount = 0;
    
    for (var scholar in _assignedScholars) {
      String evaluationStatus = scholar['assign_evaluation_status']?.toString() ?? '';
      double progressPercentage = double.tryParse(scholar['ProgressPercentage']?.toString() ?? '0') ?? 0;
      
      // Count scholars that have been evaluated (status = 1 means evaluated)
      if (evaluationStatus == '1' || evaluationStatus.toLowerCase() == 'evaluated' || evaluationStatus.toLowerCase() == 'completed') {
        evaluatedCount++;
      }
      
      if (progressPercentage == 0) {
        noProgressCount++;
      } else {
        withProgressCount++;
      }
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                "Total Scholars",
                "$totalScholars",
                Icons.people,
                Colors.blue,
                onTap: () {
                  _showAssignedScholarsAlert();
                },
                              ),
                            ),
                            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                "Evaluated",
                "$evaluatedCount",
                Icons.check_circle,
                Colors.green,
                onTap: () {
                  _showEvaluatedScholarsAlert();
                },
              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                "With Progress",
                "$withProgressCount",
                Icons.trending_up,
                Colors.orange,
                onTap: () {
                  _showProgressScholarsAlert();
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                "No Progress",
                "$noProgressCount",
                Icons.trending_down,
                Colors.red,
                onTap: () {
                  _showNoProgressScholarsAlert();
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showEvaluatedScholarsAlert() {
    List<dynamic> evaluatedScholars = _assignedScholars.where((scholar) {
      String evaluationStatus = scholar['assign_evaluation_status']?.toString() ?? '';
      return evaluationStatus == '1' || evaluationStatus.toLowerCase() == 'evaluated' || evaluationStatus.toLowerCase() == 'completed';
    }).toList();

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
              maxWidth: 600,
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
                                Icon(
                        Icons.check_circle,
                        color: Colors.green[700],
                        size: 28,
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text(
                          "Evaluated Scholars",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                        color: Colors.grey[600],
                      ),
                    ],
                  ),
                ),
                
                // Content
                Expanded(
                  child: evaluatedScholars.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "No Evaluated Scholars",
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "No scholars have been evaluated yet",
                                textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: evaluatedScholars.length,
                          itemBuilder: (context, index) {
                            var scholar = evaluatedScholars[index];
                            return _buildStatisticsScholarCard(scholar, isEvaluated: true);
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showProgressScholarsAlert() {
    List<dynamic> progressScholars = _assignedScholars.where((scholar) {
      double progressPercentage = double.tryParse(scholar['ProgressPercentage']?.toString() ?? '0') ?? 0;
      return progressPercentage > 0;
    }).toList();

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
              maxWidth: 600,
              maxHeight: 700,
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.trending_up,
                        color: Colors.orange[700],
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          "Scholars With Progress",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                        color: Colors.grey[600],
                      ),
                    ],
                  ),
                ),
                
                // Content
                Expanded(
                  child: progressScholars.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.trending_up_outlined,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "No Progress Yet",
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "No scholars have made progress on their duties yet",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: progressScholars.length,
                          itemBuilder: (context, index) {
                            var scholar = progressScholars[index];
                            return _buildStatisticsScholarCard(scholar, isEvaluated: false);
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showNoProgressScholarsAlert() {
    List<dynamic> noProgressScholars = _assignedScholars.where((scholar) {
      double progressPercentage = double.tryParse(scholar['ProgressPercentage']?.toString() ?? '0') ?? 0;
      return progressPercentage == 0;
    }).toList();

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
              maxWidth: 600,
              maxHeight: 700,
            ),
            child: Column(
              children: [
                // Header
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                        Icons.trending_down,
                        color: Colors.red[700],
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          "Scholars Without Progress",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                        color: Colors.grey[600],
                      ),
                    ],
                  ),
                ),
                
                // Content
                Expanded(
                  child: noProgressScholars.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.trending_down_outlined,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "All Scholars Have Progress",
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "All scholars have made progress on their duties",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: noProgressScholars.length,
                          itemBuilder: (context, index) {
                            var scholar = noProgressScholars[index];
                            return _buildStatisticsScholarCard(scholar, isEvaluated: false);
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatisticsScholarCard(Map<String, dynamic> scholar, {required bool isEvaluated}) {
    String fullname = scholar['Fullname'] ?? 'Unknown Scholar';
    String studEmail = scholar['stud_email'] ?? '';
    String studContact = scholar['stud_contactNumber'] ?? '';
    String assignmentName = scholar['assignment_name'] ?? 'Unknown Assignment';
    double progressPercentage = double.tryParse(scholar['ProgressPercentage']?.toString() ?? '0') ?? 0;
    String evaluationStatus = scholar['assign_evaluation_status']?.toString() ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: isEvaluated ? Colors.green : Colors.blue,
                  child: Icon(
                    isEvaluated ? Icons.check_circle : Icons.person,
                    color: Colors.white,
                                  size: 20,
                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        Text(
                          fullname,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          assignmentName,
                                    style: TextStyle(
                                      fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                if (isEvaluated)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "Evaluated",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green[800],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.email, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    studEmail,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                            ),
                          ),
                      ],
                    ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  studContact,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            if (!isEvaluated) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.trending_up, size: 16, color: Colors.blue[600]),
                  const SizedBox(width: 8),
                  Text(
                    "Progress: ${progressPercentage.toStringAsFixed(1)}%",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[600],
                      fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
            ],
          ],
        ),
      ),
    );
  }
}
