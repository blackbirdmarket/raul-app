import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';

/// Aparicion suave con un leve desplazamiento hacia arriba.
///
/// Se usa para escalonar la entrada de los elementos de una lista pasando un
/// `delay` creciente. El movimiento es corto a proposito: animaciones largas
/// se sienten lentas cuando el usuario ya sabe a donde va.
class FadeIn extends StatefulWidget {
  const FadeIn({
    required this.child,
    this.delay = Duration.zero,
    this.duration = AppConstants.durationNormal,
    this.offset = 12,
    super.key,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final double offset;

  @override
  State<FadeIn> createState() => _FadeInState();
}

class _FadeInState extends State<FadeIn> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );

  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
  );

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future<void>.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _fade,
      builder: (context, child) => Opacity(
        opacity: _fade.value,
        child: Transform.translate(
          offset: Offset(0, widget.offset * (1 - _fade.value)),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}
