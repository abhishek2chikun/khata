import 'package:flutter/material.dart';

import 'backup_models.dart';
import 'backup_scheduler.dart';
import 'drive_backup_service.dart';
import 'encrypted_drive_backup_orchestrator.dart';
import 'local_backup_transfer_service.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({
    super.key,
    required this.driveBackupService,
    this.backupTransferService,
    this.onRestoreCompleted,
    this.drawer,
    this.initialConnected,
    this.initialDriveBackups,
  });

  final DriveBackupService driveBackupService;
  final BackupTransferService? backupTransferService;
  final Future<void> Function()? onRestoreCompleted;
  final Widget? drawer;
  final bool? initialConnected;
  final List<DriveBackupListItem>? initialDriveBackups;

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  BackupScheduleSettings? _settings;
  List<DriveBackupListItem>? _driveBackups;
  String? _message;
  String? _failureMessage;
  bool _isLoading = true;
  bool _isBusy = false;
  bool _connected = false;
  bool _hasPassword = false;
  String? _accountEmail;

  @override
  void initState() {
    super.initState();
    if (widget.initialConnected != null || widget.initialDriveBackups != null) {
      _connected = widget.initialConnected ?? false;
      _driveBackups = widget.initialDriveBackups;
      _settings = const BackupScheduleSettings();
      _isLoading = false;
    }
    _loadScreenState();
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
                _buildCloudCard(settings),
                const SizedBox(height: 16),
                _buildManualCard(settings),
                if (_driveBackups != null && _driveBackups!.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 16),
                  _buildRestoreList(),
                ],
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

  Widget _buildCloudCard(BackupScheduleSettings settings) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Google Drive backup',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              _connected
                  ? 'Connected as ${_accountEmail ?? 'Google account'}.'
                  : 'Connect Google Drive to upload encrypted backups automatically.',
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              key: const Key('connectGoogleButton'),
              onPressed: _isBusy
                  ? null
                  : (_connected ? _disconnectGoogle : _connectGoogle),
              icon: Icon(_connected ? Icons.link_off_outlined : Icons.link),
              label: Text(_connected ? 'Disconnect Google' : 'Connect Google'),
            ),
            const SizedBox(height: 16),
            const Text(
              'Backup password',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            const Text(
              'Required for encryption. Stored only on this device. '
              'Re-enter after reinstalling the app.',
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                OutlinedButton(
                  key: const Key('setBackupPasswordButton'),
                  onPressed: _isBusy ? null : _configurePassword,
                  child: Text(_hasPassword ? 'Change password' : 'Set password'),
                ),
                if (_hasPassword)
                  OutlinedButton(
                    key: const Key('removeBackupPasswordButton'),
                    onPressed: _isBusy ? null : _removePassword,
                    child: const Text('Remove password'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              key: const Key('automaticBackupSwitch'),
              contentPadding: EdgeInsets.zero,
              title: const Text('Automatic daily backup'),
              subtitle: Text(
                'Runs near ${settings.dailyBackupTime.format24Hour()} with catch-up on app launch.',
              ),
              value: settings.automaticBackupsEnabled,
              onChanged: _isBusy ? null : _toggleAutomaticBackup,
            ),
            const SizedBox(height: 8),
            Text('Last backup: ${_formatLastBackup(settings)}'),
            if (_failureMessage != null) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                'Last failure: $_failureMessage',
                key: const Key('backupFailureMessage'),
              ),
            ],
            const SizedBox(height: 12),
            FilledButton.icon(
              key: const Key('backupNowButton'),
              onPressed: _isBusy ? null : _backupNow,
              icon: const Icon(Icons.cloud_upload_outlined),
              label: const Text('Back up now'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManualCard(BackupScheduleSettings settings) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Manual encrypted backup',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Save the backup file somewhere outside this phone. '
              'The password is required for restore and cannot be recovered.',
            ),
            const SizedBox(height: 12),
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
          ],
        ),
      ),
    );
  }

  Widget _buildRestoreList() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Restore from Google Drive',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ..._driveBackups!.map(
              (backup) => ListTile(
                key: Key('restoreBackup-${backup.id}'),
                contentPadding: EdgeInsets.zero,
                title: Text(backup.name),
                subtitle: Text(
                  '${_formatTimestamp(backup.createdTime)} · '
                  '${_formatSize(backup.sizeBytes)} · schema ${backup.schemaVersion}',
                ),
                trailing: TextButton(
                  key: Key('restoreBackupButton-${backup.id}'),
                  onPressed: _isBusy ? null : () => _restoreFromDrive(backup),
                  child: const Text('Restore'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadScreenState() async {
    try {
      final settings = await widget.driveBackupService.loadSettings();
      final connected = widget.initialConnected ??
          await widget.driveBackupService.isGoogleAccountConnected();
      final hasPassword = await widget.driveBackupService.hasBackupPassword();
      final accountEmail = connected
          ? await widget.driveBackupService.googleAccountEmail()
          : null;
      final failureMessage =
          await widget.driveBackupService.lastFailureMessage();
      List<DriveBackupListItem>? backups = widget.initialDriveBackups;
      if (backups == null && connected) {
        try {
          backups = await widget.driveBackupService.listDriveBackups();
        } on Object {
          backups = const <DriveBackupListItem>[];
        }
      }
      if (!mounted) return;
      setState(() {
        _settings = settings;
        _connected = connected;
        _hasPassword = hasPassword;
        _accountEmail = accountEmail;
        _failureMessage = failureMessage;
        _driveBackups = backups;
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

  Future<void> _connectGoogle() async {
    await _runAction(() async {
      await widget.driveBackupService.connectGoogleAccount();
      await _refreshCloudState();
      return 'Google account connected.';
    });
  }

  Future<void> _disconnectGoogle() async {
    await _runAction(() async {
      await widget.driveBackupService.disconnectGoogleAccount();
      await _refreshCloudState();
      return 'Google account disconnected.';
    });
  }

  Future<void> _configurePassword() async {
    final password = await _requestPassword(confirmPassword: true);
    if (password == null || !mounted) return;
    await _runAction(() async {
      await widget.driveBackupService.saveBackupPassword(password);
      _hasPassword = true;
      return 'Backup password saved on this device.';
    });
  }

  Future<void> _removePassword() async {
    await _runAction(() async {
      await widget.driveBackupService.removeBackupPassword();
      _hasPassword = false;
      return 'Backup password removed from this device.';
    });
  }

  Future<void> _toggleAutomaticBackup(bool enabled) async {
    final settings = _settings!;
    await _runAction(() async {
      final updated = BackupScheduleSettings(
        automaticBackupsEnabled: enabled,
        dailyBackupTime: settings.dailyBackupTime,
        lastBackupAt: settings.lastBackupAt,
      );
      await widget.driveBackupService.saveSettings(updated);
      _settings = updated;
      return enabled
          ? 'Automatic backup enabled for ${updated.dailyBackupTime.format24Hour()}.'
          : 'Automatic backup disabled.';
    });
  }

  Future<void> _backupNow() async {
    await _runAction(() async {
      await widget.driveBackupService.backupToDriveNow();
      await _refreshCloudState();
      return 'Encrypted backup uploaded to Google Drive.';
    });
  }

  Future<void> _restoreFromDrive(DriveBackupListItem backup) async {
    final password = await _requestPassword(
      confirmPassword: false,
      isRestore: true,
    );
    if (password == null || !mounted) return;
    await _runAction(() async {
      await widget.driveBackupService.restoreFromDrive(
        fileId: backup.id,
        password: password,
      );
      await widget.onRestoreCompleted?.call();
      return 'Backup restored. Sign in with the restored account.';
    });
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

  Future<void> _refreshCloudState() async {
    final settings = await widget.driveBackupService.loadSettings();
    final connected = await widget.driveBackupService.isGoogleAccountConnected();
    final hasPassword = await widget.driveBackupService.hasBackupPassword();
    final accountEmail = connected
        ? await widget.driveBackupService.googleAccountEmail()
        : null;
    final failureMessage =
        await widget.driveBackupService.lastFailureMessage();
    List<DriveBackupListItem>? backups;
    if (connected) {
      try {
        backups = await widget.driveBackupService.listDriveBackups();
      } on Object {
        backups = const <DriveBackupListItem>[];
      }
    }
    if (!mounted) return;
    setState(() {
      _settings = settings;
      _connected = connected;
      _hasPassword = hasPassword;
      _accountEmail = accountEmail;
      _failureMessage = failureMessage;
      _driveBackups = backups;
    });
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
    return _formatTimestamp(lastBackupAt);
  }

  String _formatTimestamp(DateTime value) {
    return '${value.year.toString().padLeft(4, '0')}-'
        '${value.month.toString().padLeft(2, '0')}-'
        '${value.day.toString().padLeft(2, '0')} '
        '${value.hour.toString().padLeft(2, '0')}:'
        '${value.minute.toString().padLeft(2, '0')}';
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    }
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }
}
