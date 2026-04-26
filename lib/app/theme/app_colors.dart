import 'package:flutter/cupertino.dart';

class AppColors {
  AppColors._();

  // Brand — Claude palette
  static const Color seedColor = Color(0xFFDB952C); // Brand gold
  static const Color brandCream = Color(0xFFFAF3E3); // Claude warm cream
  static const Color brandCharcoal = Color(0xFF1C1917); // Claude warm dark
  static const Color webDarkBackground = Color(0xFF181818);

  // CTA gradient
  static const Color ctaStart = Color(0xFFFFBD59); // top-left
  static const Color ctaEnd = Color(0xFFDB952C); // bottom-right
  static const LinearGradient ctaGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [ctaStart, ctaEnd],
  );

  // HTTP Method Colors
  static const Color methodGet = Color(0xFF2ECC71);
  static const Color methodPost = Color(0xFFE67E22);
  static const Color methodPut = Color(0xFF3498DB);
  static const Color methodPatch = Color(0xFFF39C12);
  static const Color methodDelete = Color(0xFFE74C3C);
  static const Color methodHead = Color(0xFF95A5A6);
  static const Color methodOptions = Color(0xFF95A5A6);

  // Status Code Colors
  static const Color status2xx = Color(0xFF2ECC71);
  static const Color status3xx = Color(0xFF3498DB);
  static const Color status4xx = Color(0xFFE67E22);
  static const Color status5xx = Color(0xFFE74C3C);

  // Code Editor Background
  static const Color editorDark = Color(0xFF1C1917); // warm charcoal
  static const Color editorLight = Color(0xFFFAF3E3); // warm cream

  static Color methodColor(String method) {
    switch (method.toUpperCase()) {
      case 'GET':
        return methodGet;
      case 'POST':
        return methodPost;
      case 'PUT':
        return methodPut;
      case 'PATCH':
        return methodPatch;
      case 'DELETE':
        return methodDelete;
      default:
        return methodHead;
    }
  }

  static Color statusColor(int statusCode) {
    if (statusCode >= 200 && statusCode < 300) return status2xx;
    if (statusCode >= 300 && statusCode < 400) return status3xx;
    if (statusCode >= 400 && statusCode < 500) return status4xx;
    if (statusCode >= 500) return status5xx;
    return methodHead;
  }
}
