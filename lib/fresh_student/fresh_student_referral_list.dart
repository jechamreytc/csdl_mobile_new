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
  List<String> referrals = [];
  int maxReferrals = 5;

  @override
  void initState() {
    super.initState();
    getAllReferrals();
  }

  void getAllReferrals() async {
    try {
      var url = Uri.parse("${SessionStorage.url}transaction.php");
      Map<String, dynamic> jsonData = {
        "stud_active_id": widget.student_id,
      };

      Map<String, String> requestBody = {
        "operation": "getAllReferrals",
        "json": jsonEncode(jsonData),
      };

      var response = await http.post(url, body: requestBody);
      var res = jsonDecode(response.body);

      if (response.statusCode == 200) {
        setState(() {
          referrals = List<String>.from(res.map((item) =>
              "${item['freshmen_ref_firstname']} ${item['freshmen_ref_middle_name']} ${item['freshmen_ref_lastname']}"));
        });

        print("All Referrals: $res");
      } else {
        print("Failed to load referrals. Status code: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching all referrals: $e");
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
          student_id: widget.student_id, currentIndex: 1), // Optional: replace with your drawer
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green.shade50, Colors.green.shade200],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF104038),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "HK Leads",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "$remainingLeads leads left",
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Referral list
                    ...referrals.map((name) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            name,
                            style: const TextStyle(color: Colors.white),
                          ),
                        )),
                  ],
                ),
              ),
              const Spacer(),
              ElevatedButton(
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
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
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
