import 'package:flutter/material.dart';

/// Extensii pe [BuildContext] pentru layout responsive.
/// Folosire: `context.sw(0.5)` = 50% din lățimea ecranului.
extension ScreenUtils on BuildContext {
  MediaQueryData get _mq => MediaQuery.of(this);

  double get screenWidth => _mq.size.width;
  double get screenHeight => _mq.size.height;
  double get screenShortest => _mq.size.shortestSide;
  double get screenLongest => _mq.size.longestSide;

  /// Procent din lățimea ecranului (0.0 – 1.0).
  double sw(double factor) => screenWidth * factor;

  /// Procent din înălțimea ecranului (0.0 – 1.0).
  double sh(double factor) => screenHeight * factor;

  /// Dimensiune adaptivă: [base] pe ecran de referință 390 px lățime.
  double ad(double base) => (base * screenWidth / 390.0).clamp(base * 0.7, base * 1.4);

  bool get isSmallPhone => screenShortest < 360;
  bool get isPhone => screenShortest < 600;
  bool get isTablet => screenShortest >= 600;

  /// SafeArea insets.
  EdgeInsets get safeInsets => _mq.padding;
  double get topPadding => _mq.padding.top;
  double get bottomPadding => _mq.padding.bottom;

  /// Spațiu disponibil vertical după SafeArea și tastatură.
  double get availableHeight =>
      screenHeight - _mq.padding.top - _mq.padding.bottom - _mq.viewInsets.bottom;
}

/// [Scaffold.body] care nu dă overflow: wraps content în scroll vertical.
/// Folosit pe formulare și ecrane cu text mult.
class SafeScrollBody extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;

  const SafeScrollBody({
    super.key,
    required this.child,
    this.padding,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: backgroundColor ?? Colors.transparent,
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: padding,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
              minWidth: constraints.maxWidth,
            ),
            child: IntrinsicHeight(child: child),
          ),
        ),
      ),
    );
  }
}

/// Clamp text overflow: trunchiază și adaugă ellipsis automat.
class SafeText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final int maxLines;
  final TextAlign? textAlign;

  const SafeText(
    this.text, {
    super.key,
    this.style,
    this.maxLines = 1,
    this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: style,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      textAlign: textAlign,
    );
  }
}

/// Row care nu dă overflow: copilul flexibil e primul din [children] marcat cu [Flexible].
/// Dacă nu există [Flexible]/[Expanded] în children, îi wrappează automat pe toți în [Flexible].
class SafeRow extends StatelessWidget {
  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;

  const SafeRow({
    super.key,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mainAxisSize = MainAxisSize.max,
  });

  @override
  Widget build(BuildContext context) {
    final hasFlexible = children.any((w) => w is Flexible || w is Expanded);
    final wrappedChildren = hasFlexible
        ? children
        : children.map<Widget>((w) => Flexible(child: w)).toList();

    return Row(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: mainAxisSize,
      children: wrappedChildren,
    );
  }
}

/// Container care nu depășește lățimea ecranului, cu clipping automat.
class BoundedBox extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final double? maxHeight;
  final EdgeInsetsGeometry? padding;
  final BoxDecoration? decoration;

  const BoundedBox({
    super.key,
    required this.child,
    this.maxWidth,
    this.maxHeight,
    this.padding,
    this.decoration,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, outer) => Container(
        constraints: BoxConstraints(
          maxWidth: (maxWidth ?? double.infinity).clamp(0, outer.maxWidth),
          maxHeight: maxHeight ?? double.infinity,
        ),
        padding: padding,
        decoration: decoration,
        clipBehavior: Clip.hardEdge,
        child: child,
      ),
    );
  }
}
