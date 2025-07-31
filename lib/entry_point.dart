import 'package:csdl_mobile/advisor/advisor.dart';
import 'package:csdl_mobile/fresh_student/fresh_student.dart';
import 'package:csdl_mobile/main.dart';
import 'package:csdl_mobile/session_storage.dart';
import 'package:csdl_mobile/student/student_dashboard.dart';
import 'package:flutter/material.dart';

class EntryPoint extends StatelessWidget {
  const EntryPoint({super.key});

  @override
  Widget build(BuildContext context) {
    final studentId = SessionStorage.getItem("student_id");
    final advisorId = SessionStorage.getItem("advisor_id");
    final isFresh = SessionStorage.getItem("is_fresh");

    if (studentId != null) {
      if (isFresh == "1") {
        return FreshStudent(student_id: studentId);
      } else {
        return StudentDashboard(student_id: studentId);
      }
    } else if (advisorId != null) {
      return Advisor(advisor_id: advisorId);
    } else {
      return const HomePage(); // default login screen
    }
  }
}
