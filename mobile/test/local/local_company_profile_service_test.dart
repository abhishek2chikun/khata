import 'package:flutter_test/flutter_test.dart';
import 'package:internal_billing_khata_mobile/local/local_company_profile_service.dart';
import 'package:internal_billing_khata_mobile/local/local_database.dart';
import 'package:internal_billing_khata_mobile/services/company_profile_service.dart';

void main() {
  late LocalDatabase database;
  late LocalCompanyProfileService service;

  setUp(() {
    database = LocalDatabase.memory();
    service = LocalCompanyProfileService(database: database);
  });

  tearDown(() async {
    await database.close();
  });

  test('upserts and fetches the active company profile', () async {
    final created = await service.upsertCompanyProfile(_profileInput());

    expect(created.id, isNotEmpty);
    expect(created.name, 'Khata Traders');
    expect(created.address, '10 Market Road');
    expect(created.city, 'Mumbai');
    expect(created.state, 'Maharashtra');
    expect(created.stateCode, '27');
    expect(created.gstin, '27ABCDE1234F1Z5');
    expect(created.phone, '9999999999');
    expect(created.email, 'billing@example.com');
    expect(created.bankName, 'State Bank');
    expect(created.bankAccount, '1234567890');
    expect(created.bankIfsc, 'SBIN0000001');
    expect(created.bankBranch, 'Fort');
    expect(created.jurisdiction, 'Mumbai');
    expect(created.isActive, isTrue);

    expect(created.gstFlag, isTrue);

    final fetched = await service.fetchCompanyProfile();
    expect(fetched.id, created.id);
    expect(fetched.name, 'Khata Traders');

    final updated = await service.upsertCompanyProfile(
      _profileInput(name: 'Khata Traders Updated', phone: null),
    );
    expect(updated.id, created.id);
    expect(updated.name, 'Khata Traders Updated');
    expect(updated.phone, isNull);

    final storedProfiles =
        await database.select(database.companyProfiles).get();
    expect(storedProfiles, hasLength(1));
    expect(storedProfiles.single.name, 'Khata Traders Updated');
    expect(storedProfiles.single.phone, isNull);
  });
  test('round-trips gst_flag false and true', () async {
    final nonGst = await service.upsertCompanyProfile(
      _profileInput(gstFlag: false, gstin: null),
    );
    expect(nonGst.gstFlag, isFalse);

    final gst = await service.upsertCompanyProfile(
      _profileInput(gstFlag: true),
    );
    expect(gst.gstFlag, isTrue);
  });
}

UpsertCompanyProfileInput _profileInput({
  String name = 'Khata Traders',
  String? phone = '9999999999',
  bool gstFlag = true,
  String? gstin = '27ABCDE1234F1Z5',
}) {
  return UpsertCompanyProfileInput(
    name: name,
    address: '10 Market Road',
    city: 'Mumbai',
    state: 'Maharashtra',
    stateCode: '27',
    gstin: gstin,
    gstFlag: gstFlag,
    phone: phone,
    email: 'billing@example.com',
    bankName: 'State Bank',
    bankAccount: '1234567890',
    bankIfsc: 'SBIN0000001',
    bankBranch: 'Fort',
    jurisdiction: 'Mumbai',
  );
}
