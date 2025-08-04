import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:memora/models/task_model.dart';
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
  final Set<String> _selectedPageIds = {};
  bool _isFetchingContent = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotionProvider>(context, listen: false).fetchNotionPages();
    });
  }

  void _toggleSelection(String pageId) {
    if (_isFetchingContent) return;
    setState(() {
      if (_selectedPageIds.contains(pageId)) {
        _selectedPageIds.remove(pageId);
      } else {
        _selectedPageIds.add(pageId);
      }
    });
  }

  Future<void> _startCombinedTraining() async {
    if (_selectedPageIds.isEmpty) return;

    setState(() {
      _isFetchingContent = true;
    });

    final notionProvider = Provider.of<NotionProvider>(context, listen: false);
    final List<NotionPage> selectedPages = [];

    final allPages = notionProvider.pages;
    final selectedPagesMeta = allPages
        .where((page) => _selectedPageIds.contains(page['id']))
        .toList();

    try {
      for (var pageMeta in selectedPagesMeta) {
        final pageId = pageMeta['id'];
        final titleList = pageMeta['properties']?['Name']?['title'] as List?;
        final title = titleList?.isNotEmpty == true
            ? titleList![0]['plain_text']
            : '제목 없음';
        final content = await notionProvider.getPageContent(pageId);
        selectedPages.add(
          NotionPage(id: pageId, title: title, content: content),
        );
      }

      if (!mounted) return;

      context.push(AppRoutes.review, extra: selectedPages);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('페이지 내용을 불러오는 데 실패했습니다: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isFetchingContent = false;
        });
      }
    }
  }

  void _navigateToPageViewer(
    BuildContext context,
    String pageId,
    String pageTitle,
  ) {
    final notionProvider = Provider.of<NotionProvider>(context, listen: false);
    final databaseName = notionProvider.databaseTitle ?? 'Unknown DB';
    context.push(
      '${AppRoutes.review}/${AppRoutes.notionPage.replaceFirst(':pageId', pageId)}?pageTitle=$pageTitle&databaseName=$databaseName',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: const CommonAppBar(title: 'TIL 복습 주제 선택'),
      body: Stack(
        children: [
          Consumer<NotionProvider>(
            builder: (context, notionProvider, child) {
              if (notionProvider.arePagesLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (notionProvider.pages.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Notion 페이지를 찾을 수 없습니다. 설정에서 API 키와 데이터베이스 ID를 확인해주세요.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              return ListView.builder(
                itemCount: notionProvider.pages.length,
                itemBuilder: (context, index) {
                  final page = notionProvider.pages[index];
                  final pageId = page['id'];
                  final properties = page['properties'];
                  final isSelected = _selectedPageIds.contains(pageId);

                  final titleList = properties?['Name']?['title'] as List?;
                  final title = titleList?.isNotEmpty == true
                      ? titleList![0]['plain_text']
                      : '제목 없음';

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
                          _toggleSelection(pageId);
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
              );
            },
          ),
          if (_isFetchingContent)
            Container(
              color: Colors.black.withAlpha(128),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      '페이지 내용을 불러오는 중...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: _selectedPageIds.isNotEmpty && !_isFetchingContent
          ? FloatingActionButton.extended(
              onPressed: _startCombinedTraining,
              label: const Text('훈련 시작'),
              icon: const Icon(Icons.chat_bubble_outline),
            )
          : null,
    );
  }
}
