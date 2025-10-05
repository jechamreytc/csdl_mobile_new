import 'dart:convert';
import 'package:csdl_mobile/advisor/advisor_drawer.dart';
import 'package:csdl_mobile/session_storage.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AdvisorEvaluationOffice extends StatefulWidget {
  final String advisor_id;
  final String scholar_id;
  final String supervisor_id;
  const AdvisorEvaluationOffice(
      {super.key,
      required this.advisor_id,
      required this.scholar_id,
      required this.supervisor_id});

  @override
  _AdvisorEvaluationOfficeState createState() =>
      _AdvisorEvaluationOfficeState();
}

class _AdvisorEvaluationOfficeState extends State<AdvisorEvaluationOffice> {
  final Map<String, int?> selectedValuesAreas = {};
  int currentStep = 0;
  List<dynamic> officeQuestions = []; // To hold fetched questions

  @override
  void initState() {
    super.initState();
    getEvaluationOfficeQuestions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      drawer: AdvisorDrawer(
        advisorId: widget.advisor_id,
        supervisor_id: widget.supervisor_id,
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
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20), // Space for app bar
              
              // Header Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
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
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.business,
                            color: Colors.green[700],
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Text(
                            "Office Evaluation",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Please evaluate the student's performance in office duties and responsibilities:",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Questions Section
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
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: List.generate(officeQuestions.length, (index) {
                      final question = officeQuestions[index];
                      final questionId = question['evaluation_office_questions_id'].toString();
                      final questionText = question['evaluation_office_questions_question'];

                      return buildQuestionRow(questionText, questionId, selectedValuesAreas);
                    }),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Submit Button
              Container(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    _showSubmitConfirmation();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A6312),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        "SUBMIT EVALUATION",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 20), // Bottom padding
            ],
          ),
        ),
      ),
    );
  }

  Widget buildQuestionRow(
      String question, String key, Map<String, int?> selectedValues) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 2.0),
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6.0),
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2F332D),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(5, (index) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 2.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Radio<int>(
                      value: index + 1,
                      groupValue: selectedValues[key],
                      onChanged: (value) {
                        setState(() {
                          selectedValues[key] = value;
                        });
                      },
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    Text(
                      (index + 1).toString(),
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  int calculateTotal(Map<String, int?> selectedValues) {
    return selectedValues.values
        .where((value) => value != null)
        .fold(0, (sum, value) => sum + value!);
  }

  void _showSubmitConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A6312),
        title: const Text(
          "Confirm Submission",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          "Are you sure you want to submit this evaluation? This action cannot be undone.",
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Cancel",
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              submitStudentEvaluation();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF1A6312),
            ),
            child: const Text("Submit"),
          ),
        ],
      ),
    );
  }

  void submitStudentEvaluation() async {
    try {
      int totalAreas = calculateTotal(selectedValuesAreas);

      var url = Uri.parse("${SessionStorage.url}transaction.php");
      Map<String, dynamic> jsonData = {
        "evaluation_office_supM_id": widget.supervisor_id,
        "evaluation_office_assign_stud_active_id": widget.scholar_id,
        "evaluation_office_assistant_score": totalAreas.toString(),
        "evaluation_office_assistant_strengths": "N/A",
        "evaluation_office_assistant_weaknesses": "N/A",
        "evaluation_office_ratings": totalAreas == 25
            ? "5"
            : totalAreas < 2.5
                ? "1"
                : ((totalAreas / (officeQuestions.length * 5)) * 5)
                    .toStringAsFixed(2),
      };

      Map<String, String> requestBody = {
        "json": jsonEncode(jsonData),
        "operation": "submitStudentEvaluationOffice",
      };

      var response = await http.post(url, body: requestBody);
      var res = jsonDecode(response.body);
      
      if (res != 0) {
        _showSuccessDialog();
      } else {
        _showErrorDialog("Failed to submit evaluation. Please try again.");
      }
    } catch (e) {
      _showErrorDialog("Error submitting evaluation: $e");
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A6312),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green[400], size: 28),
            const SizedBox(width: 8),
            const Text(
              "Evaluation Submitted",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: const Text(
          "The evaluation has been submitted successfully!",
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to scholar list
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF1A6312),
            ),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A6312),
        title: Row(
          children: [
            Icon(Icons.error, color: Colors.red[400], size: 28),
            const SizedBox(width: 8),
            const Text(
              "Error",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF1A6312),
            ),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void getEvaluationOfficeQuestions() async {
    try {
      var url = Uri.parse("${SessionStorage.url}transaction.php");
      Map<String, String> requestBody = {
        "operation": "getEvaluationOfficeQuestions",
      };
      var response = await http.post(url, body: requestBody);
      var res = jsonDecode(response.body);

      if (res != 0 && res is List) {
        setState(() {
          officeQuestions = res;
        });
        print(res);
        print("akwndjaw" + widget.supervisor_id);
      }
    } catch (e) {
      print("Error getting evaluation questions: $e");
    }
  }
}
