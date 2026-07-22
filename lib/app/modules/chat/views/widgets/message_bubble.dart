import 'package:cached_network_image/cached_network_image.dart';
import 'package:docwellness/app/models/message_model.dart';
import 'package:docwellness/main.dart';
import 'package:docwellness/utils/common_widgets/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isImage;
  final String? avatarUrl;
  final VoidCallback? onReply;
  final VoidCallback? onReplyPreviewTap;
  final bool isHighlighted;

  const MessageBubble({
    super.key,
    required this.message,
    this.isImage = false,
    this.avatarUrl,
    this.onReply,
    this.onReplyPreviewTap,
    this.isHighlighted = false,
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
            Flexible(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isHighlighted
                      ? const Color(0xffFFE082)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: _buildBubble(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReplyPreview() {
    final reply = message.replyTo;
    if (reply == null) return const SizedBox.shrink();
    return GestureDetector(
      onTap: onReplyPreviewTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
          border: const Border(
            left: BorderSide(color: Color(0xff851653), width: 3),
          ),
        ),
        child: Text(
          reply.messageType == 'image' ? '📷 Photo' : reply.message,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.roboto(fontSize: 12, color: Colors.black54),
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
                  showAppToast(
                    Get.overlayContext!,
                    message: 'Message copied to clipboard',
                    type: AppToastType.success,
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
    if (message.messageType == MessageType.doctorRecommendation) {
      return _buildRecommendationBubble();
    }
    if (isImage) {
      return _buildImageBubble();
    }
    return _buildTextBubble();
  }

  // Mirrors the dietician app's DoctorRecommendationBubble styling so a
  // recommendation looks the same on both ends instead of falling back to
  // the plain text bubble it used to render as here.
  Widget _buildRecommendationBubble() {
    final recommendationText =
        message.metadata?.recommendationText ?? message.content;
    final category = message.metadata?.recommendationCategory ?? 'general';

    return Container(
      constraints: const BoxConstraints(maxWidth: 300),
      decoration: BoxDecoration(
        color: const Color(0xffF0FDF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffBBF7D0), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xff10B981).withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xff059669), Color(0xff10B981)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(15),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.medical_services_outlined,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Recommendation',
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _recommendationCategoryLabel(category),
                    style: GoogleFonts.roboto(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Body
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  _recommendationCategoryIcon(category),
                  size: 18,
                  color: const Color(0xff059669),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    recommendationText,
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      color: const Color(0xff1F2A37),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Footer
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            child: Text(
              _formatTime(message.createdAt),
              style: GoogleFonts.roboto(
                fontSize: 11,
                color: const Color(0xff9CA3AF),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _recommendationCategoryLabel(String category) {
    switch (category) {
      case 'diet':
        return 'DIET';
      case 'exercise':
        return 'EXERCISE';
      case 'lifestyle':
        return 'LIFESTYLE';
      default:
        return 'GENERAL';
    }
  }

  IconData _recommendationCategoryIcon(String category) {
    switch (category) {
      case 'diet':
        return Icons.restaurant_outlined;
      case 'exercise':
        return Icons.fitness_center_outlined;
      case 'lifestyle':
        return Icons.self_improvement_outlined;
      default:
        return Icons.lightbulb_outline;
    }
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
          _buildReplyPreview(),
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
    final imageUrl = message.attachment ?? message.content;
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
            if (message.replyTo != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(6, 6, 6, 0),
                child: _buildReplyPreview(),
              ),
            GestureDetector(
              onTap: () => _openFullScreenImage(imageUrl),
              child: CachedNetworkImage(
                imageUrl: imageUrl,
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

  void _openFullScreenImage(String imageUrl) {
    final isNetwork =
        imageUrl.startsWith('http://') ||
        imageUrl.startsWith('https://') ||
        imageUrl.startsWith('blob:');
    Get.to(
      () => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text('Image', style: TextStyle(color: Colors.white)),
        ),
        body: Center(
          child: InteractiveViewer(
            panEnabled: true,
            boundaryMargin: const EdgeInsets.all(20),
            minScale: 0.5,
            maxScale: 4,
            child: isNetwork
                ? Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xff851653),
                        ),
                      );
                    },
                    errorBuilder: (_, __, ___) => const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, color: Colors.white, size: 48),
                        SizedBox(height: 16),
                        Text(
                          'Failed to load image',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  )
                : const Icon(Icons.error_outline, color: Colors.white, size: 48),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
