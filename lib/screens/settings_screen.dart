import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
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
                context,
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
          AdaptiveSlider(
            value: clampedValue,
            min: min,
            max: max,
            onChanged: onChanged,
            activeColor: Theme.of(context).primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(
    BuildContext context, {
    required String title,
    String? subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return ListTile(
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: AdaptiveSwitch(
        value: value,
        onChanged: onChanged,
        activeColor: Theme.of(context).primaryColor,
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
    AdaptiveAlertDialog.show(
      context: context,
      title: s.theme,
      message: '',
      actions: [
        ...ThemeMode.values.map((themeMode) {
          final isSelected = provider.themeMode == themeMode;
          return AlertAction(
            title: _getThemeName(themeMode, s),
            onPressed: () {
              // Закрыть диалог сначала, чтобы избежать проблем с навигацией
              Navigator.of(context).pop();
              // Затем изменить тему
              provider.setThemeMode(themeMode);
            },
            style: isSelected ? AlertActionStyle.primary : AlertActionStyle.defaultAction,
          );
        }).toList(),
        AlertAction(
          title: s.cancel,
          onPressed: () => Navigator.of(context).pop(),
          style: AlertActionStyle.cancel,
        ),
      ],
    );
  }

}