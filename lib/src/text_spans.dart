import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'parser.dart';

class MarkdownTextSpan {
  final TextStyle defaultStyle;
  final TextStyle headingStyle1;
  final TextStyle headingStyle2;
  final TextStyle headingStyle3;
  final TextStyle headingStyle4;
  final TextStyle headingStyle5;
  final TextStyle headingStyle6;
  final TextStyle boldStyle;
  final TextStyle italicStyle;
  final TextStyle codeStyle;
  final TextStyle blockquoteStyle;
  final Color linkColor;
  final VoidCallback? onLinkTap;

  MarkdownTextSpan({
    required this.defaultStyle,
    required this.headingStyle1,
    required this.headingStyle2,
    required this.headingStyle3,
    required this.headingStyle4,
    required this.headingStyle5,
    required this.headingStyle6,
    required this.boldStyle,
    required this.italicStyle,
    required this.codeStyle,
    required this.blockquoteStyle,
    required this.linkColor,
    this.onLinkTap,
  });

  /// Create InlineSpan for different markdown elements
  InlineSpan createSpan(MarkdownElement element) {
    switch (element.type) {
      case MarkdownElementType.paragraph:
        return TextSpan(text: element.content, style: defaultStyle);
      case MarkdownElementType.heading1:
        return TextSpan(text: element.content, style: headingStyle1);
      case MarkdownElementType.heading2:
        return TextSpan(text: element.content, style: headingStyle2);
      case MarkdownElementType.heading3:
        return TextSpan(text: element.content, style: headingStyle3);
      case MarkdownElementType.heading4:
        return TextSpan(text: element.content, style: headingStyle4);
      case MarkdownElementType.heading5:
        return TextSpan(text: element.content, style: headingStyle5);
      case MarkdownElementType.heading6:
        return TextSpan(text: element.content, style: headingStyle6);
      case MarkdownElementType.bold:
        return TextSpan(text: element.content, style: boldStyle);
      case MarkdownElementType.italic:
        return TextSpan(text: element.content, style: italicStyle);
      case MarkdownElementType.link:
        return TextSpan(
          text: element.content,
          style: defaultStyle.copyWith(
            color: linkColor,
            decoration: TextDecoration.underline,
          ),
          recognizer: onLinkTap != null
              ? (TapGestureRecognizer()..onTap = onLinkTap)
              : null,
        );
      case MarkdownElementType.inlineCode:
        return TextSpan(text: element.content, style: codeStyle);
      case MarkdownElementType.blockquote:
        return TextSpan(text: element.content, style: blockquoteStyle);
      case MarkdownElementType.codeBlock:
        return TextSpan(text: element.content, style: codeStyle);
      case MarkdownElementType.bulletList:
      case MarkdownElementType.orderedList:
      case MarkdownElementType.image:
        // Handled separately in the widget
        return TextSpan(text: '');
    }
  }

  /// Create list item spans with appropriate bullets
  List<InlineSpan> createBulletListSpans(
    MarkdownElement element, {
    bool ordered = false,
  }) {
    List<InlineSpan> spans = [];

    for (int i = 0; i < element.children.length; i++) {
      final child = element.children[i];
      if (ordered) {
        spans.add(TextSpan(text: '${i + 1}. ', style: defaultStyle));
      } else {
        spans.add(TextSpan(text: '• ', style: defaultStyle));
      }

      spans.add(TextSpan(text: child.content, style: defaultStyle));

      if (i < element.children.length - 1) {
        spans.add(TextSpan(text: '\n'));
      }
    }

    return spans;
  }

  /// Parse inline elements like *italic*, **bold**, [links](url), etc.
  List<InlineSpan> parseInlineElements(String text) {
    List<InlineSpan> spans = [];

    // Simple regex-based parsing for basic inline elements
    // Bold
    final boldRegex = RegExp(r'\*\*(.*?)\*\*');
    // Italic
    final italicRegex = RegExp(r'\*(.*?)\*(?!\*)');
    // Link
    final linkRegex = RegExp(r'\[(.*?)\]\((.*?)\)');
    // Inline code
    final codeRegex = RegExp(r'`(.*?)`');

    String remaining = text;
    int currentIndex = 0;

    while (currentIndex < remaining.length) {
      // Check for bold text
      final boldMatch = boldRegex.firstMatch(remaining.substring(currentIndex));
      final boldStart = boldMatch?.start ?? -1;
      final boldEnd = boldMatch != null ? boldMatch.end : -1;

      // Check for italic text (avoid matching inside bold)
      final italicMatch =
          italicRegex.firstMatch(remaining.substring(currentIndex));
      final italicStart = italicMatch?.start ?? -1;
      final italicEnd = italicMatch != null ? italicMatch.end : -1;

      // Check for links
      final linkMatch = linkRegex.firstMatch(remaining.substring(currentIndex));
      final linkStart = linkMatch?.start ?? -1;
      final linkEnd = linkMatch != null ? linkMatch.end : -1;

      // Check for inline code
      final codeMatch = codeRegex.firstMatch(remaining.substring(currentIndex));
      final codeStart = codeMatch?.start ?? -1;
      final codeEnd = codeMatch != null ? codeMatch.end : -1;

      // Find the earliest match
      final matches = [
        if (boldStart >= 0)
          {
            'type': 'bold',
            'start': boldStart,
            'end': boldEnd,
            'match': boldMatch!
          },
        if (italicStart >= 0)
          {
            'type': 'italic',
            'start': italicStart,
            'end': italicEnd,
            'match': italicMatch!
          },
        if (linkStart >= 0)
          {
            'type': 'link',
            'start': linkStart,
            'end': linkEnd,
            'match': linkMatch!
          },
        if (codeStart >= 0)
          {
            'type': 'code',
            'start': codeStart,
            'end': codeEnd,
            'match': codeMatch!
          },
      ];

      if (matches.isEmpty) {
        // No matches found, add the rest of the text
        spans.add(TextSpan(
          text: remaining.substring(currentIndex),
          style: defaultStyle,
        ));
        break;
      }

      // Sort matches by start position
      matches.sort((a, b) => (a['start'] as int).compareTo(b['start'] as int));
      final earliestMatch = matches.first;
      final earliestStart = earliestMatch['start'] as int;

      // Add text before the match
      if (earliestStart > 0) {
        spans.add(TextSpan(
          text: remaining.substring(currentIndex, currentIndex + earliestStart),
          style: defaultStyle,
        ));
      }

      // Process the match
      switch (earliestMatch['type']) {
        case 'bold':
          final match = earliestMatch['match'] as RegExpMatch;
          spans.add(TextSpan(text: match.group(1), style: boldStyle));
          currentIndex += match.end;
          break;
        case 'italic':
          final match = earliestMatch['match'] as RegExpMatch;
          spans.add(TextSpan(text: match.group(1), style: italicStyle));
          currentIndex += match.end;
          break;
        case 'link':
          final match = earliestMatch['match'] as RegExpMatch;
          final linkText = match.group(1) ?? '';
          final linkUrl = match.group(2) ?? '';
          spans.add(
            TextSpan(
              text: linkText,
              style: defaultStyle.copyWith(
                color: linkColor,
                decoration: TextDecoration.underline,
              ),
              recognizer: onLinkTap != null
                  ? (TapGestureRecognizer()..onTap = () => onLinkTap!())
                  : null,
              semanticsLabel: 'Link to $linkUrl',
            ),
          );
          currentIndex += match.end;
          break;
        case 'code':
          final match = earliestMatch['match'] as RegExpMatch;
          spans.add(TextSpan(text: match.group(1), style: codeStyle));
          currentIndex += match.end;
          break;
      }
    }

    return spans;
  }
}
