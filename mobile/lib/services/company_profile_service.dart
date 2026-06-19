import '../models/company_profile.dart';

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
    this.gstFlag = false,
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
  final bool gstFlag;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'name': name,
      'address': address,
      'city': city,
      'state': state,
      'state_code': stateCode,
      'gstin': gstin,
      'gst_flag': gstFlag,
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
