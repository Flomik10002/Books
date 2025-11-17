import 'package:flutter/material.dart';

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

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.book_outlined),
            label: s.readingNowTab,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.library_books_outlined),
            label: s.libraryTab,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings_outlined),
            label: s.settingsTab,
          ),
        ],
      ),
    );
  }
}

