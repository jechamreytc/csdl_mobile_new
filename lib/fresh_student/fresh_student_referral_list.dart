import 'dart:convert';
import 'package:csdl_mobile/fresh_student/fresh_student_add_referral_component.dart';
import 'package:csdl_mobile/fresh_student/fresh_student_drawer.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:csdl_mobile/session_storage.dart';

class FreshStudentReferralList extends StatefulWidget {
  final String student_id;
  const FreshStudentReferralList({Key? key, required this.student_id})
      : super(key: key);

  @override
  _FreshStudentReferralListState createState() =>
      _FreshStudentReferralListState();
}

class _FreshStudentReferralListState extends State<FreshStudentReferralList> {
  List<Map<String, dynamic>> referrals = [];
  int maxReferrals = 5;
  int approvedCount = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    getReferralStatusList();
  }

  void getReferralStatusList() async {
    try {
      var url = Uri.parse("${SessionStorage.url}transaction.php");
      Map<String, dynamic> jsonData = {
        "stud_active_id": widget.student_id,
      };

      Map<String, String> requestBody = {
        "operation": "getReferralStatusList",
        "json": jsonEncode(jsonData),
      };

      var response = await http.post(url, body: requestBody);
      var res = jsonDecode(response.body);

      if (response.statusCode == 200) {
        
        if (res is List) {
          // Handle case where API returns array directly
          setState(() {
            referrals = List<Map<String, dynamic>>.from(res);
            approvedCount = referrals.where((ref) => ref['freshmen_ref_status'] == 1).length;
            isLoading = false;
          });
        } else if (res is Map && res['success'] == true) {
          // Handle case where API returns object with success flag
          setState(() {
            referrals = List<Map<String, dynamic>>.from(res['referrals']);
            approvedCount = referrals.where((ref) => ref['freshmen_ref_status'] == 1).length;
            isLoading = false;
          });
        } else {
          // Handle case where API returns data but not in expected format
        setState(() {
            referrals = [];
            approvedCount = 0;
            isLoading = false;
        });
        }
      } else {
        print("Failed to load referrals. Status code: ${response.statusCode}");
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching referral status list: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    int remainingLeads = maxReferrals - referrals.length;

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
      drawer: FreshStudentDrawer(
          student_id: widget.student_id, currentIndex: 1),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            isLoading = true;
          });
          getReferralStatusList();
        },
        backgroundColor: const Color(0xFF104038),
        child: const Icon(Icons.refresh, color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green.shade50, Colors.green.shade200],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
                    // Progress Summary Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF104038),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                                "HK Leads Progress",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                                "$approvedCount / $maxReferrals approved",
                          style: const TextStyle(
                                  color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                          const SizedBox(height: 8),
                          Text(
                            "Total Referrals: ${referrals.length}",
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Referral List
                    Expanded(
                      child: referrals.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.people_outline,
                                    size: 64,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    "No referrals yet",
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "Add your first referral to get started",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: referrals.length,
                              itemBuilder: (context, index) {
                                final referral = referrals[index];
                                final status = referral['freshmen_ref_status'];
                                final name = "${referral['freshmen_ref_firstname']} ${referral['freshmen_ref_middle_name']} ${referral['freshmen_ref_lastname']}";
                                final email = referral['freshmen_ref_email_add'] ?? '';
                                final contact = referral['freshmen_ref_contact_number'] ?? '';
                                
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                name,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 6,
                                              ),
                                              decoration: BoxDecoration(
                                                color: status == 1
                                                    ? Colors.green.shade100
                                                    : status == 0
                                                        ? Colors.orange.shade100
                                                        : Colors.red.shade100,
                                                borderRadius: BorderRadius.circular(20),
                                                border: Border.all(
                                                  color: status == 1
                                                      ? Colors.green
                                                      : status == 0
                                                          ? Colors.orange
                                                          : Colors.red,
                                                  width: 1,
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    status == 1
                                                        ? Icons.check_circle
                                                        : status == 0
                                                            ? Icons.pending
                                                            : Icons.cancel,
                                                    size: 16,
                                                    color: status == 1
                                                        ? Colors.green
                                                        : status == 0
                                                            ? Colors.orange
                                                            : Colors.red,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    status == 1
                                                        ? "Approved"
                                                        : status == 0
                                                            ? "Pending"
                                                            : "Declined",
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.bold,
                                                      color: status == 1
                                                          ? Colors.green
                                                          : status == 0
                                                              ? Colors.orange
                                                              : Colors.red,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (email.isNotEmpty) ...[
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Icon(Icons.email, size: 16, color: Colors.grey.shade600),
                                              const SizedBox(width: 8),
                                              Text(
                                                email,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey.shade600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                        if (contact.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(Icons.phone, size: 16, color: Colors.grey.shade600),
                                              const SizedBox(width: 8),
                                              Text(
                                                contact,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey.shade600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                        const SizedBox(height: 12),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              "ID: ${referral['freshmen_ref_id']}",
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade500,
                                              ),
                                            ),
                                            TextButton.icon(
                                              onPressed: () => _showReferralDetails(referral['freshmen_ref_id']),
                                              icon: Icon(
                                                Icons.info_outline,
                                                size: 16,
                                                color: const Color(0xFF104038),
                                              ),
                                              label: Text(
                                                "View Details",
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: const Color(0xFF104038),
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                  ],
                ),
              ),
                                );
                              },
                            ),
                    ),
                    
                    // Add Referral Button
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FreshStudentAddReferralComponent(
                        student_id: widget.student_id,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF104038),
                          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 6,
                ),
                child: const Text(
                  "Add Referral",
                  style: TextStyle(color: Colors.white),
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }


  void _showReferralDetails(int referralId) async {
    print("Fetching details for referral ID: $referralId");
    
    try {
      var url = Uri.parse("${SessionStorage.url}transaction.php");
      Map<String, dynamic> jsonData = {
        "referral_id": referralId,
      };

      Map<String, String> requestBody = {
        "operation": "getReferralApprovalDetails",
        "json": jsonEncode(jsonData),
      };

      print("API Request: $requestBody");
      var response = await http.post(url, body: requestBody);
      print("API Response Status: ${response.statusCode}");
      print("API Response Body: ${response.body}");
      
      var res = jsonDecode(response.body);

      if (response.statusCode == 200 && res['success'] == true) {
        print("Successfully fetched referral details: ${res['referral']}");
        _showDetailsDialog(res['referral']);
      } else {
        print("API returned error: ${res['error'] ?? 'Unknown error'}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to load referral details: ${res['error'] ?? 'Unknown error'}")),
        );
      }
    } catch (e) {
      print("Error fetching referral details: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading details: $e")),
      );
    }
  }

  void _showDetailsDialog(Map<String, dynamic> referral) {
    final status = referral['freshmen_ref_status'];
    final name = "${referral['freshmen_ref_firstname']} ${referral['freshmen_ref_middle_name']} ${referral['freshmen_ref_lastname']}";
    final email = referral['freshmen_ref_email_add'] ?? '';
    final contact = referral['freshmen_ref_contact_number'] ?? '';
    final address = referral['freshmen_ref_address'] ?? '';
    final school = referral['freshmen_ref_shs_school'] ?? '';
    final referralId = referral['freshmen_ref_id'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Referral Details"),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Name and Status
              Row(
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: status == 1
                          ? Colors.green.shade100
                          : status == 0
                              ? Colors.orange.shade100
                              : Colors.red.shade100,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: status == 1
                            ? Colors.green
                            : status == 0
                                ? Colors.orange
                                : Colors.red,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          status == 1
                              ? Icons.check_circle
                              : status == 0
                                  ? Icons.pending
                                  : Icons.cancel,
                          size: 16,
                          color: status == 1
                              ? Colors.green
                              : status == 0
                                  ? Colors.orange
                                  : Colors.red,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          status == 1
                              ? "Approved"
                              : status == 0
                                  ? "Pending"
                                  : "Declined",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: status == 1
                                ? Colors.green
                                : status == 0
                                    ? Colors.orange
                                    : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Contact Information
              if (email.isNotEmpty) ...[
                _buildInfoRow(Icons.email, "Email", email),
                const SizedBox(height: 8),
              ],
              if (contact.isNotEmpty) ...[
                _buildInfoRow(Icons.phone, "Contact", contact),
                const SizedBox(height: 8),
              ],
              if (address.isNotEmpty) ...[
                _buildInfoRow(Icons.location_on, "Address", address),
                const SizedBox(height: 8),
              ],
              if (school.isNotEmpty) ...[
                _buildInfoRow(Icons.school, "SHS School", school),
                const SizedBox(height: 8),
              ],
              
              // Referral ID
              _buildInfoRow(Icons.tag, "Referral ID", referralId.toString()),
              
              // Status Information
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: status == 1 
                      ? Colors.green.shade50 
                      : status == 0 
                          ? Colors.orange.shade50 
                          : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: status == 1 
                        ? Colors.green.shade200 
                        : status == 0 
                            ? Colors.orange.shade200 
                            : Colors.red.shade200,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Status Information",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: status == 1 
                            ? Colors.green.shade700 
                            : status == 0 
                                ? Colors.orange.shade700 
                                : Colors.red.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      status == 1 
                          ? "✅ This referral has been approved and counts toward your progress."
                          : status == 0 
                              ? "⏳ This referral is pending admin review."
                              : "❌ This referral was declined and does not count toward your progress.",
                      style: TextStyle(
                        fontSize: 12,
                        color: status == 1 
                            ? Colors.green.shade700 
                            : status == 0 
                                ? Colors.orange.shade700 
                                : Colors.red.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text("Close"),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text(
          "$label: ",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade700,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ),
      ],
    );
  }
}
