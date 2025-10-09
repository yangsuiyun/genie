import 'package:flutter/material.dart';

// 微交互动画
class MicroAnimations {
  // 按钮点击波纹效果
  static Widget rippleEffect({
    required Widget child,
    required VoidCallback onTap,
    Color? rippleColor,
    BorderRadius? borderRadius,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        splashColor: rippleColor ?? Colors.white.withOpacity(0.1),
        highlightColor: rippleColor ?? Colors.white.withOpacity(0.05),
        child: child,
      ),
    );
  }

  // 卡片悬停效果
  static Widget cardHover({
    required Widget child,
    required VoidCallback onTap,
    Color? hoverColor,
    Duration duration = const Duration(milliseconds: 200),
  }) {
    return AnimatedContainer(
      duration: duration,
      child: GestureDetector(
        onTap: onTap,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: AnimatedContainer(
            duration: duration,
            child: child,
          ),
        ),
      ),
    );
  }

  // 加载动画
  static Widget loadingSpinner({
    Color? color,
    double size = 20.0,
  }) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: 2.0,
        valueColor: AlwaysStoppedAnimation<Color>(
          color ?? Colors.white,
        ),
      ),
    );
  }

  // 脉冲动画
  static Widget pulse({
    required Widget child,
    Duration duration = const Duration(milliseconds: 1000),
    double minScale = 0.95,
    double maxScale = 1.05,
  }) {
    return TweenAnimationBuilder<double>(
      duration: duration,
      tween: Tween(begin: minScale, end: maxScale),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      onEnd: () {
        // 可以在这里添加循环逻辑
      },
    );
  }

  // 呼吸动画
  static Widget breathe({
    required Widget child,
    Duration duration = const Duration(milliseconds: 2000),
    double minOpacity = 0.5,
    double maxOpacity = 1.0,
  }) {
    return TweenAnimationBuilder<double>(
      duration: duration,
      tween: Tween(begin: minOpacity, end: maxOpacity),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: child,
        );
      },
    );
  }

  // 滑动指示器
  static Widget slideIndicator({
    required int currentIndex,
    required int totalCount,
    Color? activeColor,
    Color? inactiveColor,
    double height = 4.0,
    double width = 20.0,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        totalCount,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          height: height,
          width: width,
          decoration: BoxDecoration(
            color: index == currentIndex
                ? (activeColor ?? Colors.red)
                : (inactiveColor ?? Colors.white24),
            borderRadius: BorderRadius.circular(height / 2),
          ),
        ),
      ),
    );
  }

  // 进度条动画
  static Widget animatedProgress({
    required double progress,
    Color? backgroundColor,
    Color? valueColor,
    double height = 4.0,
    Duration duration = const Duration(milliseconds: 500),
  }) {
    return TweenAnimationBuilder<double>(
      duration: duration,
      tween: Tween(begin: 0.0, end: progress),
      builder: (context, value, child) {
        return LinearProgressIndicator(
          value: value,
          backgroundColor: backgroundColor ?? Colors.white24,
          valueColor: AlwaysStoppedAnimation<Color>(
            valueColor ?? Colors.red,
          ),
          minHeight: height,
        );
      },
    );
  }

  // 数字计数动画
  static Widget countUp({
    required int targetValue,
    Duration duration = const Duration(milliseconds: 1000),
    TextStyle? textStyle,
  }) {
    return TweenAnimationBuilder<int>(
      duration: duration,
      tween: IntTween(begin: 0, end: targetValue),
      builder: (context, value, child) {
        return Text(
          value.toString(),
          style: textStyle,
        );
      },
    );
  }

  // 图标旋转动画
  static Widget rotateIcon({
    required IconData icon,
    required bool isRotating,
    Duration duration = const Duration(milliseconds: 500),
    Color? color,
    double size = 24.0,
  }) {
    return AnimatedRotation(
      turns: isRotating ? 1.0 : 0.0,
      duration: duration,
      child: Icon(
        icon,
        color: color,
        size: size,
      ),
    );
  }

  // 震动效果
  static Widget shake({
    required Widget child,
    required bool shouldShake,
    Duration duration = const Duration(milliseconds: 500),
    double intensity = 10.0,
  }) {
    return AnimatedBuilder(
      animation: AlwaysStoppedAnimation(shouldShake ? 1.0 : 0.0),
      builder: (context, animation) {
        final animValue = animation?.value ?? 0.0;
        return Transform.translate(
          offset: Offset(
            shouldShake ? (animValue * intensity * (0.5 - (animValue * 0.5))) : 0.0,
            0,
          ),
          child: child,
        );
      },
    );
  }
}

// 动画控制器混入
mixin AnimationControllerMixin<T extends StatefulWidget> on State<T>, TickerProviderStateMixin<T> {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  AnimationController get animationController => _animationController;
  Animation<double> get animation => _animation;
}
