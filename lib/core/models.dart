import 'dart:convert';

enum SyncState { localOnly, dirty, syncing, synced, conflict, error }
enum ProcessingState { uploaded, stored, pageExtraction, documentAnalysis, classification, noteGeneration, conceptExtraction, ready, failed }
enum SourceType { printedText, handwriting, annotation, visual }
enum AnnotationType { highlight, underline, circle, arrow, other }
enum QuestionType { multipleChoice, shortAnswer, fillBlank }

class BoundingBox {
  const BoundingBox(this.x, this.y, this.width, this.height);
  final double x, y, width, height;
  Map<String, dynamic> toJson() => {'x': x, 'y': y, 'width': width, 'height': height};
  factory BoundingBox.fromJson(Map<String, dynamic> j) => BoundingBox(_number(j, 'x'), _number(j, 'y'), _number(j, 'width'), _number(j, 'height'));
}

class Annotation {
  const Annotation({required this.type, this.text, required this.confidence, this.region});
  final AnnotationType type; final String? text; final double confidence; final BoundingBox? region;
}
class HandwritingFragment {
  const HandwritingFragment({required this.text, required this.confidence, this.region});
  final String text; final double confidence; final BoundingBox? region;
}
class UncertainRegion {
  const UncertainRegion({required this.description, required this.confidence, this.region});
  final String description; final double confidence; final BoundingBox? region;
}
class PageAnalysis {
  const PageAnalysis({required this.printedText, this.handwriting = const [], this.highlights = const [], this.underlines = const [], this.circles = const [], this.arrows = const [], this.uncertainRegions = const [], this.userConfirmed = false});
  final String printedText; final List<HandwritingFragment> handwriting; final List<Annotation> highlights, underlines, circles, arrows; final List<UncertainRegion> uncertainRegions; final bool userConfirmed;
  factory PageAnalysis.fromJson(Map<String, dynamic> j) {
    if (j['printedText'] is! String) throw const FormatException('printedText is required');
    List<Annotation> annotations(String key, AnnotationType expected) => _maps(j[key]).map((a) {
      final confidence = _number(a, 'confidence');
      if (confidence < 0 || confidence > 1) throw const FormatException('Invalid confidence');
      return Annotation(type: expected, text: a['text'] as String?, confidence: confidence, region: _box(a['region']));
    }).toList();
    return PageAnalysis(printedText: j['printedText'] as String, handwriting: _maps(j['handwriting']).map((h) => HandwritingFragment(text: _string(h, 'text'), confidence: _number(h, 'confidence'), region: _box(h['region']))).toList(), highlights: annotations('highlights', AnnotationType.highlight), underlines: annotations('underlines', AnnotationType.underline), circles: annotations('circles', AnnotationType.circle), arrows: annotations('arrows', AnnotationType.arrow), uncertainRegions: _maps(j['uncertainRegions']).map((u) => UncertainRegion(description: _string(u, 'description'), confidence: _number(u, 'confidence'), region: _box(u['region']))).toList(), userConfirmed: j['userConfirmed'] == true);
  }
}

class SourceEvidence {
  const SourceEvidence({required this.documentId, required this.pageNumber, required this.sourceType, this.text, this.region, required this.confidence});
  final String documentId; final int pageNumber; final SourceType sourceType; final String? text; final BoundingBox? region; final double confidence;
  Map<String, dynamic> toJson() => {'documentId': documentId, 'pageNumber': pageNumber, 'sourceType': sourceType.name, 'text': text, 'region': region?.toJson(), 'confidence': confidence};
  factory SourceEvidence.fromJson(Map<String, dynamic> j) => SourceEvidence(documentId: _string(j, 'documentId'), pageNumber: (j['pageNumber'] as num).toInt(), sourceType: SourceType.values.byName(_string(j, 'sourceType')), text: j['text'] as String?, region: _box(j['region']), confidence: _number(j, 'confidence'));
}

class Concept {
  const Concept({required this.id, required this.documentId, required this.subjectId, required this.unitId, required this.name, required this.statement, required this.explanation, required this.confidence, required this.sourceEvidence, this.userConfirmed = false, required this.createdAt, required this.updatedAt, this.deletedAt, this.syncRevision = 0, this.syncState = SyncState.localOnly, this.lastSyncedAt});
  final String id, documentId, subjectId, unitId, name, statement, explanation; final double confidence; final List<SourceEvidence> sourceEvidence; final bool userConfirmed; final DateTime createdAt, updatedAt; final DateTime? deletedAt, lastSyncedAt; final int syncRevision; final SyncState syncState;
  Concept mergeAnalysis(Concept incoming) => userConfirmed ? this : incoming;
  Map<String, dynamic> toJson() => {'id': id, 'documentId': documentId, 'subjectId': subjectId, 'unitId': unitId, 'name': name, 'statement': statement, 'explanation': explanation, 'confidence': confidence, 'sourceEvidence': sourceEvidence.map((e) => e.toJson()).toList(), 'userConfirmed': userConfirmed, 'createdAt': createdAt.toUtc().toIso8601String(), 'updatedAt': updatedAt.toUtc().toIso8601String(), 'deletedAt': deletedAt?.toUtc().toIso8601String(), 'syncRevision': syncRevision, 'syncState': syncState.name, 'lastSyncedAt': lastSyncedAt?.toUtc().toIso8601String()};
  factory Concept.fromJson(Map<String, dynamic> j) => Concept(id: _string(j, 'id'), documentId: _string(j, 'documentId'), subjectId: _string(j, 'subjectId'), unitId: _string(j, 'unitId'), name: _string(j, 'name'), statement: _string(j, 'statement'), explanation: _string(j, 'explanation'), confidence: _number(j, 'confidence'), sourceEvidence: _maps(j['sourceEvidence']).map(SourceEvidence.fromJson).toList(), userConfirmed: j['userConfirmed'] == true, createdAt: DateTime.parse(_string(j, 'createdAt')), updatedAt: DateTime.parse(_string(j, 'updatedAt')), deletedAt: _date(j['deletedAt']), syncRevision: (j['syncRevision'] as num?)?.toInt() ?? 0, syncState: SyncState.values.byName(j['syncState'] as String? ?? 'localOnly'), lastSyncedAt: _date(j['lastSyncedAt']));
}

class GeneratedQuestion {
  const GeneratedQuestion({required this.id, required this.conceptId, required this.prompt, required this.expectedAnswer, required this.explanation, required this.type, required this.variantKey, required this.generationSeed, this.choices = const []});
  final String id, conceptId, prompt, expectedAnswer, explanation, variantKey; final int generationSeed; final QuestionType type; final List<String> choices;
  factory GeneratedQuestion.fromJson(Map<String, dynamic> j) {
    final type = QuestionType.values.byName(_string(j, 'type'));
    final choices = (j['choices'] as List? ?? const []).map((e) => e as String).toList();
    if (type == QuestionType.multipleChoice && choices.length < 2) throw const FormatException('Multiple choice needs choices');
    return GeneratedQuestion(id: _string(j, 'id'), conceptId: _string(j, 'conceptId'), prompt: _string(j, 'prompt'), expectedAnswer: _string(j, 'expectedAnswer'), explanation: _string(j, 'explanation'), type: type, variantKey: _string(j, 'variantKey'), generationSeed: (j['generationSeed'] as num).toInt(), choices: choices);
  }
}

double _number(Map<String, dynamic> j, String key) { final v = j[key]; if (v is! num) throw FormatException('$key must be numeric'); return v.toDouble(); }
String _string(Map<String, dynamic> j, String key) { final v = j[key]; if (v is! String || v.trim().isEmpty) throw FormatException('$key is required'); return v; }
List<Map<String, dynamic>> _maps(Object? v) { if (v == null) return []; if (v is! List) throw const FormatException('Expected list'); return v.map((e) { if (e is! Map) throw const FormatException('Expected object'); return Map<String, dynamic>.from(e); }).toList(); }
BoundingBox? _box(Object? v) => v == null ? null : BoundingBox.fromJson(Map<String, dynamic>.from(v as Map));
DateTime? _date(Object? v) => v == null ? null : DateTime.parse(v as String);
String encodeEvidence(List<SourceEvidence> value) => jsonEncode(value.map((e) => e.toJson()).toList());
