import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:memora/constants/app_strings.dart';
import 'package:memora/providers/notion_provider.dart';
import 'package:memora/router/app_routes.dart';
import 'package:memora/widgets/common_app_bar.dart';
import 'package:provider/provider.dart';

class TilReviewSelectionScreen extends StatefulWidget {
  const TilReviewSelectionScreen({super.key});

  @override
  State<TilReviewSelectionScreen> createState() =>
      _TilReviewSelectionScreenState();
}

class _TilReviewSelectionScreenState extends State<TilReviewSelectionScreen> {
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
      context.push(AppRoutes.review, extra: notionProvider.combinedPageContent);
    } else if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(notionProvider.notionConnectionError ??
                AppStrings.pageContentLoadFailed)),
      );
    }
  }

  void _navigateToPageViewer(
    BuildContext context,
    String pageId,
    String pageTitle,
  ) {
    final notionProvider = context.read<NotionProvider>();
    final databaseName = notionProvider.databaseTitle ?? AppStrings.unknownDb;
    context.push(
      '${AppRoutes.review}/${AppRoutes.notionPage.replaceFirst(':pageId', pageId)}?pageTitle=$pageTitle&databaseName=$databaseName',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notionProvider = context.watch<NotionProvider>();

    return Scaffold(
      appBar: const CommonAppBar(title: AppStrings.tilReviewSelectionTitle),
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
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            ListView.builder(
              itemCount: notionProvider.pages.length,
              itemBuilder: (context, index) {
                final page = notionProvider.pages[index];
                final pageId = page['id'];
                final properties = page['properties'];
                final isSelected = notionProvider.selectedPageIds.contains(pageId);

                final titleList = properties?['Name']?['title'] as List?;
                final title = titleList?.isNotEmpty == true
                    ? titleList![0]['plain_text']
                    : AppStrings.noTitle;

                final icon = page['icon'];
                final emoji = icon?['type'] == 'emoji' ? icon['emoji'] : '📄';

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
                    onTap: () =>
                        _navigateToPageViewer(context, pageId, title),
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
      floatingActionButton: notionProvider.selectedPageIds.isNotEmpty &&
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