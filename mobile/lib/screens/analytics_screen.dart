import 'package:flutter/material.dart';

import '../models/analytics.dart';
import '../services/analytics_service.dart';
import '../widgets/analytics/revenue_profit_chart.dart';

enum AnalyticsDatePreset {
  today,
  last7Days,
  last30Days,
  thisMonth,
  custom,
}

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({
    super.key,
    required this.analyticsService,
    required this.drawer,
    this.initialPreset = AnalyticsDatePreset.last30Days,
    this.now,
  });

  final AnalyticsService analyticsService;
  final Widget drawer;
  final AnalyticsDatePreset initialPreset;
  final DateTime? now;

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  Dashboard? _dashboard;
  bool _isLoading = true;
  String? _errorMessage;
  String? _customRangeError;

  late AnalyticsDatePreset _preset;
  String? _fromDate;
  String? _toDate;

  DateTime get _now {
    final value = widget.now ?? DateTime.now();
    return DateTime(value.year, value.month, value.day);
  }

  @override
  void initState() {
    super.initState();
    _preset = widget.initialPreset;
    _applyPreset(_preset, reload: false);
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final dashboard = await widget.analyticsService.getDashboard(
        fromDate: _fromDate,
        toDate: _toDate,
      );
      if (!mounted) return;
      setState(() {
        _dashboard = dashboard;
        _isLoading = false;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load analytics';
        _isLoading = false;
      });
    }
  }

  void _applyPreset(AnalyticsDatePreset preset, {required bool reload}) {
    final range = _rangeForPreset(preset);
    setState(() {
      _preset = preset;
      _fromDate = range.$1;
      _toDate = range.$2;
      _customRangeError = null;
    });
    if (reload) {
      _loadDashboard();
    }
  }

  (String, String) _rangeForPreset(AnalyticsDatePreset preset) {
    switch (preset) {
      case AnalyticsDatePreset.today:
        final label = _formatDate(_now);
        return (label, label);
      case AnalyticsDatePreset.last7Days:
        final start = _now.subtract(const Duration(days: 6));
        return (_formatDate(start), _formatDate(_now));
      case AnalyticsDatePreset.last30Days:
        final start = _now.subtract(const Duration(days: 29));
        return (_formatDate(start), _formatDate(_now));
      case AnalyticsDatePreset.thisMonth:
        final start = DateTime(_now.year, _now.month, 1);
        return (_formatDate(start), _formatDate(_now));
      case AnalyticsDatePreset.custom:
        return (_fromDate ?? _formatDate(_now.subtract(const Duration(days: 29))), _toDate ?? _formatDate(_now));
    }
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  String get _selectedRangeLabel {
    if (_fromDate == null || _toDate == null) return 'All time';
    if (_fromDate == _toDate) return _fromDate!;
    return '$_fromDate to $_toDate';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: widget.drawer,
      appBar: AppBar(
        title: const Text('Analytics'),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadDashboard,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _dashboard == null) {
      return _buildLoadingSkeleton();
    }

    if (_errorMessage != null && _dashboard == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_errorMessage!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadDashboard,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final dashboard = _dashboard;
    if (dashboard == null) {
      return _buildLoadingSkeleton();
    }

    if (!dashboard.hasData) {
      return RefreshIndicator(
        onRefresh: _loadDashboard,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            _buildDateControls(),
            const SizedBox(height: 48),
            const Center(child: Text('No analytics data available')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDashboard,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildDateControls(),
          if (_isLoading) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(),
          ],
          const SizedBox(height: 16),
          Text(
            'Selected range: $_selectedRangeLabel',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          _buildKpiGrid(dashboard),
          const SizedBox(height: 16),
          RevenueProfitChart(
            points: dashboard.dailyTrend
                .map(
                  (point) => RevenueProfitChartPoint(
                    dateLabel: _shortDateLabel(point.date),
                    revenue: point.revenue,
                    profit: point.profit,
                  ),
                )
                .toList(),
            semanticSummary: _trendSemanticSummary(dashboard),
          ),
          const SizedBox(height: 16),
          _buildLedgerSummary(dashboard),
          const SizedBox(height: 16),
          _buildRankedSection(
            title: 'Top products by revenue',
            items: dashboard.topProductsByRevenue
                .take(5)
                .map((entry) => _RankedRow(
                      label: entry.productName,
                      value: entry.revenue,
                    ))
                .toList(),
          ),
          _buildRankedSection(
            title: 'Top products by profit',
            items: dashboard.topProductsByProfit
                .take(5)
                .map((entry) => _RankedRow(
                      label: entry.productName,
                      value: entry.profit,
                    ))
                .toList(),
          ),
          _buildRankedSection(
            title: 'Top customers by revenue',
            items: dashboard.revenueByCustomer
                .take(5)
                .map((entry) => _RankedRow(
                      label: entry.name,
                      value: entry.revenue,
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildDateControls(),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 720 ? 3 : 2;
            return GridView.count(
              crossAxisCount: columns,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.8,
              children: List.generate(
                6,
                (_) => Card(
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        const Card(
          child: SizedBox(height: 220),
        ),
      ],
    );
  }

  Widget _buildDateControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _presetChip('Today', AnalyticsDatePreset.today),
            _presetChip('7d', AnalyticsDatePreset.last7Days),
            _presetChip('30d', AnalyticsDatePreset.last30Days),
            _presetChip('Month', AnalyticsDatePreset.thisMonth),
            _presetChip('Custom', AnalyticsDatePreset.custom),
          ],
        ),
        if (_preset == AnalyticsDatePreset.custom) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _pickDate(isFrom: true),
                  child: Text(_fromDate != null ? 'From: $_fromDate' : 'From date'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _pickDate(isFrom: false),
                  child: Text(_toDate != null ? 'To: $_toDate' : 'To date'),
                ),
              ),
            ],
          ),
          if (_customRangeError != null) ...[
            const SizedBox(height: 8),
            Text(
              _customRangeError!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ],
    );
  }

  Widget _presetChip(String label, AnalyticsDatePreset preset) {
    return ChoiceChip(
      label: Text(label),
      selected: _preset == preset,
      onSelected: (_) => _applyPreset(preset, reload: true),
    );
  }

  Widget _buildKpiGrid(Dashboard dashboard) {
    final cards = [
      _KpiCard(label: 'Revenue', value: dashboard.totalRevenue),
      _KpiCard(label: 'Profit', value: dashboard.totalProfit),
      _KpiCard(label: 'Receivables', value: dashboard.customerReceivables),
      _KpiCard(label: 'Payables', value: dashboard.buyerPayables),
      _KpiCard(
        label: 'Active invoices',
        value: dashboard.activeInvoiceCount.toDouble(),
        isCount: true,
      ),
      _KpiCard(label: 'Avg invoice', value: dashboard.averageInvoiceValue),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 720 ? 3 : 2;
        return GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.8,
          children: cards,
        );
      },
    );
  }

  Widget _buildLedgerSummary(Dashboard dashboard) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Receivables & payables',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _SummaryRow(
              label: 'Total receivables',
              value: dashboard.customerReceivables,
            ),
            _SummaryRow(
              label: 'Total payables',
              value: dashboard.buyerPayables,
            ),
            if (dashboard.customerKhataBalances.isNotEmpty) ...[
              const Divider(height: 24),
              Text(
                'Customer balances',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              ...dashboard.customerKhataBalances.take(5).map(
                    (entry) => _SummaryRow(
                      label: entry.customerName,
                      value: entry.balance,
                    ),
                  ),
            ],
            if (dashboard.buyerPendingPayables.isNotEmpty) ...[
              const Divider(height: 24),
              Text(
                'Buyer payables',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              ...dashboard.buyerPendingPayables.take(5).map(
                    (entry) => _SummaryRow(
                      label: entry.buyerName,
                      value: entry.payable,
                    ),
                  ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRankedSection({
    required String title,
    required List<_RankedRow> items,
  }) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ...items,
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _now,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked == null) return;

    final formatted = _formatDate(picked);
    setState(() {
      if (isFrom) {
        _fromDate = formatted;
      } else {
        _toDate = formatted;
      }
      _preset = AnalyticsDatePreset.custom;
      _customRangeError = null;
    });

    if (_fromDate != null &&
        _toDate != null &&
        DateTime.parse(_fromDate!).isAfter(DateTime.parse(_toDate!))) {
      setState(() {
        _customRangeError = 'From date must be on or before to date';
      });
      return;
    }

    if (_fromDate != null && _toDate != null) {
      _loadDashboard();
    }
  }

  String _shortDateLabel(String isoDate) {
    final parts = isoDate.split('-');
    if (parts.length != 3) return isoDate;
    return '${parts[2]}/${parts[1]}';
  }

  String _trendSemanticSummary(Dashboard dashboard) {
    if (dashboard.dailyTrend.isEmpty) {
      return 'No revenue or profit trend data for $_selectedRangeLabel';
    }
    final totalRevenue = dashboard.dailyTrend.fold<double>(
      0,
      (sum, point) => sum + point.revenue,
    );
    final totalProfit = dashboard.dailyTrend.fold<double>(
      0,
      (sum, point) => sum + point.profit,
    );
    return 'Revenue and profit trend for $_selectedRangeLabel. '
        'Total revenue ${_money(totalRevenue)}, total profit ${_money(totalProfit)} '
        'across ${dashboard.dailyTrend.length} days.';
  }

  String _money(double value) => value.toStringAsFixed(2);
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.label,
    required this.value,
    this.isCount = false,
  });

  final String label;
  final double value;
  final bool isCount;

  @override
  Widget build(BuildContext context) {
    final display = isCount ? value.toInt().toString() : value.toStringAsFixed(2);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Text(
              display,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
  });

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label)),
          Text(value.toStringAsFixed(2)),
        ],
      ),
    );
  }
}

class _RankedRow extends StatelessWidget {
  const _RankedRow({
    required this.label,
    required this.value,
  });

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label)),
          Text(value.toStringAsFixed(2)),
        ],
      ),
    );
  }
}
