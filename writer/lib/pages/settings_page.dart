import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../utils/constants.dart';
import '../providers/theme_provider.dart';
import '../providers/sync_provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _urlController = TextEditingController();
  bool _isSaving = false;
  bool _isTesting = false;
  bool _isCheckingSync = false;
  String _currentUrl = '';
  String _syncStatusMessage = '';

  @override
  void initState() {
    super.initState();
    _currentUrl = ApiConstants.baseUrl;
    _urlController.text = _currentUrl;
    _initializeSyncDiagnostics();
    _checkSyncStatus();
  }
  
  void _initializeSyncDiagnostics() {
    // Initialize sync status check
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        if (mounted) {
          setState(() {
            _syncStatusMessage = 'Checking sync status...';
          });
          _checkSyncStatus();
        }
      } catch (e) {
        // Fallback initialization
        if (mounted) {
          setState(() {
            _syncStatusMessage = 'Sync status unavailable';
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _saveUrl() async {
    final newUrl = _urlController.text.trim();
    
    if (newUrl.isEmpty) {
      _showMessage('URL cannot be empty', isError: true);
      return;
    }
    
    // Basic URL validation
    if (!newUrl.startsWith('http://') && !newUrl.startsWith('https://')) {
      _showMessage('URL must start with http:// or https://', isError: true);
      return;
    }

    setState(() => _isSaving = true);

    try {
      await ApiConstants.updateBaseUrl(newUrl);
      setState(() => _currentUrl = newUrl);
      _showMessage('Server URL updated successfully');
      
      // Update sync status after URL change
      _checkSyncStatus();
    } catch (e) {
      _showMessage('Failed to save URL: $e', isError: true);
    } finally {
      setState(() => _isSaving = false);
    }
  }

  // Removed _showServerChangeWarning - sync simplified
  
  Future<void> _resetToDefault() async {
    setState(() => _isSaving = true);

    try {
      await ApiConstants.resetBaseUrl();
      setState(() {
        _currentUrl = ApiConstants.defaultBaseUrl;
        _urlController.text = _currentUrl;
      });
      _showMessage('Reset to default URL');
      _checkSyncStatus();
    } catch (e) {
      _showMessage('Failed to reset: $e', isError: true);
    } finally {
      setState(() => _isSaving = false);
    }
  }
  
  Future<void> _checkSyncStatus() async {
    if (!mounted) return;
    
    setState(() => _isCheckingSync = true);
    
    try {
      final syncProvider = Provider.of<SyncProvider>(context, listen: false);
      
      String statusMessage;
      if (syncProvider.isOnline) {
        statusMessage = '✅ Online - Ready to sync';
      } else {
        statusMessage = '📴 Offline';
      }
      
      if (mounted) {
        setState(() => _syncStatusMessage = statusMessage);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _syncStatusMessage = 'Error checking sync status');
      }
    } finally {
      if (mounted) {
        setState(() => _isCheckingSync = false);
      }
    }
  }
  
  // Removed complex sync diagnostic methods - using simplified sync system now

  Future<void> _testConnection() async {
    final testUrl = _urlController.text.trim();
    
    if (testUrl.isEmpty) {
      _showMessage('Enter a URL to test', isError: true);
      return;
    }

    setState(() => _isTesting = true);

    try {
      final response = await http.get(
        Uri.parse('$testUrl/items'),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        _showMessage('Connection successful! (${response.statusCode})');
      } else {
        _showMessage('Server responded with: ${response.statusCode}', isError: true);
      }
    } catch (e) {
      _showMessage('Connection failed: $e', isError: true);
    } finally {
      setState(() => _isTesting = false);
    }
  }

  Future<void> _showColorPicker({
    required Color currentColor,
    required String title,
    required Function(Color) onColorChanged,
  }) async {
    Color pickerColor = currentColor;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select $title'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: pickerColor,
            onColorChanged: (color) => pickerColor = color,
            labelTypes: const [ColorLabelType.rgb, ColorLabelType.hsv],
            enableAlpha: false,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              onColorChanged(pickerColor);
              Navigator.pop(context);
            },
            child: const Text('Select'),
          ),
        ],
      ),
    );
  }

  Future<void> _resetThemeToDefaults() async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    await themeProvider.resetToDefaults();
    _showMessage('Theme reset to default colors');
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        elevation: 0,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Server',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                  letterSpacing: 1.2,
                )),
            const SizedBox(height: 8),
            Card(
              color: colorScheme.surfaceVariant,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.cloud_rounded,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Server Configuration',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    // Current URL display
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: colorScheme.outline.withOpacity(0.08)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.link_rounded, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Current: $_currentUrl',
                              style: textTheme.bodySmall,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    // Sync status display
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _syncStatusMessage.startsWith('⚠️') ? Colors.orange.withOpacity(0.1) : 
                               _syncStatusMessage.startsWith('✅') ? Colors.green.withOpacity(0.1) :
                               colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _syncStatusMessage.startsWith('⚠️') ? Colors.orange.withOpacity(0.3) :
                                 _syncStatusMessage.startsWith('✅') ? Colors.green.withOpacity(0.3) :
                                 colorScheme.outline.withOpacity(0.08)
                        ),
                      ),
                      child: Row(
                        children: [
                          if (_isCheckingSync)
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          else
                            const Icon(Icons.sync_rounded, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _isCheckingSync ? 'Checking sync status...' : (_syncStatusMessage.isEmpty ? 'Sync status unknown' : _syncStatusMessage),
                              style: textTheme.bodySmall?.copyWith(
                                fontWeight: _syncStatusMessage.startsWith('⚠️') ? FontWeight.w600 : null,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: _isCheckingSync ? null : _checkSyncStatus,
                            icon: const Icon(Icons.refresh, size: 16),
                            tooltip: 'Refresh sync status',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    // URL input field
                    TextField(
                      controller: _urlController,
                      decoration: InputDecoration(
                        labelText: 'Server URL',
                        hintText: 'https://your-server.com',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        prefixIcon: const Icon(Icons.dns),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => _urlController.clear(),
                        ),
                      ),
                      keyboardType: TextInputType.url,
                      autocorrect: false,
                    ),
                    const SizedBox(height: 18),
                    // Test connection button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          foregroundColor: colorScheme.primary,
                        ),
                        onPressed: _isTesting ? null : _testConnection,
                        icon: _isTesting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.wifi_find),
                        label: Text(_isTesting ? 'Testing...' : 'Test Connection'),
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: _isSaving ? null : _resetToDefault,
                            icon: const Icon(Icons.restore),
                            label: const Text('Reset Default'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: _isSaving ? null : _saveUrl,
                            icon: _isSaving
                                ? SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: colorScheme.onPrimary,
                                    ),
                                  )
                                : const Icon(Icons.save),
                            label: Text(_isSaving ? 'Saving...' : 'Save'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
            Text('Theme & Layout',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                  letterSpacing: 1.2,
                )),
            const SizedBox(height: 8),
            Card(
              color: colorScheme.surfaceVariant,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.palette_rounded,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Theme Settings',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Consumer<ThemeProvider>(
                      builder: (context, themeProvider, child) {
                        return Column(
                          children: [
                            SwitchListTile(
                              title: const Text('Dark Mode'),
                              subtitle: Text(
                                themeProvider.isDarkMode 
                                  ? 'Dark theme is enabled' 
                                  : 'Light theme is enabled'
                              ),
                              value: themeProvider.isDarkMode,
                              onChanged: (bool value) {
                                themeProvider.toggleTheme();
                              },
                              secondary: Icon(
                                themeProvider.isDarkMode 
                                  ? Icons.dark_mode 
                                  : Icons.light_mode,
                              ),
                            ),
                            const Divider(height: 28),
                            // Layout Customization
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.grid_view_rounded,
                                    color: colorScheme.primary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Layout Style',
                                    style: textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                SegmentedButton<bool>(
                                  segments: const [
                                    ButtonSegment<bool>(
                                      value: true,
                                      icon: Icon(Icons.grid_view),
                                      label: Text('Cards'),
                                    ),
                                    ButtonSegment<bool>(
                                      value: false,
                                      icon: Icon(Icons.view_list),
                                      label: Text('List'),
                                    ),
                                  ],
                                  selected: {themeProvider.isCardLayout},
                                  onSelectionChanged: (Set<bool> newSelection) {
                                    themeProvider.setLayout(newSelection.first);
                                  },
                                  showSelectedIcon: false,
                                ),
                              ],
                            ),
                            const Divider(height: 28),
                            // Color customization title
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.color_lens_rounded,
                                    color: colorScheme.primary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Color Customization',
                                    style: textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ListTile(
                              leading: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: themeProvider.customColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: colorScheme.outline,
                                    width: 1,
                                  ),
                                ),
                              ),
                              title: const Text('Primary Color'),
                              subtitle: const Text('Works in both light and dark modes'),
                              trailing: const Icon(Icons.edit),
                              onTap: () {
                                _showColorPicker(
                                  currentColor: themeProvider.customColor,
                                  title: 'Primary Color',
                                  onColorChanged: themeProvider.setCustomColor,
                                );
                              },
                            ),
                            const SizedBox(height: 18),
                            // Reset button
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: _resetThemeToDefaults,
                                icon: const Icon(Icons.restore),
                                label: const Text('Reset to Default Colors'),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
            Text('Info',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                  letterSpacing: 1.2,
                )),
            const SizedBox(height: 8),
            Card(
              color: colorScheme.surfaceVariant,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Change the server URL if you\'re using a different backend. '
                        'Use your computer\'s IP for local development on physical devices.',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
            Text('Quick Presets',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                  letterSpacing: 1.2,
                )),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ActionChip(
                  backgroundColor: colorScheme.surfaceVariant,
                  avatar: const Icon(Icons.phone_android, size: 16),
                  label: const Text('Emulator'),
                  onPressed: () {
                    _urlController.text = 'http://10.0.2.2:3000';
                  },
                ),
                ActionChip(
                  backgroundColor: colorScheme.surfaceVariant,
                  avatar: const Icon(Icons.computer, size: 16),
                  label: const Text('Localhost'),
                  onPressed: () {
                    _urlController.text = 'http://localhost:3000';
                  },
                ),
                ActionChip(
                  backgroundColor: colorScheme.surfaceVariant,
                  avatar: const Icon(Icons.public, size: 16),
                  label: const Text('Ngrok'),
                  onPressed: () {
                    _urlController.text = ApiConstants.defaultBaseUrl;
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
