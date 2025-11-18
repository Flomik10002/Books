import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cupertino_native/cupertino_native.dart';

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
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
          // Native iOS Liquid Glass Tab Bar at bottom
          if (Platform.isIOS)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: CNTabBar(
                items: [
                  CNTabBarItem(
                    label: s.readingNowTab,
                    icon: const CNSymbol('book.fill'),
                  ),
                  CNTabBarItem(
                    label: s.libraryTab,
                    icon: const CNSymbol('books.vertical.fill'),
                  ),
                  CNTabBarItem(
                    label: s.settingsTab,
                    icon: const CNSymbol('gearshape.fill'),
                  ),
                ],
                currentIndex: _currentIndex,
                onTap: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
              ),
            ),
          // Material Bottom Navigation Bar for Android
          if (!Platform.isIOS)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: BottomNavigationBar(
                currentIndex: _currentIndex,
                onTap: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                items: [
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.book_outlined),
                    activeIcon: const Icon(Icons.book),
                    label: s.readingNowTab,
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.library_books_outlined),
                    activeIcon: const Icon(Icons.library_books),
                    label: s.libraryTab,
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.settings_outlined),
                    activeIcon: const Icon(Icons.settings),
                    label: s.settingsTab,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

