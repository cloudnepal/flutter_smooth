// ignore_for_file: avoid_print

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:hello_package/demo/impl/preempt_builder.dart';

const _kDuration = Duration(milliseconds: 300);
// const _kDuration = Duration(milliseconds: 1000);
// const _kDuration = Duration(milliseconds: 5000);

enum Mode {
  slowByAnimation,
  slowByBuilder,
  fast,
}

class EnterPageAnimation extends StatelessWidget {
  final Mode? mode;
  final Widget child;

  const EnterPageAnimation({
    super.key,
    required this.mode,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    switch (mode) {
      case null:
        return const SizedBox();
      case Mode.slowByAnimation:
        return _EnterPageAnimationSlowByAnimation(child: child);
      case Mode.slowByBuilder:
        return _EnterPageAnimationSlowByBuilder(child: child);
      case Mode.fast:
        return _EnterPageAnimationFast(child: child);
    }
  }
}

class _EnterPageAnimationSlowByAnimation extends StatefulWidget {
  final Widget child;

  const _EnterPageAnimationSlowByAnimation({required this.child});

  @override
  State<_EnterPageAnimationSlowByAnimation> createState() =>
      _EnterPageAnimationSlowByAnimationState();
}

class _EnterPageAnimationSlowByAnimationState
    extends State<_EnterPageAnimationSlowByAnimation>
    with SingleTickerProviderStateMixin {
  final counter = Counter();
  late final _controller =
      AnimationController(duration: _kDuration, vsync: this);
  late final _offsetAnimation =
      Tween<Offset>(begin: const Offset(1, 0), end: const Offset(0, 0))
          .animate(CurvedAnimation(parent: _controller, curve: Curves.linear));

  @override
  void initState() {
    super.initState();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    counter.inc();

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: [
          SlideTransition(
            position: _offsetAnimation,
            child: widget.child,
          ),
          Center(child: counter.build()),
        ],
      ),
    );
  }
}

class _EnterPageAnimationSlowByBuilder extends StatefulWidget {
  final Widget child;

  const _EnterPageAnimationSlowByBuilder({required this.child});

  @override
  State<_EnterPageAnimationSlowByBuilder> createState() =>
      _EnterPageAnimationSlowByBuilderState();
}

class _EnterPageAnimationSlowByBuilderState
    extends State<_EnterPageAnimationSlowByBuilder> {
  final counter = Counter();
  final animation = _SimpleAnimation();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, constraints) {
      counter.inc();
      animation.init();
      final ratio = animation.computeRatio();

      if (ratio < 1) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          // print(
          //     '$runtimeType.build addPostFrameCallback callback call setState');
          setState(() {});
        });
      }

      return Stack(
        children: [
          Positioned(
            left: constraints.maxWidth * max(0, 1 - ratio),
            top: 0,
            bottom: 0,
            width: constraints.maxWidth,
            child: widget.child,
          ),
          Center(child: counter.build()),
        ],
      );
    });
  }
}

class _EnterPageAnimationFast extends StatefulWidget {
  final Widget child;

  const _EnterPageAnimationFast({required this.child});

  @override
  State<_EnterPageAnimationFast> createState() =>
      _EnterPageAnimationFastState();
}

class _EnterPageAnimationFastState extends State<_EnterPageAnimationFast> {
  final counter = Counter();
  final animation = _SimpleAnimation();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) => PreemptBuilder(
        builder: (_, child) {
          counter.inc();
          animation.init();
          final ratio = animation.computeRatio();
          print('$runtimeType PreemptBuilder.builder called ratio=$ratio');

          if (ratio < 1) {
            SchedulerBinding.instance.addPostFrameCallback((_) {
              // print(
              //     '$runtimeType.build addPostFrameCallback callback call setState');
              setState(() {});
            });
          }

          return Directionality(
            textDirection: TextDirection.ltr,
            child: Stack(
              children: [
                Positioned(
                  left: constraints.maxWidth * max(0, 1 - ratio),
                  top: 0,
                  bottom: 0,
                  width: constraints.maxWidth,
                  child: child,
                ),
                Center(child: counter.build()),
                // Center(
                //   child: Container(
                //     width: 100,
                //     height: 100,
                //     color: Colors
                //         .primaries[ratio.hashCode % Colors.primaries.length],
                //   ),
                // ),
              ],
            ),
          );
        },
        child: widget.child,
      ),
    );
  }
}

// hacky, just b/c it is prototype
// TODO use vsync, duration, etc
class _SimpleAnimation {
  DateTime? initialTime;

  void init() {
    initialTime ??= DateTime.now();
  }

  double computeRatio() {
    return DateTime.now().difference(initialTime!).inMicroseconds /
        _kDuration.inMicroseconds;
  }
}

class Counter {
  var count = 0;

  void inc() => count++;

  Widget build() => Text(
      '${count.toString().padRight(10)} ${DateTime.now()}',
      style: const TextStyle(fontSize: 30, color: Colors.black),
    );
}