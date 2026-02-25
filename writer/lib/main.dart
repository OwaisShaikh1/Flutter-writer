import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'database/database.dart';
import 'providers/auth_provider.dart';
import 'providers/literature_provider.dart';
import 'providers/sync_provider.dart';
import 'providers/theme_provider.dart';
import 'theme/app_theme.dart';
import 'pages/dashboard.dart';
import 'pages/login_page.dart';
import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize API constants (load saved base URL)
  await ApiConstants.init();

  // Initialize database
  final database = AppDatabase();

  runApp(MyApp(database: database));
}

class MyApp extends StatelessWidget {
  final AppDatabase database;

  const MyApp({super.key, required this.database});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Provide database instance
        Provider<AppDatabase>.value(value: database),
        
        // Auth provider
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        
        // Literature provider (depends on database)
        ChangeNotifierProvider(
          create: (context) => LiteratureProvider(database),
        ),
        
        // Sync provider (depends on database)
        ChangeNotifierProvider(
          create: (context) => SyncProvider(database),
        ),
        
        // Theme provider
        ChangeNotifierProvider(
          create: (context) => ThemeProvider(),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Literature Dashboard',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme(themeProvider.customColor),
            darkTheme: AppTheme.darkTheme(themeProvider.customColor),
            themeMode: themeProvider.themeMode,
            home: Consumer<AuthProvider>(
              builder: (context, authProvider, _) {
            // Show loading while checking auth status
            if (authProvider.status == AuthStatus.initial ||
                authProvider.status == AuthStatus.loading) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            
            // Navigate based on auth status
            if (authProvider.isAuthenticated) {
              return Dashboard();
            } else {
              return const LoginPage();
            }
              },
            ),
          );
        },
      ),
    );
  }
}
