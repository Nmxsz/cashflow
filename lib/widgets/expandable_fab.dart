import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui';

class ExpandableFab extends StatefulWidget {
  const ExpandableFab({
    super.key,
    this.initialOpen,
    required this.distance,
    required this.children,
  });

  final bool? initialOpen;
  final double distance;
  final List<Widget> children;

  @override
  State<ExpandableFab> createState() => _ExpandableFabState();
}

class _ExpandableFabState extends State<ExpandableFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _expandAnimation;
  bool _open = false;

  @override
  void initState() {
    super.initState();
    _open = widget.initialOpen ?? false;
    _controller = AnimationController(
      value: _open ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      curve: Curves.fastOutSlowIn,
      reverseCurve: Curves.easeOutQuad,
      parent: _controller,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _open = !_open;
      if (_open) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (_open)
          Positioned.fill(
            child: GestureDetector(
              onTap: _toggle,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(
                  color: Colors.black.withOpacity(0.2),
                ),
              ),
            ),
          ),
        SizedBox.expand(
          child: Stack(
            alignment: Alignment.bottomRight,
            clipBehavior: Clip.none,
            children: [
              ..._buildExpandingActionButtons(),
              _buildToggleButton(),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildExpandingActionButtons() {
    final children = <Widget>[];
    final count = widget.children.length;
    const buttonSpacing = 35.0; // Konstanter Abstand zwischen den Buttons

    for (var i = 0; i < count; i++) {
      children.add(
        _ExpandingActionButton(
          index: i,
          totalCount: count,
          maxDistance: widget.distance,
          buttonSpacing: buttonSpacing,
          progress: _expandAnimation,
          child: widget.children[i],
        ),
      );
    }
    return children;
  }

  Widget _buildToggleButton() {
    return AnimatedContainer(
      transformAlignment: Alignment.center,
      transform: Matrix4.diagonal3Values(
        _open ? 0.7 : 1.0,
        _open ? 0.7 : 1.0,
        1.0,
      ),
      duration: const Duration(milliseconds: 250),
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      child: SizedBox(
        width: 56,
        height: 56,
        child: Material(
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          elevation: 4,
          child: InkWell(
            onTap: _toggle,
            child: Icon(
              _open ? Icons.close : Icons.add,
              size: 32,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ),
      ),
    );
  }
}

@immutable
class _ExpandingActionButton extends StatelessWidget {
  const _ExpandingActionButton({
    required this.index,
    required this.totalCount,
    required this.maxDistance,
    required this.buttonSpacing,
    required this.progress,
    required this.child,
  });

  final int index;
  final int totalCount;
  final double maxDistance;
  final double buttonSpacing;
  final Animation<double> progress;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: progress,
      builder: (context, child) {
        // Berechne die vertikale Position mit konstantem Abstand
        final offset = Offset(
          0,
          progress.value *
              (maxDistance + (buttonSpacing * (totalCount - 1))) *
              (index / (totalCount - 1)),
        );
        return Positioned(
          right: 4.0 + offset.dx,
          bottom: 4.0 + offset.dy + 56.0,
          child: child!,
        );
      },
      child: FadeTransition(
        opacity: CurvedAnimation(
          parent: progress,
          curve: Interval(
            index / totalCount,
            (index + 1) / totalCount,
            curve: Curves.easeOut,
          ),
        ),
        child: child,
      ),
    );
  }
}

@immutable
class ActionButton extends StatelessWidget {
  const ActionButton({
    super.key,
    this.onPressed,
    required this.icon,
    required this.label,
  });

  final VoidCallback? onPressed;
  final Widget icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: theme.colorScheme.onSecondary,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Material(
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              color: theme.colorScheme.secondary,
              elevation: 4,
              child: IconButton(
                onPressed: onPressed,
                icon: icon,
                color: theme.colorScheme.onSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
