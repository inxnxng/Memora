import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:memora/constants/app_strings.dart';
import 'package:memora/models/ranking_tier.dart';
import 'package:memora/router/app_routes.dart';

class RankingCard extends StatelessWidget {
  final int? userRank;
  final int rankingScore;

  const RankingCard({super.key, this.userRank, this.rankingScore = 0});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tier = tierFromScore(rankingScore);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: theme.colorScheme.surfaceContainerLow,
      child: InkWell(
        onTap: () => context.push(AppRoutes.ranking),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: tier.color(context).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(tier.icon, size: 28, color: tier.color(context)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.myCurrentRank,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (userRank != null && userRank! > 0)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Text(
                              '$userRank위',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: tier.color(context).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            tier.displayName,
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: tier.color(context),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$rankingScore${AppStrings.points}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                AppStrings.checkFullRanking,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, color: theme.colorScheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}
