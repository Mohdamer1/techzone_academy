import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/batch_service.dart';
import '../services/auth_service.dart';
import 'topics_screen.dart';
import 'files_screen.dart';
import 'attendance_screen.dart';
import 'support_screen.dart';
import 'create_account_screen.dart';

class TrainerDashboardScreen extends StatefulWidget {
  const TrainerDashboardScreen({super.key});

  @override
  State<TrainerDashboardScreen> createState() => _TrainerDashboardScreenState();
}

class _TrainerDashboardScreenState extends State<TrainerDashboardScreen> {
  final BatchService _batchService = BatchService();
  final AuthService _authService = AuthService();
  
  List<Map<String, dynamic>> _assignedBatches = [];
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadAssignedBatches();
  }

  Future<void> _loadUserData() async {
    try {
      final userData = await _authService.getUserData();
      setState(() {
        _userData = userData;
      });
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  Future<void> _loadAssignedBatches() async {
    setState(() => _isLoading = true);
    
    try {
      final batches = await _batchService.getUserBatches();
      setState(() {
        _assignedBatches = batches;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading assigned batches: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signOut() async {
    try {
      await _authService.signOut();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const CreateAccountScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error signing out: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B80EE).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.school,
                      color: Color(0xFF0B80EE),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Trainer Dashboard',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF111418),
                          ),
                        ),
                        Text(
                          _userData?['name'] ?? 'Loading...',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout),
                    onPressed: _signOut,
                    color: const Color(0xFF111418),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _assignedBatches.isEmpty
                      ? _buildNoBatchesView()
                      : _buildBatchesView(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoBatchesView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.school,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No batches assigned yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Contact your administrator to get assigned to a batch',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          // Support button
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SupportScreen(),
                ),
              );
            },
            icon: const Icon(Icons.support_agent),
            label: const Text('Contact Support'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0B80EE),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBatchesView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'My Assigned Batches',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111418),
            ),
          ),
          const SizedBox(height: 16),
          ..._assignedBatches.map((batch) => _buildBatchCard(batch)).toList(),
        ],
      ),
    );
  }

  Widget _buildBatchCard(Map<String, dynamic> batch) {
    final batchName = batch['name'] ?? 'Unknown Batch';
    final courseName = batch['course'] ?? 'Unknown Course';
    final startDate = batch['startDate'] as Timestamp?;
    final endDate = batch['endDate'] as Timestamp?;
    final schedule = batch['schedule'] ?? 'Not specified';
    final studentCount = batch['studentCount'] ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B80EE).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.school,
                    color: Color(0xFF0B80EE),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        batchName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111418),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        courseName,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B80EE).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$studentCount students',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF0B80EE),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Batch details
            Row(
              children: [
                Expanded(
                  child: _buildDetailItem(
                    icon: Icons.calendar_today,
                    label: 'Schedule',
                    value: schedule,
                  ),
                ),
                Expanded(
                  child: _buildDetailItem(
                    icon: Icons.date_range,
                    label: 'Duration',
                    value: _formatDateRange(startDate, endDate),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Management buttons
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.book,
                    label: 'Manage Topics',
                    onTap: () => _navigateToBatchContent(batch['id'], 'topics'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.folder,
                    label: 'Manage Files',
                    onTap: () => _navigateToBatchContent(batch['id'], 'files'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.calendar_today,
                    label: 'Mark Attendance',
                    onTap: () => _navigateToBatchContent(batch['id'], 'attendance'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.people,
                    label: 'View Students',
                    onTap: () => _showBatchStudents(batch),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF111418),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(
        label,
        style: const TextStyle(fontSize: 12),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF0B80EE),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );
  }

  void _navigateToBatchContent(String batchId, String contentType) {
    switch (contentType) {
      case 'topics':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TopicsScreen(batchId: batchId),
          ),
        );
        break;
      case 'files':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FilesScreen(batchId: batchId),
          ),
        );
        break;
      case 'attendance':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AttendanceScreen(batchId: batchId),
          ),
        );
        break;
    }
  }

  void _showBatchStudents(Map<String, dynamic> batch) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Students in ${batch['name']}'),
        content: FutureBuilder<List<Map<String, dynamic>>>(
          future: _getBatchStudents(batch['id']),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (snapshot.hasError) {
              return Text('Error loading students: ${snapshot.error}');
            }
            
            final students = snapshot.data ?? [];
            
            if (students.isEmpty) {
              return const Text('No students assigned to this batch yet.');
            }
            
            return SizedBox(
              width: double.maxFinite,
              height: 300,
              child: ListView.builder(
                itemCount: students.length,
                itemBuilder: (context, index) {
                  final student = students[index];
                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(
                        student['name']?.substring(0, 1).toUpperCase() ?? '?',
                      ),
                    ),
                    title: Text(student['name'] ?? 'Unknown'),
                    subtitle: Text(student['email'] ?? ''),
                  );
                },
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _getBatchStudents(String batchId) async {
    try {
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('batchIds', arrayContains: batchId)
          .where('role', isEqualTo: 'student')
          .get();

      return usersSnapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data(),
              })
          .toList();
    } catch (e) {
      print('Error getting batch students: $e');
      return [];
    }
  }

  String _formatDateRange(Timestamp? startDate, Timestamp? endDate) {
    if (startDate == null && endDate == null) {
      return 'Not specified';
    }
    
    final start = startDate?.toDate();
    final end = endDate?.toDate();
    
    if (start != null && end != null) {
      return '${_formatDate(start)} - ${_formatDate(end)}';
    } else if (start != null) {
      return 'From ${_formatDate(start)}';
    } else if (end != null) {
      return 'Until ${_formatDate(end)}';
    }
    
    return 'Not specified';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
} 