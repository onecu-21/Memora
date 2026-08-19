import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../core/models.dart';

enum AIProviderId { gemini, openAI, anthropic, mock }
class AIProviderCapabilities { const AIProviderCapabilities({required this.text, required this.vision, required this.imageInput, required this.pdfInput, required this.structuredOutput}); final bool text, vision, imageInput, pdfInput, structuredOutput; }
class ProviderModelConfig { const ProviderModelConfig({required this.documentAnalysis, required this.classification, required this.studyNotes, required this.conceptExtraction, required this.quizGeneration}); final String documentAnalysis, classification, studyNotes, conceptExtraction, quizGeneration; }
class AnalyzeDocumentInput { const AnalyzeDocumentInput({required this.documentId, required this.bytes, required this.mimeType}); final String documentId, mimeType; final Uint8List bytes; }
class DocumentAnalysisResult { const DocumentAnalysisResult(this.pages); final List<PageAnalysis> pages; }
class DocumentClassification { const DocumentClassification(this.subject, this.unit); final String subject, unit; }
class GeneratedStudyNotes { const GeneratedStudyNotes(this.markdown); final String markdown; }

sealed class AIException implements Exception { const AIException(this.message); final String message; @override String toString() => message; }
final class AIAuthenticationException extends AIException { const AIAuthenticationException(super.message); }
final class AIRateLimitException extends AIException { const AIRateLimitException(super.message); }
final class AIInvalidResponseException extends AIException { const AIInvalidResponseException(super.message); }
final class AIProviderUnavailableException extends AIException { const AIProviderUnavailableException(super.message); }
final class AIUnsupportedInputException extends AIException { const AIUnsupportedInputException(super.message); }

abstract interface class StudyAIProvider {
  AIProviderId get id; AIProviderCapabilities get capabilities;
  Future<DocumentAnalysisResult> analyzeDocument(AnalyzeDocumentInput input);
  Future<DocumentClassification> classifyDocument(DocumentAnalysisResult input);
  Future<GeneratedStudyNotes> generateStudyNotes(DocumentAnalysisResult input);
  Future<List<Concept>> extractConcepts(DocumentAnalysisResult input, {required String documentId, required String subjectId, required String unitId});
  Future<GeneratedQuestion> generateQuestion(Concept concept, {required int seed});
}

class ProviderRegistry {
  ProviderRegistry(Iterable<StudyAIProvider> providers) : _providers = {for (final p in providers) p.id: p}; final Map<AIProviderId, StudyAIProvider> _providers;
  StudyAIProvider get(AIProviderId id) => _providers[id] ?? (throw StateError('Provider not registered: $id'));
}

abstract class JsonHttpProvider implements StudyAIProvider {
  JsonHttpProvider({required this.apiKey, required this.models, http.Client? client}) : client = client ?? http.Client();
  final String apiKey; final ProviderModelConfig models; final http.Client client;
  Never unsupported() => throw const AIUnsupportedInputException('Configure this provider to perform a network request');
  @override Future<DocumentAnalysisResult> analyzeDocument(AnalyzeDocumentInput input) async => unsupported();
  @override Future<DocumentClassification> classifyDocument(DocumentAnalysisResult input) async => unsupported();
  @override Future<GeneratedStudyNotes> generateStudyNotes(DocumentAnalysisResult input) async => unsupported();
  @override Future<List<Concept>> extractConcepts(DocumentAnalysisResult input, {required String documentId, required String subjectId, required String unitId}) async => unsupported();
  @override Future<GeneratedQuestion> generateQuestion(Concept concept, {required int seed}) async => unsupported();
  Map<String, dynamic> decodeObject(String raw) { try { final value = jsonDecode(raw); if (value is! Map<String, dynamic>) throw const FormatException(); return value; } catch (_) { throw const AIInvalidResponseException('The AI returned malformed structured data.'); } }
}

class GeminiProvider extends JsonHttpProvider { GeminiProvider({required super.apiKey, required super.models, super.client}); @override AIProviderId get id => AIProviderId.gemini; @override AIProviderCapabilities get capabilities => const AIProviderCapabilities(text: true, vision: true, imageInput: true, pdfInput: true, structuredOutput: true); }
class OpenAIProvider extends JsonHttpProvider { OpenAIProvider({required super.apiKey, required super.models, super.client}); @override AIProviderId get id => AIProviderId.openAI; @override AIProviderCapabilities get capabilities => const AIProviderCapabilities(text: true, vision: true, imageInput: true, pdfInput: true, structuredOutput: true); }
class AnthropicProvider extends JsonHttpProvider { AnthropicProvider({required super.apiKey, required super.models, super.client}); @override AIProviderId get id => AIProviderId.anthropic; @override AIProviderCapabilities get capabilities => const AIProviderCapabilities(text: true, vision: true, imageInput: true, pdfInput: true, structuredOutput: true); }

class MockAIProvider implements StudyAIProvider {
  @override AIProviderId get id => AIProviderId.mock;
  @override AIProviderCapabilities get capabilities => const AIProviderCapabilities(text: true, vision: true, imageInput: true, pdfInput: true, structuredOutput: true);
  @override Future<DocumentAnalysisResult> analyzeDocument(AnalyzeDocumentInput input) async => const DocumentAnalysisResult([PageAnalysis(printedText: 'Democracy gives citizens a role in government. Direct democracy involves citizens directly; representative democracy uses elected representatives.', handwriting: [HandwritingFragment(text: 'Remember: power comes from the people', confidence: .94)], highlights: [Annotation(type: AnnotationType.highlight, text: 'citizens', confidence: .91)])]);
  @override Future<DocumentClassification> classifyDocument(DocumentAnalysisResult input) async => const DocumentClassification('Social Studies', 'Democracy');
  @override Future<GeneratedStudyNotes> generateStudyNotes(DocumentAnalysisResult input) async => const GeneratedStudyNotes('# Democracy\n\n## Core concepts\n\nCitizens participate directly or elect representatives.\n\n## Handwritten / emphasized points\n\n- Power comes from the people.\n\n## Things worth memorizing\n\n- Direct and representative democracy differ in how citizens participate.\n\n## Three-line summary\n\n1. Democracy involves citizens.\n2. Participation can be direct.\n3. Representatives can be elected.');
  @override Future<List<Concept>> extractConcepts(DocumentAnalysisResult input, {required String documentId, required String subjectId, required String unitId}) async { final now = DateTime.utc(2025); final facts = ['Direct democracy means citizens participate directly in political decisions.', 'Representative democracy means citizens elect representatives.', 'Popular sovereignty means political power comes from the people.', 'Elections allow citizens to select representatives.', 'Civic participation is citizen involvement in public decisions.', 'Majority rule decides by the greater number of votes.', 'Minority rights protect groups outside the majority.', 'Rule of law means laws apply to leaders and citizens.']; return [for (var i = 0; i < facts.length; i++) Concept(id: 'mock-$i', documentId: documentId, subjectId: subjectId, unitId: unitId, name: facts[i].split(' means').first, statement: facts[i], explanation: facts[i], confidence: .95, sourceEvidence: [SourceEvidence(documentId: documentId, pageNumber: 1, sourceType: i == 2 ? SourceType.handwriting : SourceType.printedText, text: facts[i], confidence: .9)], createdAt: now, updatedAt: now)]; }
  @override Future<GeneratedQuestion> generateQuestion(Concept concept, {required int seed}) async { final type = QuestionType.values[seed.abs() % 3]; return GeneratedQuestion(id: '${concept.id}-$seed', conceptId: concept.id, prompt: type == QuestionType.fillBlank ? '${concept.name} means ____.' : 'What best describes ${concept.name}?', expectedAnswer: concept.statement, explanation: concept.explanation, type: type, variantKey: '${type.name}-${seed % 4}', generationSeed: seed, choices: type == QuestionType.multipleChoice ? [concept.statement, 'None of the source-grounded statements'] : const []); }
}
