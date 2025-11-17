import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

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

