class ArticleModel {
  final String id;
  final String title;
  final String category;
  final String imageUrl;
  final String excerpt;
  final String content;

  ArticleModel({
    required this.id,
    required this.title,
    required this.category,
    required this.imageUrl,
    required this.excerpt,
    required this.content,
  });

  factory ArticleModel.fromJson(Map<String, dynamic> json) {
    return ArticleModel(
      id: json['_id']?.toString() ?? '',
      title: json['title'] ?? '',
      category: json['category'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      excerpt: json['excerpt'] ?? '',
      content: json['content'] ?? '',
    );
  }
}
