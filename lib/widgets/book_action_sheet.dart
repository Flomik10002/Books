import 'dart:ui';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';

import '../generated/l10n.dart';
import '../models/book.dart';
import '../providers/book_provider.dart';
import '../screens/pdf_reader_screen.dart';

class BookActionSheet {
  static void show(BuildContext context, Book book) {
    final s = S.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(36.0),
        ),
      ),
      builder: (context) => _BookActionSheetContent(book: book, s: s),
    );
  }
}

class _BookActionSheetContent extends StatelessWidget {
  final Book book;
  final S s;

  const _BookActionSheetContent({
    required this.book,
    required this.s,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(36.0),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 22.0,
          sigmaY: 22.0,
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(36.0),
            ),
            color: (isDark ? Colors.white : Colors.black)
                .withOpacity(0.18),
            border: Border(
              top: BorderSide(
                color: (isDark ? Colors.white : Colors.black)
                    .withOpacity(0.28),
                width: 0.8,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 40,
                spreadRadius: 0,
                offset: const Offset(0, -10),
              ),
            ],
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeader(context),
                  Divider(
                    color: (isDark ? Colors.white : Colors.black)
                        .withOpacity(0.12),
                  ),
            ListTile(
              leading: const Icon(Icons.open_in_new),
              title: Text(s.openBook),
              onTap: () {
                Navigator.pop(context);
                _openBook(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: Text(s.renameBook),
              onTap: () {
                Navigator.pop(context);
                _showRenameDialog(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: Text(s.changeAuthor),
              onTap: () {
                Navigator.pop(context);
                _showChangeAuthorDialog(context, s);
              },
            ),
            ListTile(
              leading: const Icon(Icons.image),
              title: Text(s.changeCover),
              onTap: () {
                Navigator.pop(context);
                _showCoverOptions(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: Text(s.share),
              onTap: () {
                Navigator.pop(context);
                // TODO: wire sharing action for book cards
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(s.bookInfoTitle),
              onTap: () {
                Navigator.pop(context);
                _showBookInfo(context);
              },
            ),
            ListTile(
            leading: const Icon(Icons.remove_circle_outline),
            title: Text(s.resetReadingProgress),
              onTap: () async {
                final messenger = ScaffoldMessenger.of(context);
                final bookProvider = Provider.of<BookProvider>(context, listen: false);
                Navigator.pop(context);
              await bookProvider.resetProgressAndHistory(book.id);
                messenger.showSnackBar(
                SnackBar(content: Text(s.readingProgressReset)),
                );
              },
            ),
                  Divider(
                    color: (isDark ? Colors.white : Colors.black)
                        .withOpacity(0.12),
                  ),
                  ListTile(
                    leading: const Icon(Icons.delete, color: Colors.red),
                    title: Text(
                      s.delete,
                      style: const TextStyle(color: Colors.red),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _showDeleteConfirmation(context);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.picture_as_pdf,
              color: Colors.red[600],
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (book.totalPages > 0)
                  Text(
                    s.readingProgress(
                      (book.readingProgress * 100).toStringAsFixed(0),
                      book.currentPage,
                      book.totalPages,
                    ),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openBook(BuildContext context) async {
    final navigator = Navigator.of(context);
    final bookProvider = Provider.of<BookProvider>(context, listen: false);
    await bookProvider.markBookOpened(book.id);
    navigator.push(
      MaterialPageRoute(
        builder: (context) => PDFReaderScreen(book: book),
      ),
    );
  }

  void _showBookInfo(BuildContext context) {
    final infoText = StringBuffer();
    infoText.writeln('${s.bookTitleLabel}: ${book.title}');
    infoText.writeln('${s.authorLabel}: ${book.author}');
    infoText.writeln('Added: ${_formatFullDate(book.addedDate)}');
    if (book.totalPages > 0) {
      infoText.writeln('Pages: ${book.totalPages}');
      infoText.writeln('Current page: ${book.currentPage}');
      infoText.writeln('Progress: ${(book.readingProgress * 100).toStringAsFixed(1)}%');
    }
    infoText.writeln('File size: ${_getFileSize()}');
    
    AdaptiveAlertDialog.show(
      context: context,
      title: s.bookInfoTitle,
      message: infoText.toString(),
      actions: [
        AlertAction(
          title: s.ok,
          onPressed: () => Navigator.pop(context),
          style: AlertActionStyle.defaultAction,
        ),
      ],
    );
  }

  String _formatFullDate(DateTime date) {
    return '${date.day}.${date.month.toString().padLeft(2, '0')}.${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _getFileSize() => 'Unknown';

  void _showRenameDialog(BuildContext context) {
    final controller = TextEditingController(text: book.title);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.renameBook),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: s.bookTitleLabel,
            border: const OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                final bookProvider = Provider.of<BookProvider>(context, listen: false);
                bookProvider.updateBookTitle(book.id, controller.text.trim());
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(s.bookUpdated)),
                );
              }
            },
            child: Text(s.save),
          ),
        ],
      ),
    );
  }

  void _showChangeAuthorDialog(BuildContext context, S s) {
    final controller = TextEditingController(text: book.author == 'Unknown Author' ? '' : book.author);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.changeAuthor),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: s.authorLabel,
            border: const OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);
              final bookProvider = Provider.of<BookProvider>(context, listen: false);
              await bookProvider.updateBookAuthor(book.id, controller.text.trim());
              navigator.pop();
              messenger.showSnackBar(
                SnackBar(content: Text(s.authorUpdated)),
              );
            },
            child: Text(s.save),
          ),
        ],
      ),
    );
  }

  void _showCoverOptions(BuildContext context) {
    AdaptiveAlertDialog.show(
      context: context,
      title: s.changeCover,
      message: s.changeCoverDescription,
      actions: [
        AlertAction(
          title: s.chooseFile,
          onPressed: () {
            Navigator.pop(context);
            _pickCustomCover(context);
          },
          style: AlertActionStyle.defaultAction,
        ),
        AlertAction(
          title: s.resetToDefault,
          onPressed: () {
            Navigator.pop(context);
            _resetToDefaultCover(context);
          },
          style: AlertActionStyle.defaultAction,
        ),
        AlertAction(
          title: s.cancel,
          onPressed: () => Navigator.pop(context),
          style: AlertActionStyle.cancel,
        ),
      ],
    );
  }

  Future<void> _pickCustomCover(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final strings = S.of(context);
    final bookProvider = Provider.of<BookProvider>(context, listen: false);
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );

      if (result != null && result.files.single.path != null) {
        await bookProvider.updateBookCover(book.id, result.files.single.path!);

        messenger.showSnackBar(
          SnackBar(content: Text(strings.coverUpdated)),
        );
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('${strings.error}: $e')),
      );
    }
  }

  Future<void> _resetToDefaultCover(BuildContext context) async {
    final bookProvider = Provider.of<BookProvider>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);
    final strings = S.of(context);
    await bookProvider.updateBookCover(book.id, null);

    messenger.showSnackBar(
      SnackBar(content: Text(strings.coverReset)),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    final bookProvider = Provider.of<BookProvider>(context, listen: false);
    final strings = S.of(context);
    AdaptiveAlertDialog.show(
      context: context,
      title: strings.deleteBookTitle,
      message: strings.deleteBookMessage(book.title),
      actions: [
        AlertAction(
          title: strings.delete,
          onPressed: () async {
            final messenger = ScaffoldMessenger.of(context);
            Navigator.pop(context);
            await bookProvider.removeBook(book.id);

            messenger.showSnackBar(
              SnackBar(
                content: Text(strings.bookDeleted),
                backgroundColor: Colors.green,
              ),
            );
          },
          style: AlertActionStyle.destructive,
        ),
        AlertAction(
          title: strings.cancel,
          onPressed: () => Navigator.pop(context),
          style: AlertActionStyle.cancel,
        ),
      ],
    );
  }
}

