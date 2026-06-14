import 'package:flutter/material.dart';

import 'backup_models.dart';
import 'backup_scheduler.dart';
import 'drive_backup_service.dart';
import 'local_backup_transfer_service.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({
    super.key,
    required this.driveBackupService,
    this.backupTransferService,
    this.onRestoreCompleted,
    this.drawer,
  });

  final DriveBackupService driveBackupService;
  final BackupTransferService? backupTransferService;
  final Future<void> Function()? onRestoreCompleted;
  final Widget? drawer;

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  BackupScheduleSettings? _settings;
  String? _message;
  bool _isLoading = true;
  bool _isBusy = false;

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
      appBar: AppBar(title: const Text('Backup & Restore')),
      body: _isLoading || settings == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: <Widget>[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text(
                          'Manual encrypted backup',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('Last backup: ${_formatLastBackup(settings)}'),
                        const SizedBox(height: 8),
                        const Text(
                          'Save the backup file somewhere outside this phone. '
                          'The password is required for restore and cannot be recovered.',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  key: const Key('exportBackupButton'),
                  onPressed: _isBusy || widget.backupTransferService == null
                      ? null
                      : _exportBackup,
                  icon: const Icon(Icons.upload_file_outlined),
                  label: const Text('Export encrypted backup'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  key: const Key('importBackupButton'),
                  onPressed: _isBusy || widget.backupTransferService == null
                      ? null
                      : _importBackup,
                  icon: const Icon(Icons.download_outlined),
                  label: const Text('Restore encrypted backup'),
                ),
                const SizedBox(height: 20),
                const Card(
                  child: ListTile(
                    leading: Icon(Icons.cloud_off_outlined),
                    title: Text('Automatic cloud backup is not configured'),
                    subtitle: Text(
                      'Use manual export for production data protection. '
                      'Google Drive automation will only be enabled after OAuth '
                      'and Android background scheduling are configured.',
                    ),
                  ),
                ),
                if (_message != null) ...<Widget>[
                  const SizedBox(height: 16),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      _message!,
                      key: const Key('backupMessage'),
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await widget.driveBackupService.loadSettings();
      if (!mounted) return;
      setState(() {
        _settings = settings;
        _isLoading = false;
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _settings = const BackupScheduleSettings();
        _message = _friendlyError(error);
        _isLoading = false;
      });
    }
  }

  Future<void> _exportBackup() async {
    final password = await _requestPassword(confirmPassword: true);
    if (password == null || !mounted) return;
    await _runAction(() async {
      await widget.backupTransferService!.exportBackup(password: password);
      await _refreshSettings();
      return 'Encrypted backup created. Finish saving it in the share sheet.';
    });
  }

  Future<void> _importBackup() async {
    final password = await _requestPassword(
      confirmPassword: false,
      isRestore: true,
    );
    if (password == null || !mounted) return;
    await _runAction(() async {
      final result =
          await widget.backupTransferService!.importBackup(password: password);
      if (result == BackupImportResult.canceled) {
        return 'Restore canceled. No data was changed.';
      }
      await widget.onRestoreCompleted?.call();
      return 'Backup restored. Sign in with the restored account.';
    });
  }

  Future<void> _runAction(Future<String> Function() action) async {
    setState(() {
      _isBusy = true;
      _message = null;
    });
    try {
      final message = await action();
      if (!mounted) return;
      setState(() => _message = message);
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _message = _friendlyError(error));
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _refreshSettings() async {
    final settings = await widget.driveBackupService.loadSettings();
    if (mounted) setState(() => _settings = settings);
  }

  Future<String?> _requestPassword({
    required bool confirmPassword,
    bool isRestore = false,
  }) async {
    final formKey = GlobalKey<FormState>();
    final passwordController = TextEditingController();
    final confirmationController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(isRestore ? 'Restore backup' : 'Encrypt backup'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (isRestore) ...<Widget>[
                  const Text(
                    'Restoring replaces all current local business data and '
                    'signs you out. This cannot be undone.',
                  ),
                  const SizedBox(height: 12),
                ],
                TextFormField(
                  key: const Key('backupPasswordField'),
                  controller: passwordController,
                  obscureText: true,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Backup password',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => (value ?? '').length < 8
                      ? 'Use at least 8 characters.'
                      : null,
                ),
                if (confirmPassword) ...<Widget>[
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const Key('backupPasswordConfirmationField'),
                    controller: confirmationController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Confirm password',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value != passwordController.text
                        ? 'Passwords do not match.'
                        : null,
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('confirmBackupAction'),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(dialogContext).pop(passwordController.text);
              }
            },
            child: Text(isRestore ? 'Replace and restore' : 'Create backup'),
          ),
        ],
      ),
    );
    return result;
  }

  String _friendlyError(Object error) {
    if (error is BackupDecryptionException ||
        error is UnsupportedBackupVersionException ||
        error is InvalidBackupPayloadException ||
        error is BackupPasswordException ||
        error is DriveBackupConfigurationException) {
      return error.toString().replaceFirst(RegExp(r'^[^:]+:\s*'), '');
    }
    return 'Backup operation failed. No data was changed.';
  }

  String _formatLastBackup(BackupScheduleSettings settings) {
    final lastBackupAt = settings.lastBackupAt;
    if (lastBackupAt == null) return 'Never';
    return '${lastBackupAt.year.toString().padLeft(4, '0')}-'
        '${lastBackupAt.month.toString().padLeft(2, '0')}-'
        '${lastBackupAt.day.toString().padLeft(2, '0')} '
        '${lastBackupAt.hour.toString().padLeft(2, '0')}:'
        '${lastBackupAt.minute.toString().padLeft(2, '0')}';
  }
}
