import 'package:csdl_mobile/marketing/hk_leads.dart';
import 'package:csdl_mobile/marketing/marketing.dart';
import 'package:csdl_mobile/marketing/marketing_edit_profile.dart';
import 'package:csdl_mobile/marketing/marketing_settings.dart';
import 'package:csdl_mobile/session_storage.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class MarketingDrawer extends StatefulWidget {
  final String adminEmail;
  final int currentIndex; // Add current screen index

  const MarketingDrawer({Key? key, required this.adminEmail, this.currentIndex = 0}) : super(key: key);

  @override
  _MarketingDrawerState createState() => _MarketingDrawerState();
}

class _MarketingDrawerState extends State<MarketingDrawer> {
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
      backgroundColor: const Color(0xFF0F172A),
      child: ListView(
        children: [
          // Drawer header stays the same
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
                Positioned(
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
                    "",
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

          // Dashboard
          buildDrawerItem(
            index: 0,
            icon: Icons.dvr_rounded,
            label: "Dashboard",
            onTap: () {
              setState(() => selectedIndex = 0);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => MarketingDashboard(
                    adminEmail: widget.adminEmail,
                  ),
                ),
              );
            },
          ),

          // HK Leads
          buildDrawerItem(
            index: 1,
            icon: Icons.leaderboard,
            label: "HK Leads",
            onTap: () {
              setState(() => selectedIndex = 1);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => HKLeadsPage(
                          adminEmail: widget.adminEmail,
                        )),
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
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => MarketingSettings(
                    adminEmail: widget.adminEmail,
                  ),
                ),
              );
            },
          ),

          // Settings & Privacy (expandable)
          // Settings & Privacy (expandable)
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
//                     builder: (context) => MarketingEditProfile(
//                       adminEmail: widget.adminEmail,
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
//                     builder: (context) => MarketingEditProfile(
//                       adminEmail: widget.adminEmail,
//                     ),
//                   );
//                 },
//               ),
//             ),
//           ],

// Logout
          buildDrawerItem(
            index: 3,
            icon: Icons.logout,
            iconColor: Colors.red,
            label: "Logout",
            onTap: () {
              setState(() => selectedIndex = 3); // Set selected on logout too
              SessionStorage.clear();
              Navigator.pushReplacementNamed(context, '/');
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
        leading: Icon(icon, color: iconColor, size: 20),
        title: Text(label, style: const TextStyle(color: Colors.white)),
        onTap: onTap,
      ),
    );
  }
}
