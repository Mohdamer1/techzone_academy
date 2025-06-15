import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'batch_details_screen.dart';

class BatchManagementScreen extends StatefulWidget {
  const BatchManagementScreen({super.key});

  @override
  State<BatchManagementScreen> createState() => _BatchManagementScreenState();
}

class _BatchManagementScreenState extends State<BatchManagementScreen> {
  List<Map<String, dynamic>> _batches = [];
  List<Map<String, dynamic>> _trainers = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadBatches();
    _loadTrainers();
  }

  Future<void> _loadBatches() async {
    try {
      final batchesSnapshot = await FirebaseFirestore.instance
          .collection('batches')
          .orderBy('createdAt', descending: true)
          .get();

      setState(() {
        _batches = batchesSnapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  ...doc.data(),
                })
            .toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading batches: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _loadTrainers() async {
    try {
      final trainersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'trainer')
          .get();

      setState(() {
        _trainers = trainersSnapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  'name': doc['name'] ?? 'Unknown',
                  'email': doc['email'] ?? 'Not provided',
                })
            .toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading trainers: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: const Text('Batch Management'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111418),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Batch List
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Existing Batches',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111418),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._batches.map((batch) => _buildBatchCard(batch)).toList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBatchCard(Map<String, dynamic> batch) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BatchDetailsScreen(batch: batch),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          title: Text(
            batch['name'],
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF111418),
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                'Trainer: ${batch['trainerName'] ?? 'Unknown'}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF60758A),
                ),
              ),
              Text(
                'Email: ${batch['trainerEmail'] ?? 'Not provided'}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF60758A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Students: ${(batch['students'] as List).length}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF60758A),
                ),
              ),
            ],
          ),
          trailing: PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              if (value == 'delete') {
                // Show confirmation dialog
                final shouldDelete = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Batch'),
                    content: const Text('Are you sure you want to delete this batch? This action cannot be undone.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );

                if (shouldDelete == true) {
                  try {
                    // Remove batch from trainers' batchIds
                    final trainersSnapshot = await FirebaseFirestore.instance
                        .collection('users')
                        .where('role', isEqualTo: 'trainer')
                        .where('batchIds', arrayContains: batch['id'])
                        .get();

                    for (var trainerDoc in trainersSnapshot.docs) {
                      await trainerDoc.reference.update({
                        'batchIds': FieldValue.arrayRemove([batch['id']])
                      });
                    }

                    // Remove batch from students' batchId
                    final studentsSnapshot = await FirebaseFirestore.instance
                        .collection('users')
                        .where('role', isEqualTo: 'student')
                        .where('batchId', isEqualTo: batch['id'])
                        .get();

                    for (var studentDoc in studentsSnapshot.docs) {
                      await studentDoc.reference.update({
                        'batchId': null
                      });
                    }

                    // Delete the batch
                    await FirebaseFirestore.instance
                        .collection('batches')
                        .doc(batch['id'])
                        .delete();

                    // Reload batches
                    await _loadBatches();

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Batch deleted successfully')),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error deleting batch: ${e.toString()}')),
                      );
                    }
                  }
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete Batch', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 