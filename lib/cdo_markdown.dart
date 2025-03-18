library cdo_markdown;

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'src/parser.dart';
import 'src/text_spans.dart';

export 'src/parser.dart';
export 'src/text_spans.dart';

class CDOMarkdown extends StatelessWidget {
  final String data;
  final TextStyle? style;
  final TextStyle? h1Style;
  final TextStyle? h2Style;
  final TextStyle? h3Style;
  final TextStyle? h4Style;
  final TextStyle? h5Style;
  final TextStyle? h6Style;
  final TextStyle? boldStyle;
  final TextStyle? italicStyle;
  final TextStyle? codeStyle;
  final TextStyle? blockquoteStyle;
  final Color? linkColor;
  final void Function(String)? onLinkTap;
  final double listItemSpacing;

  const CDOMarkdown({
    Key? key,
    required this.data,
    this.style,
    this.h1Style,
    this.h2Style,
    this.h3Style,
    this.h4Style,
    this.h5Style,
    this.h6Style,
    this.boldStyle,
    this.italicStyle,
    this.codeStyle,
    this.blockquoteStyle,
    this.linkColor,
    this.onLinkTap,
    this.listItemSpacing = 8.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final defaultStyle = style ?? theme.textTheme.bodyMedium!;

    // Default styles based on theme and provided overrides
    final TextStyle headingStyle1 = (h1Style ?? theme.textTheme.displaySmall)!;
    final TextStyle headingStyle2 =
        (h2Style ?? theme.textTheme.headlineMedium)!;
    final TextStyle headingStyle3 = (h3Style ?? theme.textTheme.headlineSmall)!;
    final TextStyle headingStyle4 = (h4Style ?? theme.textTheme.titleLarge)!;
    final TextStyle headingStyle5 = (h5Style ?? theme.textTheme.titleMedium)!;
    final TextStyle headingStyle6 = (h6Style ?? theme.textTheme.titleSmall)!;
    final TextStyle bold =
        boldStyle ?? defaultStyle.copyWith(fontWeight: FontWeight.bold);
    final TextStyle italic =
        italicStyle ?? defaultStyle.copyWith(fontStyle: FontStyle.italic);
    final TextStyle code = codeStyle ??
        defaultStyle.copyWith(
          fontFamily: 'monospace',
          backgroundColor: Colors.grey.withOpacity(0.2),
        );
    final TextStyle blockquote = blockquoteStyle ??
        defaultStyle.copyWith(
          color: Colors.grey.shade700,
          fontStyle: FontStyle.italic,
        );

    final Color link = linkColor ?? theme.colorScheme.primary;

    // Parse the markdown
    final parser = MarkdownParser();
    final elements = parser.parse(data);

    // Helper to create spans
    final markdownTextSpan = MarkdownTextSpan(
      defaultStyle: defaultStyle,
      headingStyle1: headingStyle1,
      headingStyle2: headingStyle2,
      headingStyle3: headingStyle3,
      headingStyle4: headingStyle4,
      headingStyle5: headingStyle5,
      headingStyle6: headingStyle6,
      boldStyle: bold,
      italicStyle: italic,
      codeStyle: code,
      blockquoteStyle: blockquote,
      linkColor: link,
      onLinkTap: onLinkTap != null ? () => onLinkTap!('') : null,
    );

    // Build widgets from parsed elements
    List<Widget> widgets = [];

    for (final element in elements) {
      switch (element.type) {
        case MarkdownElementType.bulletList:
        case MarkdownElementType.orderedList:
          final bool ordered = element.type == MarkdownElementType.orderedList;
          widgets.add(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: element.children.asMap().entries.map((entry) {
                final int index = entry.key;
                final MarkdownElement item = entry.value;

                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index < element.children.length - 1
                        ? listItemSpacing
                        : 0,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 20,
                        child: Text(
                          ordered ? '${index + 1}.' : '•',
                          style: defaultStyle,
                        ),
                      ),
                      Expanded(
                        child: Text.rich(
                          TextSpan(text: item.content, style: defaultStyle),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          );
          break;

        case MarkdownElementType.codeBlock:
          widgets.add(
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8.0),
              color: Colors.grey.withOpacity(0.2),
              child: Text.rich(TextSpan(text: element.content, style: code)),
            ),
          );
          break;

        case MarkdownElementType.blockquote:
          widgets.add(
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 4.0,
              ),
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(color: Colors.grey.shade300, width: 4.0),
                ),
              ),
              child: Text.rich(
                TextSpan(text: element.content, style: blockquote),
              ),
            ),
          );
          break;

        case MarkdownElementType.paragraph:
          // For paragraphs, we need to parse inline formatting
          widgets.add(Text.rich(
            TextSpan(
              children: markdownTextSpan.parseInlineElements(element.content),
              style: defaultStyle,
            ),
          ));
          break;

        case MarkdownElementType.heading1:
        case MarkdownElementType.heading2:
        case MarkdownElementType.heading3:
        case MarkdownElementType.heading4:
        case MarkdownElementType.heading5:
        case MarkdownElementType.heading6:
          // Also parse inline formatting in headings
          final TextStyle headingStyle =
              element.type == MarkdownElementType.heading1
                  ? headingStyle1
                  : element.type == MarkdownElementType.heading2
                      ? headingStyle2
                      : element.type == MarkdownElementType.heading3
                          ? headingStyle3
                          : element.type == MarkdownElementType.heading4
                              ? headingStyle4
                              : element.type == MarkdownElementType.heading5
                                  ? headingStyle5
                                  : headingStyle6;

          widgets.add(Text.rich(
            TextSpan(
              children: markdownTextSpan.parseInlineElements(element.content),
              style: headingStyle,
            ),
          ));
          break;

        default:
          widgets.add(Text.rich(markdownTextSpan.createSpan(element)));
          break;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }
}
