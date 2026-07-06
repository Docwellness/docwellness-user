import 'package:docwellness/app/models/message_model.dart';
import 'package:docwellness/main.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Doctor Note Card Widget for Patient App
/// Shows doctor notes sent by the dietician in chat
class DoctorNoteMessage extends StatelessWidget {
  final MessageModel message;

  const DoctorNoteMessage({super.key, required this.message});

  bool get isSentByMe => message.senderId == userId;

  @override
  Widget build(BuildContext context) {
    final metadata = message.metadata;
    final noteContent = message.content;

    // Parse note date from metadata
    String formattedDate = '';
    if (metadata?.noteDate != null) {
      final dt = DateTime.tryParse(metadata!.noteDate!);
      if (dt != null) {
        formattedDate =
            '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
      }
    }
    if (formattedDate.isEmpty) {
      formattedDate =
          '${message.createdAt.day.toString().padLeft(2, '0')}/${message.createdAt.month.toString().padLeft(2, '0')}/${message.createdAt.year}';
    }

    return Align(
      alignment: isSentByMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        constraints: const BoxConstraints(maxWidth: 300),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xffFDF2FA), Color(0xffFCE7F6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xff9F1561).withOpacity(0.12),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xff9F1561).withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xff9F1561).withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.note_alt_outlined,
                      size: 20,
                      color: Color(0xff9F1561),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Doctor's Note",
                          style: GoogleFonts.roboto(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xff530630),
                          ),
                        ),
                        Text(
                          _formatTime(message.createdAt),
                          style: GoogleFonts.roboto(
                            fontSize: 11,
                            color: const Color(0xff851653),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xffFCE7F6),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xffEF45B2)),
                    ),
                    child: Text(
                      formattedDate,
                      style: GoogleFonts.roboto(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xff851653),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Note Content
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Text(
                noteContent,
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xff1F2A37),
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0
        ? 12
        : hour > 12
        ? hour - 12
        : hour;
    return '$displayHour:$minute $period';
  }
}
