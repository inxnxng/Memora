import 'dart:async';

import 'package:flutter/material.dart';
import 'package:markdown_widget/markdown_widget.dart';
import 'package:memora/providers/notion_provider.dart';
import 'package:memora/providers/task_provider.dart';
import 'package:memora/screens/review/notion_quiz_chat_screen.dart';
import 'package:provider/provider.dart';

class NotionPageViewerScreen extends StatefulWidget {
  final String pageId;
  final String pageTitle;

  const NotionPageViewerScreen({
    super.key,
    required this.pageId,
    required this.pageTitle,
  });

  @override
  State<NotionPageViewerScreen> createState() => _NotionPageViewerScreenState();
}

class _NotionPageViewerScreenState extends State<NotionPageViewerScreen> {
  late Future<String> _markdownFuture;
  bool _showCompleteButton = false;
  String _pageContent = '';
  final TocController _tocController = TocController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    final notionProvider = Provider.of<NotionProvider>(context, listen: false);
    _markdownFuture = notionProvider.renderNotionDbAsMarkdown(widget.pageId);
    _markdownFuture.then((content) {
      if (mounted) {
        setState(() {
          _pageContent = content;
        });
      }
    });

    // 학습 페이지에서 n초 이상 잔류할 경우 complete 가능 상태
    Timer(const Duration(seconds: 10), () {
      if (mounted) {
        setState(() {
          _showCompleteButton = true;
        });
      }
    });
  }

  void _completeStudy(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    taskProvider
        .addStudyRecordForToday()
        .then((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('오늘의 학습이 기록되었습니다!'),
              backgroundColor: Colors.green,
            ),
          );
          // Optionally, pop the screen or disable the button
          if (mounted) {
            setState(() {
              _showCompleteButton = false; // Prevent multiple submissions
            });
          }
        })
        .catchError((error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('학습 기록에 실패했습니다: $error'),
              backgroundColor: Colors.red,
            ),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pageTitle),
        actions: [
          if (_showCompleteButton)
            IconButton(
              icon: const Icon(Icons.check_circle),
              tooltip: '학습 완료',
              onPressed: () => _completeStudy(context),
            ),
        ],
      ),
      body: FutureBuilder<String>(
        future: _markdownFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Error loading page: ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No content found on this page.'));
          } else {
            return SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16.0),
              child: MarkdownWidget(
                data: snapshot.data!,
                shrinkWrap: true,
                tocController: _tocController,
              ),
            );
          }
        },
      ),
      persistentFooterButtons: [
        if (_pageContent.isNotEmpty)
          Center(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.quiz_outlined),
              label: const Text('복습하기'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NotionQuizChatScreen(
                      pageTitle: widget.pageTitle,
                      pageContent: _pageContent,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 15,
                ),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _tocController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
