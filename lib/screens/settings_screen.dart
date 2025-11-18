import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cupertino_native/cupertino_native.dart';
import '../providers/settings_provider.dart';
import '../generated/l10n.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(s.settings),
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, child) {
          return ListView(
            children: [
              // Appearance section
              _buildSectionHeader(s.theme),
              _buildThemeSelector(context, settingsProvider, s),
              
              const Divider(),
              
              // Reading section
              _buildSectionHeader(s.readingSection),
              _buildSliderTile(
                context,
                title: s.fontSize,
                value: settingsProvider.fontSize,
                min: 12.0,
                max: 24.0,
                divisions: 12,
                onChanged: (value) => settingsProvider.setFontSize(value),
                suffix: 'px',
              ),
              _buildSliderTile(
                context,
                title: s.brightness,
                value: settingsProvider.brightness,
                min: 0.3,
                max: 1.0,
                divisions: 7,
                onChanged: (value) => settingsProvider.setBrightness(value),
                suffix: '%',
                valueFormatter: (value) => '${(value * 100).round()}%',
              ),
              _buildSwitchTile(
                title: s.keepScreenOn,
                subtitle: s.keepScreenOnDescription,
                value: settingsProvider.keepScreenOn,
                onChanged: (value) => settingsProvider.setKeepScreenOn(value),
              ),
              
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildThemeSelector(BuildContext context, SettingsProvider provider, S s) {
    return ListTile(
      leading: const Icon(Icons.palette_outlined),
      title: Text(s.theme),
      subtitle: Text(_getThemeName(provider.themeMode, s)),
      onTap: () => _showThemeDialog(context, provider, s),
    );
  }

  Widget _buildSliderTile(
    BuildContext context, {
    required String title,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required Function(double) onChanged,
    String? suffix,
    String Function(double)? valueFormatter,
  }) {
    final clampedValue = value.clamp(min, max);
    
    return ListTile(
      title: Text(title),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(valueFormatter?.call(clampedValue) ?? '${clampedValue.toStringAsFixed(1)}${suffix ?? ''}'),
          if (Platform.isIOS)
            CNSlider(
              value: clampedValue,
              min: min,
              max: max,
              onChanged: onChanged,
            )
          else
            Slider(
              value: clampedValue,
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    String? subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return ListTile(
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: Platform.isIOS
          ? CNSwitch(
              value: value,
              onChanged: onChanged,
            )
          : Switch(
              value: value,
              onChanged: onChanged,
            ),
    );
  }

  String _getThemeName(ThemeMode themeMode, S s) {
    switch (themeMode) {
      case ThemeMode.system:
        return s.systemTheme;
      case ThemeMode.light:
        return s.lightTheme;
      case ThemeMode.dark:
        return s.darkTheme;
    }
  }

  void _showThemeDialog(BuildContext context, SettingsProvider provider, S s) {
    // For complex content with ListTile, we'll use a custom dialog
    // AdaptiveAlertDialog is better for simple alerts
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.theme),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ThemeMode.values.map((themeMode) {
            final isSelected = provider.themeMode == themeMode;
            return ListTile(
              title: Text(_getThemeName(themeMode, s)),
              trailing: isSelected ? const Icon(Icons.check, color: Colors.blue) : null,
              onTap: () {
                provider.setThemeMode(themeMode);
                Navigator.of(context).pop();
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(s.cancel),
          ),
        ],
      ),
    );
  }

}