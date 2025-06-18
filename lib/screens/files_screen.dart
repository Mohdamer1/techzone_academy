import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/batch_service.dart';
import '../services/auth_service.dart';

class FilesScreen extends StatefulWidget {
  final String? batchId;
  final String? topicId;
  
  const FilesScreen({super.key, this.batchId, this.topicId});

  @override
  State<FilesScreen> createState() => _FilesScreenState();
}

class _FilesScreenState extends State<FilesScreen> {
  final BatchService _batchService = BatchService();
  final AuthService _authService = AuthService();
  
  List<Map<String, dynamic>> _files = [];
  Map<String, dynamic>? _userData;
  String? _userRole;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadFiles();
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

  Future<void> _loadFiles() async {
    setState(() => _isLoading = true);
    
    try {
      if (widget.batchId != null) {
        // Load files for specific batch
        final files = await _batchService.getBatchFiles(widget.batchId!);
        setState(() {
          _files = files;
          _isLoading = false;
        });
      } else {
        // Load all files for user's batches (for students)
        final batches = await _batchService.getUserBatches();
        List<Map<String, dynamic>> allFiles = [];
        
        for (final batch in batches) {
          final batchFiles = await _batchService.getBatchFiles(batch['id']);
          for (final file in batchFiles) {
            allFiles.add({
              ...file,
              'batchName': batch['name'],
              'batchId': batch['id'],
            });
          }
        }
        
        setState(() {
          _files = allFiles;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading files: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addFile() async {
    if (widget.batchId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a batch first')),
      );
      return;
    }

    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final fileTypeController = TextEditingController();

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New File'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'File Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: fileTypeController,
              decoration: const InputDecoration(
                labelText: 'File Type (e.g., PDF, DOC, PPT)',
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
              if (titleController.text.isNotEmpty && fileTypeController.text.isNotEmpty) {
                Navigator.of(context).pop({
                  'title': titleController.text,
                  'fileType': fileTypeController.text,
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
        await _batchService.addFileToBatch(widget.batchId!, {
          'title': result['title']!,
          'fileType': result['fileType']!,
          'description': result['description'] ?? '',
          'uploadedBy': _userData?['name'] ?? 'Unknown User',
          'topicId': widget.topicId,
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('File added successfully')),
          );
          _loadFiles();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error adding file: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String screenTitle = 'Files';
    if (widget.topicId != null) {
      screenTitle = 'Files - ${widget.topicId}';
    }

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
                  Expanded(
                    child: Text(
                      screenTitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
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
                      onPressed: _addFile,
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
                  : _files.isEmpty
                      ? _buildEmptyView()
                      : _buildFilesList(),
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
            Icons.folder,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _userRole == 'trainer' ? 'No files uploaded yet' : 'No files available',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _userRole == 'trainer' 
                ? 'Upload your first file to get started'
                : 'Files will appear here once uploaded by your trainer',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          if (_userRole == 'trainer' && widget.batchId != null) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _addFile,
              icon: const Icon(Icons.upload_file),
              label: const Text('Upload First File'),
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

  Widget _buildFilesList() {
    return ListView.separated(
      itemCount: _files.length,
      separatorBuilder: (context, index) => const SizedBox(height: 0),
      itemBuilder: (context, index) {
        final file = _files[index];
        return _buildFileCard(
          title: file['title'] ?? 'Unknown File',
          fileType: file['fileType'] ?? 'Unknown',
          description: file['description'] ?? '',
          uploadedBy: file['uploadedBy'] ?? 'Unknown User',
          batchName: file['batchName'],
          createdAt: file['createdAt'] as Timestamp?,
        );
      },
    );
  }

  Widget _buildFileCard({
    required String title,
    required String fileType,
    required String description,
    required String uploadedBy,
    String? batchName,
    Timestamp? createdAt,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
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
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B80EE).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      fileType.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF0B80EE),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (batchName != null) ...[
                    Text(
                      'Batch: $batchName',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF60758A),
                      ),
                    ),
                    const SizedBox(height: 2),
                  ],
                  Text(
                    'Uploaded by: $uploadedBy',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF60758A),
                    ),
                  ),
                  if (createdAt != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Uploaded: ${_formatDate(createdAt.toDate())}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF60758A),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              child: const Icon(Icons.download, color: Color(0xFF111418)),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
} 