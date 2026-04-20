import 'dart:io';

import 'package:flutter/material.dart';

import '../models/api_error.dart';
import '../models/seller.dart';
import '../services/payments_service.dart';
import '../services/sellers_service.dart';
import '../widgets/error_banner.dart';
import 'seller_detail_screen.dart';

class SellerListScreen extends StatefulWidget {
  const SellerListScreen({
    super.key,
    required this.sellersService,
    required this.paymentsService,
    required this.onCreateInvoice,
  });

  final SellersService sellersService;
  final PaymentsService paymentsService;
  final Future<bool> Function(Seller seller) onCreateInvoice;

  @override
  State<SellerListScreen> createState() => _SellerListScreenState();
}

class _SellerListScreenState extends State<SellerListScreen> {
  final _searchController = TextEditingController();

  List<Seller> _allSellers = const <Seller>[];
  List<Seller> _sellers = const <Seller>[];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSellers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sellers')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createSeller,
        icon: const Icon(Icons.add),
        label: const Text('Add seller'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TextField(
              key: const Key('sellerSearchField'),
              controller: _searchController,
              onChanged: (_) => _applySearchFilter(),
              decoration: const InputDecoration(
                labelText: 'Search sellers',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            if (_errorMessage != null) ...<Widget>[
              ErrorBanner(message: _errorMessage!),
              const SizedBox(height: 16),
            ],
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_sellers.isEmpty) {
      return const Center(child: Text('No sellers found'));
    }
    return ListView.separated(
      itemCount: _sellers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final seller = _sellers[index];
        return Card(
          child: ListTile(
            onTap: () => _openSeller(seller),
            title: Text(seller.name),
            subtitle: Text(seller.address),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Text(seller.pendingBalance.toStringAsFixed(2)),
                if (!seller.isActive) const Text('Archived'),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _loadSellers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final sellers = await widget.sellersService.fetchSellers();
      if (!mounted) {
        return;
      }
      setState(() {
        _allSellers = sellers;
        _sellers = _filterSellers(sellers, _searchController.text.trim());
      });
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = _messageForLoadError(error);
        _allSellers = const <Seller>[];
        _sellers = const <Seller>[];
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _applySearchFilter() {
    setState(() {
      _sellers = _filterSellers(_allSellers, _searchController.text.trim());
    });
  }

  List<Seller> _filterSellers(List<Seller> sellers, String query) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) {
      return sellers;
    }
    return sellers.where((seller) {
      final name = seller.name.toLowerCase();
      final address = seller.address.toLowerCase();
      final phone = seller.phone?.toLowerCase() ?? '';
      final gstin = seller.gstin?.toLowerCase() ?? '';
      return name.contains(normalizedQuery) ||
          address.contains(normalizedQuery) ||
          phone.contains(normalizedQuery) ||
          gstin.contains(normalizedQuery);
    }).toList();
  }

  Future<void> _openSeller(Seller seller) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => SellerDetailScreen(
          sellerId: seller.id,
          sellersService: widget.sellersService,
          paymentsService: widget.paymentsService,
          onCreateInvoice: widget.onCreateInvoice,
        ),
      ),
    );
    if (mounted) {
      await _loadSellers();
    }
  }

  Future<void> _createSeller() async {
    final created = await showDialog<bool>(
          context: context,
          builder: (_) => _CreateSellerDialog(sellersService: widget.sellersService),
        ) ??
        false;
    if (created && mounted) {
      await _loadSellers();
    }
  }

  String _messageForLoadError(Object error) {
    if (error is ApiError) {
      return error.message;
    }
    if (error is SocketException || error is HttpException) {
      return 'Unable to reach the server';
    }
    return 'Unable to load sellers';
  }
}

class _CreateSellerDialog extends StatefulWidget {
  const _CreateSellerDialog({required this.sellersService});

  final SellersService sellersService;

  @override
  State<_CreateSellerDialog> createState() => _CreateSellerDialogState();
}

class _CreateSellerDialogState extends State<_CreateSellerDialog> {
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _gstinController = TextEditingController();
  final _stateController = TextEditingController();
  final _stateCodeController = TextEditingController();

  bool _isSaving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _gstinController.dispose();
    _stateController.dispose();
    _stateCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add seller'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (_errorMessage != null) ...<Widget>[
              ErrorBanner(message: _errorMessage!),
              const SizedBox(height: 12),
            ],
            _buildField(_nameController, 'Name'),
            _buildField(_addressController, 'Address'),
            _buildField(_phoneController, 'Phone'),
            _buildField(_gstinController, 'GSTIN'),
            _buildField(_stateController, 'State'),
            _buildField(_stateCodeController, 'State code'),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create'),
        ),
      ],
    );
  }

  Widget _buildField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        enabled: !_isSaving,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await widget.sellersService.createSeller(
        CreateSellerInput(
          name: _nameController.text.trim(),
          address: _addressController.text.trim(),
          phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
          gstin: _gstinController.text.trim().isEmpty ? null : _gstinController.text.trim(),
          state: _stateController.text.trim().isEmpty ? null : _stateController.text.trim(),
          stateCode: _stateCodeController.text.trim().isEmpty ? null : _stateCodeController.text.trim(),
        ),
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } on ApiError catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = error.message;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}
