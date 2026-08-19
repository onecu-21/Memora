String normalizeAnswer(String value) => value.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
bool gradeAnswer(String submitted, String expected) => normalizeAnswer(submitted) == normalizeAnswer(expected);

class DuplicateGuard {
  DuplicateGuard({this.window = 8}); final int window; final Map<String, List<String>> _recent = {};
  bool accept(String conceptId, String prompt) { final normalized = normalizeAnswer(prompt); final list = _recent.putIfAbsent(conceptId, () => []); if (list.contains(normalized)) return false; list.add(normalized); if (list.length > window) list.removeAt(0); return true; }
}
