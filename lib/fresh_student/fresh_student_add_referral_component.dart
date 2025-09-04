import 'dart:convert';
import 'package:csdl_mobile/fresh_student/fresh_student_drawer.dart';
import 'package:csdl_mobile/session_storage.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class FreshStudentAddReferralComponent extends StatefulWidget {
  final String student_id;
  const FreshStudentAddReferralComponent({
    Key? key,
    required this.student_id,
  }) : super(key: key);

  @override
  _FreshStudentAddReferralComponentState createState() =>
      _FreshStudentAddReferralComponentState();
}

class _FreshStudentAddReferralComponentState
    extends State<FreshStudentAddReferralComponent> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController middleNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController contactNumberController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController shsSchoolController = TextEditingController();

  List<String> referrals = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: FreshStudentDrawer(student_id: widget.student_id),
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green.shade50, Colors.green.shade200],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Card(
            color: Colors.white,
            elevation: 4,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      "Referral Information",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildTextField("Last Name", lastNameController),
                    _buildTextField("First Name", firstNameController),
                    _buildTextField("Middle Name", middleNameController),
                    _buildTextField("Contact Number", contactNumberController,
                        prefixText: "+63"),
                    _buildTextField("Email Address", emailController,
                        keyboardType: TextInputType.emailAddress),
                    _buildTextField("Address", addressController),
                    _buildTextField("SHS School Name", shsSchoolController),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF104038),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          addReferral();
                        }
                      },
                      child: const Text(
                        " Add HK Lead",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {TextInputType keyboardType = TextInputType.text, String? prefixText}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Color(0xFF104038)),
          filled: true,
          fillColor: Colors.green.shade50,
          prefixText: prefixText,
          prefixStyle: const TextStyle(color: Color(0xFF104038)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF104038)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF104038), width: 2),
          ),
        ),
        validator: (value) =>
            value == null || value.isEmpty ? 'Required' : null,
      ),
    );
  }

  void addReferral() async {
    try {
      var url = Uri.parse("${SessionStorage.url}transaction.php");

      Map<String, dynamic> jsonData = {
        "freshmen_ref_scholar_id": widget.student_id,
        "freshmen_ref_lastname": lastNameController.text.trim(),
        "freshmen_ref_firstname": firstNameController.text.trim(),
        "freshmen_ref_middle_name": middleNameController.text.trim(),
        "freshmen_ref_contact_number": contactNumberController.text.trim(),
        "freshmen_ref_email_add": emailController.text.trim(),
        "freshmen_ref_address": addressController.text.trim(),
        "freshmen_ref_shs_school": shsSchoolController.text.trim(),
      };

      Map<String, String> requestBody = {
        "operation": "addFreshmenReferral",
        "json": jsonEncode(jsonData),
      };

      var response = await http.post(url, body: requestBody);
      var res = jsonDecode(response.body);

      if (response.statusCode == 200 && res != 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Referral added successfully!")),
        );
        _formKey.currentState?.reset();
        getAllReferrals();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to add referral.")),
        );
      }

      print("Add Referral Response: $res");
    } catch (e) {
      print("Error adding referral: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
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
}
