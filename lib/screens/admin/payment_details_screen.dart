import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'installment_details_screen.dart';

class PaymentDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> payment;

  const PaymentDetailsScreen({
    super.key,
    required this.payment,
  });

  @override
  State<PaymentDetailsScreen> createState() => _PaymentDetailsScreenState();
}

class _PaymentDetailsScreenState extends State<PaymentDetailsScreen> {
  final _mainFormKey = GlobalKey<FormState>();
  final _installmentFormKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  final _totalAmountController = TextEditingController();
  final _installmentCountController = TextEditingController();
  final _dueDateController = TextEditingController();

  // Controllers for "Add Next Installment" form
  final _newInstallmentAmountController = TextEditingController();
  final _newInstallmentNotesController = TextEditingController();
  final _newInstallmentDueDateController = TextEditingController();

  String _selectedPaymentMethod = 'Cash';
  String _newInstallmentSelectedPaymentMethod = 'Cash';
  DateTime? _selectedDueDate;
  DateTime? _newInstallmentSelectedDueDate;

  bool _isLoading = false;
  bool _isEditing = false;

  final List<String> _paymentMethods = ['Cash', 'Card', 'Bank Transfer'];

  // New: State variable to hold the current payment data that can be updated
  late Map<String, dynamic> _currentPayment;

  @override
  void initState() {
    super.initState();
    _currentPayment = Map.from(widget.payment); // Initialize with passed payment data
    _initializeControllers();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    _totalAmountController.dispose();
    _installmentCountController.dispose();
    _dueDateController.dispose();
    _newInstallmentAmountController.dispose();
    _newInstallmentNotesController.dispose();
    _newInstallmentDueDateController.dispose();
    super.dispose();
  }

  void _initializeControllers() {
    // Initialize controllers from _currentPayment
    _amountController.text = _currentPayment['amount']?.toString() ?? '';
    _notesController.text = _currentPayment['notes'] ?? '';
    _selectedPaymentMethod = _currentPayment['paymentMethod'] ?? 'Cash';
    if (_currentPayment['paymentType'] == 'Installment') {
      _totalAmountController.text = _currentPayment['totalAmount']?.toString() ?? '';
      _installmentCountController.text = _currentPayment['installmentCount']?.toString() ?? '';
      if (_currentPayment['dueDate'] != null) {
        _selectedDueDate = (_currentPayment['dueDate'] as Timestamp).toDate();
        _dueDateController.text = DateFormat('dd/MM/yyyy').format(_selectedDueDate!);
      }
    }
  }

  Future<void> _updatePayment() async {
    if (!_mainFormKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final paymentData = {
        'amount': double.parse(_amountController.text),
        'paymentMethod': _selectedPaymentMethod,
        'notes': _notesController.text,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (_currentPayment['paymentType'] == 'Installment') {
        paymentData['totalAmount'] = double.parse(_totalAmountController.text);
        paymentData['installmentCount'] = int.parse(_installmentCountController.text);
        if (_selectedDueDate != null) {
          paymentData['dueDate'] = Timestamp.fromDate(_selectedDueDate!);
        }
      }

      await FirebaseFirestore.instance
          .collection('payments')
          .doc(_currentPayment['id'])
          .update(paymentData);

      // Refresh local payment data after update
      await _refreshPaymentData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment updated successfully')),
        );
        setState(() => _isEditing = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating payment: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // New: Method to explicitly reload the payment data from Firestore
  Future<void> _refreshPaymentData() async {
    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('payments')
          .doc(_currentPayment['id'])
          .get();

      if (docSnapshot.exists && mounted) {
        setState(() {
          _currentPayment = {
            'id': docSnapshot.id,
            ...docSnapshot.data() as Map<String, dynamic>,
          };
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error refreshing payment data: $e')),
        );
      }
    }
  }

  Future<void> _saveNextInstallment(double installmentAmount) async {
    setState(() => _isLoading = true);
    try {
      final paymentId = _currentPayment['id']; // Use _currentPayment
      final remainingAmount = _currentPayment['remainingAmount'] as num? ?? 0; // Use _currentPayment
      final totalPaid = _currentPayment['totalPaid'] as num? ?? 0; // Use _currentPayment
      final installmentNumber = _currentPayment['installmentNumber'] as int? ?? 0; // Use _currentPayment
      final installmentCount = _currentPayment['installmentCount'] as int? ?? 0; // Use _currentPayment
      final totalAmount = _currentPayment['totalAmount'] as num? ?? 0; // Use _currentPayment

      if (installmentAmount > remainingAmount) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Installment amount cannot exceed remaining balance')),
        );
        return;
      }
      final newRemainingAmount = remainingAmount - installmentAmount;
      final newTotalPaid = totalPaid + installmentAmount;
      // Determine the correct installment number for display/tracking
      final int finalInstallmentNumber = (newRemainingAmount <= 0) ? installmentCount : installmentNumber + 1;

      // Update the main payment record
      await FirebaseFirestore.instance.collection('payments').doc(paymentId).update({
        'remainingAmount': newRemainingAmount,
        'totalPaid': newTotalPaid,
        'installmentNumber': finalInstallmentNumber,
        'status': newRemainingAmount <= 0 ? 'Completed' : 'Pending',
      });
      // Record the installment in a subtable/collection
      await FirebaseFirestore.instance.collection('installments').add({
        'paymentId': paymentId,
        'amount': installmentAmount,
        'installmentNumber': finalInstallmentNumber,
        'createdAt': FieldValue.serverTimestamp(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Next installment added successfully')),
      );
      
      // Refresh the local payment data after successful update
      await _refreshPaymentData(); // <--- CRITICAL CHANGE

      if (mounted) { // Only pop the dialog if the widget is still mounted after async operations
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showAddNextInstallmentDialog(BuildContext context) {
    final TextEditingController amountController = TextEditingController();
    final num currentRemainingAmount = _currentPayment['remainingAmount'] as num? ?? 0;
    final int currentInstallmentNumber = _currentPayment['installmentNumber'] as int? ?? 0;
    final int totalInstallmentCount = _currentPayment['installmentCount'] as int? ?? 0;

    // --- DEBUGGING: Explicitly log values for Installments Left calculation ---
    print('Debug (PaymentDetailsScreen Dialog): Raw installmentNumber from _currentPayment: ${currentInstallmentNumber}');
    print('Debug (PaymentDetailsScreen Dialog): Raw totalInstallmentCount from _currentPayment: ${totalInstallmentCount}');
    print('Debug (PaymentDetailsScreen Dialog): Raw totalPaid from _currentPayment: ${_currentPayment['totalPaid']}');
    // -------------------------------------------------------------------------

    final int installmentsLeft = totalInstallmentCount - currentInstallmentNumber;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Next Installment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Remaining Balance: ₹${currentRemainingAmount.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Installments Left: $installmentsLeft of $totalInstallmentCount',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Installment Amount',
                  hintText: 'Enter the installment amount',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final amount = double.tryParse(amountController.text);
                if (amount == null || amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid amount')),
                  );
                  return;
                }
                if (amount > currentRemainingAmount) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Installment amount cannot exceed remaining balance')),
                  );
                  return;
                }
                await _saveNextInstallment(amount);
                // Dialog will be popped by _saveNextInstallment after data refresh
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
    // Use _currentPayment instead of widget.payment throughout build method
    final payment = _currentPayment; 
    final amount = payment['amount'] as num? ?? 0;
    final totalAmount = payment['totalAmount'] as num? ?? 0;
    final remainingAmount = payment['remainingAmount'] as num? ?? 0;
    final totalPaid = payment['totalPaid'] as num? ?? 0;
    final dueDate = payment['dueDate'] as Timestamp?;
    final status = payment['status'] as String? ?? 'Pending';
    final paymentType = payment['paymentType'] as String? ?? 'Full Payment';
    final course = payment['course'] as String? ?? '';
    final isCompleted = status == 'Completed';
    final installmentNumber = payment['installmentNumber'] as int?;
    final installmentCount = payment['installmentCount'] as int?;
    final paymentSchedule = payment['paymentSchedule'] as String?;
    final parentPaymentId = payment['parentPaymentId'] as String?;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Details'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111418),
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF0F2F5),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      payment['studentName'] ?? 'Unknown Student',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      course,
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Only show 'Amount' if it's a Full Payment
                    if (paymentType == 'Full Payment')
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Amount: ₹${amount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              paymentType,
                              style: const TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    if (paymentType == 'Installment')
                      // Display payment type badge for installments even if amount isn't shown directly
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              paymentType,
                              style: const TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    if (paymentType == 'Installment') ...[
                      if (installmentNumber != null && installmentCount != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Installment $installmentNumber of $installmentCount',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                      if (paymentSchedule != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Schedule: $paymentSchedule',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                      if (totalAmount > 0 && totalPaid > 0) ...[
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Amount: ₹${totalAmount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              'Paid: ₹${totalPaid.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: totalAmount > 0 ? totalPaid / totalAmount : 0,
                          backgroundColor: Colors.grey[200],
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                        ),
                      ],
                      if (remainingAmount > 0 && !isCompleted) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Remaining: ₹${remainingAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ],
                    if (dueDate != null && !isCompleted) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(
                            'Due: ${DateFormat('dd/MM/yyyy').format(dueDate.toDate())}',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (paymentType == 'Installment' && remainingAmount > 0) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : () => _showAddNextInstallmentDialog(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0B80EE),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Text(
                    'Add Next Installment',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}