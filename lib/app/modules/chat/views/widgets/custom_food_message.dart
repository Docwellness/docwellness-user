import 'package:cached_network_image/cached_network_image.dart';
import 'package:docwellness/app/config/app_config.dart';
import 'package:docwellness/app/models/message_model.dart';
import 'package:docwellness/main.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

/// Custom Food Message Widget for Patient App
/// Shows custom/off-plan food requests sent by patient
class CustomFoodMessage extends StatelessWidget {
  final MessageModel message;

  const CustomFoodMessage({super.key, required this.message});

  bool get isSentByMe => message.senderId == userId;

  @override
  Widget build(BuildContext context) {
    final metadata = message.metadata;
    final foodName = metadata?.foodName ?? metadata?.itemName ?? 'Custom Food';
    final description = metadata?.description ?? '';
    final rawImageUrl = metadata?.image ?? metadata?.imageUrl ?? '';
    final imageUrl = (rawImageUrl.isNotEmpty && rawImageUrl.startsWith('/'))
        ? '${AppConfig.baseUrl}$rawImageUrl'
        : rawImageUrl;
    final calories = metadata?.calories ?? 0;
    final protein = metadata?.protein ?? 0;
    final carbs = metadata?.carbs ?? 0;
    final fat = metadata?.fat ?? 0;
    final status = metadata?.status ?? 'pending';

    return Align(
      alignment: isSentByMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        constraints: const BoxConstraints(maxWidth: 300),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _getStatusColor(status).withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: _getStatusColor(status).withOpacity(0.12),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xffFFF7ED),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(14),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xffF97316).withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.fastfood,
                      size: 18,
                      color: Color(0xffEA580C),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Off-Plan Food',
                          style: GoogleFonts.roboto(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xff9A3412),
                          ),
                        ),
                        Text(
                          _formatTime(message.createdAt),
                          style: GoogleFonts.roboto(
                            fontSize: 10,
                            color: const Color(0xffC2410C),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(status),
                ],
              ),
            ),

            // Food image
            if (imageUrl.isNotEmpty)
              GestureDetector(
                onTap: () => _openFullScreenImage(imageUrl),
                child: ClipRRect(
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                      height: 140,
                      color: const Color(0xffFFF7ED),
                      child: const Icon(
                        Icons.fastfood,
                        size: 48,
                        color: Color(0xffF97316),
                      ),
                    ),
                  ),
                ),
              ),

            // Food details
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    foodName,
                    style: GoogleFonts.roboto(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xff1F2937),
                    ),
                  ),
                  if (description.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        description,
                        style: GoogleFonts.roboto(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                  const SizedBox(height: 12),

                  // Nutrition info
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xffF9FAFB),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildNutrientItem(
                          'Calories',
                          '$calories',
                          'kcal',
                          Colors.orange,
                        ),
                        _buildNutrientItem(
                          'Protein',
                          '$protein',
                          'g',
                          Colors.red,
                        ),
                        _buildNutrientItem(
                          'Carbs',
                          '$carbs',
                          'g',
                          Colors.green,
                        ),
                        _buildNutrientItem('Fat', '$fat', 'g', Colors.blue),
                      ],
                    ),
                  ),

                  // Status message
                  if (status != 'pending')
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              status == 'approved'
                                  ? Icons.check_circle
                                  : Icons.cancel,
                              size: 16,
                              color: _getStatusColor(status),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              status == 'approved'
                                  ? 'Your dietician approved this food'
                                  : 'Your dietician rejected this food',
                              style: GoogleFonts.roboto(
                                fontSize: 12,
                                color: _getStatusColor(status),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    String text;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'approved':
        bgColor = const Color(0xffDCFCE7);
        textColor = const Color(0xff16A34A);
        text = 'Approved';
        icon = Icons.check_circle;
        break;
      case 'rejected':
        bgColor = const Color(0xffFEE2E2);
        textColor = const Color(0xffDC2626);
        text = 'Rejected';
        icon = Icons.cancel;
        break;
      default:
        bgColor = const Color(0xffFEF3C7);
        textColor = const Color(0xffD97706);
        text = 'Pending';
        icon = Icons.hourglass_empty;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.roboto(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutrientItem(
    String label,
    String value,
    String unit,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.roboto(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(
          '$label ($unit)',
          style: GoogleFonts.roboto(fontSize: 9, color: Colors.grey[500]),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return const Color(0xff16A34A);
      case 'rejected':
        return const Color(0xffDC2626);
      default:
        return const Color(0xffF97316);
    }
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  void _openFullScreenImage(String imageUrl) {
    Get.to(
      () => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text(
            'Food Image',
            style: TextStyle(color: Colors.white),
          ),
        ),
        body: Center(
          child: InteractiveViewer(
            panEnabled: true,
            boundaryMargin: const EdgeInsets.all(20),
            minScale: 0.5,
            maxScale: 4,
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.contain,
              progressIndicatorBuilder: (context, url, progress) =>
                  const Center(
                child: CircularProgressIndicator(color: Color(0xffF97316)),
              ),
              errorWidget: (_, __, ___) => const Column(
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
            ),
          ),
        ),
      ),
    );
  }
}
