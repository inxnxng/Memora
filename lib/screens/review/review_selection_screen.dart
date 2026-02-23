import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:memora/constants/app_strings.dart';
import 'package:memora/models/notion_page.dart';
import 'package:memora/models/notion_route_extra.dart';
import 'package:memora/providers/notion_provider.dart';
import 'package:memora/providers/task_provider.dart';
import 'package:memora/router/app_routes.dart';
import 'package:memora/widgets/common_app_bar.dart';
import 'package:provider/provider.dart';

class ReviewSelectionScreen extends StatefulWidget {
  const ReviewSelectionScreen({super.key});

  @override
  State<ReviewSelectionScreen> createState() => _ReviewSelectionScreenState();
}

class _ReviewSelectionScreenState extends State<ReviewSelectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  static const int _pageSize = 15;
  int _currentPage = 0;
  Set<String> _completedPageIds = {};
  TaskProvider? _taskProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotionProvider>().fetchNotionPages();
      context.read<NotionProvider>().clearPageSelection();
      _taskProvider = context.read<TaskProvider>();
      _taskProvider!.addListener(_onTaskProviderChanged);
      _loadCompletedPageIds();
    });
  }

  void _loadCompletedPageIds() {
    _taskProvider?.getCompletedPageIds().then((ids) {
      if (mounted) setState(() => _completedPageIds = ids);
    });
  }

  void _onTaskProviderChanged() {
    _loadCompletedPageIds();
  }

  @override
  void dispose() {
    _taskProvider?.removeListener(_onTaskProviderChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _navigateToPageViewer(
    BuildContext context,
    String pageId,
    String pageTitle,
    String? url,
  ) {
    final notionProvider = context.read<NotionProvider>();
    final databaseName = notionProvider.databaseTitle;
    final extra = NotionRouteExtra(
      databaseName: databaseName,
      pageId: pageId,
      pageTitle: pageTitle,
      url: url,
    );
    context.push('${AppRoutes.review}/${AppRoutes.notionPage}', extra: extra);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notionProvider = context.watch<NotionProvider>();

    final searchQuery = _searchController.text.trim().toLowerCase();
    final filteredPages = searchQuery.isEmpty
        ? notionProvider.pages
        : notionProvider.pages
              .where((p) => p.title.toLowerCase().contains(searchQuery))
              .toList();
    final totalPages = (filteredPages.length / _pageSize).ceil().clamp(1, 999);
    final start = (_currentPage * _pageSize).clamp(0, filteredPages.length);
    final end = (start + _pageSize).clamp(0, filteredPages.length);
    final pageItems = filteredPages.sublist(start, end);

    return Scaffold(
      appBar: CommonAppBar(
        title: AppStrings.tilReviewSelectionTitle,
        actions: const [],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: InkWell(
              onTap: () =>
                  context.push("${AppRoutes.review}/${AppRoutes.chatHistory}"),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 24,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '채팅 기록',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '이전 복습 대화 다시 보기',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ),
          // 검색
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() => _currentPage = 0),
              decoration: InputDecoration(
                hintText: '주제 검색',
                prefixIcon: const Icon(Icons.search_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(height: 8),
          // 리스트 + 페이지네이션
          Expanded(
            child: _buildBody(
              theme,
              notionProvider,
              pageItems,
              filteredPages.length,
              _completedPageIds,
            ),
          ),
          if (totalPages > 1) _buildPagination(theme, totalPages),
        ],
      ),
    );
  }

  Widget _buildBody(
    ThemeData theme,
    NotionProvider notionProvider,
    List<NotionPage> pageItems,
    int totalCount,
    Set<String> completedPageIds,
  ) {
    if (notionProvider.arePagesLoading && notionProvider.pages.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (notionProvider.pages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.article_outlined,
                size: 56,
                color: theme.colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                AppStrings.noNotionPagesFound,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (pageItems.isEmpty) {
      return Center(
        child: Text(
          '검색 결과가 없습니다.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: pageItems.length,
      itemBuilder: (context, index) {
        final page = pageItems[index];
        final pageId = page.id;
        final title = page.title;
        final url = page.url;
        final isCompleted = completedPageIds.contains(pageId);

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isCompleted
                  ? theme.colorScheme.primary.withValues(alpha: 0.3)
                  : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          color: isCompleted
              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.25)
              : null,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 10,
            ),
            onTap: () => _navigateToPageViewer(context, pageId, title, url),
            leading: Icon(
              isCompleted ? Icons.article_rounded : Icons.article_outlined,
              size: 26,
              color: isCompleted
                  ? theme.colorScheme.primary
                  : theme.colorScheme.primary.withValues(alpha: 0.7),
            ),
            title: Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
            subtitle: isCompleted
                ? Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          size: 14,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '학습 완료',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                : null,
            trailing: Icon(
              Icons.chevron_right_rounded,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        );
      },
    );
  }

  Widget _buildPagination(ThemeData theme, int totalPages) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left_rounded),
              onPressed: _currentPage > 0
                  ? () => setState(() => _currentPage--)
                  : null,
              style: IconButton.styleFrom(
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              '${_currentPage + 1} / $totalPages',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 16),
            IconButton(
              icon: const Icon(Icons.chevron_right_rounded),
              onPressed: _currentPage < totalPages - 1
                  ? () => setState(() => _currentPage++)
                  : null,
              style: IconButton.styleFrom(
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
