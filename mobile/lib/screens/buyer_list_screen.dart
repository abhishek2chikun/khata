import 'dart:io';

import 'package:flutter/material.dart';

import '../models/api_error.dart';
import '../models/buyer.dart';
import '../services/buyers_service.dart';
import '../widgets/error_banner.dart';
import 'buyer_detail_screen.dart';
import 'buyer_form_screen.dart';

class BuyerListScreen extends StatefulWidget {
  const BuyerListScreen({
    super.key,
    required this.buyersService,
    this.drawer,
  });

  final BuyersService buyersService;
  final Widget? drawer;

  @override
  State<BuyerListScreen> createState() => _BuyerListScreenState();
}

class _BuyerListScreenState extends State<BuyerListScreen> {
  final _searchController = TextEditingController();

  List<Buyer> _allBuyers = const <Buyer>[];
  List<Buyer> _buyers = const <Buyer>[];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadBuyers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: widget.drawer,
      appBar: AppBar(title: const Text('Buyers')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createBuyer,
        icon: const Icon(Icons.add),
        label: const Text('Add buyer'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TextField(
              key: const Key('buyerSearchField'),
              controller: _searchController,
              onChanged: (_) => _applySearchFilter(),
              decoration: const InputDecoration(
                labelText: 'Search buyers',
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
    if (_buyers.isEmpty) {
      return const Center(child: Text('No buyers found'));
    }
    return ListView.separated(
      itemCount: _buyers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final buyer = _buyers[index];
        return Card(
          child: ListTile(
            onTap: () => _openBuyer(buyer),
            title: Text(buyer.name),
            subtitle: Text(buyer.address),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                const Text('Pending Payable'),
                Text(buyer.pendingPayable.toStringAsFixed(2)),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _loadBuyers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final buyers = await widget.buyersService.fetchBuyers();
      if (!mounted) {
        return;
      }
      setState(() {
        _allBuyers = buyers;
        _buyers = _filterBuyers(buyers, _searchController.text);
      });
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = _messageForLoadError(error);
        _allBuyers = const <Buyer>[];
        _buyers = const <Buyer>[];
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
      _buyers = _filterBuyers(_allBuyers, _searchController.text);
    });
  }

  List<Buyer> _filterBuyers(List<Buyer> buyers, String query) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) {
      return buyers;
    }
    return buyers.where((buyer) {
      return buyer.name.toLowerCase().contains(normalizedQuery) ||
          buyer.address.toLowerCase().contains(normalizedQuery) ||
          (buyer.phone?.toLowerCase().contains(normalizedQuery) ?? false) ||
          (buyer.gstin?.toLowerCase().contains(normalizedQuery) ?? false);
    }).toList();
  }

  Future<void> _openBuyer(Buyer buyer) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => BuyerDetailScreen(
          buyerId: buyer.id,
          buyersService: widget.buyersService,
        ),
      ),
    );
    if (mounted) {
      await _loadBuyers();
    }
  }

  Future<void> _createBuyer() async {
    final result = await Navigator.of(context).push<Buyer>(
      MaterialPageRoute<Buyer>(
        builder: (_) => BuyerFormScreen(buyersService: widget.buyersService),
      ),
    );
    if (result != null && mounted) {
      await _loadBuyers();
    }
  }

  String _messageForLoadError(Object error) {
    if (error is ApiError) {
      return error.message;
    }
    if (error is SocketException || error is HttpException) {
      return 'Unable to reach the server';
    }
    return 'Unable to load buyers';
  }
}
