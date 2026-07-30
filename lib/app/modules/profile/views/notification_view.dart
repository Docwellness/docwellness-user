import 'package:docwellness/utils/app_theme/app_shadows.dart';
import 'package:docwellness/utils/app_theme/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationView extends StatefulWidget {
  const NotificationView({super.key});

  @override
  State<NotificationView> createState() => _NotificationViewState();
}

class _NotificationViewState extends State<NotificationView> {
  bool mealReminders = true;
  bool waterReminders = true;
  bool dietUpdates = true;
  bool chatMessages = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final pref = await SharedPreferences.getInstance();
    setState(() {
      mealReminders = pref.getBool('notif_meal') ?? true;
      waterReminders = pref.getBool('notif_water') ?? true;
      dietUpdates = pref.getBool('notif_diet') ?? true;
      chatMessages = pref.getBool('notif_chat') ?? true;
    });
  }

  Future<void> _save(String key, bool value) async {
    final pref = await SharedPreferences.getInstance();
    await pref.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xffFDF2FA),
        titleSpacing: 0,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(Icons.arrow_back, color: Color(0xff1F2A37)),
        ),
        title: const CustomText(
          text: 'Notification',
          fontWeight: FontWeight.w400,
          fontSize: 19,
          color: Color(0xff851653),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          _buildSwitch(
            icon: Icons.restaurant_menu,
            title: 'Meal Reminders',
            subtitle: 'Get reminded to log your meals',
            value: mealReminders,
            onChanged: (v) {
              setState(() => mealReminders = v);
              _save('notif_meal', v);
            },
          ),
          _buildSwitch(
            icon: Icons.water_drop_outlined,
            title: 'Water Reminders',
            subtitle: 'Stay hydrated with timely reminders',
            value: waterReminders,
            onChanged: (v) {
              setState(() => waterReminders = v);
              _save('notif_water', v);
            },
          ),
          _buildSwitch(
            icon: Icons.food_bank_outlined,
            title: 'Diet Plan Updates',
            subtitle: 'Get notified when your diet plan is updated',
            value: dietUpdates,
            onChanged: (v) {
              setState(() => dietUpdates = v);
              _save('notif_diet', v);
            },
          ),
          _buildSwitch(
            icon: Icons.chat_bubble_outline,
            title: 'Chat Messages',
            subtitle: 'Receive notifications for new messages',
            value: chatMessages,
            onChanged: (v) {
              setState(() => chatMessages = v);
              _save('notif_chat', v);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSwitch({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xffFEF6FB),
        borderRadius: BorderRadius.circular(12),
        border: cardBorder,
        boxShadow: cardShadow,
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xff851653), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  text: title,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xff111927),
                ),
                const SizedBox(height: 2),
                CustomText(
                  text: subtitle,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xff6B7280),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: const Color(0xff851653),
          ),
        ],
      ),
    );
  }
}
