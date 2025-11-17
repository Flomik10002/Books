import 'dart:ui';
import 'package:flutter/material.dart';

/// Базовый виджет Liquid Glass - основа единого визуального языка
/// 
/// Реализует эффект жидкого стекла с:
/// - Гауссовым блюром фона
/// - Прозрачностью материала
/// - Обводкой (границей)
/// - Внутренними и внешними тенями
/// - Скруглением углов
/// - Анимациями взаимодействия
class LiquidGlass extends StatefulWidget {
  final Widget child;
  final double blurSigma;
  final double opacity;
  final double borderRadius;
  final double borderWidth;
  final double borderOpacity;
  final List<BoxShadow>? customShadows;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Color? backgroundColor;
  final VoidCallback? onTap;
  final bool enabled;
  final Duration animationDuration;
  final Curve animationCurve;

  const LiquidGlass({
    super.key,
    required this.child,
    this.blurSigma = 15.0,
    this.opacity = 0.14,
    this.borderRadius = 22.0,
    this.borderWidth = 0.7,
    this.borderOpacity = 0.24,
    this.customShadows,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.onTap,
    this.enabled = true,
    this.animationDuration = const Duration(milliseconds: 180),
    this.animationCurve = const Cubic(0.25, 0.46, 0.45, 0.94),
  });

  @override
  State<LiquidGlass> createState() => _LiquidGlassState();
}

class _LiquidGlassState extends State<LiquidGlass>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(
        parent: _controller,
        curve: widget.animationCurve,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (!widget.enabled || widget.onTap == null) return;
    setState(() => _isPressed = true);
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    if (!widget.enabled || widget.onTap == null) return;
    setState(() => _isPressed = false);
    _controller.reverse();
    widget.onTap?.call();
  }

  void _handleTapCancel() {
    if (!widget.enabled || widget.onTap == null) return;
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Определяем цвет основы в зависимости от темы
    final baseColor = widget.backgroundColor ??
        (isDark ? Colors.white : Colors.black);
    
    // Прозрачность материала
    final materialOpacity = widget.enabled
        ? widget.opacity
        : widget.opacity * 0.5; // Уменьшенная для disabled
    
    // Обводка
    final borderOpacity = widget.enabled
        ? widget.borderOpacity
        : widget.borderOpacity * 0.5;
    
    // Тени
    final shadows = widget.customShadows ??
        _buildDefaultShadows(isDark, _isPressed);
    
    final content = Container(
      margin: widget.margin,
      padding: widget.padding,
      decoration: BoxDecoration(
        color: baseColor.withValues(alpha: materialOpacity),
        borderRadius: BorderRadius.circular(widget.borderRadius),
        border: Border.all(
          color: baseColor.withValues(alpha: borderOpacity),
          width: widget.borderWidth,
        ),
        boxShadow: shadows,
      ),
      child: widget.child,
    );

    // Применяем блюр через BackdropFilter
    final blurredContent = ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: widget.blurSigma,
          sigmaY: widget.blurSigma,
        ),
        child: content,
      ),
    );

    // Если есть обработчик тапа, оборачиваем в GestureDetector
    if (widget.onTap != null && widget.enabled) {
      return AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: GestureDetector(
              onTapDown: _handleTapDown,
              onTapUp: _handleTapUp,
              onTapCancel: _handleTapCancel,
              behavior: HitTestBehavior.opaque,
              child: blurredContent,
            ),
          );
        },
      );
    }

    return blurredContent;
  }

  List<BoxShadow> _buildDefaultShadows(bool isDark, bool isPressed) {
    if (isPressed) {
      // При нажатии тень становится слабее (материал "прилипает")
      return [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.12 : 0.10),
          blurRadius: 12,
          spreadRadius: 0,
          offset: const Offset(0, 6),
        ),
      ];
    }

    // Внешняя тень
    final outerShadow = BoxShadow(
      color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.15),
      blurRadius: 20,
      spreadRadius: 0,
      offset: const Offset(0, 10),
    );

    // Внутренняя тень (создаёт ощущение толщины стекла)
    final innerShadow = BoxShadow(
      color: Colors.white.withValues(alpha: isDark ? 0.08 : 0.06),
      blurRadius: 5,
      spreadRadius: 0,
      offset: const Offset(0, -1),
    );

    return [outerShadow, innerShadow];
  }
}

/// Утилиты для создания стандартных конфигураций Liquid Glass
class LiquidGlassStyles {
  // Bottom Navigation Bar
  static const bottomBar = LiquidGlassConfig(
    blurSigma: 18.0,
    opacity: 0.16,
    borderRadius: 30.0,
    borderWidth: 0.7,
    borderOpacity: 0.24,
  );

  // Context Menu
  static const contextMenu = LiquidGlassConfig(
    blurSigma: 14.0,
    opacity: 0.16,
    borderRadius: 20.0,
    borderWidth: 0.7,
    borderOpacity: 0.24,
  );

  // Modal Bottom Sheet
  static const bottomSheet = LiquidGlassConfig(
    blurSigma: 22.0,
    opacity: 0.18,
    borderRadius: 36.0,
    borderWidth: 0.8,
    borderOpacity: 0.28,
  );

  // Reader Controls
  static const readerControls = LiquidGlassConfig(
    blurSigma: 14.0,
    opacity: 0.14,
    borderRadius: 18.0,
    borderWidth: 0.7,
    borderOpacity: 0.24,
  );

  // Cards
  static const card = LiquidGlassConfig(
    blurSigma: 12.0,
    opacity: 0.10,
    borderRadius: 16.0,
    borderWidth: 0.5,
    borderOpacity: 0.20,
  );

  // Search Bar / Filters
  static const searchBar = LiquidGlassConfig(
    blurSigma: 10.0,
    opacity: 0.12,
    borderRadius: 16.0,
    borderWidth: 0.5,
    borderOpacity: 0.20,
  );

  // Buttons
  static const button = LiquidGlassConfig(
    blurSigma: 12.0,
    opacity: 0.14,
    borderRadius: 18.0,
    borderWidth: 0.6,
    borderOpacity: 0.24,
  );

  // AppBar / TopBar
  static const appBar = LiquidGlassConfig(
    blurSigma: 16.0,
    opacity: 0.14,
    borderRadius: 0.0, // Обычно без скругления для AppBar
    borderWidth: 0.7,
    borderOpacity: 0.24,
  );

  // Dialog
  static const dialog = LiquidGlassConfig(
    blurSigma: 20.0,
    opacity: 0.18,
    borderRadius: 24.0,
    borderWidth: 0.8,
    borderOpacity: 0.28,
  );
}

/// Конфигурация для Liquid Glass
class LiquidGlassConfig {
  final double blurSigma;
  final double opacity;
  final double borderRadius;
  final double borderWidth;
  final double borderOpacity;

  const LiquidGlassConfig({
    required this.blurSigma,
    required this.opacity,
    required this.borderRadius,
    required this.borderWidth,
    required this.borderOpacity,
  });
}

/// Расширение для применения конфигурации к виджету
extension LiquidGlassConfigExtension on LiquidGlassConfig {
  LiquidGlass apply({
    required Widget child,
    EdgeInsets? padding,
    EdgeInsets? margin,
    VoidCallback? onTap,
    bool enabled = true,
    List<BoxShadow>? customShadows,
  }) {
    return LiquidGlass(
      blurSigma: blurSigma,
      opacity: opacity,
      borderRadius: borderRadius,
      borderWidth: borderWidth,
      borderOpacity: borderOpacity,
      padding: padding,
      margin: margin,
      onTap: onTap,
      enabled: enabled,
      customShadows: customShadows,
      child: child,
    );
  }
}

