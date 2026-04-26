
import 'package:flutter/material.dart';
class TestWidget extends StatefulWidget {
  const TestWidget({super.key});
  @override State<TestWidget> createState() => _TestWidgetState();
}
class _TestWidgetState extends State<TestWidget> {
  int x = 0;
  @override Widget build(BuildContext context) => Text(x.toString());
}

