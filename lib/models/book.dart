class Book {
  final String id;
  String title;
  String author;
  final String filePath;
  final DateTime addedDate;
  DateTime? lastOpenedAt;
  int currentPage;
  int totalPages;
  String? customCoverPath;

  Book({
    required this.id,
    required this.title,
    required this.filePath,
    required this.addedDate,
    this.author = 'Unknown Author',
    this.lastOpenedAt,
    this.currentPage = 1,
    this.totalPages = 0,
    this.customCoverPath,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'filePath': filePath,
      'addedDate': addedDate.toIso8601String(),
      'lastOpenedAt': lastOpenedAt?.toIso8601String(),
      'currentPage': currentPage,
      'totalPages': totalPages,
      'customCoverPath': customCoverPath,
    };
  }

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'],
      title: json['title'],
      author: json['author'] ?? 'Unknown Author',
      filePath: json['filePath'],
      addedDate: DateTime.parse(json['addedDate']),
      lastOpenedAt: json['lastOpenedAt'] != null
          ? DateTime.tryParse(json['lastOpenedAt'])
          : null,
      currentPage: json['currentPage'] ?? 1,
      totalPages: json['totalPages'] ?? 0,
      customCoverPath: json['customCoverPath'],
    );
  }

  double get readingProgress {
    if (totalPages <= 0) return 0.0;
    return currentPage / totalPages;
  }
}