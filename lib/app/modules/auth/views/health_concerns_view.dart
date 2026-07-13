// Reference image (your screenshot): /mnt/data/Illness concerns.png

import 'package:docwellness/app/modules/auth/controllers/auth_controller.dart';
import 'package:docwellness/app/modules/auth/views/summary_view.dart';
import 'package:docwellness/utils/app_theme/custom_text.dart';
import 'package:docwellness/utils/common_widgets/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HealthConcern {
  final String title;
  final String subtitle;
  final String image;

  /// 'all' = shown to everyone, 'male' = male only, 'female' = female only
  final String gender;

  HealthConcern({
    required this.title,
    required this.subtitle,
    required this.image,
    this.gender = 'all',
  });
}

// Master list with gender tags - shared with the "Illness Attention" bottom
// sheet reused in the Request Diet Plan screen's personal info update, so
// both places show exactly the same options.
final List<HealthConcern> healthConcernOptions = [
  HealthConcern(
      title: "I don't have any of these",
      subtitle: "I am thankfully away from all this",
      image: 'assets/levels/Group.png',
    ),
    HealthConcern(
      title: "Hypertension",
      subtitle: "I have made doing exercise a lasting habit",
      image: 'assets/levels/Group1.png',
    ),
    HealthConcern(
      title: "High Cholesterol",
      subtitle: "I work on my feet and move around throughout the day",
      image: 'assets/levels/Group2.png',
    ),
    HealthConcern(
      title: "Obesity",
      subtitle: "I work on my feet and move around throughout the day",
      image: 'assets/levels/Group2.png',
    ),
    HealthConcern(
      title: "Diabetes",
      subtitle: "I work on my feet and move around throughout the day",
      image: 'assets/levels/Group2.png',
    ),
    HealthConcern(
      title: "Heart Disease",
      subtitle: "I work on my feet and move around throughout the day",
      image: 'assets/levels/Group2.png',
    ),
    HealthConcern(
      title: "Cancer",
      subtitle: "I work on my feet and move around throughout the day",
      image: 'assets/levels/Group2.png',
    ),
    HealthConcern(
      title: "Lung Disease",
      subtitle: "I work on my feet and move around throughout the day",
      image: 'assets/levels/Group2.png',
    ),
    HealthConcern(
      title: "Thyroid Disease",
      subtitle: "I work on my feet and move around throughout the day",
      image: 'assets/levels/Group2.png',
    ),
    HealthConcern(
      title: "PCOD/PCOS",
      subtitle: "I work on my feet and move around throughout the day",
      image: 'assets/levels/Group2.png',
      gender: 'female',
    ),
    HealthConcern(
      title: "Endometriosis",
      subtitle:
          "A condition where tissue similar to womb lining grows elsewhere",
      image: 'assets/levels/Group2.png',
      gender: 'female',
    ),
    HealthConcern(
      title: "Prostate Issues",
      subtitle: "Prostate-related health concerns",
      image: 'assets/levels/Group2.png',
      gender: 'male',
    ),
  HealthConcern(
    title: "Gastric Disease",
    subtitle: "I work on my feet and move around throughout the day",
    image: 'assets/levels/Group2.png',
  ),
];

/// Filters [healthConcernOptions] to the ones relevant for [gender] - shared
/// by the full-page signup screen and the "Illness Attention" bottom sheet.
List<HealthConcern> healthConcernOptionsForGender(String gender) {
  final g = gender.toLowerCase();
  return healthConcernOptions.where((item) {
    if (item.gender == 'all') return true;
    if (g == 'male' && item.gender == 'male') return true;
    if (g == 'female' && item.gender == 'female') return true;
    return false;
  }).toList();
}

class HealthConcernsScreen extends StatefulWidget {
  const HealthConcernsScreen({super.key});

  @override
  State<HealthConcernsScreen> createState() => _HealthConcernsScreenState();
}

class _HealthConcernsScreenState extends State<HealthConcernsScreen> {
  final AuthController _authController = Get.find<AuthController>();

  late List<HealthConcern> _items;

  @override
  void initState() {
    super.initState();
    final gender = _authController.selectedGender.value;
    _items = healthConcernOptionsForGender(gender);
  }

  // store selected indexes (multi-select). Use Set to allow toggling.
  final Set<int> _selected = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Color(0xffFDF2FA),
        titleSpacing: 0,
        leading: IconButton(
          onPressed: () {
            Get.back();
          },
          icon: Icon(Icons.arrow_back, color: Color(0xff1F2A37)),
        ),
        title: CustomText(
          text: 'Any health concerns?',
          fontWeight: FontWeight.w400,
          fontSize: 20,
          color: Color(0xff851653),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                const SizedBox(height: 16),
                CustomText(
                  text: 'Any health concerns?',

                  fontSize: 21,
                  fontWeight: FontWeight.w500,
                  color: Color(0xff851653),

                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24),
                ListView.separated(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),

                  itemCount: _items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    final checked = _selected.contains(index);
                    return _buildCard(item, checked, index);
                  },
                ),
                SizedBox(height: 24),
                CustomButton(
                  onTap: () {
                    if (_selected.isNotEmpty) {
                      final selectedTitles = _selected
                          .map((i) => _items[i].title)
                          .toList();
                      debugPrint('Selected: $selectedTitles');
                      Get.to(
                        () => SummaryView(healthConcerentList: selectedTitles),
                      );
                    }
                  },
                  text: 'Next',
                  isOutline: false,
                ),
                SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(HealthConcern item, bool checked, int index) {
    return GestureDetector(
      onTap: () => _toggleSelection(index),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Color(0xffF9FAFB)),
          boxShadow: [
            BoxShadow(
              color: Color(0x08000000),
              offset: Offset(0, 5),
              blurRadius: 25,
              spreadRadius: -4,
            ),
            BoxShadow(
              color: Color(0x1B000000),
              offset: Offset(0, 1.14),
              blurRadius: 5.72,
              spreadRadius: -2.67,
            ),
            BoxShadow(
              color: Color(0x1F000000),
              offset: Offset(0, 0.3),
              blurRadius: 1.51,
              spreadRadius: -1.33,
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            // Left battery image box
            SizedBox(
              width: 56,
              height: 56,
              child: Image.asset(item.image, fit: BoxFit.contain),
            ),
            const SizedBox(width: 16),
            // Title + subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    text: item.title,

                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Color(0xff851653),
                  ),
                  const SizedBox(height: 6),
                  CustomText(
                    text: item.subtitle,

                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: Color(0xff4D5761),
                  ),
                ],
              ),
            ),

            // Checkbox
            SizedBox(
              width: 30,
              height: 30,
              child: Checkbox(
                value: checked,
                onChanged: (_) => _toggleSelection(index),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(2),
                ),
                // Customising activeColor and side to match screenshot look:
                activeColor: Colors.white,
                checkColor: const Color(0xFF7A1538),
                side: const BorderSide(color: Color(0xff49454F), width: 2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleSelection(int index) {
    setState(() {
      if (index == 0) {
        _selected.clear();
        _selected.add(0);
        return;
      }

      if (_selected.contains(0)) {
        _selected.remove(0);
      }

      if (_selected.contains(index)) {
        _selected.remove(index);
      } else {
        _selected.add(index);
      }
    });
  }
}
