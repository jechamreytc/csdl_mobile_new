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

  // âœ… GET without JSON
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

  // âœ… Only POST with JSON
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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          "Scholarship Request",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF104038),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF104038),
              Color(0xFFF8FAFC),
            ],
            stops: [0.0, 0.3],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF104038).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.school,
                        size: 48,
                        color: Color(0xFF104038),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Scholarship Request Form",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF104038),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Please fill out all required information to submit your scholarship request",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Form Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Personal Information",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF104038),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Scholar ID Field
                    _buildStyledTextField(
                      controller: _studIdController,
                      label: "Scholar ID",
                      icon: Icons.badge,
                      hint: "Enter your scholar ID",
                    ),
                    const SizedBox(height: 16),
                    
                    // Scholar Name Field
                    _buildStyledTextField(
                      controller: _fullnameController,
                      label: "Scholar Name",
                      icon: Icons.person,
                      hint: "Enter your full name",
                    ),
                    const SizedBox(height: 16),
                    
                    // Reason Field
                    _buildStyledTextField(
                      controller: _reasonController,
                      label: "Reason for Stopping",
                      icon: Icons.description,
                      hint: "Please provide a detailed reason",
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),
                    
                    const Text(
                      "Academic Information",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF104038),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Student Status Dropdown
                    _buildStyledDropdown(
                      hint: "Select Student Status",
                      value: selectedStatus,
                      onChanged: (value) => setState(() => selectedStatus = value),
                      items: _statuses.map<DropdownMenuItem<String>>((item) {
                        return DropdownMenuItem(
                          value: item['status_id'].toString(),
                          child: Text(item['status_name'] ?? 'Unknown'),
                        );
                      }).toList(),
                      icon: Icons.school,
                    ),
                    const SizedBox(height: 16),
                    
                    // Academic Session Dropdown
                    _buildStyledDropdown(
                      hint: "Select Academic Session",
                      value: selectedSession,
                      onChanged: (value) => setState(() => selectedSession = value),
                      items: _sessions.map<DropdownMenuItem<String>>((item) {
                        return DropdownMenuItem(
                          value: item['session_id'].toString(),
                          child: Text(item['session_name'] ?? 'Unknown'),
                        );
                      }).toList(),
                      icon: Icons.calendar_today,
                    ),
                    const SizedBox(height: 16),
                    
                    // Course Dropdown
                    _buildStyledDropdown(
                      hint: "Select Course",
                      value: selectedCourse,
                      onChanged: (value) => setState(() => selectedCourse = value),
                      items: _courses.map<DropdownMenuItem<String>>((item) {
                        return DropdownMenuItem(
                          value: item['course_id'].toString(),
                          child: Text(item['course_name'] ?? 'Unknown'),
                        );
                      }).toList(),
                      icon: Icons.menu_book,
                    ),
                    const SizedBox(height: 32),
                    
                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : submitScholarshipRequest,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF104038),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.send, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    "Submit Request",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
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

  Widget _buildStyledTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: const Color(0xFF104038)),
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF104038), width: 2),
          ),
          labelStyle: const TextStyle(color: Color(0xFF104038)),
        ),
      ),
    );
  }

  Widget _buildStyledDropdown({
    required String hint,
    required String? value,
    required Function(String?) onChanged,
    required List<DropdownMenuItem<String>> items,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        hint: Text(hint),
        value: value,
        isExpanded: true,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: const Color(0xFF104038)),
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF104038), width: 2),
          ),
        ),
        onChanged: onChanged,
        items: items,
      ),
    );
  }
}
