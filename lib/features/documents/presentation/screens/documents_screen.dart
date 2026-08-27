import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:fluppy/fluppy.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:corevia_mobile/core/theme/colors.dart';
import 'package:corevia_mobile/l10n/app_localizations.dart';
import '../providers/document_provider.dart';
import '../../domain/entities/document_entity.dart';

const _allowedExtensions = ['jpg', 'jpeg', 'png', 'webp', 'pdf', 'doc', 'docx'];
const _maxFileSize = 25 * 1024 * 1024; // 25 MB

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  Fluppy? _fluppy;
  StreamSubscription<FluppyEvent>? _eventSub;

  // Upload state
  final Map<String, _UploadEntry> _uploads = {};
  double _overallProgress = 0;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DocumentProvider>().loadDocuments();
    });
  }

  @override
  void dispose() {
    _eventSub?.cancel();
    _fluppy?.dispose();
    super.dispose();
  }

  Fluppy _getFluppy() {
    if (_fluppy != null) return _fluppy!;

    final provider = context.read<DocumentProvider>();
    final fileDocIds = <String, String>{};

    final fluppy = Fluppy(
      uploader: S3Uploader(
        options: S3UploaderOptions(
          shouldUseMultipart: (_) => false,
          getUploadParameters: (file, options) async {
            final result = await provider.requestUpload(
              fileName: file.name,
              mimeType: file.type ?? 'application/octet-stream',
              fileSize: file.size,
            );
            fileDocIds[file.id] = result['documentId']!;
            return UploadParameters(
              method: 'PUT',
              url: result['uploadUrl']!,
              headers: {
                'Content-Type': file.type ?? 'application/octet-stream'
              },
            );
          },
          createMultipartUpload: (_) async =>
              throw UnsupportedError('Multipart not used'),
          signPart: (_, __) async =>
              throw UnsupportedError('Multipart not used'),
          completeMultipartUpload: (_, __) async =>
              throw UnsupportedError('Multipart not used'),
          listParts: (_, __) async =>
              throw UnsupportedError('Multipart not used'),
          abortMultipartUpload: (_, __) async =>
              throw UnsupportedError('Multipart not used'),
        ),
      ),
    );

    _eventSub = fluppy.events.listen((event) {
      if (!mounted) return;
      switch (event) {
        case UploadProgress(:final file, :final progress):
          setState(() {
            final entry = _uploads[file.id];
            if (entry != null) {
              entry.progress = progress.percent / 100;
              entry.status = _UploadStatus.uploading;
            }
            _overallProgress = fluppy.overallProgress.percent / 100;
          });
        case UploadComplete(:final file):
          final docId = fileDocIds[file.id];
          if (docId != null) {
            provider.confirmUpload(docId).then((_) {
              if (!mounted) return;
              setState(() {
                _uploads[file.id]?.status = _UploadStatus.confirmed;
              });
              _checkAllDone();
            }).catchError((e) {
              if (!mounted) return;
              setState(() {
                _uploads[file.id]?.status = _UploadStatus.error;
                _uploads[file.id]?.error =
                    context.l10n.confirmUploadFailed(
                      _localizedUploadError(context, e.toString()),
                    );
              });
              _checkAllDone();
            });
          }
        case UploadError(:final file, :final message):
          final localizedMessage = _localizedUploadError(context, message);
          setState(() {
            _uploads[file.id]?.status = _UploadStatus.error;
            _uploads[file.id]?.error = localizedMessage;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(localizedMessage)),
          );
          _checkAllDone();
        default:
          break;
      }
    });

    _fluppy = fluppy;
    return fluppy;
  }

  void _checkAllDone() {
    final allTerminal = _uploads.values.every(
      (e) =>
          e.status == _UploadStatus.confirmed ||
          e.status == _UploadStatus.error,
    );
    if (allTerminal && _isUploading) {
      setState(() => _isUploading = false);
      final successCount = _uploads.values
          .where((e) => e.status == _UploadStatus.confirmed)
          .length;
      if (successCount > 0 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.filesUploaded(successCount))),
        );
      }
    }
  }

  String _localizedUploadError(BuildContext context, String message) {
    final lower = message.toLowerCase();
    if (lower.contains('too large') ||
        lower.contains('file size') ||
        lower.contains('larger than') ||
        lower.contains('size limit')) {
      return context.l10n.uploadFailedFileTooLarge;
    }
    if (lower.contains('network') ||
        lower.contains('socket') ||
        lower.contains('timeout') ||
        lower.contains('connection')) {
      return context.l10n.uploadFailedNetwork;
    }
    return message;
  }

  Future<void> _pickAndUpload() async {
    final result = await FilePicker.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: _allowedExtensions,
    );
    if (result == null || result.files.isEmpty) return;

    final fluppy = _getFluppy();

    for (final pf in result.files) {
      if (pf.path == null) continue;
      if (pf.size > _maxFileSize) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.fileTooLarge(pf.name))),
          );
        }
        continue;
      }

      final file = fluppy.addFile(FluppyFile.fromPath(pf.path!, name: pf.name));
      setState(() {
        _uploads[file.id] = _UploadEntry(name: pf.name, size: pf.size);
      });
    }

    if (fluppy.pendingFiles.isNotEmpty) {
      setState(() => _isUploading = true);
      await fluppy.upload();
    }
  }

  void _removeUpload(String fileId) {
    _fluppy?.removeFile(fileId);
    setState(() => _uploads.remove(fileId));
  }

  Future<void> _downloadDocument(DocumentEntity doc) async {
    try {
      final provider = context.read<DocumentProvider>();
      final url = await provider.getDownloadUrl(doc.id);
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.failedToDownload(e.toString()))),
        );
      }
    }
  }

  Future<void> _deleteDocument(DocumentEntity doc) async {
    final provider = context.read<DocumentProvider>();
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.deleteDocumentTitle),
        content: Text(context.l10n.deleteDocumentConfirm(doc.fileName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx, rootNavigator: true).pop(false),
            child: Text(context.l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx, rootNavigator: true).pop(true),
            child: Text(
              context.l10n.delete,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await provider.deleteDocument(doc.id);
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(context.l10n.documentDeleted)),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(context.l10n.failedToDelete(e.toString()))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Consumer<DocumentProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoading && provider.documents.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return RefreshIndicator(
                    onRefresh: provider.loadDocuments,
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        const SizedBox(height: 16),
                        if (_uploads.isNotEmpty) ...[
                          _buildUploadSection(),
                          const SizedBox(height: 20),
                        ],
                        _buildUploadButton(),
                        const SizedBox(height: 20),
                        _buildDocumentsList(provider),
                        const SizedBox(height: 100),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, size: 24),
            onPressed: () => context.pop(),
            padding: EdgeInsets.zero,
          ),
          const SizedBox(width: 8),
          Text(
            context.l10n.myDocuments,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1D1D1F),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadButton() {
    return GestureDetector(
      onTap: _isUploading ? null : _pickAndUpload,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _isUploading
              ? Colors.grey.shade100
              : AppColors.green.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _isUploading
                ? Colors.grey.shade300
                : AppColors.green.withValues(alpha: 0.3),
            width: 1.5,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.upload,
              color: _isUploading ? Colors.grey : AppColors.green,
              size: 22,
            ),
            const SizedBox(width: 12),
            Text(
              _isUploading
                  ? context.l10n.uploading
                  : context.l10n.uploadDocuments,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _isUploading ? Colors.grey : AppColors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isUploading) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.l10n.uploadingTitle,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600),
                ),
                Text(
                  '${(_overallProgress * 100).round()}%',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _overallProgress,
                backgroundColor: Colors.grey.shade200,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.green),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 12),
          ],
          ..._uploads.entries
              .map((entry) => _buildUploadItem(entry.key, entry.value)),
        ],
      ),
    );
  }

  Widget _buildUploadItem(String fileId, _UploadEntry entry) {
    final IconData statusIcon;
    final Color statusColor;

    switch (entry.status) {
      case _UploadStatus.uploading:
        statusIcon = LucideIcons.loader;
        statusColor = Colors.blue;
      case _UploadStatus.confirmed:
        statusIcon = LucideIcons.check;
        statusColor = AppColors.green;
      case _UploadStatus.error:
        statusIcon = LucideIcons.x;
        statusColor = Colors.red;
      case _UploadStatus.pending:
        statusIcon = LucideIcons.clock;
        statusColor = Colors.grey;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(statusIcon, size: 18, color: statusColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.name,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (entry.status == _UploadStatus.uploading)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: entry.progress,
                        backgroundColor: Colors.grey.shade200,
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(Colors.blue),
                        minHeight: 3,
                      ),
                    ),
                  ),
                if (entry.status == _UploadStatus.error && entry.error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      entry.error!,
                      style: const TextStyle(fontSize: 11, color: Colors.red),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            _formatSize(entry.size),
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          if (entry.status == _UploadStatus.pending)
            IconButton(
              icon: const Icon(LucideIcons.x, size: 16),
              onPressed: () => _removeUpload(fileId),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
        ],
      ),
    );
  }

  Widget _buildDocumentsList(DocumentProvider provider) {
    if (provider.documents.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(LucideIcons.fileText, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              context.l10n.noDocumentsYet,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.uploadFirstDocument,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Text(
              context.l10n.yourDocuments,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1D1D1F),
              ),
            ),
          ),
          ...provider.documents.map(_buildDocumentTile),
        ],
      ),
    );
  }

  Widget _buildDocumentTile(DocumentEntity doc) {
    return InkWell(
      onTap: () => _downloadDocument(doc),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_mimeIcon(doc.mimeType),
                  color: AppColors.green, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doc.fileName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1D1D1F),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${doc.fileSizeFormatted} · ${_formatDate(doc.createdAt)}',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(LucideIcons.trash2,
                  size: 18, color: Colors.red.shade300),
              onPressed: () => _deleteDocument(doc),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
          ],
        ),
      ),
    );
  }

  IconData _mimeIcon(String mimeType) {
    if (mimeType.startsWith('image/')) return LucideIcons.image;
    if (mimeType == 'application/pdf') return LucideIcons.fileText;
    return LucideIcons.file;
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

// ── Internal upload tracking ────────────────────────────────────────────────

enum _UploadStatus { pending, uploading, confirmed, error }

class _UploadEntry {
  final String name;
  final int size;
  double progress = 0;
  _UploadStatus status = _UploadStatus.pending;
  String? error;

  _UploadEntry({required this.name, required this.size});
}
