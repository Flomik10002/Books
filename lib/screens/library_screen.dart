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
import '../providers/settings_provider.dart';
import '../widgets/book_card.dart';
import '../widgets/liquid_glass_search_bar.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  String _searchQuery = '';
  bool _isSearching = false;
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return Scaffold(
      body: SafeArea(
        child: Consumer2<BookProvider, SettingsProvider>(
          builder: (context, bookProvider, settingsProvider, _) {
            if (bookProvider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            final sortedBooks = bookProvider.getSortedBooks(
              settingsProvider.sortType,
              settingsProvider.sortAscending,
            );
            final filteredBooks = _filterBooks(sortedBooks);

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                  child: _isSearching
                      ? _buildSearchBar(s)
                      : _HeaderArea(
                          totalBooks: bookProvider.books.length,
                          settingsProvider: settingsProvider,
                        ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: filteredBooks.isEmpty
                      ? _EmptyLibraryState(
                          isSearching: _searchQuery.isNotEmpty,
                          onAddTap: () => _pickAndAddBook(context),
                        )
                      : settingsProvider.viewMode == ViewMode.grid
                          ? Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              child: GridView.builder(
                                itemCount: filteredBooks.length,
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 28,
                                  crossAxisSpacing: 12,
                                  childAspectRatio: 0.52,
                                ),
                                itemBuilder: (context, index) => BookGridCard(book: filteredBooks[index]),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              itemCount: filteredBooks.length,
                              itemBuilder: (context, index) => Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: BookListCard(book: filteredBooks[index]),
                              ),
                            ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: Platform.isIOS
            ? CNButton.icon(
                icon: const CNSymbol('plus', size: 20),
                onPressed: () => _pickAndAddBook(context),
              )
            : FloatingActionButton(
          onPressed: () => _pickAndAddBook(context),
                child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildSearchBar(S s) {
    return LiquidGlassSearchBar(
      hintText: s.searchHint,
      controller: _searchController,
            autofocus: true,
      onChanged: (value) {
        setState(() {
          _searchQuery = value;
        });
      },
      onClose: () {
        setState(() {
            _isSearching = false;
            _searchQuery = '';
          _searchController.clear();
        });
      },
    );
  }

  List<Book> _filterBooks(List<Book> books) {
    if (_searchQuery.isEmpty) return books;
    return books
        .where(
          (book) =>
              book.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              book.author.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();
  }


  Future<void> _pickAndAddBook(BuildContext context) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final strings = S.of(context);
    final bookProvider = Provider.of<BookProvider>(context, listen: false);
    var dialogShown = false;

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
      );

      if (result != null && result.files.single.path != null) {
        if (!context.mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const Center(child: CircularProgressIndicator()),
        );
        dialogShown = true;

        final success = await bookProvider.addBook(
          result.files.single.path!,
          result.files.single.name,
        );

        if (!context.mounted) return;
        if (dialogShown) {
          navigator.pop();
          dialogShown = false;
        }
        messenger.showSnackBar(
          SnackBar(
            content: Text(success ? strings.bookAddedSuccess : strings.bookAddedError),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      if (dialogShown) {
        navigator.pop();
      }
      messenger.showSnackBar(
        SnackBar(
          content: Text('${strings.error}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class _HeaderArea extends StatelessWidget {
  final int totalBooks;
  final SettingsProvider settingsProvider;

  const _HeaderArea({
    required this.totalBooks,
    required this.settingsProvider,
  });

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                s.libraryTitle,
                style: GoogleFonts.playfairDisplay(
                  textStyle: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            _buildSortMenu(context, s),
            const SizedBox(width: 8),
            _buildViewModeMenu(context, s),
          ],
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () {},
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: theme.cardColor,
              boxShadow: theme.brightness == Brightness.dark
                  ? []
                  : [
                      const BoxShadow(
                        color: Color.fromRGBO(0, 0, 0, 0.1),
                        blurRadius: 12,
                        offset: Offset(0, 6),
                      ),
                    ],
            ),
            child: Row(
              children: [
                const Icon(Icons.folder_copy_outlined),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    s.collections,
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          s.booksCount(totalBooks),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.secondary,
          ),
        ),
      ],
    );
  }

  Widget _buildSortMenu(BuildContext context, S s) {
    final currentSortType = settingsProvider.sortType;

    if (Platform.isIOS) {
      final items = [
        CNPopupMenuItem(
          label: 'По недавним',
          icon: currentSortType == BookSortType.lastOpened
              ? const CNSymbol('checkmark', size: 18)
              : null,
        ),
        CNPopupMenuItem(
          label: s.sortByName,
          icon: currentSortType == BookSortType.name
              ? const CNSymbol('checkmark', size: 18)
              : null,
        ),
        CNPopupMenuItem(
          label: s.sortByAuthor,
          icon: currentSortType == BookSortType.author
              ? const CNSymbol('checkmark', size: 18)
              : null,
        ),
        CNPopupMenuItem(
          label: s.sortByProgress,
          icon: currentSortType == BookSortType.progress
              ? const CNSymbol('checkmark', size: 18)
              : null,
        ),
        CNPopupMenuItem(
          label: 'Вручную',
          icon: currentSortType == BookSortType.manual
              ? const CNSymbol('checkmark', size: 18)
              : null,
        ),
      ];

      return CNPopupMenuButton.icon(
        buttonIcon: const CNSymbol('line.3.horizontal.decrease', size: 18),
        items: items,
        onSelected: (index) {
          switch (index) {
            case 0:
              settingsProvider.setSortType(BookSortType.lastOpened);
              break;
            case 1:
              settingsProvider.setSortType(BookSortType.name);
              break;
            case 2:
              settingsProvider.setSortType(BookSortType.author);
              break;
            case 3:
              settingsProvider.setSortType(BookSortType.progress);
              break;
            case 4:
              settingsProvider.setSortType(BookSortType.manual);
              break;
          }
        },
      );
    } else {
      return PopupMenuButton<String>(
        icon: const Icon(Icons.sort),
        onSelected: (value) {
          if (value == 'lastOpened') {
            settingsProvider.setSortType(BookSortType.lastOpened);
          } else if (value == 'name') {
            settingsProvider.setSortType(BookSortType.name);
          } else if (value == 'author') {
            settingsProvider.setSortType(BookSortType.author);
          } else if (value == 'progress') {
            settingsProvider.setSortType(BookSortType.progress);
          } else if (value == 'manual') {
            settingsProvider.setSortType(BookSortType.manual);
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'lastOpened',
            child: Row(
              children: [
                const Text('По недавним'),
                if (currentSortType == BookSortType.lastOpened) ...[
                  const Spacer(),
                  const Icon(Icons.check, size: 18),
                ],
              ],
            ),
          ),
          PopupMenuItem(
            value: 'name',
            child: Row(
              children: [
                Text(s.sortByName),
                if (currentSortType == BookSortType.name) ...[
                  const Spacer(),
                  const Icon(Icons.check, size: 18),
                ],
              ],
            ),
          ),
          PopupMenuItem(
            value: 'author',
            child: Row(
              children: [
                Text(s.sortByAuthor),
                if (currentSortType == BookSortType.author) ...[
                  const Spacer(),
                  const Icon(Icons.check, size: 18),
                ],
              ],
            ),
          ),
          PopupMenuItem(
            value: 'progress',
            child: Row(
              children: [
                Text(s.sortByProgress),
                if (currentSortType == BookSortType.progress) ...[
                  const Spacer(),
                  const Icon(Icons.check, size: 18),
                ],
              ],
            ),
          ),
          PopupMenuItem(
            value: 'manual',
            child: Row(
              children: [
                const Text('Вручную'),
                if (currentSortType == BookSortType.manual) ...[
                  const Spacer(),
                  const Icon(Icons.check, size: 18),
                ],
              ],
            ),
          ),
        ],
      );
    }
  }

  Widget _buildViewModeMenu(BuildContext context, S s) {
    final currentViewMode = settingsProvider.viewMode;

    if (Platform.isIOS) {
      final items = [
        CNPopupMenuItem(
          label: 'Сетка',
          icon: currentViewMode == ViewMode.grid 
              ? const CNSymbol('checkmark', size: 18)
              : null,
        ),
        CNPopupMenuItem(
          label: 'Список',
          icon: currentViewMode == ViewMode.list 
              ? const CNSymbol('checkmark', size: 18)
              : null,
        ),
      ];

      return CNPopupMenuButton.icon(
        buttonIcon: const CNSymbol('square.grid.2x2', size: 18),
        items: items,
        onSelected: (index) {
          if (index == 0) {
            settingsProvider.setViewMode(ViewMode.grid);
          } else if (index == 1) {
            settingsProvider.setViewMode(ViewMode.list);
          }
        },
      );
    } else {
      return PopupMenuButton<String>(
        icon: const Icon(Icons.view_module),
        onSelected: (value) {
          if (value == 'grid') {
            settingsProvider.setViewMode(ViewMode.grid);
          } else if (value == 'list') {
            settingsProvider.setViewMode(ViewMode.list);
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'grid',
            child: Row(
              children: [
                const Text('Сетка'),
                if (currentViewMode == ViewMode.grid) ...[
                  const Spacer(),
                  const Icon(Icons.check, size: 18),
                ],
              ],
            ),
          ),
          PopupMenuItem(
            value: 'list',
            child: Row(
              children: [
                const Text('Список'),
                if (currentViewMode == ViewMode.list) ...[
                  const Spacer(),
                  const Icon(Icons.check, size: 18),
                ],
              ],
            ),
          ),
        ],
      );
    }
  }
}

class _EmptyLibraryState extends StatelessWidget {
  final bool isSearching;
  final VoidCallback onAddTap;

  const _EmptyLibraryState({
    required this.isSearching,
    required this.onAddTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = S.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSearching ? Icons.search_off : Icons.auto_stories_outlined,
            size: 80,
            color: theme.colorScheme.secondary,
          ),
          const SizedBox(height: 16),
          Text(
            isSearching ? s.searchEmptyTitle : s.noBooksTitle,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            isSearching ? s.searchEmptySubtitle : s.noBooksSubtitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.secondary,
            ),
          ),
          const SizedBox(height: 24),
          if (!isSearching)
            FilledButton.icon(
              onPressed: onAddTap,
              icon: const Icon(Icons.add),
              label: Text(s.addBook),
            ),
        ],
      ),
    );
  }
}

