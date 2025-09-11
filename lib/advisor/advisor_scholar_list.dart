import 'dart:convert';
import 'package:csdl_mobile/advisor/advisor_drawer.dart';
import 'package:csdl_mobile/advisor/advisor_evaluation_office.dart';
import 'package:csdl_mobile/advisor/advisor_evalution.dart';
// import 'package:csdl_mobile/advisor/advisor_evaluation_office.dart';
// import 'package:csdl_mobile/advisor/advisor_evalution.dart';
import 'package:csdl_mobile/session_storage.dart';
// import 'package:csdl_mobile/advisor/advisor_edit_profile.dart';
// import 'package:csdl_mobile/advisor/advisor_qr_scanner.dart';
import 'package:flutter/material.dart';
// import 'package:shadcn_ui/shadcn_ui.dart';
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
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(50), // Set the height of the AppBar
        child: AppBar(
          backgroundColor:
              Colors.transparent, // Make the AppBar background transparent
          elevation: 0, // Remove the shadow of the AppBar
          flexibleSpace: Image.asset(
            'assets/images/coc_logo.png', // Path to your background image
            height: 50,
            width: 50, // Ensure the image covers the entire area
          ),
        ),
      ),
      drawer: AdvisorDrawer(advisorId: widget.advisor_id),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green.shade50, Colors.green.shade200],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            // Image.asset(
            //   'assets/images/csdl_background.jpg',
            //   fit: BoxFit.cover,
            //   width: double.infinity,
            //   height: double.infinity,
            //   alignment: Alignment.topLeft,
            // ),
            // Container(
            //   decoration: const BoxDecoration(
            //     gradient: LinearGradient(
            //       colors: [
            //         Color.fromRGBO(
            //             255, 255, 255, 0.9), // White with 50% transparency
            //         Color.fromRGBO(
            //             255, 255, 255, 0.9), // White with 50% transparency
            //       ],
            //       begin: Alignment.topCenter,
            //       end: Alignment.bottomCenter,
            //     ),
            //   ),
            // ),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20.0, vertical: 40.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    const Text(
                      "ASSIGNED SCHOLARS",
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2F332D),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Separate header pills
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.green[700],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'NAME',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 80),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.green[700],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'SECTION',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Scholar list below header pills
                    Container(
                      width: double.infinity,
                      height: 400,
                      decoration: BoxDecoration(
                        color: Colors.green[700],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : scholars.isNotEmpty
                              ? ListView.builder(
                                  itemCount: scholars.length,
                                  itemBuilder: (context, index) {
                                    final scholar = scholars[index];
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        border: Border(
                                          bottom: BorderSide(
                                            color:
                                                Colors.white.withOpacity(0.2),
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            flex: 2,
                                            child: GestureDetector(
                                              onTap: () {
                                                showDialog(
                                                  context: context,
                                                  builder: (context) =>
                                                      AlertDialog(
                                                    backgroundColor:
                                                        const Color(0xFF1A6312),
                                                    title: Text(
                                                      scholar['Fullname'] ??
                                                          'Unknown',
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 18,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    content: Column(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          "Section: ${scholar['sub_code'] ?? 'N/A'}",
                                                          style:
                                                              const TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 14,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            height: 8),
                                                        Text(
                                                          "Contact: ${scholar['stud_contactNumber'] ?? 'N/A'}",
                                                          style:
                                                              const TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 14,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            height: 4),
                                                        Text(
                                                          "Email: ${scholar['stud_email'] ?? 'N/A'}",
                                                          style:
                                                              const TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 14,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            height: 4),
                                                        Text(
                                                          "Room: ${scholar['sub_room'] ?? 'N/A'}",
                                                          style:
                                                              const TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 14,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                );
                                              },
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 8),
                                                child: Text(
                                                  scholar['Fullname'] ??
                                                      'Unknown',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: Text(
                                              scholar['sub_code'] ?? 'Office',
                                              textAlign: TextAlign.right,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          ElevatedButton(
                                            onPressed: scholar[
                                                        'assign_render_status'] ==
                                                    1
                                                ? () {
                                                    final assignment = scholar[
                                                            'assignment_name'] ??
                                                        '';
                                                    if (assignment ==
                                                        "Office") {
                                                      // Uncomment when ready
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) =>
                                                              //     AdvisorEvaluationOffice(
                                                              //   scholarId: scholar[
                                                              //       'stud_id'],
                                                              // ),
                                                              AdvisorEvaluationOffice(
                                                            advisor_id: widget
                                                                .advisor_id,
                                                            scholar_id: scholar[
                                                                'stud_active_id'],
                                                          ),
                                                        ),
                                                      );
                                                    } else if (assignment ==
                                                        "Student Facilitator") {
                                                      // Uncomment when ready
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) =>
                                                              //     AdvisorEvaluation(
                                                              //   scholarId: scholar[
                                                              //       'stud_id'],
                                                              // ),
                                                              AdvisorEvaluation(
                                                            advisor_id: widget
                                                                .advisor_id,
                                                            scholar_id: scholar[
                                                                'stud_active_id'],
                                                          ),
                                                        ),
                                                      );
                                                    } else {
                                                      ScaffoldMessenger.of(
                                                              context)
                                                          .showSnackBar(
                                                        const SnackBar(
                                                          content: Text(
                                                              "No evaluation available for this scholar."),
                                                        ),
                                                      );
                                                    }
                                                  }
                                                : null, // Button is disabled if assign_render_status != 1
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  scholar['assign_render_status'] ==
                                                          1
                                                      ? Colors.white
                                                      : Colors.white
                                                          .withOpacity(0.5),
                                              foregroundColor:
                                                  Colors.green[900],
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 10),
                                            ),
                                            child: const Text("Evaluate"),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                )
                              : Center(
                                  child: Text(
                                    errorMessage.isNotEmpty
                                        ? errorMessage
                                        : 'No scholars found.',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
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
