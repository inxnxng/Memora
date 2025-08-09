import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:memora/constants/app_strings.dart';
import 'package:memora/models/notion_route_extra.dart';
import 'package:memora/providers/notion_provider.dart';
import 'package:memora/router/app_routes.dart';
import 'package:memora/widgets/common_app_bar.dart';
import 'package:provider/provider.dart';

class ReviewSelectionScreen extends StatefulWidget {
  const ReviewSelectionScreen({super.key});

  @override
  State<ReviewSelectionScreen> createState() => _ReviewSelectionScreenState();
}

class _ReviewSelectionScreenState extends State<ReviewSelectionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<NotionProvider>();
      provider.fetchNotionPages();
      provider.clearPageSelection(); // Clear previous selections
    });
  }

  Future<void> _startCombinedTraining() async {
    final notionProvider = context.read<NotionProvider>();
    final success = await notionProvider.fetchCombinedContent();

    if (success && mounted) {
      final extra = NotionRouteExtra(
        pages: notionProvider.combinedPageContent,
        databaseName: notionProvider.databaseTitle,
      );
      context.push(AppRoutes.chat, extra: extra);
    } else if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            notionProvider.notionConnectionError ??
                AppStrings.pageContentLoadFailed,
          ),
        ),
      );
    }
  }

  void _navigateToPageViewer(
    BuildContext context,
    String pageId,
    String pageTitle,
  ) {
    final notionProvider = context.read<NotionProvider>();
    final databaseName = notionProvider.databaseTitle;

    final extra = NotionRouteExtra(
      databaseName: databaseName,
      pageId: pageId,
      pageTitle: pageTitle,
    );
    context.push('${AppRoutes.review}/${AppRoutes.notionPage}', extra: extra);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notionProvider = context.watch<NotionProvider>();

    return Scaffold(
      appBar: CommonAppBar(
        title: AppStrings.tilReviewSelectionTitle,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () =>
                context.push("${AppRoutes.review}/${AppRoutes.chatHistory}"),
            tooltip: '채팅 기록',
          ),
        ],
      ),
      body: Stack(
        children: [
          if (notionProvider.arePagesLoading && notionProvider.pages.isEmpty)
            const Center(child: CircularProgressIndicator())
          else if (notionProvider.pages.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  AppStrings.noNotionPagesFound,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            ListView.builder(
              itemCount: notionProvider.pages.length,
              itemBuilder: (context, index) {
                final page = notionProvider.pages[index];
                final pageId = page.id;
                final isSelected = notionProvider.selectedPageIds.contains(
                  pageId,
                );
                final title = page.title;
                final emoji = '📄';

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  elevation: isSelected ? 2 : 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: ListTile(
                    contentPadding: const EdgeInsets.only(
                      left: 8,
                      right: 16,
                      top: 4,
                      bottom: 4,
                    ),
                    onTap: () => _navigateToPageViewer(context, pageId, title),
                    selected: isSelected,
                    selectedTileColor: theme.primaryColor.withAlpha(20),
                    leading: Checkbox(
                      value: isSelected,
                      onChanged: (bool? value) {
                        notionProvider.togglePageSelection(pageId);
                      },
                      activeColor: theme.primaryColor,
                    ),
                    title: Row(
                      children: [
                        Text(emoji, style: const TextStyle(fontSize: 24)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(fontSize: 16),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          if (notionProvider.isFetchingCombinedContent)
            Container(
              color: Colors.black.withAlpha(128),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      AppStrings.loadingPageContent,
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton:
          notionProvider.selectedPageIds.isNotEmpty &&
              !notionProvider.isFetchingCombinedContent
          ? FloatingActionButton.extended(
              onPressed: _startCombinedTraining,
              label: const Text(AppStrings.startTraining),
              icon: const Icon(Icons.chat_bubble_outline),
            )
          : null,
    );
  }
}
