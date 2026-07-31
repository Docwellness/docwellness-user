class DoctorProfileModel {
  final String fullName;
  final DateTime? dateOfBirth;
  final String profileImage;
  final String gender;
  final String specialization;
  final int experience;
  final String qualification;
  final String bio;
  final List<String> galleryImages;

  DoctorProfileModel({
    required this.fullName,
    this.dateOfBirth,
    required this.profileImage,
    required this.gender,
    required this.specialization,
    required this.experience,
    required this.qualification,
    required this.bio,
    this.galleryImages = const [],
  });

  /// "Tejasvini" -> "Dr. Tejasvini" - shown everywhere the patient app
  /// displays her name. Left alone if she's already stored a title (e.g.
  /// "Dr. Tejasvini" or "Prof. ...") so it's never doubled up.
  String get displayName {
    if (fullName.isEmpty) return 'Doctor';
    final lower = fullName.toLowerCase();
    if (lower.startsWith('dr.') || lower.startsWith('dr ') || lower.startsWith('prof')) {
      return fullName;
    }
    return 'Dr. $fullName';
  }

  factory DoctorProfileModel.fromJson(Map<String, dynamic> json) {
    return DoctorProfileModel(
      fullName: json['fullName'] ?? '',
      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.tryParse(json['dateOfBirth'].toString())
          : null,
      profileImage: json['profileImage'] ?? '',
      gender: json['gender'] ?? '',
      specialization: json['specialization'] ?? '',
      experience: (json['experience'] as num?)?.toInt() ?? 0,
      qualification: json['qualification'] ?? '',
      bio: json['bio'] ?? '',
      galleryImages: (json['galleryImages'] as List? ?? [])
          .map((g) => (g is Map ? g['url']?.toString() : g.toString()) ?? '')
          .where((url) => url.isNotEmpty)
          .toList(),
    );
  }

  int? get age {
    if (dateOfBirth == null) return null;
    final now = DateTime.now();
    int age = now.year - dateOfBirth!.year;
    if (now.month < dateOfBirth!.month ||
        (now.month == dateOfBirth!.month && now.day < dateOfBirth!.day)) {
      age--;
    }
    return age;
  }
}
