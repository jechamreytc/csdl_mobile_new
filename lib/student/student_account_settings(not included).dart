// import 'package:csdl_mobile/student/edit_profile_sheet.dart';
// import 'package:flutter/material.dart';
// import 'package:shadcn_ui/shadcn_ui.dart';

// class StudentAccountSettings extends StatefulWidget {
//   final String student_id;

//   const StudentAccountSettings({
//     Key? key,
//     required this.student_id,
//   }) : super(key: key);
//   @override
//   _StudentAccountSettingsState createState() => _StudentAccountSettingsState();
// }

// class _StudentAccountSettingsState extends State<StudentAccountSettings> {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Container(
//         color: const Color(0xFF006400),
//         child: Center(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               ShadButton(
//                 child: const Text('Personal Information'),
//                 onPressed: () => showShadSheet(
//                   side: ShadSheetSide.right,
//                   context: context,
//                   builder: (context) => EditProfileSheet(
//                     side: ShadSheetSide.right,
//                     student_id: widget.student_id,
//                   ),
//                 ),
//                 backgroundColor: Colors.white,
//               ),
//               ShadButton(
//                 child: const Text('Logout'),
//                 onPressed: () {
//                   Navigator.pushReplacementNamed(context, '/home');
//                 },
//                 backgroundColor: Colors.white,
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
