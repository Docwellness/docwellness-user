class ReviewModel {
  final String id;
  final String patientName;
  final int rating;
  final String text;
  final DateTime? createdAt;

  ReviewModel({
    required this.id,
    required this.patientName,
    required this.rating,
    required this.text,
    this.createdAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['_id']?.toString() ?? '',
      patientName: json['patientName'] ?? 'Docwellness patient',
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      text: json['text'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }
}
