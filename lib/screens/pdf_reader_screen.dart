import 'dart:io';
import 'package:flutter/material.dart';
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
  static const Color _readerBackground = Color(0xFFF8F4E8);

  PDFViewController? controller;
  int currentPage = 1;
  int totalPages = 0;
  bool isReady = false;
  bool showControls = true;
  bool isFullscreen = false;

  @override
  void initState() {
    super.initState();
    currentPage = widget.book.currentPage.clamp(1, widget.book.totalPages > 0 ? widget.book.totalPages : 1);
    totalPages = widget.book.totalPages;
    _hideSystemUI();
  }

  @override
  void dispose() {
    // Ensure system UI is restored
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
      ));
    });
    super.dispose();
  }

  void _hideSystemUI() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  void _showSystemUI() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    // Ensure navigation bar is transparent and properly styled
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    
    return Consumer2<BookProvider, SettingsProvider>(
      builder: (context, bookProvider, settingsProvider, child) {
        return Scaffold(
          backgroundColor: _readerBackground,
          extendBodyBehindAppBar: true,
          appBar: showControls && !isFullscreen ? _buildAppBar(s, bookProvider) : null,
          body: Stack(
            children: [
              _buildPDFViewer(settingsProvider),
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
          color: (isDark ? Colors.white : Colors.black)
              .withValues(alpha: 0.14),
          border: Border(
            bottom: BorderSide(
              color: (isDark ? Colors.white : Colors.black)
                  .withValues(alpha: 0.24),
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
              foregroundColor: isDark ? Colors.white : Colors.black,
              title: Text(
                widget.book.title,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              actions: [
                // Bookmark toggle
                IconButton(
                  icon: Icon(
                    bookProvider.hasBookmarkForPage(widget.book.id, currentPage)
                        ? Icons.bookmark
                        : Icons.bookmark_border,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  onPressed: () => _toggleBookmark(bookProvider, s),
                ),
                // Context menu
                AdaptivePopupMenuButton.icon<String>(
                  icon: Icon(
                    Icons.more_vert,
                    color: isDark ? Colors.white : Colors.black,
                  ),
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

  Widget _buildPDFViewer(SettingsProvider settingsProvider) {
    if (!File(widget.book.filePath).existsSync()) {
      return _buildFileNotFoundError();
    }

    return Container(
      color: _readerBackground,
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
            backgroundColor: _readerBackground,
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
              color: Colors.black,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(color: Colors.white),
                    const SizedBox(height: 20),
                    Text(
                      S.of(context).loadingPdf,
                      style: const TextStyle(color: Colors.white),
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
    
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 10.0,
            sigmaY: 10.0,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : Colors.black)
                  .withValues(alpha: 0.12),
              border: Border(
                top: BorderSide(
                  color: (isDark ? Colors.white : Colors.black)
                      .withValues(alpha: 0.2),
                  width: 0.5,
                ),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SafeArea(
              top: false,
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
                            color: isDark ? Colors.white : Colors.black,
                            fontSize: 11,
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
                          activeColor: isDark ? const Color(0xFF4da3ff) : Colors.blue,
                        ),
                      ),
                      SizedBox(
                        width: 40,
                        child: Text(
                          '$totalPages',
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Control buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildControlButton(
                        sfSymbol: 'backward.fill',
                        enabled: currentPage > 1 && totalPages > 0,
                        onPressed: () => _previousPage(),
                        isDark: isDark,
                      ),
                      _buildControlButton(
                        sfSymbol: 'bookmarks',
                        enabled: totalPages > 0,
                        onPressed: () => _showBookmarksBottomSheet(bookProvider),
                        isDark: isDark,
                      ),
                      _buildControlButton(
                        sfSymbol: 'arrow.triangle.turn.up.right.diamond',
                        enabled: totalPages > 0,
                        onPressed: () => _showGoToPageDialog(),
                        isDark: isDark,
                      ),
                      _buildControlButton(
                        sfSymbol: bookProvider.hasBookmarkForPage(widget.book.id, currentPage)
                            ? 'bookmark.fill'
                            : 'bookmark',
                        enabled: totalPages > 0,
                        onPressed: () => _toggleBookmark(bookProvider, s),
                        isDark: isDark,
                        isActive: bookProvider.hasBookmarkForPage(widget.book.id, currentPage),
                      ),
                      _buildControlButton(
                        sfSymbol: 'forward.fill',
                        enabled: currentPage < totalPages && totalPages > 0,
                        onPressed: () => _nextPage(),
                        isDark: isDark,
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

  Widget _buildControlButton({
    required String sfSymbol,
    required bool enabled,
    required VoidCallback onPressed,
    required bool isDark,
    bool isActive = false,
  }) {
    return AdaptiveButton.sfSymbol(
      style: AdaptiveButtonStyle.prominentGlass,
      onPressed: enabled ? onPressed : null,
      sfSymbol: SFSymbol(
        sfSymbol,
        size: 22,
        color: enabled
            ? (isActive
                ? (isDark ? const Color(0xFF4da3ff) : Colors.blue)
                : null)
            : null,
      ),
    );
  }

  Widget _buildGestureDetector() {
    return Positioned.fill(
      bottom: showControls ? 100 : 0, // Exclude control strip
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          setState(() {
            showControls = !showControls;
          });
        },
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

  void _showGoToPageDialog() async {
    final s = S.of(context);
    
    final result = await AdaptiveAlertDialog.inputShow(
      context: context,
      title: s.goToPage,
      message: '',
      input: AdaptiveAlertDialogInput(
        placeholder: '${s.enterPageNumber} (1 - $totalPages)',
        keyboardType: TextInputType.number,
      ),
      actions: [
        AlertAction(
          title: s.cancel,
          onPressed: () => Navigator.pop(context),
          style: AlertActionStyle.cancel,
        ),
        AlertAction(
          title: s.jumpToPage,
          onPressed: () {},
          style: AlertActionStyle.defaultAction,
        ),
      ],
    );
    
    if (result != null) {
      final page = int.tryParse(result);
      if (page != null && page >= 1 && page <= totalPages) {
        _goToPage(page);
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.invalidPageNumber)),
        );
      }
    }
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