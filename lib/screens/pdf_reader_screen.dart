import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import '../models/book.dart';
import '../providers/book_provider.dart';
import '../providers/settings_provider.dart';
import '../generated/l10n.dart';
import 'dart:ui';
import '../widgets/bookmarks_bottom_sheet.dart';

class PDFReaderScreen extends StatefulWidget {
  final Book book;

  const PDFReaderScreen({super.key, required this.book});

  @override
  State<PDFReaderScreen> createState() => PDFReaderScreenState();
}

class PDFReaderScreenState extends State<PDFReaderScreen> {
  PDFViewController? controller;
  int currentPage = 1;
  int totalPages = 0;
  bool isReady = false;
  bool showControls = true;
  bool isFullscreen = false;

  // Динамический цвет фона в зависимости от темы
  Color _getReaderBackground(BuildContext context) {
    final theme = Theme.of(context);
    return theme.brightness == Brightness.dark
        ? const Color(0xFF1C1C1C)  // Темный фон
        : const Color(0xFFF8F4E8);  // Светлый фон
  }

  @override
  void initState() {
    super.initState();
    currentPage = widget.book.currentPage.clamp(1, widget.book.totalPages > 0 ? widget.book.totalPages : 1);
    totalPages = widget.book.totalPages;
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _hideSystemUI() {
    // Не меняем SystemUI - оставляем как есть для стабильности
  }

  void _showSystemUI() {
    // Не меняем SystemUI - оставляем как есть для стабильности
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final readerBackground = _getReaderBackground(context);
    
    return Consumer2<BookProvider, SettingsProvider>(
      builder: (context, bookProvider, settingsProvider, child) {
        return Scaffold(
          backgroundColor: readerBackground,
          extendBodyBehindAppBar: true,
          appBar: showControls && !isFullscreen ? _buildAppBar(s, bookProvider) : null,
          body: Stack(
            children: [
              _buildPDFViewer(settingsProvider, readerBackground),
              // GestureDetector keeps the button area interactive
              _buildGestureDetector(),
              // Controls overlay
              if (showControls && !isFullscreen) _buildBottomControls(s, bookProvider),
            ],
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(S s, BookProvider bookProvider) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: Container(
        decoration: BoxDecoration(
          color: CupertinoDynamicColor.withBrightness(
            color: Colors.white.withOpacity(0.14),
            darkColor: Colors.black.withOpacity(0.14),
          ).resolveFrom(context),
          border: Border(
            bottom: BorderSide(
              color: CupertinoDynamicColor.withBrightness(
                color: Colors.white.withOpacity(0.24),
                darkColor: Colors.black.withOpacity(0.24),
              ).resolveFrom(context),
              width: 0.7,
            ),
          ),
        ),
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 14.0,
              sigmaY: 14.0,
            ),
            child: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              foregroundColor: isDark ? Colors.white : Colors.black87,
              title: Text(
                widget.book.title,
                overflow: TextOverflow.ellipsis,
              ),
              actions: [
                // Bookmark toggle
                IconButton(
                  icon: Icon(
                    bookProvider.hasBookmarkForPage(widget.book.id, currentPage)
                        ? Icons.bookmark
                        : Icons.bookmark_border,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  onPressed: () => _toggleBookmark(bookProvider, s),
                ),
                // Context menu
                AdaptivePopupMenuButton.icon<String>(
                  icon: const Icon(Icons.more_vert),
                  items: [
                    AdaptivePopupMenuItem(
                      label: s.bookmarks,
                      icon: 'bookmarks',
                      value: 'bookmarks',
                    ),
                    AdaptivePopupMenuItem(
                      label: s.goToPage,
                      icon: 'arrow.triangle.turn.up.right.diamond',
                      value: 'goto',
                    ),
                    AdaptivePopupMenuItem(
                      label: s.share,
                      icon: 'square.and.arrow.up',
                      value: 'share',
                    ),
                    AdaptivePopupMenuDivider(),
                    AdaptivePopupMenuItem(
                      label: isFullscreen ? 'Exit fullscreen' : 'Fullscreen mode',
                      icon: isFullscreen ? 'arrow.down.right.and.arrow.up.left' : 'arrow.up.left.and.arrow.down.right',
                      value: 'fullscreen',
                    ),
                  ],
                  onSelected: (index, item) {
                    _handleMenuAction(item.value?.toString() ?? '', bookProvider, s);
                  },
                  buttonStyle: PopupButtonStyle.bordered,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPDFViewer(SettingsProvider settingsProvider, Color readerBackground) {
    if (!File(widget.book.filePath).existsSync()) {
      return _buildFileNotFoundError();
    }

    return Container(
      color: readerBackground,
      child: Stack(
        children: [
          PDFView(
            filePath: widget.book.filePath,
            enableSwipe: true,
            swipeHorizontal: true,
            autoSpacing: false,
            pageFling: true,
            pageSnap: true,
            defaultPage: currentPage - 1,
            fitPolicy: FitPolicy.WIDTH,
            preventLinkNavigation: false,
            backgroundColor: readerBackground,
            onRender: (pages) {
              setState(() {
                totalPages = pages!;
                isReady = true;
              });
              debugPrint('PDF loaded: $totalPages pages, current: $currentPage');
              _updateProgress();
            },
            onError: (error) {
              debugPrint('PDF Error: $error');
              _showErrorDialog();
            },
            onPageError: (page, error) {
              debugPrint('Page $page Error: $error');
            },
            onViewCreated: (PDFViewController pdfViewController) {
              controller = pdfViewController;
            },
            onPageChanged: (int? page, int? total) {
              if (total != null && total > 0) {
                final newPage = (page ?? 0) + 1;
                debugPrint('Page changed: $newPage / $total');
                setState(() {
                  currentPage = newPage.clamp(1, total);
                  totalPages = total;
                });
                _updateProgress();
              }
            },
          ),
          if (!isReady)
            Container(
              color: readerBackground,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      S.of(context).loadingPdf,
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // Brightness overlay
          if (settingsProvider.brightness < 1.0)
            Container(
              color: Color.fromRGBO(
                0,
                0,
                0,
                (1.0 - settingsProvider.brightness).clamp(0.0, 1.0),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFileNotFoundError() {
    final s = S.of(context);
    final textColor = Colors.grey.shade900;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 100,
            color: textColor.withAlpha((0.6 * 255).round()),
          ),
          const SizedBox(height: 20),
          Text(
            s.fileNotFound,
            style: TextStyle(
              fontSize: 24,
              color: textColor,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            s.fileNotFoundMessage,
            style: TextStyle(
              fontSize: 16,
              color: textColor.withAlpha((0.7 * 255).round()),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls(S s, BookProvider bookProvider) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = CupertinoDynamicColor.withBrightness(
      color: CupertinoColors.black,
      darkColor: CupertinoColors.white,
    ).resolveFrom(context);
    
    // Получить safe area insets явно для правильного позиционирования на iOS
    final mediaQuery = MediaQuery.of(context);
    final bottomPadding = mediaQuery.padding.bottom;
    
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        top: false,
        minimum: EdgeInsets.zero,
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 18.0,
              sigmaY: 18.0,
            ),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 96),
              decoration: BoxDecoration(
                color: CupertinoDynamicColor.withBrightness(
                  color: Colors.white.withOpacity(0.14),
                  darkColor: Colors.black.withOpacity(0.14),
                ).resolveFrom(context),
                border: Border(
                  top: BorderSide(
                    color: CupertinoDynamicColor.withBrightness(
                      color: Colors.white.withOpacity(0.24),
                      darkColor: Colors.black.withOpacity(0.24),
                    ).resolveFrom(context),
                    width: 0.7,
                  ),
                ),
              ),
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 12,
                bottom: 12 + bottomPadding, // Явно добавить safe area bottom для iOS
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Progress bar
                  Row(
                    children: [
                      SizedBox(
                        width: 40,
                        child: Text(
                          '$currentPage',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Expanded(
                        child: AdaptiveSlider(
                          value: totalPages > 0 ? currentPage.clamp(1, totalPages).toDouble() : 1.0,
                          min: 1.0,
                          max: totalPages > 0 ? totalPages.toDouble() : 1.0,
                          onChanged: totalPages > 0 ? (value) {
                            _goToPage(value.round());
                          } : null,
                          activeColor: CupertinoColors.systemBlue,
                        ),
                      ),
                      SizedBox(
                        width: 40,
                        child: Text(
                          '$totalPages',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Control buttons - iOS style toolbar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildIOSControlButton(
                        sfSymbol: 'backward.fill',
                        enabled: currentPage > 1 && totalPages > 0,
                        onPressed: () => _previousPage(),
                      ),
                      _buildIOSControlButton(
                        sfSymbol: 'bookmarks',
                        enabled: totalPages > 0,
                        onPressed: () => _showBookmarksBottomSheet(bookProvider),
                      ),
                      _buildIOSControlButton(
                        sfSymbol: 'arrow.triangle.turn.up.right.diamond',
                        enabled: totalPages > 0,
                        onPressed: () => _showGoToPageDialog(),
                      ),
                      _buildIOSControlButton(
                        sfSymbol: bookProvider.hasBookmarkForPage(widget.book.id, currentPage)
                            ? 'bookmark.fill'
                            : 'bookmark',
                        enabled: totalPages > 0,
                        onPressed: () => _toggleBookmark(bookProvider, s),
                        isActive: bookProvider.hasBookmarkForPage(widget.book.id, currentPage),
                      ),
                      _buildIOSControlButton(
                        sfSymbol: 'forward.fill',
                        enabled: currentPage < totalPages && totalPages > 0,
                        onPressed: () => _nextPage(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIOSControlButton({
    required String sfSymbol,
    required bool enabled,
    required VoidCallback onPressed,
    bool isActive = false,
  }) {
    final textColor = CupertinoDynamicColor.withBrightness(
      color: CupertinoColors.black,
      darkColor: CupertinoColors.white,
    ).resolveFrom(context);
    
    return AdaptiveButton.sfSymbol(
      style: AdaptiveButtonStyle.prominentGlass,
      onPressed: enabled ? onPressed : null,
      sfSymbol: SFSymbol(
        sfSymbol,
        size: 22,
        color: enabled
            ? (isActive
                ? CupertinoColors.systemBlue
                : textColor.withOpacity(1.0))
            : textColor.withOpacity(0.3),
      ),
    );
  }

  Widget _buildGestureDetector() {
    return Positioned.fill(
      bottom: showControls ? 120 : 0, // Exclude control strip
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: _handleTapUp,
        onDoubleTap: () {
          setState(() {
            isFullscreen = !isFullscreen;
            if (isFullscreen) {
              _hideSystemUI();
            } else {
              _showSystemUI();
            }
          });
        },
        child: Container(
          color: Colors.transparent,
        ),
      ),
    );
  }

  void _handleTapUp(TapUpDetails details) {
    final width = MediaQuery.of(context).size.width;
    final dx = details.localPosition.dx;
    final leftBoundary = width * 0.30;  // 0-30% для назад
    final rightBoundary = width * 0.70;  // 70-100% для вперед
    final canNavigate = controller != null && totalPages > 0;

    if (canNavigate && dx < leftBoundary) {
      _previousPage();
      return;
    }
    if (canNavigate && dx > rightBoundary) {
      _nextPage();
      return;
    }

    // Центр (30-70%) - переключение UI
    setState(() {
      showControls = !showControls;
    });
  }

  void _previousPage() async {
    debugPrint('Previous page clicked. Current: $currentPage, Total: $totalPages');
    if (controller != null && currentPage > 1 && totalPages > 0) {
      try {
        // PDF pages are zero-indexed
        await controller!.setPage(currentPage - 2);
        debugPrint('Successfully navigated to page ${currentPage - 1}');
      } catch (e) {
        debugPrint('Error navigating to previous page: $e');
      }
    }
  }

  void _nextPage() async {
    debugPrint('Next page clicked. Current: $currentPage, Total: $totalPages');
    if (controller != null && currentPage < totalPages && totalPages > 0) {
      try {
        // PDF pages are zero-indexed
        await controller!.setPage(currentPage);
        debugPrint('Successfully navigated to page ${currentPage + 1}');
      } catch (e) {
        debugPrint('Error navigating to next page: $e');
      }
    }
  }

  void _goToPage(int page) async {
    if (controller != null && totalPages > 0) {
      final safePage = page.clamp(1, totalPages);
      if (safePage != currentPage) {
        await controller!.setPage(safePage - 1);
      }
    }
  }

  void _updateProgress() {
    final bookProvider = Provider.of<BookProvider>(context, listen: false);
    bookProvider.updateBookProgress(widget.book.id, currentPage, totalPages);
  }

  void _toggleBookmark(BookProvider bookProvider, S s) async {
    if (bookProvider.hasBookmarkForPage(widget.book.id, currentPage)) {
      final bookmark = bookProvider.getBookmarkForPage(widget.book.id, currentPage);
      if (bookmark != null) {
        await bookProvider.removeBookmark(bookmark.id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.bookmarkRemoved)),
        );
      }
    } else {
      await bookProvider.addBookmark(
        widget.book.id,
        currentPage,
        '${s.page} $currentPage',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.bookmarkAdded)),
      );
    }
  }

  void _handleMenuAction(String action, BookProvider bookProvider, S s) {
    switch (action) {
      case 'bookmarks':
        _showBookmarksBottomSheet(bookProvider);
        break;
      case 'goto':
        _showGoToPageDialog();
        break;
      case 'share':
        _shareBook();
        break;
      case 'fullscreen':
        setState(() {
          isFullscreen = !isFullscreen;
          if (isFullscreen) {
            _hideSystemUI();
          } else {
            _showSystemUI();
          }
        });
        break;
    }
  }

  void _showBookmarksBottomSheet(BookProvider bookProvider) {
    showModalBottomSheet(
      context: context,
      builder: (context) => BookmarksBottomSheet(
        bookId: widget.book.id,
        onBookmarkTap: (bookmark) {
          Navigator.pop(context);
          _goToPage(bookmark.pageNumber);
        },
      ),
    );
  }

  void _showGoToPageDialog() {
    final s = S.of(context);
    final controller = TextEditingController();
    
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(s.goToPage),
        content: Padding(
          padding: const EdgeInsets.only(top: 16),
          child: CupertinoTextField(
            controller: controller,
            placeholder: '${s.enterPageNumber} (1 - $totalPages)',
            keyboardType: TextInputType.number,
            autofocus: true,
            padding: const EdgeInsets.all(12),
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
              final page = int.tryParse(controller.text);
              if (page != null && page >= 1 && page <= totalPages) {
                Navigator.pop(context);
                _goToPage(page);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(s.invalidPageNumber)),
                );
              }
            },
            child: Text(s.jumpToPage),
          ),
        ],
      ),
    );
  }

  void _shareBook() {
    Share.share(
      'Reading "${widget.book.title}" in ReaderX',
      subject: widget.book.title,
    );
  }

  void _showErrorDialog() {
    final s = S.of(context);
    AdaptiveAlertDialog.show(
      context: context,
      title: s.error,
      message: s.pdfLoadError,
      actions: [
        AlertAction(
          title: s.ok,
          onPressed: () {
            Navigator.of(context).pop();
            Navigator.of(context).pop();
          },
          style: AlertActionStyle.defaultAction,
        ),
      ],
    );
  }
}