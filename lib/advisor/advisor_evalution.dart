import 'dart:convert';
import 'package:csdl_mobile/advisor/advisor_drawer.dart';
import 'package:csdl_mobile/session_storage.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AdvisorEvaluation extends StatefulWidget {
  final String advisor_id;
  final String scholar_id;
  final String supervisor_id;
  const AdvisorEvaluation(
      {super.key,
      required this.advisor_id,
      required this.scholar_id,
      required this.supervisor_id});

  @override
  _AdvisorEvaluationState createState() => _AdvisorEvaluationState();
}

class _AdvisorEvaluationState extends State<AdvisorEvaluation> {
  final Map<String, int?> selectedValuesPerformance = {};
  final Map<String, int?> selectedValuesGeneral = {};
  final Map<String, int?> selectedValuesAttendance = {};

  List<String> performanceQuestions = [];
  List<String> generalQuestions = [];
  List<String> attendanceQuestions = [];

  int currentStep = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchEvaluationQuestions();
  }

  Future<void> fetchEvaluationQuestions() async {
    try {
      final response = await http.post(
        Uri.parse("${SessionStorage.url}transaction.php"),
        body: {
          "operation": "getEvaluationSfQuestions",
        },
      );

      final List<dynamic> data = jsonDecode(response.body);
      print("Raw data: $data");

      if (data.isNotEmpty && data is List) {
        List<String> perf = [];
        List<String> general = [];
        List<String> attendance = [];

        for (var item in data) {
          String type = item['evaluation_sf_questions_types_names'];
          String question = item['evaluation_sf_questions_question'];

          switch (type) {
            case "Performance":
              perf.add(question);
              break;
            case "General Attributes":
              general.add(question);
              break;
            case "Attendance":
              attendance.add(question);
              break;
          }
        }

        setState(() {
          performanceQuestions = perf;
          generalQuestions = general;
          attendanceQuestions = attendance;

          for (int i = 0; i < performanceQuestions.length; i++) {
            selectedValuesPerformance["${i + 1}"] = null;
          }
          for (int i = 0; i < generalQuestions.length; i++) {
            selectedValuesGeneral["${i + 1}"] = null;
          }
          for (int i = 0; i < attendanceQuestions.length; i++) {
            selectedValuesAttendance["${i + 1}"] = null;
          }

          isLoading = false;
        });
      } else {
        throw Exception("Invalid response format.");
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading questions: $e")),
      );
      print("Error loading questions: $e");
    }
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
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20), // Space for app bar
                    if (currentStep == 0) ...[
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
                                    Icons.assessment,
                                    color: Colors.green[700],
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                const Expanded(
                                  child: Text(
                                    "Performance Evaluation",
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
                              "Please rate the student's performance in the following areas:",
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
                            children: List.generate(performanceQuestions.length, (index) {
                              final key = "${index + 1}";
                              return buildQuestionRow(
                                performanceQuestions[index],
                                key,
                                selectedValuesPerformance,
                              );
                            }),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Next Button
                      Container(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              currentStep = 1;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[700],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                "Continue to General Attributes",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ] else if (currentStep == 1) ...[
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
                                    color: Colors.blue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.person,
                                    color: Colors.blue[700],
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                const Expanded(
                                  child: Text(
                                    "General Attributes",
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
                              "Please evaluate the student's general attributes and behavior:",
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
                            children: List.generate(generalQuestions.length, (index) {
                              final key = "${index + 1}";
                              return buildQuestionRow(
                                generalQuestions[index],
                                key,
                                selectedValuesGeneral,
                              );
                            }),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Navigation Buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  currentStep = 0;
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey[600],
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.arrow_back, size: 20),
                                  const SizedBox(width: 8),
                                  const Text(
                                    "Back",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  currentStep = 2;
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green[700],
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 4,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    "Continue to Attendance",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.arrow_forward, size: 20),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ] else if (currentStep == 2) ...[
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
                                    color: Colors.orange.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.schedule,
                                    color: Colors.orange[700],
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                const Expanded(
                                  child: Text(
                                    "Attendance Evaluation",
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
                              "Please rate the student's attendance and punctuality:",
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
                            children: List.generate(attendanceQuestions.length, (index) {
                              final key = "${index + 1}";
                              return buildQuestionRow(
                                attendanceQuestions[index],
                                key,
                                selectedValuesAttendance,
                              );
                            }),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Navigation Buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  currentStep = 1;
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey[600],
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.arrow_back, size: 20),
                                  const SizedBox(width: 8),
                                  const Text(
                                    "Back",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
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
                        ],
                      ),
                    ],
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
      int totalPerformance = calculateTotal(selectedValuesPerformance);
      int totalGeneral = calculateTotal(selectedValuesGeneral);
      int totalAttendance = calculateTotal(selectedValuesAttendance);
      int overall = totalPerformance + totalGeneral + totalAttendance;

      var url = Uri.parse("${SessionStorage.url}transaction.php");

      Map<String, dynamic> jsonData = {
        "evaluation_sf_supM_id": widget.supervisor_id,
        "evaluation_sf_assign_stud_id": widget.scholar_id,
        "evaluation_sf_total_perfomance": totalPerformance,
        "evaluation_sf_total_general_attributes": totalGeneral,
        "evaluation_sf_attendance": totalAttendance,
        "evaluation_sf_overall_score": overall,
      };

      Map<String, String> requestBody = {
        "json": jsonEncode(jsonData),
        "operation": "submitStudentFacilitatorEvaluation",
      };

      var response = await http.post(url, body: requestBody);
      var res = jsonDecode(response.body);

      if (res == 1) {
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
}
