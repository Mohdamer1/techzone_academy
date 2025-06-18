import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BatchAssignmentScreen extends StatefulWidget {
  const BatchAssignmentScreen({super.key});

  @override
  State<BatchAssignmentScreen> createState() => _BatchAssignmentScreenState();
}

class _BatchAssignmentScreenState extends State<BatchAssignmentScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  List<Map<String, dynamic>> _batches = [];
  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _trainers = [];
  List<String> _paidStudentEmails = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      // Load batches
      final batchesSnapshot = await _firestore.collection('batches').get();
      final batches = batchesSnapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data(),
              })
          .toList();

      // Load students
      final studentsSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'student')
          .get();
      final students = studentsSnapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data(),
              })
          .toList();

      // Load trainers
      final trainersSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'trainer')
          .get();
      final trainers = trainersSnapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data(),
              })
          .toList();

      // Load all unique student emails from payments
      final paymentsSnapshot = await _firestore.collection('payments').get();
      final paidEmailsSet = <String>{};
      for (final doc in paymentsSnapshot.docs) {
        final data = doc.data();
        final email = data['studentEmail'] as String?;
        if (email != null && email.isNotEmpty) {
          paidEmailsSet.add(email);
        }
      }

      setState(() {
        _batches = batches;
        _students = students;
        _trainers = trainers;
        _paidStudentEmails = paidEmailsSet.toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _assignUserToBatch(String userId, String batchId, String userType) async {
    try {
      // Always use batchRefId for user assignment
      String batchRefId = batchId;
      String actualBatchDocId = batchId;
      // Find the batch document by batchRefId if needed
      final batchQuery = await _firestore
          .collection('batches')
          .where('batchRefId', isEqualTo: batchId)
          .get();
      if (batchQuery.docs.isNotEmpty) {
        actualBatchDocId = batchQuery.docs.first.id;
        batchRefId = batchQuery.docs.first.data()['batchRefId'] ?? batchId;
      }

      // Update user's batchIds array with batchRefId
      await _firestore.collection('users').doc(userId).update({
        'batchIds': FieldValue.arrayUnion([batchRefId]),
      });

      // Update batch's user lists
      if (userType == 'student') {
        await _firestore.collection('batches').doc(actualBatchDocId).update({
          'students': FieldValue.arrayUnion([userId]),
        });
      } else if (userType == 'trainer') {
        // For trainers, also update the single trainerId field if it's empty
        final batchDoc = await _firestore.collection('batches').doc(actualBatchDocId).get();
        final batchData = batchDoc.data();
        if (batchData != null && (batchData['trainerId'] == null || batchData['trainerId'].toString().isEmpty)) {
          // Get trainer information
          final trainerDoc = await _firestore.collection('users').doc(userId).get();
          final trainerName = trainerDoc.data()?['name'] ?? 'Unknown';
          final trainerEmail = trainerDoc.data()?['email'] ?? 'Not provided';
          await _firestore.collection('batches').doc(actualBatchDocId).update({
            'trainerId': userId,
            'trainerName': trainerName,
            'trainerEmail': trainerEmail,
            'trainers': FieldValue.arrayUnion([userId]),
          });
        } else {
          await _firestore.collection('batches').doc(actualBatchDocId).update({
            'trainers': FieldValue.arrayUnion([userId]),
          });
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$userType assigned to batch successfully')),
        );
        _loadData(); // Reload data to reflect changes
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error assigning $userType: $e')),
        );
      }
    }
  }

  Future<void> _removeUserFromBatch(String userId, String batchId, String userType) async {
    try {
      // First, get the actual batch document ID if batchId is a batchRefId
      String actualBatchId = batchId;
      final batchQuery = await _firestore
          .collection('batches')
          .where('batchRefId', isEqualTo: batchId)
          .get();
      
      if (batchQuery.docs.isNotEmpty) {
        actualBatchId = batchQuery.docs.first.id;
      }

      // Update user's batchIds array
      await _firestore.collection('users').doc(userId).update({
        'batchIds': FieldValue.arrayRemove([batchId]), // Keep the original batchId (could be batchRefId)
      });

      // Update batch's user lists
      if (userType == 'student') {
        await _firestore.collection('batches').doc(actualBatchId).update({
          'students': FieldValue.arrayRemove([userId]),
        });
      } else if (userType == 'trainer') {
        // For trainers, also clear the single trainerId field if it matches
        final batchDoc = await _firestore.collection('batches').doc(actualBatchId).get();
        final batchData = batchDoc.data();
        
        if (batchData != null && batchData['trainerId'] == userId) {
          await _firestore.collection('batches').doc(actualBatchId).update({
            'trainerId': null,
            'trainerName': null,
            'trainerEmail': null,
            'trainers': FieldValue.arrayRemove([userId]),
          });
        } else {
          await _firestore.collection('batches').doc(actualBatchId).update({
            'trainers': FieldValue.arrayRemove([userId]),
          });
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$userType removed from batch successfully')),
        );
        _loadData(); // Reload data to reflect changes
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error removing $userType: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Batch Assignment'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111418),
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF0F2F5),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _batches.isEmpty
              ? _buildEmptyView()
              : _buildBatchesList(),
    );
  }

  Widget _buildEmptyView() {
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
            'No batches available',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create batches first to assign users',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBatchesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _batches.length,
      itemBuilder: (context, index) {
        final batch = _batches[index];
        return _buildBatchCard(batch);
      },
    );
  }

  Widget _buildBatchCard(Map<String, dynamic> batch) {
    final batchName = batch['name'] ?? 'Unknown Batch';
    final courseName = batch['course'] ?? 'Unknown Course';
    final students = List<String>.from(batch['students'] ?? []);
    final trainers = List<String>.from(batch['trainers'] ?? []);
    final trainerId = batch['trainerId'] as String?;

    // Get assigned students and trainers
    final assignedStudents = _students.where((student) => students.contains(student['id'])).toList();
    
    // For trainers, check both the trainers array and the single trainerId field
    final assignedTrainers = _trainers.where((trainer) => 
      trainers.contains(trainer['id']) || trainer['id'] == trainerId
    ).toList();

    // Only show students who have made a payment and have an account (by email)
    final availableStudents = _students.where((student) =>
      !students.contains(student['id']) &&
      _paidStudentEmails.contains(student['email'])
    ).toList();

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
              ],
            ),
            const SizedBox(height: 16),

            // Students Section
            _buildUserSection(
              title: 'Students',
              users: assignedStudents,
              availableUsers: availableStudents,
              batchId: batch['batchRefId'] ?? batch['id'], // Use batchRefId if available
              userType: 'student',
            ),

            const SizedBox(height: 16),

            // Trainers Section
            _buildUserSection(
              title: 'Trainers',
              users: assignedTrainers,
              availableUsers: _trainers.where((trainer) => 
                !trainers.contains(trainer['id']) && trainer['id'] != trainerId
              ).toList(),
              batchId: batch['batchRefId'] ?? batch['id'], // Use batchRefId if available
              userType: 'trainer',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserSection({
    required String title,
    required List<Map<String, dynamic>> users,
    required List<Map<String, dynamic>> availableUsers,
    required String batchId,
    required String userType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111418),
              ),
            ),
            if (availableUsers.isNotEmpty)
              TextButton.icon(
                onPressed: () => _showUserSelectionDialog(availableUsers, batchId, userType),
                icon: const Icon(Icons.add, size: 16),
                label: Text('Add $userType'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF0B80EE),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (users.isEmpty)
          Text(
            'No $userType assigned',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          )
        else
          ...users.map((user) => _buildUserTile(user, batchId, userType)).toList(),
      ],
    );
  }

  Widget _buildUserTile(Map<String, dynamic> user, String batchId, String userType) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            child: Text(
              user['name']?.substring(0, 1).toUpperCase() ?? '?',
              style: const TextStyle(fontSize: 12),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user['name'] ?? 'Unknown',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  user['email'] ?? '',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.remove_circle, color: Colors.red, size: 20),
            onPressed: () => _removeUserFromBatch(user['id'], batchId, userType),
          ),
        ],
      ),
    );
  }

  void _showUserSelectionDialog(List<Map<String, dynamic>> availableUsers, String batchId, String userType) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select $userType to assign'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: availableUsers.length,
            itemBuilder: (context, index) {
              final user = availableUsers[index];
              return ListTile(
                leading: CircleAvatar(
                  child: Text(
                    user['name']?.substring(0, 1).toUpperCase() ?? '?',
                  ),
                ),
                title: Text(user['name'] ?? 'Unknown'),
                subtitle: Text(user['email'] ?? ''),
                onTap: () async {
                  Navigator.of(context).pop();
                  if (userType == 'student') {
                    await _assignPaidStudentToBatch(user, batchId);
                  } else {
                    _assignUserToBatch(user['id'], batchId, userType);
                  }
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _assignPaidStudentToBatch(Map<String, dynamic> paidStudent, String batchId) async {
    try {
      // Check if user exists in users collection
      final userQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: paidStudent['email'])
          .limit(1)
          .get();
      String userId;
      if (userQuery.docs.isNotEmpty) {
        userId = userQuery.docs.first.id;
      } else {
        // Create minimal user record
        final newUser = await _firestore.collection('users').add({
          'email': paidStudent['email'],
          'name': paidStudent['name'],
          'role': 'student',
          'batchIds': [],
        });
        userId = newUser.id;
      }
      await _assignUserToBatch(userId, batchId, 'student');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error assigning student: $e')),
        );
      }
    }
  }
} 