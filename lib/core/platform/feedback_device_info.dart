import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

@immutable
class FeedbackDeviceInfo {
  const FeedbackDeviceInfo({required this.deviceName, required this.osLabel});

  final String deviceName;
  final String osLabel;
}

class FeedbackDeviceInfoResolver {
  FeedbackDeviceInfoResolver._();

  static Future<FeedbackDeviceInfo> resolve() async {
    final plugin = DeviceInfoPlugin();

    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        final info = await plugin.iosInfo;
        final deviceName = _iosMarketingName(info);
        final osLabel = 'iOS ${info.systemVersion}';
        return FeedbackDeviceInfo(deviceName: deviceName, osLabel: osLabel);
      case TargetPlatform.android:
        final info = await plugin.androidInfo;
        final brand = info.brand.trim();
        final model = info.model.trim();
        final manufacturer = info.manufacturer.trim();
        final deviceName = _joinParts([
          if (brand.isNotEmpty) brand,
          if (model.isNotEmpty && model.toLowerCase() != brand.toLowerCase())
            model,
        ]);
        final fallbackName = _joinParts([
          if (manufacturer.isNotEmpty) manufacturer,
          if (model.isNotEmpty) model,
        ]);
        final osLabel = 'Android ${info.version.release}';
        return FeedbackDeviceInfo(
          deviceName: deviceName.isEmpty ? fallbackName : deviceName,
          osLabel: osLabel,
        );
      default:
        return const FeedbackDeviceInfo(
          deviceName: 'Unknown device',
          osLabel: 'Unknown OS',
        );
    }
  }

  static String _joinParts(List<String> parts) {
    return parts.where((part) => part.trim().isNotEmpty).join(' ').trim();
  }

  static String _iosMarketingName(IosDeviceInfo info) {
    final identifier = info.utsname.machine.trim();
    const modelMap = <String, String>{
      'iPhone17,1': 'iPhone 16 Pro',
      'iPhone17,2': 'iPhone 16 Pro Max',
      'iPhone17,3': 'iPhone 16',
      'iPhone17,4': 'iPhone 16 Plus',
      'iPhone16,1': 'iPhone 15 Pro',
      'iPhone16,2': 'iPhone 15 Pro Max',
      'iPhone15,4': 'iPhone 15',
      'iPhone15,5': 'iPhone 15 Plus',
      'iPhone14,2': 'iPhone 13 Pro',
      'iPhone14,3': 'iPhone 13 Pro Max',
      'iPhone14,5': 'iPhone 13',
      'iPhone14,4': 'iPhone 13 mini',
    };
    final mapped = modelMap[identifier];
    if (mapped != null) return mapped;
    if (info.name.trim().isNotEmpty) return info.name.trim();
    if (identifier.isNotEmpty) return identifier;
    return 'iPhone';
  }
}
