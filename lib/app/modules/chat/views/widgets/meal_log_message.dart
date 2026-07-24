import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:docwellness/app/models/message_model.dart';
import 'package:docwellness/main.dart';

class MealLogMessage extends StatelessWidget {
  final MessageModel message;
  final String? avatarUrl;

  const MealLogMessage({
    super.key,
    required this.message,
    this.avatarUrl,
  });

  bool get isSentByMe => message.senderId == userId;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: isSentByMe ? 40 : 0,
        right: isSentByMe ? 0 : 40,
        top: 8,
        bottom: 8,
      ),
      child: Row(
        mainAxisAlignment:
            isSentByMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isSentByMe) _buildAvatar(),
          if (!isSentByMe) const SizedBox(width: 8),
          Flexible(child: _buildMealLogCard()),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return CircleAvatar(
      radius: 18,
      backgroundColor: const Color(0xffFCE7F6),
      backgroundImage: avatarUrl != null
          ? CachedNetworkImageProvider(avatarUrl!)
          : null,
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

  Widget _buildMealLogCard() {
    final metadata = message.metadata;

    // A free-text "meal note" (photo + description sent from the meal note
    // dialog) has no real macro data - it always fell back to the 25g/25g
    // placeholder values below because they're unset. Show the note text
    // instead of fabricated nutrition numbers.
    if (metadata?.action == 'note') {
      return _buildNoteCard();
    }

    return _buildLoggedMealCard();
  }

  Widget _buildNoteCard() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 280),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (message.attachment != null && message.attachment!.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              child: CachedNetworkImage(
                imageUrl: message.attachment!,
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
                  height: 100,
                  color: const Color(0xffF3F4F6),
                  child: const Icon(Icons.restaurant, color: Color(0xff851653), size: 40),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.note_alt_outlined, size: 16, color: Color(0xff851653)),
                    const SizedBox(width: 6),
                    Text(
                      'Meal Note',
                      style: GoogleFonts.roboto(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xff851653),
                      ),
                    ),
                  ],
                ),
                if (message.content.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    message.content,
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      color: const Color(0xff1F2A37),
                      height: 1.4,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  _formatTime(message.createdAt),
                  style: GoogleFonts.roboto(
                    fontSize: 11,
                    color: const Color(0xff9CA3AF),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildLoggedMealCard() {
    final metadata = message.metadata;

    return Container(
      constraints: const BoxConstraints(maxWidth: 300),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffE5E7EB)),
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
          if (message.attachment != null && message.attachment!.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              child: CachedNetworkImage(
                imageUrl: message.attachment!,
                height: 140,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 140,
                  color: const Color(0xffF3F4F6),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xff851653),
                      strokeWidth: 2,
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 100,
                  color: const Color(0xffF3F4F6),
                  child: const Icon(Icons.restaurant, color: Color(0xff851653), size: 40),
                ),
              ),
            ),
          Container(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (message.attachment != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: message.attachment!,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        ),
                      ),
                    if (message.attachment != null) const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            metadata?.itemName ?? 'Meal Logged',
                            style: GoogleFonts.roboto(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xff1F2A37),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xff851653),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${metadata?.servings ?? 100}G',
                                  style: GoogleFonts.roboto(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${metadata?.calories ?? 0} calorie',
                                style: GoogleFonts.roboto(
                                  fontSize: 13,
                                  color: const Color(0xff6B7280),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (metadata?.weekNumber != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xffF3F4F6),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xffE5E7EB)),
                        ),
                        child: Text(
                          'Week ${metadata!.weekNumber}',
                          style: GoogleFonts.roboto(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xff1F2A37),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                _buildNutritionRow(),
                if (metadata?.totalConsumed != null && metadata?.totalPlanned != null)
                  _buildTotalBudget(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionRow() {
    final metadata = message.metadata;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildNutrientItem(
          icon: Icons.grain,
          label: 'Protein',
          value: '${metadata?.protein ?? 25}g',
        ),
        _buildNutrientItem(
          icon: Icons.grass,
          label: 'Fiber',
          value: '${metadata?.fiber ?? 25}g',
        ),
        _buildNutrientItem(
          icon: Icons.rice_bowl_outlined,
          label: 'Carbs',
          value: '${metadata?.carbs ?? 25}g',
        ),
        _buildNutrientItem(
          icon: Icons.water_drop_outlined,
          label: 'Fat',
          value: '${metadata?.fat ?? 25}g',
        ),
      ],
    );
  }

  Widget _buildNutrientItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, size: 18, color: const Color(0xff6B7280)),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.roboto(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xff1F2A37),
          ),
        ),
        Text(
          label,
          style: GoogleFonts.roboto(
            fontSize: 11,
            color: const Color(0xff9CA3AF),
          ),
        ),
      ],
    );
  }

  Widget _buildTotalBudget() {
    final metadata = message.metadata;
    final consumed = metadata?.totalConsumed ?? 1977;
    final planned = metadata?.totalPlanned ?? 2003;

    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xffFDF2FA),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Budget',
            style: GoogleFonts.roboto(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xff851653),
            ),
          ),
          const SizedBox(height: 10),
          _buildBudgetRow(
            icon: Icons.local_fire_department,
            label: 'Calorie Budget',
            current: '$consumed Cal',
            total: '$planned Cal',
            color: const Color(0xff1F2A37),
          ),
          const SizedBox(height: 8),
          _buildBudgetRow(
            icon: Icons.water_drop,
            label: 'Fat',
            current: '30% (50 g)',
            total: '33% (55 g)',
            color: Colors.red,
          ),
          const SizedBox(height: 8),
          _buildBudgetRow(
            icon: Icons.add,
            label: 'Net Carbs',
            current: '50% (197 g)',
            total: '40% (180 g)',
            color: const Color(0xff6B7280),
          ),
          const SizedBox(height: 8),
          _buildBudgetRow(
            icon: Icons.menu_book,
            label: 'Protein',
            current: '20% (79 g)',
            total: '25% (85 g)',
            color: const Color(0xff851653),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetRow({
    required IconData icon,
    required String label,
    required String current,
    required String total,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.roboto(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
        const Spacer(),
        Text(
          current,
          style: GoogleFonts.roboto(
            fontSize: 12,
            color: const Color(0xff6B7280),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          total,
          style: GoogleFonts.roboto(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: const Color(0xff1F2A37),
          ),
        ),
      ],
    );
  }
}
