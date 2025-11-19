import 'dart:io';
import 'package:file_picker/file_picker.dart';
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
import '../utils/adaptive_snackbar.dart';
import '../widgets/book_action_sheet.dart';

class ReadingNowScreen extends StatelessWidget {
  const ReadingNowScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dividerColor = theme.brightness == Brightness.dark
        ? const Color(0xFF3A3A3A)
        : const Color(0xFFE2E2E2);

    return Scaffold(
      body: SafeArea(
        child: Consumer<BookProvider>(
          builder: (context, bookProvider, _) {
            final s = S.of(context);
            final currentBook = bookProvider.currentBook;
            final recentlyOpened = bookProvider.getRecentlyOpenedBooks(
              excludeCurrent: true,
              limit: 10,
            );

            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              children: [
                _ReadingNowHeader(dividerColor: dividerColor),
                const SizedBox(height: 24),
                if (currentBook == null)
                  _EmptyReadingNow(dividerColor: dividerColor)
                else
                  _CurrentBookCard(book: currentBook),
                const SizedBox(height: 32),
                Text(
                  s.recentlyOpenedSection.toUpperCase(),
                  style: GoogleFonts.playfairDisplay(
                    textStyle: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Divider(color: dividerColor, thickness: 1),
                const SizedBox(height: 16),
                if (recentlyOpened.isEmpty)
                  _EmptyRecentlyOpened(dividerColor: dividerColor)
                else
                  SizedBox(
                    height: 200,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: recentlyOpened.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 16),
                      itemBuilder: (context, index) => _RecentBookTile(
                        book: recentlyOpened[index],
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                  ),
                const SizedBox(height: 24),
                Text(
                  s.readingNowHint,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.secondary,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ReadingNowHeader extends StatelessWidget {
  final Color dividerColor;

  const _ReadingNowHeader({required this.dividerColor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = S.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                s.readingNowSection,
                style: GoogleFonts.playfairDisplay(
                  textStyle: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            CircleAvatar(
              radius: 15,
              backgroundColor: theme.brightness == Brightness.dark
                  ? const Color(0xFF2C2C2C)
                  : const Color(0xFFEFEFEF),
              child: Icon(
                Icons.person,
                size: 16,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Divider(color: dividerColor, thickness: 1),
      ],
    );
  }
}

class _CurrentBookCard extends StatelessWidget {
  final Book book;

  const _CurrentBookCard({required this.book});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final shadowColor = isDark
        ? const Color.fromRGBO(0, 0, 0, 0.35)
        : const Color.fromRGBO(0, 0, 0, 0.25);
    final progressPercent = (book.readingProgress * 100).round();
    final screenWidth = MediaQuery.of(context).size.width;
    final baseWidth = (screenWidth - 40) * 0.55;
    final coverWidth = baseWidth.clamp(150.0, 230.0);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _openBook(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: _CoverPreview(
              book: book,
              width: coverWidth,
              shadowColor: shadowColor,
              placeholderColor: theme.cardColor,
              accentColor: theme.colorScheme.secondary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  book.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.playfairDisplay(
                    textStyle: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                ),
              ),
              Platform.isIOS
                  ? CNPopupMenuButton.icon(
                      buttonIcon: const CNSymbol('ellipsis', size: 18),
                      items: _buildMenuItems(context),
                      onSelected: (index) => _handleMenuAction(context, index),
                    )
                  : SizedBox(
                      height: 32,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        splashRadius: 18,
                        onPressed: () => BookActionSheet.show(context, book),
                        icon: const Icon(Icons.more_horiz),
                      ),
                    ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            book.readingProgress >= 1.0 && book.totalPages > 0
                ? s.read
                : '$progressPercent%',
            style: GoogleFonts.sourceSans3(
              textStyle: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.secondary,
                letterSpacing: 0.2,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openBook(BuildContext context) async {
    final bookProvider = Provider.of<BookProvider>(context, listen: false);
    await bookProvider.markBookOpened(book.id);
    if (!context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PDFReaderScreen(book: book),
      ),
    );
  }

  List<CNPopupMenuItem> _buildMenuItems(BuildContext context) {
    final s = S.of(context);
    return [
      CNPopupMenuItem(
        label: s.delete,
        icon: const CNSymbol('trash.fill', size: 18),
      ),
      CNPopupMenuItem(
        label: s.resetReadingProgress,
        icon: const CNSymbol('arrow.counterclockwise', size: 18),
      ),
      CNPopupMenuItem(
        label: s.bookInfoTitle,
        icon: const CNSymbol('info.circle.fill', size: 18),
      ),
      CNPopupMenuItem(
        label: s.changeCover,
        icon: const CNSymbol('photo.fill', size: 18),
      ),
      CNPopupMenuItem(
        label: s.changeAuthor,
        icon: const CNSymbol('person.fill', size: 18),
      ),
      CNPopupMenuItem(
        label: s.renameBook,
        icon: const CNSymbol('pencil', size: 18),
      ),
      if (book.totalPages > 0 && book.readingProgress < 1.0)
        CNPopupMenuItem(
          label: s.markAsRead,
          icon: const CNSymbol('checkmark.circle.fill', size: 18),
        ),
    ];
  }

  void _handleMenuAction(BuildContext context, int index) {
    final s = S.of(context);
    final bookProvider = Provider.of<BookProvider>(context, listen: false);

    final menuItems = _buildMenuItems(context);
    final actualIndex = index >= menuItems.length ? menuItems.length - 1 : index;
    
    switch (actualIndex) {
      case 0: // Delete
        _showDeleteConfirmation(context);
        break;
      case 1: // Reset progress
        bookProvider.resetProgressAndHistory(book.id).then((_) {
          showAdaptiveSnackBar(context, s.readingProgressReset);
        });
        break;
      case 2: // Book info
        _showBookInfo(context);
        break;
      case 3: // Change cover
        _showCoverOptions(context);
        break;
      case 4: // Change author
        _showChangeAuthorDialog(context);
        break;
      case 5: // Rename
        _showRenameDialog(context);
        break;
      case 6: // Mark as read (if shown)
        if (book.totalPages > 0 && book.readingProgress < 1.0) {
          bookProvider.markBookAsRead(book.id).then((_) {
            showAdaptiveSnackBar(context, 'Book marked as read');
          });
        }
        break;
    }
  }

  void _showRenameDialog(BuildContext context) {
    final s = S.of(context);
    final controller = TextEditingController(text: book.title);
    
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(s.renameBook),
        content: Padding(
          padding: const EdgeInsets.only(top: 16),
          child: CupertinoTextField(
            controller: controller,
            placeholder: s.bookTitleLabel,
            autofocus: true,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: Text(s.cancel),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                final bookProvider = Provider.of<BookProvider>(context, listen: false);
                bookProvider.updateBookTitle(book.id, controller.text.trim());
                Navigator.pop(context);
                showAdaptiveSnackBar(context, s.bookUpdated);
              }
            },
            child: Text(s.save),
          ),
        ],
      ),
    );
  }

  void _showChangeAuthorDialog(BuildContext context) {
    final s = S.of(context);
    final controller = TextEditingController(
      text: book.author == 'Unknown Author' ? '' : book.author,
    );
    
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(s.changeAuthor),
        content: Padding(
          padding: const EdgeInsets.only(top: 16),
          child: CupertinoTextField(
            controller: controller,
            placeholder: s.authorLabel,
            autofocus: true,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: Text(s.cancel),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () async {
              final navigator = Navigator.of(context);
              final bookProvider = Provider.of<BookProvider>(context, listen: false);
              await bookProvider.updateBookAuthor(book.id, controller.text.trim());
              navigator.pop();
              showAdaptiveSnackBar(context, s.authorUpdated);
            },
            child: Text(s.save),
          ),
        ],
      ),
    );
  }

  void _showBookInfo(BuildContext context) {
    final s = S.of(context);
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(s.bookInfoTitle),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
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
            ],
          ),
        ),
        actions: [
          CupertinoDialogAction(
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
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  String _formatFullDate(DateTime date) {
    return '${date.day}.${date.month.toString().padLeft(2, '0')}.${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showCoverOptions(BuildContext context) {
    final s = S.of(context);
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
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
      ),
    );
  }

  Future<void> _pickCustomCover(BuildContext context) async {
    final strings = S.of(context);
    final bookProvider = Provider.of<BookProvider>(context, listen: false);
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );

      if (result != null && result.files.single.path != null) {
        await bookProvider.updateBookCover(book.id, result.files.single.path!);
        showAdaptiveSnackBar(context, strings.coverUpdated);
      }
    } catch (e) {
      showAdaptiveSnackBar(context, '${strings.error}: $e');
    }
  }

  Future<void> _resetToDefaultCover(BuildContext context) async {
    final bookProvider = Provider.of<BookProvider>(context, listen: false);
    final strings = S.of(context);
    await bookProvider.updateBookCover(book.id, null);
    showAdaptiveSnackBar(context, strings.coverReset);
  }

  void _showDeleteConfirmation(BuildContext context) {
    final bookProvider = Provider.of<BookProvider>(context, listen: false);
    final strings = S.of(context);
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
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
              Navigator.pop(context);
              await bookProvider.removeBook(book.id);
              showAdaptiveSnackBar(
                context,
                strings.bookDeleted,
                backgroundColor: Colors.green,
              );
            },
            child: Text(strings.delete),
          ),
        ],
      ),
    );
  }
}

class _CoverPreview extends StatelessWidget {
  final Book book;
  final double width;
  final Color shadowColor;
  final Color placeholderColor;
  final Color accentColor;
  static const double _targetAspectRatio = 3 / 4;

  const _CoverPreview({
    required this.book,
    required this.width,
    required this.shadowColor,
    required this.placeholderColor,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: BookCoverUtils.getCoverPath(book),
      builder: (context, snapshot) {
        final height = width / _targetAspectRatio;
        return _CoverFrame(
          width: width,
          height: height,
          shadowColor: shadowColor,
          child: snapshot.hasData && snapshot.data != null
              ? Center(
                  child: Image.file(
                    File(snapshot.data!),
                    fit: BoxFit.contain,
                  ),
                )
              : _CoverPlaceholder(
                  color: placeholderColor,
                  iconColor: accentColor,
                ),
        );
      },
    );
  }
}

class _CoverFrame extends StatelessWidget {
  final double width;
  final double height;
  final Color shadowColor;
  final Widget child;

  const _CoverFrame({
    required this.width,
    required this.height,
    required this.shadowColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
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
        child: child,
      ),
    );
  }
}

class _CoverPlaceholder extends StatelessWidget {
  final Color color;
  final Color iconColor;

  const _CoverPlaceholder({required this.color, required this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color,
      child: Center(
        child: Icon(
          Icons.menu_book_outlined,
          color: iconColor,
          size: 42,
        ),
      ),
    );
  }
}

class _EmptyReadingNow extends StatelessWidget {
  final Color dividerColor;

  const _EmptyReadingNow({required this.dividerColor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = S.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: dividerColor),
      ),
      child: Column(
        children: [
          Icon(
            Icons.auto_stories_outlined,
            size: 64,
            color: theme.colorScheme.secondary,
          ),
          const SizedBox(height: 16),
          Text(
            s.readingNowEmptyTitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.playfairDisplay(
              textStyle: theme.textTheme.titleMedium,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            s.readingNowEmptySubtitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.secondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyRecentlyOpened extends StatelessWidget {
  final Color dividerColor;

  const _EmptyRecentlyOpened({required this.dividerColor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = S.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: dividerColor),
      ),
      child: Row(
        children: [
          Icon(
            Icons.history,
            color: theme.colorScheme.secondary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              s.recentlyOpenedEmpty,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentBookTile extends StatelessWidget {
  final Book book;

  const _RecentBookTile({required this.book});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = S.of(context);

    return GestureDetector(
      onTap: () async {
        final navigator = Navigator.of(context);
        final bookProvider = Provider.of<BookProvider>(context, listen: false);
        await bookProvider.markBookOpened(book.id);
        navigator.push(
          MaterialPageRoute(builder: (context) => PDFReaderScreen(book: book)),
        );
      },
      child: SizedBox(
        width: 110,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromRGBO(0, 0, 0, 0.25),
                    blurRadius: 12,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
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
                              ),
                            );
                          }
                          return Container(
                            color: theme.cardColor,
                            child: Icon(
                              Icons.menu_book_outlined,
                              color: theme.colorScheme.secondary,
                            ),
                          );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              book.readingProgress >= 1.0 && book.totalPages > 0
                  ? s.read
                  : s.progressShort((book.readingProgress * 100).round()),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

