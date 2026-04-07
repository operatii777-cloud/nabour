// lib/widgets/theme_toggle_button.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nabour_app/theme/theme_provider.dart';

class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    // Folosim un Consumer pentru a accesa ThemeProvider și a reconstrui widget-ul la schimbare
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        // Container-ul exterior adaugă stilul de card (culoare, umbră, etc.)
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          // IconButton este butonul efectiv
          child: IconButton(
            onPressed: () {
              // La apăsare, apelăm funcția toggleTheme din provider
              themeProvider.toggleTheme();
            },
            // AnimatedSwitcher gestionează animația de tranziție între iconițe
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return ScaleTransition(scale: animation, child: child);
              },
              // Iconița se schimbă în funcție de starea temei (dark/light)
              child: Icon(
                themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                // Cheia este esențială pentru ca AnimatedSwitcher să știe că widget-ul s-a schimbat
                key: ValueKey<bool>(themeProvider.isDarkMode),
                color: themeProvider.isDarkMode ? Colors.yellow.shade700 : Colors.indigo,
                size: 24,
              ),
            ),
            tooltip: themeProvider.isDarkMode ? 'Schimbă la tema de zi' : 'Schimbă la tema de noapte',
          ),
        );
      },
    );
  }
}