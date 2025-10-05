import 'dart:convert';
import 'package:csdl_mobile/advisor/advisor_drawer.dart';
import 'package:csdl_mobile/advisor/advisor_evaluation_office.dart';
import 'package:csdl_mobile/advisor/advisor_evalution.dart';
// import 'package:csdl_mobile/advisor/advisor_evaluation_office.dart';
// import 'package:csdl_mobile/advisor/advisor_evalution.dart';
import 'package:csdl_mobile/session_storage.dart';
// import 'package:csdl_mobile/advisor/advisor_edit_profile.dart';
// import 'package:csdl_mobile/advisor/advisor_qr_scanner.dart';
import 'package:flutter/material.dart';
// import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:http/http.dart' as http;

class AdvisorScholarList extends StatefulWidget {
  final String advisor_id;
  final String supervisor_id;
  const AdvisorScholarList({
    super.key,
    required this.advisor_id,
    required this.supervisor_id,
  });

  @override
  _AdvisorScholarListState createState() => _AdvisorScholarListState();
}

class _AdvisorScholarListState extends State<AdvisorScholarList> {
  List<dynamic> scholars = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    getAssignedScholars();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
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
        currentIndex: 1,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green.shade50, Colors.green.shade200],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 70), // Space for app bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.1),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.people,
                        color: Colors.green[700],
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        "Assigned Scholars",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${scholars.length}',
                        style: TextStyle(
                          color: Colors.green[800],
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Scholars List
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.1),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: isLoading
                    ? Container(
                        height: 200,
                        child: const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                          ),
                        ),
                      )
                    : scholars.isNotEmpty
                        ? ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: scholars.length,
                            itemBuilder: (context, index) {
                              final scholar = scholars[index];
                              return _buildScholarCard(scholar, index);
                            },
                          )
                        : Container(
                            height: 200,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.people_outline,
                                    size: 48,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    errorMessage.isNotEmpty
                                        ? errorMessage
                                        : 'No scholars found.',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 16,
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
              const SizedBox(height: 50), // Bottom padding to show background
            ],
          ),
        ),
      ),
    );
  }

  // Function to build individual scholar card
  Widget _buildScholarCard(Map<String, dynamic> scholar, int index) {
    bool isEvaluated = scholar['assign_evaluation_status'] == 1;
    bool canEvaluate = scholar['assign_render_status'] == 1;
    String assignmentType = scholar['assignment_name'] ?? 'Office';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.green.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.05),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with name and status
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: assignmentType == 'Office' 
                        ? Colors.blue.withOpacity(0.1) 
                        : Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    assignmentType == 'Office' ? Icons.business : Icons.school,
                    color: assignmentType == 'Office' ? Colors.blue[700] : Colors.green[700],
                    size: 16,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        scholar['Fullname'] ?? 'Unknown',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        scholar['sub_code'] ?? 'Office',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: assignmentType == 'Office' 
                        ? Colors.blue[100] 
                        : Colors.green[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    assignmentType,
                    style: TextStyle(
                      color: assignmentType == 'Office' 
                          ? Colors.blue[800] 
                          : Colors.green[800],
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Details row
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    Icons.phone,
                    'Contact',
                    scholar['stud_contactNumber'] ?? 'N/A',
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    Icons.room,
                    'Room',
                    scholar['sub_room'] ?? 'N/A',
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Action row
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _showScholarDetailsDialog(scholar),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: Colors.green.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.green[700],
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Details',
                            style: TextStyle(
                              color: Colors.green[700],
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _buildEvaluationButton(scholar),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Function to build info item
  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: 12,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[700],
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Function to show scholar details dialog
  void _showScholarDetailsDialog(Map<String, dynamic> scholar) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.person,
              color: Colors.green[700],
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                scholar['Fullname'] ?? 'Unknown',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Section', scholar['sub_code'] ?? 'N/A'),
            _buildDetailRow('Contact', scholar['stud_contactNumber'] ?? 'N/A'),
            _buildDetailRow('Email', scholar['stud_email'] ?? 'N/A'),
            _buildDetailRow('Room', scholar['sub_room'] ?? 'N/A'),
            _buildDetailRow('Assignment', scholar['assignment_name'] ?? 'N/A'),
            if (scholar['sub_time'] != null)
              _buildDetailRow('Time', scholar['sub_time']),
          ],
        ),
        actions: [
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
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // Function to build detail row
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  // Function to build evaluation button based on student status
  Widget _buildEvaluationButton(Map<String, dynamic> scholar) {
    bool isEvaluated = scholar['assign_evaluation_status'] == 1;
    bool canEvaluate = scholar['assign_render_status'] == 1;
    
    if (isEvaluated) {
      // Student is already evaluated - show "Evaluated" status (not clickable)
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.green[600],
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.white,
              size: 12,
            ),
            const SizedBox(width: 4),
            const Text(
              "Evaluated",
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    } else if (canEvaluate) {
      // Student can be evaluated - show "Evaluate" button
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
        ),
        child: ElevatedButton(
          onPressed: () {
            _navigateToEvaluation(scholar);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green[700],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            elevation: 0,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.rate_review,
                size: 12,
                color: Colors.white,
              ),
              const SizedBox(width: 4),
              const Text(
                "Evaluate",
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      // Student cannot be evaluated yet - show disabled button
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.schedule,
              color: Colors.grey[600],
              size: 12,
            ),
            const SizedBox(width: 4),
            Text(
              "Evaluate",
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }
  }

  // Function to navigate to evaluation
  void _navigateToEvaluation(Map<String, dynamic> scholar) {
    final assignment = scholar['assignment_name'] ?? '';
    
    if (assignment == "Office") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AdvisorEvaluationOffice(
            advisor_id: widget.advisor_id,
            scholar_id: scholar['stud_active_id'].toString(),
            supervisor_id: widget.supervisor_id,
          ),
        ),
      ).then((_) {
        // Refresh the scholar list when returning from evaluation
        getAssignedScholars();
      });
    } else if (assignment == "Student Facilitator") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AdvisorEvaluation(
            advisor_id: widget.advisor_id,
            scholar_id: scholar['stud_active_id'].toString(),
            supervisor_id: widget.supervisor_id,
          ),
        ),
      ).then((_) {
        // Refresh the scholar list when returning from evaluation
        getAssignedScholars();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No evaluation available for this scholar."),
        ),
      );
    }
  }

  // Function to fetch assigned scholars
  void getAssignedScholars() async {
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
        print(res);
        print("supervisor id ni niya" + widget.supervisor_id);
        if (res != 0) {
          setState(() {
            scholars = res;
            isLoading = false;
          });
        } else {
          setState(() {
            isLoading = false;
            errorMessage = "No scholars assigned.";
          });
        }
      } else {
        setState(() {
          isLoading = false;
          errorMessage =
              "Failed to load scholars. Server returned status code: ${response.statusCode}.";
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = "An error occurred: $e";
      });
    }
  }
}
