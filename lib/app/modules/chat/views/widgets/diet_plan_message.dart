import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:docwellness/app/models/message_model.dart';
import 'package:docwellness/main.dart';

/// Diet Plan Card Widget for Patient App
/// Shows weekly diet plan sent by dietician
class DietPlanMessage extends StatelessWidget {
  final MessageModel message;

  const DietPlanMessage({super.key, required this.message});

  bool get isSentByMe => message.senderId == userId;

  @override
  Widget build(BuildContext context) {
    final metadata = message.metadata;
    final meals = metadata?.meals ?? [];
    final dayName = metadata?.dayName ?? 'Today';
    final weekDay = metadata?.weekDay ?? '';

    return Align(
      alignment: isSentByMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        constraints: const BoxConstraints(maxWidth: 320),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header with gradient
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xffEC4899),
                    const Color(0xffDB2777),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.restaurant_menu,
                      size: 22,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Diet Plan',
                          style: GoogleFonts.roboto(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '$dayName${weekDay.isNotEmpty ? ' - $weekDay' : ''}',
                          style: GoogleFonts.roboto(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${meals.length} meals',
                      style: GoogleFonts.roboto(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Meals list
            if (meals.isNotEmpty)
              ...meals.asMap().entries.map((entry) {
                final index = entry.key;
                final meal = entry.value as Map<String, dynamic>;
                return _buildMealItem(meal, index == meals.length - 1);
              }),

            // Total macros footer
            _buildMacrosFooter(metadata),

            // Timestamp
            Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    _formatTime(message.createdAt),
                    style: GoogleFonts.roboto(
                      fontSize: 11,
                      color: Colors.grey[500],
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

  Widget _buildMealItem(Map<String, dynamic> meal, bool isLast) {
    final mealName = meal['name'] ?? meal['mealName'] ?? 'Meal';
    final description = meal['description'] ?? '';
    final imageUrl = meal['image'] ?? meal['imageUrl'] ?? '';
    final servingTime = meal['servingTime'] ?? '';
    final calories = meal['calories'] ?? 0;
    final portion = meal['portion'] ?? meal['servingSize'] ?? '';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: !isLast
            ? Border(bottom: BorderSide(color: Colors.grey[200]!, width: 1))
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Meal image
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: imageUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: imageUrl,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => _buildPlaceholderImage(),
                  )
                : _buildPlaceholderImage(),
          ),
          const SizedBox(width: 12),

          // Meal details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Serving time badge
                if (servingTime.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    margin: const EdgeInsets.only(bottom: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xffFCE7F3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      servingTime,
                      style: GoogleFonts.roboto(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xffDB2777),
                      ),
                    ),
                  ),

                // Meal name
                Text(
                  mealName,
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xff1F2937),
                  ),
                ),

                // Description
                if (description.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
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

                // Portion & Calories row
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    children: [
                      if (portion.isNotEmpty) ...[
                        Icon(Icons.scale, size: 12, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          portion,
                          style: GoogleFonts.roboto(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Icon(Icons.local_fire_department, size: 12, color: Colors.orange[400]),
                      const SizedBox(width: 4),
                      Text(
                        '$calories kcal',
                        style: GoogleFonts.roboto(
                          fontSize: 11,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: const Color(0xffFCE7F3),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(
        Icons.restaurant,
        color: Color(0xffEC4899),
        size: 24,
      ),
    );
  }

  Widget _buildMacrosFooter(MessageMetadata? metadata) {
    final totalCalories = metadata?.totalCalories ?? metadata?.calories ?? 0;
    final totalProtein = metadata?.totalProtein ?? metadata?.protein ?? 0;
    final totalCarbs = metadata?.totalCarbs ?? metadata?.carbs ?? 0;
    final totalFat = metadata?.totalFat ?? metadata?.fat ?? 0;

    if (totalCalories == 0 && totalProtein == 0 && totalCarbs == 0 && totalFat == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey[200]!, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMacroItem(Icons.local_fire_department, '$totalCalories', 'kcal', Colors.orange),
          _buildMacroItem(Icons.fitness_center, '${totalProtein}g', 'Protein', Colors.red),
          _buildMacroItem(Icons.grain, '${totalCarbs}g', 'Carbs', Colors.green),
          _buildMacroItem(Icons.water_drop, '${totalFat}g', 'Fat', Colors.blue),
        ],
      ),
    );
  }

  Widget _buildMacroItem(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.roboto(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: const Color(0xff1F2937),
          ),
        ),
        Text(
          label,
          style: GoogleFonts.roboto(
            fontSize: 10,
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }
}
