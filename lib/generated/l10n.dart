import 'package:flutter/widgets.dart';

class S {
  S(this.localeName);

  final String localeName;

  static S of(BuildContext context) {
    return Localizations.of<S>(context, S)!;
  }

  static const LocalizationsDelegate<S> delegate = _SDelegate();

  // Core sections
  String get settings => 'Settings';
  String get theme => 'Appearance';
  String get readingSection => 'Reading';
  String get about => 'About';

  // Theme mode labels
  String get systemTheme => 'System';
  String get lightTheme => 'Light';
  String get darkTheme => 'Dark';

  // Library / navigation
  String get readingNowTab => 'Reading Now';
  String get libraryTab => 'Library';
  String get settingsTab => 'Settings';
  String get libraryTitle => 'Library';
  String get addBook => 'Add Book';
  String get edit => 'Edit';
  String get collections => 'Collections';
  String booksCount(int count) => count == 1 ? '1 Book' : '$count Books';
  String get sortLabel => 'Sort';
  String get sortByName => 'Name';
  String get sortByDate => 'Date Added';
  String get sortByProgress => 'Progress';
  String get sortByAuthor => 'Author';
  String get searchHint => 'Search by title or author';
  String get searchEmptyTitle => 'Nothing found';
  String get searchEmptySubtitle => 'Try changing your search query';

  // Book actions & metadata
  String get renameBook => 'Rename';
  String get changeAuthor => 'Change Author';
  String get changeCover => 'Change Cover';
  String get changeCoverDescription => 'Choose a new cover image for this book';
  String get chooseFile => 'Choose File';
  String get resetToDefault => 'Reset';
  String get bookInfoTitle => 'Book Info';
  String get bookTitleLabel => 'Book title';
  String get authorLabel => 'Author';
  String get bookUpdated => 'Book title updated';
  String get authorUpdated => 'Author updated';
  String get coverUpdated => 'Cover updated';
  String get coverReset => 'Cover reset';
  String get bookDeleted => 'Book deleted';
  String get resetReadingProgress => 'Reset progress';
  String get readingProgressReset => 'Progress and history cleared';

  // Dialog buttons
  String get save => 'Save';
  String get cancel => 'Cancel';
  String get ok => 'OK';
  String get delete => 'Delete';

  // Reader / progress
  String get readingNowSection => 'Reading Now';
  String get recentlyOpenedSection => 'Recently Opened';
  String get readingNowHint => 'Tap a cover to continue reading.';
  String get readingNowEmptyTitle => 'You have no books opened recently.';
  String get readingNowEmptySubtitle => 'Add a book to start reading!';
  String get recentlyOpenedEmpty => 'Books you open will appear here.';
  String continueReadingLabel(int current, int total) =>
      'Continue at page $current of $total';
  String progressShort(int percent) => '$percent% read';
  String readingProgress(String progress, int current, int total) =>
      '$progress% • Page $current/$total';

  // States
  String get noBooksTitle => 'No books';
  String get noBooksSubtitle => 'Tap + to add your first PDF book';
  String get noBookmarks => 'No bookmarks yet';
  String get bookmarkAdded => 'Bookmark added';
  String get bookmarkRemoved => 'Bookmark removed';
  String get bookmarks => 'Bookmarks';
  String get removeBookmark => 'Remove bookmark';
  String get notStarted => 'Not started';

  // Reader strings
  String get loadingPdf => 'Loading PDF...';
  String get fileNotFound => 'File not found';
  String get fileNotFoundMessage => 'The PDF file was deleted or moved';
  String get pdfLoadError => 'Could not load the PDF file.';
  String get goToPage => 'Go to page';
  String get enterPageNumber => 'Enter page number';
  String get jumpToPage => 'Jump';
  String get invalidPageNumber => 'Invalid page number';
  String get page => 'Page';
  String get ofPages => 'of';
  String get openBook => 'Open book';
  String get share => 'Share';

  // Add / delete book
  String get bookAddedSuccess => 'Book added successfully!';
  String get bookAddedError => 'Error adding book';
  String deleteBookMessage(String title) =>
      'Are you sure you want to delete "$title"? This can’t be undone.';
  String get deleteBookTitle => 'Delete book?';

  // Settings
  String get fontSize => 'Font size';
  String get brightness => 'Brightness';
  String get keepScreenOn => 'Keep screen on';
  String get keepScreenOnDescription => 'Prevent the display from sleeping while reading.';

  // Errors
  String get error => 'Error';

  // Localization delegate requirements
  static const List<Locale> supportedLocales = [Locale('en')];
}

class _SDelegate extends LocalizationsDelegate<S> {
  const _SDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'en';

  @override
  Future<S> load(Locale locale) async => S(locale.toString());

  @override
  bool shouldReload(_SDelegate old) => false;
}

