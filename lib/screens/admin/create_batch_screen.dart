import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class CreateBatchScreen extends StatefulWidget {
  const CreateBatchScreen({super.key});

  @override
  State<CreateBatchScreen> createState() => _CreateBatchScreenState();
}

class _CreateBatchScreenState extends State<CreateBatchScreen> {
  final _formKey = GlobalKey<FormState>();
  final _batchNameController = TextEditingController();
  final _courseController = TextEditingController();
  DateTime? _startDate;
  String? _selectedTrainerId;
  List<Map<String, dynamic>> _trainers = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadTrainers();
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
                  'name': doc['name'],
                })
            .toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading trainers: $e')),
      );
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  Future<void> _createBatch() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null || _selectedTrainerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Get trainer information
      final trainerDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_selectedTrainerId)
          .get();
      
      final trainerName = trainerDoc.data()?['name'] ?? 'Unknown';
      final trainerEmail = trainerDoc.data()?['email'] ?? 'Not provided';

      // Generate a unique batch reference ID (format: BATCH-YYYYMMDD-XXXX)
      final now = DateTime.now();
      final random = (1000 + (DateTime.now().millisecondsSinceEpoch % 9000)).toString();
      final batchRefId = 'BATCH-${DateFormat('yyyyMMdd').format(now)}-$random';

      await FirebaseFirestore.instance.collection('batches').add({
        'name': _batchNameController.text,
        'course': _courseController.text,
        'startDate': Timestamp.fromDate(_startDate!),
        'trainerId': _selectedTrainerId,
        'trainerName': trainerName,
        'trainerEmail': trainerEmail,
        'createdAt': FieldValue.serverTimestamp(),
        'students': [],
        'trainers': [_selectedTrainerId],
        'batchRefId': batchRefId,
      });

      // Update trainer's batchIds array
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_selectedTrainerId)
          .update({
        'batchIds': FieldValue.arrayUnion([batchRefId])
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Batch created successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating batch: $e')),
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

  @override
  void dispose() {
    _batchNameController.dispose();
    _courseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                      color: const Color(0xFF111518),
                    ),
                    const Expanded(
                      child: Text(
                        'Create Batch',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111518),
                        ),
                      ),
                    ),
                    const SizedBox(width: 48), // For balance
                  ],
                ),
              ),

              // Form Fields
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        // Batch Name
                        TextFormField(
                          controller: _batchNameController,
                          decoration: InputDecoration(
                            labelText: 'Batch Name',
                            hintText: 'Enter batch name',
                            filled: true,
                            fillColor: const Color(0xFFF0F2F5),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.all(16),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter batch name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Course
                        TextFormField(
                          controller: _courseController,
                          decoration: InputDecoration(
                            labelText: 'Course',
                            hintText: 'Enter course name',
                            filled: true,
                            fillColor: const Color(0xFFF0F2F5),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.all(16),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter course name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Start Date
                        InkWell(
                          onTap: () => _selectDate(context),
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Start Date',
                              hintText: 'Select start date',
                              filled: true,
                              fillColor: const Color(0xFFF0F2F5),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.all(16),
                            ),
                            child: Text(
                              _startDate == null
                                  ? 'Select start date'
                                  : DateFormat('MMM dd, yyyy').format(_startDate!),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Assigned Trainers
                        DropdownButtonFormField<String>(
                          value: _selectedTrainerId,
                          decoration: InputDecoration(
                            labelText: 'Assigned Trainers',
                            filled: true,
                            fillColor: const Color(0xFFF0F2F5),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.all(16),
                          ),
                          items: _trainers.map((trainer) {
                            return DropdownMenuItem<String>(
                              value: trainer['id'] as String,
                              child: Text(trainer['name'] as String),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedTrainerId = value;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select a trainer';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Create Button
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _createBatch,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0B80EE),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Create Batch',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 