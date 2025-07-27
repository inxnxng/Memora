import 'package:flutter/material.dart';
import 'package:markdown_widget/markdown_widget.dart';
import 'package:memora/providers/notion_provider.dart';
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

  @override
  void initState() {
    super.initState();
    // Access the provider without listening to it for one-off async operations.
    final notionProvider = Provider.of<NotionProvider>(context, listen: false);
    _markdownFuture = notionProvider.renderNotionDbAsMarkdown(widget.pageId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.pageTitle)),
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
              padding: const EdgeInsets.all(16.0),
              child: MarkdownWidget(data: snapshot.data!, shrinkWrap: true),
            );
          }
        },
      ),
    );
  }
}
