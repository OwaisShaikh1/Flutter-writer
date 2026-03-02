import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../theme/app_theme.dart';
import '../providers/sync_provider.dart';
import '../providers/literature_provider.dart';

class OfflineIndicator extends StatelessWidget {
  const OfflineIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<SyncProvider, LiteratureProvider>(
      builder: (context, syncProvider, literatureProvider, _) {
        final isOnline = syncProvider.isOnline;
        final hasOfflineChanges = syncProvider.hasOfflineChanges;
        final pendingCount = syncProvider.pendingCount;
        
        // Show banner if offline OR if there are pending changes
        if (isOnline && !hasOfflineChanges) {
          return const SizedBox.shrink();
        }
        
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          color: isOnline 
              ? Colors.orange.shade600  // Has pending changes
              : Theme.of(context).colorScheme.error,  // Offline
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                Icon(
                  isOnline ? Icons.cloud_upload_outlined : Icons.wifi_off,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isOnline 
                        ? 'You have $pendingCount changes that will sync automatically when connected.'
                        : 'You are offline. Changes are saved locally and will sync when reconnected.',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                    ),
                  ),
                ),
                if (isOnline && hasOfflineChanges && !syncProvider.isSyncing) ...[
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => _triggerSync(context, syncProvider),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                    child: const Text('Sync Now', style: TextStyle(fontSize: 12)),
                  ),
                ],
                if (syncProvider.isSyncing) ...[
                  const SizedBox(width: 8),
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _triggerSync(context, SyncProvider syncProvider) async {
    try {
      final result = await syncProvider.forceSync();
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.success ? 'Sync completed!' : 'Sync failed: ${result.message}'),
            backgroundColor: result.success ? Colors.green : Colors.red,
            duration: const Duration(seconds: 2),
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

// Alternative compact offline indicator for app bars
class OfflineChip extends StatelessWidget {
  const OfflineChip({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SyncProvider>(
      builder: (context, syncProvider, _) {
        final isOnline = syncProvider.isOnline;
        final hasOfflineChanges = syncProvider.hasOfflineChanges;
        final isSyncing = syncProvider.isSyncing;
        
        // Show chip if offline OR has pending changes OR syncing
        if (isOnline && !hasOfflineChanges && !isSyncing) {
          return const SizedBox.shrink();
        }
        
        final backgroundColor = isSyncing
            ? Colors.blue.withOpacity(0.1)
            : !isOnline
                ? Colors.red.withOpacity(0.1)
                : Colors.orange.withOpacity(0.1);
                
        final textColor = isSyncing
            ? Colors.blue
            : !isOnline
                ? Colors.red
                : Colors.orange;
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: textColor.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSyncing) ...[
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    valueColor: AlwaysStoppedAnimation<Color>(textColor),
                  ),
                ),
              ] else ...[
                Icon(
                  !isOnline 
                      ? Icons.wifi_off 
                      : hasOfflineChanges
                          ? Icons.cloud_upload_outlined
                          : Icons.cloud_done,
                  color: textColor,
                  size: 12,
                ),
              ],
              const SizedBox(width: 4),
              Text(
                isSyncing 
                    ? 'Syncing'
                    : !isOnline
                        ? 'Offline'
                        : '${syncProvider.pendingCount} pending',
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w500,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
