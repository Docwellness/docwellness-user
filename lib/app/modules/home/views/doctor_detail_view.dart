import 'package:cached_network_image/cached_network_image.dart';
import 'package:docwellness/app/models/doctor_profile_model.dart';
import 'package:docwellness/app/modules/home/services/doctor_profile_service.dart';
import 'package:docwellness/utils/app_theme/custom_text.dart';
import 'package:flutter/material.dart';

class DoctorDetailView extends StatefulWidget {
  const DoctorDetailView({super.key});

  @override
  State<DoctorDetailView> createState() => _DoctorDetailViewState();
}

class _DoctorDetailViewState extends State<DoctorDetailView> {
  DoctorProfileModel? doctor;
  bool isLoading = true;
  bool isPostsLoading = true;
  List<Map<String, dynamic>> posts = [];

  @override
  void initState() {
    super.initState();
    _fetchDoctorProfile();
    _fetchDoctorPosts();
  }

  Future<void> _fetchDoctorProfile() async {
    final service = DoctorProfileService();
    final profile = await service.getAssignedDoctorProfile();
    if (mounted) {
      setState(() {
        doctor = profile;
        isLoading = false;
      });
    }
  }

  Future<void> _fetchDoctorPosts() async {
    try {
      final service = DoctorProfileService();
      final result = await service.getDoctorPosts();
      if (!mounted) return;
      setState(() {
        posts = result;
        isPostsLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        posts = [];
        isPostsLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xffFDF2FA),
        title: const Text('About Doctor'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xff851653)),
            )
          : doctor == null
          ? const Center(child: Text('Could not load doctor profile'))
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Doctor Image Header
                  Container(
                    width: double.infinity,
                    color: const Color(0xffFEF6FB),
                    padding: const EdgeInsets.symmetric(vertical: 30),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 65,
                          backgroundColor: const Color(0xffFDF2FA),
                          backgroundImage: doctor!.profileImage.isNotEmpty
                              ? CachedNetworkImageProvider(
                                  doctor!.profileImage,
                                )
                              : null,
                          child: doctor!.profileImage.isEmpty
                              ? const Icon(
                                  Icons.person,
                                  size: 65,
                                  color: Color(0xff851653),
                                )
                              : null,
                        ),
                        const SizedBox(height: 16),
                        CustomText(
                          text: doctor!.fullName.isNotEmpty
                              ? doctor!.fullName
                              : 'Doctor',
                          fontWeight: FontWeight.w600,
                          fontSize: 22,
                          color: const Color(0xff530630),
                        ),
                        if (doctor!.specialization.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          CustomText(
                            text: doctor!.specialization,
                            fontWeight: FontWeight.w400,
                            fontSize: 14,
                            color: const Color(0xff4D5761),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Info Cards
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        if (doctor!.age != null)
                          _buildInfoCard(
                            icon: Icons.cake_outlined,
                            label: 'Age',
                            value: '${doctor!.age} yrs',
                          ),
                        if (doctor!.experience > 0) ...[
                          const SizedBox(width: 12),
                          _buildInfoCard(
                            icon: Icons.work_outline,
                            label: 'Experience',
                            value: '${doctor!.experience} yrs',
                          ),
                        ],
                        if (doctor!.qualification.isNotEmpty) ...[
                          const SizedBox(width: 12),
                          _buildInfoCard(
                            icon: Icons.school_outlined,
                            label: 'Degree',
                            value: doctor!.qualification,
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // About / Bio Section
                  if (doctor!.bio.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: CustomText(
                        text: 'About',
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                        color: const Color(0xff530630),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: CustomText(
                        text: doctor!.bio,
                        fontWeight: FontWeight.w400,
                        fontSize: 14,
                        color: const Color(0xff4D5761),
                        height: 1.5,
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: CustomText(
                      text: 'Posts',
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                      color: const Color(0xff530630),
                    ),
                  ),
                  const SizedBox(height: 10),

                  if (isPostsLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Color(0xff851653),
                        ),
                      ),
                    )
                  else if (posts.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 14,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xffFEF6FB),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const CustomText(
                          text: 'No doctor posts available right now.',
                          fontWeight: FontWeight.w400,
                          fontSize: 13,
                          color: Color(0xff6C737F),
                        ),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: posts.map((post) {
                          final imageUrl = post['imageUrl']?.toString() ?? '';
                          final text = post['text']?.toString() ?? '';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xffF3D9E9),
                              ),
                              color: Colors.white,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (imageUrl.isNotEmpty)
                                  ClipRRect(
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(12),
                                    ),
                                    child: CachedNetworkImage(
                                      imageUrl: imageUrl,
                                      width: double.infinity,
                                      height: 190,
                                      fit: BoxFit.cover,
                                      errorWidget: (_, __, ___) => Container(
                                        width: double.infinity,
                                        height: 190,
                                        color: const Color(0xffFEF6FB),
                                        child: const Icon(
                                          Icons.broken_image,
                                          color: Color(0xff9DA4AE),
                                        ),
                                      ),
                                    ),
                                  ),
                                if (text.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: CustomText(
                                      text: text,
                                      fontWeight: FontWeight.w400,
                                      fontSize: 13,
                                      color: const Color(0xff4D5761),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xffFEF6FB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xffFDF2FA)),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xff851653), size: 24),
            const SizedBox(height: 8),
            CustomText(
              text: label,
              fontWeight: FontWeight.w400,
              fontSize: 11,
              color: const Color(0xff4D5761),
            ),
            const SizedBox(height: 4),
            CustomText(
              text: value,
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: const Color(0xff530630),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
