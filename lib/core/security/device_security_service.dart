import 'package:flutter/foundation.dart';
import 'package:flutter_jailbreak_detection/flutter_jailbreak_detection.dart';

/// Phase 9, P9-U8 - device-integrity signal sent on login (consumed by the
/// backend's device-risk middleware). Patient-app policy is soft: a
/// jailbroken/rooted device only gets flagged for the backend's audit log,
/// login is never refused locally - docwellness-dietician's stricter
/// policy blocks login instead, since that app handles patient PHI.
class DeviceSecurityService {
  static Future<Map<String, String>> riskHeaders() async {
    try {
      final jailbroken = await FlutterJailbreakDetection.jailbroken;
      return {
        'X-Jailbreak-Detected': jailbroken.toString(),
        'X-Root-Detected': jailbroken.toString(),
      };
    } catch (e) {
      // Detection failing shouldn't block login - default to "false"
      // (unknown), not a false positive.
      debugPrint('DeviceSecurityService.riskHeaders failed (non-fatal): $e');
      return {
        'X-Jailbreak-Detected': 'false',
        'X-Root-Detected': 'false',
      };
    }
  }
}
