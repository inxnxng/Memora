import 'package:flutter/material.dart';
import 'package:memora/providers/notion_provider.dart';
import 'package:memora/screens/notion_quiz_chat_screen.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart'; // New import

class TilReviewSelectionScreen extends StatefulWidget {
  const TilReviewSelectionScreen({super.key});

  @override
  State<TilReviewSelectionScreen> createState() =>
      _TilReviewSelectionScreenState();
}

class _TilReviewSelectionScreenState extends State<TilReviewSelectionScreen> {
  int? _selectedIndex;
  String? _selectedPageContent;
  final Map<String, String> _pageContentCache = {};
  final ItemScrollController _itemScrollController =
      ItemScrollController(); // New
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create(); // New

  @override
  void initState() {
    super.initState();
    _initializeQuizState();
  }

  Future<void> _initializeQuizState() async {
    final notionProvider = Provider.of<NotionProvider>(context, listen: false);
    await notionProvider.fetchNotionPages();

    if (notionProvider.pages.isNotEmpty) {
      setState(() {
        _selectedIndex = 0; // Select the first page by default
      });
      // Manually trigger content load for the first page
      _loadPageContent(0, notionProvider.pages[0]['id']);
    }
  }

  Future<void> _loadPageContent(int index, String pageId) async {
    final notionProvider = Provider.of<NotionProvider>(context, listen: false);
    if (_pageContentCache.containsKey(pageId)) {
      setState(() {
        _selectedPageContent = _pageContentCache[pageId];
      });
    } else {
      try {
        final content = await notionProvider.getPageContent(pageId);
        if (!mounted) return;
        setState(() {
          _selectedPageContent = content;
          _pageContentCache[pageId] = content; // Cache the content
        });
      } catch (e) {
        debugPrint('Error fetching page content: $e');
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('페이지 내용을 불러오는 데 실패했습니다: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final notionProvider = Provider.of<NotionProvider>(context);
    final String selectedPageTitle =
        (_selectedIndex != null &&
            notionProvider.pages.isNotEmpty &&
            _selectedIndex! < notionProvider.pages.length)
        ? (notionProvider.pages[_selectedIndex!]['properties']?['Name']?['title']
                          as List?)
                      ?.isNotEmpty ==
                  true
              ? notionProvider
                    .pages[_selectedIndex!]['properties']!['Name']!['title']![0]['plain_text']
              : '제목 없음'
        : '';

    return Scaffold(
      appBar: AppBar(title: const Text('TIL 복습')),
      body: notionProvider.arePagesLoading
          ? const Center(child: CircularProgressIndicator())
          : notionProvider.pages.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Notion 페이지를 찾을 수 없습니다. 설정에서 API 키와 데이터베이스 ID를 확인해주세요.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHorizontalPageList(notionProvider.pages),
                if (_selectedIndex != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 8.0),
                    child: Text(
                      selectedPageTitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                Expanded(
                  child: _selectedPageContent != null
                      ? Container(
                          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          decoration: BoxDecoration(
                            color: const Color.fromRGBO(0, 0, 0, 0.05),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              _selectedPageContent!,
                              style: const TextStyle(
                                fontSize: 16.0,
                                height: 1.5,
                              ),
                            ),
                          ),
                        )
                      : _selectedIndex != null
                      ? const Center(child: CircularProgressIndicator())
                      : const Center(child: Text('복습할 페이지를 위에서 선택해주세요.')),
                ),
                _buildReviewButton(notionProvider),
                const SizedBox(height: 20),
              ],
            ),
    );
  }

  Widget _buildHorizontalPageList(List<dynamic> pages) {
    return SizedBox(
      height: 120,
      child: ScrollablePositionedList.builder(
        // Changed to ScrollablePositionedList.builder
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(16.0),
        itemCount: pages.length,
        itemScrollController: _itemScrollController, // Added controller
        itemPositionsListener: _itemPositionsListener, // Added listener
        itemBuilder: (context, index) {
          final page = pages[index];
          if (page['properties'] == null ||
              page['properties']['Name'] == null ||
              page['properties']['Name']['title'] == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Notion API 연결이 필요합니다. 설정을 먼저 완료해주세요.'),
                ),
              );
            });
            return const SizedBox.shrink();
          }
          final title =
              (page['properties']?['Name']?['title'] as List?)?.isNotEmpty ==
                  true
              ? page['properties']!['Name']!['title']![0]['plain_text']
              : '제목 없음';
          final iconEmoji = page['icon']?['emoji'];
          final isSelected = _selectedIndex == index;

          return GestureDetector(
            onTap: () async {
              setState(() {
                _selectedIndex = index;
                _selectedPageContent = null; // Clear previous content
              });
              // Scroll to the selected item
              _itemScrollController.scrollTo(
                index: index,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOutCubic,
                alignment: 0.5, // Center the item
              );

              final notionProvider = Provider.of<NotionProvider>(
                context,
                listen: false,
              );
              final selectedPage = pages[index];
              final pageId = selectedPage['id'];

              if (_pageContentCache.containsKey(pageId)) {
                setState(() {
                  _selectedPageContent = _pageContentCache[pageId];
                });
              } else {
                try {
                  final content = await notionProvider.getPageContent(pageId);
                  if (!mounted) return;
                  setState(() {
                    _selectedPageContent = content;
                    _pageContentCache[pageId] = content; // Cache the content
                  });
                } catch (e) {
                  debugPrint('Error fetching page content: $e');
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('페이지 내용을 불러오는 데 실패했습니다: $e')),
                  );
                }
              }
            },
            child: Container(
              width: 100,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: isSelected ? Colors.blue.shade100 : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
                border: isSelected
                    ? Border.all(color: Colors.blue, width: 2)
                    : null,
              ),
              child: Stack(
                children: [
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 3,
                      ),
                    ),
                  ),
                  if (iconEmoji != null)
                    Positioned(
                      top: 4,
                      left: 4,
                      child: Text(
                        iconEmoji,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildReviewButton(NotionProvider notionProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade100,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: _selectedIndex == null
            ? null
            : () async {
                if (_selectedIndex == null ||
                    _selectedIndex! >= notionProvider.pages.length) {
                  return;
                }
                final selectedPage = notionProvider.pages[_selectedIndex!];
                final pageId = selectedPage['id'];
                final pageTitle =
                    (selectedPage['properties']?['Name']?['title'] as List?)
                            ?.isNotEmpty ==
                        true
                    ? selectedPage['properties']!['Name']!['title']![0]['plain_text']
                    : '제목 없음';

                // Show loading indicator while fetching content
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) =>
                      const Center(child: CircularProgressIndicator()),
                );

                try {
                  final pageContent = await notionProvider.getPageContent(
                    pageId,
                  );
                  if (!mounted) return; // Add this line
                  Navigator.pop(context); // Dismiss loading indicator

                  if (!mounted) return; // Add this line
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NotionQuizChatScreen(
                        pageTitle: pageTitle,
                        pageContent: pageContent,
                      ),
                    ),
                  );
                } catch (e) {
                  if (!mounted) return; // Add this line
                  Navigator.pop(context); // Dismiss loading indicator
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('콘텐츠를 불러오는 데 실패했습니다: $e')),
                  );
                }
              },
        child: const Text(
          '선택한 내용 복습하기',
          style: TextStyle(
            fontSize: 18,
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
