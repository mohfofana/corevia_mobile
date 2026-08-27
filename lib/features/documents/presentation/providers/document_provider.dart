import 'package:flutter/foundation.dart';
import '../../data/repositories/document_repository.dart';
import '../../domain/entities/document_entity.dart';

class DocumentProvider with ChangeNotifier {
  final DocumentRepository _repository = DocumentRepository();

  List<DocumentEntity> _documents = [];
  bool _isLoading = false;
  String? _error;

  List<DocumentEntity> get documents => _documents;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadDocuments() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _documents = await _repository.listDocuments();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, String>> requestUpload({
    required String fileName,
    required String mimeType,
    required int fileSize,
  }) {
    return _repository.requestUpload(
      fileName: fileName,
      mimeType: mimeType,
      fileSize: fileSize,
    );
  }

  Future<void> confirmUpload(String documentId) async {
    try {
      await _repository.confirmUpload(documentId);
      await loadDocuments();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<String> getDownloadUrl(String documentId) {
    return _repository.getDownloadUrl(documentId);
  }

  Future<void> deleteDocument(String documentId) async {
    try {
      await _repository.deleteDocument(documentId);
      _documents.removeWhere((d) => d.id == documentId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }
}
