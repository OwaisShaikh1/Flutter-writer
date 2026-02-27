# Writer - Literature Dashboard Flutter Application

## Table of Contents
1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Project Structure](#project-structure)
4. [Data Models](#data-models)
5. [Database Layer](#database-layer)
6. [State Management](#state-management)
7. [Services Layer](#services-layer)
8. [Screens/Pages](#screenspages)
9. [Widgets](#widgets)
10. [API Integration](#api-integration)
11. [Offline-First Strategy](#offline-first-strategy)
12. [Authentication Flow](#authentication-flow)
13. [Synchronization System](#synchronization-system)
14. [User Scenarios & Flows](#user-scenarios--flows)
15. [Dependencies](#dependencies)
16. [Configuration](#configuration)

---

## Overview

**Writer** is a Flutter-based literature dashboard application that allows users to:
- Browse, read, and manage literary works (novels, poetry, drama, essays, etc.)
- Create and publish their own literature with chapters
- Work offline with local SQLite database storage
- Sync data bidirectionally with a backend server
- Manage favorites and reading progress

The app implements an **offline-first architecture** using Drift (SQLite ORM) for local persistence and a **change log synchronization pattern** for data sync.

---

## Architecture

### High-Level Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           PRESENTATION LAYER                            │
├─────────────────────────────────────────────────────────────────────────┤
│  Pages/Screens                    │  Widgets                            │
│  ├── Dashboard                    │  ├── Header                         │
│  ├── LoginPage                    │  ├── SearchBar                      │
│  ├── RegisterPage                 │  ├── FilterSection                  │
│  ├── ProfilePage                  │  ├── LiteratureList                 │
│  ├── IntroductionPage             │  ├── OfflineIndicator               │
│  ├── ChapterReaderPage            │  ├── ProfileHeader/Stats/About      │
│  ├── CreateLiteraturePage         │  └── ProfileLibrary                 │
│  ├── EditLiteraturePage           │                                     │
│  ├── MyWorksPage                  │                                     │
│  └── SettingsPage                 │                                     │
├─────────────────────────────────────────────────────────────────────────┤
│                          STATE MANAGEMENT LAYER                         │
├─────────────────────────────────────────────────────────────────────────┤
│  Providers (ChangeNotifier)                                             │
│  ├── AuthProvider         → Handles authentication state                │
│  ├── LiteratureProvider   → Manages literature items & chapters         │
│  └── SyncProvider         → Manages sync status & connectivity          │
├─────────────────────────────────────────────────────────────────────────┤
│                             SERVICES LAYER                              │
├─────────────────────────────────────────────────────────────────────────┤
│  ├── ApiService           → HTTP client for backend communication       │
│  ├── AuthService          → Authentication operations                   │
│  ├── StorageService       → Secure storage for tokens/credentials       │
│  └── SyncService          → Bidirectional synchronization logic         │
├─────────────────────────────────────────────────────────────────────────┤
│                              DATA LAYER                                 │
├─────────────────────────────────────────────────────────────────────────┤
│  Database (Drift/SQLite)          │  Models                             │
│  ├── AppDatabase                  │  ├── LiteratureItem                 │
│  ├── Tables:                      │  ├── Chapter                        │
│  │   ├── Items                    │  └── UserProfile                    │
│  │   ├── Chapters                 │                                     │
│  │   ├── Users                    │                                     │
│  │   ├── UserActivity             │                                     │
│  │   └── SyncLog                  │                                     │
│  └── DAOs:                        │                                     │
│      ├── ItemsDao                 │                                     │
│      ├── ChaptersDao              │                                     │
│      ├── UserDao                  │                                     │
│      ├── UserActivityDao          │                                     │
│      └── SyncLogDao               │                                     │
└─────────────────────────────────────────────────────────────────────────┘
```

### Architecture Patterns
- **MVVM-like Pattern**: Providers act as ViewModels
- **Repository Pattern**: DAOs abstract database operations
- **Service Layer Pattern**: Services handle business logic
- **Offline-First**: Local database as source of truth
- **Change Log Pattern**: Track local changes for sync

---

## Project Structure

```
lib/
├── main.dart                    # App entry point, provider setup
├── database/
│   ├── database.dart            # Drift database definition
│   ├── database.g.dart          # Generated database code
│   ├── dao/
│   │   ├── items_dao.dart       # Data access for items
│   │   ├── chapters_dao.dart    # Data access for chapters
│   │   ├── user_dao.dart        # Data access for users
│   │   ├── user_activity_dao.dart
│   │   └── sync_log_dao.dart    # Sync operations logging
│   └── tables/
│       ├── items_table.dart     # Items table schema
│       ├── chapters_table.dart  # Chapters table schema
│       ├── users_table.dart     # Users table schema
│       ├── user_activity_table.dart
│       └── sync_log_table.dart  # Sync log schema
├── models/
│   ├── literature_item.dart     # Literature item model
│   ├── chapter.dart             # Chapter model
│   └── user_profile.dart        # User profile model
├── pages/
│   ├── dashboard.dart           # Main dashboard screen
│   ├── login_page.dart          # Login screen
│   ├── register_page.dart       # Registration screen
│   ├── profile_page.dart        # User profile screen
│   ├── introduction_page.dart   # Literature detail/intro
│   ├── chapter_reader_page.dart # Chapter reading interface
│   ├── create_literature_page.dart
│   ├── edit_literature_page.dart
│   ├── my_works_page.dart       # User's created works
│   └── settings_page.dart       # App settings
├── providers/
│   ├── auth_provider.dart       # Authentication state
│   ├── literature_provider.dart # Literature management
│   └── sync_provider.dart       # Sync status management
├── services/
│   ├── api_service.dart         # REST API client
│   ├── auth_service.dart        # Auth operations
│   ├── storage_service.dart     # Secure storage
│   └── sync_service.dart        # Synchronization logic
├── utils/
│   ├── constants.dart           # API constants, app settings
│   └── network_utils.dart       # Connectivity utilities
└── widgets/
    ├── header.dart              # Dashboard header
    ├── search_bar.dart          # Search input
    ├── filter_section.dart      # Type filter chips
    ├── literature_list.dart     # Literature card list
    ├── offline_indicator.dart   # Offline status banner
    ├── profile_header.dart      # Profile header widget
    ├── profile_stats.dart       # User statistics
    └── profile_about.dart       # User bio/details
```

---

## Data Models

### LiteratureItem

Represents a piece of literature (novel, poem, drama, etc.)

```dart
class LiteratureItem {
  final int id;
  final String title;
  final String author;
  final int? authorId;          // User ID who created this
  final String type;            // Novel, Poetry, Drama, etc.
  final double rating;
  final int chapters;           // Chapter count
  final int comments;
  final String? imageUrl;       // Remote image URL
  final String? imageLocalPath; // Local cached image path
  final String description;
  final bool isFavorite;
  final bool isSynced;          // Sync status
}
```

**JSON Serialization:** Supports multiple field name variants for backend compatibility:
- `id` / `item_id`
- `title` / `name`
- `rating` / `review`
- `chapters` / `chaptersCount` / `Number_of_chapters`

### Chapter

Represents a chapter within a literature item.

```dart
class Chapter {
  final int id;
  final int itemId;             // Parent literature ID
  final int number;             // Chapter number (1-based)
  final String title;
  final String content;         // Full chapter text
  final bool isDownloaded;      // Offline availability
  final DateTime? downloadedAt;
  final DateTime? createdAt;
}
```

### UserProfile

User account information.

```dart
class UserProfile {
  final int id;
  final String name;
  final String username;
  final String email;
  final String? bio;
  final int followers;
  final int following;
  final int posts;              // Published works count
  final DateTime? createdAt;
}
```

---

## Database Layer

### Drift ORM Setup

The app uses **Drift** (formerly Moor) for type-safe SQLite operations.

**Database File:** `writer_app.db` stored in app documents directory

**Schema Version:** 4 (with migration support)

### Tables

#### Items Table
```dart
@DataClassName('ItemEntity')
class Items extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get author => text()();
  IntColumn get authorId => integer().nullable()();
  TextColumn get type => text()();
  RealColumn get rating => real().withDefault(const Constant(0.0))();
  IntColumn get chaptersCount => integer().withDefault(const Constant(0))();
  IntColumn get commentsCount => integer().withDefault(const Constant(0))();
  TextColumn get imageUrl => text().nullable()();
  TextColumn get imageLocalPath => text().nullable()();
  TextColumn get description => text()();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
```

#### Chapters Table
```dart
@DataClassName('ChapterEntity')
class Chapters extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get itemId => integer().references(Items, #id, onDelete: KeyAction.cascade)();
  IntColumn get number => integer()();
  TextColumn get title => text()();
  TextColumn get content => text()();
  BoolColumn get isDownloaded => boolean().withDefault(const Constant(false))();
  DateTimeColumn get downloadedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  
  // Unique constraint: one chapter per number per item
  @override
  List<Set<Column>> get uniqueKeys => [{itemId, number}];
}
```

#### Users Table
```dart
@DataClassName('UserEntity')
class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get username => text().unique()();
  TextColumn get email => text()();
  TextColumn get bio => text().nullable()();
  IntColumn get followers => integer().withDefault(const Constant(0))();
  IntColumn get following => integer().withDefault(const Constant(0))();
  IntColumn get posts => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
```

#### SyncLog Table
Tracks local changes for synchronization.

```dart
@DataClassName('SyncLogEntry')
class SyncLog extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get entityType => text()();    // 'item' or 'chapter'
  IntColumn get entityId => integer()();    // Local entity ID
  IntColumn get parentId => integer().nullable()(); // Parent item ID for chapters
  TextColumn get operation => text()();     // 'create', 'update', 'delete'
  TextColumn get payload => text()();       // JSON data to sync
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
}
```

#### UserActivity Table
Tracks reading progress.

```dart
@DataClassName('UserActivityEntity')
class UserActivity extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get itemId => integer().references(Items, #id, onDelete: KeyAction.cascade)();
  IntColumn get lastChapterRead => integer().withDefault(const Constant(0))();
  IntColumn get currentPage => integer().withDefault(const Constant(0))();
  RealColumn get progressPercent => real().withDefault(const Constant(0.0))();
  DateTimeColumn get lastReadAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get notes => text().nullable()();
}
```

### Database Migrations

```dart
@override
MigrationStrategy get migration {
  return MigrationStrategy(
    onCreate: (Migrator m) async => await m.createAll(),
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 2) await m.addColumn(items, items.authorId);
      if (from < 3) {
        // Clean up duplicate chapters
        await customStatement('''
          DELETE FROM chapters WHERE id NOT IN (
            SELECT MIN(id) FROM chapters GROUP BY item_id, number
          )
        ''');
      }
      if (from < 4) await m.createTable(syncLog);
    },
  );
}
```

### Data Access Objects (DAOs)

#### ItemsDao
- `getAllItems()` / `watchAllItems()` - List all items (stream for reactive)
- `getItemById(int id)` - Get single item
- `searchItems(String query)` - Search by name/author
- `getItemsByType(String type)` - Filter by type
- `getFavorites()` - Get favorited items
- `watchItemsByAuthorId(int authorId)` - User's own works
- `upsertItem(ItemsCompanion item)` - Insert/update
- `toggleFavorite(int id, bool isFav)` - Toggle favorite status
- `markAsSynced(int id)` - Mark as synchronized
- `deleteItem(int id)` - Delete item
- `changeItemId(int oldId, int newId, ItemEntity item)` - Remap ID after sync

#### ChaptersDao
- `watchChaptersByItemId(int itemId)` - Stream chapters
- `getChaptersByItemId(int itemId)` - List chapters
- `getChapter(int itemId, int chapterNumber)` - Specific chapter
- `upsertChapter(ChaptersCompanion chapter)` - Insert/update
- `insertChapters(List<ChaptersCompanion> chapters)` - Batch insert
- `markAsDownloaded(int itemId, int chapterNumber)` - Mark available offline
- `getDownloadedChaptersCount(int itemId)` - Count downloaded
- `deleteChaptersByItemId(int itemId)` - Delete all chapters for item
- `updateChaptersItemId(int oldItemId, int newItemId)` - Remap parent ID

#### SyncLogDao
- `logItemCreate()` / `logItemUpdate()` / `logItemDelete()` - Log item operations
- `logChapterCreate()` / `logChapterUpdate()` / `logChapterDelete()` - Log chapter ops
- `getPendingOperations()` - Get operations to sync
- `getPendingCount()` / `watchPendingCount()` - Count pending operations
- `markAttempted(int id, String? error)` - Track sync attempts
- `removeOperation(int id)` - Clear completed operation

---

## State Management

### Provider Pattern

The app uses the **Provider** package with `ChangeNotifier` for state management.

### AuthProvider

Manages authentication state and user session.

```dart
enum AuthStatus { initial, authenticated, unauthenticated, loading }

class AuthProvider with ChangeNotifier {
  AuthStatus _status = AuthStatus.initial;
  UserProfile? _currentUser;
  String? _errorMessage;
  
  // Key methods:
  Future<void> _checkAuthStatus();           // Verify stored credentials
  Future<void> _verifyTokenInBackground();   // Non-blocking token check
  Future<bool> login(String username, String password);
  Future<bool> register({name, username, password, email});
  Future<void> logout();
}
```

**Features:**
- Auto-restore session from secure storage
- Background token verification (non-blocking)
- Graceful offline handling - stays logged in if credentials valid locally

### LiteratureProvider

Central provider for literature item management.

```dart
class LiteratureProvider with ChangeNotifier {
  List<LiteratureItem> _items = [];
  List<LiteratureItem> _myWorks = [];
  bool _isLoading = false;
  bool _isSyncing = false;
  String _searchQuery = '';
  String _selectedFilter = 'All';
  DateTime? _lastSyncTime;
  int? _currentUserId;
  
  // Key methods:
  void setSearchQuery(String query);
  void setFilter(String filter);
  Future<SyncResult> syncWithBackend();
  Future<void> toggleFavorite(int id);
  Future<void> deleteItem(int id);
  Future<int> createLiterature({title, author, type, description, chapters});
  Future<void> updateLiterature({id, title, ...});
  Future<List<Chapter>> getChaptersForItem(int itemId);
  Future<void> refreshMyWorks();
  Future<int> claimOrphanItems();  // Migrate old items to current user
}
```

**Features:**
- Reactive database watching via Drift streams
- Local filtering (search + type) without re-fetching
- Bidirectional sync with change logging
- Ownership tracking via `authorId`

### SyncProvider

Manages network status and synchronization operations.

```dart
enum SyncStatus { idle, syncing, success, error }

class SyncProvider with ChangeNotifier {
  SyncStatus _status = SyncStatus.idle;
  bool _isOnline = true;
  int _pendingSyncCount = 0;
  
  // Key methods:
  Future<SyncResult> syncAll();           // Full bidirectional sync
  Future<SyncResult> pushChanges();       // Push local only
  Future<SyncResult> pullChanges();       // Pull remote only
  Future<SyncResult> downloadChapters(int itemId);
  Future<bool> downloadChapter(int itemId, int chapterNumber);
}
```

**Features:**
- Connectivity monitoring via `connectivity_plus`
- Pending changes counter (reactive)
- Manual sync control (not automatic)

---

## Services Layer

### ApiService

HTTP client for all backend communication.

```dart
class ApiService {
  Future<Map<String, String>> _getHeaders();  // Include JWT token
  
  // Fetch operations:
  Future<List<LiteratureItem>> fetchItems();
  Future<LiteratureItem?> fetchItem(int id);
  Future<List<Chapter>> fetchChapters(int itemId);
  Future<Chapter?> fetchChapter(int bookId, int chapterNumber);
  Future<UserProfile?> fetchUserProfile(int userId);
  
  // Create operations:
  Future<int?> createItem({name, type, description, review, imageUrl});
  Future<bool> createChapters(int itemId, List<Map> chapters);
  
  // Update operations:
  Future<bool> updateItem({itemId, name, type, description, ...});
  Future<bool> updateChapters(int itemId, List<Map> chapters);
  Future<bool> updateChapter(int itemId, int chapterNumber, Map data);
  
  // Delete operations:
  Future<bool> deleteItem(int itemId);
  Future<bool> deleteChapter(int itemId, int chapterNumber);
  
  // Utilities:
  Future<String?> downloadImage(String imageUrl, String fileName);
  Future<bool> submitRating(int itemId, double rating);
  Future<bool> addComment(int itemId, String comment);
}
```

### AuthService

Authentication operations.

```dart
class AuthService {
  Future<Map<String, dynamic>> login(String username, String password);
  Future<Map<String, dynamic>> register({name, username, password, email});
  Future<bool> verifyToken();
  Future<Map<String, dynamic>> verifyTokenWithResponse();  // Detailed response
  Future<void> logout();
  Future<String?> getToken();
  Future<bool> isLoggedIn();
  Future<int?> getCurrentUserId();
}
```

### StorageService

Secure credential and settings storage using `flutter_secure_storage`.

```dart
class StorageService {
  // Token management
  Future<void> saveToken(String token);
  Future<String?> getToken();
  
  // User info
  Future<void> saveUserId(int userId);
  Future<int?> getUserId();
  Future<void> saveUsername(String username);
  Future<void> saveName(String name);
  
  // Server URL configuration
  Future<void> saveBaseUrl(String url);
  Future<String> getBaseUrl();
  
  // Pending operations
  Future<void> addPendingDelete(int itemId);
  Future<List<int>> getPendingDeletes();
  
  Future<void> clearAll();  // Logout
}
```

### SyncService

Core synchronization logic implementing the **Change Log Pattern**.

```dart
class SyncService {
  // Connectivity
  Future<bool> isOnline();
  
  // Change Logging
  Future<void> logItemCreate(int localId, {...});
  Future<void> logItemUpdate(int itemId, Map changes);
  Future<void> logItemDelete(int itemId);
  Future<void> logChapterCreate(int chapterId, int itemId, {...});
  Future<void> logChapterUpdate(int chapterId, int itemId, Map changes);
  Future<void> logChapterDelete(int chapterId, int itemId);
  
  // Sync Operations
  Future<int> getPendingSyncCount();
  Stream<int> watchPendingSyncCount();
  Future<SyncResult> processSyncLog();  // Push local changes
  Future<SyncResult> pullItems();        // Pull remote items
  Future<SyncResult> pullChapters(int itemId);
  Future<SyncResult> fullSync();         // Push then pull
  
  // Legacy compatibility
  Future<bool> downloadChapter(int itemId, int chapterNumber);
  Future<bool> syncUserProfile(int userId);
  Future<void> clearAllData();
}
```

**Sync Flow:**
1. User creates/edits item locally → Logged in SyncLog table
2. User clicks "Sync" button → `processSyncLog()` sends changes to backend
3. Backend returns success → Remove from SyncLog, update local IDs if new
4. After push → `pullItems()` fetches latest from server
5. Merge remote data into local database

---

## Screens/Pages

### Dashboard (`dashboard.dart`)

**Purpose:** Main screen showing literature catalog

**Features:**
- Offline indicator banner at top
- Search bar for filtering
- Filter chips (All, Poems, Drama, Novel)
- Sync button with status
- Item count display
- Literature list (pull-to-refresh)
- FAB for creating new literature

**User Actions:**
- Search/filter literature
- Tap item → Navigate to IntroductionPage
- Pull to refresh → Trigger sync
- Tap Sync button → Manual synchronization
- Navigate to Profile, My Works, Settings

### LoginPage (`login_page.dart`)

**Purpose:** User authentication

**Features:**
- Username/password fields with validation
- Login button with loading state
- "Continue without login" for offline browsing
- Register link
- Settings access for server configuration

### RegisterPage (`register_page.dart`)

**Purpose:** New user registration

**Features:**
- Full name, username, email, password fields
- Password confirmation
- Auto-login after successful registration

### ProfilePage (`profile_page.dart`)

**Purpose:** Display user profile and statistics

**Features:**
- Profile header (name, username, avatar)
- Statistics (followers, following, books read, favorites)
- About section (bio, join date, contact)
- Library section (favorite books with progress)
- Login prompt for unauthenticated users

### IntroductionPage (`introduction_page.dart`)

**Purpose:** Literature detail view

**Features:**
- Cover image display
- Title, author, type badge
- Rating display (stars)
- Stats cards (chapters count, comments)
- Description text
- "Start Reading" button → ChapterReaderPage
- Favorite toggle button
- "Download for offline" button

### ChapterReaderPage (`chapter_reader_page.dart`)

**Purpose:** Reading interface for chapters

**Features:**
- Chapter content display
- Chapter navigation (Previous/Next buttons)
- Chapter selector popup menu
- Download all chapters button
- Offline availability indicator
- Auto-download if online and chapter missing

### CreateLiteraturePage (`create_literature_page.dart`)

**Purpose:** Create new literature works

**Features:**
- Title input field
- Type selector dropdown (Novel, Poetry, Drama, Short Story, Essay, Biography)
- Description textarea
- Chapter management:
  - Add chapter dialog (title + content)
  - Edit existing chapters
  - Delete chapters
  - Drag-to-reorder chapters
- Save button → Creates locally with sync log entry

### EditLiteraturePage (`edit_literature_page.dart`)

**Purpose:** Edit existing literature

**Features:**
- All CreateLiteraturePage features
- Load existing item data
- Load existing chapters
- Unsaved changes warning on exit
- Change tracking for sync

### MyWorksPage (`my_works_page.dart`)

**Purpose:** View/manage user's created literature

**Features:**
- List of user's works with sync status
- Edit button per item
- Delete button per item (with confirmation)
- Create new work FAB
- "Claim Existing Items" button for orphan migration
- Empty state with call-to-action

### SettingsPage (`settings_page.dart`)

**Purpose:** App configuration

**Features:**
- Server URL configuration
- Current URL display
- URL input field
- Test Connection button
- Save button
- Reset to Default button
- Quick presets (Emulator, Localhost, Ngrok)

---

## Widgets

### Header (`header.dart`)
Dashboard header with title, settings, and profile buttons.

### LiteratureSearchBar (`search_bar.dart`)
Text input field with search icon for filtering.

### FilterSection (`filter_section.dart`)
Horizontal list of `ChoiceChip` widgets for type filtering.

### LiteratureList (`literature_list.dart`)
ListView of literature cards with:
- Cover image (cached network image or local)
- Title, author
- Type badge (color-coded)
- Rating stars
- Chapter count
- Favorite indicator
- Sync status indicator

### OfflineIndicator (`offline_indicator.dart`)
Orange banner showing offline status with retry button.

### ProfileHeader, ProfileStats, ProfileAbout, ProfileLibrary
Modular profile page components.

---

## API Integration

### Base URL Configuration

```dart
class ApiConstants {
  static const String defaultBaseUrl = 'https://pokily-unawaked-amado.ngrok-free.app';
  static String _baseUrl = defaultBaseUrl;
  
  static Future<void> init();           // Load from storage
  static Future<void> updateBaseUrl(String url);  // Save to storage
  static Future<void> resetBaseUrl();   // Reset to default
}
```

### Endpoints Used

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| POST | `/login` | No | User login |
| POST | `/register` | No | User registration |
| POST | `/verify-token` | Yes | Token validation |
| GET | `/items` | No | List all items |
| GET | `/items/:id` | No | Get single item |
| POST | `/items` | Yes | Create new item |
| PUT | `/items/:id` | Yes | Update item |
| DELETE | `/items/:id` | Yes | Delete item |
| GET | `/chapters?bookId=X` | No | Get chapters for item |
| GET | `/chapters?bookId=X&chapterNumber=Y` | No | Get specific chapter |
| POST | `/chapters` | Yes | Create chapters |
| PUT | `/chapters/:itemId` | Yes | Update all chapters |
| DELETE | `/chapters/:itemId/:number` | Yes | Delete chapter |
| GET | `/users/:id` | Yes | Get user profile |
| GET | `/my-items` | Yes | Get user's items |

### Request Headers

```dart
{
  'Content-Type': 'application/json',
  'Authorization': 'Bearer <jwt_token>'  // When authenticated
}
```

---

## Offline-First Strategy

### Design Principles

1. **Local Database as Truth**: All UI reads from local SQLite
2. **Optimistic UI**: Changes appear immediately, sync later
3. **Change Logging**: Operations logged for later sync
4. **Graceful Degradation**: App works fully offline

### Data Flow

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│     UI       │────▶│   Provider   │────▶│   Database   │
│   (Pages)    │◀────│ (ChangeNotif)│◀────│   (Drift)    │
└──────────────┘     └──────────────┘     └──────────────┘
                            │
                            │ User clicks Sync
                            ▼
                     ┌──────────────┐     ┌──────────────┐
                     │ SyncService  │────▶│  ApiService  │
                     │              │◀────│              │
                     └──────────────┘     └──────────────┘
                                                 │
                                                 ▼
                                          ┌──────────────┐
                                          │   Backend    │
                                          │   Server     │
                                          └──────────────┘
```

### Reactive Updates

Using Drift streams for automatic UI updates:

```dart
// In LiteratureProvider
_itemsDao.watchAllItems().listen((entities) {
  _items = entities.map((e) => LiteratureItem.fromEntity(e)).toList();
  notifyListeners();  // UI automatically updates
});
```

### Offline Scenarios

| Scenario | Behavior |
|----------|----------|
| App opens offline | Loads cached items from database |
| Create item offline | Saves locally, logs CREATE operation |
| Edit item offline | Saves locally, logs UPDATE operation |
| Delete item offline | Removes locally, logs DELETE operation |
| Go online + Sync | Process sync log, then pull updates |
| Read chapters offline | Shows downloaded chapters only |

---

## Authentication Flow

### Login Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                          LOGIN FLOW                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────┐    ┌──────────────┐    ┌──────────────┐           │
│  │  Login   │───▶│ AuthService  │───▶│   Backend    │           │
│  │   Page   │    │   .login()   │    │  /login      │           │
│  └──────────┘    └──────────────┘    └──────────────┘           │
│       │                                      │                  │
│       │                                      ▼                  │
│       │         ┌──────────────────────────────────┐            │
│       │         │ Success Response:                │            │
│       │         │ { token, user: {id, name, ...} } │            │
│       │         └──────────────────────────────────┘            │
│       │                         │                               │
│       │                         ▼                               │
│       │         ┌──────────────────────────────────┐            │
│       │         │ StorageService saves:            │            │
│       │         │ - JWT token                      │            │
│       │         │ - User ID                        │            │
│       │         │ - Username                       │            │
│       │         │ - Display name                   │            │
│       │         └──────────────────────────────────┘            │
│       │                         │                               │
│       ▼                         ▼                               │
│  ┌──────────┐    ┌──────────────┐                               │
│  │Dashboard │◀───│ AuthProvider │                               │
│  │          │    │ status=auth  │                               │
│  └──────────┘    └──────────────┘                               │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Session Restoration

```
┌─────────────────────────────────────────────────────────────────┐
│                    APP STARTUP FLOW                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  App Launch                                                     │
│       │                                                         │
│       ▼                                                         │
│  ┌──────────────────────────────────────┐                       │
│  │ AuthProvider._checkAuthStatus()      │                       │
│  │                                      │                       │
│  │  1. Check StorageService.isLoggedIn()│                       │
│  │  2. If yes, load user info locally   │                       │
│  │  3. Set status = authenticated       │                       │
│  │  4. Start background token verify    │                       │
│  └──────────────────────────────────────┘                       │
│            │                                                    │
│            ├─── Has credentials ───▶ Dashboard                  │
│            │                                                    │
│            └─── No credentials ────▶ LoginPage                  │
│                                                                 │
│  Background: verifyTokenWithResponse()                          │
│       │                                                         │
│       ├─── Token valid ───────▶ Continue normally               │
│       │                                                         │
│       ├─── Token invalid (403) ▶ Logout                         │
│       │                                                         │
│       └─── Network error ─────▶ Stay logged in (offline mode)   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Authentication States

| State | Meaning | UI Shown |
|-------|---------|----------|
| `initial` | Checking status | Loading spinner |
| `loading` | Login/register in progress | Loading spinner |
| `authenticated` | User logged in | Dashboard |
| `unauthenticated` | No valid session | LoginPage |

---

## Synchronization System

### Change Log Pattern

Instead of marking items as "dirty", all operations are logged:

```
┌─────────────────────────────────────────────────────────────────┐
│                    CHANGE LOG SYNC                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  User Action         SyncLog Entry                              │
│  ────────────        ─────────────                              │
│                                                                 │
│  Create Item    →    { entityType: 'item',                      │
│                        entityId: <localId>,                     │
│                        operation: 'create',                     │
│                        payload: {name, type, ...} }             │
│                                                                 │
│  Update Item    →    { entityType: 'item',                      │
│                        entityId: <itemId>,                      │
│                        operation: 'update',                     │
│                        payload: {<changed fields>} }            │
│                                                                 │
│  Delete Item    →    { entityType: 'item',                      │
│                        entityId: <itemId>,                      │
│                        operation: 'delete',                     │
│                        payload: {} }                            │
│                                                                 │
│  Add Chapter    →    { entityType: 'chapter',                   │
│                        entityId: <chapterId>,                   │
│                        parentId: <itemId>,                      │
│                        operation: 'create',                     │
│                        payload: {number, title, content} }      │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Full Sync Process

```
┌─────────────────────────────────────────────────────────────────┐
│                    SYNC PROCESS                                 │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  User clicks "Sync"                                             │
│       │                                                         │
│       ▼                                                         │
│  ┌──────────────────────────────────────┐                       │
│  │ 1. PUSH: processSyncLog()            │                       │
│  │    - Get pending operations          │                       │
│  │    - For each CREATE item:           │                       │
│  │      • POST /items                   │                       │
│  │      • Get backend ID                │                       │
│  │      • Remap local ID → backend ID   │                       │
│  │      • Update chapters item_id       │                       │
│  │    - For each UPDATE: PUT /items/:id │                       │
│  │    - For each DELETE: DELETE /items  │                       │
│  │    - Process chapter operations      │                       │
│  │    - Remove completed from SyncLog   │                       │
│  └──────────────────────────────────────┘                       │
│       │                                                         │
│       ▼                                                         │
│  ┌──────────────────────────────────────┐                       │
│  │ 2. PULL: pullItems()                 │                       │
│  │    - GET /items                      │                       │
│  │    - Upsert all items to database    │                       │
│  │    - Mark as synced                  │                       │
│  └──────────────────────────────────────┘                       │
│       │                                                         │
│       ▼                                                         │
│  ┌──────────────────────────────────────┐                       │
│  │ 3. PULL CHAPTERS (optional)          │                       │
│  │    - For each item: GET /chapters    │                       │
│  │    - Upsert chapters                 │                       │
│  │    - Mark as downloaded              │                       │
│  └──────────────────────────────────────┘                       │
│       │                                                         │
│       ▼                                                         │
│  Return SyncResult { success, message, itemCount }              │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### ID Remapping

When a locally-created item is synced:

```dart
// Local item has auto-increment ID (e.g., 1001)
// Backend assigns official ID (e.g., 42)

Future<void> _processItemOperation(...) async {
  switch (op.operation) {
    case 'create':
      final remoteId = await _api.createItem(...);
      
      // Store mapping for chapter operations
      itemIdMapping[op.entityId] = remoteId;
      
      // Create new record with backend ID
      await _itemsDao.changeItemId(op.entityId, remoteId, item);
      
      // Update chapters to reference new ID
      await _chaptersDao.updateChaptersItemId(op.entityId, remoteId);
      
      // Delete old local record
      await _itemsDao.deleteItem(op.entityId);
      break;
  }
}
```

---

## User Scenarios & Flows

### Scenario 1: First-Time User

1. **Open App** → LoginPage shown
2. **Tap "Register"** → RegisterPage
3. **Fill form & submit** → Account created, auto-login
4. **Dashboard shown** → Empty list
5. **Tap Sync** → Pull items from server
6. **Browse & read** → Tap item → IntroductionPage → ChapterReaderPage

### Scenario 2: Offline Browsing

1. **Open App offline** → Dashboard loads cached items
2. **Orange banner** → "You are offline"
3. **Browse items** → All cached items available
4. **Read chapters** → Only downloaded chapters shown
5. **Go online** → Banner disappears
6. **Sync** → Updates pulled

### Scenario 3: Create Literature Offline

1. **Tap "Write" FAB** → CreateLiteraturePage
2. **Enter title, type, description**
3. **Add chapters** via dialog
4. **Save** → Item saved locally, SyncLog entry created
5. **MyWorksPage** → Shows item with "Local" badge
6. **Go online + Sync** → Item pushed to server
7. **MyWorksPage** → Shows item with "Synced" badge

### Scenario 4: Edit Own Work

1. **Navigate to MyWorksPage**
2. **Tap item** → EditLiteraturePage
3. **Modify title, add/edit/delete chapters**
4. **Save** → Local update, SyncLog entry
5. **Sync** → Changes pushed to server

### Scenario 5: Delete Work

1. **MyWorksPage** → Tap delete icon
2. **Confirmation dialog** → Confirm
3. **Item deleted locally** → SyncLog DELETE entry
4. **Sync** → DELETE sent to server

### Scenario 6: Download for Offline Reading

1. **IntroductionPage** → Tap "Download for offline"
2. **All chapters downloaded** → Stored in local DB
3. **Go offline** → Can still read all chapters
4. **ChapterReaderPage** → Shows "Available offline" indicator

### Scenario 7: Change Server URL

1. **SettingsPage** → Enter new URL
2. **Test Connection** → Validates endpoint
3. **Save** → URL persisted
4. **Sync** → Uses new server

### Scenario 8: Session Expiration

1. **Token expires while using app**
2. **Background verify** → Detects 403
3. **Auto-logout** → Redirected to LoginPage
4. **Re-login** → New token obtained

---

## Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # HTTP Client
  http: ^0.13.6
  
  # SQLite Database via Drift
  drift: ^2.14.0
  sqlite3_flutter_libs: ^0.5.0
  path_provider: ^2.1.0
  path: ^1.8.3
  
  # State Management
  provider: ^6.1.0
  
  # Image Caching
  cached_network_image: ^3.3.0
  
  # Secure Storage for JWT tokens
  flutter_secure_storage: ^9.0.0
  
  # Network connectivity check
  connectivity_plus: ^5.0.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
  
  # Code generation for Drift
  drift_dev: ^2.14.0
  build_runner: ^2.4.0
```

### Key Dependency Purposes

| Package | Purpose |
|---------|---------|
| `drift` | Type-safe SQLite ORM |
| `provider` | State management |
| `flutter_secure_storage` | Encrypted credential storage |
| `connectivity_plus` | Network status monitoring |
| `cached_network_image` | Image caching with offline support |
| `http` | HTTP client for API calls |
| `path_provider` | Access app document directory |

---

## Configuration

### Build Commands

```bash
# Generate Drift database code
dart run build_runner build --delete-conflicting-outputs

# Run app
flutter run

# Build release APK
flutter build apk --release
```

### Environment-Specific URLs

| Environment | URL |
|-------------|-----|
| Emulator | `http://10.0.2.2:3000` |
| Localhost | `http://localhost:3000` |
| Physical Device | Computer's IP (e.g., `http://192.168.1.x:3000`) |
| Production | Ngrok or deployed server URL |

### App Constants

```dart
class AppConstants {
  static const String appName = 'Literature Dashboard';
  static const String dbName = 'writer_app.db';
  static const List<String> filterOptions = ['All', 'Drama', 'Poems', 'Novel', 'Article'];
  static const Duration autoSyncInterval = Duration(hours: 6);
}
```

---

## Error Handling

### Network Errors
- Timeout: 10s for connections, 15s for responses
- Graceful degradation to offline mode
- User-friendly error messages via SnackBar

### Database Errors
- Migration failures logged
- Constraint violations handled
- Transaction rollback on failure

### Authentication Errors
- Token expiration detection
- Auto-logout on invalid token
- Network errors don't force logout

---

## Security Considerations

1. **JWT Tokens**: Stored in `flutter_secure_storage` (encrypted)
2. **Password Hashing**: Done server-side with bcrypt
3. **HTTPS**: Recommended for production
4. **API Authorization**: Token-based for protected endpoints
5. **Ownership Validation**: Users can only edit/delete own items

---

## Future Enhancements

- [ ] Push notifications for new content
- [ ] Automatic background sync
- [ ] Reading progress sync across devices
- [ ] Comments system
- [ ] Social features (follow authors)
- [ ] Dark mode support
- [ ] Export/Import user data
- [ ] Multi-language support

---

*Documentation generated for Writer v1.0.0*
