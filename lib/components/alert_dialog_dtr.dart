import 'package:flutter/material.dart';

Widget showAlertDialog(BuildContext context, String title, String name,
    String id, List<Map<String, String>> data) {
  return AlertDialog(
    titlePadding: const EdgeInsets.all(8), // Minimal padding for the title
    contentPadding:
        EdgeInsets.zero, // Remove content padding to touch the edges
    title: Row(
      children: [
        const CircleAvatar(
          radius: 30,
          backgroundImage:
              AssetImage('assets/your_image.png'), // Add your image here
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              'Name: $name',
              style: const TextStyle(fontSize: 12),
            ),
            Text(
              'ID: $id',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ],
    ),
    content: SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(
            vertical: 5.0), // Minimal padding for the content
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DataTable(
              columnSpacing: 29,
              columns: const [
                DataColumn(
                  label: Text(
                    'Date',
                    style: TextStyle(fontSize: 10),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Time In',
                    style: TextStyle(fontSize: 10),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Time Out',
                    style: TextStyle(fontSize: 10),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Total Time',
                    style: TextStyle(fontSize: 10),
                  ),
                ),
              ],
              rows: data.map((row) {
                final timeIn = DateTime.parse(row['time_in']!);
                final timeOut = DateTime.parse(row['time_out']!);
                final totalTime = timeOut.difference(timeIn).inHours;

                return DataRow(cells: [
                  DataCell(Text(row['date']!)),
                  DataCell(Text(row['time_in']!)),
                  DataCell(Text(row['time_out']!)),
                  DataCell(Text('$totalTime hours')),
                ]);
              }).toList(),
            ),
          ],
        ),
      ),
    ),
    actions: <Widget>[
      TextButton(
        child: const Text('Close'),
        onPressed: () {
          Navigator.of(context).pop();
        },
      ),
    ],
  );
  
}

