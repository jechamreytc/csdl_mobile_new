// import 'dart:convert';
// import 'package:csdl_mobile/main.dart';
// import 'package:csdl_mobile/session_storage.dart';
// import 'package:csdl_mobile/student/request_schedule.dart';
// import 'package:csdl_mobile/student/student.dart';
// import 'package:csdl_mobile/student/student_account_settings.dart';
// import 'package:csdl_mobile/student/student_dtr.dart';
// import 'package:flutter/material.dart';
// import 'package:hidden_drawer_menu/hidden_drawer_menu.dart';
// import 'package:http/http.dart' as http;

// class StudentHiddenDrawer extends StatefulWidget {
//   final String student_id;
//   const StudentHiddenDrawer({
//     Key? key,
//     required this.student_id,
//   }) : super(key: key);

//   @override
//   _StudentHiddenDrawerState createState() => _StudentHiddenDrawerState();
// }

// class _StudentHiddenDrawerState extends State<StudentHiddenDrawer> {
//   List<ScreenHiddenDrawer> itemsStudents = [];
//   bool isScholarAssigned = false;
//   bool isLoading = true; // Add this to track loading state

//   @override
//   void initState() {
//     super.initState();
//     updateMenuItems();
//     setState(() {
//       isLoading = false;
//     });
//     // scholarAssignedChecker(); // Check scholar assignment on init
//   }

//   @override
//   Widget build(BuildContext context) {
//     return isLoading
//         ? Scaffold(
//             body: Center(
//                 child: CircularProgressIndicator()), // Show loading indicator
//           )
//         : HiddenDrawerMenu(
//             backgroundColorMenu: Colors.white,
//             backgroundColorAppBar: const Color(0xFF006400),
//             screens: itemsStudents,
//             tittleAppBar: const Text(""),
//             slidePercent: 45,
//             verticalScalePercent: 100,
//             contentCornerRadius: 50,
//             isTitleCentered: true,
//           );
//   }

//   // Function to check if scholar is assigned or not
//   // void scholarAssignedChecker() async {
//   //   try {
//   //     var url = Uri.parse("${SessionStorage.url}transaction.php");
//   //     Map<String, dynamic> jsonData = {
//   //       "stud_active_id": widget.student_id,
//   //     };
//   //     Map<String, String> requestBody = {
//   //       "operation": "scholarAssignedChecker",
//   //       "json": jsonEncode(jsonData),
//   //     };

//   //     var response = await http.post(url, body: requestBody);
//   //     var res = jsonDecode(response.body);

//   //     setState(() {
//   //       isScholarAssigned = res["COUNT(*)"] != 0;
//   //       isLoading = false; // Stop loading once the response is received
//   //     });

//   //     updateMenuItems(); // Update menu items after scholar status check
//   //   } catch (e) {
//   //     print(e);
//   //     setState(() {
//   //       isLoading = false; // Stop loading in case of an error
//   //     });
//   //   }
//   // }

//   // Update the menu items based on whether a scholar is assigned
//   void updateMenuItems() {
//     List<ScreenHiddenDrawer> newItems = [];

//     newItems.add(
//       ScreenHiddenDrawer(
//         ItemHiddenMenu(
//           selectedStyle: const TextStyle(
//             color: Colors.black,
//           ),
//           name: "📋 Duty Assignment",
//           baseStyle: const TextStyle(
//             color: Colors.black,
//             fontSize: 12.0,
//           ),
//           colorLineSelected: Colors.black,
//         ),
//         Student(
//           student_id: widget.student_id,
//         ),
//       ),
//     );

//     newItems.add(
//       ScreenHiddenDrawer(
//         ItemHiddenMenu(
//           selectedStyle: const TextStyle(
//             color: Colors.black,
//           ),
//           name: "⏰ Daily Time Record",
//           baseStyle: const TextStyle(
//             color: Colors.black,
//             fontSize: 12.0,
//           ),
//           colorLineSelected: Colors.black,
//         ),
//         StudentDtr(
//           student_id: widget.student_id,
//         ),
//       ),
//     );

//     // // Add "Request Schedule" only if scholar is not assigned
//     // if (!isScholarAssigned) {
//     //   newItems.add(
//     //     ScreenHiddenDrawer(
//     //       ItemHiddenMenu(
//     //         selectedStyle: const TextStyle(
//     //           color: Colors.black,
//     //         ),
//     //         name: "📝 Request Schedule",
//     //         baseStyle: const TextStyle(
//     //           color: Colors.black,
//     //           fontSize: 12.0,
//     //         ),
//     //         colorLineSelected: Colors.black,
//     //       ),
//     //       RequestSchedule(
//     //         student_id: widget.student_id,
//     //       ),
//     //     ),
//     //   );
//     // }

//     newItems.add(
//       ScreenHiddenDrawer(
//         ItemHiddenMenu(
//           selectedStyle: const TextStyle(
//             color: Colors.black,
//           ),
//           name: "⚙️ Account Settings",
//           baseStyle: const TextStyle(
//             color: Colors.black,
//             fontSize: 12.0,
//           ),
//           colorLineSelected: Colors.black,
//         ),
//         StudentAccountSettings(
//           student_id: widget.student_id,
//         ),
//       ),
//     );
//     setState(() {
//       // Update the list with new items
//       itemsStudents = newItems;
//     });
//   }
// }
