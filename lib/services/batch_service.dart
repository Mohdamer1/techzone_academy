import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BatchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Get user's assigned batches
  Future<List<Map<String, dynamic>>> getUserBatches() async {
    try {
      if (currentUser == null) return [];

      final userDoc = await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .get();

      if (!userDoc.exists) return [];

      final userData = userDoc.data()!;
      final role = userData['role'] as String?;
      final batchIds = List<String>.from(userData['batchIds'] ?? []);

      if (batchIds.isEmpty) return [];

      // Get batch details - try both by document ID and by batchRefId
      List<Map<String, dynamic>> batches = [];
      
      for (String batchId in batchIds) {
        // First try to find by document ID
        var batchDoc = await _firestore
            .collection('batches')
            .doc(batchId)
            .get();
        
        // If not found, try to find by batchRefId
        if (!batchDoc.exists) {
          final batchQuery = await _firestore
              .collection('batches')
              .where('batchRefId', isEqualTo: batchId)
              .get();
          
          if (batchQuery.docs.isNotEmpty) {
            batchDoc = batchQuery.docs.first;
          }
        }
        
        if (batchDoc.exists) {
          final batchData = batchDoc.data()!;
          
          // Handle both old and new data structures
          bool hasAccess = false;
          
          if (role == 'trainer') {
            // Check if trainer is assigned via trainerId or trainers array
            final trainerId = batchData['trainerId'] as String?;
            final trainers = List<String>.from(batchData['trainers'] ?? []);
            hasAccess = trainerId == currentUser!.uid || trainers.contains(currentUser!.uid);
          } else if (role == 'student') {
            // Check if student is assigned via students array
            final students = List<String>.from(batchData['students'] ?? []);
            hasAccess = students.contains(currentUser!.uid);
          }
          
          if (hasAccess) {
            batches.add({
              'id': batchDoc.id,
              ...batchData,
            });
          }
        }
      }

      return batches;
    } catch (e) {
      print('Error getting user batches: $e');
      return [];
    }
  }

  // Get batch details by ID
  Future<Map<String, dynamic>?> getBatchById(String batchId) async {
    try {
      final doc = await _firestore
          .collection('batches')
          .doc(batchId)
          .get();

      if (!doc.exists) return null;

      return {
        'id': doc.id,
        ...doc.data()!,
      };
    } catch (e) {
      print('Error getting batch: $e');
      return null;
    }
  }

  // Check if user has access to a specific batch
  Future<bool> hasBatchAccess(String batchId) async {
    try {
      if (currentUser == null) return false;

      final userDoc = await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .get();

      if (!userDoc.exists) return false;

      final userData = userDoc.data()!;
      final batchIds = List<String>.from(userData['batchIds'] ?? []);

      return batchIds.contains(batchId);
    } catch (e) {
      print('Error checking batch access: $e');
      return false;
    }
  }

  // Get topics for a specific batch
  Future<List<Map<String, dynamic>>> getBatchTopics(String batchId) async {
    try {
      if (!await hasBatchAccess(batchId)) return [];

      final topicsSnapshot = await _firestore
          .collection('batches')
          .doc(batchId)
          .collection('topics')
          .orderBy('createdAt', descending: true)
          .get();

      return topicsSnapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data(),
              })
          .toList();
    } catch (e) {
      print('Error getting batch topics: $e');
      return [];
    }
  }

  // Get files for a specific batch
  Future<List<Map<String, dynamic>>> getBatchFiles(String batchId) async {
    try {
      if (!await hasBatchAccess(batchId)) return [];

      final filesSnapshot = await _firestore
          .collection('batches')
          .doc(batchId)
          .collection('files')
          .orderBy('createdAt', descending: true)
          .get();

      return filesSnapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data(),
              })
          .toList();
    } catch (e) {
      print('Error getting batch files: $e');
      return [];
    }
  }

  // Add topic to batch (for trainers)
  Future<void> addTopicToBatch(String batchId, Map<String, dynamic> topicData) async {
    try {
      if (!await hasBatchAccess(batchId)) {
        throw Exception('Access denied to this batch');
      }

      await _firestore
          .collection('batches')
          .doc(batchId)
          .collection('topics')
          .add({
            ...topicData,
            'createdAt': FieldValue.serverTimestamp(),
            'createdBy': currentUser!.uid,
          });
    } catch (e) {
      print('Error adding topic: $e');
      rethrow;
    }
  }

  // Add file to batch (for trainers)
  Future<void> addFileToBatch(String batchId, Map<String, dynamic> fileData) async {
    try {
      if (!await hasBatchAccess(batchId)) {
        throw Exception('Access denied to this batch');
      }

      await _firestore
          .collection('batches')
          .doc(batchId)
          .collection('files')
          .add({
            ...fileData,
            'createdAt': FieldValue.serverTimestamp(),
            'createdBy': currentUser!.uid,
          });
    } catch (e) {
      print('Error adding file: $e');
      rethrow;
    }
  }

  // Get attendance for a specific batch
  Future<List<Map<String, dynamic>>> getBatchAttendance(String batchId) async {
    try {
      if (!await hasBatchAccess(batchId)) return [];

      final attendanceSnapshot = await _firestore
          .collection('batches')
          .doc(batchId)
          .collection('attendance')
          .orderBy('date', descending: true)
          .get();

      return attendanceSnapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data(),
              })
          .toList();
    } catch (e) {
      print('Error getting batch attendance: $e');
      return [];
    }
  }

  // Mark attendance for a batch (for trainers)
  Future<void> markAttendance(String batchId, Map<String, dynamic> attendanceData) async {
    try {
      if (!await hasBatchAccess(batchId)) {
        throw Exception('Access denied to this batch');
      }

      await _firestore
          .collection('batches')
          .doc(batchId)
          .collection('attendance')
          .add({
            ...attendanceData,
            'createdAt': FieldValue.serverTimestamp(),
            'markedBy': currentUser!.uid,
          });
    } catch (e) {
      print('Error marking attendance: $e');
      rethrow;
    }
  }

  // Get user role
  Future<String?> getUserRole() async {
    try {
      if (currentUser == null) return null;

      final userDoc = await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .get();

      if (!userDoc.exists) return null;

      return userDoc.data()!['role'] as String?;
    } catch (e) {
      print('Error getting user role: $e');
      return null;
    }
  }
} 