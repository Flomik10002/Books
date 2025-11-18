import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import '../models/book.dart';
import '../models/bookmark.dart';
import '../utils/pdf_thumbnail_generator.dart';
import 'settings_provider.dart';

class BookProvider with ChangeNotifier {
  List<Book> _books = [];
  List<Bookmark> _bookmarks = [];
  bool _isLoading = false;

  List<Book> get books => _books;
  List<Bookmark> get bookmarks => _bookmarks;
  bool get isLoading => _isLoading;

  BookProvider() {
    loadBooks();
    loadBookmarks();
  }

  // Last opened book
  Book? get currentBook {
    final openedBooks = _books.where((book) => book.lastOpenedAt != null).toList();
    if (openedBooks.isEmpty) return null;
    openedBooks.sort((a, b) => b.lastOpenedAt!.compareTo(a.lastOpenedAt!));
    return openedBooks.first;
  }

  // Books for Recently Opened section
  List<Book> getRecentlyOpenedBooks({bool excludeCurrent = true, int limit = 10}) {
    final openedBooks = _books.where((book) => book.lastOpenedAt != null).toList()
      ..sort((a, b) => b.lastOpenedAt!.compareTo(a.lastOpenedAt!));

    if (excludeCurrent && openedBooks.isNotEmpty) {
      openedBooks.removeAt(0);
    }

    return openedBooks.take(limit).toList();
  }

  // Sorted books
  List<Book> getSortedBooks(BookSortType sortType, bool ascending) {
    final sortedBooks = List<Book>.from(_books);
    
    switch (sortType) {
      case BookSortType.lastOpened:
        sortedBooks.sort((a, b) {
          // Books with lastOpenedAt come first, sorted by most recent
          if (a.lastOpenedAt == null && b.lastOpenedAt == null) {
            return 0;
          }
          if (a.lastOpenedAt == null) return 1;
          if (b.lastOpenedAt == null) return -1;
          return b.lastOpenedAt!.compareTo(a.lastOpenedAt!);
        });
        break;
      case BookSortType.name:
        sortedBooks.sort((a, b) => a.title.compareTo(b.title));
        break;
      case BookSortType.author:
        sortedBooks.sort(
          (a, b) => a.author.toLowerCase().compareTo(b.author.toLowerCase()),
        );
        break;
      case BookSortType.progress:
        sortedBooks.sort((a, b) => a.readingProgress.compareTo(b.readingProgress));
        break;
      case BookSortType.manual:
        // Manual sorting - keep current order (will be implemented later)
        break;
    }
    
    if (!ascending && sortType != BookSortType.lastOpened && sortType != BookSortType.manual) {
      return sortedBooks.reversed.toList();
    }
    
    return sortedBooks;
  }

  Future<void> loadBooks() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final booksJson = prefs.getStringList('books') ?? [];
      
      _books = booksJson.map((bookStr) {
        final bookData = jsonDecode(bookStr);
        return Book.fromJson(bookData);
      }).toList();
    } catch (e) {
      debugPrint('Error loading books: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> saveBooks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final booksJson = _books.map((book) => jsonEncode(book.toJson())).toList();
      await prefs.setStringList('books', booksJson);
    } catch (e) {
      debugPrint('Error saving books: $e');
    }
  }

  // Bookmarks
  Future<void> loadBookmarks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bookmarksJson = prefs.getStringList('bookmarks') ?? [];
      
      _bookmarks = bookmarksJson.map((bookmarkStr) {
        final bookmarkData = jsonDecode(bookmarkStr);
        return Bookmark.fromJson(bookmarkData);
      }).toList();
    } catch (e) {
      debugPrint('Error loading bookmarks: $e');
    }
    notifyListeners();
  }

  Future<void> saveBookmarks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bookmarksJson = _bookmarks.map((bookmark) => jsonEncode(bookmark.toJson())).toList();
      await prefs.setStringList('bookmarks', bookmarksJson);
    } catch (e) {
      debugPrint('Error saving bookmarks: $e');
    }
  }

  Future<void> addBookmark(String bookId, int pageNumber, String title) async {
    final bookmark = Bookmark(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      bookId: bookId,
      pageNumber: pageNumber,
      title: title,
      createdDate: DateTime.now(),
    );

    _bookmarks.add(bookmark);
    await saveBookmarks();
    notifyListeners();
  }

  Future<void> removeBookmark(String bookmarkId) async {
    _bookmarks.removeWhere((bookmark) => bookmark.id == bookmarkId);
    await saveBookmarks();
    notifyListeners();
  }

  List<Bookmark> getBookmarksForBook(String bookId) {
    return _bookmarks.where((bookmark) => bookmark.bookId == bookId).toList()
      ..sort((a, b) => a.pageNumber.compareTo(b.pageNumber));
  }

  bool hasBookmarkForPage(String bookId, int pageNumber) {
    return _bookmarks.any((bookmark) => 
      bookmark.bookId == bookId && bookmark.pageNumber == pageNumber);
  }

  Bookmark? getBookmarkForPage(String bookId, int pageNumber) {
    try {
      return _bookmarks.firstWhere((bookmark) => 
        bookmark.bookId == bookId && bookmark.pageNumber == pageNumber);
    } catch (e) {
      return null;
    }
  }

  Future<void> updateBookCover(String bookId, String? coverPath) async {
    try {
      final bookIndex = _books.indexWhere((book) => book.id == bookId);
      if (bookIndex != -1) {
        _books[bookIndex].customCoverPath = coverPath;
        await saveBooks();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating book cover: $e');
    }
  }

  Future<void> updateBookTitle(String bookId, String newTitle) async {
    try {
      final bookIndex = _books.indexWhere((book) => book.id == bookId);
      if (bookIndex != -1) {
        _books[bookIndex].title = newTitle;
        await saveBooks();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating book title: $e');
    }
  }

  Future<void> updateBookAuthor(String bookId, String newAuthor) async {
    try {
      final bookIndex = _books.indexWhere((book) => book.id == bookId);
      if (bookIndex != -1) {
        _books[bookIndex].author = newAuthor.trim().isEmpty ? 'Unknown Author' : newAuthor.trim();
        await saveBooks();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating book author: $e');
    }
  }

  Future<bool> addBook(String filePath, String fileName) async {
    try {
      // Copy file into app directory
      final appDir = await getApplicationDocumentsDirectory();
      final booksDir = Directory('${appDir.path}/books');
      if (!await booksDir.exists()) {
        await booksDir.create(recursive: true);
      }

      final originalFile = File(filePath);
      final newPath = '${booksDir.path}/$fileName';
      await originalFile.copy(newPath);

      // Create book entry
      final book = Book(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: fileName.replaceAll('.pdf', ''),
        author: 'Unknown Author',
        filePath: newPath,
        addedDate: DateTime.now(),
        lastOpenedAt: null,
      );

      _books.add(book);
      await saveBooks();
      
      // Optionally generate cover in background
      // PDFThumbnailGenerator.generateThumbnail(newPath, book.id).then((_) {
      //   notifyListeners();
      // });
      
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error adding book: $e');
      return false;
    }
  }

  Future<void> removeBook(String bookId) async {
    try {
      final bookIndex = _books.indexWhere((book) => book.id == bookId);
      if (bookIndex != -1) {
        final book = _books[bookIndex];
        
        // Remove file
        final file = File(book.filePath);
        if (await file.exists()) {
          await file.delete();
        }

        // Remove cached thumbnails
        await PDFThumbnailGenerator.deleteThumbnails(bookId);

        // Remove bookmarks for this book
        _bookmarks.removeWhere((bookmark) => bookmark.bookId == bookId);
        await saveBookmarks();

        _books.removeAt(bookIndex);
        await saveBooks();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error removing book: $e');
    }
  }

  Future<void> updateBookProgress(String bookId, int currentPage, int totalPages) async {
    try {
      final bookIndex = _books.indexWhere((book) => book.id == bookId);
      if (bookIndex != -1) {
        _books[bookIndex].currentPage = currentPage;
        _books[bookIndex].totalPages = totalPages;
        await saveBooks();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating book progress: $e');
    }
  }

  Future<void> markBookOpened(String bookId) async {
    try {
      final bookIndex = _books.indexWhere((book) => book.id == bookId);
      if (bookIndex != -1) {
        _books[bookIndex].lastOpenedAt = DateTime.now();
        await saveBooks();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error marking book opened: $e');
    }
  }

  Future<void> resetProgressAndHistory(String bookId) async {
    try {
      final bookIndex = _books.indexWhere((book) => book.id == bookId);
      if (bookIndex != -1) {
        _books[bookIndex].lastOpenedAt = null;
        _books[bookIndex].currentPage = 1;
        _books[bookIndex].totalPages = 0;
        await saveBooks();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error resetting book progress: $e');
    }
  }

  Book? getBookById(String bookId) {
    try {
      return _books.firstWhere((book) => book.id == bookId);
    } catch (e) {
      return null;
    }
  }

  // Stats
  int get totalBooks => _books.length;
  int get completedBooks => _books.where((book) => book.readingProgress >= 1.0).length;
  int get inProgressBooks => _books.where((book) => book.readingProgress > 0 && book.readingProgress < 1.0).length;
  double get averageProgress {
    if (_books.isEmpty) return 0.0;
    final totalProgress = _books.fold<double>(0.0, (sum, book) => sum + book.readingProgress);
    return totalProgress / _books.length;
  }
}