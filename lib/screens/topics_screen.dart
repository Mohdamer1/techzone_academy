import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'files_screen.dart';

class TopicsScreen extends StatelessWidget {
  const TopicsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final topics = [
      'Introduction to Programming',
      'Data Structures and Algorithms',
      'Object-Oriented Programming',
      'Database Management Systems',
      'Software Engineering Principles',
      'Web Development Fundamentals',
      'Mobile App Development',
      'Cloud Computing Concepts',
      'Artificial Intelligence and Machine Learning',
      'Cybersecurity Fundamentals',
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
                      'Topics',
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
            // Topics list
            Expanded(
              child: ListView.separated(
                itemCount: topics.length,
                separatorBuilder: (context, index) => const SizedBox(height: 0),
                itemBuilder: (context, index) {
                  return _buildTopicCard(
                    context,
                    title: topics[index],
                    trainer: 'Trainer: Dr. Emily Carter',
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

  Widget _buildTopicCard(BuildContext context, {required String title, required String trainer}) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const FilesScreen(),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F2F5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.insert_drive_file, color: Color(0xFF111418)),
                  ),
                  const SizedBox(width: 16),
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
                        trainer,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF60758A),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                child: const Icon(Icons.chevron_right, color: Color(0xFF111418)),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 