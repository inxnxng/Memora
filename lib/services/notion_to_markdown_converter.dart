class NotionToMarkdownConverter {
  String convert(List<dynamic> blocks) {
    final buffer = StringBuffer();
    for (final block in blocks) {
      final type = block['type'] as String;
      final content = block[type] ?? {};

      switch (type) {
        case 'heading_1':
          buffer.writeln('# ${_getRichText(content['rich_text'])}\n');
          break;
        case 'heading_2':
          buffer.writeln('## ${_getRichText(content['rich_text'])}\n');
          break;
        case 'heading_3':
          buffer.writeln('### ${_getRichText(content['rich_text'])}\n');
          break;
        case 'paragraph':
          buffer.writeln('${_getRichText(content['rich_text'])}\n');
          break;
        case 'bulleted_list_item':
          buffer.writeln('* ${_getRichText(content['rich_text'])}');
          break;
        case 'numbered_list_item':
          buffer.writeln('1. ${_getRichText(content['rich_text'])}');
          break;
        case 'to_do':
          final checked = content['checked'] as bool;
          buffer.writeln(
            '- [${checked ? 'x' : ' '}] ${_getRichText(content['rich_text'])}',
          );
          break;
        case 'quote':
          buffer.writeln('> ${_getRichText(content['rich_text'])}\n');
          break;
        case 'code':
          final language = content['language'];
          buffer.writeln(
            '```$language\n${_getRichText(content['rich_text'])}\n```\n',
          );
          break;
        case 'divider':
          buffer.writeln('---\n');
          break;
        case 'image':
          final imageUrl =
              content['external']?['url'] ?? content['file']?['url'];
          if (imageUrl != null) {
            buffer.writeln('![]($imageUrl)\n');
          }
          break;
        default:
          break;
      }
    }
    return buffer.toString();
  }

  String _getRichText(List<dynamic> richText) {
    final buffer = StringBuffer();
    for (final textItem in richText) {
      // Handle cases where 'text' might be null (e.g., for mentions)
      if (textItem['text'] == null) continue;

      var text = textItem['text']['content'];
      final annotations = textItem['annotations'];
      if (annotations['bold']) {
        text = '**$text**';
      }
      if (annotations['italic']) {
        text = '*$text*';
      }
      if (annotations['strikethrough']) {
        text = '~~$text~~';
      }
      if (annotations['code']) {
        text = '`$text`';
      }
      final href = textItem['href'];
      if (href != null) {
        text = '[$text]($href)';
      }
      buffer.write(text);
    }
    return buffer.toString();
  }
}
