// import 'dart:convert';
// import 'package:csdl_mobile/advisor/advisor.dart';
// import 'package:csdl_mobile/advisor/advisor_evalution.dart';
// import 'package:csdl_mobile/advisor/advisor_qr_scanner.dart';
// import 'package:csdl_mobile/advisor/advisor_qr_scanner_adjustment.dart';
// import 'package:csdl_mobile/advisor/advisor_scholar_list.dart';
// import 'package:csdl_mobile/advisor/advisor_settings.dart';
// import 'package:csdl_mobile/main.dart';
// import 'package:csdl_mobile/session_storage.dart';
// import 'package:flutter/material.dart';
// import 'package:hidden_drawer_menu/hidden_drawer_menu.dart';
// import 'package:http/http.dart' as http;

// class AdvisorHiddenDrawer extends StatefulWidget {
//   final String advisor_id;
//   const AdvisorHiddenDrawer({
//     Key? key,
//     required this.advisor_id,
//   }) : super(key: key);

//   @override
//   _AdvisorHiddenDrawerState createState() => _AdvisorHiddenDrawerState();
// }

// class _AdvisorHiddenDrawerState extends State<AdvisorHiddenDrawer> {
//   List<ScreenHiddenDrawer> itemsStudents = [];
//   // bool isScholarAssigned = false;
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
//   //       "supM_id": widget.advisor_id,
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

//     // newItems.add(
//     //   ScreenHiddenDrawer(
//     //     ItemHiddenMenu(
//     //       selectedStyle: const TextStyle(
//     //         color: Colors.black,
//     //       ),
//     //       name: "â° Dashboard",
//     //       baseStyle: const TextStyle(
//     //         color: Colors.black,
//     //         fontSize: 12.0,
//     //       ),
//     //       colorLineSelected: Colors.black,
//     //     ),
//     //     Advisor(
//     //       advisor_id: widget.advisor_id,
//     //     ),
//     //   ),
//     // );

//     newItems.add(
//       ScreenHiddenDrawer(
//         ItemHiddenMenu(
//           selectedStyle: const TextStyle(
//             color: Colors.black,
//           ),
//           name: "ðŸ“‹ Scholar List",
//           baseStyle: const TextStyle(
//             color: Colors.black,
//             fontSize: 12.0,
//           ),
//           colorLineSelected: Colors.black,
//         ),
//         AdvisorScholarList(
//           advisor_id: widget.advisor_id,
//         ),
//       ),
//     );

//     newItems.add(
//       ScreenHiddenDrawer(
//         ItemHiddenMenu(
//           selectedStyle: const TextStyle(
//             color: Colors.black,
//           ),
//           name: "â° Adjustments",
//           baseStyle: const TextStyle(
//             color: Colors.black,
//             fontSize: 12.0,
//           ),
//           colorLineSelected: Colors.black,
//         ),
//         AdvisorQrScannerAdjustment(),
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
//     //         name: "ðŸ“ Request Schedule",
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
//           name: "âš™ï¸ QR Code Scanner",
//           baseStyle: const TextStyle(
//             color: Colors.black,
//             fontSize: 12.0,
//           ),
//           colorLineSelected: Colors.black,
//         ),
//         AdvisorQrScanner(),
//       ),
//     );

//     newItems.add(
//       ScreenHiddenDrawer(
//         ItemHiddenMenu(
//           selectedStyle: const TextStyle(
//             color: Colors.black,
//           ),
//           name: "âš™ï¸ Account Settings",
//           baseStyle: const TextStyle(
//             color: Colors.black,
//             fontSize: 12.0,
//           ),
//           colorLineSelected: Colors.black,
//         ),
//         AdvisorSettings(
//           advisor_id: widget.advisor_id,
//         ),
//       ),
//     );
//     setState(() {
//       // Update the list with new items
//       itemsStudents = newItems;
//     });
//   }
// }
