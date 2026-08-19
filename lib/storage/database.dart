import 'dart:convert';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../core/models.dart';

class MemoraDatabase {
  MemoraDatabase._(this.db); final Database db;
  static const schemaVersion = 1;
  static Future<MemoraDatabase> open(String directory) async { sqfliteFfiInit(); final db = await databaseFactoryFfi.openDatabase(p.join(directory, 'memora.db'), options: OpenDatabaseOptions(version: schemaVersion, onCreate: (db, version) async { for (final statement in _schema) { await db.execute(statement); } await _seedSubjects(db); })); return MemoraDatabase._(db); }
  static Future<void> _seedSubjects(Database db) async { for (final name in ['Korean','Mathematics','English','Science','Social Studies','History','Other']) { await db.insert('subjects', {'id': 'subject-${name.toLowerCase().replaceAll(' ', '-')}', 'name': name, 'updated_at': DateTime.now().toUtc().toIso8601String(), 'sync_state': 'localOnly'}); } }
  Future<void> saveConcept(Concept c) => db.insert('concepts', {'id': c.id, 'document_id': c.documentId, 'subject_id': c.subjectId, 'unit_id': c.unitId, 'name': c.name, 'statement': c.statement, 'explanation': c.explanation, 'confidence': c.confidence, 'evidence_json': encodeEvidence(c.sourceEvidence), 'user_confirmed': c.userConfirmed ? 1 : 0, 'created_at': c.createdAt.toIso8601String(), 'updated_at': c.updatedAt.toIso8601String(), 'sync_state': 'dirty'}, conflictAlgorithm: ConflictAlgorithm.replace).then((_) {});
  Future<void> recordAttempt({required String id, required GeneratedQuestion question, required String answer, required bool correct}) async { await db.transaction((txn) async { await txn.insert('quiz_attempts', {'id': id, 'question_id': question.id, 'concept_id': question.conceptId, 'submitted_answer': answer, 'expected_answer': question.expectedAnswer, 'correct': correct ? 1 : 0, 'created_at': DateTime.now().toUtc().toIso8601String(), 'sync_state': 'dirty'}); await txn.insert('sync_records', {'id': 'attempt:$id', 'entity_type': 'quiz_attempt', 'entity_id': id, 'operation': 'upsert', 'state': 'dirty', 'payload_json': jsonEncode({'id': id, 'conceptId': question.conceptId, 'correct': correct})}); }); }
  Future<int> pendingChanges() async => Sqflite.firstIntValue(await db.rawQuery("SELECT COUNT(*) FROM sync_records WHERE state IN ('dirty','error')")) ?? 0;
  Future<void> close() => db.close();
}

const _schema = <String>[
  'CREATE TABLE local_accounts (id TEXT PRIMARY KEY, email TEXT, updated_at TEXT NOT NULL)',
  'CREATE TABLE devices (id TEXT PRIMARY KEY, name TEXT NOT NULL, updated_at TEXT NOT NULL)',
  'CREATE TABLE subjects (id TEXT PRIMARY KEY, name TEXT NOT NULL, updated_at TEXT NOT NULL, deleted_at TEXT, revision INTEGER DEFAULT 0, sync_state TEXT NOT NULL)',
  'CREATE TABLE units (id TEXT PRIMARY KEY, subject_id TEXT NOT NULL, name TEXT NOT NULL, updated_at TEXT NOT NULL, deleted_at TEXT, sync_state TEXT NOT NULL)',
  'CREATE TABLE documents (id TEXT PRIMARY KEY, unit_id TEXT NOT NULL, title TEXT NOT NULL, original_mime TEXT NOT NULL, original_path TEXT NOT NULL, processing_state TEXT NOT NULL, user_confirmed INTEGER NOT NULL DEFAULT 0, updated_at TEXT NOT NULL, deleted_at TEXT, sync_state TEXT NOT NULL)',
  'CREATE TABLE document_pages (id TEXT PRIMARY KEY, document_id TEXT NOT NULL, page_number INTEGER NOT NULL, asset_path TEXT, analysis_json TEXT, user_confirmed INTEGER NOT NULL DEFAULT 0, updated_at TEXT NOT NULL, sync_state TEXT NOT NULL)',
  'CREATE TABLE study_notes (id TEXT PRIMARY KEY, document_id TEXT NOT NULL, markdown TEXT NOT NULL, user_confirmed INTEGER NOT NULL DEFAULT 0, updated_at TEXT NOT NULL, sync_state TEXT NOT NULL)',
  'CREATE TABLE concepts (id TEXT PRIMARY KEY, document_id TEXT NOT NULL, subject_id TEXT NOT NULL, unit_id TEXT NOT NULL, name TEXT NOT NULL, statement TEXT NOT NULL, explanation TEXT NOT NULL, confidence REAL NOT NULL, evidence_json TEXT NOT NULL, user_confirmed INTEGER NOT NULL, created_at TEXT NOT NULL, updated_at TEXT NOT NULL, deleted_at TEXT, sync_state TEXT NOT NULL)',
  'CREATE TABLE questions (id TEXT PRIMARY KEY, concept_id TEXT NOT NULL, prompt TEXT NOT NULL, expected_answer TEXT NOT NULL, type TEXT NOT NULL, variant_key TEXT NOT NULL, seed INTEGER NOT NULL, created_at TEXT NOT NULL, sync_state TEXT NOT NULL)',
  'CREATE TABLE quiz_attempts (id TEXT PRIMARY KEY, question_id TEXT NOT NULL, concept_id TEXT NOT NULL, submitted_answer TEXT NOT NULL, expected_answer TEXT NOT NULL, correct INTEGER NOT NULL, created_at TEXT NOT NULL, sync_state TEXT NOT NULL)',
  'CREATE TABLE concept_progress (concept_id TEXT PRIMARY KEY, attempts INTEGER NOT NULL, correct_attempts INTEGER NOT NULL, consecutive_correct INTEGER NOT NULL, consecutive_incorrect INTEGER NOT NULL, mastery REAL NOT NULL, last_reviewed_at TEXT, next_review_at TEXT, sync_state TEXT NOT NULL)',
  'CREATE TABLE bad_question_reports (id TEXT PRIMARY KEY, question_id TEXT NOT NULL, reason TEXT NOT NULL, details TEXT, created_at TEXT NOT NULL, sync_state TEXT NOT NULL)',
  'CREATE TABLE sync_records (id TEXT PRIMARY KEY, entity_type TEXT NOT NULL, entity_id TEXT NOT NULL, operation TEXT NOT NULL, state TEXT NOT NULL, payload_json TEXT NOT NULL)',
  'CREATE TABLE user_settings (id TEXT PRIMARY KEY, value_json TEXT NOT NULL, updated_at TEXT NOT NULL, sync_state TEXT NOT NULL)'
];
