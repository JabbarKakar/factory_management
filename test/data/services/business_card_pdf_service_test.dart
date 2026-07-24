import 'package:factory_management/data/services/export/business_card_pdf_service.dart';
import 'package:factory_management/domain/entities/factory_profile.dart';
import 'package:factory_management/domain/entities/factory_profile_sub_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final sampleProfile = FactoryProfile(
    id: 'fac-101',
    identity: const IdentityInfo(
      businessName: 'Apex Marble Industry',
      legalName: 'Apex Industrial Private Limited',
      tagline: 'Premium Natural Stone Processing',
      establishedYear: 2018,
    ),
    contact: const ContactInfo(
      address: 'Plot 42, Sector I-9',
      city: 'Islamabad',
      province: 'ICT',
      phone: '+92 300 1234567',
      email: 'info@apexmarble.com',
      website: 'www.apexmarble.com',
      googleMapsLink: 'https://maps.google.com/?q=33.68,73.04',
    ),
    legal: const LegalInfo(
      ntn: '1234567-8',
      strn: '9876543210123',
    ),
    ownership: const OwnershipInfo(
      ownerName: 'Zahid Khan',
    ),
  );

  group('BusinessCardPdfService', () {
    test('generateSingleCardPdf produces non-empty PDF document bytes', () async {
      final pdfBytes = await BusinessCardPdfService.generateSingleCardPdf(sampleProfile);
      expect(pdfBytes, isNotNull);
      expect(pdfBytes.length, greaterThan(100));
    });

    test('generateA4PrintSheet produces 10-card A4 print sheet bytes', () async {
      final pdfBytes = await BusinessCardPdfService.generateA4PrintSheet(sampleProfile);
      expect(pdfBytes, isNotNull);
      expect(pdfBytes.length, greaterThan(500));
    });

    test('gracefully handles missing optional fields (NTN, STRN, email, tagline)', () async {
      final minimalProfile = FactoryProfile.legacy(
        id: 'fac-minimal',
        name: 'Simple Stone Factory',
      );

      final singlePdf = await BusinessCardPdfService.generateSingleCardPdf(minimalProfile);
      final a4Pdf = await BusinessCardPdfService.generateA4PrintSheet(minimalProfile);

      expect(singlePdf.length, greaterThan(100));
      expect(a4Pdf.length, greaterThan(500));
    });
  });
}
