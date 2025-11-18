import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../generated/l10n.dart';
import '../models/book.dart';
import '../providers/book_provider.dart';
import '../screens/pdf_reader_screen.dart';

class BookActionSheet {
  static void show(BuildContext context, Book book) {
    final s = S.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context),
            const Divider(),
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
            const Divider(),
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
    // Using standard AlertDialog for complex content layout
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.bookInfoTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('${s.bookTitleLabel}:', book.title),
            _buildInfoRow('${s.authorLabel}:', book.author),
            _buildInfoRow('Added:', _formatFullDate(book.addedDate)),
            if (book.totalPages > 0) ...[
              _buildInfoRow('Pages:', '${book.totalPages}'),
              _buildInfoRow('Current page:', '${book.currentPage}'),
              _buildInfoRow('Progress:', '${(book.readingProgress * 100).toStringAsFixed(1)}%'),
            ],
            _buildInfoRow('File size:', _getFileSize()),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(s.ok),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _formatFullDate(DateTime date) {
    return '${date.day}.${date.month.toString().padLeft(2, '0')}.${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _getFileSize() => 'Unknown';

  void _showRenameDialog(BuildContext context) {
    final controller = TextEditingController(text: book.title);

    // Using standard AlertDialog for text input (AdaptiveAlertDialog doesn't support TextField)
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

    // Using standard AlertDialog for text input (AdaptiveAlertDialog doesn't support TextField)
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
    showDialog(
      context: context,
      builder: (context) => Platform.isIOS
          ? CupertinoAlertDialog(
              title: Text(s.changeCover),
              content: Text(s.changeCoverDescription),
              actions: [
                CupertinoDialogAction(
                  onPressed: () => Navigator.pop(context),
                  child: Text(s.cancel),
                ),
                CupertinoDialogAction(
                  onPressed: () {
                    Navigator.pop(context);
                    _pickCustomCover(context);
                  },
                  child: Text(s.chooseFile),
                ),
                CupertinoDialogAction(
                  onPressed: () {
                    Navigator.pop(context);
                    _resetToDefaultCover(context);
                  },
                  child: Text(s.resetToDefault),
                ),
              ],
            )
          : AlertDialog(
        title: Text(s.changeCover),
        content: Text(s.changeCoverDescription),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _pickCustomCover(context);
            },
            child: Text(s.chooseFile),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetToDefaultCover(context);
            },
            child: Text(s.resetToDefault),
          ),
        ],
      ),
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
    showDialog(
      context: context,
      builder: (context) => Platform.isIOS
          ? CupertinoAlertDialog(
              title: Text(strings.deleteBookTitle),
              content: Text(strings.deleteBookMessage(book.title)),
              actions: [
                CupertinoDialogAction(
                  onPressed: () => Navigator.pop(context),
                  child: Text(strings.cancel),
                ),
                CupertinoDialogAction(
                  isDestructiveAction: true,
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
                  child: Text(strings.delete),
                ),
              ],
            )
          : AlertDialog(
        title: Text(strings.deleteBookTitle),
        content: Text(strings.deleteBookMessage(book.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(strings.cancel),
          ),
          TextButton(
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
                  child: Text(strings.delete),
          ),
        ],
      ),
    );
  }
}

