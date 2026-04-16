import 'package:flutter/material.dart';

class MapTopBar extends StatelessWidget {
  final int privateChatUnreadCount;
  final int friendRequestCount;
  final int cereriCount;
  final int chatBadgeCount;
  final bool isDriver;
  final String? userPhotoUrl;
  final String userAvatarEmoji;
  final VoidCallback onMenuTap;
  final VoidCallback onPoiTap;
  final VoidCallback onProfileTap;
  final VoidCallback onRefreshTap;
  final VoidCallback? onAiTap;
  final bool canShowAi;

  const MapTopBar({
    super.key,
    required this.privateChatUnreadCount,
    required this.friendRequestCount,
    required this.cereriCount,
    required this.chatBadgeCount,
    required this.isDriver,
    this.userPhotoUrl,
    required this.userAvatarEmoji,
    required this.onMenuTap,
    required this.onPoiTap,
    required this.onProfileTap,
    required this.onRefreshTap,
    this.onAiTap,
    this.canShowAi = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 28, 16, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Group: Menu + POI
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _TopButton(
                icon: Icons.menu_rounded,
                onTap: onMenuTap,
              ),
              const SizedBox(width: 10),
              _TopButton(
                icon: Icons.place_rounded,
                iconColor: const Color(0xFF0EA5E9),
                glowColor: const Color(0xFF0EA5E9).withValues(alpha: 0.2),
                borderColor: const Color(0xFF0EA5E9).withValues(alpha: 0.3),
                onTap: onPoiTap,
              ),
            ],
          ),
          
          const Spacer(),
          
          // Right Group: AI + Refresh + Profile
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (canShowAi && onAiTap != null) ...[
                _TopButton(
                  icon: Icons.mic_rounded, // Using mic as placeholder for AI button logic
                  iconColor: Colors.cyanAccent,
                  onTap: onAiTap!,
                ),
                const SizedBox(width: 8),
              ],
              _TopButton(
                icon: Icons.refresh_rounded,
                iconSize: 22,
                onTap: onRefreshTap,
              ),
              const SizedBox(width: 8),
              _ProfileButton(
                photoUrl: userPhotoUrl,
                avatarEmoji: userAvatarEmoji,
                badgeCount: friendRequestCount + privateChatUnreadCount + cereriCount + chatBadgeCount,
                onTap: onProfileTap,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TopButton extends StatelessWidget {
  final IconData icon;
  final double size;
  final double iconSize;
  final Color iconColor;
  final Color? glowColor;
  final Color? borderColor;
  final VoidCallback onTap;

  const _TopButton({
    required this.icon,
    this.size = 44,
    this.iconSize = 24,
    this.iconColor = Colors.white,
    this.glowColor,
    this.borderColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.black87,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: glowColor ?? Colors.white.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: borderColor ?? Colors.white12,
            width: 1,
          ),
        ),
        child: Icon(icon, color: iconColor, size: iconSize),
      ),
    );
  }
}

class _ProfileButton extends StatelessWidget {
  final String? photoUrl;
  final String avatarEmoji;
  final int badgeCount;
  final VoidCallback onTap;

  const _ProfileButton({
    this.photoUrl,
    required this.avatarEmoji,
    required this.badgeCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoUrl != null && photoUrl!.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: ClipOval(
              child: hasPhoto
                  ? Image.network(
                      photoUrl!,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _EmojiAvatar(emoji: avatarEmoji),
                    )
                  : _EmojiAvatar(emoji: avatarEmoji),
            ),
          ),
          if (badgeCount > 0)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 18,
                  minHeight: 18,
                ),
                child: Text(
                  badgeCount > 99 ? '99+' : '$badgeCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmojiAvatar extends StatelessWidget {
  final String emoji;
  const _EmojiAvatar({required this.emoji});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        emoji,
        style: const TextStyle(fontSize: 24),
      ),
    );
  }
}
