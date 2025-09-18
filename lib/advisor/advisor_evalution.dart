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
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade50, Colors.green.shade200],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Stack(
                children: [
                  Image.asset(
                    'assets/images/csdl_background.jpg',
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    alignment: Alignment.topLeft,
                  ),
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color.fromRGBO(255, 255, 255, 0.95),
                          Color.fromRGBO(255, 255, 255, 0.95),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                        top: kToolbarHeight + 8, left: 23.0, right: 23.0),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (currentStep == 0) ...[
                            const Text("Performance",
                                style: TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 10),
                            ...List.generate(performanceQuestions.length,
                                (index) {
                              final key = "${index + 1}";
                              return buildQuestionRow(
                                  performanceQuestions[index],
                                  key,
                                  selectedValuesPerformance);
                            }),
                            Center(
                              child: ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    currentStep = 1;
                                  });
                                },
                                child: const Text("Next"),
                              ),
                            ),
                          ] else if (currentStep == 1) ...[
                            const Text("General Attributes",
                                style: TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 10),
                            ...List.generate(generalQuestions.length, (index) {
                              final key = "${index + 1}";
                              return buildQuestionRow(generalQuestions[index],
                                  key, selectedValuesGeneral);
                            }),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      currentStep = 0;
                                    });
                                  },
                                  child: const Text("Back"),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      currentStep = 2;
                                    });
                                  },
                                  child: const Text("Next"),
                                ),
                              ],
                            ),
                          ] else if (currentStep == 2) ...[
                            const Text("Attendance",
                                style: TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 10),
                            ...List.generate(attendanceQuestions.length,
                                (index) {
                              final key = "${index + 1}";
                              return buildQuestionRow(
                                  attendanceQuestions[index],
                                  key,
                                  selectedValuesAttendance);
                            }),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      currentStep = 1;
                                    });
                                  },
                                  child: const Text("Back"),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    submitStudentEvaluation();
                                  },
                                  child: const Text("Submit"),
                                ),
                              ],
                            ),
                          ]
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget buildQuestionRow(
      String question, String key, Map<String, int?> selectedValues) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: const TextStyle(
                fontSize: 10, fontWeight: FontWeight.w500, height: 1.5),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(5, (index) {
              return Row(
                children: [
                  Radio<int>(
                    value: index + 1,
                    groupValue: selectedValues[key],
                    onChanged: (value) {
                      setState(() {
                        selectedValues[key] = value;
                      });
                    },
                  ),
                  Text((index + 1).toString(),
                      style: const TextStyle(fontSize: 10)),
                ],
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Evaluation submitted successfully!')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Submission failed. Please try again.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error submitting evaluation: $e")),
      );
    }
  }
}
