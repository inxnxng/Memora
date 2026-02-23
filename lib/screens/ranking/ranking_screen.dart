import 'package:flutter/material.dart';
import 'package:memora/constants/app_strings.dart';
import 'package:memora/models/ranking_tier.dart';
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
  int? _displayedRank;

  @override
  void initState() {
    super.initState();
    _rankingStream = Provider.of<UserProvider>(
      context,
      listen: false,
    ).getTopRankings();
  }

  void _shareRanking(int? rank, int score, String tierName) {
    String message;
    if (rank != null && rank > 0) {
      message =
          'Memora 랭킹에서 $tierName $score pt로 $rank위! 함께 도전해요 🔥';
    } else {
      message = 'Memora에서 꾸준히 학습 중이에요. 나도 도전할래요?';
    }
    SharePlus.instance.share(
      ShareParams(text: message, subject: AppStrings.shareRanking),
    );
  }

  String _maskDisplayName(String? name) {
    if (name == null || name.isEmpty) return AppStrings.noName;
    final koreanRegex = RegExp(r'[ㄱ-ㅎ|ㅏ-ㅣ|가-힣]');
    if (koreanRegex.hasMatch(name)) {
      return name[0] + '*' * (name.length - 1);
    }
    if (name.length <= 2) return name;
    return name.substring(0, 2) + '*' * (name.length - 2);
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final myScore = userProvider.rankingScore;
    final myUserId = userProvider.userId;
    final myTier = tierFromScore(myScore);
    int? myRank;

    return Scaffold(
      appBar: const CommonAppBar(title: AppStrings.rankingTitle),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _rankingStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    AppStrings.rankLoadFailed,
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.emoji_events_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppStrings.noRankingData,
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppStrings.studyMoreToRank,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final rankings = snapshot.data!;
          final myRankIndex =
              rankings.indexWhere((user) => user['id'] == myUserId);
          myRank = myRankIndex != -1 ? myRankIndex + 1 : null;
          _displayedRank = myRank;

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _buildMyRankingCard(
                  rank: myRank,
                  score: myScore,
                  tier: myTier,
                  streak: userProvider.streakCount,
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Row(
                    children: [
                      Text(
                        '전체 순위',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final user = rankings[index];
                    final rank = index + 1;
                    final isMe = user['id'] == myUserId;
                    final score = (user['rankingScore'] as num?)?.toInt() ?? 0;
                    final tier = tierFromScore(score);
                    final displayName =
                        user['displayName'] ?? AppStrings.noName;

                    return _RankingListItem(
                      rank: rank,
                      displayName: isMe ? (user['displayName'] ?? '나') : _maskDisplayName(displayName),
                      score: score,
                      tier: tier,
                      streak: (user['streakCount'] as num?)?.toInt() ?? 0,
                      isMe: isMe,
                    );
                  },
                  childCount: rankings.length,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _shareRanking(
          _displayedRank ?? context.read<UserProvider>().userRank,
          myScore,
          myTier.displayName,
        ),
        icon: const Icon(Icons.share),
        label: const Text(AppStrings.shareRanking),
      ),
    );
  }

  Widget _buildMyRankingCard({
    required int? rank,
    required int score,
    required RankingTier tier,
    required int streak,
  }) {
    final theme = Theme.of(context);
    final progress = progressInCurrentTier(score);
    final toNext = scoreToNextTier(score);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        color: theme.colorScheme.surfaceContainerHigh,
        child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: tier.color(context).withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: tier.color(context).withValues(alpha: 0.6),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              tier.icon,
                              size: 18,
                              color: tier.color(context),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              tier.displayName,
                              style: theme.textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: tier.color(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      if (rank != null && rank > 0)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$rank',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            Text(
                              '위',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        )
                      else
                        Text(
                          AppStrings.noRank,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '$score',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        AppStrings.points,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.local_fire_department,
                        size: 20,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$streak${AppStrings.streakDays}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  if (toNext != null && toNext > 0) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 8,
                              backgroundColor: theme
                                  .colorScheme.surfaceContainerHighest
                                  .withValues(alpha: 0.5),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                tier.color(context),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${AppStrings.nextTier} $toNext${AppStrings.points}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
        ),
      ),
    );
  }
}


class _RankingListItem extends StatelessWidget {
  final int rank;
  final String displayName;
  final int score;
  final RankingTier tier;
  final int streak;
  final bool isMe;

  const _RankingListItem({
    required this.rank,
    required this.displayName,
    required this.score,
    required this.tier,
    required this.streak,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rankColor = rank <= 3
        ? (rank == 1
            ? const Color(0xFFFFD700)
            : rank == 2
                ? const Color(0xFFC0C0C0)
                : const Color(0xFFCD7F32))
        : theme.colorScheme.onSurfaceVariant;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isMe
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.4)
            : theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: isMe
            ? Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.5),
                width: 1.5,
              )
            : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: SizedBox(
          width: 36,
          child: Text(
            '$rank',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: rankColor,
            ),
          ),
        ),
        title: Row(
          children: [
            Icon(
              tier.icon,
              size: 16,
              color: tier.color(context),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                displayName,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: isMe ? FontWeight.bold : FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '$score${AppStrings.points}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            if (streak > 0)
              Text(
                '$streak${AppStrings.streakDays}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
