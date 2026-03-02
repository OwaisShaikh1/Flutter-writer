enum ConflictResolution {
  serverWins,
  clientWins, 
  mergeChanges,
  manualResolve,
}

class ConflictInfo {
  final String entityType;
  final int entityId;
  final int serverVersion;
  final int clientVersion;
  final Map<String, dynamic> serverData;
  final Map<String, dynamic> clientData;
  final DateTime serverUpdatedAt;
  final DateTime clientUpdatedAt;
  
  ConflictInfo({
    required this.entityType,
    required this.entityId,
    required this.serverVersion,
    required this.clientVersion,
    required this.serverData,
    required this.clientData,
    required this.serverUpdatedAt,
    required this.clientUpdatedAt,
  });

  bool get hasVersionConflict => serverVersion != clientVersion;
  bool get hasTimestampConflict => serverUpdatedAt.isAfter(clientUpdatedAt);
  
  // Simple heuristic: server is newer if its version is higher OR if timestamps are newer  
  bool get serverIsNewer => serverVersion > clientVersion || hasTimestampConflict;
}

class ConflictResolver {
  /// Resolve conflict based on strategy
  static Map<String, dynamic> resolveConflict(
    ConflictInfo conflict, 
    ConflictResolution strategy
  ) {
    switch (strategy) {
      case ConflictResolution.serverWins:
        return conflict.serverData;
        
      case ConflictResolution.clientWins:
        return conflict.clientData;
        
      case ConflictResolution.mergeChanges:
        return _mergeChanges(conflict);
        
      case ConflictResolution.manualResolve:
        // Return null to indicate manual resolution needed
        throw ConflictNeedsManualResolutionException(conflict);
    }
  }
  
  /// Simple merge strategy: use server data but preserve client-specific fields
  static Map<String, dynamic> _mergeChanges(ConflictInfo conflict) {
    final merged = Map<String, dynamic>.from(conflict.serverData);
    
    // Preserve client-specific fields that shouldn't be overridden by server
    final clientPreservedFields = ['isFavorite', 'hasChanged', 'imageLocalPath'];
    
    for (final field in clientPreservedFields) {
      if (conflict.clientData.containsKey(field)) {
        merged[field] = conflict.clientData[field];
      }
    }
    
    // For chapters, try to merge content if both changed
    if (conflict.entityType == 'chapter' && 
        conflict.clientData['content'] != conflict.serverData['content']) {
      merged['content'] = _mergeChapterContent(
        conflict.serverData['content'] as String? ?? '',
        conflict.clientData['content'] as String? ?? '',
      );
    }
    
    // Use the higher version number
    merged['version'] = [conflict.serverVersion, conflict.clientVersion].reduce((a, b) => a > b ? a : b) + 1;
    merged['updatedAt'] = DateTime.now().toIso8601String();
    
    return merged;
  }
  
  /// Simple content merge: append client changes to server content if different
  static String _mergeChapterContent(String serverContent, String clientContent) {
    if (serverContent == clientContent) return serverContent;
    if (serverContent.isEmpty) return clientContent;
    if (clientContent.isEmpty) return serverContent;
    
    // Simple strategy: append client content with a separator
    return '$serverContent\n\n--- Client Changes ---\n$clientContent';
  }
}

class ConflictNeedsManualResolutionException implements Exception {
  final ConflictInfo conflict;
  
  ConflictNeedsManualResolutionException(this.conflict);
  
  @override
  String toString() => 'Manual conflict resolution needed for ${conflict.entityType} ${conflict.entityId}';
}