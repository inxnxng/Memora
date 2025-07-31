import 'package:flutter/material.dart';
import 'package:memora/models/task_model.dart';
import 'package:memora/providers/notion_provider.dart';
import 'package:memora/screens/review/notion_page_viewer_screen.dart';
import 'package:memora/screens/roadmap/combined_training_chat_screen.dart';
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
    final List<Future<NotionPage>> pageFutures = [];

    final allPages = notionProvider.pages;
    final selectedPagesMeta = allPages
        .where((page) => _selectedPageIds.contains(page['id']))
        .toList();

    for (var pageMeta in selectedPagesMeta) {
      pageFutures.add(
        Future(() async {
          final pageId = pageMeta['id'];
          final titleList = pageMeta['properties']?['Name']?['title'] as List?;
          final title = titleList?.isNotEmpty == true
              ? titleList![0]['plain_text']
              : '제목 없음';
          final content = await notionProvider.getPageContent(pageId);
          return NotionPage(id: pageId, title: title, content: content);
        }),
      );
    }

    try {
      final selectedPages = await Future.wait(pageFutures);

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              CombinedTrainingChatScreen(pages: selectedPages),
        ),
      );
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

  void _navigateToPageViewer(String pageId, String pageTitle) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            NotionPageViewerScreen(pageId: pageId, pageTitle: pageTitle),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('TIL 복습 주제 선택')),
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
                    color: isSelected
                        ? theme.primaryColor.withOpacity(0.05)
                        : theme.cardColor,
                    child: InkWell(
                      onTap: () => _navigateToPageViewer(pageId, title),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8.0,
                          vertical: 12.0,
                        ),
                        child: Row(
                          children: [
                            Checkbox(
                              value: isSelected,
                              onChanged: (bool? value) {
                                _toggleSelection(pageId);
                              },
                              activeColor: theme.primaryColor,
                            ),
                            const SizedBox(width: 8),
                            Text(emoji, style: const TextStyle(fontSize: 24)),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                title,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
          if (_isFetchingContent)
            Container(
              color: Colors.black.withOpacity(0.5),
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
