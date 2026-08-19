class ConceptProgress {
  const ConceptProgress({required this.conceptId, this.attempts = 0, this.correctAttempts = 0, this.consecutiveCorrect = 0, this.consecutiveIncorrect = 0, this.masteryScore = 0, this.lastReviewedAt, this.nextReviewAt});
  final String conceptId; final int attempts, correctAttempts, consecutiveCorrect, consecutiveIncorrect; final double masteryScore; final DateTime? lastReviewedAt, nextReviewAt;
}

ConceptProgress calculateMastery({required ConceptProgress progress, required bool correct, required DateTime now}) {
  final streak = correct ? progress.consecutiveCorrect + 1 : 0;
  final wrongStreak = correct ? 0 : progress.consecutiveIncorrect + 1;
  final delta = correct ? 0.14 + (streak >= 3 ? 0.05 : 0) : -(0.20 + wrongStreak * 0.04);
  final mastery = (progress.masteryScore + delta).clamp(0.0, 1.0).toDouble();
  final delay = correct ? (streak >= 5 ? const Duration(days: 14) : streak >= 3 ? const Duration(days: 4) : Duration(hours: 8 * streak)) : Duration(minutes: wrongStreak >= 2 ? 5 : 15);
  return ConceptProgress(conceptId: progress.conceptId, attempts: progress.attempts + 1, correctAttempts: progress.correctAttempts + (correct ? 1 : 0), consecutiveCorrect: streak, consecutiveIncorrect: wrongStreak, masteryScore: mastery, lastReviewedAt: now, nextReviewAt: now.add(delay));
}

ConceptProgress? selectNextConcept({required List<ConceptProgress> concepts, required DateTime now}) {
  if (concepts.isEmpty) return null;
  final ordered = [...concepts]..sort((a, b) {
    double priority(ConceptProgress p) { final due = p.nextReviewAt == null || !p.nextReviewAt!.isAfter(now); return (due ? 10 : 0) + (1 - p.masteryScore) * 5 + p.consecutiveIncorrect * 2 - p.consecutiveCorrect * .2; }
    final score = priority(b).compareTo(priority(a));
    return score != 0 ? score : a.conceptId.compareTo(b.conceptId);
  });
  return ordered.first;
}
