import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:markdown_widget/markdown_widget.dart';
import 'package:memora/models/notion_page.dart';
import 'package:memora/models/notion_route_extra.dart';
import 'package:memora/providers/notion_provider.dart';
import 'package:memora/providers/task_provider.dart';
import 'package:memora/router/app_routes.dart';
import 'package:memora/widgets/common_app_bar.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class NotionPageViewerScreen extends StatefulWidget {
  final String pageId;
  final String pageTitle;
  final String databaseName;
  final String? url;

  const NotionPageViewerScreen({
    super.key,
    required this.pageId,
    required this.pageTitle,
    required this.databaseName,
    this.url,
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
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent) {
        setState(() {
          _showCompleteButton = true;
        });
      }
    });
  }

  void _completeStudy(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    taskProvider
        .addStudyRecordForToday(
          databaseName: widget.databaseName,
          title: widget.pageTitle,
        )
        .then((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('오늘의 학습이 기록되었습니다!'),
              backgroundColor: Colors.green,
            ),
          );

          if (mounted) {
            setState(() {
              _showCompleteButton = false;
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

  Future<void> _launchUrl() async {
    if (widget.url == null) return;
    final Uri url = Uri.parse(widget.url!);
    if (!await launchUrl(url)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch Notion link')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: widget.pageTitle,
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
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.url != null)
              OutlinedButton.icon(
                icon: const Icon(Icons.link),
                label: const Text('노션 보러 가기'),
                onPressed: _launchUrl,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 15,
                  ),
                ),
              ),
            if (widget.url != null) const SizedBox(width: 12),
            if (_pageContent.isNotEmpty)
              ElevatedButton.icon(
                icon: const Icon(Icons.quiz_sharp),
                label: const Text('복습하기'),
                onPressed: () {
                  final page = NotionPage(
                    id: widget.pageId,
                    title: widget.pageTitle,
                    content: _pageContent,
                    url: widget.url,
                  );
                  final routeExtra = NotionRouteExtra(
                    pages: [page],
                    databaseName: widget.databaseName,
                  );
                  context.push(AppRoutes.chat, extra: routeExtra);
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 15,
                  ),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
          ],
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
