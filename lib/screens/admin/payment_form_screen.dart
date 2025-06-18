import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class PaymentFormScreen extends StatefulWidget {
  const PaymentFormScreen({super.key});

  @override
  State<PaymentFormScreen> createState() => _PaymentFormScreenState();
}

class _PaymentFormScreenState extends State<PaymentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _studentNameController = TextEditingController();
  final _studentEmailController = TextEditingController();
  final _amountController = TextEditingController();
  final _totalAmountController = TextEditingController();
  final _notesController = TextEditingController();
  final _installmentCountController = TextEditingController(text: '1');
  final _courseController = TextEditingController();
  final _paymentScheduleController = TextEditingController();

  String _paymentType = 'Full Payment';
  DateTime? _dueDate;
  bool _isLoading = false;
  int _installmentNumber = 1;
  String? _parentPaymentId;

  @override
  void initState() {
    super.initState();
    _paymentScheduleController.text = 'Monthly';
  }

  @override
  void dispose() {
    _studentNameController.dispose();
    _studentEmailController.dispose();
    _amountController.dispose();
    _totalAmountController.dispose();
    _notesController.dispose();
    _installmentCountController.dispose();
    _courseController.dispose();
    _paymentScheduleController.dispose();
    super.dispose();
  }

  Future<void> _selectDueDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );

    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  Future<void> _submitPayment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final totalAmount = _paymentType == 'Full Payment'
          ? _amountController.text.isEmpty
              ? 0.0
              : double.parse(_amountController.text)
          : _totalAmountController.text.isEmpty
              ? 0.0
              : double.parse(_totalAmountController.text);

      final amount = _amountController.text.isEmpty
          ? 0.0
          : double.parse(_amountController.text);

      // Calculate remaining amount
      final remainingAmount = totalAmount - amount;

      // --- Robust batch assignment logic ---
      // Find the batch by course and get its batchRefId
      String? batchRefId;
      final batchQuery = await FirebaseFirestore.instance
          .collection('batches')
          .where('course', isEqualTo: _courseController.text)
          .get();
      if (batchQuery.docs.isNotEmpty) {
        batchRefId = batchQuery.docs.first.data()['batchRefId'];
      }

      // Check if user exists for this email
      final userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: _studentEmailController.text)
          .limit(1)
          .get();
      String? userId;
      if (userQuery.docs.isNotEmpty) {
        userId = userQuery.docs.first.id;
        // Add batchRefId to batchIds if not already present
        if (batchRefId != null) {
          await FirebaseFirestore.instance.collection('users').doc(userId).update({
            'batchIds': FieldValue.arrayUnion([batchRefId]),
            'name': _studentNameController.text,
            'role': 'student',
          });
        }
      } else {
        // Create minimal user record if not present
        final newUser = await FirebaseFirestore.instance.collection('users').add({
          'email': _studentEmailController.text,
          'name': _studentNameController.text,
          'role': 'student',
          'batchIds': batchRefId != null ? [batchRefId] : [],
          'autoCreated': true,
        });
        userId = newUser.id;
      }

      // Check if this is an installment payment
      if (_paymentType == 'Installment') {
        // Create the parent payment for the installment plan
        final parentPaymentRef = await FirebaseFirestore.instance
            .collection('payments')
            .add({
          'studentName': _studentNameController.text,
          'studentEmail': _studentEmailController.text,
          'course': _courseController.text,
          'totalAmount': totalAmount, // Total amount of the installment plan
          'remainingAmount': remainingAmount, // Remaining after initial installment
          'totalPaid': amount, // Amount paid with the first installment
          'paymentType': 'Installment',
          'status': remainingAmount <= 0 ? 'Completed' : 'Pending',
          'installmentNumber': 1, // Explicitly set to 1 for the first installment
          'installmentCount': int.parse(_installmentCountController.text),
          'paymentSchedule': _paymentScheduleController.text,
          'createdAt': FieldValue.serverTimestamp(),
          'notes': _notesController.text,
        });

        _parentPaymentId = parentPaymentRef.id;

        // --- DEBUGGING: Log parent payment data after creation ---
        final createdPaymentSnapshot = await parentPaymentRef.get();
        print('Debug (PaymentFormScreen): Parent Payment Created: ${createdPaymentSnapshot.data()}');
        // -----------------------------------------------------------

        // Record the first installment as a sub-document
        await parentPaymentRef.collection('installments').add({
          'amount': amount,
          'paymentMethod': 'Cash', // Assuming default or add a field for this
          'createdAt': FieldValue.serverTimestamp(),
          'dueDate': _dueDate != null
              ? Timestamp.fromDate(_dueDate!)
              : FieldValue.serverTimestamp(),
          'notes': _notesController.text,
          'installmentNumber': 1, // Set installment number for the sub-document as well
        });
      } else {
        // Create full payment
        await FirebaseFirestore.instance
            .collection('payments')
            .add({
          'studentName': _studentNameController.text,
          'studentEmail': _studentEmailController.text,
          'course': _courseController.text,
          'amount': amount,
          'paymentType': 'Full Payment',
          'status': 'Completed',
          'createdAt': FieldValue.serverTimestamp(),
          'notes': _notesController.text,
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment added successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding payment: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Payment'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111418),
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF0F2F5),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Student Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _studentNameController,
                      decoration: const InputDecoration(
                        labelText: 'Student Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter student name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _studentEmailController,
                      decoration: const InputDecoration(
                        labelText: 'Student Email',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter student email';
                        }
                        if (!value.contains('@')) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Payment Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _courseController,
                      decoration: const InputDecoration(
                        labelText: 'Course',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter course';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _paymentType,
                      decoration: const InputDecoration(
                        labelText: 'Payment Type',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Full Payment',
                          child: Text('Full Payment'),
                        ),
                        DropdownMenuItem(
                          value: 'Installment',
                          child: Text('Installment'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _paymentType = value);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    if (_paymentType == 'Installment') ...[
                      TextFormField(
                        controller: _totalAmountController,
                        decoration: const InputDecoration(
                          labelText: 'Total Amount',
                          border: OutlineInputBorder(),
                          prefixText: '₹',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter total amount';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Please enter a valid amount';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _installmentCountController,
                        decoration: const InputDecoration(
                          labelText: 'Number of Installments',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter number of installments';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _paymentScheduleController,
                        decoration: const InputDecoration(
                          labelText: 'Payment Schedule',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter payment schedule';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                    TextFormField(
                      controller: _amountController,
                      decoration: InputDecoration(
                        labelText: _paymentType == 'Full Payment'
                            ? 'Amount'
                            : 'Installment Amount',
                        border: const OutlineInputBorder(),
                        prefixText: '₹',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter amount';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid amount';
                        }
                        if (_paymentType == 'Installment') {
                          final totalAmount = double.tryParse(
                                  _totalAmountController.text) ??
                              0;
                          final installmentAmount =
                              double.tryParse(value) ?? 0;
                          if (installmentAmount > totalAmount) {
                            return 'Installment amount cannot be greater than total amount';
                          }
                        }
                        return null;
                      },
                    ),
                    if (_paymentType == 'Installment') ...[
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: _selectDueDate,
                        icon: const Icon(Icons.calendar_today),
                        label: Text(
                          _dueDate != null
                              ? DateFormat('dd/MM/yyyy').format(_dueDate!)
                              : 'Select Due Date',
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF0B80EE),
                          side: const BorderSide(color: Color(0xFF0B80EE)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notes',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitPayment,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: const Color(0xFF0B80EE),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Add Payment'),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 