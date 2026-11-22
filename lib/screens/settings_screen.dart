import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/connectivity_service.dart';
import '../services/vpn_service.dart';
import '../services/flux_policy.dart';
import '../main.dart';
import 'app_filter_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int offlineHours = 2;
  int maxSimultaneous = 8;
  int maxControlMinutes = 3;
  bool prioritizeForeground = true;

  int selectedTestMinutes = 10;
  final TextEditingController _customController = TextEditingController();
  bool testActive = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      offlineHours = prefs.getInt('offline_hours') ?? 2;
      maxSimultaneous = prefs.getInt('max_simultaneous') ?? 8;
      maxControlMinutes = prefs.getInt('max_control_minutes') ?? 3;
      prioritizeForeground = prefs.getBool('prioritize_foreground') ?? true;
      testActive = ConnectivityService.isTestModeActive;
      selectedTestMinutes = ConnectivityService.testMinutes;
    });
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('offline_hours', offlineHours);
    await prefs.setInt('max_simultaneous', maxSimultaneous);
    await prefs.setInt('max_control_minutes', maxControlMinutes);
    await prefs.setBool('prioritize_foreground', prioritizeForeground);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Configurações salvas')),
      );
    }
  }

  Future<void> _startTest() async {
    int minutes = selectedTestMinutes;
    if (_customController.text.isNotEmpty) {
      final custom = int.tryParse(_customController.text);
      if (custom != null && custom > 0) {
        minutes = custom;
      }
    }
    await ConnectivityService.startTestMode(minutes);
    setState(() => testActive = true);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Modo de teste ativado: $minutes minutos')),
      );
    }
  }

  Future<void> _cancelTest() async {
    await ConnectivityService.cancelTestMode();
    setState(() => testActive = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Modo de teste cancelado')),
      );
    }
  }

  Future<void> _stopVpn() async {
    await VpnController.stop();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('VPN desligada. Internet liberada.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Monitoramento normal', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          const Text('Tempo offline mínimo para ativar', style: TextStyle(fontWeight: FontWeight.bold)),
          Slider(
            value: offlineHours.toDouble(),
            min: 1,
            max: 6,
            divisions: 5,
            label: '$offlineHours h',
            onChanged: (v) => setState(() => offlineHours = v.toInt()),
          ),
          Text('Padrão: 2 horas | Atual: $offlineHours h'),
          const SizedBox(height: 16),
          const Text('Máximo de apps simultâneos', style: TextStyle(fontWeight: FontWeight.bold)),
          Slider(
            value: maxSimultaneous.toDouble(),
            min: 2,
            max: 20,
            divisions: 18,
            label: '$maxSimultaneous',
            onChanged: (v) => setState(() => maxSimultaneous = v.toInt()),
          ),
          const SizedBox(height: 16),
          const Text('Tempo máximo de controle', style: TextStyle(fontWeight: FontWeight.bold)),
          Slider(
            value: maxControlMinutes.toDouble(),
            min: 1,
            max: 5,
            divisions: 4,
            label: '$maxControlMinutes min',
            onChanged: (v) => setState(() => maxControlMinutes = v.toInt()),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text('Priorizar app em primeiro plano'),
            value: prioritizeForeground,
            onChanged: (v) => setState(() => prioritizeForeground = v),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _save,
            child: const Text('Salvar configurações'),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _stopVpn,
            icon: const Icon(Icons.vpn_key_off),
            label: const Text('Desligar VPN agora'),
            style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
          ),
          OutlinedButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AppFilterScreen())), icon: const Icon(Icons.apps), label: const Text('Filtrar e priorizar aplicativos')),
          FilledButton.icon(
            onPressed: () async {
              await FluxPolicy.stopAll();
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Parada geral ativada.')));
            },
            icon: const Icon(Icons.power_settings_new), label: const Text('Parada geral'),
          ),
          OutlinedButton.icon(
            onPressed: () async {
              await FluxPolicy.resume();
              if (await FluxPolicy.canRun()) await initForegroundService();
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Monitoramento reativado.')));
            },
            icon: const Icon(Icons.restart_alt), label: const Text('Reativar FluxNet'),
          ),
          const Divider(height: 48),
          const Text('Modo de teste', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text(
            'Teste o sistema com tempos curtos. Não altera as configurações normais.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          if (testActive)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange),
              ),
              child: const Row(
                children: [
                  Icon(Icons.science, color: Colors.orange),
                  SizedBox(width: 8),
                  Text('Teste ativo', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          const SizedBox(height: 16),
          const Text('Tempo do teste'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [10, 20, 30].map((min) {
              return ChoiceChip(
                label: Text('$min min'),
                selected: selectedTestMinutes == min && _customController.text.isEmpty,
                onSelected: (_) {
                  setState(() {
                    selectedTestMinutes = min;
                    _customController.clear();
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _customController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Personalizado (minutos)',
              border: OutlineInputBorder(),
              hintText: 'Ex: 15',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: testActive ? null : _startTest,
                  child: const Text('Iniciar teste'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: testActive ? _cancelTest : null,
                  child: const Text('Cancelar teste'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
