import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cupertino_native/cupertino_native.dart';
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
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
              // Menu button on top right of cover
              Positioned(
                top: 8,
                right: 8,
                child: _buildAdaptiveMenuButton(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Progress centered
          SizedBox(
            width: double.infinity,
            child: Text(
              '${(book.readingProgress * 100).round()}% read',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.secondary,
                fontSize: 13,
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

  Widget _buildAdaptiveMenuButton(BuildContext context) {
    if (Platform.isIOS) {
      // Use CNPopupMenuButton for iOS
      return CNPopupMenuButton.icon(
        buttonIcon: const CNSymbol('ellipsis', size: 18),
        items: _buildMenuItems(context),
        onSelected: (index) => _handleMenuAction(context, index),
      );
    } else {
      // Use AdaptiveButton with Builder for proper context
      return Builder(
        builder: (builderContext) {
          return AdaptiveButton(
            onPressed: () => _showMaterialMenu(builderContext),
            style: AdaptiveButtonStyle.plain,
            size: AdaptiveButtonSize.small,
            child: const Icon(Icons.more_horiz, size: 18),
          );
        },
      );
    }
  }

  void _showMaterialMenu(BuildContext context) {
    final RenderBox? button = context.findRenderObject() as RenderBox?;
    if (button == null) return;

    final RenderBox? overlay = Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (overlay == null) return;

    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    showMenu<String>(
      context: context,
      position: position,
      items: _buildMaterialMenuItems(context),
    ).then((value) {
      if (value != null) {
        final index = _getMenuIndexByValue(value);
        if (index != null) {
          _handleMenuAction(context, index);
        }
      }
    });
  }

  List<PopupMenuItem<String>> _buildMaterialMenuItems(BuildContext context) {
    final s = S.of(context);
    return [
      PopupMenuItem(
        value: 'delete',
        child: Row(
          children: [
            const Icon(Icons.delete, size: 18),
            const SizedBox(width: 12),
            Text(s.delete),
          ],
        ),
      ),
      PopupMenuItem(
        value: 'reset',
        child: Row(
          children: [
            const Icon(Icons.refresh, size: 18),
            const SizedBox(width: 12),
            Text(s.resetReadingProgress),
          ],
        ),
      ),
      PopupMenuItem(
        value: 'info',
        child: Row(
          children: [
            const Icon(Icons.info_outline, size: 18),
            const SizedBox(width: 12),
            Text(s.bookInfoTitle),
          ],
        ),
      ),
      PopupMenuItem(
        value: 'cover',
        child: Row(
          children: [
            const Icon(Icons.image, size: 18),
            const SizedBox(width: 12),
            Text(s.changeCover),
          ],
        ),
      ),
      PopupMenuItem(
        value: 'author',
        child: Row(
          children: [
            const Icon(Icons.person_outline, size: 18),
            const SizedBox(width: 12),
            Text(s.changeAuthor),
          ],
        ),
      ),
      PopupMenuItem(
        value: 'rename',
        child: Row(
          children: [
            const Icon(Icons.edit, size: 18),
            const SizedBox(width: 12),
            Text(s.renameBook),
          ],
        ),
      ),
      PopupMenuItem(
        value: 'open',
        child: Row(
          children: [
            const Icon(Icons.open_in_new, size: 18),
            const SizedBox(width: 12),
            Text(s.openBook),
          ],
        ),
      ),
    ];
  }

  int? _getMenuIndexByValue(String value) {
    switch (value) {
      case 'delete':
        return 0;
      case 'reset':
        return 1;
      case 'info':
        return 2;
      case 'cover':
        return 3;
      case 'author':
        return 4;
      case 'rename':
        return 5;
      case 'open':
        return 6;
      default:
        return null;
    }
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
      CNPopupMenuItem(
        label: s.openBook,
        icon: const CNSymbol('book.fill', size: 18),
      ),
    ];
  }

  void _handleMenuAction(BuildContext context, int index) {
    final s = S.of(context);
    final bookProvider = Provider.of<BookProvider>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);

    switch (index) {
      case 0: // Delete
        _showDeleteConfirmation(context);
        break;
      case 1: // Reset progress
        bookProvider.resetProgressAndHistory(book.id).then((_) {
          messenger.showSnackBar(
            SnackBar(content: Text(s.readingProgressReset)),
          );
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
      case 6: // Open book
        _openBook(context);
        break;
    }
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
          Stack(
            children: [
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
              // Menu button on top right of cover
              Positioned(
                top: 4,
                right: 4,
                child: _buildAdaptiveMenuButton(context),
              ),
            ],
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

  Widget _buildAdaptiveMenuButton(BuildContext context) {
    if (Platform.isIOS) {
      // Use CNPopupMenuButton for iOS
      return CNPopupMenuButton.icon(
        buttonIcon: const CNSymbol('ellipsis', size: 18),
        items: _buildMenuItems(context),
        onSelected: (index) => _handleMenuAction(context, index),
      );
    } else {
      // Use AdaptiveButton with Builder for proper context
      return Builder(
        builder: (builderContext) {
          return AdaptiveButton(
            onPressed: () => _showMaterialMenu(builderContext),
            style: AdaptiveButtonStyle.plain,
            size: AdaptiveButtonSize.small,
            child: const Icon(Icons.more_horiz, size: 18),
          );
        },
      );
    }
  }

  void _showMaterialMenu(BuildContext context) {
    final RenderBox? button = context.findRenderObject() as RenderBox?;
    if (button == null) return;

    final RenderBox? overlay = Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (overlay == null) return;

    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    showMenu<String>(
      context: context,
      position: position,
      items: _buildMaterialMenuItems(context),
    ).then((value) {
      if (value != null) {
        final index = _getMenuIndexByValue(value);
        if (index != null) {
          _handleMenuAction(context, index);
        }
      }
    });
  }

  List<PopupMenuItem<String>> _buildMaterialMenuItems(BuildContext context) {
    final s = S.of(context);
    return [
      PopupMenuItem(
        value: 'delete',
        child: Row(
          children: [
            const Icon(Icons.delete, size: 18),
            const SizedBox(width: 12),
            Text(s.delete),
          ],
        ),
      ),
      PopupMenuItem(
        value: 'reset',
        child: Row(
          children: [
            const Icon(Icons.refresh, size: 18),
            const SizedBox(width: 12),
            Text(s.resetReadingProgress),
          ],
        ),
      ),
      PopupMenuItem(
        value: 'info',
        child: Row(
          children: [
            const Icon(Icons.info_outline, size: 18),
            const SizedBox(width: 12),
            Text(s.bookInfoTitle),
          ],
        ),
      ),
      PopupMenuItem(
        value: 'cover',
        child: Row(
          children: [
            const Icon(Icons.image, size: 18),
            const SizedBox(width: 12),
            Text(s.changeCover),
          ],
        ),
      ),
      PopupMenuItem(
        value: 'author',
        child: Row(
          children: [
            const Icon(Icons.person_outline, size: 18),
            const SizedBox(width: 12),
            Text(s.changeAuthor),
          ],
        ),
      ),
      PopupMenuItem(
        value: 'rename',
        child: Row(
          children: [
            const Icon(Icons.edit, size: 18),
            const SizedBox(width: 12),
            Text(s.renameBook),
          ],
        ),
      ),
      PopupMenuItem(
        value: 'open',
        child: Row(
          children: [
            const Icon(Icons.open_in_new, size: 18),
            const SizedBox(width: 12),
            Text(s.openBook),
          ],
        ),
      ),
    ];
  }

  int? _getMenuIndexByValue(String value) {
    switch (value) {
      case 'delete':
        return 0;
      case 'reset':
        return 1;
      case 'info':
        return 2;
      case 'cover':
        return 3;
      case 'author':
        return 4;
      case 'rename':
        return 5;
      case 'open':
        return 6;
      default:
        return null;
    }
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
      CNPopupMenuItem(
        label: s.openBook,
        icon: const CNSymbol('book.fill', size: 18),
      ),
    ];
  }

  void _handleMenuAction(BuildContext context, int index) {
    final s = S.of(context);
    final bookProvider = Provider.of<BookProvider>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);

    switch (index) {
      case 0: // Delete
        _showDeleteConfirmation(context);
        break;
      case 1: // Reset progress
        bookProvider.resetProgressAndHistory(book.id).then((_) {
          messenger.showSnackBar(
            SnackBar(content: Text(s.readingProgressReset)),
          );
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
      case 6: // Open book
        _openBook(context);
        break;
    }
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

