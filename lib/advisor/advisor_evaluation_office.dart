import 'dart:convert';
import 'package:csdl_mobile/session_storage.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AdvisorEvaluationOffice extends StatefulWidget {
  final String advisor_id;
  final String scholar_id;
  const AdvisorEvaluationOffice(
      {super.key, required this.advisor_id, required this.scholar_id});

  @override
  _AdvisorEvaluationOfficeState createState() =>
      _AdvisorEvaluationOfficeState();
}

class _AdvisorEvaluationOfficeState extends State<AdvisorEvaluationOffice> {
  final Map<String, int?> selectedValuesAreas =
      {}; // Store selected values for Areas questions

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
                "Advisor Evaluation - Areas",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              buildQuestionRow("a. Evaluation 1", "a", selectedValuesAreas),
              buildQuestionRow("b. Evaluation 2", "b", selectedValuesAreas),
              buildQuestionRow("c. Evaluation 3", "c", selectedValuesAreas),
              buildQuestionRow("d. Evaluation 4", "d", selectedValuesAreas),
              buildQuestionRow("e. Evaluation 5", "e", selectedValuesAreas),
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

  // Function to calculate the total score for Areas category
  int calculateTotal(Map<String, int?> selectedValues) {
    return selectedValues.values
        .where((value) => value != null)
        .fold(0, (sum, value) => sum + value!);
  }

  void submitStudentEvaluation() async {
    try {
      // Calculate the total for Areas category
      int totalAreas = calculateTotal(selectedValuesAreas);

      var url = Uri.parse("${SessionStorage.url}transaction.php");
      Map<String, dynamic> jsonData = {
        "evaluation_sf_supM_id": widget.advisor_id,
        "evaluation_sf_assign_stud_id": widget.scholar_id,
        "evaluation_sf_total_areas": totalAreas,
        "evaluation_sf_overall_score": totalAreas, // Sum of Areas category
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
