import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/app_list_service.dart';

class AppFilterScreen extends StatefulWidget {
  const AppFilterScreen({super.key});
  @override State<AppFilterScreen> createState() => _AppFilterScreenState();
}
class _AppFilterScreenState extends State<AppFilterScreen> {
  List<Map<String,String>> apps = [];
  Set<String> excluded = {}, priority = {};
  String search = '';
  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final a = await AppListService.getCachedOrLoad();
    if (mounted) setState(() {
      apps = a;
      excluded = (prefs.getStringList('flux_excluded') ?? []).toSet();
      priority = (prefs.getStringList('flux_priority') ?? []).toSet();
    });
  }
  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('flux_excluded', excluded.toList());
    await prefs.setStringList('flux_priority', priority.toList());
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preferências de aplicativos salvas')));
  }
  @override Widget build(BuildContext context) {
    final visible = apps.where((a) => '${a['name']} ${a['package']}'.toLowerCase().contains(search.toLowerCase())).toList();
    return Scaffold(appBar: AppBar(title: const Text('Aplicativos da fila'), actions: [IconButton(onPressed: _save, icon: const Icon(Icons.save))]),
      body: Column(children: [
        Padding(padding: const EdgeInsets.all(12), child: TextField(decoration: const InputDecoration(labelText: 'Buscar aplicativo', prefixIcon: Icon(Icons.search)), onChanged: (v) => setState(() => search = v))),
        const Padding(padding: EdgeInsets.all(8), child: Text('Incluir = participa da fila. Prioritário = vai antes. Aplicativos fora da fila não são bloqueados individualmente pela VPN; podem continuar sujeitos ao túnel durante os lotes.')),
        Expanded(child: ListView.builder(itemCount: visible.length, itemBuilder: (context, i) {
          final app = visible[i], pkg = app['package']!;
          return ListTile(title: Text(app['name'] ?? pkg), subtitle: Text(pkg, maxLines: 1, overflow: TextOverflow.ellipsis),
            leading: Checkbox(value: !excluded.contains(pkg), onChanged: (v) => setState(() { if (v == true) excluded.remove(pkg); else {excluded.add(pkg); priority.remove(pkg);} })),
            trailing: IconButton(tooltip: 'Prioridade', icon: Icon(priority.contains(pkg) ? Icons.star : Icons.star_border), onPressed: excluded.contains(pkg) ? null : () => setState(() { if (!priority.add(pkg)) priority.remove(pkg); })));
        }))
      ]));
  }
}
