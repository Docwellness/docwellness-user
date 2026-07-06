import 'package:cached_network_image/cached_network_image.dart';
import 'package:docwellness/utils/app_theme/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ImageViewer extends StatelessWidget {
  final String title;
  final String subTitle;
  final String image;
  final bool isNetwork;
  const ImageViewer({
    super.key,
    required this.subTitle,
    required this.title,
    required this.image,
    this.isNetwork = false,
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
          text: title,
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
              SizedBox(height: 50),

              isNetwork
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: image,
                        height: 340,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => SizedBox(
                          height: 340,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: Color(0xff851653),
                            ),
                          ),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          height: 340,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Color(0xffFDF2FA),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.broken_image,
                              size: 48,
                              color: Color(0xff9DA4AE),
                            ),
                          ),
                        ),
                      ),
                    )
                  : Container(
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
