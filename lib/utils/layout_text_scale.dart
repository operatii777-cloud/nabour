import 'package:flutter/widgets.dart';

/// Factor din [TextScaler] (setări accesibilitate / font sistem), folosit pentru
/// înălțimi și padding-uri fixe ca să nu fie tăiate când textul e mai mare.
///
/// Folosește aceeași scalare pe care o vede arborele după [MaterialApp.builder].
///
/// Pe unele telefoane (ex. MIUI) fontul/emoji ies mai „mari” decât pe tablete la
/// aceeași lățime; [boldText] și lățimea mică măresc ușor factorul de layout.
double layoutScaleFactor(BuildContext context) {
  final mq = MediaQuery.of(context);
  final ts = mq.textScaler;
  const ref = 14.0;
  var f = ts.scale(ref) / ref;
  if (mq.boldText) {
    f *= 1.05;
  }
  if (mq.size.width < 400) {
    f *= 1.06;
  }
  return f.clamp(0.85, 2.0);
}

EdgeInsets scaledFromLTRB(
  double left,
  double top,
  double right,
  double bottom,
  double scale,
) {
  return EdgeInsets.fromLTRB(
    left * scale,
    top * scale,
    right * scale,
    bottom * scale,
  );
}
