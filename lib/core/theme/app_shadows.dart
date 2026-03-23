import 'package:flutter/material.dart';

class AppShadows {
  static const panel = [
    BoxShadow(
      color: Color(0x1F101828),
      blurRadius: 36,
      offset: Offset(0, 18),
    ),
  ];

  static const button = [
    BoxShadow(
      color: Color(0x331D4ED8),
      blurRadius: 26,
      offset: Offset(0, 14),
    ),
  ];

  const AppShadows._();
}
