import 'dart:io';

import 'package:flutter/material.dart';

import '../models/company_profile.dart';
import '../models/api_error.dart';
import '../models/customer.dart';
import '../services/balance_share_service.dart';
import '../services/company_profile_service.dart';
import '../services/payments_service.dart';
import '../services/customers_service.dart';
import '../widgets/error_banner.dart';
import '../widgets/app_ui.dart';
import 'customer_detail_screen.dart';
import 'daily_collections_screen.dart';

class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({
    super.key,
    required this.customersService,
    required this.paymentsService,
    required this.onCreateInvoice,
    this.drawer,
    this.companyProfileService,
    this.balanceShareService,
  });

  final CustomersService customersService;
  final PaymentsService paymentsService;
  final Future<bool> Function(Customer customer) onCreateInvoice;
  final Widget? drawer;
  final CompanyProfileService? companyProfileService;
  final BalanceShareService? balanceShareService;

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  final _searchController = TextEditingController();

  List<Customer> _allCustomers = const <Customer>[];
  List<Customer> _customers = const <Customer>[];
  bool _isLoading = true;
  bool _isSharingDailySummary = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
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
      appBar: AppBar(
        title: const Text('Customers/Khata'),
        actions: <Widget>[
          IconButton(
            key: const Key('openDailyCollectionsButton'),
            onPressed: _isLoading ? null : _openDailyCollections,
            icon: const Icon(Icons.grid_view_outlined),
            tooltip: 'Daily collections',
          ),
          if (widget.balanceShareService != null &&
              widget.companyProfileService != null)
            IconButton(
              key: const Key('shareDailyBalanceButton'),
              onPressed: _isLoading || _isSharingDailySummary
                  ? null
                  : _previewShareDailySummary,
              icon: _isSharingDailySummary
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.share_outlined),
              tooltip: 'Share daily balances',
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createCustomer,
        icon: const Icon(Icons.add),
        label: const Text('Add customer'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TextField(
              key: const Key('customerSearchField'),
              controller: _searchController,
              onChanged: (_) => _applySearchFilter(),
              decoration: const InputDecoration(
                labelText: 'Search customers',
                hintText: 'Name, phone, address or GSTIN',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 10),
            if (!_isLoading)
              Text(
                '${_customers.length} ${_customers.length == 1 ? 'customer' : 'customers'}',
                style: Theme.of(context).textTheme.labelLarge,
              ),
            const SizedBox(height: 10),
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
    if (_customers.isEmpty) {
      return AppEmptyState(
        icon: Icons.people_outline,
        title: _searchController.text.trim().isEmpty
            ? 'No customers yet'
            : 'No matching customers',
        message: _searchController.text.trim().isEmpty
            ? 'Add a customer to start invoicing and tracking Khata.'
            : 'Try a different name, phone number, address or GSTIN.',
      );
    }
    return ListView.separated(
      itemCount: _customers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final customer = _customers[index];
        return Card(
          child: ListTile(
            onTap: () => _openCustomer(customer),
            leading: CircleAvatar(
              child: Text(customer.name.trim().isEmpty
                  ? '?'
                  : customer.name.trim().characters.first.toUpperCase()),
            ),
            title: Text(
              customer.name,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: customer.address.trim().isEmpty
                ? const Text('No address added')
                : Text(
                    customer.address,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Text(
                  'Receivable',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                Text(
                  '₹${customer.pendingBalance.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                if (!customer.isActive)
                  Text(
                    'Archived',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _loadCustomers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final customers = await widget.customersService.fetchCustomers();
      if (!mounted) {
        return;
      }
      setState(() {
        _allCustomers = customers;
        _customers = _filterCustomers(customers, _searchController.text.trim());
      });
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = _messageForLoadError(error);
        _allCustomers = const <Customer>[];
        _customers = const <Customer>[];
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
      _customers =
          _filterCustomers(_allCustomers, _searchController.text.trim());
    });
  }

  List<Customer> _filterCustomers(List<Customer> customers, String query) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) {
      return customers;
    }
    return customers.where((customer) {
      final name = customer.name.toLowerCase();
      final address = customer.address.toLowerCase();
      final phone = customer.phone?.toLowerCase() ?? '';
      final gstin = customer.gstin?.toLowerCase() ?? '';
      return name.contains(normalizedQuery) ||
          address.contains(normalizedQuery) ||
          phone.contains(normalizedQuery) ||
          gstin.contains(normalizedQuery);
    }).toList();
  }

  Future<void> _openDailyCollections() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => DailyCollectionsScreen(
          paymentsService: widget.paymentsService,
          onSubmitted: _loadCustomers,
        ),
      ),
    );
    if (mounted) {
      await _loadCustomers();
    }
  }

  Future<void> _openCustomer(Customer customer) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => CustomerDetailScreen(
          customerId: customer.id,
          customersService: widget.customersService,
          paymentsService: widget.paymentsService,
          onCreateInvoice: widget.onCreateInvoice,
          companyProfileService: widget.companyProfileService,
          balanceShareService: widget.balanceShareService,
        ),
      ),
    );
    if (mounted) {
      await _loadCustomers();
    }
  }

  Future<void> _previewShareDailySummary() async {
    final profileService = widget.companyProfileService;
    final shareService = widget.balanceShareService;
    if (profileService == null || shareService == null) {
      return;
    }

    setState(() {
      _isSharingDailySummary = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait(<Future<Object>>[
        profileService.fetchCompanyProfile(),
        widget.customersService.fetchCustomers(),
      ]);
      if (!mounted) {
        return;
      }
      final profile = results[0] as CompanyProfile;
      final customers = results[1] as List<Customer>;
      final asOfDate = _dateString(DateTime.now());
      final message = formatDailyBalanceShareMessage(
        sellerName: profile.name,
        asOfDate: asOfDate,
        customers: customers,
      );
      final shouldShare = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Share daily balances'),
          content: SingleChildScrollView(child: Text(message)),
          actions: <Widget>[
            TextButton(
              key: const Key('cancelDailyBalanceShareButton'),
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              key: const Key('confirmDailyBalanceShareButton'),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Share'),
            ),
          ],
        ),
      );
      if (shouldShare == true) {
        await shareService.shareText(message);
      }
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = _messageForLoadError(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSharingDailySummary = false;
        });
      }
    }
  }

  String _dateString(DateTime value) {
    return '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
  }

  Future<void> _createCustomer() async {
    final created = await showDialog<bool>(
          context: context,
          builder: (_) =>
              _CreateCustomerDialog(customersService: widget.customersService),
        ) ??
        false;
    if (created && mounted) {
      await _loadCustomers();
    }
  }

  String _messageForLoadError(Object error) {
    if (error is ApiError) {
      return error.message;
    }
    if (error is SocketException || error is HttpException) {
      return 'Unable to reach the server';
    }
    return 'Unable to load customers';
  }
}

class _CreateCustomerDialog extends StatefulWidget {
  const _CreateCustomerDialog({required this.customersService});

  final CustomersService customersService;

  @override
  State<_CreateCustomerDialog> createState() => _CreateCustomerDialogState();
}

class _CreateCustomerDialogState extends State<_CreateCustomerDialog> {
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _gstinController = TextEditingController();
  final _stateController = TextEditingController();
  final _stateCodeController = TextEditingController();

  bool _isSaving = false;
  bool _whatsappSameAsPhone = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_syncWhatsappIfSame);
  }

  void _syncWhatsappIfSame() {
    if (_whatsappSameAsPhone) {
      _whatsappController.text = _phoneController.text;
    }
  }

  @override
  void dispose() {
    _phoneController.removeListener(_syncWhatsappIfSame);
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    _gstinController.dispose();
    _stateController.dispose();
    _stateCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add customer'),
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
            SwitchListTile(
              title: const Text('WhatsApp same as phone'),
              value: _whatsappSameAsPhone,
              onChanged: _isSaving
                  ? null
                  : (value) {
                      setState(() {
                        _whatsappSameAsPhone = value;
                        if (value) {
                          _whatsappController.text = _phoneController.text;
                        }
                      });
                    },
            ),
            _buildField(
              _whatsappController,
              'WhatsApp number',
              enabled: !_whatsappSameAsPhone,
            ),
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

  Widget _buildField(TextEditingController controller, String label,
      {bool enabled = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        enabled: enabled && !_isSaving,
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
      await widget.customersService.createCustomer(
        CreateCustomerInput(
          name: _nameController.text.trim(),
          address: _addressController.text.trim(),
          phone: _phoneController.text.trim().isEmpty
              ? null
              : _phoneController.text.trim(),
          whatsappNumber: _whatsappSameAsPhone
              ? (_phoneController.text.trim().isEmpty
                  ? null
                  : _phoneController.text.trim())
              : (_whatsappController.text.trim().isEmpty
                  ? null
                  : _whatsappController.text.trim()),
          gstin: _gstinController.text.trim().isEmpty
              ? null
              : _gstinController.text.trim(),
          state: _stateController.text.trim().isEmpty
              ? null
              : _stateController.text.trim(),
          stateCode: _stateCodeController.text.trim().isEmpty
              ? null
              : _stateCodeController.text.trim(),
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
