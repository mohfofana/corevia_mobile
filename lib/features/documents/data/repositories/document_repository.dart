import 'package:corevia_mobile/networking/api_service.dart';
import 'package:corevia_mobile/networking/routes/document_routes.dart';
import '../../domain/entities/document_entity.dart';

class DocumentRepository {
  Future<List<DocumentEntity>> listDocuments() async {
    final res = await ApiService.authGet(DocumentRoutes.list());
    final List<dynamic> items = res as List<dynamic>;
    return items
        .map((e) => DocumentEntity.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Returns { documentId, uploadUrl }
  Future<Map<String, String>> requestUpload({
    required String fileName,
    required String mimeType,
    required int fileSize,
  }) async {
    final res = await ApiService.authPost(DocumentRoutes.requestUpload(), {
      'fileName': fileName,
      'mimeType': mimeType,
      'fileSize': fileSize,
    });
    final data = res as Map<String, dynamic>;
    return {
      'documentId': data['documentId'] as String,
      'uploadUrl': data['uploadUrl'] as String,
    };
  }

  Future<void> confirmUpload(String documentId) async {
    await ApiService.authPost(DocumentRoutes.confirmUpload(documentId), {});
  }

  Future<String> getDownloadUrl(String documentId) async {
    final res = await ApiService.authGet(DocumentRoutes.downloadUrl(documentId));
    final data = res as Map<String, dynamic>;
    return data['downloadUrl'] as String;
  }

  Future<void> deleteDocument(String documentId) async {
    await ApiService.authDelete(DocumentRoutes.delete(documentId));
  }
}
