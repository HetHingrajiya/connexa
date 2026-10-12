import 'package:flutter/material.dart';

/// Layout classification based on logical pixel breakpoints.
enum DeviceType {
  mobile,
  tablet,
  desktop;

  bool get isMobile => this == DeviceType.mobile;
  bool get isTablet => this == DeviceType.tablet;
  bool get isDesktop => this == DeviceType.desktop;
}

/// Breakpoint boundaries for responsive design across platforms.
abstract final class Breakpoints {
  /// Width below 600 logical pixels is classified as mobile.
  static const double mobileMax = 599.99;

  /// Width from 600 to below 1024 logical pixels is classified as tablet.
  static const double tabletMin = 600.0;

  /// Width 1024 logical pixels and above is classified as desktop.
  static const double desktopMin = 1024.0;
}

/// Helper methods for determining device type and responsive metrics.
abstract final class ResponsiveHelper {
  /// Resolves the [DeviceType] based on the provided width.
  static DeviceType getDeviceType(double width) {
    if (width < Breakpoints.tabletMin) {
      return DeviceType.mobile;
    } else if (width < Breakpoints.desktopMin) {
      return DeviceType.tablet;
    } else {
      return DeviceType.desktop;
    }
  }

  /// Resolves the [DeviceType] using the window/context [MediaQuery].
  static DeviceType deviceTypeOf(BuildContext context) {
    return getDeviceType(MediaQuery.sizeOf(context).width);
  }
}

/// A responsive widget builder providing context, current [DeviceType],
/// current width, and layout constraints.
typedef ResponsiveWidgetBuilder =
    Widget Function(
      BuildContext context,
      DeviceType deviceType,
      BoxConstraints constraints,
    );

/// A reusable responsive container that evaluates constraints via [LayoutBuilder]
/// and exposes the classified [DeviceType] and width.
class ResponsiveBuilder extends StatelessWidget {
  const ResponsiveBuilder({
    super.key,
    required this.builder,
    this.useScreenWidth = true,
  });

  final ResponsiveWidgetBuilder builder;
  final bool useScreenWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width = useScreenWidth
            ? MediaQuery.sizeOf(context).width
            : (constraints.maxWidth.isFinite
                  ? constraints.maxWidth
                  : MediaQuery.sizeOf(context).width);
        final DeviceType deviceType = ResponsiveHelper.getDeviceType(width);
        return builder(context, deviceType, constraints);
      },
    );
  }
}

/// Convenience widget allowing separate builders for mobile, tablet, and desktop layouts.
class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
    this.useScreenWidth = true,
  });

  final Widget Function(BuildContext context, BoxConstraints constraints)
  mobile;
  final Widget Function(BuildContext context, BoxConstraints constraints)?
  tablet;
  final Widget Function(BuildContext context, BoxConstraints constraints)?
  desktop;
  final bool useScreenWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width = useScreenWidth
            ? MediaQuery.sizeOf(context).width
            : (constraints.maxWidth.isFinite
                  ? constraints.maxWidth
                  : MediaQuery.sizeOf(context).width);
        final DeviceType deviceType = ResponsiveHelper.getDeviceType(width);

        if (deviceType == DeviceType.desktop && desktop != null) {
          return desktop!(context, constraints);
        } else if (deviceType == DeviceType.tablet && tablet != null) {
          return tablet!(context, constraints);
        } else {
          return mobile(context, constraints);
        }
      },
    );
  }
}

/// A responsive center container that constrains content to a maximum width
/// on tablet and desktop/web viewports.
class ResponsiveCenterBox extends StatelessWidget {
  const ResponsiveCenterBox({
    super.key,
    required this.child,
    this.maxMobileWidth = double.infinity,
    this.maxTabletWidth = 680.0,
    this.maxDesktopWidth = 920.0,
    this.padding,
  });

  final Widget child;
  final double maxMobileWidth;
  final double maxTabletWidth;
  final double maxDesktopWidth;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder:
          (
            BuildContext context,
            DeviceType deviceType,
            BoxConstraints constraints,
          ) {
            final double maxWidth = switch (deviceType) {
              DeviceType.mobile => maxMobileWidth,
              DeviceType.tablet => maxTabletWidth,
              DeviceType.desktop => maxDesktopWidth,
            };

            Widget content = child;
            if (padding != null) {
              content = Padding(padding: padding!, child: content);
            }

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: content,
              ),
            );
          },
    );
  }
}
