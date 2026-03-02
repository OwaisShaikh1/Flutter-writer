import '../providers/sync_provider.dart';
import '../database/database.dart';

/// Simplified sync diagnostics utility
/// The complex sync tracking has been removed in favor of direct API calls
class SyncDiagnostics {
  final SyncProvider _syncProvider;

  SyncDiagnostics(AppDatabase db) 
    : _syncProvider = SyncProvider(db);

  /// Get simple status for UI display
  String getSimpleStatus() {
    if (_syncProvider.isOnline) {
      return '✅ Online - Ready to sync';
    } else {
      return '📴 Offline';
    }
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'Never';
    
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }
}