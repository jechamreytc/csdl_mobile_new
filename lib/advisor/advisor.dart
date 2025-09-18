import 'dart:convert';
import 'package:csdl_mobile/advisor/advisor_drawer.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:csdl_mobile/session_storage.dart';

class Advisor extends StatefulWidget {
  final String advisor_id;
  final String supervisor_id;
  const Advisor({
    super.key,
    required this.advisor_id,
    required this.supervisor_id,
  });

  @override
  _AdvisorState createState() => _AdvisorState();
}

class _AdvisorState extends State<Advisor> {
  List<dynamic> _subjects = [];
  List<dynamic> _scholars = [];
  String _advisorName = "";
  String _advisorEmail = "";

  @override
  void initState() {
    super.initState();
    _fetchSupervisorProfile();
    _fetchSubjects();
    _fetchScholars();
  }

  Future<void> _fetchSupervisorProfile() async {
    try {
      var url = Uri.parse("${SessionStorage.url}transaction.php");

      Map<String, dynamic> payload;

      // If it's a number, send as supM_id, otherwise treat it as email
      if (int.tryParse(widget.advisor_id) != null) {
        payload = {"supM_id": widget.advisor_id};
      } else {
        payload = {"supM_email": widget.advisor_id};
      }

      var response = await http.post(url, body: {
        "operation": "getSupervisorProfile",
        "json": jsonEncode(payload),
      });

      var res = jsonDecode(response.body);
      print("Raw response: ${response.body}");
      print("Decoded response: $res");

      if (res["success"] == true && res["data"] != null) {
        var data = res["data"];
        setState(() {
          _advisorName = data["supM_name"] ?? "Unknown";
          _advisorEmail = data["supM_email"] ?? "No email";
        });
      } else {
        setState(() {
          _advisorName = "Unknown";
          _advisorEmail = "No email";
        });
      }
    } catch (e) {
      print("Error fetching supervisor profile: $e");
    }
  }

  Future<void> _fetchSubjects() async {
    try {
      var url = Uri.parse("${SessionStorage.url}transaction.php");
      var response = await http.post(url, body: {
        "operation": "getAdvisorSubjects",
        "json": jsonEncode({"supM_id": widget.advisor_id}),
      });
      var res = jsonDecode(response.body);

      if (res != 0 && res is List) {
        setState(() => _subjects = res);
      }
    } catch (e) {
      print("Error fetching subjects: $e");
    }
  }

  Future<void> _fetchScholars() async {
    try {
      var url = Uri.parse("${SessionStorage.url}transaction.php");
      var response = await http.post(url, body: {
        "operation": "getAdvisorScholars",
        "json": jsonEncode({"supM_id": widget.advisor_id}),
      });
      var res = jsonDecode(response.body);

      if (res != 0 && res is List) {
        setState(() => _scholars = res);
      }
    } catch (e) {
      print("Error fetching scholars: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Scaffold(
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
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
        drawer: AdvisorDrawer(
          advisorId: widget.advisor_id,
          supervisor_id: widget.supervisor_id,
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green.shade50, Colors.green.shade200],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // const Text(
              //   "Welcome",
              //   style: TextStyle(
              //     fontSize: 20,
              //     fontWeight: FontWeight.bold,
              //     color: Colors.green,
              //   ),
              // ),
              const SizedBox(height: 8),

              // ✅ Supervisor Info Card
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Color(0xFF104038),
                        child:
                            Icon(Icons.person, size: 30, color: Colors.white),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "$_advisorName",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "$_advisorEmail",
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Subjects Section
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Subjects",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const Divider(),
                      _subjects.isEmpty
                          ? const Text("No subjects found.")
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _subjects.length,
                              itemBuilder: (context, index) {
                                var subj = _subjects[index];
                                return ListTile(
                                  leading: const Icon(Icons.book,
                                      color: Colors.blue),
                                  title: Text(subj["subject_name"] ??
                                      "Unknown Subject"),
                                  subtitle: Text(
                                      "Code: ${subj["subject_code"] ?? 'N/A'}"),
                                );
                              },
                            ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Scholars Section
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Assigned Scholars",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const Divider(),
                      _scholars.isEmpty
                          ? const Text("No scholars found.")
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _scholars.length,
                              itemBuilder: (context, index) {
                                var scholar = _scholars[index];
                                return ListTile(
                                  leading: const Icon(Icons.person,
                                      color: Colors.green),
                                  title: Text(scholar["stud_name"] ??
                                      "Unknown Scholar"),
                                  subtitle: Text(
                                      "Course: ${scholar["course"] ?? 'N/A'}"),
                                );
                              },
                            ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
