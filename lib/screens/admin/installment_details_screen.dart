import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class InstallmentDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> payment;

  const InstallmentDetailsScreen({
    super.key,
    required this.payment,
  });

  @override
  State<InstallmentDetailsScreen> createState() => _InstallmentDetailsScreenState();
}

class _InstallmentDetailsScreenState extends State<InstallmentDetailsScreen> {
  List<Map<String, dynamic>> _installments = [];
  bool _isLoading = true;
  String _sortBy = 'date'; // 'date' or 'status'
  bool _sortAscending = false;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadInstallments();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInstallments() async {
    setState(() => _isLoading = true);

    try {
      // Listen to real-time updates
      FirebaseFirestore.instance
          .collection('payments')
          .where('studentEmail', isEqualTo: widget.payment['studentEmail'])
          .where('course', isEqualTo: widget.payment['course'])
          .orderBy('createdAt', descending: true)
          .snapshots()
          .listen((snapshot) {
        if (mounted) {
          setState(() {
            _installments = snapshot.docs.map((doc) {
              final data = doc.data();
              return {
                'id': doc.id,
                ...data,
              };
            }).toList();
            _sortInstallments();
          });
        }
      });

      // Initial load
      final querySnapshot = await FirebaseFirestore.instance
          .collection('payments')
          .where('studentEmail', isEqualTo: widget.payment['studentEmail'])
          .where('course', isEqualTo: widget.payment['course'])
          .orderBy('createdAt', descending: true)
          .get();

      if (mounted) {
        setState(() {
          _installments = querySnapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              ...data,
            };
          }).toList();
          _sortInstallments();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading installments: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _sortInstallments() {
    _installments.sort((a, b) {
      if (_sortBy == 'date') {
        final dateA = (a['createdAt'] as Timestamp).toDate();
        final dateB = (b['createdAt'] as Timestamp).toDate();
        return _sortAscending ? dateA.compareTo(dateB) : dateB.compareTo(dateA);
      } else {
        final statusA = a['status'] as String? ?? 'Pending';
        final statusB = b['status'] as String? ?? 'Pending';
        return _sortAscending ? statusA.compareTo(statusB) : statusB.compareTo(statusA);
      }
    });
  }

  List<Map<String, dynamic>> _getFilteredInstallments() {
    if (_searchController.text.isEmpty) {
      return _installments;
    }

    final searchTerm = _searchController.text.toLowerCase();
    return _installments.where((installment) {
      final amount = installment['amount']?.toString().toLowerCase() ?? '';
      final status = installment['status']?.toString().toLowerCase() ?? '';
      final notes = installment['notes']?.toString().toLowerCase() ?? '';
      
      return amount.contains(searchTerm) ||
          status.contains(searchTerm) ||
          notes.contains(searchTerm);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '₹');
    final totalAmount = widget.payment['totalAmount'] as num? ?? 0;
    final remainingAmount = widget.payment['remainingAmount'] as num? ?? 0;
    final paidAmount = totalAmount - remainingAmount;
    final progress = totalAmount > 0 ? paidAmount / totalAmount : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Installment Details'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111418),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadInstallments,
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF0F2F5),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.payment['studentName'] ?? 'Unknown Student',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.payment['course'] ?? '',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildAmountCard(
                            'Total Amount',
                            currencyFormat.format(totalAmount),
                            Colors.blue,
                          ),
                          _buildAmountCard(
                            'Paid Amount',
                            currencyFormat.format(paidAmount),
                            Colors.green,
                          ),
                          _buildAmountCard(
                            'Remaining',
                            currencyFormat.format(remainingAmount),
                            Colors.orange,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Payment Progress',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '${(progress * 100).toStringAsFixed(1)}%',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: progress,
                            backgroundColor: Colors.grey[200],
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: Column(
                    children: [
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search installments...',
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
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _sortBy,
                              decoration: const InputDecoration(
                                labelText: 'Sort By',
                                border: OutlineInputBorder(),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'date',
                                  child: Text('Date'),
                                ),
                                DropdownMenuItem(
                                  value: 'status',
                                  child: Text('Status'),
                                ),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _sortBy = value;
                                    _sortInstallments();
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          IconButton(
                            icon: Icon(
                              _sortAscending
                                  ? Icons.arrow_upward
                                  : Icons.arrow_downward,
                            ),
                            onPressed: () {
                              setState(() {
                                _sortAscending = !_sortAscending;
                                _sortInstallments();
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _getFilteredInstallments().length,
                    itemBuilder: (context, index) {
                      final installment = _getFilteredInstallments()[index];
                      final amount = installment['amount'] as num;
                      final status = installment['status'] as String? ?? 'Pending';
                      final createdAt = installment['createdAt'] as Timestamp?;
                      final dueDate = installment['dueDate'] as Timestamp?;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Installment ${index + 1}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
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
                              Text(
                                'Amount: ${currencyFormat.format(amount)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (createdAt != null) ...[
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_today,
                                        size: 16, color: Colors.grey),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Paid on: ${DateFormat('dd/MM/yyyy').format(createdAt.toDate())}',
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              if (dueDate != null) ...[
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.event,
                                        size: 16, color: Colors.grey),
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
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildAmountCard(String title, String amount, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            amount,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Completed':
        return Colors.green;
      case 'Pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
} 