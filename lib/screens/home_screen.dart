import 'dart:async';
import 'package:flutter/material.dart';
import '../services/connectivity_service.dart';
import 'control_overlay.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String status = 'Monitorando conexão...';
  bool controlActive = false;
  Timer? _refreshTimer;
  StreamSubscription<void>? _autoSub;

  @override
  void initState() {
    super.initState();
    _checkStatus();
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) => _checkStatus());
    _autoSub = ConnectivityService.onAutoTrigger.listen((_) {
      if (!controlActive && mounted) {
        _startControl(auto: true);
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _autoSub?.cancel();
    super.dispose();
  }

  Future<void> _checkStatus() async {
    final should = await ConnectivityService.shouldActivateControl();
    if (mounted) {
      setState(() {
        status = should
            ? 'Condição atingida. Aguardando internet para iniciar automaticamente.'
            : 'Aguardando período offline suficiente.';
      });
    }
  }

  void _startControl({bool auto = false}) async {
    if (controlActive) return;
    final should = await ConnectivityService.shouldActivateControl();
    if (!should && !auto) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ainda não passou tempo offline suficiente.')),
      );
      return;
    }
    setState(() => controlActive = true);
    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => const ControlOverlay(),
        ),
      ).then((_) {
        if (mounted) {
          setState(() => controlActive = false);
        }
        ConnectivityService.markOnlineHandled();
        _checkStatus();
      });
    }
  }

  String _formatDuration(Duration d) {
    if (d.inHours > 0) {
      return '${d.inHours}h ${d.inMinutes.remainder(60)}min';
    }
    return '${d.inMinutes}min ${d.inSeconds.remainder(60)}s';
  }

  @override
  Widget build(BuildContext context) {
    final isTest = ConnectivityService.isTestModeActive;
    final offline = ConnectivityService.currentOfflineDuration;
    final required = ConnectivityService.requiredOfflineDuration;
    final progress = required.inSeconds > 0
        ? (offline.inSeconds / required.inSeconds).clamp(0.0, 1.0)
        : 0.0;
    final reached = offline >= required;

    return Scaffold(
      appBar: AppBar(
        title: const Text('NetQueue'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ).then((_) => _checkStatus()),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isTest ? Colors.orange : Colors.blue,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isTest ? 'MODO TESTE' : 'MODO NORMAL',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(status, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Status do monitoramento', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('Tempo offline acumulado: ${_formatDuration(offline)}'),
                    Text('Tempo necessário: ${_formatDuration(required)}'),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(value: progress),
                    const SizedBox(height: 8),
                    Text(reached
                        ? 'Período atingido. Aguardando internet para iniciar automaticamente.'
                        : 'Aguardando período mínimo...'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'O sistema inicia a fila automaticamente assim que o tempo offline for atingido e a internet voltar. Não é preciso apertar nenhum botão.',
            ),
            const Spacer(),
            if (controlActive)
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                  setState(() => controlActive = false);
                },
                icon: const Icon(Icons.stop),
                label: const Text('Parar operação'),
              )
            else
              FilledButton.icon(
                onPressed: () => _startControl(auto: false),
                icon: const Icon(Icons.play_arrow),
                label: const Text('Iniciar controle de fila agora'),
              ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _checkStatus,
              child: const Text('Atualizar status'),
            ),
          ],
        ),
      ),
    );
  }
}
