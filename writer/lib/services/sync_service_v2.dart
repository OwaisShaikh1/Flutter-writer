// Re-export SyncService as SyncServiceV2 for compatibility
export 'sync_service.dart' show SyncResult;
import 'sync_service.dart';

/// Alias class for backwards compatibility
class SyncServiceV2 extends SyncService {
  SyncServiceV2(super.db);
}
