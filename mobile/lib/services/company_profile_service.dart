import 'dart:convert';

import '../models/company_profile.dart';
import 'api_client.dart';

abstract class CompanyProfileService {
  Future<CompanyProfile> fetchCompanyProfile();
}

class ApiCompanyProfileService implements CompanyProfileService {
  ApiCompanyProfileService({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<CompanyProfile> fetchCompanyProfile() async {
    final response = await _apiClient.get('/company-profile');
    return CompanyProfile.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }
}
