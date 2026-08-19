import '../core/models.dart';
abstract interface class SyncTransport { Future<void> push(List<Map<String, dynamic>> records); }
class SyncResult { const SyncResult(this.state, this.pending, [this.message]); final SyncState state; final int pending; final String? message; }
class SyncEngine {
  SyncEngine(this.transport); final SyncTransport transport;
  Future<SyncResult> synchronize(List<Map<String, dynamic>> records) async { if (records.isEmpty) return const SyncResult(SyncState.synced, 0); try { await transport.push(records); return const SyncResult(SyncState.synced, 0); } catch (_) { return SyncResult(SyncState.error, records.length, 'Sync failed; changes remain saved locally.'); } }
  Concept resolveConcept(Concept local, Concept remote) { if (local.userConfirmed && remote.updatedAt.isAfter(local.updatedAt)) { return Concept(id: local.id, documentId: local.documentId, subjectId: local.subjectId, unitId: local.unitId, name: local.name, statement: local.statement, explanation: local.explanation, confidence: local.confidence, sourceEvidence: local.sourceEvidence, userConfirmed: true, createdAt: local.createdAt, updatedAt: local.updatedAt, syncRevision: local.syncRevision, syncState: SyncState.conflict); } return remote.updatedAt.isAfter(local.updatedAt) ? remote : local; }
  Map<String,dynamic> settingsPayload({required String provider, required bool darkMode}) => {'provider': provider, 'darkMode': darkMode};
}
