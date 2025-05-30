class Blog {
  final String imageUrl;
  final String title;
  final String content;
  final String date;

  Blog({
    required this.imageUrl,
    required this.title,
    required this.content,
    required this.date,
  });

  factory Blog.fromJson(Map<String, dynamic> json) {
    return Blog(
      imageUrl: "https://doctorwala.info/storage/${json['blg_image'] ?? ''}",
      title: json['blg_title'] ?? '',
      content: json['blg_desc'] ?? '',
      date: json['created_at'] ?? '',
    );
  }
}
