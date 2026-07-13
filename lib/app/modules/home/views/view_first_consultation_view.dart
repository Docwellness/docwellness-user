import 'package:docwellness/app/models/consultation_form_field.dart';
import 'package:docwellness/app/modules/home/controllers/home_controller.dart';
import 'package:docwellness/app/modules/home/services/first_consultation_service.dart';
import 'package:docwellness/app/modules/home/services/request_diet_service.dart';
import 'package:docwellness/utils/app_theme/custom_text.dart';
import 'package:docwellness/utils/common_widgets/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Mirrors the dietician app's "View / Edit Consultation" form (same field
/// cards, same section headers, same styling) but read-only for every field
/// except Consent & Confidentiality, which the patient fills in themselves.
class ViewFirstConsultationView extends StatefulWidget {
  const ViewFirstConsultationView({super.key});

  @override
  State<ViewFirstConsultationView> createState() =>
      _ViewFirstConsultationViewState();
}

class _ViewFirstConsultationViewState
    extends State<ViewFirstConsultationView> {
  final FirstConsultationService _service = FirstConsultationService();

  static const String _consentFieldId = 'consent_acknowledgement';
  static const String _signatureFieldId = 'consent_signature_name';
  static const String _consentValue = 'I consent';

  static const _accent = Color(0xff851653);
  static const _bg = Color(0xffFEF6FB);
  static const _border = Color(0xffFAA7E0);
  static const _labelColor = Color(0xff1F2A37);

  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _errorMessage;
  List<ConsultationFormField> _fields = [];
  Map<String, dynamic> _answersById = {};
  List<String> _labReportFiles = [];
  String _patientGender = '';

  bool _consentChecked = false;
  bool _alreadyConsented = false;
  final TextEditingController _signatureController = TextEditingController();
  final Map<String, TextEditingController> _readOnlyControllers = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _signatureController.dispose();
    for (final c in _readOnlyControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _service.getTemplate(),
        _service.getMyConsultation(),
        RequestDietService().getUserInfo(),
      ]);
      final templateResponse = results[0];
      final consultationResponse = results[1];
      final userInfoResponse = results[2];

      _patientGender =
          userInfoResponse?['data']?['profile']?['gender']?.toString() ?? '';

      final templateFields = (templateResponse?['data']?['fields'] as List?) ?? [];
      _fields = templateFields
          .map((f) => ConsultationFormField.fromJson(Map<String, dynamic>.from(f)))
          .where((f) => f.genderScope == 'general' || f.genderScope == _genderKey())
          .toList()
        ..sort((a, b) => a.order.compareTo(b.order));

      final consultationData = consultationResponse?['data'];
      if (consultationData == null) {
        _errorMessage = 'Your dietician hasn\'t recorded a first consultation yet.';
      } else {
        final customAnswers = (consultationData['customAnswers'] as List?) ?? [];
        _answersById = {
          for (final a in customAnswers) (a['fieldId'] ?? '').toString(): a['value'],
        };
        _labReportFiles = List<String>.from(
          (consultationData['labReports']?['files'] as List?) ?? [],
        );

        final consentValue = _answersById[_consentFieldId];
        _alreadyConsented =
            consentValue is List && consentValue.contains(_consentValue);
        _consentChecked = _alreadyConsented;

        final signatureValue = _answersById[_signatureFieldId];
        if (signatureValue != null) {
          _signatureController.text = signatureValue.toString();
        }

        for (final field in _fields) {
          if (field.fieldId == _consentFieldId ||
              field.fieldId == _signatureFieldId) {
            continue;
          }
          if (_isTextual(field.type)) {
            final v = _answersById[field.fieldId];
            _readOnlyControllers[field.fieldId] =
                TextEditingController(text: v?.toString() ?? '');
          }
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _genderKey() {
    if (_patientGender == 'Male') return 'male';
    if (_patientGender == 'Female') return 'female';
    return '';
  }

  bool _isTextual(ConsultationFieldType t) =>
      t == ConsultationFieldType.text ||
      t == ConsultationFieldType.textarea ||
      t == ConsultationFieldType.number ||
      t == ConsultationFieldType.date;

  Future<void> _submit() async {
    final signature = _signatureController.text.trim();
    if (!_consentChecked || signature.isEmpty) return;

    setState(() => _isSubmitting = true);
    try {
      final response = await _service.submitConsent(
        acknowledged: true,
        signatureName: signature,
      );
      if (response != null && response['success'] == true) {
        setState(() => _alreadyConsented = true);
        if (Get.isRegistered<HomeController>()) {
          final home = Get.find<HomeController>();
          home.hasFirstConsultation.value = true;
          home.firstConsultationConsented.value = true;
        }
        Get.back();
        Get.snackbar(
          'Consent submitted',
          'Your dietician can now create your diet plan.',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        Get.snackbar(
          'Could not submit',
          response?['message'] ?? 'Please try again.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // Home's button/message reflects hasFirstConsultation & consent state as
  // of whenever it last fetched them - since this view is reached by both
  // pushing (button) and replacing (notification tap), and neither leaves
  // an awaited Future on Home's side to hook a refresh onto, re-sync it
  // here on the way out instead. Fire-and-forget: don't block the back
  // navigation on the network round trip, Home's Obx will just pick the
  // update up once it resolves.
  void _syncHomeState() {
    if (Get.isRegistered<HomeController>()) {
      Get.find<HomeController>().fetchFirstConsultationExists();
    }
  }

  void _goBack() {
    _syncHomeState();
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) _syncHomeState();
      },
      child: Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xffFDF2FA),
        leading: IconButton(
          onPressed: _goBack,
          icon: const Icon(Icons.arrow_back, color: Color(0xff1F2A37)),
        ),
        title: CustomText(
          text: 'First Consultation',
          fontWeight: FontWeight.w600,
          fontSize: 18,
          color: const Color(0xff1F2A37),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _accent))
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: CustomText(
                      text: _errorMessage!,
                      fontWeight: FontWeight.w400,
                      fontSize: 14,
                      color: const Color(0xff4D5761),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : _buildContent(),
      // Fixed to the bottom of the screen (not part of the scrollable form)
      // so it's always reachable without scrolling to the end. Hidden once
      // consent has already been submitted, since there's nothing left to
      // submit.
      bottomNavigationBar: (!_isLoading && _errorMessage == null && !_alreadyConsented)
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                child: CustomButton(
                  isLoading: _isSubmitting,
                  onTap:
                      (_consentChecked && _signatureController.text.trim().isNotEmpty)
                      ? _submit
                      : () {},
                  text: 'Submit Form',
                  isOutline: false,
                  fontSize: 14,
                  buttonColor:
                      (_consentChecked && _signatureController.text.trim().isNotEmpty)
                      ? const Color(0xff530630)
                      : const Color(0xffBFA3B0),
                ),
              ),
            )
          : null,
      ),
    );
  }

  Widget _buildContent() {
    final children = <Widget>[];
    String? lastSection;
    for (final field in _fields) {
      if (field.section.isNotEmpty && field.section != lastSection) {
        children.add(_buildSectionHeader(field));
        lastSection = field.section;
      } else if (field.section.isEmpty) {
        lastSection = null;
      }
      children.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildFieldCard(field),
        ),
      );
    }

    return ListView(padding: const EdgeInsets.all(16), children: children);
  }

  Widget _buildSectionHeader(ConsultationFormField field) {
    final suffix = field.genderScope == 'female'
        ? ' (Female clients only)'
        : field.genderScope == 'male'
        ? ' (Male clients only)'
        : '';
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            text: '${field.section}$suffix',
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: _accent,
          ),
          const SizedBox(height: 4),
          const Divider(color: _border, height: 1),
        ],
      ),
    );
  }

  Widget _buildFieldCard(ConsultationFormField field) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: CustomText(
                  text: field.label,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  color: _labelColor,
                ),
              ),
              if (field.required)
                const Text(
                  ' *',
                  style: TextStyle(color: _accent, fontWeight: FontWeight.w700),
                ),
            ],
          ),
          const SizedBox(height: 8),
          _buildFieldInput(field),
        ],
      ),
    );
  }

  Widget _buildFieldInput(ConsultationFormField field) {
    // Consent & signature are the only two editable fields; everything else
    // (including these two once already submitted) renders read-only.
    if (field.fieldId == _consentFieldId) {
      return _alreadyConsented
          ? _readOnlyCheckboxRow(_consentValue, true)
          : _consentCheckbox();
    }
    if (field.fieldId == _signatureFieldId) {
      return _textInput(_signatureController, disabled: _alreadyConsented, live: !_alreadyConsented);
    }

    switch (field.type) {
      case ConsultationFieldType.text:
      case ConsultationFieldType.textarea:
      case ConsultationFieldType.number:
      case ConsultationFieldType.date:
        return _textInput(
          _readOnlyControllers[field.fieldId] ?? TextEditingController(),
          disabled: true,
        );
      case ConsultationFieldType.yesNo:
        return _readOnlyChoice(const ['Yes', 'No'], _answersById[field.fieldId]);
      case ConsultationFieldType.singleChoice:
        return _readOnlyChoice(field.options, _answersById[field.fieldId]);
      case ConsultationFieldType.multiChoice:
        return _readOnlyMultiChoice(
          field.options,
          _answersById[field.fieldId],
        );
      case ConsultationFieldType.file:
        return CustomText(
          text: _labReportFiles.isNotEmpty
              ? '${_labReportFiles.length} file(s) attached'
              : 'No file attached',
          fontWeight: FontWeight.w400,
          fontSize: 13,
          color: const Color(0xff6B7280),
        );
    }
  }

  Widget _textInput(
    TextEditingController controller, {
    required bool disabled,
    bool live = false,
  }) {
    return TextField(
      controller: controller,
      enabled: !disabled,
      maxLines: 1,
      onChanged: live ? (_) => setState(() {}) : null,
      decoration: InputDecoration(
        hintText: disabled ? 'Not provided' : 'Type your answer...',
        filled: true,
        fillColor: disabled ? const Color(0xffF3F4F6) : Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        hintStyle: const TextStyle(color: Color(0xff9DA4AE), fontSize: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _border),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _accent),
        ),
      ),
      style: const TextStyle(fontSize: 13, color: _labelColor),
    );
  }

  Widget _readOnlyChoice(List<String> options, dynamic answer) {
    final selected = answer?.toString();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: options
          .map(
            (opt) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Radio<String>(
                    value: opt,
                    groupValue: selected,
                    activeColor: _accent,
                    onChanged: null,
                  ),
                  Expanded(
                    child: Text(
                      opt,
                      style: const TextStyle(fontSize: 14, color: _labelColor),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _readOnlyMultiChoice(List<String> options, dynamic answer) {
    final selected = answer is List
        ? List<String>.from(answer.map((e) => e.toString()))
        : <String>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: options
          .map(
            (opt) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Checkbox(
                    value: selected.contains(opt),
                    activeColor: _accent,
                    onChanged: null,
                  ),
                  Expanded(
                    child: Text(
                      opt,
                      style: const TextStyle(fontSize: 14, color: _labelColor),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _readOnlyCheckboxRow(String label, bool checked) {
    return Row(
      children: [
        Checkbox(value: checked, activeColor: _accent, onChanged: null),
        Expanded(
          child: Text(label, style: const TextStyle(fontSize: 14, color: _labelColor)),
        ),
      ],
    );
  }

  Widget _consentCheckbox() {
    return InkWell(
      onTap: () => setState(() => _consentChecked = !_consentChecked),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: _consentChecked,
            activeColor: _accent,
            onChanged: (v) => setState(() => _consentChecked = v ?? false),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                _consentValue,
                style: const TextStyle(fontSize: 14, color: _labelColor),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
