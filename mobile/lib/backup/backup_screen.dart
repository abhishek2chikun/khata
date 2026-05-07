import 'package:flutter/material.dart';

import 'backup_scheduler.dart';
import 'drive_backup_service.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({
    super.key,
    required this.driveBackupService,
    this.drawer,
  });

  final DriveBackupService driveBackupService;
  final Widget? drawer;

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  BackupScheduleSettings? _settings;
  final _hourController = TextEditingController();
  final _minuteController = TextEditingController();
  String? _message;
  bool _isLoading = true;
  bool _isBusy = false;

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  Widget build(BuildContext context) {
    final settings = _settings;
    return Scaffold(
      drawer: widget.drawer,
      appBar: AppBar(
        title: const Text('Backup & Restore'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _isLoading || settings == null
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text('Last backup: ${_formatLastBackup(settings)}'),
                          const SizedBox(height: 8),
                          Text(
                            'Daily backup time: '
                            '${settings.dailyBackupTime.format24Hour()}',
                          ),
                          const SizedBox(height: 12),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Automatic backups'),
                            value: settings.automaticBackupsEnabled,
                            onChanged: (value) {
                              setState(() {
                                _settings = BackupScheduleSettings(
                                  automaticBackupsEnabled: value,
                                  dailyBackupTime: settings.dailyBackupTime,
                                  lastBackupAt: settings.lastBackupAt,
                                );
                              });
                            },
                          ),
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: TextField(
                                  controller: _hourController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Daily backup hour',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _minuteController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Daily backup minute',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton(
                            onPressed: _isBusy ? null : _saveSchedule,
                            child: const Text('Save backup schedule'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _isBusy ? null : _exportBackup,
                    icon: const Icon(Icons.upload_file_outlined),
                    label: const Text('Export backup'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _isBusy ? null : _importBackup,
                    icon: const Icon(Icons.download_outlined),
                    label: const Text('Import backup'),
                  ),
                  if (_message != null) ...<Widget>[
                    const SizedBox(height: 16),
                    Text(_message!),
                  ],
                ],
              ),
      ),
    );
  }

  Future<void> _loadSettings() async {
    final settings = await widget.driveBackupService.loadSettings();
    if (!mounted) {
      return;
    }
    setState(() {
      _settings = settings;
      _hourController.text = settings.dailyBackupTime.hour.toString();
      _minuteController.text = settings.dailyBackupTime.minute.toString();
      _isLoading = false;
    });
  }

  Future<void> _saveSchedule() async {
    final current = _settings;
    if (current == null) {
      return;
    }
    final next = BackupScheduleSettings(
      automaticBackupsEnabled: current.automaticBackupsEnabled,
      dailyBackupTime: BackupTimeOfDay(
        hour: int.tryParse(_hourController.text) ?? 0,
        minute: int.tryParse(_minuteController.text) ?? 0,
      ),
      lastBackupAt: current.lastBackupAt,
    );

    setState(() {
      _isBusy = true;
      _message = null;
    });
    try {
      await widget.driveBackupService.saveSettings(next);
      if (!mounted) {
        return;
      }
      setState(() {
        _settings = next;
        _message = 'Backup schedule saved.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
        });
      }
    }
  }

  Future<void> _exportBackup() async {
    await _runAction(
        widget.driveBackupService.exportBackup, 'Backup exported.');
  }

  Future<void> _importBackup() async {
    await _runAction(
        widget.driveBackupService.importBackup, 'Backup imported.');
  }

  Future<void> _runAction(
    Future<void> Function() action,
    String successMessage,
  ) async {
    setState(() {
      _isBusy = true;
      _message = null;
    });
    try {
      await action();
      if (!mounted) {
        return;
      }
      setState(() {
        _message = successMessage;
      });
    } on DriveBackupConfigurationException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _message = error.message;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
        });
      }
    }
  }

  String _formatLastBackup(BackupScheduleSettings settings) {
    final lastBackupAt = settings.lastBackupAt;
    if (lastBackupAt == null) {
      return 'Never';
    }
    return '${lastBackupAt.year.toString().padLeft(4, '0')}-'
        '${lastBackupAt.month.toString().padLeft(2, '0')}-'
        '${lastBackupAt.day.toString().padLeft(2, '0')} '
        '${lastBackupAt.hour.toString().padLeft(2, '0')}:'
        '${lastBackupAt.minute.toString().padLeft(2, '0')}';
  }
}
