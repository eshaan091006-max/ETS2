import 'dart:io';
import 'package:flutter/foundation.dart';

class LinkValidator {
  static Future<bool> isValidWorkingLink(String urlString) async {
    final uri = Uri.tryParse(urlString);
    if (uri == null || !uri.hasAbsolutePath || (uri.scheme != 'http' && uri.scheme != 'https')) {
      return false;
    }

    if (kIsWeb) {
      // On web, CORS prevents reading responses from other domains.
      // We can only check if it is syntactically a valid URL.
      return true;
    }

    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 4);
      
      // Try HEAD request first (faster, less bandwidth)
      final headRequest = await client.headUrl(uri);
      final headResponse = await headRequest.close();
      if (headResponse.statusCode >= 200 && headResponse.statusCode < 400) {
        return true;
      }
      
      // If HEAD request fails (some servers block HEAD), try GET request
      final getRequest = await client.getUrl(uri);
      final getResponse = await getRequest.close();
      return getResponse.statusCode >= 200 && getResponse.statusCode < 400;
    } catch (_) {
      return false;
    }
  }
}
