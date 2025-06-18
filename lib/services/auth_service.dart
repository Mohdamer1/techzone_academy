import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get user data
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      if (currentUser == null) {
        print('No current user found');
        return null;
      }
      
      final doc = await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .get();
      
      if (!doc.exists) {
        print('No user document found for ${currentUser!.uid}');
        return null;
      }
      
      return {
        'id': doc.id,
        ...doc.data()!,
      };
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      print('Attempting to sign in with email: $email');
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      print('Sign in successful for user: ${result.user?.uid}');
      return result;
    } catch (e) {
      print('Error signing in: $e');
      rethrow;
    }
  }

  // Create user with email and password
  Future<UserCredential> createUserWithEmailAndPassword(
      String email, String password, String name, String role, String mobileNumber) async {
    try {
      print('Attempting to create user with email: $email');
      // Create user
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      print('User created successfully: ${userCredential.user?.uid}');

      // Check for payments with this email and collect all batchRefIds
      final paymentsSnapshot = await _firestore
          .collection('payments')
          .where('studentEmail', isEqualTo: email)
          .get();
      final batchRefIds = <String>{};
      for (final doc in paymentsSnapshot.docs) {
        final data = doc.data();
        // Find the batch by course and get its batchRefId
        if (data['course'] != null) {
          final batchQuery = await _firestore
              .collection('batches')
              .where('course', isEqualTo: data['course'])
              .get();
          if (batchQuery.docs.isNotEmpty) {
            final batchRefId = batchQuery.docs.first.data()['batchRefId'];
            if (batchRefId != null) {
              batchRefIds.add(batchRefId);
            }
          }
        }
      }

      // Check if a minimal user record exists (autoCreated)
      final existingUserQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .where('autoCreated', isEqualTo: true)
          .limit(1)
          .get();
      if (existingUserQuery.docs.isNotEmpty) {
        // Update the minimal user record with full registration info
        final docId = existingUserQuery.docs.first.id;
        await _firestore.collection('users').doc(docId).update({
          'name': name,
          'mobileNumber': mobileNumber,
          'role': role,
          'autoCreated': false,
          'batchIds': batchRefIds.toList(),
        });
      } else {
        // Create user document
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'name': name,
          'email': email,
          'mobileNumber': mobileNumber,
          'role': role,
          'createdAt': FieldValue.serverTimestamp(),
          'batchId': null,
          'batchIds': batchRefIds.toList(),
        });
      }
      print('User document created/updated successfully');

      return userCredential;
    } catch (e) {
      print('Error creating user: $e');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      print('User signed out successfully');
    } catch (e) {
      print('Error signing out: $e');
      rethrow;
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      print('Password reset email sent to: $email');
    } catch (e) {
      print('Error resetting password: $e');
      rethrow;
    }
  }

  // Register with email and password
  Future<UserCredential> registerWithEmailAndPassword(
      String email, String password, String name) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user document in Firestore
      await _firestore.collection('users').doc(result.user!.uid).set({
        'name': name,
        'email': email,
        'role': 'student', // Default role
        'createdAt': FieldValue.serverTimestamp(),
      });

      return result;
    } catch (e) {
      rethrow;
    }
  }

  // Update user profile
  Future<void> updateUserProfile(String name, String? photoURL) async {
    try {
      if (currentUser == null) throw 'No user is currently signed in.';
      
      await _firestore.collection('users').doc(currentUser?.uid).update({
        'name': name,
        if (photoURL != null) 'photoURL': photoURL,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw 'An error occurred while updating the profile.';
    }
  }
} 