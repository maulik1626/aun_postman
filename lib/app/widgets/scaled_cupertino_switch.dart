import 'package:flutter/cupertino.dart';

/// App-wide [CupertinoSwitch] at a consistent visual scale.
class ScaledCupertinoSwitch extends StatelessWidget {
  const ScaledCupertinoSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeTrackColor,
    this.trackColor,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final Color? activeTrackColor;
  final Color? trackColor;

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: 0.65,
      alignment: Alignment.center,
      child: CupertinoSwitch(
        value: value,
        onChanged: onChanged,
        activeTrackColor: activeTrackColor,
        trackColor: trackColor,
      ),
    );
  }
}
