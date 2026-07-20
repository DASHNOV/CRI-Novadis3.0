import 'package:flutter_test/flutter_test.dart';
import 'package:novadis_cri/core/utils/cri_reference.dart';

void main() {
  group('CriReference.siteAcronym', () {
    test('derives initials from significant words', () {
      expect(CriReference.siteAcronym('Centre Commercial Rivetoile'),
          equals('CCR'));
    });

    test('ignores stop words', () {
      expect(CriReference.siteAcronym('Hôtel de Ville'), equals('HV'));
      expect(CriReference.siteAcronym('Gare du Nord'), equals('GN'));
    });

    test('handles separators (tirets / slash)', () {
      expect(CriReference.siteAcronym('Aix-en-Provence'), equals('AP'));
    });

    test('falls back to first letters for single word', () {
      expect(CriReference.siteAcronym('Monoprix'), equals('M'));
    });

    test('returns empty for empty/null input', () {
      expect(CriReference.siteAcronym(''), equals(''));
      expect(CriReference.siteAcronym(null), equals(''));
    });
  });

  group('CriReference.generate', () {
    test('builds CRI<date>_<acronyme><client>', () {
      final ref = CriReference.generate(
        date: DateTime(2026, 7, 20),
        siteName: 'Centre Commercial Rivetoile',
        clientName: 'Monoprix',
      );
      expect(ref, equals('CRI20260720_CCRMonoprix'));
    });

    test('pads month and day', () {
      final ref = CriReference.generate(
        date: DateTime(2026, 1, 5),
        siteName: 'Gare du Nord',
        clientName: 'SNCF',
      );
      expect(ref, equals('CRI20260105_GNSNCF'));
    });

    test('strips spaces and special chars from client name', () {
      final ref = CriReference.generate(
        date: DateTime(2026, 7, 20),
        siteName: 'Monoprix',
        clientName: 'Groupe Casino & Cie',
      );
      expect(ref, equals('CRI20260720_MGroupeCasinoCie'));
    });
  });
}
