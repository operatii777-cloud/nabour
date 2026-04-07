/// 🔍 WIDGET PENTRU AFIȘAREA CONSOLEI DE DEBUG
/// 
/// Acest widget afișează mesajele de debug, erori și warning-uri
/// într-un overlay pentru monitorizare în timp real.
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nabour_app/services/debug_console_monitor.dart';

class DebugConsoleWidget extends StatefulWidget {
  const DebugConsoleWidget({super.key});

  @override
  State<DebugConsoleWidget> createState() => _DebugConsoleWidgetState();
}

class _DebugConsoleWidgetState extends State<DebugConsoleWidget> {
  final DebugConsoleMonitor _monitor = DebugConsoleMonitor();
  Timer? _refreshTimer;
  bool _isExpanded = false;
  String _filter = 'all'; // all, errors, warnings

  @override
  void initState() {
    super.initState();
    // Refresh la fiecare 2 secunde
    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();
    
    final stats = _monitor.getStatistics();
    final hasIssues = _monitor.hasCriticalIssues();
    final recentErrors = stats['recent_errors_1min'] as int;
    final recentWarnings = stats['recent_warnings_1min'] as int;
    
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: GestureDetector(
        onTap: () => setState(() => _isExpanded = !_isExpanded),
        child: Container(
          height: _isExpanded ? 300 : 60,
          decoration: BoxDecoration(
            color: hasIssues ? Colors.red.shade900 : Colors.grey.shade900,
            border: Border(
              top: BorderSide(
                color: hasIssues ? Colors.red : Colors.grey.shade700,
                width: 2,
              ),
            ),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Icon(
                      hasIssues ? Icons.error : Icons.info_outline,
                      color: hasIssues ? Colors.red : Colors.white70,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Debug Console',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(),
                    if (recentErrors > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$recentErrors',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    if (recentWarnings > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$recentWarnings',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(width: 8),
                    Icon(
                      _isExpanded ? Icons.expand_more : Icons.expand_less,
                      color: Colors.white70,
                    ),
                  ],
                ),
              ),
              // Content (dacă este expandat)
              if (_isExpanded)
                Expanded(
                  child: Container(
                    color: Colors.black87,
                    child: Column(
                      children: [
                        // Filtre
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Row(
                            children: [
                              _buildFilterButton('all', 'Toate'),
                              const SizedBox(width: 8),
                              _buildFilterButton('errors', 'Erori'),
                              const SizedBox(width: 8),
                              _buildFilterButton('warnings', 'Warning-uri'),
                              const Spacer(),
                              TextButton(
                                onPressed: () {
                                  _monitor.clear();
                                  setState(() {});
                                },
                                child: const Text('Șterge', style: TextStyle(color: Colors.white70)),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1, color: Colors.grey),
                        // Mesaje
                        Expanded(
                          child: _buildMessagesList(),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterButton(String filter, String label) {
    final isSelected = _filter == filter;
    return GestureDetector(
      onTap: () => setState(() => _filter = filter),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.grey.shade800,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildMessagesList() {
    List<DebugMessage> messages;
    
    switch (_filter) {
      case 'errors':
        messages = _monitor.getErrors(limit: 50);
        break;
      case 'warnings':
        messages = _monitor.getWarnings(limit: 50);
        break;
      default:
        messages = _monitor.getMessages(limit: 50);
    }
    
    if (messages.isEmpty) {
      return const Center(
        child: Text(
          'Nu există mesaje',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }
    
    return ListView.builder(
      reverse: true, // Cele mai recente în sus
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[messages.length - 1 - index];
        return _buildMessageItem(message);
      },
    );
  }

  Widget _buildMessageItem(DebugMessage message) {
    Color color;
    IconData icon;
    
    switch (message.type) {
      case DebugMessageType.error:
        color = Colors.red;
        icon = Icons.error;
        break;
      case DebugMessageType.warning:
        color = Colors.orange;
        icon = Icons.warning;
        break;
      case DebugMessageType.success:
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case DebugMessageType.info:
        color = Colors.blue;
        icon = Icons.info;
        break;
      default:
        color = Colors.grey;
        icon = Icons.bug_report;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade800, width: 0.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                if (message.source != null)
                  Text(
                    'Source: ${message.source}',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 9,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            '${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}:${message.timestamp.second.toString().padLeft(2, '0')}',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
}

