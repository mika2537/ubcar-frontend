import 'dart:async';

import 'package:flutter/material.dart';

enum _DocumentType { license, registration, photo, insurance }
enum _DocumentStatus { pending, uploaded, verified, rejected }

class _Document {
  final _DocumentType id;
  final String title;
  final String description;
  _DocumentStatus status;
  String? file;

  _Document({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    this.file,
  });
}

class DriverDocumentScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final VoidCallback? onComplete;

  const DriverDocumentScreen({
    super.key,
    this.onBack,
    this.onComplete,
  });

  @override
  State<DriverDocumentScreen> createState() => _DriverDocumentScreenState();
}

class _DriverDocumentScreenState extends State<DriverDocumentScreen> {
  late List<_Document> documents;
  _DocumentType? selectedDoc;
  bool isUploading = false;

  @override
  void initState() {
    super.initState();
    documents = [
      _Document(
        id: _DocumentType.license,
        title: "Driver's License",
        description: 'Front and back of your license',
        status: _DocumentStatus.pending,
      ),
      _Document(
        id: _DocumentType.registration,
        title: 'Vehicle Registration',
        description: 'RC book or registration certificate',
        status: _DocumentStatus.pending,
      ),
      _Document(
        id: _DocumentType.photo,
        title: 'Profile Photo',
        description: 'Clear photo of your face',
        status: _DocumentStatus.pending,
      ),
      _Document(
        id: _DocumentType.insurance,
        title: 'Vehicle Insurance',
        description: 'Valid insurance document',
        status: _DocumentStatus.pending,
      ),
    ];
  }

  bool get allUploaded => documents.every((d) => d.status != _DocumentStatus.pending);
  int get uploadedCount => documents.where((d) => d.status != _DocumentStatus.pending).length;

  Color _badgeBg(_DocumentStatus status) {
    switch (status) {
      case _DocumentStatus.pending:
        return Colors.grey.shade200;
      case _DocumentStatus.uploaded:
        return Colors.orange.withOpacity(0.15);
      case _DocumentStatus.verified:
        return Colors.green.withOpacity(0.15);
      case _DocumentStatus.rejected:
        return Colors.red.withOpacity(0.15);
    }
  }

  Color _badgeText(_DocumentStatus status) {
    switch (status) {
      case _DocumentStatus.pending:
        return Colors.black54;
      case _DocumentStatus.uploaded:
        return Colors.orange.shade800;
      case _DocumentStatus.verified:
        return Colors.green.shade800;
      case _DocumentStatus.rejected:
        return Colors.red.shade800;
    }
  }

  String _statusLabel(_DocumentStatus status) {
    switch (status) {
      case _DocumentStatus.pending:
        return 'Required';
      case _DocumentStatus.uploaded:
        return 'Under Review';
      case _DocumentStatus.verified:
        return 'Verified';
      case _DocumentStatus.rejected:
        return 'Rejected';
    }
  }

  IconData _docIcon(_DocumentType id) {
    switch (id) {
      case _DocumentType.license:
        return Icons.file_copy;
      case _DocumentType.registration:
        return Icons.directions_car;
      case _DocumentType.photo:
        return Icons.person;
      case _DocumentType.insurance:
        return Icons.shield;
    }
  }

  Future<void> handleUpload(_DocumentType docId) async {
    if (isUploading) return;
    setState(() => isUploading = true);

    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    setState(() {
      documents = documents.map((d) {
        if (d.id != docId) return d;
        return _Document(
          id: d.id,
          title: d.title,
          description: d.description,
          status: _DocumentStatus.uploaded,
          file: 'document.pdf',
        );
      }).toList();

      selectedDoc = null;
      isUploading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final selected = selectedDoc == null
        ? null
        : documents.firstWhere((d) => d.id == selectedDoc);

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: widget.onBack,
                        icon: const Icon(Icons.arrow_back),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.grey.shade200,
                          shape: const CircleBorder(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Document Verification',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                            ),
                            SizedBox(height: 6),
                            Text('Upload required documents', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Verification Progress',
                              style: TextStyle(fontWeight: FontWeight.w800, color: Colors.black54),
                            ),
                            const Spacer(),
                            Text(
                              '$uploadedCount/${documents.length}',
                              style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.indigo),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: uploadedCount / documents.length,
                            minHeight: 8,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.indigo),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
                    itemCount: documents.length,
                    itemBuilder: (context, index) {
                      final doc = documents[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: ListTile(
                          onTap: () => setState(() => selectedDoc = doc.id),
                          leading: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: doc.status == _DocumentStatus.verified
                                  ? Colors.green.withOpacity(0.12)
                                  : doc.status == _DocumentStatus.uploaded
                                      ? Colors.orange.withOpacity(0.12)
                                      : doc.status == _DocumentStatus.rejected
                                          ? Colors.red.withOpacity(0.12)
                                          : Colors.indigo.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(_docIcon(doc.id),
                                color: doc.status == _DocumentStatus.verified
                                    ? Colors.green
                                    : doc.status == _DocumentStatus.uploaded
                                        ? Colors.orange.shade800
                                        : doc.status == _DocumentStatus.rejected
                                            ? Colors.red.shade800
                                            : Colors.indigo),
                          ),
                          title: Text(doc.title, style: const TextStyle(fontWeight: FontWeight.w900)),
                          subtitle: Text(doc.description, style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w700)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _badgeBg(doc.status),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _statusLabel(doc.status),
                                  style: TextStyle(
                                    color: _badgeText(doc.status),
                                    fontWeight: FontWeight.w900,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.chevron_right),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: allUploaded ? widget.onComplete : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        disabledBackgroundColor: Colors.indigo.withOpacity(0.35),
                      ),
                      child: Text(
                        allUploaded ? 'Submit for Review' : 'Upload All Documents',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            if (selected != null)
              Positioned.fill(
                child: Container(
                  color: Colors.black45,
                  child: Center(
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(26),
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                            child: Row(
                              children: [
                                IconButton(
                                  onPressed: () => setState(() => selectedDoc = null),
                                  icon: const Icon(Icons.close),
                                  style: IconButton.styleFrom(
                                    backgroundColor: Colors.grey.shade200,
                                    shape: const CircleBorder(),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    selected.title,
                                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          Expanded(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              child: Column(
                                children: [
                                  AspectRatio(
                                    aspectRatio: 4 / 3,
                                    child: Container(
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(26),
                                        border: Border.all(
                                          color: isUploading ? Colors.indigo.withOpacity(0.75) : Colors.grey.shade300,
                                          width: 2,
                                          style: BorderStyle.solid,
                                        ),
                                        color: isUploading ? Colors.indigo.withOpacity(0.06) : Colors.grey.shade50,
                                      ),
                                      child: Center(
                                        child: isUploading
                                            ? Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: const [
                                                  SizedBox(
                                                    width: 46,
                                                    height: 46,
                                                    child: CircularProgressIndicator(strokeWidth: 3),
                                                  ),
                                                  SizedBox(height: 12),
                                                  Text('Uploading...', style: TextStyle(fontWeight: FontWeight.w900)),
                                                ],
                                              )
                                            : selected.status != _DocumentStatus.pending
                                                ? Column(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      const Icon(Icons.check_circle, size: 56, color: Colors.green),
                                                      const SizedBox(height: 10),
                                                      const Text(
                                                        'Document Uploaded',
                                                        style: TextStyle(fontWeight: FontWeight.w900),
                                                      ),
                                                      const SizedBox(height: 6),
                                                      Text(selected.file ?? 'document.pdf', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w700)),
                                                    ],
                                                  )
                                                : Column(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: const [
                                                      Icon(Icons.upload_file, size: 56, color: Colors.black45),
                                                      SizedBox(height: 12),
                                                      Text('Tap to upload', style: TextStyle(fontWeight: FontWeight.w900)),
                                                      SizedBox(height: 6),
                                                      Text('or drag and drop', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w700)),
                                                    ],
                                                  ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 14),

                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Guidelines',
                                          style: TextStyle(fontWeight: FontWeight.w900),
                                        ),
                                        const SizedBox(height: 10),
                                        ...const [
                                          'Document should be clearly visible',
                                          'All text must be readable',
                                          'File size under 10MB (JPG, PNG, PDF)',
                                        ].map((t) {
                                          return Padding(
                                            padding: const EdgeInsets.only(bottom: 8),
                                            child: Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Icon(Icons.check, size: 16, color: Colors.green),
                                                const SizedBox(width: 8),
                                                Expanded(child: Text(t, style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w700))),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: Column(
                              children: [
                                SizedBox(
                                  width: double.infinity,
                                  height: 46,
                                  child: ElevatedButton.icon(
                                    onPressed: isUploading ? null : () => handleUpload(selected.id),
                                    icon: const Icon(Icons.camera_alt),
                                    label: const Text('Take Photo'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.indigo,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: double.infinity,
                                  height: 46,
                                  child: OutlinedButton.icon(
                                    onPressed: isUploading ? null : () => handleUpload(selected.id),
                                    icon: const Icon(Icons.upload),
                                    label: const Text('Upload from Gallery'),
                                    style: OutlinedButton.styleFrom(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
