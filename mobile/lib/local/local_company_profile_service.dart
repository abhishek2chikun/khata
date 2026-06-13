import 'package:drift/drift.dart';

import '../models/api_error.dart';
import '../models/company_profile.dart' as profile_model;
import '../services/company_profile_service.dart';
import 'local_database.dart';
import 'local_customers_service.dart';

class LocalCompanyProfileService implements CompanyProfileService {
  LocalCompanyProfileService({required LocalDatabase database})
      : _database = database;

  final LocalDatabase _database;

  @override
  Future<profile_model.CompanyProfile> fetchCompanyProfile() async {
    final profile = await (_database.select(_database.companyProfiles)
          ..where((profile) => profile.isActive.equals(true))
          ..limit(1))
        .getSingleOrNull();
    if (profile == null) {
      throw const ApiError(
        code: 'NOT_FOUND',
        message: 'Company profile not found',
        statusCode: 404,
      );
    }
    return _toCompanyProfile(profile);
  }

  @override
  Future<profile_model.CompanyProfile> upsertCompanyProfile(
      UpsertCompanyProfileInput input) async {
    final now = DateTime.now().toUtc().toIso8601String();
    final existing = await (_database.select(_database.companyProfiles)
          ..where((profile) => profile.isActive.equals(true))
          ..limit(1))
        .getSingleOrNull();
    final id = existing?.id ?? generateLocalUuid();
    final companion = CompanyProfilesCompanion(
      id: Value(id),
      name: Value(input.name),
      address: Value(input.address),
      city: Value(input.city),
      state: Value(input.state),
      stateCode: Value(input.stateCode),
      gstin: Value(input.gstin),
      gstFlag: Value(input.gstFlag),
      phone: Value(input.phone),
      email: Value(input.email),
      bankName: Value(input.bankName),
      bankAccount: Value(input.bankAccount),
      bankIfsc: Value(input.bankIfsc),
      bankBranch: Value(input.bankBranch),
      jurisdiction: Value(input.jurisdiction),
      isActive: const Value(true),
      createdAt: Value(existing?.createdAt ?? now),
      updatedAt: Value(now),
    );

    if (existing == null) {
      await _database.into(_database.companyProfiles).insert(companion);
    } else {
      await (_database.update(_database.companyProfiles)
            ..where((profile) => profile.id.equals(id)))
          .write(companion);
    }

    return fetchCompanyProfile();
  }

  profile_model.CompanyProfile _toCompanyProfile(CompanyProfile profile) {
    return profile_model.CompanyProfile(
      id: profile.id,
      name: profile.name,
      address: profile.address,
      city: profile.city,
      state: profile.state,
      stateCode: profile.stateCode,
      gstin: profile.gstin,
      gstFlag: profile.gstFlag,
      phone: profile.phone,
      email: profile.email,
      bankName: profile.bankName,
      bankAccount: profile.bankAccount,
      bankIfsc: profile.bankIfsc,
      bankBranch: profile.bankBranch,
      jurisdiction: profile.jurisdiction,
      isActive: profile.isActive,
    );
  }
}
