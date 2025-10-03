import 'package:csdl_mobile/advisor/advisor.dart';
import 'package:csdl_mobile/advisor/advisor_edit_profile.dart';
import 'package:csdl_mobile/advisor/advisor_qr_scanner.dart';
import 'package:csdl_mobile/advisor/advisor_scholar_list.dart';
import 'package:csdl_mobile/advisor/advisor_student_adjustment.dart';
import 'package:csdl_mobile/session_storage.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class AdvisorDrawer extends StatefulWidget {
  final String advisorId;
  final String supervisor_id;
  final int currentIndex; // Add current screen index

  const AdvisorDrawer(
      {Key? key, required this.advisorId, required this.supervisor_id, this.currentIndex = 0})
      : super(key: key);

  @override
  _AdvisorDrawerState createState() => _AdvisorDrawerState();
}

class _AdvisorDrawerState extends State<AdvisorDrawer> {
  late int selectedIndex;

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
            icon: Icons.dashboard,
            label: "Dashboard",
            onTap: () {
              setState(() => selectedIndex = 0);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => Advisor(
                    advisor_id: widget.advisorId,
                    supervisor_id: widget.supervisor_id,
                  ),
                ),
              );
            },
          ),

          // ASSIGNED SCHOLAR
          buildDrawerItem(
            index: 1,
            icon: Icons.list,
            label: "Assigned Scholar",
            onTap: () {
              setState(() => selectedIndex = 1);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => AdvisorScholarList(
                    advisor_id: widget.advisorId,
                    supervisor_id: widget.supervisor_id,
                  ),
                ),
              );
            },
          ),

          // QR SCANNER
          buildDrawerItem(
            index: 2,
            icon: Icons.qr_code_scanner,
            label: "QR Scanner",
            onTap: () {
              setState(() => selectedIndex = 2);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      AdvisorQrScanner(advisor_id: widget.advisorId),
                ),
              );
            },
          ),

          buildDrawerItem(
            index: 3,
            icon: Icons.qr_code_scanner,
            label: "Student Adjustment",
            onTap: () {
              setState(() => selectedIndex = 3);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AdvisorStudentAdjustment(
                    advisor_id: widget.advisorId,
                    supervisor_id: widget.supervisor_id,
                  ),
                ),
              );
            },
          ),

          // ACCOUNT SETTINGS
          buildDrawerItem(
            index: 4,
            icon: Icons.settings,
            label: "Account Settings",
            onTap: () {
              setState(() => selectedIndex = 4);
              Navigator.pop(context);
              showShadSheet(
                side: ShadSheetSide.right,
                context: context,
                builder: (context) => AdvisorEditProfileSheet(
                  side: ShadSheetSide.right,
                  advisor_id: widget.advisorId,
                ),
              );
            },
          ),

          // LOGOUT
          buildDrawerItem(
            index: 5,
            icon: Icons.logout,
            iconColor: Colors.red,
            label: "Logout",
            onTap: () {
              SessionStorage.clear(); // ❌ Clear all session

              Navigator.pushReplacementNamed(context, '/'); // Back to login
            },
          )
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
