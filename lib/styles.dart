import 'package:flutter/material.dart';

const Color primaryColor = Color(0xFF0D3B91);
const Color accentPurple = Color(0xFF7C3AED);
const Color accentPink = Color(0xFFEF6CDE);
const Color accentYellow = Color(0xFFFFB020);
const Color softBackground = Color(0xFFF5F6FA);

LinearGradient headerGradient = const LinearGradient(
  colors: [primaryColor, Color(0xFF0B2F72)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

RoundedRectangleBorder defaultCardShape = RoundedRectangleBorder(
  borderRadius: BorderRadius.circular(16),
);
