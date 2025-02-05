import 'dart:convert';
import 'package:csdl_mobile/session_storage.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AdvisorEvaluation extends StatefulWidget {
  final String advisor_id;
  final String scholar_id;
  const AdvisorEvaluation(
      {super.key, required this.advisor_id, required this.scholar_id});

  @override
  _AdvisorEvaluationState createState() => _AdvisorEvaluationState();
}

class _AdvisorEvaluationState extends State<AdvisorEvaluation> {
  final Map<String, int?> selectedValuesPerformance =
      {}; // Store selected values for Performance questions
  final Map<String, int?> selectedValuesGeneral =
      {}; // Store selected values for General Attributes questions
  final Map<String, int?> selectedValuesAttendance =
      {}; // Store selected values for Attendance questions

  int currentStep = 0; // To track the current step

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            if (currentStep == 0) ...[
              const Text(
                "Advisor Evaluation - Performance",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              buildQuestionRow(
                  "a. Evaluation 1", "a", selectedValuesPerformance),
              buildQuestionRow(
                  "b. Evaluation 2", "b", selectedValuesPerformance),
              buildQuestionRow(
                  "c. Evaluation 3", "c", selectedValuesPerformance),
              buildQuestionRow(
                  "d. Evaluation 4", "d", selectedValuesPerformance),
              buildQuestionRow(
                  "e. Evaluation 5", "e", selectedValuesPerformance),
              buildQuestionRow(
                  "f. Evaluation 6", "f", selectedValuesPerformance),
              buildQuestionRow(
                  "g. Evaluation 7", "g", selectedValuesPerformance),
              buildQuestionRow(
                  "h. Evaluation 8", "h", selectedValuesPerformance),
              buildQuestionRow(
                  "i. Evaluation 9", "i", selectedValuesPerformance),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    currentStep = 1;
                  });
                },
                child: const Text("Next"),
              ),
            ] else if (currentStep == 1) ...[
              const Text(
                "Advisor Evaluation - General Attributes",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              buildQuestionRow("a. Evaluation 1", "a", selectedValuesGeneral),
              buildQuestionRow("b. Evaluation 2", "b", selectedValuesGeneral),
              buildQuestionRow("c. Evaluation 3", "c", selectedValuesGeneral),
              buildQuestionRow("d. Evaluation 4", "d", selectedValuesGeneral),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    currentStep = 2;
                  });
                },
                child: const Text("Next"),
              ),
            ] else if (currentStep == 2) ...[
              const Text(
                "Advisor Evaluation - Attendance",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              buildQuestionRow(
                  "a. Evaluation 1", "a", selectedValuesAttendance),
              buildQuestionRow(
                  "b. Evaluation 2", "b", selectedValuesAttendance),
              buildQuestionRow(
                  "c. Evaluation 3", "c", selectedValuesAttendance),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  submitStudentEvaluation();
                },
                child: const Text("Submit"),
              ),
            ],
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

  // Function to calculate the total score for each category
  int calculateTotal(Map<String, int?> selectedValues) {
    return selectedValues.values
        .where((value) => value != null)
        .fold(0, (sum, value) => sum + value!);
  }

  void submitStudentEvaluation() async {
    try {
      // Calculate the totals for each category
      int totalPerformance = calculateTotal(selectedValuesPerformance);
      int totalGeneral = calculateTotal(selectedValuesGeneral);
      int totalAttendance = calculateTotal(selectedValuesAttendance);

      var url = Uri.parse("${SessionStorage.url}transaction.php");
      Map<String, dynamic> jsonData = {
        "evaluation_sf_supM_id": widget.advisor_id,
        "evaluation_sf_assign_stud_id": widget.scholar_id,
        "evaluation_sf_total_perfomance": totalPerformance,
        "evaluation_sf_total_general_attributes": totalGeneral,
        "evaluation_sf_attendance": totalAttendance,
        "evaluation_sf_overall_score": totalPerformance +
            totalGeneral +
            totalAttendance, // Sum of all categories
      };

      Map<String, String> requestBody = {
        "json": jsonEncode(jsonData),
        "operation": "submitStudentEvaluation",
      };

      var response = await http.post(url, body: requestBody);

      if (response.statusCode == 200) {
        var res = jsonDecode(response.body);
        print(res);
      }
    } catch (e) {
      print("Error submitting evaluation: $e");
    }
  }
}
