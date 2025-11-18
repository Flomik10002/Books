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
    _showSystemUI();
    super.dispose();
  }

  void _hideSystemUI() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  void _showSystemUI() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
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
    return AppBar(
      backgroundColor: _readerBackground.withAlpha((0.92 * 255).round()),
      foregroundColor: Colors.black87,
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
            color: Colors.black87,
          ),
          onPressed: () => _toggleBookmark(bookProvider, s),
        ),
        // Context menu
        AdaptivePopupMenuButton.text<String>(
          label: '',
          items: [
            AdaptivePopupMenuItem(
              label: s.bookmarks,
              icon: 'bookmark.fill',
              value: 'bookmarks',
            ),
            AdaptivePopupMenuItem(
              label: s.goToPage,
              icon: 'arrow.right.circle.fill',
              value: 'goto',
            ),
            const AdaptivePopupMenuDivider(),
            AdaptivePopupMenuItem(
              label: s.share,
              icon: 'square.and.arrow.up',
              value: 'share',
            ),
            AdaptivePopupMenuItem(
              label: isFullscreen ? 'Exit fullscreen' : 'Fullscreen mode',
              icon: 'arrow.up.left.and.arrow.down.right',
              value: 'fullscreen',
            ),
          ],
          onSelected: (index, item) {
            final value = item.value;
            if (value != null) {
              _handleMenuAction(value, bookProvider, s);
            }
          },
          buttonStyle: PopupButtonStyle.plain,
        ),
      ],
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
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Color.fromRGBO(0, 0, 0, 0.8),
              Colors.transparent,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Progress bar
              Row(
                children: [
                  Text(
                    '$currentPage',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  Expanded(
                    child: AdaptiveSlider(
                      value: totalPages > 0 ? currentPage.clamp(1, totalPages).toDouble() : 1.0,
                      min: 1.0,
                      max: totalPages > 0 ? totalPages.toDouble() : 1.0,
                      onChanged: totalPages > 0 ? (value) {
                        _goToPage(value.round());
                      } : null,
                      activeColor: Colors.blue,
                    ),
                  ),
                  Text(
                    '$totalPages',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
              
              // Control buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      onPressed: currentPage > 1 && totalPages > 0 ? () {
                        debugPrint('Previous button pressed!');
                        _previousPage();
                      } : null,
                      icon: Icon(
                        Icons.skip_previous, 
                        color: currentPage > 1 ? Colors.white : Colors.white30,
                      ),
                      iconSize: 32,
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      onPressed: totalPages > 0 ? () {
                        debugPrint('Bookmarks button pressed!');
                        _showBookmarksBottomSheet(bookProvider);
                      } : null,
                      icon: const Icon(Icons.bookmarks, color: Colors.white),
                      iconSize: 28,
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      onPressed: totalPages > 0 ? () {
                        debugPrint('Navigation button pressed!');
                        _showGoToPageDialog();
                      } : null,
                      icon: const Icon(Icons.navigation, color: Colors.white),
                      iconSize: 28,
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      onPressed: totalPages > 0 ? () {
                        debugPrint('Bookmark toggle pressed!');
                        _toggleBookmark(bookProvider, s);
                      } : null,
                      icon: Icon(
                        bookProvider.hasBookmarkForPage(widget.book.id, currentPage)
                            ? Icons.bookmark
                            : Icons.bookmark_border,
                        color: Colors.white,
                      ),
                      iconSize: 28,
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      onPressed: currentPage < totalPages && totalPages > 0 ? () {
                        debugPrint('Next button pressed!');
                        _nextPage();
                      } : null,
                      icon: Icon(
                        Icons.skip_next, 
                        color: currentPage < totalPages ? Colors.white : Colors.white30,
                      ),
                      iconSize: 32,
                    ),
                  ),
                ],
              ),
              
              // Page info
              Text(
                '${(totalPages > 0 ? (currentPage / totalPages * 100) : 0).toStringAsFixed(1)}% • ${s.page} $currentPage ${s.ofPages} $totalPages',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
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
    final leftBoundary = width * 0.35;
    final rightBoundary = width * 0.65;
    final canNavigate = controller != null && totalPages > 0;

    if (canNavigate && dx < leftBoundary) {
      _previousPage();
      return;
    }
    if (canNavigate && dx > rightBoundary) {
      _nextPage();
      return;
    }

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
    
    // For text input, we'll use a custom dialog with AdaptiveAlertDialog styling
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.goToPage),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: s.enterPageNumber,
            hintText: '1 - $totalPages',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(s.cancel),
          ),
          TextButton(
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
          style: AlertActionStyle.primary,
        ),
      ],
    );
  }
}