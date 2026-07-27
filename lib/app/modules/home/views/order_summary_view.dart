import 'package:docwellness/app/modules/auth/widgets/bmi_container.dart';
import 'package:docwellness/app/modules/home/controllers/home_controller.dart';
import 'package:docwellness/app/modules/home/services/request_diet_service.dart';
import 'package:docwellness/app/modules/home/views/main_request_diet_plan_view.dart';
import 'package:docwellness/utils/app_theme/custom_text.dart';
import 'package:docwellness/utils/common_widgets/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Read-only review of what was submitted: Step 1 (personal information +
/// BMI) and Step 2 (selected membership plan).
///
/// Two ways to reach this screen:
/// - `requestId == null` (the Home "Order Summary" button): shows the
///   patient's CURRENT request via HomeController's shared fields - same
///   behavior as before, editable while that request is still Unpaid.
/// - `requestId` set (tapped from the profile screen's "Your Orders" list):
///   fetches that SPECIFIC order independently (never touches
///   HomeController's shared fields, which back other screens like the
///   edit form/Home banners) and is only editable if that particular order
///   is still Unpaid - a past/closed order is always read-only.
class OrderSummaryView extends StatefulWidget {
  final String? requestId;
  const OrderSummaryView({super.key, this.requestId});

  @override
  State<OrderSummaryView> createState() => _OrderSummaryViewState();
}

class _OrderSummaryViewState extends State<OrderSummaryView> {
  final HomeController controller = Get.find<HomeController>();
  final RequestDietService _service = RequestDietService();

  bool get _isSpecificOrder => widget.requestId != null;

  // Only populated/used when _isSpecificOrder - a specific historical order
  // never overwrites HomeController's shared "current request" fields.
  bool _specificLoading = true;
  Map<String, dynamic>? _specificData;

  @override
  void initState() {
    super.initState();
    if (_isSpecificOrder) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _fetchSpecific());
    } else {
      // Fetch straight from the diet plan request itself (not the mutable
      // patient profile) - this is the actual submitted record, includes the
      // start date, and reflects the selected membership plan.
      // Deferred past the current frame since this mutates Rx fields before
      // its first await, and Home stays mounted underneath this screen with
      // its own Obx watching the same HomeController fields (see the same
      // fix/comment in MainRequestDietPlanView.initState()).
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.fetchRequestDetails();
      });
    }
  }

  Future<void> _fetchSpecific() async {
    final response = await _service.getRequestById(widget.requestId!);
    if (!mounted) return;
    setState(() {
      _specificData = response?['data'] is Map
          ? Map<String, dynamic>.from(response['data'])
          : null;
      _specificLoading = false;
    });
  }

  String _formatDate(dynamic raw) {
    if (raw == null) return '';
    final str = raw.toString();
    if (str.isEmpty) return '';
    var parsed = DateTime.tryParse(str);
    if (parsed == null) {
      // Some older records stored a raw JS `Date.toString()` value instead
      // of an ISO date string - fall back to pulling day/month/year out of
      // that format directly (matches HomeController.fetchRequestDetails).
      const months = {
        'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6,
        'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12,
      };
      final match = RegExp(r'^\w{3} (\w{3}) (\d{2}) (\d{4})').firstMatch(str);
      if (match != null && months.containsKey(match.group(1))) {
        parsed = DateTime(
          int.parse(match.group(3)!),
          months[match.group(1)]!,
          int.parse(match.group(2)!),
        );
      }
    }
    if (parsed == null) return '';
    return "${parsed.day.toString().padLeft(2, '0')}/"
        "${parsed.month.toString().padLeft(2, '0')}/"
        "${parsed.year}";
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
          text: 'Order Summary',
          fontWeight: FontWeight.w400,
          fontSize: 18,
          color: Color(0xff1F2A37),
        ),
      ),
      body: _isSpecificOrder
          ? (_specificLoading
              ? const Center(child: CircularProgressIndicator())
              : _specificData == null
                  ? Center(
                      child: CustomText(
                        text: 'Could not load this order.',
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xff9DA4AE),
                      ),
                    )
                  : _buildSpecificContent(_specificData!))
          : Obx(
              () => controller.isRequestDietPlanLoading.value
                  ? const Center(child: CircularProgressIndicator())
                  : _buildCurrentContent(),
            ),
    );
  }

  /// Home's "current request" path - reads HomeController's shared fields,
  /// unchanged from before this screen supported viewing past orders.
  Widget _buildCurrentContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),

          _sectionHeader('Step 1 · Personal Information'),
          const SizedBox(height: 16),

          _summaryCard([
            _ReadOnlyRow(
              label: 'Start Date for Diet',
              value: controller.requestUserStartDate.text,
            ),
            _ReadOnlyRow(
              label: 'Full name',
              value: controller.requestUserName.text,
            ),
            _ReadOnlyRow(
              label: 'Date of Birth',
              value: controller.requestUserDob.text,
            ),
            _ReadOnlyRow(
              label: 'Gender',
              value: controller.selectedGender.value,
            ),
            _ReadOnlyRow(
              label: 'Initial Weight',
              value: '${controller.requestUserWeight.text} Kg',
            ),
            _ReadOnlyRow(
              label: 'Height',
              value: '${controller.requestUserHeight.text} CM',
              isLast: true,
            ),
          ]),

          const SizedBox(height: 16),
          Obx(
            () => BmiContainer(
              index: controller.bmiIndex.value,
              value: controller.bmiValue.value,
              targetedWeight: controller.targetedWeight.value,
              activityLevel: null,
              healthConcerentList: controller.illness.toList(),
              activityLevelText: controller.activityLevel.value,
            ),
          ),

          const SizedBox(height: 28),

          _sectionHeader('Step 2 · Selected Plan'),
          const SizedBox(height: 16),

          Obx(
            () => _summaryCard([
              _ReadOnlyRow(
                label: 'Membership',
                value: controller.selectedPlanName.value,
              ),
              _ReadOnlyRow(
                label: 'Amount',
                value: '₹${controller.selectedPlanAmount.value.toInt()}/month',
                isLast: true,
              ),
            ]),
          ),

          const SizedBox(height: 28),

          // Only while the dietician hasn't sent a payment request yet -
          // same condition that currently gates the home screen's
          // "Awaiting Payment Request" state.
          Obx(() {
            if (controller.requestStatus.value != 'Unpaid') {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: CustomButton(
                onTap: () {
                  Get.to(() => MainRequestDietPlanView());
                },
                text: 'Update Plan Request',
                isOutline: true,
                fontSize: 14,
              ),
            );
          }),
        ],
      ),
    );
  }

  /// A specific (possibly historical) order's path - reads purely from the
  /// fetched detail map, never HomeController's shared fields.
  Widget _buildSpecificContent(Map<String, dynamic> data) {
    final isEditable = data['isEditable'] == true;
    final healthConcerns = data['healthConcerns'] is List
        ? List<String>.from(
            (data['healthConcerns'] as List).map((e) => e.toString()),
          )
        : <String>[];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),

          _sectionHeader('Step 1 · Personal Information'),
          const SizedBox(height: 16),

          _summaryCard([
            _ReadOnlyRow(
              label: 'Start Date for Diet',
              value: _formatDate(data['startDateForDiet']),
            ),
            _ReadOnlyRow(
              label: 'Full name',
              value: (data['fullName'] ?? '').toString(),
            ),
            _ReadOnlyRow(
              label: 'Date of Birth',
              value: _formatDate(data['dateOfBirth']),
            ),
            _ReadOnlyRow(
              label: 'Gender',
              value: (data['gender'] ?? '').toString(),
            ),
            _ReadOnlyRow(
              label: 'Initial Weight',
              value: '${data['weight'] ?? '--'} Kg',
            ),
            _ReadOnlyRow(
              label: 'Height',
              value: '${data['height'] ?? '--'} CM',
              isLast: true,
            ),
          ]),

          const SizedBox(height: 16),
          BmiContainer(
            index: (data['weightIndex'] as num?)?.toInt() ?? 0,
            value: (data['bmi'] as num?)?.toDouble() ?? 0,
            targetedWeight: (data['targetWeight'] ?? '').toString(),
            activityLevel: null,
            healthConcerentList: healthConcerns,
            activityLevelText: (data['activityLevel'] ?? '').toString(),
          ),

          const SizedBox(height: 28),

          _sectionHeader('Step 2 · Selected Plan'),
          const SizedBox(height: 16),

          _summaryCard([
            _ReadOnlyRow(
              label: 'Membership',
              value: (data['membershipPlan'] ?? '--').toString(),
            ),
            _ReadOnlyRow(
              label: 'Amount',
              value: data['membershipAmount'] != null
                  ? '₹${(data['membershipAmount'] as num).toInt()}/month'
                  : '--',
              isLast: true,
            ),
          ]),

          const SizedBox(height: 28),

          // This order is only ever the CURRENT request when it's still
          // Unpaid (a patient can have at most one Unpaid request at a
          // time - see createDietPlanRequest's upsert-while-Unpaid logic),
          // so refreshing HomeController's shared fields here keeps the
          // edit form (MainRequestDietPlanView) correctly pre-filled.
          if (isEditable)
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: CustomButton(
                onTap: () async {
                  await controller.fetchRequestDetails();
                  Get.to(() => MainRequestDietPlanView());
                },
                text: 'Update Plan Request',
                isOutline: true,
                fontSize: 14,
              ),
            ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String text) {
    return Center(
      child: CustomText(
        text: text,
        fontWeight: FontWeight.w500,
        fontSize: 17,
        color: const Color(0xff851653),
      ),
    );
  }

  Widget _summaryCard(List<Widget> rows) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xffF9FAFB)),
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
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
      child: Column(children: rows),
    );
  }
}

class _ReadOnlyRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isLast;

  const _ReadOnlyRow({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: Color(0xffF3F4F6)),
              ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CustomText(
            text: label,
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: const Color(0xff6C737F),
          ),
          Flexible(
            child: CustomText(
              text: value.isEmpty ? '--' : value,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xff384250),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
