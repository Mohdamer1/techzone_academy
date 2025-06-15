import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FilesScreen extends StatelessWidget {
  const FilesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final files = [
      {'title': 'Assignment 1', 'date': 'Uploaded on 2024-01-15'},
      {'title': 'Lecture Notes', 'date': 'Uploaded on 2024-01-20'},
      {'title': 'Project Guidelines', 'date': 'Uploaded on 2024-01-25'},
      {'title': 'Quiz 1', 'date': 'Uploaded on 2024-02-01'},
      {'title': 'Midterm Exam', 'date': 'Uploaded on 2024-02-05'},
      {'title': 'Final Project', 'date': 'Uploaded on 2024-02-10'},
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, size: 24, color: Color(0xFF111418)),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Expanded(
                    child: Text(
                      'Files',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.015,
                        color: Color(0xFF111418),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), // To balance the back icon
                ],
              ),
            ),
            // Files list
            Expanded(
              child: ListView.separated(
                itemCount: files.length,
                separatorBuilder: (context, index) => const SizedBox(height: 0),
                itemBuilder: (context, index) {
                  return _buildFileCard(
                    title: files[index]['title']!,
                    date: files[index]['date']!,
                  );
                },
              ),
            ),
            // Bottom padding
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildFileCard({required String title, required String date}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF111418),
                  ),
                ),
                Text(
                  date,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF60758A),
                  ),
                ),
              ],
            ),
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              child: const Icon(Icons.download, color: Color(0xFF111418)),
            ),
          ],
        ),
      ),
    );
  }
} 