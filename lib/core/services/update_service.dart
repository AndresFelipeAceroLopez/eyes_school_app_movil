import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pub_semver/pub_semver.dart';

import 'package:eyes_school/core/errors/app_failure.dart';
import 'package:eyes_school/core/network/api_config.dart';
import 'package:eyes_school/providers/repository_providers.dart';

final updateServiceProvider = Provider<UpdateService>((ref) {
  return UpdateService(ref.watch(dioProvider));
});

bool _platformIsAndroid() => Platform.isAndroid;

class UpdateInfo {
  final bool hasUpdate;
  final String latestVersion;
  final String? releaseNotes;
  final String? downloadUrl;

  UpdateInfo({
    required this.hasUpdate,
    required this.latestVersion,
    this.releaseNotes,
    this.downloadUrl,
  });
}

class UpdateService {
  UpdateService(this._dio, {this._isAndroid = _platformIsAndroid});

  final Dio _dio;

  /// Injected so the version check can be tested off-device (APP-07).
  final bool Function() _isAndroid;

  /// `owner/repo` on GitHub, configurable for QA (APP-07).
  static const String _githubApiUrl =
      'https://api.github.com/repos/${ApiConfig.updateRepo}/releases/latest';

  /// Checks if there is a newer version published on GitHub Releases.
  Future<UpdateInfo> checkForUpdates() async {
    if (!_isAndroid()) {
      // OTA via direct APK is only supported on Android.
      return UpdateInfo(hasUpdate: false, latestVersion: '');
    }

    try {
      final response = await _dio.get(_githubApiUrl);
      if (response.statusCode != 200) {
        return UpdateInfo(hasUpdate: false, latestVersion: '');
      }

      final data = response.data;
      String tagName = data['tag_name'] as String;
      
      // Clean up the tag name (e.g., 'v1.0.2' -> '1.0.2')
      if (tagName.startsWith('v') || tagName.startsWith('V')) {
        tagName = tagName.substring(1);
      }

      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersionString = packageInfo.version;

      final currentVersion = Version.parse(currentVersionString);
      final latestVersion = Version.parse(tagName);

      if (latestVersion > currentVersion) {
        final assets = data['assets'] as List;
        String? downloadUrl;
        
        // Find the APK asset
        for (final asset in assets) {
          final name = asset['name'] as String;
          if (name.endsWith('.apk')) {
            downloadUrl = asset['browser_download_url'] as String;
            break;
          }
        }

        return UpdateInfo(
          hasUpdate: downloadUrl != null,
          latestVersion: tagName,
          releaseNotes: data['body'] as String?,
          downloadUrl: downloadUrl,
        );
      }

      return UpdateInfo(hasUpdate: false, latestVersion: currentVersionString);
    } catch (e) {
      // If version parsing fails or network error occurs, assume no update.
      return UpdateInfo(hasUpdate: false, latestVersion: '');
    }
  }

  /// Downloads the APK and triggers the Android package installer.
  Future<void> downloadAndInstallUpdate({
    required String downloadUrl,
    required void Function(double progress) onProgress,
  }) async {
    try {
      final directory = await getTemporaryDirectory();
      final savePath = '${directory.path}/update.apk';

      await _dio.download(
        downloadUrl,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            onProgress(received / total);
          }
        },
      );

      final result = await OpenFilex.open(savePath);
      if (result.type != ResultType.done) {
        throw UnexpectedFailure('No se pudo abrir el instalador: ${result.message}');
      }
    } catch (e) {
      throw UnexpectedFailure('Error al descargar la actualización: $e');
    }
  }
}
