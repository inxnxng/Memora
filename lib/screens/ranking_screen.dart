import 'package:flutter/material.dart';
import 'package:memora/models/user_model.dart';

class RankingScreen extends StatelessWidget {
  const RankingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 임시 데이터
    final List<AppUser> users = [
      AppUser(uid: '1', displayName: 'Alex', progress: 0.9),
      AppUser(uid: '2', displayName: 'Bella', progress: 0.8),
      AppUser(uid: '3', displayName: 'Inkyung', progress: 0.777),
    ];
    const myUid = '3'; // 내 uid를 '3'으로 가정

    return Scaffold(
      appBar: AppBar(title: const Text('글로벌 랭킹')),
      body: ListView.builder(
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          final isMe = user.uid == myUid;

          return Card(
            color: isMe ? Colors.blue.shade50 : null,
            child: ListTile(
              leading: Text(
                '${index + 1}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              title: Text(
                user.displayName,
                style: TextStyle(
                  fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              trailing: Text(
                '${(user.progress * 100).toStringAsFixed(1)}%',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          );
        },
      ),
    );
  }
}
