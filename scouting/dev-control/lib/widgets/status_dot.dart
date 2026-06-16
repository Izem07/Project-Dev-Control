import 'package:flutter/material.dart';
import '../models/app_state.dart';
import '../theme.dart';

class StatusDot extends StatefulWidget {
  final ProcessStatus status;
  final double size;

  const StatusDot({super.key, required this.status, this.size = 12});

  @override
  State<StatusDot> createState() => _StatusDotState();
}

class _StatusDotState extends State<StatusDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _blink;

  @override
  void initState() {
    super.initState();
    _blink = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _blink.dispose();
    super.dispose();
  }

  Color get _color {
    switch (widget.status) {
      case ProcessStatus.online:
        return statusOnline;
      case ProcessStatus.running:
        return statusRunning;
      case ProcessStatus.offline:
        return statusOffline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dot = Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: _color,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: _color.withValues(alpha: 0.6), blurRadius: 10)],
      ),
    );

    if (widget.status == ProcessStatus.running) {
      return FadeTransition(opacity: _blink, child: dot);
    }
    return dot;
  }
}

class InfoDot extends StatelessWidget {
  final Color color;
  final double size;

  const InfoDot({super.key, this.color = statusInfo, this.size = 12});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 10)],
      ),
    );
  }
}
