import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:docwellness/app/models/conversation_model.dart';

class ConversationTile extends StatelessWidget {
  final ConversationModel conversation;
  final VoidCallback onTap;

  const ConversationTile({
    super.key,
    required this.conversation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xffFDF2FA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xffFCE7F6)),
        ),
        margin: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            _buildAvatar(),
            const SizedBox(width: 12),
            Expanded(child: _buildContent()),
            _buildTrailing(),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Stack(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: const Color(0xffFCE7F6),
          backgroundImage: conversation.displayImage != null
              ? CachedNetworkImageProvider(conversation.displayImage!)
              : null,
          child: conversation.displayImage == null
              ? Text(
                  conversation.displayName.isNotEmpty
                      ? conversation.displayName[0].toUpperCase()
                      : '?',
                  style: GoogleFonts.roboto(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xff851653),
                  ),
                )
              : null,
        ),
        // Online indicator
        if (conversation.isOnline)
          Positioned(
            right: 2,
            bottom: 2,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          conversation.displayName,
          style: GoogleFonts.roboto(
            fontSize: 16,
            fontWeight: conversation.unreadCount > 0
                ? FontWeight.w600
                : FontWeight.w500,
            color: const Color(0xff1F2A37),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          conversation.lastMessage?.content ?? 'Start a conversation',
          style: GoogleFonts.roboto(
            fontSize: 14,
            fontWeight: conversation.unreadCount > 0
                ? FontWeight.w500
                : FontWeight.w400,
            color: conversation.unreadCount > 0
                ? const Color(0xff1F2A37)
                : const Color(0xff6B7280),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildTrailing() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          conversation.lastMessage?.timeAgo ?? '',
          style: GoogleFonts.roboto(
            fontSize: 12,
            color: conversation.unreadCount > 0
                ? const Color(0xff851653)
                : const Color(0xff9CA3AF),
          ),
        ),
        const SizedBox(height: 6),
        if (conversation.unreadCount > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xff851653),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              conversation.unreadCount > 99
                  ? '99+'
                  : conversation.unreadCount.toString(),
              style: GoogleFonts.roboto(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          )
        else
          const SizedBox(height: 20),
      ],
    );
  }
}
