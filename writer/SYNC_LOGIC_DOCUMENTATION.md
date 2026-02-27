# Database Sync Logic - Complete Documentation

## Overview

This document explains the minimal, bulletproof sync logic between the Flutter app (SQLite) and the Node.js backend (MySQL).

---

## 1. Database Schema Mapping

### Server Database (MySQL)

```sql
-- Users table
CREATE TABLE users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  Name VARCHAR(255),
  username VARCHAR(255) UNIQUE,
  password VARCHAR(255),
  email VARCHAR(255)
);

-- Items (Literature works) table
CREATE TABLE items (
  id INT AUTO_INCREMENT PRIMARY KEY,      -- Server-assigned ID
  name VARCHAR(255),
  type VARCHAR(50),                        -- Drama, Poetry, Novel
  description TEXT,
  review DECIMAL(3,1) DEFAULT 0,           -- Rating
  image_path VARCHAR(255),
  author_id INT,                           -- FK to users.id
  FOREIGN KEY (author_id) REFERENCES users(id)
);

-- Chapters table
CREATE TABLE chapters (
  id INT AUTO_INCREMENT PRIMARY KEY,
  number INT,                              -- Chapter number (1, 2, 3...)
  name VARCHAR(255),                       -- Chapter title
  item_id INT,                             -- FK to items.id (SERVER ID)
  Text TEXT,                               -- Chapter content
  FOREIGN KEY (item_id) REFERENCES items(id) ON DELETE CASCADE
);

-- Likes table
CREATE TABLE likes (
  id INT AUTO_INCREMENT PRIMARY KEY,
  item_id INT,
  user_id INT,
  UNIQUE KEY unique_like (item_id, user_id)
);

-- Comments table
CREATE TABLE comments (
  id INT AUTO_INCREMENT PRIMARY KEY,
  item_id INT,
  user_id INT,
  content TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
```

### Local Database (SQLite/Drift)

```dart
// Items table
class Items extends Table {
  IntColumn get id => integer().autoIncrement()();     // LOCAL ID (never changes)
  IntColumn get serverId => integer().nullable()();    // SERVER ID (set after sync)
  TextColumn get name => text()();
  TextColumn get author => text()();
  IntColumn get authorId => integer().nullable()();
  TextColumn get type => text()();
  RealColumn get rating => real().withDefault(const Constant(0.0))();
  IntColumn get chaptersCount => integer().withDefault(const Constant(0))();
  IntColumn get commentsCount => integer().withDefault(const Constant(0))();
  IntColumn get likesCount => integer().withDefault(const Constant(0))();
  BoolColumn get isLikedByUser => boolean().withDefault(const Constant(false))();
  TextColumn get imageUrl => text().nullable()();
  TextColumn get imageLocalPath => text().nullable()();
  TextColumn get description => text()();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// Chapters table
class Chapters extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get itemId => integer().references(Items, #id)();  // References LOCAL items.id
  IntColumn get number => integer()();
  TextColumn get title => text()();
  TextColumn get content => text()();
  BoolColumn get isDownloaded => boolean().withDefault(const Constant(false))();
  DateTimeColumn get downloadedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// Sync Log table (pending operations queue)
class SyncLog extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get entityType => text()();     // 'item' or 'chapter'
  IntColumn get entityId => integer()();     // LOCAL entity ID
  IntColumn get parentId => integer().nullable()();  // For chapters: LOCAL item ID
  TextColumn get operation => text()();      // 'create', 'update', 'delete'
  TextColumn get payload => text()();        // JSON data
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
}
```

---

## 2. The Key Concept: Local ID vs Server ID

| Field | Source | When Set | Can Change? | Used For |
|-------|--------|----------|-------------|----------|
| `id` (local) | SQLite autoincrement | On insert | **Never** | All local references, FK constraints |
| `server_id` | Backend response | After first sync | **Never** (set once) | API calls to backend |

### Why This Matters

```
┌─────────────────────────────────────────────────────────────────────────┐
│  LOCAL DATABASE                                                          │
├─────────────────────────────────────────────────────────────────────────┤
│  items table:                                                            │
│  ┌────┬───────────┬────────────────────────────────┐                    │
│  │ id │ server_id │ name                           │                    │
│  ├────┼───────────┼────────────────────────────────┤                    │
│  │ 1  │ 42        │ "My Novel" (synced)            │                    │
│  │ 2  │ NULL      │ "Draft Story" (local only)     │                    │
│  │ 3  │ 99        │ "Another Work" (synced)        │                    │
│  │ 50 │ 50        │ "Server Item" (pulled from API)│  ← Note: id=server_id │
│  └────┴───────────┴────────────────────────────────┘                    │
│                                                                          │
│  chapters table:                                                         │
│  ┌────┬─────────┬────────┬─────────────────────────┐                    │
│  │ id │ item_id │ number │ title                   │                    │
│  ├────┼─────────┼────────┼─────────────────────────┤                    │
│  │ 1  │ 1       │ 1      │ "Chapter 1"             │  ← item_id=1 (LOCAL) │
│  │ 2  │ 1       │ 2      │ "Chapter 2"             │                    │
│  │ 3  │ 2       │ 1      │ "Draft Chapter"         │  ← item_id=2 (LOCAL) │
│  └────┴─────────┴────────┴─────────────────────────┘                    │
└─────────────────────────────────────────────────────────────────────────┘

When making API call for Chapter 1:
1. Get chapter.item_id = 1 (LOCAL)
2. Look up items.server_id WHERE id = 1 → server_id = 42
3. Call API with server_id = 42
```

---

## 3. CRUD Operations Flow

### Item Creation

```
User creates "My New Novel"
         │
         ▼
┌─────────────────────────────────────┐
│ 1. Insert into local DB             │
│    - id = 5 (auto-generated)        │
│    - server_id = NULL               │
│    - is_synced = false              │
└─────────────────────────────────────┘
         │
         ▼
    ┌─────────┐
    │ Online? │
    └────┬────┘
         │
    ┌────┴────┐
   YES        NO
    │          │
    ▼          │
┌──────────────────────┐   │
│ 2. POST /items       │   │
│    Returns id: 77    │   │
└──────────────────────┘   │
         │                 │
         ▼                 │
┌──────────────────────┐   │
│ 3. Update local:     │   │
│    server_id = 77    │   │
│    is_synced = true  │   │
└──────────────────────┘   │
         │                 │
         └────────┬────────┘
                  │
                  ▼
         ┌───────────────────────┐
    NO   │ 4. Add to sync_log:   │
    ─────│    entity_type: item  │
         │    entity_id: 5       │
         │    operation: create  │
         │    payload: {...data} │
         └───────────────────────┘
```

### Item Update

```
User updates item (local_id = 5)
         │
         ▼
┌─────────────────────────────────────┐
│ 1. Update local DB immediately      │
└─────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────┐
│ 2. Get server_id from local DB      │
│    SELECT server_id WHERE id = 5    │
│    → server_id = 77 (or NULL)       │
└─────────────────────────────────────┘
         │
         ▼
    ┌──────────────────────┐
    │ Online AND           │
    │ server_id != NULL ?  │
    └──────────┬───────────┘
               │
    ┌──────────┴──────────┐
   YES                    NO
    │                      │
    ▼                      │
┌──────────────────────┐   │
│ 3. PUT /items/77     │   │
└──────────────────────┘   │
    │                      │
    └──────────┬───────────┘
               │
               ▼
       ┌───────────────────────┐
  NO   │ 4. Add to sync_log:   │
  ─────│    operation: update  │
       │    entity_id: 5       │
       │    (LOCAL id)         │
       └───────────────────────┘
```

### Chapter Creation

```
User creates chapter for item (local_id = 5)
         │
         ▼
┌─────────────────────────────────────┐
│ 1. Insert into local DB             │
│    - item_id = 5 (LOCAL id)         │
│    - number = 1                     │
└─────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────┐
│ 2. Get parent item's server_id      │
│    SELECT server_id WHERE id = 5    │
│    → server_id = 77 (or NULL)       │
└─────────────────────────────────────┘
         │
         ▼
    ┌──────────────────────┐
    │ Online AND           │
    │ parent server_id     │
    │ != NULL ?            │
    └──────────┬───────────┘
               │
    ┌──────────┴──────────┐
   YES                    NO
    │                      │
    ▼                      │
┌──────────────────────┐   │
│ 3. POST /chapters    │   │
│    {itemId: 77, ...} │   │  ← Use SERVER id
└──────────────────────┘   │
    │                      │
    └──────────┬───────────┘
               │
               ▼
       ┌───────────────────────┐
  NO   │ 4. Add to sync_log:   │
  ─────│    entity_type: chapter│
       │    parent_id: 5       │  ← LOCAL item id
       │    operation: create  │
       └───────────────────────┘
```

---

## 4. Push Sync Logic (Local → Server)

When user clicks "Sync" or app comes online:

```
┌─────────────────────────────────────────────────────────────────────────┐
│  PUSH SYNC ALGORITHM                                                     │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  1. Get all pending operations from sync_log (ordered by created_at)    │
│                                                                          │
│  2. Initialize empty mapping: newItemIdMapping = {}                     │
│     (tracks local_id → server_id for items created in this batch)       │
│                                                                          │
│  3. For each operation:                                                  │
│                                                                          │
│     IF entity_type == 'item':                                           │
│        IF operation == 'create':                                        │
│           → POST /items                                                  │
│           → Get server_id from response                                 │
│           → UPDATE items SET server_id = X WHERE id = local_id         │
│           → newItemIdMapping[local_id] = server_id                      │
│                                                                          │
│        IF operation == 'update':                                        │
│           → server_id = newItemIdMapping[local_id] ?? getServerId()    │
│           → PUT /items/{server_id}                                      │
│                                                                          │
│        IF operation == 'delete':                                        │
│           → server_id = getServerId(local_id)                          │
│           → DELETE /items/{server_id}  (if server_id exists)           │
│                                                                          │
│     IF entity_type == 'chapter':                                        │
│        → parent_server_id = newItemIdMapping[parent_id]                │
│                           ?? getServerId(parent_id)                     │
│                                                                          │
│        IF operation == 'create':                                        │
│           → POST /chapters {itemId: parent_server_id, ...}             │
│                                                                          │
│        IF operation == 'update':                                        │
│           → PUT /chapters/{parent_server_id}/{chapterNumber}           │
│                                                                          │
│        IF operation == 'delete':                                        │
│           → DELETE /chapters/{parent_server_id}/{chapterNumber}        │
│                                                                          │
│  4. Remove operation from sync_log on success                           │
│     Mark as attempted with error on failure                             │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### Why newItemIdMapping?

Consider this scenario:
1. User creates Item A offline (local_id = 10)
2. User creates Chapter 1 for Item A offline
3. User creates Chapter 2 for Item A offline
4. User clicks Sync

sync_log contains:
```
[
  {entity_type: 'item', entity_id: 10, operation: 'create'},
  {entity_type: 'chapter', parent_id: 10, operation: 'create', payload: {number: 1}},
  {entity_type: 'chapter', parent_id: 10, operation: 'create', payload: {number: 2}}
]
```

When processing:
1. Create Item A → server returns server_id = 55
2. Store mapping: newItemIdMapping[10] = 55
3. Create Chapter 1 → look up parent_id=10 in mapping → use server_id=55
4. Create Chapter 2 → same lookup → use server_id=55

Without the mapping, chapters would fail because `getServerId(10)` won't have the server_id yet (database update might not be committed yet in same transaction).

---

## 5. Pull Sync Logic (Server → Local)

```
┌─────────────────────────────────────────────────────────────────────────┐
│  PULL SYNC ALGORITHM                                                     │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  1. GET /items from server                                              │
│                                                                          │
│  2. For each server item:                                               │
│                                                                          │
│     Check: existing = SELECT * FROM items WHERE server_id = item.id    │
│                                                                          │
│     IF existing != NULL:                                                │
│        → UPDATE existing item with server data                          │
│        → Preserve local id (never change it)                           │
│                                                                          │
│     ELSE:                                                               │
│        → INSERT new item with:                                          │
│          - id = server_id (for simplicity: local_id == server_id)      │
│          - server_id = server_id                                        │
│          - is_synced = true                                             │
│                                                                          │
│  3. DELETION SYNC - Detect items deleted on other devices:              │
│     → Get all local synced items (WHERE server_id IS NOT NULL)         │
│     → For each local synced item:                                       │
│        IF server_id NOT IN server_item_ids:                            │
│           → DELETE chapters WHERE item_id = local_id                    │
│           → DELETE item WHERE id = local_id                             │
│     → Preserves local-only items (server_id = NULL)                    │
│                                                                          │
│  4. For each item, pull chapters:                                       │
│     → GET /chapters?bookId={server_id}                                  │
│     → Store with item_id = local_id (not server_id!)                   │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### Server-Originated vs Local-Originated Items

| Origin | Local ID | Server ID | Notes |
|--------|----------|-----------|-------|
| Created locally, synced | Auto (e.g., 5) | Different (e.g., 77) | IDs differ |
| Pulled from server | Same as server (e.g., 77) | 77 | IDs match |
| Created locally, NOT synced | Auto (e.g., 8) | NULL | No server ID yet |

### Deletion Sync Behavior

**When Device A deletes an item:**
1. Item deleted locally on Device A
2. DELETE request sent to server → item removed from database
3. Device A has no trace of the item

**When Device B syncs:**
1. Pulls all items from server (deleted item NOT in list)
2. Compares local synced items with server items
3. Finds the deleted item (has server_id but not on server)
4. Deletes it locally → Device B now matches Device A

**Local-only items are safe:**
- Items created offline (server_id = NULL) are never deleted during pull sync
- They'll be pushed when the device comes online

---

## 6. Sync Log Optimizations

The sync_log DAO has smart deduplication:

### Create + Update → Single Create
```dart
// If create is pending and update comes in, merge them:
Future<void> logItemUpdate(int itemId, Map<String, dynamic> data) async {
  final existingCreate = await getPendingCreate(itemId);
  if (existingCreate != null) {
    // Merge update data into create payload
    existingData.addAll(data);
    await updatePayload(existingCreate.id, existingData);
  } else {
    // Log as separate update
    await insertUpdateLog(itemId, data);
  }
}
```

### Create + Delete → Remove Both
```dart
Future<void> logItemDelete(int itemId) async {
  // Remove any pending creates/updates for this item
  await deleteWhere(entityType: 'item', entityId: itemId);
  
  // Remove pending chapter operations for this item
  await deleteWhere(entityType: 'chapter', parentId: itemId);
  
  // Log the delete (only if item was synced)
  await insertDeleteLog(itemId);
}
```

---

## 7. Edge Cases Handled

### Case 1: Create Item, Add Chapters, Go Online
```
Timeline:
1. Offline: Create Item (local_id=5)
2. Offline: Add Chapter 1 (item_id=5)
3. Offline: Add Chapter 2 (item_id=5)
4. Online: Click Sync

Sync process:
- Process item create → server returns id=99 → store server_id=99
- Process chapter 1 create → look up parent server_id=99 → POST
- Process chapter 2 create → look up parent server_id=99 → POST
✅ All synced correctly
```

### Case 2: Edit Item While Offline
```
Timeline:
1. Online: Create Item → synced (local=5, server=99)
2. Offline: Edit item title
3. Offline: Edit item description
4. Online: Click Sync

Sync process:
- First edit creates sync_log entry
- Second edit UPDATES same sync_log entry (merged)
- Only ONE update sent to server
✅ Efficient sync
```

### Case 3: Delete Unsynced Item
```
Timeline:
1. Offline: Create Item (local_id=5, server_id=NULL)
2. Offline: Add Chapter 1
3. Offline: Delete Item

Sync process:
- Delete removes all pending operations for item and its chapters
- No API calls needed (nothing exists on server)
✅ Clean slate
```

### Case 4: Network Failure During Sync
```
Timeline:
1. Start push sync with 3 operations
2. Operation 1 succeeds → removed from sync_log
3. Operation 2 fails (network error) → marked with error
4. Operation 3 not attempted

Next sync:
- Operation 2 retried (attempts counter incremented)
- Operation 3 processed
✅ Resumable sync
```

---

## 8. Usage Examples

### Creating an Item with Chapters

```dart
final syncService = SyncServiceV2(database);

// 1. Create item (returns LOCAL id)
final localItemId = await syncService.createItem(
  name: 'My Novel',
  type: 'Novel',
  description: 'A great story',
  author: 'John Doe',
  authorId: currentUserId,
);

// 2. Create chapters (use LOCAL item id)
await syncService.createChapter(
  itemId: localItemId,
  number: 1,
  title: 'Chapter 1: The Beginning',
  content: 'Once upon a time...',
);

await syncService.createChapter(
  itemId: localItemId,
  number: 2,
  title: 'Chapter 2: The Middle',
  content: 'And then...',
);

// 3. If offline, changes are queued. If online, they're synced immediately.
```

### Manual Sync

```dart
// Push local changes to server
final pushResult = await syncService.pushSync();
print('Pushed: ${pushResult.syncedCount}, Failed: ${pushResult.failedCount}');

// Pull server changes to local
final pullResult = await syncService.pullItems();
print('Pulled: ${pullResult.syncedCount} items');

// Full bidirectional sync
final fullResult = await syncService.fullSync();
```

### Watching Pending Changes

```dart
// Show badge with pending sync count
syncService.watchPendingSyncCount().listen((count) {
  setState(() => pendingCount = count);
});
```

---

## 9. Summary

| Principle | Implementation |
|-----------|----------------|
| Local ID is permanent | `items.id` never changes after insert |
| Server ID is optional | `items.server_id` is nullable, set only after sync |
| Chapters use local ID | `chapters.item_id` → `items.id` (local) |
| API uses server ID | Always resolve local→server before API call |
| Offline changes queued | `sync_log` table stores pending operations |
| Order matters | Process sync_log oldest-first, track ID mappings |
| Smart deduplication | Merge create+update, remove create+delete |

This minimal design works in ALL scenarios: online, offline, partial sync, interrupted operations, network failures, etc.
