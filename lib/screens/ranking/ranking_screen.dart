import 'package:flutter/material.dart';
import 'package:memora/providers/user_provider.dart';
import 'package:memora/widgets/common_app_bar.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

class RankingScreen extends StatefulWidget {
  const RankingScreen({super.key});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  late Stream<List<Map<String, dynamic>>> _rankingStream;

  @override
  void initState() {
    super.initState();
    _rankingStream = Provider.of<UserProvider>(
      context,
      listen: false,
    ).getTopRankings();
  }

  /// 공유 기능을 처리하는 메소드
  void _shareRanking(int? rank, int streak) {
    String message;
    if (rank != null && rank > 0) {
      message = "Memora에서 $streak일 연속 학습 중! 현재 $rank위입니다. 저를 이겨보세요! 🔥";
    } else {
      message = "Memora에서 $streak일 연속 학습하며 꾸준함을 실천하고 있어요. 함께해요!";
    }
    SharePlus.instance.share(
      ShareParams(text: message, subject: 'Memora 랭킹 공유'),
    );
  }

  String _maskDisplayName(String? name) {
    if (name == null || name.isEmpty) {
      return '이름 없음';
    }
    final koreanRegex = RegExp(r'[ㄱ-ㅎ|ㅏ-ㅣ|가-힣]');

    if (koreanRegex.hasMatch(name)) {
      return name[0] + '*' * (name.length - 1);
    } else {
      if (name.length <= 2) {
        return name;
      }
      return name.substring(0, 2) + '*' * (name.length - 2);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final myRank = userProvider.userRank;
    final myStreak = userProvider.streakCount;
    final myDisplayName = userProvider.displayName;

    return Scaffold(
      appBar: const CommonAppBar(title: '전체 랭킹'),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _rankingStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('랭킹을 불러오는 데 실패했습니다.'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('랭킹 정보가 없습니다.'));
          }

          final rankings = snapshot.data!;

          return Column(
            children: [
              // 현재 내 랭킹 정보 카드
              _buildMyRankingCard(myRank, myStreak, myDisplayName),
              const Divider(height: 1),
              // 전체 랭킹 목록
              Expanded(
                child: ListView.builder(
                  itemCount: rankings.length,
                  itemBuilder: (context, index) {
                    final user = rankings[index];
                    final rank = index + 1;
                    final isMe = user['displayName'] == myDisplayName;
                    final displayName = user['displayName'] ?? '이름 없음';

                    return ListTile(
                      leading: Text(
                        '$rank',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isMe
                              ? Theme.of(context).primaryColor
                              : Colors.grey,
                        ),
                      ),
                      title: Text(
                        _maskDisplayName(displayName),
                        style: TextStyle(
                          fontWeight: isMe
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      trailing: Text(
                        '${user['streakCount'] ?? 0}일 연속',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      tileColor: isMe
                          ? Theme.of(
                              context,
                            ).primaryColor.withAlpha((255 * 0.1).round())
                          : null,
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _shareRanking(myRank, myStreak),
        tooltip: '공유하기',
        child: const Icon(Icons.share),
      ),
    );
  }

  /// 현재 사용자의 랭킹 정보를 보여주는 카드 위젯
  Widget _buildMyRankingCard(int? rank, int streak, String? displayName) {
    return Card(
      margin: const EdgeInsets.all(12.0),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(
              children: [
                const Text(
                  '내 순위',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  rank != null && rank > 0 ? '$rank위' : 'N/A',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
            Column(
              children: [
                const Text(
                  '내 스트릭',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  '$streak일',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
