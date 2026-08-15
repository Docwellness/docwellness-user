class SocialMediaPostModel {
  final String id;
  final String platform; // 'youtube' | 'instagram'
  final String url;
  final String thumbnailUrl;
  final String caption;

  SocialMediaPostModel({
    required this.id,
    required this.platform,
    required this.url,
    required this.thumbnailUrl,
    required this.caption,
  });

  factory SocialMediaPostModel.fromJson(Map<String, dynamic> json) {
    return SocialMediaPostModel(
      id: json['_id']?.toString() ?? '',
      platform: json['platform'] ?? '',
      url: json['url'] ?? '',
      thumbnailUrl: json['thumbnailUrl'] ?? '',
      caption: json['caption'] ?? '',
    );
  }
}
