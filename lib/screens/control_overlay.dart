import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_device_apps/flutter_device_apps.dart';
import '../services/connectivity_service.dart';

class ControlOverlay extends StatefulWidget {
  const ControlOverlay({super.key});

  @override
  State<ControlOverlay> createState() => _ControlOverlayState();
}

class _ControlOverlayState extends State<ControlOverlay> {
  List<AppInfo> apps = [];
  int currentIndex = 0;
  double progress = 0.0;
  Timer? _timer;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadApps();
  }

  Future<void> _loadApps() async {
    final list = await FlutterDeviceApps.listApps(
      includeSystem: false,
      onlyLaunchable: true,
      includeIcons: true,
    );
    list.shuffle();
    setState(() {
      apps = list.take(6).toList();
      loading = false;
    });
    _startProgress();
  }

  void _startProgress() {
    _timer?.cancel();
    progress = 0.0;
    _timer = Timer.periodic(const Duration(milliseconds: 80), (timer) {
      if (!mounted) return;
      setState(() {
        progress += 0.02;
        if (progress >= 1.0) {
          progress = 1.0;
          timer.cancel();
          Future.delayed(const Duration(milliseconds: 600), _nextApp);
        }
      });
    });
  }

  void _nextApp() {
    if (!mounted) return;
    if (currentIndex < apps.length - 1) {
      setState(() {
        currentIndex++;
        progress = 0.0;
      });
      _startProgress();
    } else {
      _finish();
    }
  }

  void _finish() {
    ConnectivityService.markOnlineHandled();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _timer?.cancel();
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

    final app = apps.isEmpty ? null : apps[currentIndex];

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
              '${currentIndex + 1} de ${apps.length}',
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const Spacer(),
            if (app != null) ...[
              if (app.iconBytes != null)
                Image.memory(app.iconBytes!, width: 96, height: 96)
              else
                const Icon(Icons.android, size: 96, color: Colors.white),
              const SizedBox(height: 16),
              Text(
                app.appName ?? 'Aplicativo',
                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('Liberando acesso à rede...', style: TextStyle(color: Colors.white70)),
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
