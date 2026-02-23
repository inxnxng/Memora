import 'package:flutter/material.dart';

enum ProficiencyLevel {
  beginner,
  intermediate,
  advanced;

  String get displayName {
    switch (this) {
      case ProficiencyLevel.beginner:
        return '초급';
      case ProficiencyLevel.intermediate:
        return '중급';
      case ProficiencyLevel.advanced:
        return '고급';
    }
  }

  String get description {
    switch (this) {
      case ProficiencyLevel.beginner:
        return '이제 막 훈련을 시작하는 단계입니다. 부담 없이 시작해 보세요!';
      case ProficiencyLevel.intermediate:
        return '훈련에 익숙해지고, 더 높은 목표를 향해 나아가는 단계입니다.';
      case ProficiencyLevel.advanced:
        return '훈련에 익숙한 단계입니다. 꾸준한 노력으로 기억력을 유지하세요.';
    }
  }

  /// 숙련도 선택 시 팝업에 표시할 기준 설명
  String get criteriaDescription {
    switch (this) {
      case ProficiencyLevel.beginner:
        return '• 하루 목표: 3회 학습\n'
            '• 복습을 막 시작한 단계\n'
            '• 부담 없이 습관을 만드는 단계';
      case ProficiencyLevel.intermediate:
        return '• 하루 목표: 5회 학습\n'
            '• 꾸준히 복습하는 단계\n'
            '• 조금씩 목표를 높여가는 단계';
      case ProficiencyLevel.advanced:
        return '• 하루 목표: 7회 학습\n'
            '• 꾸준히 훈련해 온 단계\n'
            '• 최고의 기억력 유지를 위한 단계';
    }
  }

  int get dailyGoal {
    switch (this) {
      case ProficiencyLevel.beginner:
        return 3;
      case ProficiencyLevel.intermediate:
        return 5;
      case ProficiencyLevel.advanced:
        return 7;
    }
  }

  IconData get icon {
    switch (this) {
      case ProficiencyLevel.beginner:
        return Icons.spa_outlined;
      case ProficiencyLevel.intermediate:
        return Icons.eco_outlined;
      case ProficiencyLevel.advanced:
        return Icons.workspace_premium_outlined;
    }
  }

  static ProficiencyLevel? fromString(String? levelString) {
    if (levelString == null) return null;
    for (var level in ProficiencyLevel.values) {
      if (level.name == levelString) {
        return level;
      }
    }
    return null;
  }

  // get all levels as a string list
  static List<String> get allLevels =>
      ProficiencyLevel.values.map((level) => level.name).toList();
}
