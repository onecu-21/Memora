import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as p;

class StoredDocument { const StoredDocument(this.originalPath, this.mimeType); final String originalPath, mimeType; }
class DocumentFileStore {
  DocumentFileStore(this.root); final Directory root; static const maxBytes = 50 * 1024 * 1024;
  static const allowed = {'image/jpeg', 'image/png', 'image/webp', 'application/pdf'};
  Future<StoredDocument> preserveOriginal({required String documentId, required Uint8List bytes}) async { if (bytes.isEmpty || bytes.length > maxBytes) throw const FormatException('File must be between 1 byte and 50 MB'); final mime = _sniff(bytes); if (!allowed.contains(mime)) throw const FormatException('Only JPEG, PNG, WebP, and PDF are supported'); final safeId = documentId.replaceAll(RegExp('[^a-zA-Z0-9-]'), ''); if (safeId != documentId || safeId.isEmpty) throw const FormatException('Invalid document ID'); final directory = Directory(p.join(root.path, 'documents', safeId)); await directory.create(recursive: true); final target = File(p.join(directory.path, 'original')); await target.writeAsBytes(bytes, flush: true); return StoredDocument(target.path, mime); }
  String _sniff(Uint8List b) { if (b.length >= 4 && b[0] == 0x25 && b[1] == 0x50 && b[2] == 0x44 && b[3] == 0x46) return 'application/pdf'; if (b.length >= 3 && b[0] == 0xff && b[1] == 0xd8 && b[2] == 0xff) return 'image/jpeg'; if (b.length >= 8 && b[0] == 0x89 && b[1] == 0x50 && b[2] == 0x4e && b[3] == 0x47) return 'image/png'; if (b.length >= 12 && String.fromCharCodes(b.sublist(0, 4)) == 'RIFF' && String.fromCharCodes(b.sublist(8, 12)) == 'WEBP') return 'image/webp'; return 'unknown'; }
}
