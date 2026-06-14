import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../constants/app_constants.dart';
import '../models/smart_alarm.dart';
import '../providers/user_provider.dart';
import '../services/smart_alarm_service.dart';
import '../widgets/widgets.dart';
import 'premium_purchase_screen.dart';

class SmartAlarmScreen extends StatefulWidget {
  const SmartAlarmScreen({super.key});

  @override
  State<SmartAlarmScreen> createState() => _SmartAlarmScreenState();
}

class _SmartAlarmScreenState extends State<SmartAlarmScreen> {
  final SmartAlarmService _service = SmartAlarmService();
  List<SmartAlarm> _alarms = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final alarms = await _service.loadAlarms();
    if (mounted) setState(() { _alarms = alarms; _loading = false; });
  }

  Future<void> _addAlarm() async {
    final result = await showDialog<SmartAlarm>(
      context: context,
      builder: (_) => const _AlarmEditDialog(),
    );
    if (result == null) return;
    await _service.saveAlarm(result);
    await _load();
    if (mounted) {
      final optimal = _service.computeOptimalWakeTime(result);
      _showScheduledSnack(optimal);
    }
  }

  Future<void> _editAlarm(SmartAlarm alarm) async {
    final result = await showDialog<SmartAlarm>(
      context: context,
      builder: (_) => _AlarmEditDialog(existing: alarm),
    );
    if (result == null) return;
    await _service.saveAlarm(result);
    await _load();
    if (mounted) {
      final optimal = _service.computeOptimalWakeTime(result);
      _showScheduledSnack(optimal);
    }
  }

  void _showScheduledSnack(DateTime optimal) {
    final h = optimal.hour.toString().padLeft(2, '0');
    final m = optimal.minute.toString().padLeft(2, '0');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Alarm scheduled for $h:$m')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPremium =
        context.select<UserProvider, bool>((p) => p.isPremium);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Alarm'),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: SafeArea(
        child: isPremium ? _body() : _premiumGate(context),
      ),
      floatingActionButton: isPremium
          ? FloatingActionButton(
              onPressed: _addAlarm,
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add_alarm, color: AppColors.textInverse),
            )
          : null,
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_alarms.isEmpty) {
      return _emptyState();
    }
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: _alarms.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (_, i) => _alarmCard(_alarms[i]),
    );
  }

  Widget _alarmCard(SmartAlarm alarm) {
    final optimal = _service.computeOptimalWakeTime(alarm);
    final optH = optimal.hour.toString().padLeft(2, '0');
    final optM = optimal.minute.toString().padLeft(2, '0');
    final targetH = alarm.time.hour.toString().padLeft(2, '0');
    final targetM = alarm.time.minute.toString().padLeft(2, '0');
    final smartWake = optimal.hour != alarm.time.hour ||
        optimal.minute != alarm.time.minute;

    return ModernCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => _editAlarm(alarm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$targetH:$targetM',
                      style: AppTypography.heading2.copyWith(
                        color: alarm.enabled
                            ? AppColors.textPrimary
                            : AppColors.textTertiary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      alarm.label ?? 'Smart Alarm',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (smartWake) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          const Icon(Icons.nights_stay,
                              size: 14, color: AppColors.accent),
                          const SizedBox(width: 4),
                          Text(
                            'Optimal wake: $optH:$optM',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.accent,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      alarm.isRecurring ? 'Daily' : 'Once',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Switch(
                  value: alarm.enabled,
                  activeThumbColor: AppColors.accent,
                  onChanged: (v) async {
                    await _service.enableAlarm(alarm.id, v);
                    await _load();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: AppColors.textTertiary),
                  onPressed: () async {
                    await _service.deleteAlarm(alarm.id);
                    await _load();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.alarm_off,
              size: 64, color: AppColors.textTertiary),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'No alarms set',
            style: AppTypography.heading3.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Tap + to add a smart alarm',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _premiumGate(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline,
                size: 64, color: AppColors.secondary),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Smart Alarm is Premium',
              style: AppTypography.heading3.copyWith(
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Wake up feeling refreshed. Smart Alarm detects your sleep cycles '
              'and wakes you at the lightest sleep phase within your chosen window.',
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const PremiumPurchaseScreen(),
                ),
              ),
              child: const Text('Upgrade to Premium'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Add / edit dialog ─────────────────────────────────────────────────────────

class _AlarmEditDialog extends StatefulWidget {
  final SmartAlarm? existing;
  const _AlarmEditDialog({this.existing});

  @override
  State<_AlarmEditDialog> createState() => _AlarmEditDialogState();
}

class _AlarmEditDialogState extends State<_AlarmEditDialog> {
  late TimeOfDay _wakeTime;
  TimeOfDay? _bedTime;
  late int _windowMinutes;
  late bool _isRecurring;
  late TextEditingController _labelCtrl;

  @override
  void initState() {
    super.initState();
    final a = widget.existing;
    _wakeTime = a != null
        ? TimeOfDay(hour: a.time.hour, minute: a.time.minute)
        : TimeOfDay.now();
    _bedTime = (a != null && a.hasBedTime)
        ? TimeOfDay(hour: a.bedTimeHour!, minute: a.bedTimeMinute!)
        : null;
    _windowMinutes = a?.windowMinutes ?? 30;
    _isRecurring = a?.isRecurring ?? true;
    _labelCtrl = TextEditingController(text: a?.label ?? 'Wake up');
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickWakeTime() async {
    final picked = await showTimePicker(context: context, initialTime: _wakeTime);
    if (picked != null) setState(() => _wakeTime = picked);
  }

  Future<void> _pickBedTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _bedTime ?? const TimeOfDay(hour: 23, minute: 0),
    );
    if (picked != null) setState(() => _bedTime = picked);
  }

  SmartAlarm _buildAlarm() {
    final now = DateTime.now();
    final time = DateTime(
        now.year, now.month, now.day, _wakeTime.hour, _wakeTime.minute);
    return SmartAlarm(
      id: widget.existing?.id ?? const Uuid().v4(),
      time: time,
      enabled: true,
      label: _labelCtrl.text.trim().isEmpty ? 'Wake up' : _labelCtrl.text.trim(),
      windowMinutes: _windowMinutes,
      bedTimeHour: _bedTime?.hour,
      bedTimeMinute: _bedTime?.minute,
      isRecurring: _isRecurring,
    );
  }

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  String _optimalPreview() {
    if (_bedTime == null) return _formatTime(_wakeTime);
    final alarm = _buildAlarm();
    final optimal = SmartAlarmService().computeOptimalWakeTime(alarm);
    final h = optimal.hour.toString().padLeft(2, '0');
    final m = optimal.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(
        widget.existing == null ? 'New Smart Alarm' : 'Edit Alarm',
        style: AppTypography.heading3.copyWith(color: AppColors.textPrimary),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Label
            TextField(
              controller: _labelCtrl,
              style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.textPrimary),
              decoration: const InputDecoration(labelText: 'Label'),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Wake time
            _sectionLabel('Wake time'),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                _formatTime(_wakeTime),
                style: AppTypography.heading2.copyWith(
                    color: AppColors.textPrimary),
              ),
              trailing: TextButton(
                onPressed: _pickWakeTime,
                child: const Text('Change'),
              ),
            ),

            // Bed time
            _sectionLabel('Bedtime estimate (optional)'),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                _bedTime != null ? _formatTime(_bedTime!) : 'Not set',
                style: AppTypography.bodyLarge.copyWith(
                    color: _bedTime != null
                        ? AppColors.textPrimary
                        : AppColors.textTertiary),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    onPressed: _pickBedTime,
                    child: Text(_bedTime != null ? 'Change' : 'Set'),
                  ),
                  if (_bedTime != null)
                    IconButton(
                      icon: const Icon(Icons.clear,
                          color: AppColors.textTertiary, size: 18),
                      onPressed: () => setState(() => _bedTime = null),
                    ),
                ],
              ),
            ),

            // Wake window
            _sectionLabel('Wake window: $_windowMinutes min'),
            Slider(
              value: _windowMinutes.toDouble(),
              min: 10,
              max: 60,
              divisions: 10,
              label: '$_windowMinutes min',
              onChanged: (v) =>
                  setState(() => _windowMinutes = v.round()),
            ),

            // Optimal wake preview
            if (_bedTime != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  const Icon(Icons.nights_stay,
                      size: 16, color: AppColors.accent),
                  const SizedBox(width: 6),
                  Text(
                    'Optimal wake: ${_optimalPreview()}',
                    style: AppTypography.labelMedium.copyWith(
                        color: AppColors.accent),
                  ),
                ],
              ),
            ],

            const SizedBox(height: AppSpacing.md),

            // Recurring
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Repeat daily',
                  style: AppTypography.bodyLarge.copyWith(
                      color: AppColors.textPrimary)),
              value: _isRecurring,
              activeThumbColor: AppColors.accent,
              onChanged: (v) => setState(() => _isRecurring = v),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(_buildAlarm()),
          child: const Text('Save'),
        ),
      ],
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: 2),
        child: Text(
          text,
          style: AppTypography.labelSmall.copyWith(
              color: AppColors.textTertiary),
        ),
      );
}
