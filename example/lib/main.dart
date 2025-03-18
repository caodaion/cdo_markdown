import 'package:flutter/material.dart';
import 'package:cdo_markdown/cdo_markdown.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CDO Markdown Example',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const MarkdownExampleScreen(),
    );
  }
}

class MarkdownExampleScreen extends StatefulWidget {
  const MarkdownExampleScreen({Key? key}) : super(key: key);

  @override
  State<MarkdownExampleScreen> createState() => _MarkdownExampleScreenState();
}

class _MarkdownExampleScreenState extends State<MarkdownExampleScreen> {
  final String _markdownExample = '''
# CDO Markdown Example

## Headings
### Level 3 heading
#### Level 4 heading
##### Level 5 heading
###### Level 6 heading

## Text Formatting

**This text is bold**
*This text is italic*
This is regular text

## Links
[Visit Cao Dai ON](https://caodaion.org)

## Code
Inline `code` example

```
// Code block example
void main() {
  print('Hello, Markdown!');
}
```

## Lists

### Bullet List
- Item 1
- Item 2
- Item 3

### Ordered List
1. First item
2. Second item
3. Third item

## Blockquotes
> This is a blockquote.
> It can span multiple lines.
''';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CDO Markdown Example')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CDOMarkdown(
              data: _markdownExample,
              // Customize styles (optional)
              h1Style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
              linkColor: Colors.green,
              onLinkTap: (url) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Link tapped: $url')));
              },
            ),
            const SizedBox(height: 32),
            const Text(
              'Example of customized styles:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            CDOMarkdown(
              data: '# Custom Heading\n**Custom bold**\n*Custom italic*',
              h1Style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Colors.purple,
                letterSpacing: 1.2,
              ),
              boldStyle: const TextStyle(
                fontWeight: FontWeight.w900,
                color: Colors.red,
                fontSize: 18,
              ),
              italicStyle: const TextStyle(
                fontStyle: FontStyle.italic,
                color: Colors.teal,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
