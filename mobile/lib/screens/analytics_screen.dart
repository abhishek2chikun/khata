import 'package:flutter/material.dart';

import '../models/analytics.dart';
import '../services/analytics_service.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({
    super.key,
    required this.analyticsService,
    required this.drawer,
  });

  final AnalyticsService analyticsService;
  final Widget drawer;

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  Dashboard? _dashboard;
  bool _isLoading = true;
  String? _errorMessage;

  String? _fromDate;
  String? _toDate;

  @override
  void initState() {
    super.initState();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: widget.drawer,
      appBar: AppBar(title: const Text('Analytics')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
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

    final dashboard = _dashboard!;
    final hasData = dashboard.revenueByCompany.isNotEmpty ||
        dashboard.profitByCompany.isNotEmpty ||
        dashboard.customerKhataBalances.isNotEmpty ||
        dashboard.buyerPendingPayables.isNotEmpty ||
        dashboard.topProductsByQuantity.isNotEmpty ||
        dashboard.lowStock.isNotEmpty;

    if (!hasData) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('No analytics data available'),
            const SizedBox(height: 16),
            _buildDateControls(),
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
          const SizedBox(height: 16),
          _buildSection(
            title: 'Revenue by Company',
            items: dashboard.revenueByCompany
                .map((e) => _SummaryRow(label: e.name, value: e.revenue))
                .toList(),
          ),
          _buildSection(
            title: 'Profit by Company',
            items: dashboard.profitByCompany
                .map((e) => _SummaryRow(label: e.name, value: e.profit))
                .toList(),
          ),
          _buildSection(
            title: 'Customer Balances',
            items: dashboard.customerKhataBalances
                .map((e) => _SummaryRow(
                    label: e.customerName, value: e.balance))
                .toList(),
          ),
          _buildSection(
            title: 'Buyer Payables',
            items: dashboard.buyerPendingPayables
                .map(
                    (e) => _SummaryRow(label: e.buyerName, value: e.payable))
                .toList(),
          ),
          _buildSection(
            title: 'Top Products',
            items: dashboard.topProductsByQuantity
                .map((e) => _SummaryRow(
                    label: e.productName, value: e.quantity))
                .toList(),
          ),
          _buildSection(
            title: 'Low Stock',
            items: dashboard.lowStock
                .map((e) => _SummaryRow(
                    label: e.productName,
                    value: e.quantityOnHand,
                    subtitle: 'Threshold: ${e.lowStockThreshold}'))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDateControls() {
    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: () => _pickDate(isFrom: true),
            child: Text(
              _fromDate != null ? 'From: $_fromDate' : 'From date',
            ),
          ),
        ),
        Expanded(
          child: TextButton(
            onPressed: () => _pickDate(isFrom: false),
            child: Text(
              _toDate != null ? 'To: $_toDate' : 'To date',
            ),
          ),
        ),
        IconButton(
          onPressed: _loadDashboard,
          icon: const Icon(Icons.refresh),
        ),
      ],
    );
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked == null) return;
    final formatted =
        '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    setState(() {
      if (isFrom) {
        _fromDate = formatted;
      } else {
        _toDate = formatted;
      }
    });
    _loadDashboard();
  }

  Widget _buildSection({
    required String title,
    required List<_SummaryRow> items,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ...items,
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
    this.subtitle,
  });

  final String label;
  final double value;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
          Text(value.toStringAsFixed(2)),
        ],
      ),
    );
  }
}
