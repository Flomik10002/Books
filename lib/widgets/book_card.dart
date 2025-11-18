import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cupertino_native/cupertino_native.dart';

import '../generated/l10n.dart';
import '../models/book.dart';
import '../providers/book_provider.dart';
import '../screens/pdf_reader_screen.dart';
import '../utils/book_cover_utils.dart';
import 'book_action_sheet.dart';

class BookCard extends StatelessWidget {
  final Book book;

  const BookCard({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final shadowColor = isDark
        ? const Color.fromRGBO(0, 0, 0, 0.35)
        : const Color.fromRGBO(0, 0, 0, 0.25);

    return GestureDetector(
      onTap: () async {
        final navigator = Navigator.of(context);
        final bookProvider = Provider.of<BookProvider>(context, listen: false);
        await bookProvider.markBookOpened(book.id);
        navigator.push(
          MaterialPageRoute(builder: (context) => PDFReaderScreen(book: book)),
        );
      },
      onLongPress: () => BookActionSheet.show(context, book),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: shadowColor,
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: AspectRatio(
                aspectRatio: 3 / 4,
                child: FutureBuilder<String?>(
                  future: BookCoverUtils.getCoverPath(book),
                  builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data != null) {
                  return Center(
                    child: Image.file(
                      File(snapshot.data!),
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => _buildDefaultPdfIcon(theme),
                    ),
                  );
                }
                return _buildDefaultPdfIcon(theme);
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            book.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.playfairDisplay(
              textStyle: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            book.author,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.secondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            s.progressShort((book.readingProgress * 100).round()),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.secondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultPdfIcon(ThemeData theme) {
    return ColoredBox(
      color: theme.cardColor,
      child: Center(
        child: Icon(
          Icons.menu_book_outlined,
          size: 42,
          color: theme.colorScheme.secondary,
        ),
      ),
    );
  }
}

/// Grid card for books - shows only cover with progress and menu button
class BookGridCard extends StatelessWidget {
  final Book book;

  const BookGridCard({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final shadowColor = isDark
        ? const Color.fromRGBO(0, 0, 0, 0.35)
        : const Color.fromRGBO(0, 0, 0, 0.25);

    return GestureDetector(
      onTap: () async {
        final navigator = Navigator.of(context);
        final bookProvider = Provider.of<BookProvider>(context, listen: false);
        await bookProvider.markBookOpened(book.id);
        navigator.push(
          MaterialPageRoute(builder: (context) => PDFReaderScreen(book: book)),
        );
      },
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: shadowColor,
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: AspectRatio(
                aspectRatio: 3 / 4,
                child: FutureBuilder<String?>(
                  future: BookCoverUtils.getCoverPath(book),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data != null) {
                      return Center(
                        child: Image.file(
                          File(snapshot.data!),
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => _buildDefaultPdfIcon(theme),
                        ),
                      );
                    }
                    return _buildDefaultPdfIcon(theme);
                  },
                ),
              ),
            ),
          ),
          // Progress badge at bottom
          Positioned(
            bottom: 8,
            left: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withOpacity(0.9),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                s.progressShort((book.readingProgress * 100).round()),
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          // Menu button at top right
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () => BookActionSheet.show(context, book),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withOpacity(0.9),
                  shape: BoxShape.circle,
                ),
                child: Platform.isIOS
                    ? const Center(
                        child: CNIcon(symbol: CNSymbol('ellipsis', size: 14)),
                      )
                    : const Center(
                        child: Icon(Icons.more_vert, size: 18),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultPdfIcon(ThemeData theme) {
    return ColoredBox(
      color: theme.cardColor,
      child: Center(
        child: Icon(
          Icons.menu_book_outlined,
          size: 42,
          color: theme.colorScheme.secondary,
        ),
      ),
    );
  }
}

/// List card for books - shows cover on left, title/author/progress on right, menu at bottom right
class BookListCard extends StatelessWidget {
  final Book book;

  const BookListCard({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final shadowColor = isDark
        ? const Color.fromRGBO(0, 0, 0, 0.2)
        : const Color.fromRGBO(0, 0, 0, 0.15);

    return GestureDetector(
      onTap: () async {
        final navigator = Navigator.of(context);
        final bookProvider = Provider.of<BookProvider>(context, listen: false);
        await bookProvider.markBookOpened(book.id);
        navigator.push(
          MaterialPageRoute(builder: (context) => PDFReaderScreen(book: book)),
        );
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover on left
          Container(
            width: 80,
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: shadowColor,
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: FutureBuilder<String?>(
                future: BookCoverUtils.getCoverPath(book),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data != null) {
                    return Image.file(
                      File(snapshot.data!),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildDefaultPdfIcon(theme),
                    );
                  }
                  return _buildDefaultPdfIcon(theme);
                },
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Title, author, progress on right
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.playfairDisplay(
                    textStyle: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  book.author,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.secondary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  s.progressShort((book.readingProgress * 100).round()),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.secondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          // Menu button at bottom right
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: GestureDetector(
                onTap: () => BookActionSheet.show(context, book),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface.withOpacity(0.7),
                    shape: BoxShape.circle,
                  ),
                  child: Platform.isIOS
                      ? const Center(
                          child: CNIcon(symbol: CNSymbol('ellipsis', size: 14)),
                        )
                      : const Center(
                          child: Icon(Icons.more_vert, size: 18),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultPdfIcon(ThemeData theme) {
    return ColoredBox(
      color: theme.cardColor,
      child: Center(
        child: Icon(
          Icons.menu_book_outlined,
          size: 32,
          color: theme.colorScheme.secondary,
        ),
      ),
    );
  }
}

