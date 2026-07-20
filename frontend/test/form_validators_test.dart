import 'package:flutter_test/flutter_test.dart';
import 'package:novadis_cri/core/utils/form_validators.dart';

void main() {
  group('CriFormValidators', () {
    group('projectNumber', () {
      test('returns null for valid project number', () {
        final validator = CriFormValidators.projectNumber();
        expect(validator('PRJ-2024-001'), isNull);
        expect(validator('PRJ-2025-999'), isNull);
        expect(validator('PRJ-2020-100'), isNull);
      });

      test('returns error for invalid format', () {
        final validator = CriFormValidators.projectNumber();
        expect(validator('PRJ-24-001'), isNotNull);
        expect(validator('PRJ2024001'), isNotNull);
        expect(validator('prj-2024-001'), isNotNull);
        expect(validator('PRJ-2024-1'), isNotNull);
        expect(validator('PRJ-2024-0001'), isNotNull);
      });

      test('returns error for empty value', () {
        final validator = CriFormValidators.projectNumber();
        expect(validator(''), isNotNull);
        expect(validator(null), isNotNull);
      });

      test('returns error for invalid year', () {
        final validator = CriFormValidators.projectNumber();
        expect(validator('PRJ-2019-001'), isNotNull);
        expect(validator('PRJ-2100-001'), isNotNull);
      });
    });

    group('commandeNumber', () {
      test('returns null for valid commande numbers', () {
        final validator = CriFormValidators.commandeNumber();
        expect(validator('CC09813'), isNull);
        expect(validator('CC1234'), isNull);
        expect(validator('CC123456'), isNull);
      });

      test('returns null for empty value (optional field)', () {
        final validator = CriFormValidators.commandeNumber();
        expect(validator(''), isNull);
        expect(validator(null), isNull);
      });

      test('returns error for invalid format', () {
        final validator = CriFormValidators.commandeNumber();
        expect(validator('cc09813'), isNotNull);
        expect(validator('CC'), isNotNull);
        expect(validator('CC123'), isNotNull);
        expect(validator('CC1234567'), isNotNull);
        expect(validator('09813'), isNotNull);
        expect(validator('CC-09813'), isNotNull);
      });
    });

    group('ticketNumber', () {
      test('returns null for valid ticket number', () {
        final validator = CriFormValidators.ticketNumber();
        expect(validator('TICK-2024-00001'), isNull);
        expect(validator('TICK-2025-99999'), isNull);
        expect(validator('TICK-2020-12345'), isNull);
      });

      test('returns error for invalid format', () {
        final validator = CriFormValidators.ticketNumber();
        expect(validator('TICK-24-00001'), isNotNull);
        expect(validator('TICK202400001'), isNotNull);
        expect(validator('tick-2024-00001'), isNotNull);
        expect(validator('TICK-2024-001'), isNotNull);
        expect(validator('TICK-2024-000001'), isNotNull);
      });

      test('returns error for empty value', () {
        final validator = CriFormValidators.ticketNumber();
        expect(validator(''), isNotNull);
        expect(validator(null), isNotNull);
      });
    });

    group('frenchPhone', () {
      test('returns null for valid French phone numbers', () {
        final validator = CriFormValidators.frenchPhone();
        expect(validator('0612345678'), isNull);
        expect(validator('06 12 34 56 78'), isNull);
        expect(validator('06-12-34-56-78'), isNull);
        expect(validator('06.12.34.56.78'), isNull);
        expect(validator('+33612345678'), isNull);
        expect(validator('0033612345678'), isNull);
      });

      test('returns null for empty value (optional field)', () {
        final validator = CriFormValidators.frenchPhone();
        expect(validator(''), isNull);
        expect(validator(null), isNull);
      });

      test('returns error for invalid phone numbers', () {
        final validator = CriFormValidators.frenchPhone();
        expect(validator('061234567'), isNotNull); // Too short
        expect(validator('06123456789'), isNotNull); // Too long
        expect(validator('1234567890'), isNotNull); // Doesn't start with 0
        expect(validator('00123456789'), isNotNull); // Invalid prefix
      });
    });

    group('email', () {
      test('returns null for valid email addresses', () {
        final validator = CriFormValidators.email();
        expect(validator('test@example.com'), isNull);
        expect(validator('user.name@domain.fr'), isNull);
        expect(validator('user+tag@example.org'), isNull);
      });

      test('returns null for empty value when not required', () {
        final validator = CriFormValidators.email();
        expect(validator(''), isNull);
        expect(validator(null), isNull);
      });

      test('returns error for empty value when required', () {
        final validator = CriFormValidators.email(required: true);
        expect(validator(''), isNotNull);
        expect(validator(null), isNotNull);
      });

      test('returns error for invalid email addresses', () {
        final validator = CriFormValidators.email();
        expect(validator('invalid'), isNotNull);
        expect(validator('invalid@'), isNotNull);
        expect(validator('invalid@.com'), isNotNull);
        expect(validator('@example.com'), isNotNull);
      });

      test('rejects previously accepted false positives', () {
        final validator = CriFormValidators.email();
        // TLD à 1 seul caractère
        expect(validator('a@b.c'), isNotNull);
        // points consécutifs dans le domaine
        expect(validator('a@b..com'), isNotNull);
        // point en début/fin de partie locale
        expect(validator('.user@example.com'), isNotNull);
        expect(validator('user.@example.com'), isNotNull);
        // points consécutifs dans la partie locale
        expect(validator('us..er@example.com'), isNotNull);
        // tiret en bordure de label de domaine
        expect(validator('user@-example.com'), isNotNull);
        expect(validator('user@example-.com'), isNotNull);
      });

      test('accepts valid multi-label domains', () {
        final validator = CriFormValidators.email();
        expect(validator('user@mail.example.co.uk'), isNull);
        expect(validator('user@sub-domain.example.com'), isNull);
      });
    });

    group('notFutureDate', () {
      test('returns null for past dates', () {
        final validator = CriFormValidators.notFutureDate();
        expect(
          validator(DateTime.now().subtract(const Duration(days: 1))),
          isNull,
        );
        expect(validator(DateTime(2020, 1, 1)), isNull);
      });

      test('returns null for today', () {
        final validator = CriFormValidators.notFutureDate();
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        expect(validator(today), isNull);
      });

      test('returns error for future dates', () {
        final validator = CriFormValidators.notFutureDate();
        expect(
          validator(DateTime.now().add(const Duration(days: 1))),
          isNotNull,
        );
        expect(validator(DateTime(2099, 12, 31)), isNotNull);
      });

      test('returns error for null date', () {
        final validator = CriFormValidators.notFutureDate();
        expect(validator(null), isNotNull);
      });
    });

    group('notPastDate', () {
      test('returns null for future dates', () {
        final validator = CriFormValidators.notPastDate();
        expect(validator(DateTime.now().add(const Duration(days: 1))), isNull);
        expect(validator(DateTime(2099, 12, 31)), isNull);
      });

      test('returns null for today', () {
        final validator = CriFormValidators.notPastDate();
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        expect(validator(today), isNull);
      });

      test('returns error for past dates', () {
        final validator = CriFormValidators.notPastDate();
        expect(
          validator(DateTime.now().subtract(const Duration(days: 1))),
          isNotNull,
        );
        expect(validator(DateTime(2020, 1, 1)), isNotNull);
      });

      test('returns null for null date (optional)', () {
        final validator = CriFormValidators.notPastDate();
        expect(validator(null), isNull);
      });
    });

    group('timeAfter', () {
      test('returns null when end time is after start time', () {
        final startTime = DateTime(2024, 1, 1, 9, 0);
        final validator = CriFormValidators.timeAfter(startTime: startTime);

        expect(validator(DateTime(2024, 1, 1, 10, 0)), isNull);
        expect(validator(DateTime(2024, 1, 1, 9, 1)), isNull);
      });

      test('returns error when end time is before or equal to start time', () {
        final startTime = DateTime(2024, 1, 1, 9, 0);
        final validator = CriFormValidators.timeAfter(startTime: startTime);

        expect(validator(DateTime(2024, 1, 1, 8, 0)), isNotNull);
        expect(validator(DateTime(2024, 1, 1, 9, 0)), isNotNull);
      });

      test('returns null when either time is null', () {
        final validator1 = CriFormValidators.timeAfter(startTime: null);
        expect(validator1(DateTime(2024, 1, 1, 10, 0)), isNull);

        final startTime = DateTime(2024, 1, 1, 9, 0);
        final validator2 = CriFormValidators.timeAfter(startTime: startTime);
        expect(validator2(null), isNull);
      });
    });

    group('required', () {
      test('returns null for non-null values', () {
        final validator = CriFormValidators.required<String>();
        expect(validator('value'), isNull);
        expect(validator('  value  '), isNull);
      });

      test('returns error for null values', () {
        final validator = CriFormValidators.required<String>();
        expect(validator(null), isNotNull);
      });

      test('returns error for empty strings', () {
        final validator = CriFormValidators.required<String>();
        expect(validator(''), isNotNull);
        expect(validator('   '), isNotNull);
      });

      test('returns error for empty lists', () {
        final validator = CriFormValidators.required<List>();
        expect(validator([]), isNotNull);
      });

      test('returns null for non-empty lists', () {
        final validator = CriFormValidators.required<List>();
        expect(validator(['item']), isNull);
      });
    });

    group('compose', () {
      test('runs all validators and returns first error', () {
        final validator = CriFormValidators.compose<String>([
          CriFormValidators.required(),
          CriFormValidators.minLength(min: 5),
        ]);

        expect(validator(null), contains('requis'));
        expect(validator('ab'), contains('5'));
        expect(validator('abcdef'), isNull);
      });
    });
  });
}
