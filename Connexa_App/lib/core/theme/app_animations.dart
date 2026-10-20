import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Centralized animation constants and utilities for the Connexa Enterprise Platform.
abstract final class AppAnimations {
  /// Standard duration for page navigation transitions (220ms).
  static const Duration pageTransition = Duration(milliseconds: 220);

  /// Standard duration for micro-interactions, hovers, and button states (180ms).
  static const Duration micro = Duration(milliseconds: 180);

  /// Duration for expandable panels and accordions (240ms).
  static const Duration panel = Duration(milliseconds: 240);

  /// Standard cubic easing curve for enterprise UI.
  static const Curve defaultCurve = Curves.easeOutCubic;

  /// Creates a standardized [CustomTransitionPage] with subtle fade and 2% vertical slide.
  static CustomTransitionPage<T> buildPageTransition<T>({
    required LocalKey key,
    required Widget child,
    Duration duration = pageTransition,
  }) {
    return CustomTransitionPage<T>(
      key: key,
      child: child,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder:
          (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
            Widget child,
          ) {
            if (MediaQuery.of(context).disableAnimations) {
              return child;
            }

            final CurvedAnimation curved = CurvedAnimation(
              parent: animation,
              curve: defaultCurve,
            );

            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.0, 0.02),
                  end: Offset.zero,
                ).animate(curved),
                child: child,
              ),
            );
          },
    );
  }
}

/// A lightweight widget providing staggered fade and slide entrance for lists and dashboard grids.
class AppStaggeredEntrance extends StatefulWidget {
  const AppStaggeredEntrance({
    super.key,
    required this.child,
    this.index = 0,
    this.delayIncrement = const Duration(milliseconds: 40),
    this.duration = const Duration(milliseconds: 240),
  });

  final Widget child;
  final int index;
  final Duration delayIncrement;
  final Duration duration;

  @override
  State<AppStaggeredEntrance> createState() => _AppStaggeredEntranceState();
}

class _AppStaggeredEntranceState extends State<AppStaggeredEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);

    final CurvedAnimation curved = CurvedAnimation(
      parent: _controller,
      curve: AppAnimations.defaultCurve,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(curved);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.04),
      end: Offset.zero,
    ).animate(curved);

    final int delayMs = widget.index * widget.delayIncrement.inMilliseconds;
    if (delayMs > 0) {
      Future<void>.delayed(Duration(milliseconds: delayMs), () {
        if (mounted) {
          _controller.forward();
        }
      });
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) {
      return widget.child;
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(position: _slideAnimation, child: widget.child),
    );
  }
}
