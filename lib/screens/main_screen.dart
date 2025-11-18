import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';

import '../generated/l10n.dart';
import 'library_screen.dart';
import 'reading_now_screen.dart';
import 'settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    ReadingNowScreen(),
    LibraryScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return AdaptiveScaffold(
      appBar: AdaptiveAppBar(
        useNativeToolbar: true,
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: AdaptiveBottomNavigationBar(
        items: [
          AdaptiveNavigationDestination(
            icon: PlatformInfo.isIOS26OrHigher()
                ? "book.fill"
                : PlatformInfo.isIOS
                    ? CupertinoIcons.book
                    : Icons.book_outlined,
            selectedIcon: PlatformInfo.isIOS26OrHigher()
                ? "book.fill"
                : PlatformInfo.isIOS
                    ? CupertinoIcons.book_fill
                    : Icons.book,
            label: s.readingNowTab,
          ),
          AdaptiveNavigationDestination(
            icon: PlatformInfo.isIOS26OrHigher()
                ? "books.vertical.fill"
                : PlatformInfo.isIOS
                    ? CupertinoIcons.book_solid
                    : Icons.library_books_outlined,
            selectedIcon: PlatformInfo.isIOS26OrHigher()
                ? "books.vertical.fill"
                : PlatformInfo.isIOS
                    ? CupertinoIcons.book_solid
                    : Icons.library_books,
            label: s.libraryTab,
          ),
          AdaptiveNavigationDestination(
            icon: PlatformInfo.isIOS26OrHigher()
                ? "gearshape.fill"
                : PlatformInfo.isIOS
                    ? CupertinoIcons.settings
                    : Icons.settings_outlined,
            selectedIcon: PlatformInfo.isIOS26OrHigher()
                ? "gearshape.fill"
                : PlatformInfo.isIOS
                    ? CupertinoIcons.settings_solid
                    : Icons.settings,
            label: s.settingsTab,
          ),
        ],
        selectedIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}

