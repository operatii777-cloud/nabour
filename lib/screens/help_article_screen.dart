import 'package:flutter/material.dart';

// Un ecran generic care afișează un titlu și o listă de widget-uri ca și conținut.
class HelpArticleScreen extends StatelessWidget {
  final String articleTitle;
  final List<Widget> contentWidgets;

  const HelpArticleScreen({
    super.key,
    required this.articleTitle,
    required this.contentWidgets,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(articleTitle),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: contentWidgets,
        ),
      ),
    );
  }
}
