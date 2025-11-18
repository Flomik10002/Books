import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

/// iOS 26 Liquid Glass Search Bar
/// 
/// Прозрачная поисковая строка с blur эффектом, которая:
/// - Расширяется при фокусе
/// - Имеет эффект блика, следующий за пальцем
/// - Использует SF Symbols иконки
class LiquidGlassSearchBar extends StatefulWidget {
  final String? hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClose;
  final TextEditingController? controller;
  final bool autofocus;

  const LiquidGlassSearchBar({
    super.key,
    this.hintText,
    this.onChanged,
    this.onClose,
    this.controller,
    this.autofocus = false,
  });

  @override
  State<LiquidGlassSearchBar> createState() => _LiquidGlassSearchBarState();
}

class _LiquidGlassSearchBarState extends State<LiquidGlassSearchBar>
    with SingleTickerProviderStateMixin {
  late FocusNode _focusNode;
  late AnimationController _expandController;
  late Animation<double> _expandAnimation;
  
  bool _isFocused = false;
  bool _hasText = false;
  Offset? _glowPosition;
  bool _isPressed = false;
  
  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
    
    _expandController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeOutCubic,
    );
    
    if (widget.controller != null) {
      _hasText = widget.controller!.text.isNotEmpty;
      widget.controller!.addListener(_onTextChange);
    }
    
    if (widget.autofocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _expandController.dispose();
    if (widget.controller != null) {
      widget.controller!.removeListener(_onTextChange);
    }
    super.dispose();
  }

  void _onFocusChange() {
    final isFocused = _focusNode.hasFocus;
    if (_isFocused != isFocused) {
      setState(() {
        _isFocused = isFocused;
      });
      
      if (isFocused) {
        _expandController.forward();
      } else {
        _expandController.reverse();
      }
    }
  }

  void _onTextChange() {
    final hasText = widget.controller?.text.isNotEmpty ?? false;
    if (_hasText != hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
  }

  void _onPanStart(DragStartDetails details) {
    if (Platform.isIOS) {
      setState(() {
        _isPressed = true;
        _glowPosition = details.localPosition;
      });
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (Platform.isIOS && _isPressed) {
      setState(() {
        _glowPosition = details.localPosition;
      });
    }
  }

  void _onPanEnd(DragEndDetails details) {
    if (Platform.isIOS) {
      // Плавно убираем блик
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() {
            _isPressed = false;
            _glowPosition = null;
          });
        }
      });
    }
  }

  void _onPanCancel() {
    if (Platform.isIOS) {
      setState(() {
        _isPressed = false;
        _glowPosition = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return AnimatedBuilder(
      animation: _expandAnimation,
      builder: (context, child) {
        return GestureDetector(
          onPanStart: _onPanStart,
          onPanUpdate: _onPanUpdate,
          onPanEnd: _onPanEnd,
          onPanCancel: _onPanCancel,
          child: Container(
            height: 50,
            margin: EdgeInsets.symmetric(
              horizontal: 20 * (1 - _expandAnimation.value * 0.3),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    color: (isDark 
                        ? Colors.white.withOpacity(0.1)
                        : Colors.black.withOpacity(0.05)
                    ).withOpacity(0.6 + _expandAnimation.value * 0.2),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 0.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Эффект блика, следующий за пальцем (только на iOS)
                      if (Platform.isIOS && _glowPosition != null)
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 50),
                          left: _glowPosition!.dx - 60,
                          top: _glowPosition!.dy - 60,
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 100),
                            opacity: _isPressed ? 1.0 : 0.0,
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    Colors.white.withOpacity(0.4),
                                    Colors.white.withOpacity(0.2),
                                    Colors.white.withOpacity(0.0),
                                  ],
                                  stops: const [0.0, 0.5, 1.0],
                                ),
                              ),
                            ),
                          ),
                        ),
                      
                      // Содержимое поисковой строки
                      Row(
                        children: [
                          const SizedBox(width: 16),
                          // Иконка поиска
                          Icon(
                            CupertinoIcons.search,
                            color: Colors.white.withOpacity(0.7),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          // Текстовое поле
                          Expanded(
                            child: CupertinoTextField(
                              controller: widget.controller,
                              focusNode: _focusNode,
                              placeholder: widget.hintText ?? 'Search',
                              placeholderStyle: TextStyle(
                                color: Colors.white.withOpacity(0.4),
                                fontSize: 16,
                              ),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 16,
                              ),
                              decoration: const BoxDecoration(),
                              onChanged: (value) {
                                setState(() {
                                  _hasText = value.isNotEmpty;
                                });
                                widget.onChanged?.call(value);
                              },
                              suffix: _hasText
                                  ? GestureDetector(
                                      onTap: () {
                                        widget.controller?.clear();
                                        setState(() {
                                          _hasText = false;
                                        });
                                        widget.onChanged?.call('');
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        child: Icon(
                                          CupertinoIcons.clear_circled_solid,
                                          color: Colors.white.withOpacity(0.6),
                                          size: 18,
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Кнопка закрытия
                          if (widget.onClose != null)
                            GestureDetector(
                              onTap: widget.onClose,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                child: Icon(
                                  CupertinoIcons.xmark,
                                  color: Colors.white.withOpacity(0.7),
                                  size: 18,
                                ),
                              ),
                            ),
                          const SizedBox(width: 8),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

