import 'dart:convert';

import '../models/company_profile.dart';
import 'api_client.dart';

class UpsertCompanyProfileInput {
  const UpsertCompanyProfileInput({
    required this.name,
    required this.address,
    required this.city,
    required this.state,
    required this.stateCode,
    this.gstin,
    this.phone,
    this.email,
    this.bankName,
    this.bankAccount,
    this.bankIfsc,
    this.bankBranch,
    this.jurisdiction,
  });

  final String name;
  final String address;
  final String city;
  final String state;
  final String stateCode;
  final String? gstin;
  final String? phone;
  final String? email;
  final String? bankName;
  final String? bankAccount;
  final String? bankIfsc;
  final String? bankBranch;
  final String? jurisdiction;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'name': name,
      'address': address,
      'city': city,
      'state': state,
      'state_code': stateCode,
      'gstin': gstin,
      'phone': phone,
      'email': email,
      'bank_name': bankName,
      'bank_account': bankAccount,
      'bank_ifsc': bankIfsc,
      'bank_branch': bankBranch,
      'jurisdiction': jurisdiction,
    };
  }
}

abstract class CompanyProfileService {
  Future<CompanyProfile> fetchCompanyProfile();

  Future<CompanyProfile> upsertCompanyProfile(UpsertCompanyProfileInput input);
}

class ApiCompanyProfileService implements CompanyProfileService {
  ApiCompanyProfileService({required ApiClient apiClient})
      : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<CompanyProfile> fetchCompanyProfile() async {
    final response = await _apiClient.get('/company-profile');
    return CompanyProfile.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>);
  }

  @override
  Future<CompanyProfile> upsertCompanyProfile(
      UpsertCompanyProfileInput input) async {
    final response =
        await _apiClient.put('/company-profile', body: input.toJson());
    return CompanyProfile.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>);
  }
}
