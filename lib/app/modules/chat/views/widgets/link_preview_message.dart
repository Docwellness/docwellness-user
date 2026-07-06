import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

class LinkPreviewMessage extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String subtitle;
  final String caption;
  final DateTime timestamp;
  final bool isSentByMe;
  final VoidCallback? onTap;

  const LinkPreviewMessage({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.subtitle,
    this.caption = '',
    required this.timestamp,
    this.isSentByMe = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: isSentByMe ? 60 : 0,
        right: isSentByMe ? 0 : 60,
        top: 6,
        bottom: 6,
      ),
      child: Row(
        mainAxisAlignment:
            isSentByMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isSentByMe) _buildAvatar(),
          if (!isSentByMe) const SizedBox(width: 8),
          Flexible(child: _buildCard(context)),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return CircleAvatar(
      radius: 18,
      backgroundColor: const Color(0xffFCE7F6),
      child: ClipOval(
        child: Image.asset(
          'assets/images/avatar_dietician.png',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Text(
            'D',
            style: GoogleFonts.roboto(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xff851653),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xffE5E7EB), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 160,
                  color: const Color(0xffF3F4F6),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xff851653),
                      strokeWidth: 2,
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 160,
                  color: const Color(0xffF3F4F6),
                  child: const Icon(
                    Icons.image_outlined,
                    color: Color(0xff9CA3AF),
                    size: 48,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.roboto(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xff1F2A37),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.roboto(
                      fontSize: 13,
                      color: const Color(0xff6B7280),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (caption.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xffFCE7F6),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    caption,
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      color: const Color(0xff851653),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
