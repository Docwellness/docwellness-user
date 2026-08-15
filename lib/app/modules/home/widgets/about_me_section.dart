import 'package:cached_network_image/cached_network_image.dart';
import 'package:docwellness/app/models/doctor_profile_model.dart';
import 'package:docwellness/app/modules/home/views/doctor_detail_view.dart';
import 'package:docwellness/utils/app_theme/app_shadows.dart';
import 'package:docwellness/utils/app_theme/custom_text.dart';
import 'package:flutter/material.dart';

class AboutMeSection extends StatelessWidget {
  final DoctorProfileModel? doctor;

  const AboutMeSection({super.key, this.doctor});

  @override
  Widget build(BuildContext context) {
    final name = doctor?.displayName ?? 'Dr. Tejasvini';
    // Leads with the relationship ("your dietician"), not a credentials
    // line - specialization/experience still show once the dietician has
    // actually filled those in, but the fallback stays warm rather than
    // reading like a clinical placeholder.
    final desc = doctor != null && doctor!.specialization.isNotEmpty
        ? doctor!.specialization
        : 'Your dietician, cheering you on every step of the way';
    final hasImage = doctor != null && doctor!.profileImage.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xffFEF6FB),
        borderRadius: BorderRadius.circular(12),
        border: cardBorder,
        boxShadow: cardShadow,
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
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xffFCE7F6),
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(color: const Color(0xffEF45B2)),
                  ),
                  child: const CustomText(
                    text: 'YOUR DIETICIAN',
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xff851653),
                  ),
                ),
                const SizedBox(height: 6),
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
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 12),

                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DoctorDetailView(),
                      ),
                    );
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CustomText(
                        text: "Meet $name",
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xffF670CA),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.arrow_forward,
                        size: 12,
                        color: Color(0xffF670CA),
                      ),
                    ],
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
