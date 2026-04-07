import 'package:flutter/material.dart';

/// Un widget care desenează steagul României.
///
/// Poate fi scalat folosind parametrii `width` și `height`.
class RomanianFlag extends StatelessWidget {
  final double width;
  final double height;

  const RomanianFlag({
    super.key,
    this.width = 30.0,
    this.height = 20.0,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(2.0),
      child: SizedBox(
        width: width,
        height: height,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: ColoredBox(color: Color(0xFF002B7F))), // albastru
            Expanded(child: ColoredBox(color: Color(0xFFFCD116))), // galben
            Expanded(child: ColoredBox(color: Color(0xFFCE1126))), // roșu
          ],
        ),
      ),
    );
  }
}


