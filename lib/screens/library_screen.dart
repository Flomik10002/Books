import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../generated/l10n.dart';
import '../models/book.dart';
import '../providers/book_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/book_card.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  String _searchQuery = '';
  bool _isSearching = false;

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
                          onEditTap: () {},
                          onSearchTap: () => setState(() => _isSearching = true),
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _SortRow(
                    sortType: settingsProvider.sortType,
                    ascending: settingsProvider.sortAscending,
                    onSortSelected: (type) => settingsProvider.setSortType(type),
                    onToggleDirection: () =>
                        settingsProvider.setSortAscending(!settingsProvider.sortAscending),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: filteredBooks.isEmpty
                      ? _EmptyLibraryState(
                          isSearching: _searchQuery.isNotEmpty,
                          onAddTap: () => _pickAndAddBook(context),
                        )
                      : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: GridView.builder(
                            itemCount: filteredBooks.length,
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 28,
                              crossAxisSpacing: 12,
                              childAspectRatio: 0.52,
                            ),
                            itemBuilder: (context, index) => BookCard(book: filteredBooks[index]),
                          ),
                        ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: FloatingActionButton.extended(
          onPressed: () => _pickAndAddBook(context),
          icon: const Icon(Icons.add),
          label: Text(s.addBook),
        ),
      ),
    );
  }

  Widget _buildSearchBar(S s) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            autofocus: true,
            decoration: InputDecoration(
              hintText: s.searchHint,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _searchQuery = ''),
                    )
                  : null,
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => setState(() {
              _isSearching = false;
              _searchQuery = '';
          }),
        ),
      ],
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
  final VoidCallback onEditTap;
  final VoidCallback onSearchTap;

  const _HeaderArea({
    required this.totalBooks,
    required this.onEditTap,
    required this.onSearchTap,
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
            TextButton(
              onPressed: onEditTap,
              child: Text(s.edit),
            ),
            IconButton(
              onPressed: onSearchTap,
              icon: const Icon(Icons.search),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const Icon(Icons.folder_copy_outlined),
            title: Text(
              s.collections,
              style: theme.textTheme.bodyLarge,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
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
}

class _SortRow extends StatelessWidget {
  final BookSortType sortType;
  final bool ascending;
  final ValueChanged<BookSortType> onSortSelected;
  final VoidCallback onToggleDirection;

  const _SortRow({
    required this.sortType,
    required this.ascending,
    required this.onSortSelected,
    required this.onToggleDirection,
  });

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);

    return Row(
      children: [
        Text(
          '${s.sortLabel}:',
          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(width: 8),
        _SortSelector(
          currentType: sortType,
          onSelected: onSortSelected,
        ),
        IconButton(
          icon: Icon(
            ascending ? Icons.arrow_upward : Icons.arrow_downward,
          ),
          onPressed: onToggleDirection,
        ),
      ],
    );
  }
}

class _SortSelector extends StatelessWidget {
  final BookSortType currentType;
  final ValueChanged<BookSortType> onSelected;

  const _SortSelector({
    required this.currentType,
    required this.onSelected,
  });

  String _labelFor(BookSortType type, S s) {
    switch (type) {
      case BookSortType.name:
        return s.sortByName;
      case BookSortType.dateAdded:
        return s.sortByDate;
      case BookSortType.progress:
        return s.sortByProgress;
      case BookSortType.author:
        return s.sortByAuthor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return PopupMenuButton<BookSortType>(
      onSelected: onSelected,
      itemBuilder: (context) => BookSortType.values
          .map(
            (type) => PopupMenuItem(
              value: type,
              child: Text(_labelFor(type, s)),
            ),
          )
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_labelFor(currentType, s)),
            const SizedBox(width: 4),
            const Icon(Icons.expand_more, size: 16),
          ],
        ),
      ),
    );
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

