class DocumentRoutes {
  static const String base = '/api/documents';

  /// POST - Request a presigned upload URL
  static String requestUpload() => '$base/upload';

  /// POST - Confirm upload after file is in S3
  static String confirmUpload(String documentId) => '$base/$documentId/confirm';

  /// GET - List current user's documents
  static String list() => base;

  /// GET - Get presigned download URL
  static String downloadUrl(String documentId) => '$base/$documentId/download';

  /// DELETE - Soft-delete a document
  static String delete(String documentId) => '$base/$documentId';
}
