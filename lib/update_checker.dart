import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

class UpdateInfo {
  final bool hasUpdate;
  final String currentVersion;
  final String latestVersion;
  final String releaseUrl;
  final bool checkFailed;

  const UpdateInfo({
    required this.hasUpdate,
    required this.currentVersion,
    required this.latestVersion,
    required this.releaseUrl,
    this.checkFailed = false,
  });

  static const UpdateInfo unknown = UpdateInfo(
    hasUpdate: false,
    currentVersion: '',
    latestVersion: '',
    releaseUrl: '',
    checkFailed: true,
  );
}

class UpdateChecker {
  static const _apiUrl =
      'https://api.github.com/repos/DMStyles/installment-calculator/releases/latest';
  static const _releasePageUrl =
      'https://github.com/DMStyles/installment-calculator/releases/latest';

  /// Silently checks for a newer GitHub release.
  /// Returns [UpdateInfo.unknown] on any error (no internet, timeout, etc.).
  static Future<UpdateInfo> check() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version; // e.g. "1.2.0"

      final response = await http
          .get(
            Uri.parse(_apiUrl),
            headers: {'Accept': 'application/vnd.github+json'},
          )
          .timeout(const Duration(seconds: 6));

      if (response.statusCode != 200) return UpdateInfo.unknown;

      final data = json.decode(response.body) as Map<String, dynamic>;
      final tagName = (data['tag_name'] as String?)?.replaceFirst('v', '') ?? '';
      final releaseUrl = (data['html_url'] as String?) ?? _releasePageUrl;

      if (tagName.isEmpty) return UpdateInfo.unknown;

      final hasUpdate = _isNewer(tagName, currentVersion);

      return UpdateInfo(
        hasUpdate: hasUpdate,
        currentVersion: currentVersion,
        latestVersion: tagName,
        releaseUrl: releaseUrl,
      );
    } catch (_) {
      // No internet, timeout, or parse error — fail silently.
      return UpdateInfo.unknown;
    }
  }

  /// Returns true if [remote] version is strictly newer than [local].
  static bool _isNewer(String remote, String local) {
    try {
      final r = _parse(remote);
      final l = _parse(local);
      for (int i = 0; i < 3; i++) {
        if (r[i] > l[i]) return true;
        if (r[i] < l[i]) return false;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  static List<int> _parse(String v) {
    final parts = v.split('.');
    return List.generate(3, (i) => i < parts.length ? (int.tryParse(parts[i]) ?? 0) : 0);
  }
}
