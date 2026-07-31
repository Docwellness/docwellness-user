import 'package:cached_network_image/cached_network_image.dart';
import 'package:docwellness/app/models/article_model.dart';
import 'package:docwellness/utils/app_theme/custom_text.dart';
import 'package:flutter/material.dart';

class ArticleDetailView extends StatelessWidget {
  final ArticleModel article;
  const ArticleDetailView({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: const Color(0xffFDF2FA),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xff1F2A37)),
              onPressed: () => Navigator.pop(context),
            ),
            expandedHeight: 220,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: article.imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: article.imageUrl,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(
                        color: const Color(0xffFEF6FB),
                        child: const Icon(Icons.image_outlined, color: Color(0xff9DA4AE)),
                      ),
                    )
                  : Container(color: const Color(0xffFEF6FB)),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (article.category.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xffFCE7F6),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: CustomText(
                        text: article.category.toUpperCase(),
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                        color: const Color(0xff851653),
                      ),
                    ),
                  const SizedBox(height: 10),
                  CustomText(
                    text: article.title,
                    fontWeight: FontWeight.w600,
                    fontSize: 22,
                    color: const Color(0xff530630),
                    height: 1.3,
                  ),
                  const SizedBox(height: 16),
                  CustomText(
                    text: article.content.isNotEmpty ? article.content : article.excerpt,
                    fontWeight: FontWeight.w400,
                    fontSize: 15,
                    color: const Color(0xff4D5761),
                    height: 1.6,
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
