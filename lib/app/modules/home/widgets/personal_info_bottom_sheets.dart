import 'package:docwellness/app/modules/auth/views/activity_level_view.dart';
import 'package:docwellness/app/modules/auth/views/health_concerns_view.dart';
import 'package:docwellness/utils/app_theme/custom_text.dart';
import 'package:docwellness/utils/common_widgets/custom_button.dart';
import 'package:flutter/material.dart';

/// "Illness Attention" picker for the Request Diet Plan personal info
/// update - same options/card styling as the signup HealthConcernsScreen,
/// just presented as a bottom sheet instead of a full page.
Future<List<String>?> showIllnessAttentionSheet(
  BuildContext context, {
  required String gender,
  required List<String> selected,
}) {
  return showModalBottomSheet<List<String>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) =>
        _IllnessAttentionSheet(gender: gender, initiallySelected: selected),
  );
}

/// "Activity Level" picker for the same screen - same options/card styling
/// as the signup ActivityLevelView, as a bottom sheet; tapping an option
/// selects it and closes the sheet immediately (single-select).
Future<String?> showActivityLevelSheet(
  BuildContext context, {
  String? selected,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _ActivityLevelSheet(initiallySelected: selected),
  );
}

Widget _dragHandle() {
  return Center(
    child: Container(
      width: 40,
      height: 4,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(2),
      ),
    ),
  );
}

BoxDecoration _cardDecoration(bool checked) {
  return BoxDecoration(
    color: checked ? const Color(0xffFEF6FB) : Colors.white,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(
      color: checked ? const Color(0xffFCFCFD) : const Color(0xffF9FAFB),
    ),
    boxShadow: const [
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
  );
}

class _IllnessAttentionSheet extends StatefulWidget {
  final String gender;
  final List<String> initiallySelected;

  const _IllnessAttentionSheet({
    required this.gender,
    required this.initiallySelected,
  });

  @override
  State<_IllnessAttentionSheet> createState() =>
      _IllnessAttentionSheetState();
}

class _IllnessAttentionSheetState extends State<_IllnessAttentionSheet> {
  late final List<HealthConcern> _items;
  late final Set<int> _selected;

  @override
  void initState() {
    super.initState();
    _items = healthConcernOptionsForGender(widget.gender);
    _selected = _items
        .asMap()
        .entries
        .where((e) => widget.initiallySelected.contains(e.value.title))
        .map((e) => e.key)
        .toSet();
  }

  void _toggle(int index) {
    setState(() {
      if (index == 0) {
        _selected
          ..clear()
          ..add(0);
        return;
      }
      _selected.remove(0);
      if (_selected.contains(index)) {
        _selected.remove(index);
      } else {
        _selected.add(index);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.92,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            children: [
              _dragHandle(),
              const CustomText(
                text: 'Any health concerns?',
                fontSize: 19,
                fontWeight: FontWeight.w500,
                color: Color(0xff851653),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  itemCount: _items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    final checked = _selected.contains(index);
                    return GestureDetector(
                      onTap: () => _toggle(index),
                      child: Container(
                        decoration: _cardDecoration(checked),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 48,
                              height: 48,
                              child: Image.asset(
                                item.image,
                                fit: BoxFit.contain,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CustomText(
                                    text: item.title,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xff851653),
                                  ),
                                  const SizedBox(height: 4),
                                  CustomText(
                                    text: item.subtitle,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    color: const Color(0xff4D5761),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              width: 26,
                              height: 26,
                              child: Checkbox(
                                value: checked,
                                onChanged: (_) => _toggle(index),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(2),
                                ),
                                activeColor: Colors.white,
                                checkColor: const Color(0xFF7A1538),
                                side: const BorderSide(
                                  color: Color(0xff49454F),
                                  width: 2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              CustomButton(
                onTap: () {
                  final titles = _selected.map((i) => _items[i].title).toList();
                  Navigator.of(context).pop(titles);
                },
                text: 'Done',
                isOutline: false,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ActivityLevelSheet extends StatelessWidget {
  final String? initiallySelected;

  const _ActivityLevelSheet({required this.initiallySelected});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.8,
      minChildSize: 0.4,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            children: [
              _dragHandle(),
              const CustomText(
                text: 'What’s your activity level?',
                fontSize: 19,
                fontWeight: FontWeight.w500,
                color: Color(0xff851653),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  itemCount: activityLevelOptions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final data = activityLevelOptions[index];
                    final checked = data['title'] == initiallySelected;
                    return GestureDetector(
                      onTap: () => Navigator.of(context).pop(data['title']),
                      child: Container(
                        height: 88,
                        decoration: _cardDecoration(checked),
                        padding: const EdgeInsets.only(left: 20, right: 12),
                        child: Row(
                          children: [
                            SizedBox(
                              height: 60,
                              width: 34,
                              child: Image.asset(data['image']!),
                            ),
                            const SizedBox(width: 18),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CustomText(
                                    text: data['title']!,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 16,
                                    color: const Color(0xff851653),
                                  ),
                                  const SizedBox(height: 4),
                                  CustomText(
                                    text: data['subtitle']!,
                                    fontWeight: FontWeight.w400,
                                    fontSize: 12,
                                    color: const Color(0xff4D5761),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
