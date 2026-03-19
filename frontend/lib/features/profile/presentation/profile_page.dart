import 'dart:async';
import 'package:flutter/material.dart';

import '../../../app/app_controller.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, required this.controller});

  final VoiceIqAppController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final session = controller.session;
    final subscription = controller.subscription;
    final completedSessions = controller.completedSessionsCount;

    void showAction(String message) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }

    Future<void> openEditProfile() async {
      final nameController = TextEditingController(
        text: session?.fullName ?? 'VoiceIQ Developer',
      );
      final trackController = TextEditingController(
        text: session?.targetRole ?? 'Software Engineer',
      );

      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Edit profile'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Full name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: trackController,
                  decoration: const InputDecoration(labelText: 'Target track'),
                ),
                const SizedBox(height: 12),
                Text(
                  'Email: ${session?.email ?? '-'}',
                  style: Theme.of(dialogContext).textTheme.bodySmall,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  await controller.updateLocalProfile(
                    fullName: nameController.text,
                    targetRole: trackController.text,
                  );
                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop();
                  }
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Profile updated locally.')),
                    );
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      );
    }

    Future<void> handleRowTap(String label) async {
      if (label == 'Logout') {
        await controller.logout();
        return;
      }
      if (label == 'Edit profile') {
        await openEditProfile();
        return;
      }
      showAction('$label will be connected in the next pass.');
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Color(0xFFEDEBFF),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                session?.initials ?? 'VI',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A2E),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(session?.fullName ?? 'VoiceIQ Developer', style: theme.textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text(session?.targetRole ?? 'Software Engineer track', style: theme.textTheme.bodySmall),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: openEditProfile,
                child: const Text('Edit profile'),
              ),
            ),
            const SizedBox(height: 20),
            _ProfileStatsRow(
              sessionsLabel: '$completedSessions',
              planLabel: subscription?.developerAccount == true
                  ? 'Dev Pro'
                  : (session?.plan ?? 'FREE'),
              secondsLabel: '${subscription?.processedSecondsUsed ?? 0}',
            ),
            const SizedBox(height: 20),
            _SettingsGroup(
              title: 'Preferences',
              rows: const [
                _SettingsRow(label: 'Notification reminders', trailing: 'On'),
                _SettingsRow(label: 'Daily goal', trailing: '10 min'),
                _SettingsRow(label: 'Voice language', trailing: 'English'),
              ],
              onRowTap: handleRowTap,
            ),
            const SizedBox(height: 16),
            _SettingsGroup(
              title: 'Account',
              rows: const [
                _SettingsRow(label: 'Edit profile'),
                _SettingsRow(label: 'Change password'),
                _SettingsRow(label: 'Connected accounts'),
              ],
              onRowTap: handleRowTap,
            ),
            const SizedBox(height: 16),
            _SettingsGroup(
              title: 'Subscription',
              rows: [
                _SettingsRow(
                  label: 'Current plan',
                  trailing: subscription?.developerAccount == true
                      ? 'Developer Pro'
                      : (session?.plan ?? 'Free'),
                ),
                const _SettingsRow(label: 'Upgrade to Pro', highlight: true),
              ],
              onRowTap: handleRowTap,
            ),
            const SizedBox(height: 16),
            _SettingsGroup(
              title: 'Support',
              rows: const [
                _SettingsRow(label: 'Help centre'),
                _SettingsRow(label: 'Send feedback'),
                _SettingsRow(label: 'Rate the app'),
              ],
              onRowTap: handleRowTap,
            ),
            const SizedBox(height: 16),
            _SettingsGroup(
              title: 'Logout',
              rows: const [_SettingsRow(label: 'Logout', destructive: true)],
              onRowTap: handleRowTap,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileStatsRow extends StatelessWidget {
  const _ProfileStatsRow({
    required this.sessionsLabel,
    required this.planLabel,
    required this.secondsLabel,
  });

  final String sessionsLabel;
  final String planLabel;
  final String secondsLabel;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final muted =
        Theme.of(context).textTheme.bodySmall?.color ?? const Color(0xFF9CA3AF);

    Widget item(String value, String label) {
      return Expanded(
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(color: muted, fontSize: 12)),
          ],
        ),
      );
    }

    return Row(
      children: [
        item(sessionsLabel, 'Sessions'),
        item(planLabel, 'Plan'),
        item(secondsLabel, 'Seconds'),
      ],
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({
    required this.title,
    required this.rows,
    required this.onRowTap,
  });

  final String title;
  final List<_SettingsRow> rows;
  final FutureOr<void> Function(String) onRowTap;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      color: isDark ? const Color(0xFF171728) : null,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: onSurface,
              ),
            ),
            const SizedBox(height: 8),
            ...rows.asMap().entries.map((entry) {
              final index = entry.key;
              final row = entry.value;
              return Column(
                children: [
                  _ClickableSettingsRow(
                    row: row,
                    onTap: () => onRowTap(row.label),
                  ),
                  if (index != rows.length - 1)
                    const Divider(height: 1, color: Color.fromRGBO(0, 0, 0, 0.08)),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.label,
    this.trailing,
    this.highlight = false,
    this.destructive = false,
  });

  final String label;
  final String? trailing;
  final bool highlight;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final muted =
        Theme.of(context).textTheme.bodySmall?.color ?? const Color(0xFF6B7280);
    final color = destructive
        ? const Color(0xFFEF4444)
        : highlight
        ? const Color(0xFF6C63FF)
        : onSurface;

    return ListTile(
      dense: true,
      visualDensity: const VisualDensity(vertical: -1),
      contentPadding: EdgeInsets.zero,
      title: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: highlight ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
      trailing: trailing != null
          ? Text(
              trailing!,
              style: TextStyle(
                color: highlight ? const Color(0xFF6C63FF) : muted,
              ),
            )
          : Icon(Icons.chevron_right_rounded, color: muted),
    );
  }
}

class _ClickableSettingsRow extends StatelessWidget {
  const _ClickableSettingsRow({
    required this.row,
    required this.onTap,
  });

  final _SettingsRow row;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: row,
    );
  }
}
