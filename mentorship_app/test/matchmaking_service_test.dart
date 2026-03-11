import 'package:flutter_test/flutter_test.dart';
import 'package:mentorship_app/services/matchmaking_service.dart';

void main() {
  // calculateCosineSimilarity is a static method — no Firebase needed.
  group('MatchmakingService.calculateCosineSimilarity', () {
    test('identical vectors → score ≈ 1.0', () {
      final vec = [1.0, 2.0, 3.0];
      final score = MatchmakingService.calculateCosineSimilarity(vec, vec);
      expect(score, closeTo(1.0, 0.0001));
    });

    test('orthogonal vectors → score ≈ 0.0', () {
      final vecA = [1.0, 0.0, 0.0];
      final vecB = [0.0, 1.0, 0.0];
      final score = MatchmakingService.calculateCosineSimilarity(vecA, vecB);
      expect(score, closeTo(0.0, 0.0001));
    });

    test('opposite vectors → score ≈ -1.0', () {
      final vecA = [1.0, 2.0, 3.0];
      final vecB = [-1.0, -2.0, -3.0];
      final score = MatchmakingService.calculateCosineSimilarity(vecA, vecB);
      expect(score, closeTo(-1.0, 0.0001));
    });

    test('zero vector → returns 0.0 (no divide-by-zero crash)', () {
      final zero = [0.0, 0.0, 0.0];
      final vec = [1.0, 2.0, 3.0];
      expect(MatchmakingService.calculateCosineSimilarity(zero, vec), equals(0.0));
      expect(MatchmakingService.calculateCosineSimilarity(vec, zero), equals(0.0));
      expect(MatchmakingService.calculateCosineSimilarity(zero, zero), equals(0.0));
    });

    test('known vectors → correct dot-product-over-magnitude result', () {
      final vecA = [1.0, 0.0];
      final vecB = [1.0, 1.0];
      // cosine = 1 / (1 * sqrt(2)) ≈ 0.7071
      final score = MatchmakingService.calculateCosineSimilarity(vecA, vecB);
      expect(score, closeTo(0.7071, 0.001));
    });
  });
}
