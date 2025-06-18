import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentPaymentHistoryScreen extends StatefulWidget {
  final String studentId;
  final String studentName;
  const StudentPaymentHistoryScreen({super.key, required this.studentId, required this.studentName});

  @override
  State<StudentPaymentHistoryScreen> createState() => _StudentPaymentHistoryScreenState();
}

class _StudentPaymentHistoryScreenState extends State<StudentPaymentHistoryScreen> {
  List<Map<String, dynamic>> _payments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    setState(() => _isLoading = true);
    try {
      final paymentsSnapshot = await FirebaseFirestore.instance
          .collection('payments')
          .where('studentId', isEqualTo: widget.studentId)
          .orderBy('createdAt', descending: true)
          .get();
      setState(() {
        _payments = paymentsSnapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  ...doc.data() as Map<String, dynamic>,
                })
            .toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading payments: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'N/A';
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Payment History - ${widget.studentName}'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111418),
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF0F2F5),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _payments.isEmpty
              ? const Center(child: Text('No payment history found.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _payments.length,
                  itemBuilder: (context, index) {
                    final payment = _payments[index];
                    return Container(
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
                          payment['paymentType'] == 'Installment'
                              ? 'Installment ${payment['installmentNumber']}/${payment['installmentCount']}'
                              : 'Full Payment',
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
                            Text('Amount: ₹${payment['amount']}', style: const TextStyle(fontSize: 14, color: Color(0xFF60758A))),
                            if (payment['paymentType'] == 'Installment') ...[
                              const SizedBox(height: 4),
                              Text('Total Amount: ₹${payment['totalAmount']}', style: const TextStyle(fontSize: 14, color: Color(0xFF60758A))),
                              const SizedBox(height: 4),
                              if (payment['remainingAmount'] != null)
                                Text('Remaining: ₹${payment['remainingAmount']}', style: const TextStyle(fontSize: 14, color: Color(0xFF60758A))),
                              if (payment['dueDate'] != null)
                                Text('Due Date: ${_formatDate(payment['dueDate'])}', style: const TextStyle(fontSize: 14, color: Color(0xFF60758A))),
                            ],
                            if (payment['notes']?.isNotEmpty ?? false) ...[
                              const SizedBox(height: 4),
                              Text('Notes: ${payment['notes']}', style: const TextStyle(fontSize: 14, color: Color(0xFF60758A))),
                            ],
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(_formatDate(payment['createdAt']), style: const TextStyle(fontSize: 12, color: Color(0xFF60758A))),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: payment['status'] == 'Completed' ? Colors.green.shade100 : Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                payment['status'] ?? 'Pending',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: payment['status'] == 'Completed' ? Colors.green.shade800 : Colors.orange.shade800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
} 