import 'package:flutter/material.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final List<Map<String, dynamic>> attendanceHistory = [
    {'date': '10/10/2024', 'status': 'Present'},
    {'date': '10/11/2024', 'status': 'Absent'},
    {'date': '10/12/2024', 'status': 'Present'},
    {'date': '10/13/2024', 'status': 'Absent'},
    {'date': '10/14/2024', 'status': 'Present'},
    {'date': '10/15/2024', 'status': 'Absent'},
    {'date': '10/16/2024', 'status': 'Present'},
    {'date': '10/17/2024', 'status': 'Absent'},
    {'date': '10/18/2024', 'status': 'Present'},
    {'date': '10/19/2024', 'status': 'Absent'},
    {'date': '10/20/2024', 'status': 'Present'},
    {'date': '10/21/2024', 'status': 'Absent'},
    {'date': '10/22/2024', 'status': 'Present'},
    {'date': '10/23/2024', 'status': 'Absent'},
    {'date': '10/24/2024', 'status': 'Present'},
    {'date': '10/25/2024', 'status': 'Absent'},
    {'date': '10/26/2024', 'status': 'Present'},
    {'date': '10/27/2024', 'status': 'Absent'},
    {'date': '10/28/2024', 'status': 'Present'},
    {'date': '10/29/2024', 'status': 'Absent'},
    {'date': '10/30/2024', 'status': 'Present'},
    {'date': '10/31/2024', 'status': 'Absent'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Color(0xFF111418)),
                  onPressed: () => Navigator.pop(context),
                ),
                const Expanded(
                  child: Text(
                    'Attendance History',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111418),
                    ),
                  ),
                ),
                const SizedBox(width: 48), // To balance the back button
              ],
            ),
          ),

          // Calendar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                // Month selector
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left, color: Color(0xFF111418)),
                      onPressed: () {},
                    ),
                    const Text(
                      'October 2024',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111418),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right, color: Color(0xFF111418)),
                      onPressed: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Week days
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: const [
                    Text('S', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('M', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('T', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('W', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('T', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('F', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('S', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),

                // Calendar grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    childAspectRatio: 1,
                  ),
                  itemCount: 31,
                  itemBuilder: (context, index) {
                    final day = index + 1;
                    final isPresent = day % 2 == 0;
                    return Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isPresent ? const Color(0xFF0C7FF2) : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          day.toString(),
                          style: TextStyle(
                            color: isPresent ? Colors.white : const Color(0xFF111418),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Attendance list
          Expanded(
            child: ListView.builder(
              itemCount: attendanceHistory.length,
              itemBuilder: (context, index) {
                final record = attendanceHistory[index];
                final isPresent = record['status'] == 'Present';
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F2F5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          isPresent ? Icons.check_circle : Icons.cancel,
                          color: const Color(0xFF111418),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              record['date'],
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF111418),
                              ),
                            ),
                            Text(
                              record['status'],
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF60758A),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        record['status'],
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF111418),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
} 