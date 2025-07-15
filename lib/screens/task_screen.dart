import 'package:flutter/material.dart';
import 'package:memora/models/task_model.dart';
import 'package:memora/providers/task_provider.dart';

import 'package:memora/screens/training_chat_screen.dart';
import 'package:memora/services/openai_service.dart';
import 'package:provider/provider.dart';

class TaskScreen extends StatelessWidget {
  final Task task;
  const TaskScreen({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final openAIService = OpenAIService();

    return Scaffold(
      appBar: AppBar(title: Text(task.title)),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.lightbulb_outline, size: 100, color: Colors.amber),
            const SizedBox(height: 24),
            Text(
              '오늘의 훈련',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Text(
              task.description,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge, // Smaller font size
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () async {
                if (await openAIService.isApiKeyAvailable()) {
                  if (!context.mounted) return; // Add this line
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TrainingChatScreen(
                        taskTitle: task.title,
                        taskDescription: task.description,
                        taskId: task.id,
                        taskProvider: taskProvider,
                      ),
                    ),
                  );
                } else {
                  if (!context.mounted) return; // Add this line
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('OpenAI API Key가 필요합니다.')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.blue,
              ),
              child: Text(
                task.isCompleted
                    ? '다시 훈련해보기'
                    : '훈련 시작!', // Conditional button text
                style: const TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
