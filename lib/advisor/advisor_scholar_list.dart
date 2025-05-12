import 'dart:convert';
import 'package:csdl_mobile/advisor/advisor_evaluation_office.dart';
import 'package:csdl_mobile/advisor/advisor_evalution.dart';
import 'package:csdl_mobile/session_storage.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AdvisorScholarList extends StatefulWidget {
  final String advisor_id;
  const AdvisorScholarList({
    super.key,
    required this.advisor_id,
  });

  @override
  _AdvisorScholarListState createState() => _AdvisorScholarListState();
}

class _AdvisorScholarListState extends State<AdvisorScholarList> {
  List<dynamic> scholars = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    getAssignedScholars();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scholar List'),
      ),
      body: Center(
        child: isLoading
            ? const CircularProgressIndicator()
            : scholars.isNotEmpty
                ? createListView()
                : Text(errorMessage.isNotEmpty
                    ? errorMessage
                    : 'No scholars found.'),
      ),
    );
  }

  Widget createListView() {
    return ListView.builder(
      itemCount: scholars.length,
      itemBuilder: (context, index) {
        final scholar = scholars[index];
        String status = "Incomplete";
        if (scholar['assign_render_status'] != null) {
          int? renderStatus =
              int.tryParse(scholar['assign_render_status'].toString());
          if (renderStatus == 1) {
            status = "Complete";
          }
        }

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: ListTile(
            title: Text(scholar['Fullname'] ?? 'Unknown'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Contact: ${scholar['stud_contactNumber'] ?? 'N/A'}"),
                Text("Email: ${scholar['stud_email'] ?? 'N/A'}"),
                Text("Room: ${scholar['sub_room'] ?? 'N/A'}"),
                Text("Status: $status"),
              ],
            ),
            trailing: status == "Complete"
                ? ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    onPressed: () {
                      if (scholar['sub_code'] != null) {
                        // Navigate to AdvisorEvaluation if `sub_code` is available (from sub_supM_id)
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AdvisorEvaluation(
                              scholar_id: scholar['stud_active_id'],
                              advisor_id: widget.advisor_id,
                            ),
                          ),
                        );
                      } else {
                        // Navigate to AdvisorEvaluationOffice if sub_supM_id is not present (from offT_supM_id)
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AdvisorEvaluationOffice(
                              scholar_id: scholar['stud_active_id'],
                              advisor_id: widget.advisor_id,
                            ),
                          ),
                        );
                      }
                    },
                    child: const Text(
                      "Evaluate",
                      style: TextStyle(color: Colors.white),
                    ),
                  )
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                    ),
                    onPressed: null, // Disable button for incomplete status
                    child: const Text(
                      "Evaluate",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
          ),
        );
      },
    );
  }

  // Function to fetch assigned scholars
  void getAssignedScholars() async {
    try {
      var url = Uri.parse("${SessionStorage.url}transaction.php");
      Map<String, dynamic> jsonData = {
        "sub_supM_id": widget.advisor_id,
      };

      Map<String, String> requestBody = {
        "operation": "getAssignedScholars",
        "json": jsonEncode(jsonData),
      };

      var response = await http.post(url, body: requestBody);

      if (response.statusCode == 200) {
        var res = jsonDecode(response.body);
        print(res);
        if (res != 0) {
          setState(() {
            scholars = res;
            isLoading = false;
          });
        } else {
          setState(() {
            isLoading = false;
            errorMessage = "No scholars assigned.";
          });
        }
      } else {
        setState(() {
          isLoading = false;
          errorMessage =
              "Failed to load scholars. Server returned status code: ${response.statusCode}.";
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = "An error occurred: $e";
      });
    }
  }
}
