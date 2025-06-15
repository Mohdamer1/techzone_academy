import 'package:flutter/material.dart';

class TrainerDashboardScreen extends StatelessWidget {
  const TrainerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: const DecorationImage(
                        image: NetworkImage('https://lh3.googleusercontent.com/aida-public/AB6AXuAY51RKvmv7U5BFY3o-9pbc-ZYiCh-PP-tifCSRE3vUC6qkBpZl3WLWSeFHFQcclWfN54rWh0h2wZwkzL9Qjj85AiXFNjK2RuRhNt4hwK9LCwG0H1rM7Z5oBz5vV1n-lCftgskUQvuuhTqTgBG6EQ9h-SHx39K9_tGLCw6txykGC0bM2auCmkDOccK3X8lENlkN-vTW5uU_CXPqZ6Tj5jmJufV2-oFeMAixPkvyrLSfbAo8i_KKM1sGQOOYjv1yPhj3lUt7UNfK_WE'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'Trainer Dashboard',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111418),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), // To balance the profile picture
                ],
              ),
            ),

            // Assigned Batches Section
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 24, 16, 12),
              child: Text(
                'Assigned Batches',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111418),
                ),
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildBatchCard(
                    imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuCLzyDas6bsFK60OkYpo-7quEMn1VX6c8MeTBpnqtiWw1zaO-PX-DYKZulIH0sk3JJSdwXnG0lBsKs3rrkPNfan-Dd-Y62hQ2Snt0blXT5kzPQJv9ZmmX5l2zKPDseNGglba_7HaOsQ240DK_iKg17kbTHxn7V5pIn8i1pLVicqJ6VYaUCD1X6Czj0_JdFBBU4gBePwPtGeF0z9jbf57cM_McZnUj-jbZILhJdMrzo0C3IPAo7xMpuZwQ_vThagwIvABk8GQAEXOa4',
                    title: 'Batch A',
                    studentCount: '10 students',
                  ),
                  const SizedBox(width: 12),
                  _buildBatchCard(
                    imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuARnQopq-FDiGG3R5jCC7avt25_dW25qR7jRG9pl8LR_ShLFrNEgyQX9NwcTwAXwf51YNWpGqXs8w2eABAt-nMbLOFCoOki14ADIvVHXJZ0F1aSd97LJrn6u3fDyXjZN7HhORx00SPjY8RuBY3kCa9OeQfXpn3H2zHKRSQPHWcQARfOoDYUk-3BNB2J34dyDzWvoK__f2LtoAgJeWORA1zqyH4mB9vJM0P_VD19ghMX75Id7IoISdIdLyI-WzkbxzP8Pj2qA0VDOpc',
                    title: 'Batch B',
                    studentCount: '15 students',
                  ),
                ],
              ),
            ),

            // Upcoming Classes Section
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 24, 16, 12),
              child: Text(
                'Upcoming Classes',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111418),
                ),
              ),
            ),
            _buildClassItem(
              title: 'Class A',
              time: '10:00 AM - 12:00 PM',
            ),
            _buildClassItem(
              title: 'Class B',
              time: '2:00 PM - 4:00 PM',
            ),

            // Quick Actions Section
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 24, 16, 12),
              child: Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111418),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0C7FF2),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Mark Attendance',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF0F2F5),
                        foregroundColor: const Color(0xFF111418),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Upload Materials',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Schedule Section
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 24, 16, 12),
              child: Text(
                'My Schedule',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111418),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
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
                        'July 2024',
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
                      final isSelected = day == 5;
                      return Container(
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF0C7FF2) : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            day.toString(),
                            style: TextStyle(
                              color: isSelected ? Colors.white : const Color(0xFF111418),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBatchCard({
    required String imageUrl,
    required String title,
    required String studentCount,
  }) {
    return Container(
      width: 160,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            height: 160,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(
                image: NetworkImage(imageUrl),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF111418),
            ),
          ),
          Text(
            studentCount,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF60758A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassItem({
    required String title,
    required String time,
  }) {
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
            child: const Icon(Icons.calendar_today, color: Color(0xFF111418)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
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
                  time,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF60758A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 