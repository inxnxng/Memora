class QuizQuestion {
  final String question;
  final List<String> options;
  final int answer; // 0-based index of the correct option

  QuizQuestion({
    required this.question,
    required this.options,
    required this.answer,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      question: json['question'] as String,
      options: List<String>.from(json['options'] as List),
      answer: json['answer'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {'question': question, 'options': options, 'answer': answer};
  }
}
