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
