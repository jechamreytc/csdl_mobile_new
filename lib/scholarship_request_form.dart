import 'dart:convert';
import 'package:csdl_mobile/session_storage.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ScholarshipRequestForm extends StatefulWidget {
  const ScholarshipRequestForm({super.key});

  @override
  State<ScholarshipRequestForm> createState() => _ScholarshipRequestFormState();
}

class _ScholarshipRequestFormState extends State<ScholarshipRequestForm> {
  final TextEditingController _studIdController = TextEditingController();
  final TextEditingController _fullnameController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();

  List<dynamic> _statuses = [];
  List<dynamic> _sessions = [];
  List<dynamic> _courses = [];

  String? selectedStatus;
  String? selectedSession;
  String? selectedCourse;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchStudentStatuses();
    fetchAcademicSessions();
    fetchCourses();
  }

  // ✅ GET without JSON
  void fetchStudentStatuses() async {
    try {
      var url = Uri.parse("${SessionStorage.url}assign.php");
      var response = await http.post(url, body: {
        "operation": "getStudStatus",
      });
      var res = jsonDecode(response.body);

      if (res is List) {
        setState(() {
          _statuses = res;
        });
      } else {
        print("Invalid student status response: $res");
      }
    } catch (e) {
      print("Error fetching student statuses: $e");
    }
  }

  void fetchAcademicSessions() async {
    try {
      var url = Uri.parse("${SessionStorage.url}assign.php");
      var response = await http.post(url, body: {
        "operation": "getSessionAcademicFiltered",
      });
      var res = jsonDecode(response.body);

      if (res is List) {
        setState(() {
          _sessions = res;
        });
      } else {
        print("Invalid academic session response: $res");
      }
    } catch (e) {
      print("Error fetching academic sessions: $e");
    }
  }

  void fetchCourses() async {
    try {
      var url = Uri.parse("${SessionStorage.url}CSDL.php");
      var response = await http.post(url, body: {
        "operation": "getcourse",
      });
      var res = jsonDecode(response.body);

      if (res is List) {
        setState(() {
          _courses = res;
        });
      } else {
        print("Invalid course response: $res");
      }
    } catch (e) {
      print("Error fetching courses: $e");
    }
  }

  // ✅ Only POST with JSON
  void submitScholarshipRequest() async {
    String studId = _studIdController.text.trim();
    String fullname = _fullnameController.text.trim();
    String reason = _reasonController.text.trim();

    if ([
      studId,
      fullname,
      reason,
      selectedStatus,
      selectedSession,
      selectedCourse
    ].any((e) => e == null || e.toString().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("All fields are required.")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      var url = Uri.parse("${SessionStorage.url}assign.php");
      Map<String, dynamic> jsonData = {
        "scholarship_stud_id": studId,
        "scholarship_request_fullname": fullname,
        "scholarship_request_description": reason,
        "scholarship_student_status_id": selectedStatus,
        "scholarship_request_academic_session_id": selectedSession,
        "scholarship_request_course_id": selectedCourse,
      };

      var response = await http.post(url, body: {
        "operation": "scholarshipRequest",
        "json": jsonEncode(jsonData),
      });

      if (response.body != '0') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Request submitted successfully.")),
        );
        _studIdController.clear();
        _fullnameController.clear();
        _reasonController.clear();
        setState(() {
          selectedStatus = null;
          selectedSession = null;
          selectedCourse = null;
        });
      } else {
        throw Exception("Submission failed");
      }
    } catch (e) {
      print("Submission error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Submission failed.")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scholarship Request")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextField(
              controller: _studIdController,
              decoration: const InputDecoration(labelText: "Scholar ID"),
            ),
            TextField(
              controller: _fullnameController,
              decoration: const InputDecoration(labelText: "Scholar Name"),
            ),
            TextField(
              controller: _reasonController,
              decoration:
                  const InputDecoration(labelText: "Reason for Stopping"),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            DropdownButton<String>(
              hint: const Text("Select Student Status"),
              value: selectedStatus,
              isExpanded: true,
              onChanged: (value) => setState(() => selectedStatus = value),
              items: _statuses.map<DropdownMenuItem<String>>((item) {
                return DropdownMenuItem(
                  value: item['status_id'].toString(),
                  child: Text(item['status_name'] ?? 'Unknown'),
                );
              }).toList(),
            ),
            DropdownButton<String>(
              hint: const Text("Select Academic Session"),
              value: selectedSession,
              isExpanded: true,
              onChanged: (value) => setState(() => selectedSession = value),
              items: _sessions.map<DropdownMenuItem<String>>((item) {
                return DropdownMenuItem(
                  value: item['session_id'].toString(),
                  child: Text(item['session_name'] ?? 'Unknown'),
                );
              }).toList(),
            ),
            DropdownButton<String>(
              hint: const Text("Select Course"),
              value: selectedCourse,
              isExpanded: true,
              onChanged: (value) => setState(() => selectedCourse = value),
              items: _courses.map<DropdownMenuItem<String>>((item) {
                return DropdownMenuItem(
                  value: item['course_id'].toString(),
                  child: Text(item['course_name'] ?? 'Unknown'),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isLoading ? null : submitScholarshipRequest,
              child: isLoading
                  ? const CircularProgressIndicator()
                  : const Text("Submit"),
            ),
          ],
        ),
      ),
    );
  }
}
