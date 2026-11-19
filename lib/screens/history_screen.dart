import 'package:flutter/material.dart';
import '../services/app_list_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> history = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final h = await AppListService.getHistory();
    if (mounted) {
      setState(() {
        history = h;
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Histórico da fila')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : history.isEmpty
              ? const Center(child: Text('Nenhum app passou pela fila ainda.'))
              : ListView.builder(
                  itemCount: history.length,
                  itemBuilder: (_, i) {
                    final item = history[i];
                    final time = DateTime.tryParse(item['time'] ?? '')?.toLocal();
                    return ListTile(
                      title: Text(item['name'] ?? 'App'),
                      subtitle: Text(time != null
                          ? '${time.day}/${time.month} ${time.hour}:${time.minute.toString().padLeft(2, '0')}'
                          : ''),
                    );
                  },
                ),
    );
  }
}
