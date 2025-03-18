import 'package:flutter/material.dart';

enum MarkdownElementType {
  paragraph,
  heading1,
  heading2,
  heading3,
  heading4,
  heading5,
  heading6,
  bold,
  italic,
  link,
  image,
  bulletList,
  orderedList,
  codeBlock,
  inlineCode,
  blockquote,
}

class MarkdownElement {
  final MarkdownElementType type;
  final String content;
  final List<MarkdownElement> children;
  final String? url;
  final int? level;

  MarkdownElement({
    required this.type,
    required this.content,
    this.children = const [],
    this.url,
    this.level,
  });
}

class MarkdownParser {
  /// Parse markdown string into a list of [MarkdownElement]s
  List<MarkdownElement> parse(String markdown) {
    final List<MarkdownElement> elements = [];
    final List<String> lines = markdown.split('\n');

    int i = 0;
    while (i < lines.length) {
      final String line = lines[i].trim();

      // Skip empty lines
      if (line.isEmpty) {
        i++;
        continue;
      }

      // Parse headings
      if (line.startsWith('#')) {
        int level = 1;
        while (level < 7 && level < line.length && line[level] == '#') {
          level++;
        }

        final content = line.substring(level).trim();
        elements.add(
          MarkdownElement(type: _getHeadingType(level), content: content),
        );
        i++;
        continue;
      }

      // Parse blockquote
      if (line.startsWith('> ')) {
        final String content = line.substring(2).trim();
        elements.add(
          MarkdownElement(
            type: MarkdownElementType.blockquote,
            content: content,
          ),
        );
        i++;
        continue;
      }

      // Parse unordered lists
      if (line.startsWith('- ') ||
          line.startsWith('* ') ||
          line.startsWith('+ ')) {
        final List<String> items = [];
        while (i < lines.length &&
            (lines[i].trim().startsWith('- ') ||
                lines[i].trim().startsWith('* ') ||
                lines[i].trim().startsWith('+ '))) {
          items.add(lines[i].trim().substring(2).trim());
          i++;
        }

        elements.add(
          MarkdownElement(
            type: MarkdownElementType.bulletList,
            content: '',
            children: items
                .map(
                  (item) => MarkdownElement(
                    type: MarkdownElementType.paragraph,
                    content: item,
                  ),
                )
                .toList(),
          ),
        );
        continue;
      }

      // Parse ordered lists
      final RegExp orderedListRegex = RegExp(r'^\d+\.\s');
      if (orderedListRegex.hasMatch(line)) {
        final List<String> items = [];
        while (i < lines.length && orderedListRegex.hasMatch(lines[i].trim())) {
          final match = orderedListRegex.firstMatch(lines[i].trim());
          final length = match!.end - match.start;
          items.add(lines[i].trim().substring(length).trim());
          i++;
        }

        elements.add(
          MarkdownElement(
            type: MarkdownElementType.orderedList,
            content: '',
            children: items
                .map(
                  (item) => MarkdownElement(
                    type: MarkdownElementType.paragraph,
                    content: item,
                  ),
                )
                .toList(),
          ),
        );
        continue;
      }

      // Parse code blocks
      if (line.startsWith('```')) {
        i++;
        final List<String> codeLines = [];
        while (i < lines.length && !lines[i].trim().startsWith('```')) {
          codeLines.add(lines[i]);
          i++;
        }
        i++; // Skip the closing ```

        elements.add(
          MarkdownElement(
            type: MarkdownElementType.codeBlock,
            content: codeLines.join('\n'),
          ),
        );
        continue;
      }

      // Default to paragraph
      elements.add(
        MarkdownElement(
          type: MarkdownElementType.paragraph,
          content: _parseInlineElements(line),
        ),
      );
      i++;
    }

    return elements;
  }

  /// Parse inline elements like bold, italic, links, etc.
  String _parseInlineElements(String text) {
    // Process inline formatting like bold, italic, etc.
    // We'll keep the raw markdown markers and let the span builder handle them
    // This approach allows us to have nested formatting
    return text;
  }

  /// Process and extract inline formatting like bold, italic etc. from text
  Map<String, List<Map<String, dynamic>>> processInlineFormatting(String text) {
    // Extract bold text
    final boldRegex = RegExp(r'\*\*(.*?)\*\*');
    final boldMatches = boldRegex.allMatches(text).map((match) {
      return {
        'start': match.start,
        'end': match.end,
        'text': match.group(1)!,
      };
    }).toList();

    // Extract italic text
    final italicRegex = RegExp(r'\*(.*?)\*');
    final italicMatches = italicRegex
        .allMatches(text)
        .map((match) {
          // Avoid matching bold text as italic
          if (match.start > 0 &&
              text[match.start - 1] == '*' &&
              match.end < text.length &&
              text[match.end] == '*') {
            return null;
          }
          return {
            'start': match.start,
            'end': match.end,
            'text': match.group(1)!,
          };
        })
        .where((item) => item != null)
        .cast<Map<String, dynamic>>()
        .toList();

    // Extract links
    final linkRegex = RegExp(r'\[(.*?)\]\((.*?)\)');
    final linkMatches = linkRegex.allMatches(text).map((match) {
      return {
        'start': match.start,
        'end': match.end,
        'text': match.group(1)!,
        'url': match.group(2)!,
      };
    }).toList();

    // Extract inline code
    final codeRegex = RegExp(r'`(.*?)`');
    final codeMatches = codeRegex.allMatches(text).map((match) {
      return {
        'start': match.start,
        'end': match.end,
        'text': match.group(1)!,
      };
    }).toList();

    return {
      'bold': boldMatches,
      'italic': italicMatches,
      'link': linkMatches,
      'code': codeMatches,
    };
  }

  /// Get the appropriate heading type based on level
  MarkdownElementType _getHeadingType(int level) {
    switch (level) {
      case 1:
        return MarkdownElementType.heading1;
      case 2:
        return MarkdownElementType.heading2;
      case 3:
        return MarkdownElementType.heading3;
      case 4:
        return MarkdownElementType.heading4;
      case 5:
        return MarkdownElementType.heading5;
      case 6:
        return MarkdownElementType.heading6;
      default:
        return MarkdownElementType.heading1;
    }
  }
}
