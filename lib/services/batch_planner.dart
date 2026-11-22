import 'dart:math';

class BatchPlanner {
  static const heavyTokens = ['youtube', 'instagram', 'tiktok', 'facebook', 'terabox', 'drive', 'dropbox', 'netflix', 'spotify'];
  static const protectedTokens = ['dialer', 'telecom', 'phone', 'emergency'];
  static bool heavy(String pkg) => heavyTokens.any((t) => pkg.toLowerCase().contains(t));
  static bool protected(String pkg) => protectedTokens.any((t) => pkg.toLowerCase().contains(t));
  static List<List<Map<String, String>>> plan(List<Map<String, String>> apps, {int size = 8, Set<String> excluded = const {}, Set<String> priority = const {}}) {
    final candidates = apps.where((a) => !excluded.contains(a['package'])).toList();
    candidates.sort((a,b) {
      final ap = priority.contains(a['package']) || protected(a['package'] ?? '');
      final bp = priority.contains(b['package']) || protected(b['package'] ?? '');
      return ap == bp ? 0 : (ap ? -1 : 1);
    });
    final heavyApps = candidates.where((a) => heavy(a['package'] ?? '')).toList();
    final lightApps = candidates.where((a) => !heavy(a['package'] ?? '')).toList();
    final batches = <List<Map<String,String>>>[];
    final count = max(2, min(size, 20));
    while (heavyApps.isNotEmpty || lightApps.isNotEmpty) {
      final batch = <Map<String,String>>[];
      if (heavyApps.isNotEmpty) batch.add(heavyApps.removeAt(0));
      while (batch.length < count && lightApps.isNotEmpty) { batch.add(lightApps.removeAt(0)); }
      if (batch.isEmpty && heavyApps.isNotEmpty) batch.add(heavyApps.removeAt(0));
      batches.add(batch);
    }
    return batches;
  }
}
