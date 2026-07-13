/// Mirrors docwellness-dietician's ConsultationFormField - the field
/// definitions for the DocWellness first-consultation questionnaire. The
/// patient app only ever renders these read-only (except the two Consent &
/// Confidentiality fields), so this is a trimmed model with no editing
/// affordances of its own.
enum ConsultationFieldType {
  text,
  textarea,
  number,
  date,
  yesNo,
  singleChoice,
  multiChoice,
  file,
}

ConsultationFieldType consultationFieldTypeFromApi(String? raw) {
  switch (raw) {
    case 'textarea':
      return ConsultationFieldType.textarea;
    case 'number':
      return ConsultationFieldType.number;
    case 'date':
      return ConsultationFieldType.date;
    case 'yesNo':
      return ConsultationFieldType.yesNo;
    case 'singleChoice':
      return ConsultationFieldType.singleChoice;
    case 'multiChoice':
      return ConsultationFieldType.multiChoice;
    case 'file':
      return ConsultationFieldType.file;
    case 'text':
    default:
      return ConsultationFieldType.text;
  }
}

class ConsultationFormField {
  final String fieldId;
  final ConsultationFieldType type;
  final String label;
  final List<String> options;
  final bool required;
  final int order;
  final String section;
  final String genderScope; // 'general' | 'female' | 'male'
  final String? dependsOnFieldId;
  final List<String> dependsOnValues;

  ConsultationFormField({
    required this.fieldId,
    required this.type,
    required this.label,
    this.options = const [],
    this.required = false,
    this.order = 0,
    this.section = '',
    this.genderScope = 'general',
    this.dependsOnFieldId,
    this.dependsOnValues = const [],
  });

  factory ConsultationFormField.fromJson(Map<String, dynamic> json) {
    final genderScope = (json['genderScope'] ?? 'general').toString();
    return ConsultationFormField(
      fieldId: (json['fieldId'] ?? '').toString(),
      type: consultationFieldTypeFromApi(json['type']?.toString()),
      label: (json['label'] ?? '').toString(),
      options: (json['options'] is List)
          ? List<String>.from((json['options'] as List).map((e) => e.toString()))
          : <String>[],
      required: json['required'] == true,
      order: (json['order'] is num) ? (json['order'] as num).toInt() : 0,
      section: (json['section'] ?? '').toString(),
      genderScope: ['general', 'female', 'male'].contains(genderScope)
          ? genderScope
          : 'general',
      dependsOnFieldId: json['dependsOnFieldId']?.toString(),
      dependsOnValues: (json['dependsOnValues'] is List)
          ? List<String>.from(
              (json['dependsOnValues'] as List).map((e) => e.toString()),
            )
          : <String>[],
    );
  }
}

/// One submitted answer from FirstConsultation.customAnswers.
class ConsultationAnswer {
  final String fieldId;
  final dynamic value;

  ConsultationAnswer({required this.fieldId, required this.value});

  factory ConsultationAnswer.fromJson(Map<String, dynamic> json) {
    return ConsultationAnswer(
      fieldId: (json['fieldId'] ?? '').toString(),
      value: json['value'],
    );
  }

  String get displayValue {
    if (value == null) return '—';
    if (value is List) {
      final list = List<String>.from(value.map((e) => e.toString()));
      return list.isEmpty ? '—' : list.join(', ');
    }
    final s = value.toString().trim();
    return s.isEmpty ? '—' : s;
  }
}
