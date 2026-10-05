import 'package:flutter/material.dart';

/// Semantic, high-contrast dark luxury financial color tokens.
class AppColors {
  AppColors._();

  // Background & Surfaces
  static const Color deepSlate = Color(0xFF0F172A);      // #0F172A - Main Scaffold Canvas
  static const Color cardSurface = Color(0xFF1E293B);    // #1E293B - Cards, Modals, Sheets
  static const Color surfaceElevated = Color(0xFF334155);// #334155 - Elevated Panels, Hover
  static const Color borderSubtle = Color(0xFF475569);   // #475569 - Dividers, Outlines
  static const Color borderHighlight = Color(0xFF64748B);// #64748B - Focused Input Borders

  // Brand & Semantic Accents
  static const Color emeraldGreen = Color(0xFF10B981);   // #10B981 - Primary Accent, Settled, Positive
  static const Color emeraldDark = Color(0xFF047857);    // #047857 - Deep Emerald Hover/Pressed
  static const Color sovereignGold = Color(0xFFD4AF37);  // #D4AF37 - Secondary Accent, Allocation, Slots
  static const Color crimsonRed = Color(0xFFEF4444);     // #EF4444 - Error, Delinquent, Danger
  static const Color amberWarning = Color(0xFFF59E0B);   // #F59E0B - Pending, Maker Approval, Grace
  static const Color skyInfo = Color(0xFF0EA5E9);        // #0EA5E9 - Information, Status Inquiries

  // Text Hierarchy
  static const Color textPrimary = Color(0xFFF8FAFC);    // #F8FAFC - High-emphasis text
  static const Color textSecondary = Color(0xFF94A3B8);  // #94A3B8 - Metadata, Subtitles, Captions
  static const Color textMuted = Color(0xFF64748B);      // #64748B - Disabled, Placeholders
}
