import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/batch_service.dart';
import '../services/auth_service.dart';
import 'files_screen.dart';

class TopicsScreen extends StatefulWidget {
  final String? batchId;
  
  const TopicsScreen({super.key, this.batchId});

  @override
  State<TopicsScreen> createState() => _TopicsScreenState();
}

class _TopicsScreenState extends State<TopicsScreen> {
  final BatchService _batchService = BatchService();
  final AuthService _authService = AuthService();
  
  List<Map<String, dynamic>> _topics = [];
  Map<String, dynamic>? _userData;
  String? _userRole;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadTopics();
  }

  Future<void> _loadUserData() async {
    try {
      final userData = await _authService.getUserData();
      final role = await _batchService.getUserRole();
      setState(() {
        _userData = userData;
        _userRole = role;
      });
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  Future<void> _loadTopics() async {
    setState(() => _isLoading = true);
    
    try {
      if (widget.batchId != null) {
        // Load topics for specific batch
        final topics = await _batchService.getBatchTopics(widget.batchId!);
        setState(() {
          _topics = topics;
          _isLoading = false;
        });
      } else {
        // Load all topics for user's batches (for students)
        final batches = await _batchService.getUserBatches();
        List<Map<String, dynamic>> allTopics = [];
        
        for (final batch in batches) {
          final batchTopics = await _batchService.getBatchTopics(batch['id']);
          for (final topic in batchTopics) {
            allTopics.add({
              ...topic,
              'batchName': batch['name'],
              'batchId': batch['id'],
            });
          }
        }
        
        setState(() {
          _topics = allTopics;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading topics: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addTopic() async {
    if (widget.batchId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a batch first')),
      );
      return;
    }

    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final dayController = TextEditingController();

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Topic'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Topic Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: dayController,
              decoration: const InputDecoration(
                labelText: 'Day (e.g., Day 1, Week 1)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.isNotEmpty && dayController.text.isNotEmpty) {
                Navigator.of(context).pop({
                  'title': titleController.text,
                  'day': dayController.text,
                  'description': descriptionController.text,
                });
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result != null) {
      try {
        await _batchService.addTopicToBatch(widget.batchId!, {
          'title': result['title']!,
          'day': result['day']!,
          'description': result['description'] ?? '',
          'trainerName': _userData?['name'] ?? 'Unknown Trainer',
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Topic added successfully')),
          );
          _loadTopics();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error adding topic: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, size: 24, color: Color(0xFF111418)),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Expanded(
                    child: Text(
                      'Topics',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.015,
                        color: Color(0xFF111418),
                      ),
                    ),
                  ),
                  if (_userRole == 'trainer' && widget.batchId != null)
                    IconButton(
                      icon: const Icon(Icons.add, size: 24, color: Color(0xFF111418)),
                      onPressed: _addTopic,
                    )
                  else
                    const SizedBox(width: 48), // To balance the back icon
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _topics.isEmpty
                      ? _buildEmptyView()
                      : _buildTopicsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.book,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _userRole == 'trainer' ? 'No topics added yet' : 'No topics available',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _userRole == 'trainer' 
                ? 'Add your first topic to get started'
                : 'Topics will appear here once added by your trainer',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          if (_userRole == 'trainer' && widget.batchId != null) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _addTopic,
              icon: const Icon(Icons.add),
              label: const Text('Add First Topic'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0B80EE),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTopicsList() {
    return ListView.separated(
      itemCount: _topics.length,
      separatorBuilder: (context, index) => const SizedBox(height: 0),
      itemBuilder: (context, index) {
        final topic = _topics[index];
        return _buildTopicCard(
          context,
          title: topic['title'] ?? 'Unknown Topic',
          day: topic['day'] ?? '',
          description: topic['description'] ?? '',
          trainer: topic['trainerName'] ?? 'Unknown Trainer',
          batchName: topic['batchName'],
          createdAt: topic['createdAt'] as Timestamp?,
        );
      },
    );
  }

  Widget _buildTopicCard(
    BuildContext context, {
    required String title,
    required String day,
    required String description,
    required String trainer,
    String? batchName,
    Timestamp? createdAt,
  }) {
    return GestureDetector(
      onTap: () {
        // Navigate to files for this topic
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => FilesScreen(
              batchId: widget.batchId ?? batchName,
              topicId: title, // Use title as topic identifier
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F2F5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.insert_drive_file, color: Color(0xFF111418)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF111418),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            day,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF0B80EE),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (batchName != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              'Batch: $batchName',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF60758A),
                              ),
                            ),
                          ],
                          const SizedBox(height: 2),
                          Text(
                            'Trainer: $trainer',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF60758A),
                            ),
                          ),
                          if (createdAt != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              'Added: ${_formatDate(createdAt.toDate())}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFF60758A),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                child: const Icon(Icons.chevron_right, color: Color(0xFF111418)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
} 