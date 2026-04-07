import 'package:flutter/material.dart';
import 'package:nabour_app/content/help_content.dart'; // Importăm conținutul
import 'package:nabour_app/screens/help_article_screen.dart'; // Importăm noul ecran de articol

class HelpCategoryScreen extends StatelessWidget {
  final String categoryTitle;
  final Map<String, IconData> topics;

  const HelpCategoryScreen({
    super.key,
    required this.categoryTitle,
    required this.topics,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(categoryTitle),
      ),
      body: ListView.builder(
        itemCount: topics.length,
        itemBuilder: (context, index) {
          final String title = topics.keys.elementAt(index);
          final IconData icon = topics.values.elementAt(index);
          
          // Obținem conținutul articolului din "biblioteca" noastră
          // Dacă nu găsim conținut, trimitem un text implicit.
          final List<Widget> content = HelpContent.articles[title] ?? 
              [Text('Conținutul pentru "$title" va fi adăugat în curând.')];

          return ListTile(
            leading: Icon(icon, color: Colors.grey.shade700),
            title: Text(title),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  // Navigăm la ecranul de articol, trimițându-i titlul și conținutul
                  builder: (ctx) => HelpArticleScreen(
                    articleTitle: title,
                    contentWidgets: content,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
