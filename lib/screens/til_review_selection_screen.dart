import 'package:flutter/material.dart';
import 'package:memora/providers/notion_provider.dart';
import 'package:memora/screens/notion_page_viewer_screen.dart';
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
    // Fetch pages when the screen is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotionProvider>(context, listen: false).fetchNotionPages();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('TIL 복습 페이지 선택')),
      body: Consumer<NotionProvider>(
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

              // Safely extract title
              final titleList = properties?['Name']?['title'] as List?;
              final title = titleList?.isNotEmpty == true
                  ? titleList![0]['plain_text']
                  : '제목 없음';

              // Safely extract emoji icon
              final icon = page['icon'];
              final emoji = icon?['type'] == 'emoji' ? icon['emoji'] : '📄';

              return Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: ListTile(
                  leading: Text(emoji, style: const TextStyle(fontSize: 24)),
                  title: Text(title),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NotionPageViewerScreen(
                          pageId: pageId,
                          pageTitle: title,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
