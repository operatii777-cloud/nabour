import 'package:flutter/material.dart';
import 'package:nabour_app/services/contacts_service.dart';

/// Ecran pentru gestionarea vizibilității preferențiale.
/// Userul selectează care contacte din agendă NU îl pot vedea pe hartă.
/// Returnează [Set<String>] de UID-uri excluse la Navigator.pop().
class VisibilityExclusionsScreen extends StatefulWidget {
  final List<ContactAppUser> contacts;
  final Set<String> excludedUids;

  const VisibilityExclusionsScreen({
    super.key,
    required this.contacts,
    required this.excludedUids,
  });

  @override
  State<VisibilityExclusionsScreen> createState() =>
      _VisibilityExclusionsScreenState();
}

class _VisibilityExclusionsScreenState
    extends State<VisibilityExclusionsScreen> {
  late Set<String> _excluded;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _excluded = Set.from(widget.excludedUids);
  }

  List<ContactAppUser> get _filtered {
    if (_search.isEmpty) return widget.contacts;
    final q = _search.toLowerCase();
    return widget.contacts
        .where((c) =>
            c.displayName.toLowerCase().contains(q) ||
            c.phoneNumber.contains(q))
        .toList();
  }

  void _save() => Navigator.of(context).pop(_excluded);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final excludedCount = _excluded.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exclude vizibilitate pentru...'),
        actions: [
          TextButton(
            onPressed: _save,
            child: Text(
              'Salvează',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Descriere
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withAlpha(80),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.visibility_off_rounded,
                    color: theme.colorScheme.primary, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Contactele bifate NU te vor vedea pe hartă, '
                    'chiar dacă ești vizibil vecinilor.',
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onSurface.withAlpha(200),
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (excludedCount > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Row(
                children: [
                  Icon(Icons.block_rounded,
                      size: 15,
                      color: theme.colorScheme.error.withAlpha(180)),
                  const SizedBox(width: 6),
                  Text(
                    '$excludedCount contact${excludedCount == 1 ? '' : 'e'} exclus${excludedCount == 1 ? '' : 'e'}',
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.error.withAlpha(200),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => setState(() => _excluded.clear()),
                    child: const Text('Șterge toate', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),

          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Caută contact...',
                prefixIcon: const Icon(Icons.search, size: 20),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest,
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),

          // List
          Expanded(
            child: widget.contacts.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.contacts_outlined,
                              size: 56,
                              color: theme.colorScheme.onSurface.withAlpha(80)),
                          const SizedBox(height: 16),
                          Text(
                            'Niciun contact din agendă\nnu folosește aplicația.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color:
                                  theme.colorScheme.onSurface.withAlpha(140),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : _filtered.isEmpty
                    ? const Center(child: Text('Niciun rezultat.'))
                    : ListView.builder(
                        itemCount: _filtered.length,
                        itemBuilder: (context, i) {
                          final contact = _filtered[i];
                          final isExcluded = _excluded.contains(contact.uid);
                          final initial = contact.displayName.isNotEmpty
                              ? contact.displayName[0].toUpperCase()
                              : '?';
                          return CheckboxListTile(
                            value: isExcluded,
                            onChanged: (val) {
                              setState(() {
                                if (val == true) {
                                  _excluded.add(contact.uid);
                                } else {
                                  _excluded.remove(contact.uid);
                                }
                              });
                            },
                            secondary: CircleAvatar(
                              backgroundColor: isExcluded
                                  ? theme.colorScheme.errorContainer
                                  : theme.colorScheme.primaryContainer,
                              child: Text(
                                initial,
                                style: TextStyle(
                                  color: isExcluded
                                      ? theme.colorScheme.onErrorContainer
                                      : theme.colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              contact.displayName,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: isExcluded
                                    ? theme.colorScheme.error
                                    : null,
                              ),
                            ),
                            subtitle: Text(
                              contact.phoneNumber,
                              style: const TextStyle(fontSize: 12),
                            ),
                            activeColor: theme.colorScheme.error,
                            checkColor: Colors.white,
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
