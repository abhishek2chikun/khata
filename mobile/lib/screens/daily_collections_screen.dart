import 'dart:io';

import 'package:flutter/material.dart';

import '../models/api_error.dart';
import '../services/payments_service.dart';
import '../widgets/error_banner.dart';

class DailyCollectionsScreen extends StatefulWidget {
  const DailyCollectionsScreen({
    super.key,
    required this.paymentsService,
    this.onSubmitted,
  });

  final PaymentsService paymentsService;
  final VoidCallback? onSubmitted;

  @override
  State<DailyCollectionsScreen> createState() => _DailyCollectionsScreenState();
}

class _DailyCollectionsScreenState extends State<DailyCollectionsScreen> {
  final _searchController = TextEditingController();
  final _amountControllers = <String, TextEditingController>{};

  List<String> _selectedDates = const <String>[];
  List<CollectionGridCustomerRow> _allCustomers = const <CollectionGridCustomerRow>[];
  List<CollectionGridCustomerRow> _visibleCustomers = const <CollectionGridCustomerRow>[];
  String? _batchRequestId;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _selectedDates = <String>[_todayString()];
    _loadGrid();
  }

  @override
  void dispose() {
    _searchController.dispose();
    for (final controller in _amountControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily collections'),
        actions: <Widget>[
          IconButton(
            key: const Key('addCollectionDateButton'),
            tooltip: 'Add date',
            onPressed: _isLoading || _isSaving || _selectedDates.length >= 7 ? null : _addPreviousDate,
            icon: const Icon(Icons.calendar_today_outlined),
          ),
          if (_selectedDates.length > 1)
            IconButton(
              key: const Key('removeCollectionDateButton'),
              tooltip: 'Remove oldest date',
              onPressed: _isLoading || _isSaving ? null : _removeOldestDate,
              icon: const Icon(Icons.event_busy_outlined),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TextField(
              key: const Key('dailyCollectionsSearchField'),
              controller: _searchController,
              onChanged: (_) => _applySearchFilter(),
              decoration: const InputDecoration(
                labelText: 'Search customers',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            if (_errorMessage != null) ...<Widget>[
              ErrorBanner(message: _errorMessage!),
              const SizedBox(height: 12),
            ],
            if (_successMessage != null) ...<Widget>[
              Text(
                key: const Key('dailyCollectionsSuccessMessage'),
                _successMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(height: 12),
            ],
            Expanded(child: _buildBody()),
            const SizedBox(height: 12),
            Text(
              key: const Key('dailyCollectionsSummary'),
              _summaryText(),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 12),
            FilledButton(
              key: const Key('saveDailyCollectionsButton'),
              onPressed: _isLoading || _isSaving ? null : _confirmAndSave,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save collections'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_visibleCustomers.isEmpty) {
      return const Center(child: Text('No customers with pending balance'));
    }
    return ListView.separated(
      itemCount: _visibleCustomers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final customer = _visibleCustomers[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        customer.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Text(customer.pendingBalance.toStringAsFixed(2)),
                  ],
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _selectedDates.map((date) {
                      final isToday = date == _todayString();
                      final existing = customer.existingTotals[date] ?? 0;
                      final controller = _controllerFor(customer.id, date);
                      return Container(
                        width: 132,
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isToday
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).dividerColor,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            Text(
                              isToday ? '$date (Today)' : date,
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              key: Key('existingTotal-${customer.id}-$date'),
                              'Collected: ${existing.toStringAsFixed(2)}',
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              key: Key('additionalAmount-${customer.id}-$date'),
                              controller: controller,
                              enabled: !_isSaving,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'Additional',
                                isDense: true,
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (_) {
                                _invalidateBatchRequestId();
                                setState(() {});
                              },
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _loadGrid({bool preserveInputs = false, bool preserveMessages = false}) async {
    setState(() {
      _isLoading = true;
      if (!preserveMessages) {
        _errorMessage = null;
        _successMessage = null;
      }
    });

    try {
      final sortedDates = List<String>.from(_selectedDates)..sort();
      final grid = await widget.paymentsService.loadCollectionGrid(
        fromDate: sortedDates.first,
        toDate: sortedDates.last,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _allCustomers = grid.customers;
        _visibleCustomers = _filterCustomers(_allCustomers, _searchController.text.trim());
        _selectedDates = List<String>.from(grid.dates);
        if (!preserveInputs) {
          _clearUnusedControllers();
        }
      });
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = _messageForError(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _confirmAndSave() async {
    if (_pendingEntryCount() == 0) {
      setState(() {
        _errorMessage = 'Enter at least one collection amount';
      });
      return;
    }

    final validationError = _validationError();
    if (validationError != null) {
      setState(() {
        _errorMessage = validationError;
      });
      return;
    }

    final entryCount = _pendingEntryCount();
    final totalAmount = _pendingTotalAmount();
    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm collections'),
        content: Text('Post $entryCount entries totaling ${totalAmount.toStringAsFixed(2)}?'),
        actions: <Widget>[
          TextButton(
            key: const Key('cancelDailyCollectionsButton'),
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('confirmDailyCollectionsButton'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (shouldSave != true || !mounted) {
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
      _successMessage = null;
    });

    _batchRequestId ??= generateRequestId();
    final entries = _buildEntries();

    try {
      final result = await widget.paymentsService.recordCollectionBatch(
        BatchCollectionInput(requestId: _batchRequestId!, entries: entries),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _successMessage =
            'Posted ${result.entryCount} entries totaling ${result.totalAmount.toStringAsFixed(2)}';
        _batchRequestId = null;
      });
      _clearCommittedInputs(entries);
      widget.onSubmitted?.call();
      await _loadGrid(preserveMessages: true);
    } on ApiError catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = error.message;
        if (error.code == 'STALE_BALANCE' || error.code == 'IDEMPOTENCY_CONFLICT') {
          _batchRequestId = null;
        }
      });
      if (error.code == 'STALE_BALANCE') {
        await _loadGrid(preserveInputs: true, preserveMessages: true);
      }
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = _messageForError(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  List<BatchCollectionEntryInput> _buildEntries() {
    final entries = <BatchCollectionEntryInput>[];
    for (final customer in _allCustomers) {
      for (final date in _selectedDates) {
        final amount = _parseAmount(_controllerFor(customer.id, date).text);
        if (amount == null || amount <= 0) {
          continue;
        }
        entries.add(
          BatchCollectionEntryInput(
            customerId: customer.id,
            occurredOn: date,
            amount: amount,
          ),
        );
      }
    }
    return entries;
  }

  void _clearCommittedInputs(List<BatchCollectionEntryInput> entries) {
    for (final entry in entries) {
      final key = _cellKey(entry.customerId, entry.occurredOn);
      _amountControllers[key]?.clear();
    }
  }

  void _clearUnusedControllers() {
    final validKeys = <String>{
      for (final customer in _allCustomers)
        for (final date in _selectedDates) _cellKey(customer.id, date),
    };
    final staleKeys = _amountControllers.keys.where((key) => !validKeys.contains(key)).toList();
    for (final key in staleKeys) {
      _amountControllers.remove(key)?.dispose();
    }
  }

  TextEditingController _controllerFor(String customerId, String date) {
    final key = _cellKey(customerId, date);
    return _amountControllers.putIfAbsent(key, TextEditingController.new);
  }

  String _cellKey(String customerId, String date) => '$customerId|$date';

  void _applySearchFilter() {
    setState(() {
      _visibleCustomers = _filterCustomers(_allCustomers, _searchController.text.trim());
    });
  }

  List<CollectionGridCustomerRow> _filterCustomers(
    List<CollectionGridCustomerRow> customers,
    String query,
  ) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) {
      return customers;
    }
    return customers
        .where((customer) => customer.name.toLowerCase().contains(normalizedQuery))
        .toList();
  }

  void _addPreviousDate() {
    if (_selectedDates.length >= 7) {
      return;
    }
    final oldest = _selectedDates.reduce((left, right) => left.compareTo(right) < 0 ? left : right);
    final previous = _parseDate(oldest).subtract(const Duration(days: 1));
    final previousString = _dateString(previous);
    if (_daysBetween(previousString, _todayString()) > 6) {
      setState(() {
        _errorMessage = 'Collection dates cannot be older than six days';
      });
      return;
    }
    setState(() {
      _selectedDates = <String>[..._selectedDates, previousString]..sort();
      _errorMessage = null;
    });
    _loadGrid(preserveInputs: true);
  }

  void _removeOldestDate() {
    if (_selectedDates.length <= 1) {
      return;
    }
    final oldest = _selectedDates.reduce((left, right) => left.compareTo(right) < 0 ? left : right);
    setState(() {
      _selectedDates = _selectedDates.where((date) => date != oldest).toList();
    });
    for (final customer in _allCustomers) {
      _amountControllers.remove(_cellKey(customer.id, oldest))?.dispose();
    }
    _loadGrid(preserveInputs: true);
  }

  String? _validationError() {
    for (final customer in _allCustomers) {
      var enteredTotal = 0.0;
      for (final date in _selectedDates) {
        final amount = _parseAmount(_controllerFor(customer.id, date).text);
        if (amount == null) {
          return 'Enter valid amounts with up to two decimals';
        }
        if (amount < 0) {
          return 'Amounts cannot be negative';
        }
        enteredTotal += amount;
      }
      if (enteredTotal > customer.pendingBalance) {
        return '${customer.name} exceeds pending balance';
      }
    }
    return null;
  }

  int _pendingEntryCount() {
    var count = 0;
    for (final customer in _allCustomers) {
      for (final date in _selectedDates) {
        final amount = _parseAmount(_controllerFor(customer.id, date).text);
        if (amount != null && amount > 0) {
          count += 1;
        }
      }
    }
    return count;
  }

  double _pendingTotalAmount() {
    var total = 0.0;
    for (final customer in _allCustomers) {
      for (final date in _selectedDates) {
        final amount = _parseAmount(_controllerFor(customer.id, date).text);
        if (amount != null && amount > 0) {
          total += amount;
        }
      }
    }
    return total;
  }

  String _summaryText() {
    return '${_pendingEntryCount()} entries • ${_pendingTotalAmount().toStringAsFixed(2)} total';
  }

  void _invalidateBatchRequestId() {
    _batchRequestId = null;
  }

  double? _parseAmount(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return 0;
    }
    if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(trimmed)) {
      return null;
    }
    return double.parse(trimmed);
  }

  String _todayString() => _dateString(DateTime.now());

  String _dateString(DateTime value) {
    return '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
  }

  DateTime _parseDate(String value) {
    final parts = value.split('-');
    return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
  }

  int _daysBetween(String earlier, String later) {
    return _parseDate(later).difference(_parseDate(earlier)).inDays;
  }

  String _messageForError(Object error) {
    if (error is ApiError) {
      return error.message;
    }
    if (error is SocketException || error is HttpException) {
      return 'Unable to reach the server';
    }
    return 'Unable to save collections';
  }
}
