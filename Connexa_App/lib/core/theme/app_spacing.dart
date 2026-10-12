import 'package:flutter/material.dart';

/// Centralized spacing scale, dimensions, and border radius tokens for Connexa.
abstract final class AppSpacing {
  // Spacing Scale
  static const double xxs = 2.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 32.0;
  static const double huge = 40.0;
  static const double massive = 48.0;

  // Corner Radii
  static const double radiusXs = 4.0;
  static const double radiusSm = 6.0;
  static const double radiusMd = 8.0;
  static const double radiusLg = 12.0;
  static const double radiusXl = 16.0;
  static const double radiusFull = 9999.0;

  static const BorderRadius borderRadiusXs = BorderRadius.all(
    Radius.circular(radiusXs),
  );
  static const BorderRadius borderRadiusSm = BorderRadius.all(
    Radius.circular(radiusSm),
  );
  static const BorderRadius borderRadiusMd = BorderRadius.all(
    Radius.circular(radiusMd),
  );
  static const BorderRadius borderRadiusLg = BorderRadius.all(
    Radius.circular(radiusLg),
  );
  static const BorderRadius borderRadiusXl = BorderRadius.all(
    Radius.circular(radiusXl),
  );
  static const BorderRadius borderRadiusFull = BorderRadius.all(
    Radius.circular(radiusFull),
  );

  // Common Edge Insets
  static const EdgeInsets paddingXs = EdgeInsets.all(xs);
  static const EdgeInsets paddingSm = EdgeInsets.all(sm);
  static const EdgeInsets paddingMd = EdgeInsets.all(md);
  static const EdgeInsets paddingLg = EdgeInsets.all(lg);
  static const EdgeInsets paddingXl = EdgeInsets.all(xl);
  static const EdgeInsets paddingXxl = EdgeInsets.all(xxl);

  // Responsive Screen Padding
  static const EdgeInsets screenPaddingMobile = EdgeInsets.symmetric(
    horizontal: lg,
    vertical: lg,
  );
  static const EdgeInsets screenPaddingTablet = EdgeInsets.symmetric(
    horizontal: xxl,
    vertical: xxl,
  );
  static const EdgeInsets screenPaddingDesktop = EdgeInsets.symmetric(
    horizontal: xxxl,
    vertical: xxxl,
  );

  // Standard Max Content Widths
  static const double maxContentWidthMobile = double.infinity;
  static const double maxContentWidthTablet = 680.0;
  static const double maxContentWidthDesktop = 960.0;
  static const double maxContentWidthWide = 1200.0;
}
