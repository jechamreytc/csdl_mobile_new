import 'package:csdl_mobile/session_storage.dart';
import 'package:csdl_mobile/student/edit_profile_sheet.dart';
import 'package:csdl_mobile/student/student.dart';
import 'package:csdl_mobile/student/student_dashboard.dart';
import 'package:csdl_mobile/student/student_job_type.dart';
import 'package:csdl_mobile/student/student_ocr.dart';
// import 'package:csdl_mobile/student/student_dashboard.dart';
// import 'package:csdl_mobile/student/student_dtr.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class StudentDrawer extends StatefulWidget {
  final String student_id;
  final int currentIndex; // Add current screen index

  const StudentDrawer({Key? key, required this.student_id, this.currentIndex = 0}) : super(key: key);

  @override
  _StudentDrawerState createState() => _StudentDrawerState();
}

class _StudentDrawerState extends State<StudentDrawer> {
  late int selectedIndex;
  bool settingsExpanded = false; // NEW

  @override
  void initState() {
    super.initState();
    selectedIndex = widget.currentIndex; // Initialize with current screen
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 250,
      backgroundColor: const Color(0xFF0F172A), // dark background
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF0F172A)),
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  top: 15,
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(
                        image: AssetImage(
                            'assets/images/csdl_background_no_bg.jpg'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                const Positioned(
                  left: 80,
                  top: 15,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("HK SMS",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 25,
                              fontWeight: FontWeight.bold)),
                      Text("HK Scholars",
                          style: TextStyle(color: Colors.white, fontSize: 12)),
                      Text("Management System",
                          style: TextStyle(color: Colors.white, fontSize: 12)),
                    ],
                  ),
                ),
                const Positioned(
                  left: 0,
                  top: 120,
                  child: Text(
                    "DRAWER",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),

          buildDrawerItem(
            index: 0,
            icon: Icons.dvr_rounded,
            label: "Dashboard",
            onTap: () {
              setState(() => selectedIndex = 0);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => StudentDashboard(
                    student_id: widget.student_id,
                  ),
                ),
              );
            },
          ),

          // DUTY ASSIGNMENT
          buildDrawerItem(
            index: 1,
            icon: Icons.assignment,
            label: "Duty Assignment",
            onTap: () {
              setState(() => selectedIndex = 1);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => Student(student_id: widget.student_id),
                ),
              );
            },
          ),

          //SEND SCHEDULE
          buildDrawerItem(
            index: 2,
            icon: Icons.send,
            label: "Document Upload & Status",
            onTap: () {
              setState(() => selectedIndex = 2);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      StudentOcr(student_id: widget.student_id),
                ),
              );
            },
          ),

          // ACCOUNT SETTINGS
          buildDrawerItem(
            index: 3,
            icon: Icons.settings,
            label: "Account Settings",
            onTap: () {
              setState(() => selectedIndex = 3);
              Navigator.pop(context);
              showShadSheet(
                side: ShadSheetSide.right,
                context: context,
                builder: (context) => EditProfileSheet(
                  side: ShadSheetSide.right,
                  student_id: widget.student_id,
                ),
              );
            },
          ),
//           Container(
//             margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//             decoration: BoxDecoration(
//               color: selectedIndex == 10
//                   ? const Color(0xFF104038)
//                   : Colors.transparent,
//             ),
//             child: ListTile(
//               leading: const Icon(Icons.settings, color: Colors.white),
//               title: const Text("Settings & Privacy",
//                   style: TextStyle(color: Colors.white)),
//               trailing: Icon(
//                 settingsExpanded
//                     ? Icons.keyboard_arrow_up
//                     : Icons.keyboard_arrow_down,
//                 color: Colors.white,
//               ),
//               onTap: () {
//                 setState(() {
//                   settingsExpanded = !settingsExpanded;
//                   selectedIndex = 10; // mark settings as selected
//                 });
//               },
//             ),
//           ),

// // Sub-menu Personal Details
//           if (settingsExpanded) ...[
//             Padding(
//               padding: const EdgeInsets.only(left: 30.0),
//               child: buildDrawerItem(
//                 index: 21,
//                 icon: Icons.person,
//                 label: "Personal Details",
//                 onTap: () {
//                   setState(() => selectedIndex = 21); // Set selected here
//                   Navigator.pop(context);
//                   showShadSheet(
//                     side: ShadSheetSide.right,
//                     context: context,
//                     builder: (context) => EditProfileSheet(
//                       side: ShadSheetSide.right,
//                       student_id: widget.student_id,
//                     ),
//                   );
//                 },
//               ),
//             ),
//             Padding(
//               padding: const EdgeInsets.only(left: 30.0),
//               child: buildDrawerItem(
//                 index: 22,
//                 icon: Icons.lock,
//                 label: "Password & Security",
//                 onTap: () {
//                   setState(() => selectedIndex = 22); // Set selected here
//                   Navigator.pop(context);
//                   showShadSheet(
//                     side: ShadSheetSide.right,
//                     context: context,
//                     builder: (context) => EditProfileSheet(
//                       side: ShadSheetSide.right,
//                       student_id: widget.student_id,
//                     ),
//                   );
//                 },
//               ),
//             ),
//           ],

// LOGOUT
          buildDrawerItem(
            index: 4,
            icon: Icons.logout,
            iconColor: Colors.red,
            label: "Logout",
            onTap: () {
              SessionStorage.clear(); // ❌ Clear all session

              Navigator.pushReplacementNamed(context, '/'); // Back to login
            },
          ),
          // buildDrawerItem(
          //   index: 5,
          //   icon: Icons.settings,
          //   label: "Job Type",
          //   onTap: () {
          //     setState(() => selectedIndex = 5);
          //     Navigator.pop(context);
          //     showShadSheet(
          //       side: ShadSheetSide.right,
          //       context: context,
          //       builder: (context) => StudentJobType(
          //         student_id: widget.student_id,
          //       ),
          //     );
          //   },
          // ),
        ],
      ),
    );
  }

  Widget buildDrawerItem({
    required int index,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color iconColor = Colors.white,
  }) {
    final isSelected = selectedIndex == index;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF104038) : Colors.transparent,
      ),
      child: ListTile(
        leading: Icon(icon, color: iconColor),
        title: Text(label, style: const TextStyle(color: Colors.white)),
        onTap: onTap,
      ),
    );
  }
}
