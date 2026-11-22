import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

/// Έλεγχος στο notify. Νεότερη έκδοση δεν κλείνει: μόνο εγκατάσταση.
class FloantaUpdate {
  static const _manifestUrl = 'https://notify.eshopservices.gr/apis/software/floanta_rustdesk';
  static const _channel = MethodChannel('floanta.rustdesk/update');
  static bool _open = false;

  static Future<void> prompt(BuildContext context) async {
    if (const bool.fromEnvironment('FLOANTA_PLAY')) {
      return;
    }
    if (_open) {
      return;
    }
    final check = await _check();
    if (check == null || !context.mounted) {
      return;
    }
    _open = true;
    var busy = false;
    var message = 'Η έκδοση ${check.current} δεν υποστηρίζεται. Εγκαταστήστε την ${check.latest}.';
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return PopScope(
              canPop: false,
              child: AlertDialog(
                title: const Text('Απαιτείται ενημέρωση'),
                content: Text(message),
                actions: [
                  TextButton(
                    onPressed: busy
                        ? null
                        : () async {
                            setLocal(() {
                              busy = true;
                              message = 'Γίνεται λήψη…';
                            });
                            try {
                              await _channel.invokeMethod<void>('install', {'url': check.url});
                            } catch (e) {
                              setLocal(() {
                                busy = false;
                                message = e is PlatformException
                                    ? (e.message ?? 'Η ενημέρωση δεν ξεκίνησε')
                                    : 'Η ενημέρωση δεν ξεκίνησε';
                              });
                            }
                          },
                    child: const Text('Ενημέρωση τώρα'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    _open = false;
  }

  static Future<_Release?> _check() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final current = info.version.trim();
      final res = await http.get(Uri.parse(_manifestUrl)).timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) {
        return null;
      }
      final decoded = jsonDecode(utf8.decode(res.bodyBytes));
      if (decoded is! Map) {
        return null;
      }
      final latest = (decoded['version'] ?? '').toString().trim();
      final url = (decoded['download_url'] ?? '').toString().trim();
      if (latest.isEmpty || url.isEmpty || current.isEmpty) {
        return null;
      }
      if (_compare(current, latest) >= 0) {
        return null;
      }
      return _Release(current: current, latest: latest, url: url);
    } catch (_) {
      return null;
    }
  }

  static int _compare(String a, String b) {
    List<int> parts(String value) {
      final clean = value.split('+').first.split('-').first.trim();
      if (clean.isEmpty) {
        return [0];
      }
      return clean.split('.').map((part) => int.tryParse(part) ?? 0).toList();
    }

    final left = parts(a);
    final right = parts(b);
    final count = left.length > right.length ? left.length : right.length;
    for (var i = 0; i < count; i++) {
      final x = i < left.length ? left[i] : 0;
      final y = i < right.length ? right[i] : 0;
      if (x != y) {
        return x.compareTo(y);
      }
    }
    return 0;
  }
}

class _Release {
  _Release({required this.current, required this.latest, required this.url});

  final String current;
  final String latest;
  final String url;
}
