import 'package:flutter/material.dart';

// 页面转场动画
class PageTransitions {
  // 侧边栏滑入动画
  static Widget slideFromLeft(Widget child, Animation<double> animation) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(-1.0, 0.0),
        end: Offset.zero,
      ).animate(CurveTween(curve: Curves.easeInOut).animate(animation)),
      child: child,
    );
  }

  // 侧边栏滑出动画
  static Widget slideToLeft(Widget child, Animation<double> animation) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: Offset.zero,
        end: const Offset(-1.0, 0.0),
      ).animate(CurveTween(curve: Curves.easeInOut).animate(animation)),
      child: child,
    );
  }

  // 模态框淡入动画
  static Widget fadeIn(Widget child, Animation<double> animation) {
    return FadeTransition(
      opacity: animation,
      child: ScaleTransition(
        scale: Tween<double>(
          begin: 0.8,
          end: 1.0,
        ).animate(CurveTween(curve: Curves.easeOutBack).animate(animation)),
        child: child,
      ),
    );
  }

  // 模态框淡出动画
  static Widget fadeOut(Widget child, Animation<double> animation) {
    return FadeTransition(
      opacity: animation,
      child: ScaleTransition(
        scale: Tween<double>(
          begin: 1.0,
          end: 0.8,
        ).animate(CurveTween(curve: Curves.easeInBack).animate(animation)),
        child: child,
      ),
    );
  }

  // 专注模式进入动画
  static Widget focusModeEnter(Widget child, Animation<double> animation) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0.0, 1.0),
        end: Offset.zero,
      ).animate(CurveTween(curve: Curves.easeInOutCubic).animate(animation)),
      child: FadeTransition(
        opacity: animation,
        child: child,
      ),
    );
  }

  // 专注模式退出动画
  static Widget focusModeExit(Widget child, Animation<double> animation) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: Offset.zero,
        end: const Offset(0.0, 1.0),
      ).animate(CurveTween(curve: Curves.easeInOutCubic).animate(animation)),
      child: FadeTransition(
        opacity: animation,
        child: child,
      ),
    );
  }

  // 卡片弹出动画
  static Widget cardPop(Widget child, Animation<double> animation) {
    return ScaleTransition(
      scale: Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurveTween(curve: Curves.elasticOut).animate(animation)),
      child: FadeTransition(
        opacity: animation,
        child: child,
      ),
    );
  }

  // 按钮点击动画
  static Widget buttonPress(Widget child, Animation<double> animation) {
    return ScaleTransition(
      scale: Tween<double>(
        begin: 1.0,
        end: 0.95,
      ).animate(CurveTween(curve: Curves.easeInOut).animate(animation)),
      child: child,
    );
  }
}

// 自定义页面路由
class CustomPageRoute<T> extends PageRoute<T> {
  final Widget child;
  final RouteTransitionsBuilder transitionsBuilder;
  final Duration transitionDuration;
  final Duration reverseTransitionDuration;

  CustomPageRoute({
    required this.child,
    required this.transitionsBuilder,
    this.transitionDuration = const Duration(milliseconds: 300),
    this.reverseTransitionDuration = const Duration(milliseconds: 300),
    RouteSettings? settings,
  }) : super(settings: settings);

  @override
  Color? get barrierColor => Colors.black54;

  @override
  String? get barrierLabel => null;

  @override
  bool get barrierDismissible => true;

  @override
  bool get maintainState => true;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return child;
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return transitionsBuilder(context, animation, secondaryAnimation, child);
  }
}

// 专注模式路由
class FocusModeRoute<T> extends CustomPageRoute<T> {
  FocusModeRoute({
    required Widget child,
    RouteSettings? settings,
  }) : super(
          child: child,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return PageTransitions.focusModeEnter(child, animation);
          },
          transitionDuration: const Duration(milliseconds: 500),
          settings: settings,
        );
}

// 模态框路由
class ModalRoute<T> extends CustomPageRoute<T> {
  ModalRoute({
    required Widget child,
    RouteSettings? settings,
  }) : super(
          child: child,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return PageTransitions.fadeIn(child, animation);
          },
          transitionDuration: const Duration(milliseconds: 250),
          settings: settings,
        );
}
