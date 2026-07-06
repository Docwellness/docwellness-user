import 'package:docwellness/utils/app_theme/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class VideoViewer extends StatelessWidget {
  final String day;
  final String subTitle;
  final String image;
  const VideoViewer({
    super.key,
    required this.subTitle,
    required this.day,
    required this.image,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Color(0xffFDF2FA),
        leading: IconButton(
          onPressed: () {
            Get.back();
          },

          icon: Icon(Icons.arrow_back, color: Color(0xff1F2A37)),
        ),
        title: CustomText(
          text: 'Workout Video',
          fontWeight: FontWeight.w400,
          fontSize: 18,
          color: Color(0xff1F2A37),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: CustomText(
                  text: day,
                  fontWeight: FontWeight.w500,
                  fontSize: 22,
                  color: Color(0xff851653),
                ),
              ),

              Container(
                height: 340,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: AssetImage(image),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SizedBox(height: 16),
              CustomText(
                text: subTitle,
                fontWeight: FontWeight.w400,
                fontSize: 15,
                color: Color(0xff49454F),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
