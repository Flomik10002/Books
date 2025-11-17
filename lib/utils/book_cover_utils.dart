import 'dart:io';

import '../models/book.dart';
import 'pdf_thumbnail_generator.dart';

class BookCoverUtils {
  static Future<String?> getCoverPath(Book book) async {
    if (book.customCoverPath != null && book.customCoverPath!.isNotEmpty) {
      final file = File(book.customCoverPath!);
      if (await file.exists()) {
        return book.customCoverPath;
      }
    }

    return await PDFThumbnailGenerator.generateCoverThumbnail(
      book.filePath,
      book.id,
    );
  }

  static Future<String?> getCurrentPagePath(Book book) async {
    final targetPage = book.currentPage <= 0 ? 1 : book.currentPage;
    final preview = await PDFThumbnailGenerator.generatePageThumbnail(
      book.filePath,
      book.id,
      targetPage,
    );

    if (preview != null) {
      return preview;
    }

    return getCoverPath(book);
  }
}

