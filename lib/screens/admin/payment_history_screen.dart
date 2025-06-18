import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'payment_details_screen.dart';
import 'payment_form_screen.dart';

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  final _searchController = TextEditingController();
  String _selectedFilter = 'All';
  String _selectedStatus = 'All';
  DateTime? _startDate;
  DateTime? _endDate;
  List<Map<String, dynamic>> _payments = [];
  bool _isLoading = true;

  final List<String> _filters = ['All', 'Full Payment', 'Installment'];
  final List<String> _statuses = ['All', 'Pending', 'Completed'];

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPayments() async {
    setState(() => _isLoading = true);

    try {
      Query query = FirebaseFirestore.instance.collection('payments');

      // Apply filters
      if (_selectedFilter != 'All') {
        query = query.where('paymentType', isEqualTo: _selectedFilter);
      }
      if (_selectedStatus != 'All') {
        query = query.where('status', isEqualTo: _selectedStatus);
      }

      // Apply search
      if (_searchController.text.isNotEmpty) {
        query = query.where('studentName', isGreaterThanOrEqualTo: _searchController.text)
                    .where('studentName', isLessThanOrEqualTo: _searchController.text + '\uf8ff');
      }

      // Order by creation date
      query = query.orderBy('createdAt', descending: true);

      final querySnapshot = await query.get();
      setState(() {
        _payments = querySnapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'id': doc.id,
            ...data,
          };
        }).toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading payments: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<Map<String, dynamic>> _getFilteredPayments() {
    if (_searchController.text.isEmpty) {
      return _payments;
    }

    final searchTerm = _searchController.text.toLowerCase();
    return _payments.where((payment) {
      final studentName = payment['studentName']?.toString().toLowerCase() ?? '';
      final studentEmail = payment['studentEmail']?.toString().toLowerCase() ?? '';
      final notes = payment['notes']?.toString().toLowerCase() ?? '';
      
      return studentName.contains(searchTerm) ||
          studentEmail.contains(searchTerm) ||
          notes.contains(searchTerm);
    }).toList();
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadPayments();
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredPayments = _getFilteredPayments();
    final currencyFormat = NumberFormat.currency(symbol: '₹');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment History'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111418),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PaymentFormScreen(),
                ),
              );
              _loadPayments();
            },
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF0F2F5),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by student name, email, or notes',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                  ),
                  onChanged: (value) => setState(() {}),
                ),
                const SizedBox(height: 16),
                // Filters
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedFilter,
                        decoration: const InputDecoration(
                          labelText: 'Payment Type',
                          border: OutlineInputBorder(),
                        ),
                        items: _filters.map((filter) => DropdownMenuItem<String>(
                          value: filter,
                          child: Text(filter),
                        )).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedFilter = value);
                            _loadPayments();
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedStatus,
                        decoration: const InputDecoration(
                          labelText: 'Status',
                          border: OutlineInputBorder(),
                        ),
                        items: _statuses.map((status) => DropdownMenuItem<String>(
                          value: status,
                          child: Text(status),
                        )).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedStatus = value);
                            _loadPayments();
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Date Range
                OutlinedButton.icon(
                  onPressed: _selectDateRange,
                  icon: const Icon(Icons.date_range),
                  label: Text(
                    _startDate != null && _endDate != null
                        ? '${DateFormat('MMM d, y').format(_startDate!)} - ${DateFormat('MMM d, y').format(_endDate!)}'
                        : 'Select Date Range',
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
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredPayments.isEmpty
                    ? const Center(
                        child: Text(
                          'No payments found',
                          style: TextStyle(fontSize: 16),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredPayments.length,
                        itemBuilder: (context, index) {
                          final payment = filteredPayments[index];
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
                          
                          return _buildPaymentCard(payment);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(Map<String, dynamic> payment) {
    // --- DEBUGGING: Print the raw payment data ---
    print('Building Payment Card for: ${payment['studentName']}');
    print('Payment Data: $payment');
    // -----------------------------------------------
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

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PaymentDetailsScreen(
                payment: payment,
              ),
            ),
          );
          _loadPayments();
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          payment['studentName'] ?? 'Unknown Student',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          course,
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: _getStatusColor(status),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    paymentType == 'Installment'
                        ? 'Total Amount: ₹${totalAmount.toStringAsFixed(2)}'
                        : 'Amount: ₹${amount.toStringAsFixed(2)}',
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
              if (paymentType == 'Installment') ...[
                if (installmentNumber != null && installmentCount != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    isCompleted
                        ? 'All Installments Completed'
                        : 'Installment $installmentNumber of $installmentCount',
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
    );
  }

  Color _getStatusColor(String status) {
    if (status == 'Completed') {
      return Colors.green;
    } else if (status == 'Pending') {
      return Colors.orange;
    } else {
      throw Exception('Unknown status');
    }
  }
} 