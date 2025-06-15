import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class ReceiptGenerationScreen extends StatefulWidget {
  const ReceiptGenerationScreen({super.key});

  @override
  State<ReceiptGenerationScreen> createState() => _ReceiptGenerationScreenState();
}

class _ReceiptGenerationScreenState extends State<ReceiptGenerationScreen> {
  List<Map<String, dynamic>> _payments = [];
  List<Map<String, dynamic>> _students = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPayments();
    _loadStudents();
  }

  Future<void> _loadPayments() async {
    try {
      final paymentsSnapshot = await FirebaseFirestore.instance
          .collection('payments')
          .orderBy('createdAt', descending: true)
          .get();

      setState(() {
        _payments = paymentsSnapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  ...doc.data(),
                })
            .toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading payments: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _loadStudents() async {
    try {
      final studentsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'student')
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

  String _getStudentName(String studentId) {
    final student = _students.firstWhere(
      (s) => s['id'] == studentId,
      orElse: () => {'name': 'Unknown Student'},
    );
    return student['name'];
  }

  Future<void> _generateReceipt(Map<String, dynamic> payment) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final pdf = pw.Document();

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
                pw.Text('Date: ${_formatDate(payment['createdAt'])}'),
                pw.SizedBox(height: 10),
                pw.Text('Student Name: ${_getStudentName(payment['studentId'])}'),
                pw.SizedBox(height: 10),
                pw.Text('Amount: ₹${payment['amount']}'),
                pw.SizedBox(height: 10),
                pw.Text('Payment Method: ${payment['paymentMethod'].toString().toUpperCase()}'),
                if (payment['notes']?.isNotEmpty ?? false) ...[
                  pw.SizedBox(height: 10),
                  pw.Text('Notes: ${payment['notes']}'),
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
              ],
            );
          },
        ),
      );

      // Save the PDF
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/receipt_${payment['id']}.pdf');
      await file.writeAsBytes(await pdf.save());

      // TODO: Implement sharing or downloading the PDF
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Receipt generated: ${file.path}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating receipt: ${e.toString()}')),
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

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'N/A';
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: const Text('Receipt Generation'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111418),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Payment History',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111418),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ..._payments.map((payment) => _buildPaymentCard(payment)).toList(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPaymentCard(Map<String, dynamic> payment) {
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
          _getStudentName(payment['studentId']),
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
            Text(
              'Amount: ₹${payment['amount']}',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF60758A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Method: ${payment['paymentMethod'].toString().toUpperCase()}',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF60758A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Date: ${_formatDate(payment['createdAt'])}',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF60758A),
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.receipt_long),
          onPressed: () => _generateReceipt(payment),
          color: const Color(0xFF0B80EE),
        ),
      ),
    );
  }
} 