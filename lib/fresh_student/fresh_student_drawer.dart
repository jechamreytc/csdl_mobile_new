import 'package:csdl_mobile/fresh_student/fresh_student.dart';
import 'package:csdl_mobile/fresh_student/fresh_student_profile_sheet.dart';
import 'package:csdl_mobile/fresh_student/fresh_student_referral_list.dart';
import 'package:flutter/material.dart';

import 'package:csdl_mobile/student/edit_profile_sheet.dart';
import 'package:csdl_mobile/student/student.dart';
// import 'package:csdl_mobile/student/student_dashboard.dart';
// import 'package:csdl_mobile/student/student_dtr.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class FreshStudentDrawer extends StatefulWidget {
  final String student_id;

  const FreshStudentDrawer({Key? key, required this.student_id})
      : super(key: key);

  @override
  _FreshStudentDrawerState createState() => _FreshStudentDrawerState();
}

class _FreshStudentDrawerState extends State<FreshStudentDrawer> {
  int selectedIndex = 0;

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
                  top: 10,
                  child: Container(
                    width: 60,
                    height: 60,
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
                  top: 10,
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
                    "DASHBOARD",
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

          //DASHBOARD
          buildDrawerItem(
            index: 0,
            icon: Icons.dashboard,
            label: "Dashboard",
            onTap: () {
              setState(() => selectedIndex = 0);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => FreshStudent(
                          student_id: widget.student_id,
                        )),
              );
            },
          ),

          // DUTY ASSIGNMENT
          buildDrawerItem(
            index: 1,
            icon: Icons.dvr_rounded,
            label: "Referral List",
            onTap: () {
              setState(() => selectedIndex = 1);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => FreshStudentReferralList(
                    student_id: widget.student_id,
                  ),
                ),
              );
            },
          ),

          // ACCOUNT SETTINGS
          buildDrawerItem(
            index: 2,
            icon: Icons.settings,
            label: "Account Settings",
            onTap: () {
              setState(() => selectedIndex = 2);
              Navigator.pop(context);
              showShadSheet(
                side: ShadSheetSide.right,
                context: context,
                builder: (context) => FreshStudentProfileSheet(
                  side: ShadSheetSide.right,
                  student_id: widget.student_id,
                ),
              );
            },
          ),

          // LOGOUT
          buildDrawerItem(
            index: 3,
            icon: Icons.logout,
            iconColor: Colors.red,
            label: "Logout",
            onTap: () {
              setState(() => selectedIndex = 3);
              Navigator.pushReplacementNamed(context, '/home');
            },
          ),
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
