import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../utils/constants.dart';
import '../providers/theme_provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _urlController = TextEditingController();
  bool _isSaving = false;
  bool _isTesting = false;
  String _currentUrl = '';

  @override
  void initState() {
    super.initState();
    _currentUrl = ApiConstants.baseUrl;
    _urlController.text = _currentUrl;
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
    } catch (e) {
      _showMessage('Failed to save URL: $e', isError: true);
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _resetToDefault() async {
    setState(() => _isSaving = true);

    try {
      await ApiConstants.resetBaseUrl();
      setState(() {
        _currentUrl = ApiConstants.defaultBaseUrl;
        _urlController.text = _currentUrl;
      });
      _showMessage('Reset to default URL');
    } catch (e) {
      _showMessage('Failed to reset: $e', isError: true);
    } finally {
      setState(() => _isSaving = false);
    }
  }

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Server Configuration Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.cloud_rounded,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Server Configuration',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Current URL display
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.link_rounded, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Current: $_currentUrl',
                              style: Theme.of(context).textTheme.bodySmall,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // URL input field
                    TextField(
                      controller: _urlController,
                      decoration: InputDecoration(
                        labelText: 'Server URL',
                        hintText: 'https://your-server.com',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.dns),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => _urlController.clear(),
                        ),
                      ),
                      keyboardType: TextInputType.url,
                      autocorrect: false,
                    ),
                    const SizedBox(height: 16),
                    
                    // Test connection button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
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
                    const SizedBox(height: 12),
                    
                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isSaving ? null : _resetToDefault,
                            icon: const Icon(Icons.restore),
                            label: const Text('Reset Default'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _isSaving ? null : _saveUrl,
                            icon: _isSaving
                                ? SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Theme.of(context).colorScheme.onPrimary,
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
            
            const SizedBox(height: 16),
            
            // Theme Settings Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.palette_rounded,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Theme Settings',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
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
                            
                            const Divider(),
                            
                            // Color customization title
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.color_lens_rounded,
                                    color: Theme.of(context).colorScheme.onSurface,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Color Customization',
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Light mode color picker
                            ListTile(
                              leading: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: themeProvider.customColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Theme.of(context).colorScheme.outline,
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
                            
                            const SizedBox(height: 16),
                            
                            // Reset button
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
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
            
            const SizedBox(height: 16),
            
            // Info card
            Card(
              color: Theme.of(context).colorScheme.surface,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Change the server URL if you\'re using a different backend. '
                        'Use your computer\'s IP for local development on physical devices.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Quick presets section
            Text(
              'Quick Presets',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.phone_android, size: 16),
                  label: const Text('Emulator'),
                  onPressed: () {
                    _urlController.text = 'http://10.0.2.2:3000';
                  },
                ),
                ActionChip(
                  avatar: const Icon(Icons.computer, size: 16),
                  label: const Text('Localhost'),
                  onPressed: () {
                    _urlController.text = 'http://localhost:3000';
                  },
                ),
                ActionChip(
                  avatar: const Icon(Icons.public, size: 16),
                  label: const Text('Ngrok'),
                  onPressed: () {
                    _urlController.text = ApiConstants.defaultBaseUrl;
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
