import 'package:flutter/material.dart';
import '../theme.dart';

enum FedsButtonStyle { primary, secondary, stop, ios }

class FedsButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final FedsButtonStyle style;
  final bool small;

  const FedsButton({
    super.key,
    required this.label,
    this.onPressed,
    this.style = FedsButtonStyle.primary,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    final h = small ? 32.0 : 40.0;
    final fontSize = small ? 12.0 : 13.0;
    final hPad = small ? 12.0 : 16.0;

    switch (style) {
      case FedsButtonStyle.primary:
        return _gradient(primaryGradient, h, hPad, fontSize);
      case FedsButtonStyle.stop:
        return _gradient(stopGradient, h, hPad, fontSize);
      case FedsButtonStyle.ios:
        return _gradient(iosGradient, h, hPad, fontSize);
      case FedsButtonStyle.secondary:
        return SizedBox(
          height: h,
          child: TextButton(
            onPressed: onPressed,
            style: TextButton.styleFrom(
              foregroundColor: onPressed == null
                  ? textSecondary.withValues(alpha: 0.4)
                  : textPrimary,
              backgroundColor: const Color(0x80303D3D),
              padding: EdgeInsets.symmetric(horizontal: hPad),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: cardBorder),
              ),
              textStyle: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: fontSize,
              ),
            ),
            child: Text(label),
          ),
        );
    }
  }

  Widget _gradient(
    LinearGradient grad,
    double h,
    double hPad,
    double fontSize,
  ) {
    return SizedBox(
      height: h,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: onPressed == null ? null : grad,
          color: onPressed == null ? cardBorder : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: hPad),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: fontSize,
            ),
          ),
          child: Text(label),
        ),
      ),
    );
  }
}
