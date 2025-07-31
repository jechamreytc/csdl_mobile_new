import 'package:csdl_mobile/advisor/advisor_edit_profile.dart';
// import 'package:csdl_mobile/student/edit_profile_sheet.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class AdvisorSettings extends StatefulWidget {
  final String advisor_id;

  const AdvisorSettings({
    Key? key,
    required this.advisor_id,
  }) : super(key: key);
  @override
  _AdvisorSettingsState createState() => _AdvisorSettingsState();
}

class _AdvisorSettingsState extends State<AdvisorSettings> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: const Color(0xFF006400),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ShadButton(
                child: const Text('Account Settings'),
                onPressed: () => showShadSheet(
                  side: ShadSheetSide.right,
                  context: context,
                  builder: (context) => AdvisorEditProfileSheet(
                    side: ShadSheetSide.right,
                    advisor_id: widget.advisor_id,
                  ),
                ),
                backgroundColor: Colors.white,
              ),
              ShadButton(
                child: const Text('Logout'),
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/home');
                },
                backgroundColor: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
