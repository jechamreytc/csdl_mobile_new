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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      drawer: FreshStudentDrawer(
        student_id: widget.student_id,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTextField("Last Name", lastNameController),
              _buildTextField("First Name", firstNameController),
              _buildTextField("Middle Name", middleNameController),
              _buildTextField("Contact Number", contactNumberController,
                  prefixText: "+63"),
              _buildTextField("Email Address", emailController,
                  keyboardType: TextInputType.emailAddress),
              _buildTextField("Address", addressController),
              _buildTextField("SHS School Name", shsSchoolController),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF104038),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    addReferral();
                  }
                },
                child: const Text("ADD HK LEAD",
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {TextInputType keyboardType = TextInputType.text, String? prefixText}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: const Color(0xFF104038),
          labelStyle: const TextStyle(color: Colors.white),
          prefixText: prefixText,
          prefixStyle: const TextStyle(color: Colors.white),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        style: const TextStyle(color: Colors.white),
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
