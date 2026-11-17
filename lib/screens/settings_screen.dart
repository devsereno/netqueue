import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int offlineHours = 2;
  int maxSimultaneous = 1;
  int maxControlMinutes = 3;
  bool prioritizeForeground = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      offlineHours = prefs.getInt('offline_hours') ?? 2;
      maxSimultaneous = prefs.getInt('max_simultaneous') ?? 1;
      maxControlMinutes = prefs.getInt('max_control_minutes') ?? 3;
      prioritizeForeground = prefs.getBool('prioritize_foreground') ?? true;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
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
          const SizedBox(height: 24),
          const Text('Máximo de apps simultâneos', style: TextStyle(fontWeight: FontWeight.bold)),
          Slider(
            value: maxSimultaneous.toDouble(),
            min: 1,
            max: 3,
            divisions: 2,
            label: '$maxSimultaneous',
            onChanged: (v) => setState(() => maxSimultaneous = v.toInt()),
          ),
          const SizedBox(height: 24),
          const Text('Tempo máximo de controle', style: TextStyle(fontWeight: FontWeight.bold)),
          Slider(
            value: maxControlMinutes.toDouble(),
            min: 1,
            max: 5,
            divisions: 4,
            label: '$maxControlMinutes min',
            onChanged: (v) => setState(() => maxControlMinutes = v.toInt()),
          ),
          const SizedBox(height: 24),
          SwitchListTile(
            title: const Text('Priorizar app em primeiro plano'),
            value: prioritizeForeground,
            onChanged: (v) => setState(() => prioritizeForeground = v),
          ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: _save,
            child: const Text('Salvar configurações'),
          ),
        ],
      ),
    );
  }
}
