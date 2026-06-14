import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internal_billing_khata_mobile/models/api_error.dart';
import 'package:internal_billing_khata_mobile/models/company_profile.dart';
import 'package:internal_billing_khata_mobile/screens/company_profile_screen.dart';
import 'package:internal_billing_khata_mobile/services/company_profile_service.dart';

void main() {
  testWidgets('empty profile can be saved as a GST seller', (tester) async {
    final service = _ProfileService(profile: null);
    await tester.pumpWidget(
      MaterialApp(
        home: CompanyProfileScreen(
          companyProfileService: service,
          drawer: const Drawer(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('No company profile yet'), findsOneWidget);
    await tester.enterText(find.bySemanticsLabel('Company name'), 'Khata Co');
    await tester.enterText(find.bySemanticsLabel('Address'), 'Main Road');
    await tester.enterText(find.bySemanticsLabel('City'), 'Mumbai');
    await tester.enterText(find.bySemanticsLabel('State'), 'Maharashtra');
    await tester.enterText(find.bySemanticsLabel('State code'), '27');
    await tester.tap(find.text('GST registered seller'));
    await tester.pump();

    await tester
        .ensureVisible(find.byKey(const Key('saveCompanyProfileButton')));
    await tester.tap(find.byKey(const Key('saveCompanyProfileButton')));
    await tester.pumpAndSettle();
    expect(find.text('GSTIN is required for GST registered sellers'),
        findsOneWidget);
    expect(service.savedInputs, isEmpty);

    await tester.enterText(find.bySemanticsLabel('GSTIN'), '27ABCDE1234F1Z5');
    await tester
        .ensureVisible(find.byKey(const Key('saveCompanyProfileButton')));
    await tester.tap(find.byKey(const Key('saveCompanyProfileButton')));
    await tester.pumpAndSettle();

    expect(service.savedInputs, hasLength(1));
    expect(service.savedInputs.single.gstFlag, isTrue);
    expect(service.savedInputs.single.gstin, '27ABCDE1234F1Z5');
    expect(find.text('Company profile saved'), findsOneWidget);
  });

  testWidgets('switching an existing profile to non-GST clears GSTIN',
      (tester) async {
    final service = _ProfileService(profile: _profile);
    await tester.pumpWidget(
      MaterialApp(
        home: CompanyProfileScreen(
          companyProfileService: service,
          drawer: const Drawer(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('GSTIN'), findsOneWidget);
    await tester.tap(find.text('GST registered seller'));
    await tester.pump();
    await tester
        .ensureVisible(find.byKey(const Key('saveCompanyProfileButton')));
    await tester.tap(find.byKey(const Key('saveCompanyProfileButton')));
    await tester.pumpAndSettle();

    expect(service.savedInputs.single.gstFlag, isFalse);
    expect(service.savedInputs.single.gstin, isNull);
  });
}

class _ProfileService implements CompanyProfileService {
  _ProfileService({required this.profile});

  CompanyProfile? profile;
  final List<UpsertCompanyProfileInput> savedInputs = [];

  @override
  Future<CompanyProfile> fetchCompanyProfile() async {
    final value = profile;
    if (value == null) {
      throw const ApiError(
        code: 'NOT_FOUND',
        message: 'Not found',
        statusCode: 404,
      );
    }
    return value;
  }

  @override
  Future<CompanyProfile> upsertCompanyProfile(
      UpsertCompanyProfileInput input) async {
    savedInputs.add(input);
    profile = CompanyProfile(
      id: 'company-1',
      name: input.name,
      address: input.address,
      city: input.city,
      state: input.state,
      stateCode: input.stateCode,
      gstin: input.gstin,
      gstFlag: input.gstFlag,
      phone: input.phone,
      email: input.email,
      bankName: input.bankName,
      bankAccount: input.bankAccount,
      bankIfsc: input.bankIfsc,
      bankBranch: input.bankBranch,
      jurisdiction: input.jurisdiction,
      isActive: true,
    );
    return profile!;
  }
}

const _profile = CompanyProfile(
  id: 'company-1',
  name: 'Khata Co',
  address: 'Main Road',
  city: 'Mumbai',
  state: 'Maharashtra',
  stateCode: '27',
  gstin: '27ABCDE1234F1Z5',
  gstFlag: true,
  phone: null,
  email: null,
  bankName: null,
  bankAccount: null,
  bankIfsc: null,
  bankBranch: null,
  jurisdiction: null,
  isActive: true,
);
