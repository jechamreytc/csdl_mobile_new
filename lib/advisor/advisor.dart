import 'package:csdl_mobile/advisor/advisor_edit_profile.dart';
import 'package:csdl_mobile/advisor/advisor_qr_scanner.dart';
import 'package:csdl_mobile/advisor/advisor_scholar_list.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class Advisor extends StatefulWidget {
  final String advisor_id;
  const Advisor({
    super.key,
    required this.advisor_id,
  });

  @override
  _AdvisorState createState() => _AdvisorState();
}

class _AdvisorState extends State<Advisor> {
  String? selectedOption;

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Scaffold(
        backgroundColor: Colors.blue.shade800,
        appBar: AppBar(
          title: const Text('Advisor'),
          backgroundColor: Colors.blue.shade800,
        ),
        drawer: advisorDrawer(context),
        body: const Center(
          child: Column(
            children: [
              Text('Advisor'),
            ],
          ),
        ),
      ),
    );
  }

  Widget advisorDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: const Color.fromARGB(255, 9, 99, 58),
      child: SizedBox(
        width: 200, // Set the desired width of the drawer
        child: Column(
          children: [
            DrawerHeader(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: const Text("Advisor",
                    style: TextStyle(color: Colors.white)),
              ),
            ),
            ListTile(
              leading: const Icon(
                Icons.settings,
                color: Colors.white,
              ),
              title: const Text("Account Settings",
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                showShadSheet(
                  side: ShadSheetSide.right,
                  context: context,
                  builder: (context) => AdvisorEditProfileSheet(
                    side: ShadSheetSide.right,
                    advisor_id: widget.advisor_id,
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.list,
                color: Colors.white,
              ),
              title: const Text("Assigned Scholar",
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AdvisorScholarList(
                      advisor_id: widget.advisor_id,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.qr_code_scanner,
                color: Colors.white,
              ),
              title: const Text(
                "QR Scanner",
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AdvisorQrScanner(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.logout,
                color: Colors.white,
              ),
              title: const Text(
                'Logout',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pushReplacementNamed(context, '/home');
              },
            ),
            // ListTile(
            //   leading: const Icon(
            //     Icons.qr_code_scanner,
            //     color: Colors.white,
            //   ),
            //   title: DropdownButton<String>(
            //     value: selectedOption,
            //     dropdownColor: const Color.fromARGB(255, 9, 99, 58),
            //     items: [
            //       DropdownMenuItem(
            //         value: 'regular',
            //         child: const Text(
            //           'Regular',
            //           style: TextStyle(color: Colors.white),
            //         ),
            //       ),
            //       DropdownMenuItem(
            //         value: 'adjustment',
            //         child: const Text(
            //           'Adjustment',
            //           style: TextStyle(color: Colors.white),
            //         ),
            //       ),
            //     ],
            //     onChanged: (value) {
            //       setState(() {
            //         selectedOption = value;
            //       });

            //       if (value == 'regular') {
            //         Navigator.push(
            //           context,
            //           MaterialPageRoute(
            //             builder: (context) => const AdvisorQrScanner(),
            //           ),
            //         );
            //       } else if (value == 'adjustment') {
            //         Navigator.push(
            //           context,
            //           MaterialPageRoute(
            //             builder: (context) =>
            //                 const AdvisorQrScanner(), // Replace with Adjustment Page if needed
            //           ),
            //         );
            //       }
            //     },
            //     hint: const Text(
            //       "QR Scanner",
            //       style: TextStyle(color: Colors.white),
            //     ),
            //     underline: Container(),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}
