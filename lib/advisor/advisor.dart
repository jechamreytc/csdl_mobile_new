import 'package:csdl_mobile/advisor/advisor_drawer.dart';
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
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
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
        drawer: AdvisorDrawer(
          advisorId: widget.advisor_id,
        ),
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
      width: 250,
      backgroundColor: Colors.green[700],
      child: SizedBox(
        width: 200,
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.green.shade700,
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    top: 10,
                    child: Column(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            image: DecorationImage(
                              image: AssetImage(
                                  'assets/images/csdl_background_no_bg.jpg'),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 80,
                    top: 10,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          "HK SMS",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "HK Scholars",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          "Management System",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 0,
                    top: 100 + 20,
                    child: Text(
                      "ACCOUNT",
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
                Icons.checklist,
                color: Colors.white,
              ),
              title: const Text("Evaluation",
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
                    builder: (context) => AdvisorQrScanner(
                      advisor_id: widget.advisor_id,
                    ),
                  ),
                );
              },
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
