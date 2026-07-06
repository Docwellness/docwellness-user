import 'dart:io';

import 'package:buttons_tabbar/buttons_tabbar.dart';
import 'package:docwellness/app/modules/diet/controllers/diet_controller.dart';
import 'package:docwellness/utils/app_theme/custom_text.dart';
import 'package:docwellness/utils/common_widgets/custom_button.dart';
import 'package:docwellness/utils/common_widgets/custom_dropdown.dart';
import 'package:docwellness/utils/common_widgets/custom_field.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class CreateMyFoodSheet extends StatefulWidget {
  final ScrollController scrollController;

  const CreateMyFoodSheet({super.key, required this.scrollController});

  @override
  State<CreateMyFoodSheet> createState() => _CreateMyFoodSheetState();
}

class _CreateMyFoodSheetState extends State<CreateMyFoodSheet>
    with SingleTickerProviderStateMixin {
  final DietController controller = Get.find<DietController>();
  String selectedQuantity = '';
  String selectedPortion = '';
  final TextEditingController foodName = TextEditingController();
  final TextEditingController foodDes = TextEditingController();
  late TabController tabController;
  int shiftIndex = 0;
  @override
  void initState() {
    controller.pickedMyFoodImage.value = null;
    super.initState();
    tabController = TabController(length: 7, vsync: this);
    tabController.addListener(() {
      if (!mounted) return;
      setState(() {
        shiftIndex = tabController.index;
      });
    });
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: ListView(
        controller: widget.scrollController,
        children: [
          Center(
            child: Container(
              width: 32,
              height: 4,
              margin: const EdgeInsets.only(bottom: 10, top: 10),
              decoration: BoxDecoration(
                color: Color(0xff79747E),
                borderRadius: BorderRadius.circular(100),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 13),
            child: Row(
              children: [
                IconButton(
                  onPressed: () {
                    Get.back();
                  },
                  icon: Icon(Icons.arrow_back, color: Color(0xff1F2A37)),
                ),
                SizedBox(width: 14),
                CustomText(
                  text: 'Create My Food',
                  fontWeight: FontWeight.w400,
                  fontSize: 19,
                  color: Color(0xff1F2A37),
                ),
              ],
            ),
          ),
          Divider(color: Color(0xffE5E7EB)),
          SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Obx(
              () => GestureDetector(
                onTap: () => controller.pickMyFoodImage(),
                child: Container(
                  height: 196,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Color(0xffFEF6FB),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: controller.pickedMyFoodImage.value == null
                        ? Image.asset('assets/icons/camera.png', height: 48)
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.file(
                              File(controller.pickedMyFoodImage.value!.path),
                              fit: BoxFit.contain,
                              width: double.infinity,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 8, top: 32),
            child: PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ButtonsTabBar(
                  controller: tabController,
                  radius: 8,
                  height: 42,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                  backgroundColor: const Color(0xffFCCEEF),
                  borderWidth: 1,
                  borderColor: const Color(0xffFCCEEF),
                  labelStyle: GoogleFonts.roboto(
                    color: Color(0xff530630),
                    fontWeight: FontWeight.w500,
                  ),

                  unselectedLabelStyle: GoogleFonts.roboto(
                    color: Color(0xff4D5761),
                    fontWeight: FontWeight.w500,
                  ),
                  unselectedBorderColor: const Color(0xffD2D6DB),
                  unselectedDecoration: BoxDecoration(
                    color: Colors.transparent,
                    border: Border.all(
                      color: const Color(0xffD2D6DB),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),

                  tabs: const [
                    Tab(text: "Breakfast"),
                    Tab(text: "Morning Drink"),
                    Tab(text: "Lunch"),
                    Tab(text: "Brunch"),
                    Tab(text: "Dinner"),
                    Tab(text: "Evening Snacks"),
                    Tab(text: "Night Drink"),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: CustomField(
              controller: foodName,
              lable: 'Food Name',
              hintText: 'Add Food name',
              changeBorderColor: false,
            ),
          ),
          SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: CustomField(
              controller: foodDes,
              lable: 'Description',
              hintText: 'Add few more words for describing food',
              maxLines: 6,
              changeBorderColor: false,
            ),
          ),
          SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: CustomDropdown(
                    label: 'Quantity',
                    items: List.generate(
                      9,
                      (index) => 'Bowl (${(index + 1) * 100}gm)',
                    ),
                    value: selectedQuantity,
                    onChanged: (v) {
                      setState(() {
                        selectedQuantity = v!;
                      });
                    },
                    isRounded: false,
                    suffixIconColor: const Color(0xff0D121C),
                  ),
                ),

                SizedBox(width: 8),
                SizedBox(
                  width: 122,
                  child: CustomDropdown(
                    label: 'Portion',
                    items: List.generate(10, (index) => "${index + 1}"),
                    value: selectedPortion,
                    onChanged: (v) {
                      setState(() {
                        selectedPortion = v!;
                      });
                    },
                    isRounded: false,
                    suffixIconColor: Color(0xff0D121C),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 60),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Obx(
              () => CustomButton(
                isLoading: controller.showCreateMealLoading.value,
                onTap: () async {
                  if (controller.pickedMyFoodImage.value == null) {
                    Get.snackbar("Error", "Food image is required");
                    return;
                  }
                  if (foodName.text.trim().isEmpty) {
                    Get.snackbar("Error", "Food name is required");
                    return;
                  }
                  if (selectedQuantity.isEmpty || selectedPortion.isEmpty) {
                    Get.snackbar("Error", "Select quantity & portion");
                    return;
                  }

                  await controller.createMyFood(
                    date: DateTime.now().toIso8601String().split('T').first,
                    servingTime: const [
                      "Breakfast",
                      "Morning Drink",
                      "Lunch",
                      "Brunch",
                      "Dinner",
                      "Evening Snack",
                      "Night Drink",
                    ][shiftIndex],
                    foodName: foodName.text.trim(),
                    description: foodDes.text.trim(),
                    quantityLabel: selectedQuantity,
                    portion: int.parse(selectedPortion),
                  );
                },
                text: 'Submit Logged Meal',
                isOutline: false,
                fontSize: 14,
              ),
            ),
          ),
          SizedBox(height: 35),
        ],
      ),
    );
  }
}
