import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novadis_cri/features/cri_form/widgets/priority_chip.dart';
import 'package:novadis_cri/data/local/tables/cri_service_table.dart';

void main() {
  group('PriorityChip', () {
    testWidgets('displays correct label for each priority', (tester) async {
      for (final priority in ServicePriority.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: PriorityChip(priority: priority)),
          ),
        );

        expect(find.text(priority.label), findsOneWidget);
      }
    });

    testWidgets('shows icon when showIcon is true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PriorityChip(priority: ServicePriority.haute, showIcon: true),
          ),
        ),
      );

      expect(find.byType(Icon), findsOneWidget);
    });

    testWidgets('hides icon when showIcon is false', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PriorityChip(
              priority: ServicePriority.haute,
              showIcon: false,
            ),
          ),
        ),
      );

      expect(find.byType(Icon), findsNothing);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PriorityChip(
              priority: ServicePriority.normale,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(PriorityChip));
      expect(tapped, isTrue);
    });
  });

  group('PrioritySelector', () {
    testWidgets('displays all priority options', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: PrioritySelector(onPriorityChanged: (_) {})),
        ),
      );

      for (final priority in ServicePriority.values) {
        expect(find.text(priority.label), findsOneWidget);
      }
    });

    testWidgets('highlights selected priority', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrioritySelector(
              selectedPriority: ServicePriority.haute,
              onPriorityChanged: (_) {},
            ),
          ),
        ),
      );

      // The selected chip should be found
      final chips = tester.widgetList<PriorityChip>(find.byType(PriorityChip));
      final selectedChip = chips.firstWhere(
        (chip) => chip.priority == ServicePriority.haute,
      );
      expect(selectedChip.isSelected, isTrue);
    });

    testWidgets('calls onPriorityChanged when option is tapped', (
      tester,
    ) async {
      ServicePriority? selectedPriority;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrioritySelector(
              onPriorityChanged: (priority) => selectedPriority = priority,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Critique'));
      expect(selectedPriority, equals(ServicePriority.critique));
    });
  });

  group('PriorityBadge', () {
    testWidgets('renders a small circular badge', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: PriorityBadge(priority: ServicePriority.haute)),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration;

      expect(decoration.shape, equals(BoxShape.circle));
      expect(container.constraints?.maxWidth, equals(8));
      expect(container.constraints?.maxHeight, equals(8));
    });
  });

  group('PriorityIndicator', () {
    testWidgets('displays priority label and icon (non-compact)', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PriorityIndicator(
              priority: ServicePriority.critique,
              compact: false,
            ),
          ),
        ),
      );

      expect(find.text('Priorité'), findsOneWidget);
      expect(find.text('Critique'), findsOneWidget);
      expect(find.byType(Icon), findsWidgets);
    });

    testWidgets('displays compact version', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PriorityIndicator(
              priority: ServicePriority.basse,
              compact: true,
            ),
          ),
        ),
      );

      expect(find.text('Priorité'), findsNothing);
      expect(find.text('Basse'), findsOneWidget);
    });
  });

  group('ServicePriority enum', () {
    test('has correct color for each priority', () {
      expect(ServicePriority.basse.color, equals(const Color(0xFF4CAF50)));
      expect(ServicePriority.normale.color, equals(const Color(0xFF2196F3)));
      expect(ServicePriority.haute.color, equals(const Color(0xFFFF9800)));
      expect(ServicePriority.critique.color, equals(const Color(0xFFF44336)));
    });

    test('fromString returns correct enum value', () {
      expect(
        ServicePriority.fromString('basse'),
        equals(ServicePriority.basse),
      );
      expect(
        ServicePriority.fromString('Basse'),
        equals(ServicePriority.basse),
      );
      expect(
        ServicePriority.fromString('normale'),
        equals(ServicePriority.normale),
      );
      expect(
        ServicePriority.fromString('Normale'),
        equals(ServicePriority.normale),
      );
      expect(
        ServicePriority.fromString('haute'),
        equals(ServicePriority.haute),
      );
      expect(
        ServicePriority.fromString('Haute'),
        equals(ServicePriority.haute),
      );
      expect(
        ServicePriority.fromString('critique'),
        equals(ServicePriority.critique),
      );
      expect(
        ServicePriority.fromString('Critique'),
        equals(ServicePriority.critique),
      );
    });

    test('fromString returns default for unknown value', () {
      expect(
        ServicePriority.fromString('unknown'),
        equals(ServicePriority.normale),
      );
      expect(ServicePriority.fromString(''), equals(ServicePriority.normale));
    });
  });
}
