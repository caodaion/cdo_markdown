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
    final italicRegex = RegExp(r'\*(.*?)\*');
    // Link
    final linkRegex = RegExp(r'\[(.*?)\]\((.*?)\)');
    // Inline code
    final codeRegex = RegExp(r'`(.*?)`');

    String remaining = text;
    int currentIndex = 0;

    while (currentIndex < remaining.length) {
      // Check for bold text
      final boldMatch = boldRegex.firstMatch(remaining.substring(currentIndex));
      final italicMatch = italicRegex.firstMatch(
        remaining.substring(currentIndex),
      );
      final linkMatch = linkRegex.firstMatch(remaining.substring(currentIndex));
      final codeMatch = codeRegex.firstMatch(remaining.substring(currentIndex));

      // Find the closest match
      int? boldStart = boldMatch?.start;
      int? italicStart = italicMatch?.start;
      int? linkStart = linkMatch?.start;
      int? codeStart = codeMatch?.start;

      // If no matches, add remaining text
      if (boldStart == null &&
          italicStart == null &&
          linkStart == null &&
          codeStart == null) {
        spans.add(
          TextSpan(
            text: remaining.substring(currentIndex),
            style: defaultStyle,
          ),
        );
        break;
      }

      // Find the earliest match
      int? earliestStart;
      if (boldStart != null) earliestStart = boldStart;
      if (italicStart != null &&
          (earliestStart == null || italicStart < earliestStart))
        earliestStart = italicStart;
      if (linkStart != null &&
          (earliestStart == null || linkStart < earliestStart))
        earliestStart = linkStart;
      if (codeStart != null &&
          (earliestStart == null || codeStart < earliestStart))
        earliestStart = codeStart;

      // Add text before the match
      if (earliestStart! > 0) {
        spans.add(
          TextSpan(
            text: remaining.substring(
              currentIndex,
              currentIndex + earliestStart,
            ),
            style: defaultStyle,
          ),
        );
      }

      // Handle the match
      if (earliestStart == boldStart && boldMatch != null) {
        spans.add(TextSpan(text: boldMatch.group(1), style: boldStyle));
        currentIndex += boldMatch.end;
      } else if (earliestStart == italicStart && italicMatch != null) {
        spans.add(TextSpan(text: italicMatch.group(1), style: italicStyle));
        currentIndex += italicMatch.end;
      } else if (earliestStart == linkStart && linkMatch != null) {
        final String linkText = linkMatch.group(1) ?? '';
        final String linkUrl = linkMatch.group(2) ?? '';
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
        currentIndex += linkMatch.end;
      } else if (earliestStart == codeStart && codeMatch != null) {
        spans.add(TextSpan(text: codeMatch.group(1), style: codeStyle));
        currentIndex += codeMatch.end;
      }
    }

    return spans;
  }
}
