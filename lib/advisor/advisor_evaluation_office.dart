import 'dart:convert';
import 'package:csdl_mobile/advisor/advisor_drawer.dart';
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
      drawer: AdvisorDrawer(advisorId: widget.advisor_id),
      body: Stack(
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
                  Expanded(
                    child: ListView.builder(
                      itemCount: officeQuestions.length,
                      itemBuilder: (context, index) {
                        final question = officeQuestions[index];
                        final questionId =
                            question['evaluation_office_questions_id']
                                .toString();
                        final questionText =
                            question['evaluation_office_questions_question'];

                        return buildQuestionRow(
                            questionText, questionId, selectedValuesAreas);
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        submitStudentEvaluation();
                      },
                      child: const Text("Submit"),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildQuestionRow(
      String question, String key, Map<String, int?> selectedValues) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w500, height: 1.5),
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
      int totalAreas = calculateTotal(selectedValuesAreas);

      var url = Uri.parse("${SessionStorage.url}transaction.php");
      Map<String, dynamic> jsonData = {
        "evaluation_office_supM_id": widget.advisor_id,
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
        print("Evaluation submitted successfully.");
      }
    } catch (e) {
      print("Error submitting evaluation: $e");
    }
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
      }
    } catch (e) {
      print("Error getting evaluation questions: $e");
    }
  }

}
