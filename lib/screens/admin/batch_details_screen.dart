import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BatchDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> batch;

  const BatchDetailsScreen({
    super.key,
    required this.batch,
  });

  @override
  State<BatchDetailsScreen> createState() => _BatchDetailsScreenState();
}

class _BatchDetailsScreenState extends State<BatchDetailsScreen> {
  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _trainers = [];
  List<Map<String, dynamic>> _availableStudents = [];
  List<Map<String, dynamic>> _availableTrainers = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadStudents();
    _loadTrainers();
    _loadAvailableStudents();
    _loadAvailableTrainers();
  }

  Future<void> _loadStudents() async {
    try {
      final studentsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'student')
          .where('batchId', isEqualTo: widget.batch['id'])
          .get();

      setState(() {
        _students = studentsSnapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  ...doc.data(),
                })
            .toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading students: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _loadTrainers() async {
    try {
      final trainersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'trainer')
          .where('batchIds', arrayContains: widget.batch['id'])
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

  Future<void> _loadAvailableStudents() async {
    try {
      final studentsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'student')
          .get();

      setState(() {
        _availableStudents = studentsSnapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  ...doc.data(),
                })
            .toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading available students: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _loadAvailableTrainers() async {
    try {
      final trainersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'trainer')
          .get();

      setState(() {
        _availableTrainers = trainersSnapshot.docs
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
          SnackBar(content: Text('Error loading available trainers: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _addStudent(String studentId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Update student's batchId
      await FirebaseFirestore.instance
          .collection('users')
          .doc(studentId)
          .update({'batchId': widget.batch['id']});

      // Add student to batch's students array
      await FirebaseFirestore.instance
          .collection('batches')
          .doc(widget.batch['id'])
          .update({
        'students': FieldValue.arrayUnion([studentId])
      });

      await _loadStudents();
      await _loadAvailableStudents();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Student added successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding student: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _addTrainer(String trainerId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Add batch to trainer's batchIds array
      await FirebaseFirestore.instance
          .collection('users')
          .doc(trainerId)
          .update({
        'batchIds': FieldValue.arrayUnion([widget.batch['id']])
      });

      // Add trainer to batch's trainers array
      await FirebaseFirestore.instance
          .collection('batches')
          .doc(widget.batch['id'])
          .update({
        'trainers': FieldValue.arrayUnion([trainerId])
      });

      await _loadTrainers();
      await _loadAvailableTrainers();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Trainer added successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding trainer: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _removeStudent(String studentId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Remove batchId from student
      await FirebaseFirestore.instance
          .collection('users')
          .doc(studentId)
          .update({'batchId': null});

      // Remove student from batch's students array
      await FirebaseFirestore.instance
          .collection('batches')
          .doc(widget.batch['id'])
          .update({
        'students': FieldValue.arrayRemove([studentId])
      });

      await _loadStudents();
      await _loadAvailableStudents();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Student removed successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error removing student: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _removeTrainer(String trainerId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Remove batch from trainer's batchIds array
      await FirebaseFirestore.instance
          .collection('users')
          .doc(trainerId)
          .update({
        'batchIds': FieldValue.arrayRemove([widget.batch['id']])
      });

      // Remove trainer from batch's trainers array
      await FirebaseFirestore.instance
          .collection('batches')
          .doc(widget.batch['id'])
          .update({
        'trainers': FieldValue.arrayRemove([trainerId])
      });

      await _loadTrainers();
      await _loadAvailableTrainers();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Trainer removed successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error removing trainer: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showAddStudentDialog() async {
    final searchController = TextEditingController();
    List<Map<String, dynamic>> filteredStudents = _availableStudents.where((student) => 
      !(widget.batch['students'] as List).contains(student['id'])
    ).toList();

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Student'),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.height * 0.6,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Search Field
                TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    labelText: 'Search by email or mobile number',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF0F2F5),
                  ),
                  onChanged: (value) {
                    setState(() {
                      if (value.isEmpty) {
                        filteredStudents = _availableStudents.where((student) => 
                          !(widget.batch['students'] as List).contains(student['id'])
                        ).toList();
                      } else {
                        final searchTerm = value.toLowerCase();
                        filteredStudents = _availableStudents.where((student) {
                          final email = student['email']?.toString().toLowerCase() ?? '';
                          final mobile = student['mobileNumber']?.toString() ?? '';
                          final name = student['name']?.toString().toLowerCase() ?? '';
                          return !(widget.batch['students'] as List).contains(student['id']) &&
                                 (email.contains(searchTerm) || 
                                  mobile.contains(searchTerm) ||
                                  name.contains(searchTerm));
                        }).toList();
                      }
                    });
                  },
                ),
                const SizedBox(height: 16),
                
                // Results List
                Expanded(
                  child: filteredStudents.isEmpty
                    ? const Center(
                        child: Text(
                          'No students found',
                          style: TextStyle(
                            color: Color(0xFF60758A),
                            fontSize: 16,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: filteredStudents.length,
                        itemBuilder: (context, index) {
                          final student = filteredStudents[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Text(
                                student['name'] ?? 'Unknown',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    'Email: ${student['email'] ?? 'Not provided'}',
                                    style: const TextStyle(
                                      color: Color(0xFF60758A),
                                    ),
                                  ),
                                  Text(
                                    'Mobile: ${student['mobileNumber'] ?? 'Not provided'}',
                                    style: const TextStyle(
                                      color: Color(0xFF60758A),
                                    ),
                                  ),
                                ],
                              ),
                              trailing: const Icon(Icons.add_circle_outline),
                              onTap: () {
                                _addStudent(student['id']);
                                Navigator.pop(context);
                              },
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
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddTrainerDialog() async {
    final searchController = TextEditingController();
    List<Map<String, dynamic>> filteredTrainers = _availableTrainers.where((trainer) => 
      !(widget.batch['trainers'] as List).contains(trainer['id'])
    ).toList();

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Trainer'),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.height * 0.6,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Search Field
                TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    labelText: 'Search by name or email',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF0F2F5),
                  ),
                  onChanged: (value) {
                    setState(() {
                      if (value.isEmpty) {
                        filteredTrainers = _availableTrainers.where((trainer) => 
                          !(widget.batch['trainers'] as List).contains(trainer['id'])
                        ).toList();
                      } else {
                        final searchTerm = value.toLowerCase();
                        filteredTrainers = _availableTrainers.where((trainer) {
                          final name = trainer['name']?.toString().toLowerCase() ?? '';
                          final email = trainer['email']?.toString().toLowerCase() ?? '';
                          return !(widget.batch['trainers'] as List).contains(trainer['id']) &&
                                 (name.contains(searchTerm) || email.contains(searchTerm));
                        }).toList();
                      }
                    });
                  },
                ),
                const SizedBox(height: 16),
                
                // Results List
                Expanded(
                  child: filteredTrainers.isEmpty
                    ? const Center(
                        child: Text(
                          'No trainers found',
                          style: TextStyle(
                            color: Color(0xFF60758A),
                            fontSize: 16,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: filteredTrainers.length,
                        itemBuilder: (context, index) {
                          final trainer = filteredTrainers[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Text(
                                trainer['name'] ?? 'Unknown',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                'Email: ${trainer['email'] ?? 'Not provided'}',
                                style: const TextStyle(
                                  color: Color(0xFF60758A),
                                ),
                              ),
                              trailing: const Icon(Icons.add_circle_outline),
                              onTap: () {
                                _addTrainer(trainer['id']);
                                Navigator.pop(context);
                              },
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
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: Text(widget.batch['name']),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111418),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Batch Info Card
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Batch Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF111418),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Course: ${widget.batch['course'] ?? 'Not specified'}',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF60758A),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Start Date: ${widget.batch['startDate'] != null ? (widget.batch['startDate'] as Timestamp).toDate().toString().split(' ')[0] : 'Not specified'}',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF60758A),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Batch Reference ID: ${widget.batch['batchRefId'] ?? 'Not assigned'}',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF60758A),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Trainers Section
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Trainers',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF111418),
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: _showAddTrainerDialog,
                              icon: const Icon(Icons.add),
                              label: const Text('Add Trainer'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ..._trainers.map((trainer) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(
                              trainer['name'] ?? 'Unknown',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              'Email: ${trainer['email'] ?? 'Not provided'}',
                              style: const TextStyle(
                                color: Color(0xFF60758A),
                              ),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                              onPressed: () => _removeTrainer(trainer['id']),
                            ),
                          ),
                        )).toList(),
                      ],
                    ),
                  ),

                  // Students Section
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Students',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF111418),
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: _showAddStudentDialog,
                              icon: Icon(Icons.add),
                              label: Text('Add Student'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ..._students.map((student) => Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    student['name'],
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Color(0xFF111418),
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.remove_circle_outline),
                                    color: Colors.red,
                                    onPressed: () => _removeStudent(student['id']),
                                  ),
                                ],
                              ),
                            )),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
} 