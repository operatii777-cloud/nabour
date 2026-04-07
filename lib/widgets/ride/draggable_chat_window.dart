import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nabour_app/l10n/app_localizations.dart';
import 'package:nabour_app/models/chat_message_model.dart';
import 'package:nabour_app/services/firestore_service.dart';
import 'package:nabour_app/services/translation_service.dart';
import 'package:nabour_app/widgets/chat/whatsapp_message_bubble.dart';

class DraggableChatWindow extends StatefulWidget {
  final VoidCallback onClose;
  final String rideId;
  final String otherUserName;
  final String otherUserPhone;
  final Function(String) onCall;

  const DraggableChatWindow({
    super.key,
    required this.onClose,
    required this.rideId,
    required this.otherUserName,
    required this.otherUserPhone,
    required this.onCall,
  });

  @override
  State<DraggableChatWindow> createState() => _DraggableChatWindowState();
}

class _DraggableChatWindowState extends State<DraggableChatWindow> {
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  Offset _position = const Offset(50, 100);
  bool _isDragging = false;
  bool _isMinimized = false;

  void _editMessageInDraggable(String messageId, String currentText) {
    final editController = TextEditingController(text: currentText);
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Builder(
          builder: (context) {
            final l10n = AppLocalizations.of(context)!;
            return Text(l10n.editMessage);
          },
        ),
        content: TextField(
          controller: editController,
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)?.writeNewText ?? 'Scrie noul text...',
            border: const OutlineInputBorder(),
          ),
          maxLines: 3,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Builder(
              builder: (context) {
                final l10n = AppLocalizations.of(context)!;
                return Text(l10n.cancel);
              },
            ),
          ),
          TextButton(
            onPressed: () async {
              final newText = editController.text.trim();
              if (newText.isNotEmpty && newText != currentText) {
                final navigator = Navigator.of(dialogContext);
                final scaffoldMessenger = ScaffoldMessenger.of(dialogContext);
                
                try {
                  await FirestoreService().editChatMessage(widget.rideId, messageId, newText);
                  if (mounted) {
                    navigator.pop();
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Builder(
                          builder: (context) {
                            final l10n = AppLocalizations.of(context)!;
                            return Text(l10n.messageEditedSuccess);
                          },
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    navigator.pop();
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Builder(
                          builder: (context) {
                            final l10n = AppLocalizations.of(context)!;
                            return Text(l10n.errorEditingMessage(e.toString()));
                          },
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              } else {
                Navigator.pop(dialogContext);
              }
            },
            child: Builder(
              builder: (context) {
                final l10n = AppLocalizations.of(context)!;
                return Text(l10n.save);
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _translateMessage(String messageId, String text) async {
    try {
      // 1. Obține traducerea folosind noul TranslationService
      // Presupunem că știm limba sursă și țintă (RO <-> EN)
      // O variantă simplă: detectăm automat sau încercăm ambele
      final translationService = TranslationService();

      // Dacă textul are caractere românești, probabil e RO -> EN
      final isRomanian = text.toLowerCase().contains(RegExp(r'[ășțîâ]'));

      final translated = await translationService.translate(
        text,
        source: Locale(isRomanian ? 'ro' : 'en'),
        target: Locale(isRomanian ? 'en' : 'ro'),
      );
      
      if (translated != text) {
        // 2. Salvează în Firestore
        await FirestoreService().translateChatMessage(widget.rideId, messageId, translated);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Mesaj tradus cu succes!'),
              backgroundColor: Colors.blue,
              duration: Duration(seconds: 1),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Nu s-a găsit o traducere locală și Gemini e dezactivat.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Eroare la traducere: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          if (!_isMinimized) {
            setState(() {
              _position += details.delta;
              _isDragging = true;
            });
          }
        },
        onPanEnd: (details) {
          setState(() {
            _isDragging = false;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          width: _isMinimized ? 60 : MediaQuery.of(context).size.width * 0.8,
          height: _isMinimized ? 60 : MediaQuery.of(context).size.height * 0.6,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(_isMinimized ? 30 : 16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha((255 * 0.3).round()),
                blurRadius: _isDragging ? 20 : 10,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: _isMinimized ? _buildMinimizedView() : _buildFullChatView(),
        ),
      ),
    );
  }

  Widget _buildMinimizedView() {
    return GestureDetector(
      onTap: () => setState(() => _isMinimized = false),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(30),
        ),
        child: const Icon(
          Icons.chat_bubble,
          color: Colors.white,
          size: 30,
        ),
      ),
    );
  }

  Widget _buildFullChatView() {
    return Column(
      children: [
        // Header cu drag handle și controale
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Row(
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha((255 * 0.7).round()),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Chat cu ${widget.otherUserName}",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Butoane de control
              IconButton(
                onPressed: () => widget.onCall(widget.otherUserPhone),
                icon: Icon(
                  Icons.call,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
              IconButton(
                onPressed: () => setState(() => _isMinimized = true),
                icon: Icon(
                  Icons.minimize,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
              IconButton(
                onPressed: widget.onClose,
                icon: Icon(
                  Icons.close,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ],
          ),
        ),
        // Chat messages
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirestoreService().getChatMessages(widget.rideId),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final messages = snapshot.data!.docs;
              return ListView.builder(
                controller: _chatScrollController,
                reverse: true,
                padding: const EdgeInsets.all(8),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[index].data();
                  final isMe = msg['senderId'] == FirebaseAuth.instance.currentUser?.uid;
                  final timestamp = msg['timestamp'] as Timestamp?;
                  
                  // Convertim la ChatMessage pentru WhatsAppMessageBubble
                  try {
                    final chatMsg = ChatMessage.fromMap(msg);
                    return WhatsAppMessageBubble(
                      message: chatMsg,
                      isMe: isMe,
                      otherUserName: isMe ? null : widget.otherUserName,
                      onLongPress: isMe ? () => _editMessageInDraggable(messages[index].id, msg['text'] ?? msg['message'] ?? '') : null,
                      onTranslate: (notUsedId, text) => _translateMessage(messages[index].id, text),
                    );
                  } catch (e) {
                    // Fallback la vechiul format dacă conversia eșuează
                    return _buildMessageBubble(msg, isMe, timestamp, messages[index].id);
                  }
                },
              );
            },
          ),
        ),
        // Input field
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _chatController,
                  decoration: const InputDecoration(
                    hintText: "Scrie un mesaj...",
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.send, color: Theme.of(context).colorScheme.primary),
                onPressed: _sendMessage,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg, bool isMe, Timestamp? timestamp, String messageId) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: isMe ? () => _editMessage(messageId, msg['text']) : null,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.6),
          decoration: BoxDecoration(
            color: isMe ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(16),
            border: isMe ? Border.all(color: Theme.of(context).colorScheme.primary.withAlpha((255 * 0.3).round())) : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          msg['text'],
                          style: TextStyle(
                            color: isMe ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSecondaryContainer,
                          ),
                        ),
                        if (msg['isEdited'] == true) ...[
                          const SizedBox(height: 2),
                          Text(
                            '(editat)',
                            style: TextStyle(
                              fontSize: 10,
                              color: (isMe ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSecondaryContainer).withAlpha((255 * 0.6).round()),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (isMe) ...[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.edit,
                      size: 14,
                      color: (isMe ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSecondaryContainer).withAlpha((255 * 0.7).round()),
                    ),
                  ],
                ],
              ),
              if (timestamp != null)
                Text(
                  "${timestamp.toDate().hour.toString().padLeft(2, '0')}:${timestamp.toDate().minute.toString().padLeft(2, '0')}",
                  style: TextStyle(
                    color: (isMe ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSecondaryContainer).withAlpha((255 * 0.7).round()),
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _sendMessage() {
    final messageText = _chatController.text.trim();
    if (messageText.isEmpty) return;

    try {
      unawaited(FirestoreService().sendChatMessage(widget.rideId, messageText));
      _chatController.clear();
      HapticFeedback.lightImpact();
      FocusScope.of(context).unfocus();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Eroare la trimiterea mesajului: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _editMessage(String messageId, String currentText) {
    final editController = TextEditingController(text: currentText);
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Builder(
          builder: (context) {
            final l10n = AppLocalizations.of(context)!;
            return Text(l10n.editMessage);
          },
        ),
        content: TextField(
          controller: editController,
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)?.writeNewText ?? 'Scrie noul text...',
            border: const OutlineInputBorder(),
          ),
          maxLines: 3,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Builder(
              builder: (context) {
                final l10n = AppLocalizations.of(context)!;
                return Text(l10n.cancel);
              },
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final newText = editController.text.trim();
              
              if (newText.isNotEmpty && newText != currentText) {
                // ✅ FIX: Captează context-ul ÎNAINTE de await
                final navigator = Navigator.of(dialogContext);
                final scaffoldMessenger = ScaffoldMessenger.of(dialogContext);
                
                try {
                  await FirestoreService().editChatMessage(widget.rideId, messageId, newText);
                  
                  if (mounted) {
                    navigator.pop();
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Builder(
                          builder: (context) {
                            final l10n = AppLocalizations.of(context)!;
                            return Text(l10n.messageEditedSuccess);
                          },
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    navigator.pop();
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Builder(
                          builder: (context) {
                            final l10n = AppLocalizations.of(context)!;
                            return Text(l10n.errorEditingMessage(e.toString()));
                          },
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              } else {
                Navigator.pop(dialogContext);
              }
            },
            child: Builder(
              builder: (context) {
                final l10n = AppLocalizations.of(context)!;
                return Text(l10n.save);
              },
            ),
          ),
        ],
      ),
    );
  }
}
