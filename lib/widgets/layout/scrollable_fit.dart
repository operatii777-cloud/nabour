import 'package:flutter/material.dart';

/// Corp de ecran cu scroll vertical când conținutul depășește spațiul
/// (ecrane înguste, tastatură, font mărit).
///
/// Folosește-l ca înlocuitor pentru `Column`/`Padding` direct în `Scaffold.body`
/// pe formulare și ecrane cu mult text.
class ScrollableFit extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;

  const ScrollableFit({
    super.key,
    required this.child,
    this.padding,
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: physics ?? const AlwaysScrollableScrollPhysics(),
          padding: padding,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: child,
          ),
        );
      },
    );
  }
}

/// Rând care nu lasă textul să iasă din ecran: primul [flexibleChild] în [Expanded].
class OverflowSafeRow extends StatelessWidget {
  final List<Widget> leading;
  final Widget flexibleChild;
  final List<Widget> trailing;
  final CrossAxisAlignment crossAxisAlignment;

  const OverflowSafeRow({
    super.key,
    this.leading = const [],
    required this.flexibleChild,
    this.trailing = const [],
    this.crossAxisAlignment = CrossAxisAlignment.center,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        ...leading,
        Expanded(child: flexibleChild),
        ...trailing,
      ],
    );
  }
}

/// Wrapper pentru bottom sheet-uri și dialogs care trebuie să se adapteze la
/// înălțimea ecranului și tastatura virtuală.
class AdaptiveSheetBody extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  /// Fracțiune maximă din înălțimea ecranului (default 0.92).
  final double maxHeightFactor;

  const AdaptiveSheetBody({
    super.key,
    required this.child,
    this.padding,
    this.maxHeightFactor = 0.92,
  });

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final maxH = mq.size.height * maxHeightFactor - mq.viewInsets.bottom;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxH.clamp(100, double.infinity)),
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: padding,
        child: child,
      ),
    );
  }
}

/// Column care nu dă overflow: dacă conținutul e prea mare, devine scrollabil.
class SafeColumn extends StatelessWidget {
  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;
  final EdgeInsetsGeometry? padding;

  const SafeColumn({
    super.key,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mainAxisSize = MainAxisSize.min,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final col = Column(
          mainAxisAlignment: mainAxisAlignment,
          crossAxisAlignment: crossAxisAlignment,
          mainAxisSize: mainAxisSize,
          children: children,
        );
        if (constraints.maxHeight == double.infinity) return col;

        return SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: padding,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: col,
          ),
        );
      },
    );
  }
}
