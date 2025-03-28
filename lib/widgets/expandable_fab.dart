import 'package:flutter/material.dart';
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

class _ExpandableFabState extends State<ExpandableFab> {
  bool _open = false;

  @override
  void initState() {
    super.initState();
    _open = widget.initialOpen ?? false;
  }

  void _toggle() {
    setState(() {
      _open = !_open;
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
    if (!_open) return [];

    final children = <Widget>[];
    final count = widget.children.length;
    const buttonSpacing = 50.0;

    for (var i = 0; i < count; i++) {
      children.add(
        Positioned(
          right: 4.0,
          bottom: 4.0 + 80.0 + (buttonSpacing * i),
          child: widget.children[i],
        ),
      );
    }
    return children;
  }

  Widget _buildToggleButton() {
    return SizedBox(
      width: 56,
      height: 56,
      child: Material(
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        elevation: 4,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF2196F3),
                Color(0xFF9C27B0),
              ],
            ),
          ),
          child: InkWell(
            onTap: _toggle,
            child: Icon(
              _open ? Icons.close : Icons.add,
              size: 32,
              color: Colors.white,
            ),
          ),
        ),
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
