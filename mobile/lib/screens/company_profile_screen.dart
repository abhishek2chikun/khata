import 'dart:io';

import 'package:flutter/material.dart';

import '../models/api_error.dart';
import '../models/company_profile.dart';
import '../services/company_profile_service.dart';
import '../widgets/error_banner.dart';

class CompanyProfileScreen extends StatefulWidget {
  const CompanyProfileScreen({
    super.key,
    required this.companyProfileService,
    required this.drawer,
  });

  final CompanyProfileService companyProfileService;
  final Widget drawer;

  @override
  State<CompanyProfileScreen> createState() => _CompanyProfileScreenState();
}

class _CompanyProfileScreenState extends State<CompanyProfileScreen> {
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _stateCodeController = TextEditingController();
  final _gstinController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _bankAccountController = TextEditingController();
  final _bankIfscController = TextEditingController();
  final _bankBranchController = TextEditingController();
  final _jurisdictionController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  String? _infoMessage;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _stateCodeController.dispose();
    _gstinController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _bankNameController.dispose();
    _bankAccountController.dispose();
    _bankIfscController.dispose();
    _bankBranchController.dispose();
    _jurisdictionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: widget.drawer,
      appBar: AppBar(title: const Text('Company profile')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  if (_errorMessage != null) ...<Widget>[
                    ErrorBanner(message: _errorMessage!),
                    const SizedBox(height: 16),
                  ],
                  if (_infoMessage != null) ...<Widget>[
                    Material(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(_infoMessage!),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  _buildField(_nameController, 'Company name'),
                  _buildField(_addressController, 'Address'),
                  _buildField(_cityController, 'City'),
                  _buildField(_stateController, 'State'),
                  _buildField(_stateCodeController, 'State code'),
                  _buildField(_gstinController, 'GSTIN'),
                  _buildField(_phoneController, 'Phone'),
                  _buildField(_emailController, 'Email'),
                  _buildField(_bankNameController, 'Bank name'),
                  _buildField(_bankAccountController, 'Bank account'),
                  _buildField(_bankIfscController, 'Bank IFSC'),
                  _buildField(_bankBranchController, 'Bank branch'),
                  _buildField(_jurisdictionController, 'Jurisdiction'),
                  const SizedBox(height: 16),
                  FilledButton(
                    key: const Key('saveCompanyProfileButton'),
                    onPressed: _isSaving ? null : _save,
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save company profile'),
                  ),
                ],
              ),
            ),
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

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _infoMessage = null;
    });

    try {
      final profile = await widget.companyProfileService.fetchCompanyProfile();
      _populate(profile);
    } on ApiError catch (error) {
      if (error.statusCode == 404) {
        _infoMessage =
            'No company profile yet. Fill this before regular invoicing.';
      } else {
        _errorMessage = error.message;
      }
    } on Object catch (error) {
      _errorMessage = _messageForError(error);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _save() async {
    setState(() {
      _isSaving = true;
      _errorMessage = null;
      _infoMessage = null;
    });

    try {
      final saved = await widget.companyProfileService.upsertCompanyProfile(
        UpsertCompanyProfileInput(
          name: _nameController.text.trim(),
          address: _addressController.text.trim(),
          city: _cityController.text.trim(),
          state: _stateController.text.trim(),
          stateCode: _stateCodeController.text.trim(),
          gstin: _emptyToNull(_gstinController.text),
          phone: _emptyToNull(_phoneController.text),
          email: _emptyToNull(_emailController.text),
          bankName: _emptyToNull(_bankNameController.text),
          bankAccount: _emptyToNull(_bankAccountController.text),
          bankIfsc: _emptyToNull(_bankIfscController.text),
          bankBranch: _emptyToNull(_bankBranchController.text),
          jurisdiction: _emptyToNull(_jurisdictionController.text),
        ),
      );
      _populate(saved);
      if (!mounted) {
        return;
      }
      setState(() {
        _infoMessage = 'Company profile saved';
      });
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

  void _populate(CompanyProfile profile) {
    _nameController.text = profile.name;
    _addressController.text = profile.address;
    _cityController.text = profile.city;
    _stateController.text = profile.state;
    _stateCodeController.text = profile.stateCode;
    _gstinController.text = profile.gstin ?? '';
    _phoneController.text = profile.phone ?? '';
    _emailController.text = profile.email ?? '';
    _bankNameController.text = profile.bankName ?? '';
    _bankAccountController.text = profile.bankAccount ?? '';
    _bankIfscController.text = profile.bankIfsc ?? '';
    _bankBranchController.text = profile.bankBranch ?? '';
    _jurisdictionController.text = profile.jurisdiction ?? '';
  }

  String _messageForError(Object error) {
    if (error is ApiError) {
      return error.message;
    }
    if (error is SocketException || error is HttpException) {
      return 'Unable to reach the server';
    }
    return 'Unable to load company profile';
  }
}

String? _emptyToNull(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}
