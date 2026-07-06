import 'package:cached_network_image/cached_network_image.dart';
import 'package:docwellness/app/models/message_model.dart';
import 'package:docwellness/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isImage;
  final String? avatarUrl;
  final VoidCallback? onReply;

  const MessageBubble({
    super.key,
    required this.message,
    this.isImage = false,
    this.avatarUrl,
    this.onReply,
  });

  bool get isSentByMe => message.senderId == userId;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () => _showMessageOptions(context),
      child: Padding(
        padding: EdgeInsets.only(
          left: isSentByMe ? 60 : 0,
          right: isSentByMe ? 0 : 60,
          top: 4,
          bottom: 4,
        ),
        child: Row(
          mainAxisAlignment: isSentByMe
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isSentByMe) _buildAvatar(),
            if (!isSentByMe) const SizedBox(width: 8),
            Flexible(child: _buildBubble()),
          ],
        ),
      ),
    );
  }

  void _showMessageOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.reply, color: Color(0xff851653)),
              title: Text('Reply', style: GoogleFonts.roboto()),
              onTap: () {
                Navigator.pop(context);
                onReply?.call();
              },
            ),
            if (!isImage)
              ListTile(
                leading: const Icon(Icons.copy, color: Color(0xff851653)),
                title: Text('Copy', style: GoogleFonts.roboto()),
                onTap: () {
                  Navigator.pop(context);
                  Clipboard.setData(ClipboardData(text: message.content));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Message copied to clipboard'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ListTile(
              leading: const Icon(Icons.share, color: Color(0xff851653)),
              title: Text('Share', style: GoogleFonts.roboto()),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return CircleAvatar(
      radius: 18,
      backgroundColor: const Color(0xffFCE7F6),
      backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
      child: avatarUrl == null
          ? ClipOval(
              child: Image.asset(
                'assets/images/avatar_dietician.png',
                fit: BoxFit.cover,
                width: 36,
                height: 36,
                errorBuilder: (context, error, stackTrace) => Text(
                  'D',
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xff851653),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildBubble() {
    if (isImage) {
      return _buildImageBubble();
    }
    return _buildTextBubble();
  }

  Widget _buildTextBubble() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isSentByMe ? const Color(0xffFCE7F6) : const Color(0xffFDF2FA),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(isSentByMe ? 18 : 4),
          bottomRight: Radius.circular(isSentByMe ? 4 : 18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message.content,
            style: GoogleFonts.roboto(
              fontSize: 15,
              color: const Color(0xff851653),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _formatTime(message.createdAt),
                style: GoogleFonts.roboto(
                  fontSize: 11,
                  color: const Color(0xff9CA3AF),
                ),
              ),
              if (isSentByMe) ...[
                const SizedBox(width: 4),
                Icon(
                  message.isRead ? Icons.done_all : Icons.done,
                  size: 14,
                  color: message.isRead ? Colors.blue : const Color(0xff9CA3AF),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImageBubble() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 250),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xffFCE7F6), width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            CachedNetworkImage(
              imageUrl: message.attachment ?? message.content,
              placeholder: (context, url) => Container(
                height: 150,
                color: const Color(0xffFDF2FA),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xff851653),
                    strokeWidth: 2,
                  ),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                height: 150,
                color: const Color(0xffFDF2FA),
                child: const Icon(Icons.error, color: Colors.red),
              ),
              fit: BoxFit.cover,
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              color: isSentByMe
                  ? const Color(0xffFCE7F6)
                  : const Color(0xffFDF2FA),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatTime(message.createdAt),
                    style: GoogleFonts.roboto(
                      fontSize: 11,
                      color: const Color(0xff9CA3AF),
                    ),
                  ),
                  if (isSentByMe) ...[
                    const SizedBox(width: 4),
                    Icon(
                      message.isRead ? Icons.done_all : Icons.done,
                      size: 14,
                      color: message.isRead
                          ? Colors.blue
                          : const Color(0xff9CA3AF),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
