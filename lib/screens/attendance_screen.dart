import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/batch_service.dart';
import '../services/auth_service.dart';

class AttendanceScreen extends StatefulWidget {
  final String? batchId;
  
  const AttendanceScreen({super.key, this.batchId});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final BatchService _batchService = BatchService();
  final AuthService _authService = AuthService();
  
  List<Map<String, dynamic>> _attendanceRecords = [];
  List<Map<String, dynamic>> _batchStudents = [];
  Map<String, dynamic>? _userData;
  String? _userRole;
  bool _isLoading = true;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadAttendanceData();
  }

  Future<void> _loadUserData() async {
    try {
      final userData = await _authService.getUserData();
      final role = await _batchService.getUserRole();
      setState(() {
        _userData = userData;
        _userRole = role;
      });
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  Future<void> _loadAttendanceData() async {
    setState(() => _isLoading = true);
    
    try {
      if (widget.batchId != null) {
        // Load attendance for specific batch
        final attendance = await _batchService.getBatchAttendance(widget.batchId!);
        final students = await _getBatchStudents(widget.batchId!);
        setState(() {
          _attendanceRecords = attendance;
          _batchStudents = students;
          _isLoading = false;
        });
      } else {
        // Load all attendance for user's batches (for students)
        final batches = await _batchService.getUserBatches();
        List<Map<String, dynamic>> allAttendance = [];
        
        for (final batch in batches) {
          final batchAttendance = await _batchService.getBatchAttendance(batch['id']);
          for (final record in batchAttendance) {
            allAttendance.add({
              ...record,
              'batchName': batch['name'],
              'batchId': batch['id'],
            });
          }
        }
        
        setState(() {
          _attendanceRecords = allAttendance;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading attendance data: $e');
      setState(() => _isLoading = false);
    }
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

  Future<void> _markAttendance() async {
    if (widget.batchId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a batch first')),
      );
      return;
    }

    if (_batchStudents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No students assigned to this batch')),
      );
      return;
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _buildAttendanceDialog(),
    );

    if (result != null) {
      try {
        await _batchService.markAttendance(widget.batchId!, {
          'date': Timestamp.fromDate(_selectedDate),
          'markedBy': _userData?['name'] ?? 'Unknown Trainer',
          'students': result['students'],
          'totalStudents': _batchStudents.length,
          'presentCount': result['presentCount'],
          'absentCount': result['absentCount'],
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Attendance marked successfully')),
          );
          _loadAttendanceData();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error marking attendance: $e')),
          );
        }
      }
    }
  }

  Widget _buildAttendanceDialog() {
    Map<String, bool> studentAttendance = {};
    for (final student in _batchStudents) {
      studentAttendance[student['id']] = true; // Default to present
    }

    return StatefulBuilder(
      builder: (context, setState) {
        int presentCount = studentAttendance.values.where((present) => present).length;
        int absentCount = _batchStudents.length - presentCount;

        return AlertDialog(
          title: Text('Mark Attendance - ${_formatDate(_selectedDate)}'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Present: $presentCount'),
                    Text('Absent: $absentCount'),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: _batchStudents.length,
                    itemBuilder: (context, index) {
                      final student = _batchStudents[index];
                      final studentId = student['id'];
                      final isPresent = studentAttendance[studentId] ?? true;

                      return ListTile(
                        title: Text(student['name'] ?? 'Unknown'),
                        subtitle: Text(student['email'] ?? ''),
                        trailing: Switch(
                          value: isPresent,
                          onChanged: (value) {
                            setState(() {
                              studentAttendance[studentId] = value;
                            });
                          },
                        ),
                        leading: Icon(
                          isPresent ? Icons.check_circle : Icons.cancel,
                          color: isPresent ? Colors.green : Colors.red,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop({
                  'students': studentAttendance,
                  'presentCount': presentCount,
                  'absentCount': absentCount,
                });
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

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
                    'Attendance',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111418),
                    ),
                  ),
                ),
                if (_userRole == 'trainer' && widget.batchId != null)
                  IconButton(
                    icon: const Icon(Icons.add, color: Color(0xFF111418)),
                    onPressed: _markAttendance,
                  )
                else
                  const SizedBox(width: 48), // To balance the back button
              ],
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _attendanceRecords.isEmpty
                    ? _buildEmptyView()
                    : _buildAttendanceList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _userRole == 'trainer' ? 'No attendance records yet' : 'No attendance records available',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _userRole == 'trainer' 
                ? 'Mark attendance for your first class'
                : 'Attendance records will appear here once marked by your trainer',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          if (_userRole == 'trainer' && widget.batchId != null) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _markAttendance,
              icon: const Icon(Icons.calendar_today),
              label: const Text('Mark Attendance'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0B80EE),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAttendanceList() {
    return ListView.builder(
      itemCount: _attendanceRecords.length,
      itemBuilder: (context, index) {
        final record = _attendanceRecords[index];
        final date = record['date'] as Timestamp?;
        final presentCount = record['presentCount'] ?? 0;
        final absentCount = record['absentCount'] ?? 0;
        final totalStudents = record['totalStudents'] ?? 0;
        final markedBy = record['markedBy'] ?? 'Unknown';
        final batchName = record['batchName'];

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Card(
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
                          color: const Color(0xFFF0F2F5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.calendar_today,
                          color: Color(0xFF111418),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              date != null ? _formatDate(date.toDate()) : 'Unknown Date',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF111418),
                              ),
                            ),
                            if (batchName != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Batch: $batchName',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF60758A),
                                ),
                              ),
                            ],
                            const SizedBox(height: 4),
                            Text(
                              'Marked by: $markedBy',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF60758A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildAttendanceStat('Present', presentCount, Colors.green),
                      _buildAttendanceStat('Absent', absentCount, Colors.red),
                      _buildAttendanceStat('Total', totalStudents, Colors.blue),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAttendanceStat(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF60758A),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
} 