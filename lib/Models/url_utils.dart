class UrlUtils {
  static String normalizeImageUrl(String rawUrl) {
    if (rawUrl.isEmpty) return '';

    // Replace localhost with emulator-compatible IP
    if (rawUrl.contains('127.0.0.1')) {
      return rawUrl.replaceFirst('127.0.0.1', '10.0.2.2');
    }

    // If the URL is relative (e.g., /storage/images/banner.png)
    if (!rawUrl.startsWith('http')) {
      return 'http://10.0.2.2:8000$rawUrl';
    }

    return rawUrl;
  }
}
