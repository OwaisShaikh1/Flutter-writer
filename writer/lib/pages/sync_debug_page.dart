import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../database/database.dart';
import '../database/dao/sync_log_dao.dart';
import '../providers/sync_provider.dart';

class SyncDebugPage extends StatefulWidget {
  const SyncDebugPage({super.key});

  @override
  State<SyncDebugPage> createState() => _SyncDebugPageState();
}

class _SyncDebugPageState extends State<SyncDebugPage> {
  late final SyncLogDao _syncLogDao;
  bool _isBusy = false;
  List<SyncLogEntry> _entries = const [];

  @override
  void initState() {
    super.initState();
    _syncLogDao = SyncLogDao(context.read<AppDatabase>());
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    final rows = await _syncLogDao.getPendingOperations();
    if (!mounted) return;
    setState(() {
      _entries = rows;
    });
  }

  Future<void> _processNow() async {
    if (_isBusy) return;
    setState(() => _isBusy = true);
    try {
      final result = await context.read<SyncProvider>().forceSync();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.success ? 'Sync completed' : 'Sync failed: ${result.message}')),
      );
      await _loadEntries();
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _clearQueue() async {
    if (_isBusy) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Sync Queue'),
        content: const Text(
          'This will remove all pending sync_log entries from local storage. Use only for testing.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isBusy = true);
    try {
      await _syncLogDao.clearAll();
      if (!mounted) return;
      await _loadEntries();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sync queue cleared')),
      );
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  String _payloadPreview(String payload) {
    try {
      final decoded = jsonDecode(payload);
      final text = const JsonEncoder.withIndent('  ').convert(decoded);
      return text.length > 300 ? '${text.substring(0, 300)}...' : text;
    } catch (_) {
      return payload.length > 300 ? '${payload.substring(0, 300)}...' : payload;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sync Debug'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reload queue',
            onPressed: _isBusy ? null : _loadEntries,
          ),
          IconButton(
            icon: const Icon(Icons.play_arrow),
            tooltip: 'Process queue now',
            onPressed: _isBusy ? null : _processNow,
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Clear queue',
            onPressed: _isBusy ? null : _clearQueue,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Text('Pending entries: ${_entries.length}'),
                const Spacer(),
                if (kDebugMode)
                  const Text(
                    'Debug mode',
                    style: TextStyle(fontSize: 12),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _entries.isEmpty
                ? const Center(child: Text('No pending sync operations'))
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: _entries.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final e = _entries[index];
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '#${e.id}  ${e.entityType}/${e.operation}  entity=${e.entityId}',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 4),
                              Text('user=${e.userId ?? 'null'} parent=${e.parentId ?? 'null'} attempts=${e.attempts}'),
                              if (e.lastError != null && e.lastError!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'lastError: ${e.lastError}',
                                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                                ),
                              ],
                              const SizedBox(height: 8),
                              Text(
                                _payloadPreview(e.payload),
                                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
