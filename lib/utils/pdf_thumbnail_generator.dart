import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';

class PDFThumbnailGenerator {
  static Future<Directory> _thumbnailsDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/thumbnails');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  static Future<String> _coverPath(String bookId) async {
    final dir = await _thumbnailsDirectory();
    return '${dir.path}/${bookId}_cover.png';
  }

  static Future<String> _pagePath(String bookId, int pageNumber) async {
    final dir = await _thumbnailsDirectory();
    return '${dir.path}/${bookId}_page_$pageNumber.png';
  }

  static Future<String?> generateCoverThumbnail(String pdfPath, String bookId) async {
    return _renderPage(pdfPath, bookId, 1, await _coverPath(bookId));
  }

  static Future<String?> generatePageThumbnail(
    String pdfPath,
    String bookId,
    int pageNumber,
  ) async {
    final safePage = pageNumber <= 0 ? 1 : pageNumber;
    final targetPath = await _pagePath(bookId, safePage);
    final result = await _renderPage(pdfPath, bookId, safePage, targetPath);
    if (result != null) {
      await _cleanupObsoletePages(bookId, safePage);
    }
    return result;
  }

  static Future<String?> _renderPage(
    String pdfPath,
    String bookId,
    int pageNumber,
    String destinationPath,
  ) async {
    PdfDocument? document;
    PdfPage? page;
    try {
      final file = File(destinationPath);
      if (await file.exists()) {
        return destinationPath;
      }

      document = await PdfDocument.openFile(pdfPath);
      final safePage = pageNumber.clamp(1, document.pagesCount);
      page = await document.getPage(safePage);
      const double targetWidth = 1200;
      final double targetHeight = targetWidth * page.height / page.width;

      final image = await page.render(
        width: targetWidth,
        height: targetHeight,
        format: PdfPageImageFormat.png,
      );

      if (image == null) {
        return null;
      }

      await file.writeAsBytes(image.bytes);
      return destinationPath;
    } catch (e) {
      debugPrint('Error generating thumbnail for $bookId: $e');
      return null;
    } finally {
      await page?.close();
      await document?.close();
    }
  }

  static Future<void> _cleanupObsoletePages(String bookId, int keepPage) async {
    try {
      final dir = await _thumbnailsDirectory();
      final entities = dir.listSync();

      for (final entity in entities) {
        if (entity is File &&
            entity.path.contains('${bookId}_page_') &&
            !entity.path.endsWith('_page_$keepPage.png')) {
          await entity.delete();
        }
      }
    } catch (_) {}
  }

  static Future<void> deleteThumbnails(String bookId) async {
    try {
      final dir = await _thumbnailsDirectory();
      final entities = dir.listSync();
      for (final entity in entities) {
        if (entity is File && entity.path.contains(bookId)) {
          await entity.delete();
        }
      }
    } catch (e) {
      debugPrint('Error deleting thumbnails: $e');
    }
  }
}
