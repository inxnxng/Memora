import 'package:flutter/material.dart';

/// 랭킹 점수에 따른 티어. 게이미피케이션용.
enum RankingTier { bronze, silver, gold, platinum, diamond }

extension RankingTierExtension on RankingTier {
  /// 티어 최소 점수 (이 점수 이상이면 해당 티어)
  int get minScore {
    switch (this) {
      case RankingTier.bronze:
        return 0;
      case RankingTier.silver:
        return 100;
      case RankingTier.gold:
        return 500;
      case RankingTier.platinum:
        return 1500;
      case RankingTier.diamond:
        return 4000;
    }
  }

  String get displayName {
    switch (this) {
      case RankingTier.bronze:
        return '브론즈';
      case RankingTier.silver:
        return '실버';
      case RankingTier.gold:
        return '골드';
      case RankingTier.platinum:
        return '플래티넘';
      case RankingTier.diamond:
        return '다이아몬드';
    }
  }

  IconData get icon {
    switch (this) {
      case RankingTier.bronze:
        return Icons.lens;
      case RankingTier.silver:
        return Icons.lens;
      case RankingTier.gold:
        return Icons.star;
      case RankingTier.platinum:
        return Icons.workspace_premium;
      case RankingTier.diamond:
        return Icons.diamond;
    }
  }

  Color color(BuildContext context) {
    switch (this) {
      case RankingTier.bronze:
        return const Color(0xFFCD7F32);
      case RankingTier.silver:
        return const Color(0xFFC0C0C0);
      case RankingTier.gold:
        return const Color(0xFFFFD700);
      case RankingTier.platinum:
        return const Color(0xFFE5E4E2);
      case RankingTier.diamond:
        return const Color(0xFFB9F2FF);
    }
  }
}

/// 점수로 티어 계산
RankingTier tierFromScore(int score) {
  if (score >= RankingTier.diamond.minScore) return RankingTier.diamond;
  if (score >= RankingTier.platinum.minScore) return RankingTier.platinum;
  if (score >= RankingTier.gold.minScore) return RankingTier.gold;
  if (score >= RankingTier.silver.minScore) return RankingTier.silver;
  return RankingTier.bronze;
}

/// 다음 티어까지 남은 점수 (이미 최고 티어면 null)
int? scoreToNextTier(int score) {
  final current = tierFromScore(score);
  final tiers = RankingTier.values;
  final idx = tiers.indexOf(current);
  if (idx >= tiers.length - 1) return null;
  final next = tiers[idx + 1];
  return next.minScore - score;
}

/// 현재 티어 구간에서의 진행률 0.0 ~ 1.0 (다음 티어까지)
double progressInCurrentTier(int score) {
  final current = tierFromScore(score);
  final tiers = RankingTier.values;
  final idx = tiers.indexOf(current);
  final currentMin = current.minScore;
  if (idx >= tiers.length - 1) return 1.0;
  final nextMin = tiers[idx + 1].minScore;
  final range = nextMin - currentMin;
  if (range <= 0) return 1.0;
  return ((score - currentMin) / range).clamp(0.0, 1.0);
}
