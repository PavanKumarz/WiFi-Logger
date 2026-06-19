import 'package:flutter/material.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:wifi_logger/services/db_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> _results = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadResults();
  }

  Future<void> _loadResults() async {
    final data = await DbService.getResults();
    setState(() {
      _results = data;
      _loading = false;
    });
  }

  Future<void> _clearHistory() async {
    await DbService.deleteAll();
    _loadResults();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _results.isEmpty ? null : _clearHistory,
            tooltip: 'Clear history',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _results.isEmpty
          ? const Center(child: Text('No tests yet. Run a speed test first.'))
          : RefreshIndicator(
              onRefresh: _loadResults,
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _results.length,
                itemBuilder: (context, index) {
                  final r = _results[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: DottedBorder(
                      dashPattern: const [6, 3],
                      borderType: BorderType.RRect,
                      radius: const Radius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r['network_name'] ?? 'Unknown',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Download: ${r['download_speed']} Mbps'),
                                Text('Upload: ${r['upload_speed']} Mbps'),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Ping: ${r['ping']} ms'),
                                Text(r['tested_at'] ?? ''),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
