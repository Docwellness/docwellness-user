import 'package:cached_network_image/cached_network_image.dart';
import 'package:docwellness/app/models/doctor_profile_model.dart';
import 'package:docwellness/app/modules/home/views/doctor_detail_view.dart';
import 'package:docwellness/utils/app_theme/custom_text.dart';
import 'package:flutter/material.dart';

class AboutMeSection extends StatelessWidget {
  final DoctorProfileModel? doctor;

  const AboutMeSection({super.key, this.doctor});

  @override
  Widget build(BuildContext context) {
    final name = doctor?.fullName ?? 'Dr. Tejasvini';
    final desc = doctor != null && doctor!.experience > 0
        ? '${doctor!.specialization.isNotEmpty ? doctor!.specialization : "Nutrition Expert"} with ${doctor!.experience}+ years of experience'
        : 'Nutrition Expert with 10+ years of experience';
    final hasImage = doctor != null && doctor!.profileImage.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xffFEF6FB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xffFDF2FA)),
      ),
      child: Row(
        children: [
          Container(
            height: 120,
            width: 120,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: hasImage
                    ? CachedNetworkImageProvider(doctor!.profileImage)
                          as ImageProvider
                    : const AssetImage('assets/demo_image/Image.png'),
                fit: BoxFit.cover,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  text: name,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xff530630),
                  fontSize: 17,
                ),

                const SizedBox(height: 2),

                CustomText(
                  text: desc,
                  fontSize: 11,
                  color: const Color(0xff4D5761),
                  fontWeight: FontWeight.w400,
                ),

                const SizedBox(height: 30),

                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DoctorDetailView(),
                      ),
                    );
                  },
                  child: CustomText(
                    text: "Learn More",
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xffF670CA),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
