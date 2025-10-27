// import 'dart:convert';
// import 'package:csdl_mobile/components/image_background.dart';
// import 'package:csdl_mobile/session_storage.dart';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;

// class RequestSchedule extends StatefulWidget {
//   final String student_id;
//   const RequestSchedule({
//     Key? key,
//     required this.student_id,
//   }) : super(key: key);

//   @override
//   _RequestScheduleState createState() => _RequestScheduleState();
// }

// class _RequestScheduleState extends State<RequestSchedule> {
//   int subject_id = 0;
//   String selectedSchedule = ''; // To hold the selected combined value
//   List<String> combinedSchedules = []; // To hold available schedules
//   List<Map<String, dynamic>> requestScheduleResponse =
//       []; // To store the response from the request
//   String noScheduleMessage = ''; // To hold the "No Available Schedule" message

//   @override
//   void initState() {
//     super.initState();
//     getScholarAllAvailableSchedule(); // Get available schedule data
//   }

//   // Function to get the available schedule data from the API
//   void getScholarAllAvailableSchedule() async {
//     try {
//       var url = Uri.parse("${SessionStorage.url}transaction.php");
//       Map<String, dynamic> jsonData = {
//         "ocr_studActive_id": widget.student_id,
//       };
//       Map<String, String> requestBody = {
//         "operation": "getScholarAllAvailableSchedule",
//         "json": jsonEncode(jsonData),
//       };

//       var response = await http.post(url, body: requestBody);
//       if (response.statusCode == 200) {
//         var data = jsonDecode(response.body);
//         print("Available Schedules: $data");

//         // Extract the combined schedule data for the dropdown
//         List<String> tempSchedules = [];

//         // Loop through the response and extract required fields
//         for (var item in data) {
//           String combinedSchedule =
//               "${item["ocr_day"]} - ${item["ocr_schedule_time_from"]} to ${item["ocr_schedule_time_to"]}";
//           tempSchedules.add(combinedSchedule);
//         }

//         setState(() {
//           combinedSchedules = tempSchedules;
//         });
//       } else {
//         print("Failed to load available schedules.");
//       }
//     } catch (e) {
//       print("Error getting available schedules: $e");
//     }
//   }

//   void getRequestSchedule() async {
//     if (selectedSchedule.isEmpty) {
//       print("No schedule selected.");
//       return;
//     }

//     // Split the selectedSchedule into day, time_from, and time_to
//     List<String> selectedParts = selectedSchedule.split(' - ');
//     if (selectedParts.length == 2) {
//       String selectedDay = selectedParts[0];
//       List<String> timeParts = selectedParts[1].split(' to ');
//       String selectedTimeFrom = timeParts[0];
//       String selectedTimeTo = timeParts[1];

//       print(
//           "Requesting schedule with day: $selectedDay, from: $selectedTimeFrom, to: $selectedTimeTo");

//       try {
//         var url = Uri.parse("${SessionStorage.url}transaction.php");
//         Map<String, dynamic> jsonData = {
//           "day_name": selectedDay,
//           "time_from": selectedTimeFrom,
//           "time_to": selectedTimeTo
//         };

//         Map<String, String> requestBody = {
//           "operation": "getRequestSchedule",
//           "json": jsonEncode(jsonData),
//         };

//         var response = await http.post(url, body: requestBody);
//         if (response.statusCode == 200) {
//           var data = jsonDecode(response.body);
//           print("Request Schedule Response: $data");

//           // Check if the response is 0 (no available schedule)
//           if (data == 0 || data.isEmpty) {
//             setState(() {
//               noScheduleMessage =
//                   "No available schedule for the selected day and time.";
//               requestScheduleResponse = []; // Clear previous response
//             });
//           } else {
//             // Update the requestScheduleResponse with the received data
//             setState(() {
//               noScheduleMessage = ''; // Clear the no schedule message
//               requestScheduleResponse = List<Map<String, dynamic>>.from(data);
//               subject_id = requestScheduleResponse[0]['sub_id'];
//             });
//           }
//         } else {
//           print("Failed to request schedule.");
//         }
//       } catch (e) {
//         print("Error requesting schedule: $e");
//       }
//     }
//   }

//   void sendRequestSchedule() async {
//     try {
//       var url = Uri.parse("${SessionStorage.url}transaction.php");
//       Map<String, dynamic> jsonData = {
//         "stud_active_id": widget.student_id,
//         "sub_id": subject_id,
//       };
//       Map<String, String> requestBody = {
//         "operation": "sendRequestSchedule",
//         "json": jsonEncode(jsonData),
//       };
//       var response = await http.post(url, body: requestBody);
//       if (response.statusCode == 200) {
//         var data = jsonDecode(response.body);
//         print("Send Request Schedule Response: $data");
//       }
//     } catch (e) {
//       print("Error sending request schedule: $e");
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Schedule Request'),
//       ),
//       body: Stack(
//         children: [
//           ImageBackground(),
//           Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text('Schedules',
//                     style:
//                         TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),

//                 // Dropdown for combined schedule
//                 if (combinedSchedules.isNotEmpty)
//                   DropdownButton<String>(
//                     value: selectedSchedule.isEmpty ? null : selectedSchedule,
//                     hint: Text("Select a schedule"),
//                     items: combinedSchedules.map((String schedule) {
//                       return DropdownMenuItem<String>(
//                         value: schedule,
//                         child: Text(schedule),
//                       );
//                     }).toList(),
//                     onChanged: (newValue) {
//                       setState(() {
//                         selectedSchedule = newValue!;
//                       });
//                     },
//                   ),

//                 // Button to request schedule after selection
//                 ElevatedButton(
//                   onPressed:
//                       selectedSchedule.isEmpty ? null : getRequestSchedule,
//                   child: Text('Check Available Schedule'),
//                 ),

//                 // Display "No Available Schedule" message if there is no available schedule
//                 if (noScheduleMessage.isNotEmpty)
//                   Padding(
//                     padding: const EdgeInsets.all(8.0),
//                     child: Text(
//                       noScheduleMessage,
//                       style: TextStyle(color: Colors.red, fontSize: 16),
//                     ),
//                   ),

//                 // Display the requested schedule response in a ListView
//                 if (requestScheduleResponse.isNotEmpty)
//                   Expanded(
//                     child: ListView.builder(
//                       itemCount: requestScheduleResponse.length,
//                       itemBuilder: (context, index) {
//                         var item = requestScheduleResponse[index];
//                         return Card(
//                           margin: EdgeInsets.symmetric(vertical: 8.0),
//                           child: ExpansionTile(
//                             leading: Text('${item['sub_code']}'),
//                             title: Text('${item['sub_descriptive_title']}'),
//                             subtitle: Text('${item['sub_section']}'),
//                             children: [
//                               ListTile(
//                                 title: Text('Time: ${item['sub_time']}'),
//                                 subtitle: Text('Room: ${item['sub_room']}'),
//                               ),
//                               ListTile(
//                                 title: Text('F2F Day: ${item['F2F_Day']}'),
//                                 subtitle: Text('RC Day: ${item['RC_Day']}'),
//                               ),
//                               // Add a button inside the ExpansionTile
//                               Padding(
//                                 padding: const EdgeInsets.all(8.0),
//                                 child: ElevatedButton(
//                                   onPressed: () {
//                                     sendRequestSchedule();
//                                     print("Request Schedule button clicked");
//                                   },
//                                   child: Text('Request Schedule'),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         );
//                       },
//                     ),
//                   ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
