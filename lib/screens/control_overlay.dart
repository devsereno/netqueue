import 'dart:async';
import 'package:flutter/material.dart';
import '../services/connectivity_service.dart';
import '../services/vpn_service.dart';
import '../services/app_list_service.dart';
import '../services/batch_planner.dart';
import '../services/flux_policy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ControlOverlay extends StatefulWidget {
  const ControlOverlay({super.key});

  @override
  State<ControlOverlay> createState() => _ControlOverlayState();
}

class _ControlOverlayState extends State<ControlOverlay> {
  List<Map<String, String>> apps = [];
  int currentIndex = 0;
  List<List<Map<String,String>>> batches = [];
  bool finishing = false;
  DateTime? startedAt;
  int secondsPerBatch = 5;
  double progress = 0.0;
  Timer? _timer;
  bool loading = true;
  bool vpnReady = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    if (!await FluxPolicy.canRun()) { if (mounted) Navigator.of(context).pop(); return; }
    vpnReady = await VpnController.prepare();
    if (!mounted) return;
    if (!vpnReady) {
      Navigator.of(context).pop();
      return;
    }
    final cached = await AppListService.getCachedOrLoad();
    final prefs = await SharedPreferences.getInstance();
    final excluded = prefs.getStringList('flux_excluded')?.toSet() ?? <String>{};
    final priority = prefs.getStringList('flux_priority')?.toSet() ?? <String>{};
    final configured = prefs.getInt('max_simultaneous') ?? 8;
    final charging = await FluxPolicy.isCharging();
    final networks = await Connectivity().checkConnectivity();
    // Heuristic only: transport type is NOT a measured bandwidth or congestion signal.
    final constrained = networks.contains(ConnectivityResult.mobile);
    final size = (configured + (charging ? 2 : 0) - (constrained ? 2 : 0)).clamp(2, 20);
    secondsPerBatch = (prefs.getInt('flux_batch_seconds') ?? 5).clamp(2, 15);
    batches = BatchPlanner.plan(cached, size: size, excluded: excluded, priority: priority);
    startedAt = DateTime.now();
    setState(() { apps = cached.toList(); loading = false; });
    if (batches.isNotEmpty) {
      await _updateVpnForCurrent();
      if (mounted) _startProgress();
    } else {
      await _finish();
    }
  }

  Future<void> _updateVpnForCurrent() async {
    if (currentIndex >= batches.length || finishing) return;
    final batch = batches[currentIndex];
    await VpnController.start(batch.map((a) => a['package']!).toList());
    for (final app in batch) {
      await AppListService.addToHistory(app['name'] ?? 'App', app['package']!);
    }
  }

  void _startProgress() {
    _timer?.cancel();
    progress = 0.0;
    _timer = Timer.periodic(const Duration(milliseconds: 80), (timer) {
      if (!mounted) return;
      setState(() {
        progress += 0.08 / secondsPerBatch;
        if (progress >= 1.0) {
          progress = 1.0;
          timer.cancel();
          Future.delayed(const Duration(milliseconds: 600), _nextApp);
        }
      });
    });
  }

  Future<void> _nextApp() async {
    if (!mounted || finishing) return;
    if (!await FluxPolicy.canRun()) { await _finish(); return; }
    if (currentIndex < batches.length - 1) {
      setState(() {
        currentIndex++;
        progress = 0.0;
      });
      await _updateVpnForCurrent();
      _startProgress();
    } else {
      await _finish();
    }
  }

  Future<void> _finish() async {
    if (finishing) return;
    finishing = true;
    _timer?.cancel();
    try { await VpnController.stop(); } finally {
      await ConnectivityService.markOnlineHandled();
      await FluxPolicy.event('queue_completed', {'batches': batches.length, 'apps': batches.fold<int>(0,(s,b)=>s+b.length), 'duration_seconds': DateTime.now().difference(startedAt ?? DateTime.now()).inSeconds});
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _timer?.cancel();
    VpnController.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        backgroundColor: Colors.black87,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final app = batches.isEmpty || currentIndex >= batches.length ? null : batches[currentIndex].first;

    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.92),
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white70),
                onPressed: _finish,
              ),
            ),
            Text(
              'Lote ${currentIndex + 1} de ${batches.length} — ${batches.isEmpty ? 0 : batches[currentIndex].length} apps',
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const Spacer(),
            if (app != null) ...[
              const Icon(Icons.android, size: 96, color: Colors.white),
              const SizedBox(height: 16),
              Text(
                '${app['name'] ?? 'Aplicativo'} e outros do lote',
                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                vpnReady ? 'Liberando acesso à rede...' : 'Controle visual (VPN não autorizada)',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48),
                child: Column(
                  children: [
                    LinearProgressIndicator(
                      value: progress,
                      minHeight: 12,
                      backgroundColor: Colors.white24,
                      color: Colors.blueAccent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    const SizedBox(height: 8),
                    Text('${(progress * 100).toInt()}%', style: const TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ],
            const Spacer(),
            Container(
              margin: const EdgeInsets.all(16),
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white24),
              ),
              child: const Center(
                child: Text('Espaço para anúncio', style: TextStyle(color: Colors.white54)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
