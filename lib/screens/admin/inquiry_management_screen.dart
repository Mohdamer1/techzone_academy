import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'inquiry_details_screen.dart';
import 'create_inquiry_screen.dart';

class InquiryManagementScreen extends StatefulWidget {
  const InquiryManagementScreen({super.key});

  @override
  State<InquiryManagementScreen> createState() => _InquiryManagementScreenState();
}

class _InquiryManagementScreenState extends State<InquiryManagementScreen> {
  final _searchController = TextEditingController();
  String _selectedStatus = 'All';
  DateTime? _startDate;
  DateTime? _endDate;
  List<QueryDocumentSnapshot> _inquiries = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadInquiries();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInquiries() async {
    setState(() => _isLoading = true);

    try {
      Query query = FirebaseFirestore.instance.collection('inquiries');

      // Apply status filter
      if (_selectedStatus != 'All') {
        query = query.where('status', isEqualTo: _selectedStatus);
      }

      // Apply date range filter
      if (_startDate != null) {
        query = query.where('createdAt', isGreaterThanOrEqualTo: _startDate);
      }
      if (_endDate != null) {
        query = query.where('createdAt', isLessThanOrEqualTo: _endDate);
      }

      // Order by creation date
      query = query.orderBy('createdAt', descending: true);

      final snapshot = await query.get();
      setState(() {
        _inquiries = snapshot.docs;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading inquiries: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<QueryDocumentSnapshot> _filterInquiries() {
    if (_searchController.text.isEmpty) {
      return _inquiries;
    }

    final searchTerm = _searchController.text.toLowerCase();
    return _inquiries.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return data['name'].toString().toLowerCase().contains(searchTerm) ||
          data['phone'].toString().toLowerCase().contains(searchTerm) ||
          data['email'].toString().toLowerCase().contains(searchTerm);
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
      _loadInquiries();
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredInquiries = _filterInquiries();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inquiry Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateInquiryScreen(),
                ),
              );
              if (result == true) {
                _loadInquiries();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Search by name, phone, or email',
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                    ),
                  ),
                  onChanged: (value) => setState(() {}),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedStatus,
                        decoration: const InputDecoration(
                          labelText: 'Status',
                          border: OutlineInputBorder(),
                        ),
                        items: ['All', 'New', 'In Progress', 'Completed', 'Cancelled']
                            .map((status) => DropdownMenuItem(
                                  value: status,
                                  child: Text(status),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedStatus = value);
                            _loadInquiries();
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _selectDateRange,
                        icon: const Icon(Icons.date_range),
                        label: Text(_startDate == null
                            ? 'Select Date Range'
                            : '${_startDate!.day}/${_startDate!.month}/${_startDate!.year} - ${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredInquiries.isEmpty
                    ? const Center(child: Text('No inquiries found'))
                    : ListView.builder(
                        itemCount: filteredInquiries.length,
                        itemBuilder: (context, index) {
                          final doc = filteredInquiries[index];
                          final data = doc.data() as Map<String, dynamic>;
                          final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
                          
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: ListTile(
                              title: Text(data['name'] ?? 'Unknown'),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(data['phone'] ?? 'No phone'),
                                  Text(data['email'] ?? 'No email'),
                                  Text('Course: ${data['interestedCourse'] ?? 'Not specified'}'),
                                  if (createdAt != null)
                                    Text(
                                      'Created: ${createdAt.day}/${createdAt.month}/${createdAt.year}',
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                ],
                              ),
                              trailing: Chip(
                                label: Text(data['status'] ?? 'Unknown'),
                                backgroundColor: _getStatusColor(data['status']),
                              ),
                              onTap: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => InquiryDetailsScreen(
                                      inquiryId: doc.id,
                                      inquiry: data,
                                    ),
                                  ),
                                );
                                if (result == true) {
                                  _loadInquiries();
                                }
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'New':
        return Colors.blue.shade100;
      case 'In Progress':
        return Colors.orange.shade100;
      case 'Completed':
        return Colors.green.shade100;
      case 'Cancelled':
        return Colors.red.shade100;
      default:
        return Colors.grey.shade100;
    }
  }
} 