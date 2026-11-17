import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    final should = await ConnectivityService.shouldActivateControl();
    if (mounted) {
      setState(() {
        status = should
            ? 'Condição atingida! Pronto para controlar a fila.'
            : 'Aguardando período offline suficiente.';
      });
    }
  }

  void _startControl() async {
    final should = await ConnectivityService.shouldActivateControl();
    if (!should) {
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
        setState(() => controlActive = false);
        ConnectivityService.markOnlineHandled();
        _checkStatus();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NetQueue'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(status, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 32),
            const Text(
              'Este app monitora quando a internet fica desligada por um tempo longo. '
              'Quando você liga a internet de novo, ele pode criar uma fila controlada '
              'para os apps acessarem a rede sem travar o celular.',
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: controlActive ? null : _startControl,
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
