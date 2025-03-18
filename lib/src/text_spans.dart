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
        // For paragraphs, parse the inline elements
        return TextSpan(
          children: parseInlineElements(element.content),
          style: defaultStyle,
        );
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

    // Improved regex patterns
    // Bold - match text between double asterisks
    final boldRegex = RegExp(r'\*\*(.*?)\*\*');
    // Italic - match text between single asterisks, ensuring they're not part of bold markers
    final italicRegex = RegExp(r'(?<!\*)\*(?!\*)(.*?)(?<!\*)\*(?!\*)');
    // Link
    final linkRegex = RegExp(r'\[(.*?)\]\((.*?)\)');
    // Inline code
    final codeRegex = RegExp(r'`(.*?)`');

    int currentIndex = 0;

    while (currentIndex < text.length) {
      // Find all matches
      final boldMatches = boldRegex.allMatches(text.substring(currentIndex));
      final italicMatches =
          italicRegex.allMatches(text.substring(currentIndex));
      final linkMatches = linkRegex.allMatches(text.substring(currentIndex));
      final codeMatches = codeRegex.allMatches(text.substring(currentIndex));

      // Find the earliest match
      Match? earliestMatch;
      String matchType = '';

      for (final match in boldMatches) {
        if (earliestMatch == null || match.start < earliestMatch.start) {
          earliestMatch = match;
          matchType = 'bold';
        }
      }

      for (final match in italicMatches) {
        if (earliestMatch == null || match.start < earliestMatch.start) {
          earliestMatch = match;
          matchType = 'italic';
        }
      }

      for (final match in linkMatches) {
        if (earliestMatch == null || match.start < earliestMatch.start) {
          earliestMatch = match;
          matchType = 'link';
        }
      }

      for (final match in codeMatches) {
        if (earliestMatch == null || match.start < earliestMatch.start) {
          earliestMatch = match;
          matchType = 'code';
        }
      }

      // No matches found, add remaining text
      if (earliestMatch == null) {
        spans.add(
            TextSpan(text: text.substring(currentIndex), style: defaultStyle));
        break;
      }

      // Add text before the match
      if (earliestMatch.start > 0) {
        spans.add(TextSpan(
          text:
              text.substring(currentIndex, currentIndex + earliestMatch.start),
          style: defaultStyle,
        ));
      }

      // Process the match based on type
      switch (matchType) {
        case 'bold':
          spans.add(TextSpan(
            text: earliestMatch.group(1),
            style: boldStyle,
          ));
          break;
        case 'italic':
          spans.add(TextSpan(
            text: earliestMatch.group(1),
            style: italicStyle,
          ));
          break;
        case 'link':
          final linkText = earliestMatch.group(1) ?? '';
          final linkUrl = earliestMatch.group(2) ?? '';
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
          break;
        case 'code':
          spans.add(TextSpan(
            text: earliestMatch.group(1),
            style: codeStyle,
          ));
          break;
      }

      // Move past this match
      currentIndex += earliestMatch.end;
    }

    return spans;
  }
}
