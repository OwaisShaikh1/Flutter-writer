import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sync_provider.dart';
import '../providers/literature_provider.dart';
import '../services/offline_sync_service.dart';

class OfflineStatusIndicator extends StatelessWidget {
  const OfflineStatusIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<SyncProvider, LiteratureProvider>(
      builder: (context, syncProvider, literatureProvider, child) {
        final isOnline = syncProvider.isOnline;
        final isSyncing = syncProvider.isSyncing || literatureProvider.isSyncing;
        final pendingCount = syncProvider.pendingCount;
        final hasOfflineChanges = syncProvider.hasOfflineChanges;

        // Don't show anything if online and no pending changes
        if (isOnline && !isSyncing && !hasOfflineChanges) {
          return const SizedBox.shrink();
        }

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _getStatusColor(isOnline, isSyncing, hasOfflineChanges),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSyncing) ...[
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(width: 8),
              ] else ...[
                Icon(
                  _getStatusIcon(isOnline, hasOfflineChanges),
                  size: 16,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
              ],
              Text(
                _getStatusText(isOnline, isSyncing, hasOfflineChanges, pendingCount),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (hasOfflineChanges && !isSyncing && isOnline) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _triggerSync(context, syncProvider, literatureProvider),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Sync',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Color _getStatusColor(bool isOnline, bool isSyncing, bool hasOfflineChanges) {
    if (isSyncing) return Colors.blue;
    if (!isOnline) return Colors.red;
    if (hasOfflineChanges) return Colors.orange;
    return Colors.green;
  }

  IconData _getStatusIcon(bool isOnline, bool hasOfflineChanges) {
    if (!isOnline) return Icons.wifi_off;
    if (hasOfflineChanges) return Icons.cloud_upload_outlined;
    return Icons.cloud_done;
  }

  String _getStatusText(bool isOnline, bool isSyncing, bool hasOfflineChanges, int pendingCount) {
    if (isSyncing) return 'Syncing...';
    if (!isOnline && hasOfflineChanges) return 'Offline ($pendingCount changes)';
    if (!isOnline) return 'Offline';
    if (hasOfflineChanges) return '$pendingCount changes pending';
    return 'Synced';
  }

  void _triggerSync(context, SyncProvider syncProvider, LiteratureProvider literatureProvider) async {
    try {
      final result = await syncProvider.forceSync();
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.success ? 'Sync completed successfully!' : 'Sync failed: ${result.message}'),
            backgroundColor: result.success ? Colors.green : Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync failed: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}

class SyncStatusCard extends StatelessWidget {
  const SyncStatusCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<SyncProvider, LiteratureProvider>(
      builder: (context, syncProvider, literatureProvider, child) {
        final pendingCount = syncProvider.pendingCount;
        
        if (pendingCount == 0) return const SizedBox.shrink();

        return Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.sync_problem,
                      color: syncProvider.isOnline ? Colors.orange : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Offline Changes',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  syncProvider.isOnline
                      ? 'You have $pendingCount unsynchronized changes that will be uploaded when you sync.'
                      : 'You have $pendingCount changes saved locally. They will be synchronized when you get back online.',
                ),
                const SizedBox(height: 12),
                if (syncProvider.isOnline && !syncProvider.isSyncing)
                  ElevatedButton.icon(
                    onPressed: () => _triggerManualSync(context, syncProvider),
                    icon: const Icon(Icons.sync),
                    label: const Text('Sync Now'),
                  ),
                if (syncProvider.isSyncing)
                  const Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 8),
                      Text('Synchronizing...'),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _triggerManualSync(context, SyncProvider syncProvider) async {
    try {
      final result = await syncProvider.forceSync() ;
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.success 
                ? 'Successfully synchronized ${result.itemCount ?? 0} changes!' 
                : 'Sync failed: ${result.message}'
            ),
            backgroundColor: result.success ? Colors.green : Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}