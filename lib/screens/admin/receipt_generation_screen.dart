import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:html' as html;
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ReceiptGenerationScreen extends StatefulWidget {
  const ReceiptGenerationScreen({super.key});

  @override
  State<ReceiptGenerationScreen> createState() => _ReceiptGenerationScreenState();
}

class _ReceiptGenerationScreenState extends State<ReceiptGenerationScreen> {
  List<Map<String, dynamic>> _allPayments = [];
  bool _isLoading = true;
  final _searchController = TextEditingController();
  String _selectedStatus = 'All';

  final List<String> _statuses = ['All', 'Pending', 'Completed'];

  @override
  void initState() {
    super.initState();
    _loadAllPayments();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAllPayments() async {
    setState(() => _isLoading = true);

    try {
      print('Loading all payments...');
      
      Query query = FirebaseFirestore.instance.collection('payments');
      
      // Apply status filter if not "All"
      if (_selectedStatus != 'All') {
        query = query.where('status', isEqualTo: _selectedStatus);
      }

      final paymentsSnapshot = await query.get();

      print('Found ${paymentsSnapshot.docs.length} payments');
      
      setState(() {
        _allPayments = paymentsSnapshot.docs
            .map((doc) {
              final data = doc.data();
              if (data is Map<String, dynamic>) {
                return {'id': doc.id, ...data};
              } else if (data is Map) {
                return {'id': doc.id, ...Map<String, dynamic>.from(data)};
              } else {
                return {'id': doc.id};
              }
            })
            .toList();
        
        // Sort by creation date in memory (descending - newest first)
        _allPayments.sort((a, b) {
          final aCreatedAt = a['createdAt'] as Timestamp?;
          final bCreatedAt = b['createdAt'] as Timestamp?;
          
          if (aCreatedAt == null && bCreatedAt == null) return 0;
          if (aCreatedAt == null) return 1;
          if (bCreatedAt == null) return -1;
          
          return bCreatedAt.compareTo(aCreatedAt); // Descending order
        });
      });
      
      // Debug: Print first payment structure
      if (_allPayments.isNotEmpty) {
        print('First payment structure: ${_allPayments.first}');
      }
      
    } catch (e) {
      print('Error loading payments: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading payments: ${e.toString()}')),
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
      return _allPayments;
    }

    final searchTerm = _searchController.text.toLowerCase();
    return _allPayments.where((payment) {
      final studentName = payment['studentName']?.toString().toLowerCase() ?? '';
      final studentEmail = payment['studentEmail']?.toString().toLowerCase() ?? '';
      final course = payment['course']?.toString().toLowerCase() ?? '';
      
      return studentName.contains(searchTerm) ||
          studentEmail.contains(searchTerm) ||
          course.contains(searchTerm);
    }).toList();
  }

  Future<void> _generateAndShareReceipt(Map<String, dynamic> payment) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final pdf = pw.Document();

      // Get payment details with proper null safety
      final studentName = payment['studentName']?.toString() ?? 'Unknown Student';
      final studentEmail = payment['studentEmail']?.toString() ?? '';
      final course = payment['course']?.toString() ?? '';
      final paymentType = payment['paymentType']?.toString() ?? 'Full Payment';
      final totalAmount = (payment['totalAmount'] as num?) ?? 0;
      final totalPaid = (payment['totalPaid'] as num?) ?? 0;
      
      // Calculate the amount for this specific payment
      final amount = paymentType == 'Installment' 
          ? (payment['amount'] as num?) ?? totalPaid  // Use amount if available, otherwise totalPaid
          : totalAmount; // For full payments, use totalAmount
      
      final installmentNumber = payment['installmentNumber'] as int?;
      final installmentCount = payment['installmentCount'] as int?;
      final paymentSchedule = payment['paymentSchedule']?.toString() ?? '';
      final notes = payment['notes']?.toString() ?? '';
      final createdAt = payment['createdAt'] as Timestamp?;
      final dueDate = payment['dueDate'] as Timestamp?;

      // Add content to the PDF
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Center(
                  child: pw.Text(
                    'TechZone Academy',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Center(
                  child: pw.Text(
                    'Payment Receipt',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 40),

                // Receipt Details
                pw.Text('Receipt No: ${payment['id']}'),
                pw.SizedBox(height: 10),
                pw.Text('Date: ${_formatDate(createdAt)}'),
                pw.SizedBox(height: 10),
                pw.Text('Student Name: $studentName'),
                pw.SizedBox(height: 10),
                pw.Text('Student Email: $studentEmail'),
                pw.SizedBox(height: 10),
                pw.Text('Course: $course'),
                pw.SizedBox(height: 10),
                pw.Text('Payment Type: $paymentType'),
                pw.SizedBox(height: 10),
                
                // Amount details based on payment type
                if (paymentType == 'Installment') ...[
                  pw.Text('Total Course Amount: Rs. ${totalAmount.toStringAsFixed(2)}'),
                  pw.SizedBox(height: 10),
                  pw.Text('Installment Amount: Rs. ${amount.toStringAsFixed(2)}'),
                  pw.SizedBox(height: 10),
                  if (installmentNumber != null && installmentCount != null)
                    pw.Text('Installment: $installmentNumber of $installmentCount'),
                  pw.SizedBox(height: 10),
                  if (paymentSchedule.isNotEmpty)
                    pw.Text('Payment Schedule: $paymentSchedule'),
                  pw.SizedBox(height: 10),
                  pw.Text('Total Paid: Rs. ${totalPaid.toStringAsFixed(2)}'),
                  pw.SizedBox(height: 10),
                ] else ...[
                  pw.Text('Amount: Rs. ${amount.toStringAsFixed(2)}'),
                  pw.SizedBox(height: 10),
                ],

                if (dueDate != null) ...[
                  pw.Text('Due Date: ${_formatDate(dueDate)}'),
                  pw.SizedBox(height: 10),
                ],

                if (notes.isNotEmpty) ...[
                  pw.Text('Notes: $notes'),
                  pw.SizedBox(height: 10),
                ],

                pw.SizedBox(height: 40),

                // Footer
                pw.Center(
                  child: pw.Text(
                    'Thank you for your payment!',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontStyle: pw.FontStyle.italic,
                    ),
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Center(
                  child: pw.Text(
                    'This is a computer generated receipt.',
                    style: pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );

      // Generate PDF bytes
      final pdfBytes = await pdf.save();

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Handle PDF download based on platform
      if (kIsWeb) {
        // Web platform - use dart:html for download
        final fileName = 'receipt_${payment['id']}_${studentName.replaceAll(' ', '_')}.pdf';
        final blob = html.Blob([pdfBytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', fileName)
          ..click();
        html.Url.revokeObjectUrl(url);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Receipt downloaded successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Mobile platform - show message for now
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('PDF generation is currently supported on web only'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }

    } catch (e) {
      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }
      
      print('Error generating receipt: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating receipt: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'N/A';
    final date = timestamp.toDate();
    return DateFormat('dd/MM/yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final filteredPayments = _getFilteredPayments();

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: const Text('Receipt Generation'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111418),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search Bar and Filters
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by student name, email, or course',
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
                // Status Filter
                DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'Payment Status',
                    border: OutlineInputBorder(),
                  ),
                  items: _statuses.map((status) => DropdownMenuItem<String>(
                    value: status,
                    child: Text(status),
                  )).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedStatus = value);
                      _loadAllPayments();
                    }
                  },
                ),
              ],
            ),
          ),
          
          // Payment List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredPayments.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.receipt_long,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No payments found',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredPayments.length,
                        itemBuilder: (context, index) {
                          final payment = filteredPayments[index];
                          return _buildPaymentCard(payment);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(Map<String, dynamic> payment) {
    try {
      print('Building payment card for: ${payment['studentName']}');
      print('Payment data: $payment');
      
      // Extract payment details with proper null safety
      final studentName = payment['studentName']?.toString() ?? 'Unknown Student';
      final studentEmail = payment['studentEmail']?.toString() ?? '';
      final course = payment['course']?.toString() ?? '';
      final status = payment['status']?.toString() ?? 'Pending';
      
      // For installment payments, use totalPaid as the amount for this receipt
      // For full payments, use totalAmount
      final paymentType = payment['paymentType']?.toString() ?? 'Full Payment';
      final totalAmount = (payment['totalAmount'] as num?) ?? 0;
      final totalPaid = (payment['totalPaid'] as num?) ?? 0;
      
      // Calculate the amount for this specific payment
      final amount = paymentType == 'Installment' 
          ? (payment['amount'] as num?) ?? totalPaid  // Use amount if available, otherwise totalPaid
          : totalAmount; // For full payments, use totalAmount
      
      final installmentNumber = payment['installmentNumber'] as int?;
      final installmentCount = payment['installmentCount'] as int?;
      final paymentSchedule = payment['paymentSchedule']?.toString() ?? '';
      final createdAt = payment['createdAt'] as Timestamp?;

      print('Extracted values - studentName: $studentName, amount: $amount, paymentType: $paymentType, status: $status');

      return Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
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
                          studentName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          studentEmail,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          course,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
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
              
              // Payment details
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        paymentType == 'Installment'
                            ? 'Installment Amount: Rs. ${amount.toStringAsFixed(2)}'
                            : 'Amount: Rs. ${amount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (paymentType == 'Installment' && totalAmount > 0) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Total Course: Rs. ${totalAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ],
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
                    'Installment $installmentNumber of $installmentCount',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
                if (paymentSchedule.isNotEmpty) ...[
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
                  const SizedBox(height: 8),
                  Text(
                    'Total Paid: Rs. ${totalPaid.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ],

              if (createdAt != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Paid on: ${_formatDate(createdAt)}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],

              const SizedBox(height: 16),
              
              // Generate Receipt Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _generateAndShareReceipt(payment),
                  icon: const Icon(Icons.receipt_long),
                  label: const Text('Generate Receipt'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0B80EE),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e, stackTrace) {
      print('Error building payment card: $e');
      print('Stack trace: $stackTrace');
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Error displaying payment',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Payment ID: ${payment['id'] ?? 'Unknown'}',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 8),
              Text(
                'Error: $e',
                style: const TextStyle(fontSize: 12, color: Colors.red),
              ),
            ],
          ),
        ),
      );
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
} 