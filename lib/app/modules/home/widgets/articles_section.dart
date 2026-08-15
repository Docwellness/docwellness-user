import 'package:cached_network_image/cached_network_image.dart';
import 'package:docwellness/app/models/article_model.dart';
import 'package:docwellness/app/modules/home/views/article_detail_view.dart';
import 'package:docwellness/utils/app_theme/app_shadows.dart';
import 'package:docwellness/utils/app_theme/custom_text.dart';
import 'package:flutter/material.dart';

class ArticlesSection extends StatelessWidget {
  final List<ArticleModel> articles;
  const ArticlesSection({super.key, required this.articles});

  @override
  Widget build(BuildContext context) {
    if (articles.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: CustomText(
            text: 'Articles for You',
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: const Color(0xff530630),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: articles.map((a) => _ArticleCard(article: a)).toList(),
          ),
        ),
      ],
    );
  }
}

class _ArticleCard extends StatelessWidget {
  final ArticleModel article;
  const _ArticleCard({required this.article});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ArticleDetailView(article: article)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: cardBorder,
          boxShadow: cardShadow,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: article.imageUrl.isNotEmpty
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
            Padding(
              padding: const EdgeInsets.all(14),
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
                  const SizedBox(height: 8),
                  CustomText(
                    text: article.title,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: const Color(0xff1F2A37),
                  ),
                  if (article.excerpt.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    CustomText(
                      text: article.excerpt,
                      fontWeight: FontWeight.w400,
                      fontSize: 13,
                      color: const Color(0xff4D5761),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      height: 1.4,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      CustomText(
                        text: 'Read more',
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: const Color(0xffF670CA),
                      ),
                      const SizedBox(width: 2),
                      const Icon(Icons.arrow_forward, size: 12, color: Color(0xffF670CA)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
