import 'package:flutter/material.dart';
import 'package:memora/models/user_model.dart';
<<<<<<< HEAD
import 'package:memora/services/firebase_service.dart';
=======
>>>>>>> 82a6e4a (feat: Add Home, Notification, Notion Connect, Profile, Quiz, Ranking, Roadmap, and Task screens)

class RankingScreen extends StatelessWidget {
  const RankingScreen({super.key});

  @override
  Widget build(BuildContext context) {
<<<<<<< HEAD
    final firebaseService = FirebaseService();

    return Scaffold(
      appBar: AppBar(title: const Text('글로벌 랭킹')),
      body: FutureBuilder<List<AppUser>>(
        future: firebaseService.getRanking(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('랭킹 데이터가 없습니다.'));
          }

          final users = snapshot.data!;
          final myUid = firebaseService.currentUser?.uid;

          return ListView.builder(
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
=======
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
>>>>>>> 82a6e4a (feat: Add Home, Notification, Notion Connect, Profile, Quiz, Ranking, Roadmap, and Task screens)
          );
        },
      ),
    );
  }
}
