import 'package:flutter/material.dart';
import 'package:nabour_app/core/haptics/haptic_service.dart';
import 'smart_suggestion_model.dart';

/// Row de sugestii rapide afișat sub search bar pe MapScreen.
/// Tap pe sugestie → completează direct destinația.
class SmartSuggestionsRow extends StatelessWidget {
  final List<SmartSuggestion> suggestions;
  final void Function(SmartSuggestion suggestion) onSuggestionTap;

  const SmartSuggestionsRow({
    super.key,
    required this.suggestions,
    required this.onSuggestionTap,
  });

  IconData _iconFor(SmartSuggestionType type) {
    switch (type) {
      case SmartSuggestionType.home:
        return Icons.home_rounded;
      case SmartSuggestionType.work:
        return Icons.work_rounded;
      case SmartSuggestionType.frequent:
        return Icons.history_rounded;
      case SmartSuggestionType.timeBased:
        return Icons.schedule_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: suggestions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final s = suggestions[i];
          return GestureDetector(
            onTap: () {
              HapticService.instance.light();
              onSuggestionTap(s);
            },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _iconFor(s.type),
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    s.label,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
