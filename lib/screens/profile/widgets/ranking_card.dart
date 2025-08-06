import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:memora/constants/app_strings.dart';
import 'package:memora/router/app_routes.dart';

class RankingCard extends StatelessWidget {
  final int? userRank;

  const RankingCard({super.key, this.userRank});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              AppStrings.rankingInfo,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(AppStrings.myCurrentRank,
                    style: TextStyle(fontSize: 16)),
                Text(
                  userRank != null && userRank! > 0
                      ? '$userRank위'
                      : AppStrings.noRank,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.push(AppRoutes.ranking),
              child: const Text(AppStrings.checkFullRanking),
            ),
          ],
        ),
      ),
    );
  }
}
