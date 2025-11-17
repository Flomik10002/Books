import 'dart:ui';
import 'package:flutter/material.dart';
import 'liquid_glass.dart';

/// Нижняя навигационная панель в стиле Liquid Glass
class LiquidGlassBottomBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<BottomNavigationBarItem> items;
  final double? height;

  const LiquidGlassBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.height = 72.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: LiquidGlassStyles.bottomBar.apply(
        padding: EdgeInsets.zero,
        child: Container(
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (index) {
              final item = items[index];
              final isActive = index == currentIndex;
              
              // Определяем виджет иконки для отображения
              Widget iconWidget;
              if (isActive && item.activeIcon != null) {
                iconWidget = item.activeIcon!;
              } else {
                iconWidget = item.icon;
              }
              
              // Извлекаем IconData из виджета, если это Icon
              IconData? iconData;
              if (iconWidget is Icon) {
                iconData = iconWidget.icon;
              }
              
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(index),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (iconData != null)
                        Icon(
                          iconData,
                          size: isActive ? 28 : 22,
                          color: isActive
                              ? (isDark ? const Color(0xFF4da3ff) : theme.colorScheme.primary)
                              : (isDark ? Colors.white.withValues(alpha: 0.6) : Colors.black.withValues(alpha: 0.5)),
                        )
                      else
                        SizedBox(
                          width: isActive ? 28 : 22,
                          height: isActive ? 28 : 22,
                          child: iconWidget,
                        ),
                      const SizedBox(height: 4),
                      Text(
                        item.label ?? '',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                          color: isActive
                              ? (isDark ? const Color(0xFF4da3ff) : theme.colorScheme.primary)
                              : (isDark ? Colors.white.withValues(alpha: 0.6) : Colors.black.withValues(alpha: 0.5)),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

/// Карточка в стиле Liquid Glass
class LiquidGlassCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final bool enabled;

  const LiquidGlassCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.margin,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return LiquidGlassStyles.card.apply(
      padding: padding ?? const EdgeInsets.all(16),
      margin: margin,
      onTap: onTap,
      enabled: enabled,
      customShadows: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 8,
          spreadRadius: 0,
          offset: const Offset(0, 4),
        ),
      ],
      child: child,
    );
  }
}

/// Кнопка в стиле Liquid Glass
class LiquidGlassButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final bool enabled;
  final EdgeInsets? padding;
  final double? minWidth;
  final double? minHeight;

  const LiquidGlassButton({
    super.key,
    required this.child,
    this.onPressed,
    this.enabled = true,
    this.padding,
    this.minWidth,
    this.minHeight,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return LiquidGlassStyles.button.apply(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      onTap: enabled ? onPressed : null,
      enabled: enabled,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: minWidth ?? 0,
          minHeight: minHeight ?? 0,
        ),
        child: DefaultTextStyle(
          style: TextStyle(
            color: enabled
                ? (isDark ? Colors.white : Colors.black.withValues(alpha: 0.85))
                : (isDark ? Colors.white.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.3)),
            fontWeight: FontWeight.w500,
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Контекстное меню в стиле Liquid Glass
class LiquidGlassMenu extends StatelessWidget {
  final List<LiquidGlassMenuItem> items;
  final EdgeInsets? padding;

  const LiquidGlassMenu({
    super.key,
    required this.items,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return LiquidGlassStyles.contextMenu.apply(
      padding: padding ?? const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: items.map((item) {
          return _MenuItemTile(
            item: item,
            isLast: item == items.last,
          );
        }).toList(),
      ),
    );
  }
}

class LiquidGlassMenuItem {
  final IconData? icon;
  final String title;
  final VoidCallback? onTap;
  final Color? color;
  final bool enabled;

  const LiquidGlassMenuItem({
    this.icon,
    required this.title,
    this.onTap,
    this.color,
    this.enabled = true,
  });
}

class _MenuItemTile extends StatelessWidget {
  final LiquidGlassMenuItem item;
  final bool isLast;

  const _MenuItemTile({
    required this.item,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = item.color ??
        (isDark ? Colors.white : Colors.black.withValues(alpha: 0.85));
    
    return InkWell(
      onTap: item.enabled ? item.onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            if (item.icon != null) ...[
              Icon(
                item.icon,
                size: 20,
                color: item.enabled
                    ? textColor
                    : textColor.withValues(alpha: 0.3),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                item.title,
                style: TextStyle(
                  color: item.enabled
                      ? textColor
                      : textColor.withValues(alpha: 0.3),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Верхняя панель (AppBar) в стиле Liquid Glass
class LiquidGlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final double? elevation;

  const LiquidGlassAppBar({
    super.key,
    this.title,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.elevation,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black)
            .withValues(alpha: LiquidGlassStyles.appBar.opacity),
        border: Border(
          bottom: BorderSide(
            color: (isDark ? Colors.white : Colors.black)
                .withValues(alpha: LiquidGlassStyles.appBar.borderOpacity),
            width: LiquidGlassStyles.appBar.borderWidth,
          ),
        ),
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: LiquidGlassStyles.appBar.blurSigma,
            sigmaY: LiquidGlassStyles.appBar.blurSigma,
          ),
          child: AppBar(
            title: title,
            actions: actions,
            leading: leading,
            automaticallyImplyLeading: automaticallyImplyLeading,
            elevation: 0,
            backgroundColor: Colors.transparent,
            foregroundColor: isDark ? Colors.white : Colors.black.withValues(alpha: 0.85),
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// Поисковая строка в стиле Liquid Glass
class LiquidGlassSearchBar extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final Widget? prefixIcon;
  final Widget? suffixIcon;

  const LiquidGlassSearchBar({
    super.key,
    this.controller,
    this.hintText,
    this.onChanged,
    this.onClear,
    this.prefixIcon,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return LiquidGlassStyles.searchBar.apply(
      padding: EdgeInsets.zero,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black.withValues(alpha: 0.85),
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: isDark
                ? Colors.white.withValues(alpha: 0.5)
                : Colors.black.withValues(alpha: 0.4),
          ),
          prefixIcon: prefixIcon ??
              Icon(
                Icons.search,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.6)
                    : Colors.black.withValues(alpha: 0.5),
              ),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }
}

/// Селектор/фильтр в стиле Liquid Glass
class LiquidGlassSelector<T> extends StatelessWidget {
  final T value;
  final List<T> options;
  final String Function(T) labelBuilder;
  final ValueChanged<T> onSelected;
  final IconData? icon;

  const LiquidGlassSelector({
    super.key,
    required this.value,
    required this.options,
    required this.labelBuilder,
    required this.onSelected,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return LiquidGlassStyles.searchBar.apply(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      onTap: () => _showSelectorDialog(context),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 18,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.6)
                  : Colors.black.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 8),
          ],
          Text(
            labelBuilder(value),
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black.withValues(alpha: 0.85),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.expand_more,
            size: 16,
            color: isDark
                ? Colors.white.withValues(alpha: 0.6)
                : Colors.black.withValues(alpha: 0.5),
          ),
        ],
      ),
    );
  }

  void _showSelectorDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => LiquidGlassDialog(
        title: const Text('Select'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: options.map((option) {
            final isSelected = option == value;
            return ListTile(
              title: Text(labelBuilder(option)),
              trailing: isSelected
                  ? Icon(Icons.check, color: Theme.of(context).primaryColor)
                  : null,
              onTap: () {
                onSelected(option);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}

/// Диалог в стиле Liquid Glass
class LiquidGlassDialog extends StatelessWidget {
  final Widget? title;
  final Widget? content;
  final List<Widget>? actions;

  const LiquidGlassDialog({
    super.key,
    this.title,
    this.content,
    this.actions,
  });

  /// Показать диалог с поддержкой barrierDismissible
  static Future<T?> show<T>({
    required BuildContext context,
    Widget? title,
    Widget? content,
    List<Widget>? actions,
    bool barrierDismissible = true,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => LiquidGlassDialog(
        title: title,
        content: content,
        actions: actions,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: LiquidGlassStyles.dialog.apply(
        padding: EdgeInsets.zero,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (title != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: DefaultTextStyle(
                  style: Theme.of(context).textTheme.titleLarge!,
                  child: title!,
                ),
              ),
            if (content != null)
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: DefaultTextStyle(
                    style: Theme.of(context).textTheme.bodyMedium!,
                    child: content!,
                  ),
                ),
              ),
            if (actions != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: actions!,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

