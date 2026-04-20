class CompanyProfile {
  const CompanyProfile({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
    required this.state,
    required this.stateCode,
    required this.gstin,
    required this.phone,
    required this.email,
    required this.bankName,
    required this.bankAccount,
    required this.bankIfsc,
    required this.bankBranch,
    required this.jurisdiction,
    required this.isActive,
  });

  final String id;
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
  final bool isActive;

  factory CompanyProfile.fromJson(Map<String, dynamic> json) {
    return CompanyProfile(
      id: json['id'].toString(),
      name: json['name'] as String? ?? '',
      address: json['address'] as String? ?? '',
      city: json['city'] as String? ?? '',
      state: json['state'] as String? ?? '',
      stateCode: json['state_code'] as String? ?? '',
      gstin: json['gstin'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      bankName: json['bank_name'] as String?,
      bankAccount: json['bank_account'] as String?,
      bankIfsc: json['bank_ifsc'] as String?,
      bankBranch: json['bank_branch'] as String?,
      jurisdiction: json['jurisdiction'] as String?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}
